using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Prometheus;
using Serilog;
using System.Text;
using UserService.Data;

var builder = WebApplication.CreateBuilder(args);

// Serilog
builder.Host.UseSerilog((ctx, lc) => lc
    .ReadFrom.Configuration(ctx.Configuration)
    .WriteTo.Console()
);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "UserService", Version = "v1" });

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
    var xmlPath = Path.Combine(AppContext.BaseDirectory, "UserService.xml");
    if (File.Exists(xmlPath))
    {
        c.IncludeXmlComments(xmlPath);
    }
});

// EF Core + SQL Server
builder.Services.AddDbContext<UserDbContext>(opts =>
    opts.UseSqlServer(builder.Configuration.GetConnectionString("Default"))
);

// Auth
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

var app = builder.Build();

// Auto-migrate + seed
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<UserDbContext>();
    db.Database.Migrate();
    if (!db.Users.Any())
    {
        db.Users.AddRange(
            new UserService.Models.User { Name = "Alice", Email = "alice@example.com" },
            new UserService.Models.User { Name = "Bob", Email = "bob@example.com" }
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
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "UserService v1");
    c.RoutePrefix = "swagger";
});

// Thu thập metric HTTP của ứng dụng
app.UseHttpMetrics();

app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

// Endpoint để Prometheus đọc metric
app.MapMetrics();

app.Run();
