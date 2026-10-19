using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Shared.Contracts.Users;
using Microsoft.AspNetCore.Authorization;
using UserService.Data;
using UserService.Models;
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

    /// <summary>
    /// Đăng ký tài khoản mới
    /// </summary>
    /// <param name="req">Thông tin đăng ký (Name, Email)</param>
    /// <param name="db">Database context</param>
    /// <returns>User vừa được tạo hoặc token nếu chọn</returns>
    [HttpPost("register")]
    [AllowAnonymous]
    public async Task<ActionResult<UserDto>> Register(
        [FromBody] TokenRequest req,
        [FromServices] UserDbContext db)
    {
        // Validate input
        if (string.IsNullOrWhiteSpace(req.Name) || string.IsNullOrWhiteSpace(req.Email))
            return BadRequest("Name & Email required");

        // Kiểm tra email đã tồn tại chưa
        var emailExists = await db.Users.AnyAsync(u => u.Email == req.Email);
        if (emailExists)
            return Conflict(new { message = $"Email '{req.Email}' đã được đăng ký" });

        // Kiểm tra name đã tồn tại chưa (tuỳ chọn)
        // var nameExists = await db.Users.AnyAsync(u => u.Name == req.Name);
        // if (nameExists)
        //     return Conflict(new { message = $"Tên '{req.Name}' đã tồn tại" });

        try
        {
            // Tạo user mới
            var newUser = new User
            {
                Name = req.Name,
                Email = req.Email
            };

            db.Users.Add(newUser);
            await db.SaveChangesAsync();

            // Trả về user info
            return CreatedAtAction(
                nameof(Register),
                new { id = newUser.Id },
                new UserDto(newUser.Id, newUser.Name, newUser.Email)
            );
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Lỗi khi tạo user", detail = ex.Message });
        }
    }
}
