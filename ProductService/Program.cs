using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Polly;
using ProductService.Data;
using ProductService.Services;
using Serilog;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Serilog
builder.Host.UseSerilog((ctx, lc) => lc.ReadFrom.Configuration(ctx.Configuration).WriteTo.Console());

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "ProductService", Version = "v1" });

    var jwtScheme = new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Description = "Nhập: Bearer {token}",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        Reference = new OpenApiReference
        {
            Type = ReferenceType.SecurityScheme,
            Id = JwtBearerDefaults.AuthenticationScheme
        }
    };

    c.AddSecurityDefinition(jwtScheme.Reference.Id, jwtScheme);
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        { jwtScheme, Array.Empty<string>() }
    });

    // Include XML documentation
    var xmlPath = Path.Combine(AppContext.BaseDirectory, "ProductService.xml");
    if (File.Exists(xmlPath))
    {
        c.IncludeXmlComments(xmlPath);
    }
});

builder.Services.AddDbContext<ProductDbContext>(opts =>
    opts.UseSqlServer(builder.Configuration.GetConnectionString("Default"))
);

// JWT
var jwt = builder.Configuration.GetSection("Jwt");
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateIssuerSigningKey = true,
            ValidateLifetime = true,          
            ClockSkew = TimeSpan.Zero,        
            RequireSignedTokens = true,

            ValidIssuer = jwt["Issuer"],
            ValidAudience = jwt["Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt["Key"]!))
        };
    });
builder.Services.AddAuthorization();

// HttpClientFactory + Polly for UserService
builder.Services.AddHttpClient<IUserClient, UserClient>(client =>
{
    // When running via Docker Compose, we call UserService by its compose service name.
    client.BaseAddress = new Uri(builder.Configuration["Services:UserServiceBaseUrl"]!);
})
.AddPolicyHandler(UserClient.GetRetryPolicy());

var app = builder.Build();

// Auto-migrate + seed
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<ProductDbContext>();
    db.Database.Migrate();
    if (!db.Products.Any())
    {
        db.Products.AddRange(
            new ProductService.Models.Product { Name = "Keyboard", Price = 49.99m, Quantity = 100, CreatedByUserId = 1 },
            new ProductService.Models.Product { Name = "Mouse", Price = 25.00m, Quantity = 200, CreatedByUserId = 2 }
        );
        db.SaveChanges();
    }
}

//if (app.Environment.IsDevelopment() || true)
//{
//    app.UseSwagger();
//    app.UseSwaggerUI();
//}
// Redirect root to swagger
app.MapGet("/", context =>
{
    context.Response.Redirect("/swagger/index.html", permanent: false);
    return Task.CompletedTask;
});

app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "ProductService v1");
    c.RoutePrefix = "swagger";
});
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.Run();
