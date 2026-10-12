using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Shared.Contracts.Users;
using UserService.Data;
using UserService.Models;

namespace UserService.Controllers;

[ApiController]
[Route("users")]
[Authorize]
public class UsersController : ControllerBase
{
    private readonly UserDbContext _db;
    public UsersController(UserDbContext db) => _db = db;

    [HttpGet]
    public async Task<ActionResult<IEnumerable<UserDto>>> GetAll()
        => Ok(await _db.Users.Select(u => new UserDto(u.Id, u.Name, u.Email)).ToListAsync());

    [HttpGet("{id:int}")]
    public async Task<ActionResult<UserDto>> GetById(int id)
    {
        var u = await _db.Users.FindAsync(id);
        return u is null ? NotFound() : Ok(new UserDto(u.Id, u.Name, u.Email));
    }

    [HttpPost]
    public async Task<ActionResult<UserDto>> Create(UserCreateDto dto)
    {
        var u = new User { Name = dto.Name, Email = dto.Email };
        _db.Users.Add(u);
        await _db.SaveChangesAsync();
        return CreatedAtAction(nameof(GetById), new { id = u.Id }, new UserDto(u.Id, u.Name, u.Email));
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, UserUpdateDto dto)
    {
        var u = await _db.Users.FindAsync(id);
        if (u is null) return NotFound();
        u.Name = dto.Name; u.Email = dto.Email;
        await _db.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var u = await _db.Users.FindAsync(id);
        if (u is null) return NotFound();
        _db.Users.Remove(u);
        await _db.SaveChangesAsync();
        return NoContent();
    }
}
