using System.ComponentModel.DataAnnotations;
namespace ProductService.Models;
public class Product
{
    public int Id { get; set; }
    [Required, MaxLength(100)] public string Name { get; set; } = string.Empty;
    [Range(0, 1_000_000)] public decimal Price { get; set; }
    [Range(0, int.MaxValue)] public int Quantity { get; set; }
    public int CreatedByUserId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
