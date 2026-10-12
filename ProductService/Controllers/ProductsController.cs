using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ProductService.Data;
using ProductService.Models;
using ProductService.Services;
using Shared.Contracts.Products;
using Shared.Contracts.Users;

namespace ProductService.Controllers;

[ApiController]
[Route("products")]
[Authorize]
public class ProductsController : ControllerBase
{
    private readonly ProductDbContext _db;
    private readonly IUserClient _userClient;

    public ProductsController(ProductDbContext db, IUserClient userClient)
    {
        _db = db;
        _userClient = userClient;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ProductDto>>> GetAll(CancellationToken ct)
    {
        var data = await _db.Products.AsNoTracking().ToListAsync(ct);
        var result = new List<ProductDto>();
        foreach (var p in data)
        {
            UserBriefDto? creator = null;
            try { creator = await _userClient.GetUserAsync(p.CreatedByUserId, ct); } catch { }
            result.Add(new ProductDto(p.Id, p.Name, p.Price, p.Quantity, p.CreatedByUserId, creator));
        }
        return Ok(result);
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ProductDto>> GetById(int id, CancellationToken ct)
    {
        var p = await _db.Products.FindAsync(new object?[] { id }, ct);
        if (p is null) return NotFound();
        UserBriefDto? creator = null;
        try { creator = await _userClient.GetUserAsync(p.CreatedByUserId, ct); } catch { }
        return Ok(new ProductDto(p.Id, p.Name, p.Price, p.Quantity, p.CreatedByUserId, creator));
    }

    [HttpPost]
    public async Task<ActionResult<ProductDto>> Create(ProductCreateDto dto, CancellationToken ct)
    {
        var p = new Product { Name = dto.Name, Price = dto.Price, Quantity = dto.Quantity, CreatedByUserId = dto.CreatedByUserId };
        _db.Products.Add(p);
        await _db.SaveChangesAsync(ct);
        return CreatedAtAction(nameof(GetById), new { id = p.Id }, new ProductDto(p.Id, p.Name, p.Price, p.Quantity, p.CreatedByUserId, null));
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, ProductUpdateDto dto, CancellationToken ct)
    {
        var p = await _db.Products.FindAsync(new object?[] { id }, ct);
        if (p is null) return NotFound();
        p.Name = dto.Name; p.Price = dto.Price; p.Quantity = dto.Quantity;
        await _db.SaveChangesAsync(ct);
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id, CancellationToken ct)
    {
        var p = await _db.Products.FindAsync(new object?[] { id }, ct);
        if (p is null) return NotFound();
        _db.Products.Remove(p);
        await _db.SaveChangesAsync(ct);
        return NoContent();
    }
}
