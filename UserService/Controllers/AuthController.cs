using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Shared.Contracts.Users;
using Microsoft.AspNetCore.Authorization;
using UserService.Data;
using Microsoft.EntityFrameworkCore;

namespace UserService.Controllers;

[ApiController]
[Route("auth")]
public class AuthController : ControllerBase
{
    private readonly IConfiguration _config;
    public AuthController(IConfiguration config) => _config = config;

    [HttpPost("token")]
    [AllowAnonymous]  
    public async Task<ActionResult<TokenResponse>> Token(
    [FromBody] TokenRequest req,
    [FromServices] UserDbContext db)
    {
        if (string.IsNullOrWhiteSpace(req.Name) || string.IsNullOrWhiteSpace(req.Email))
            return BadRequest("Name & Email required");

        
        var exists = await db.Users.AnyAsync(u => u.Email == req.Email && u.Name == req.Name);
        if (!exists) return Unauthorized("Invalid credentials.");

        var jwt = _config.GetSection("Jwt");
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt["Key"]!));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var expires = DateTime.UtcNow.AddMinutes(int.Parse(jwt["ExpiresMinutes"] ?? "120"));

        var claims = new[]
        {
        new Claim(JwtRegisteredClaimNames.Sub, req.Email),
        new Claim("name", req.Name),
        new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
    };

        var token = new JwtSecurityToken(
            issuer: jwt["Issuer"],
            audience: jwt["Audience"],
            claims: claims,
            expires: expires,
            signingCredentials: creds);

        var tokenStr = new JwtSecurityTokenHandler().WriteToken(token);
        return Ok(new TokenResponse(tokenStr, (long)(expires - DateTime.UtcNow).TotalSeconds));
    }
}
