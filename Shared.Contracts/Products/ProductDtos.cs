using Shared.Contracts.Users;

namespace Shared.Contracts.Products;
public record ProductCreateDto(string Name, decimal Price, int Quantity, int CreatedByUserId);
public record ProductUpdateDto(string Name, decimal Price, int Quantity);
public record ProductDto(int Id, string Name, decimal Price, int Quantity, int CreatedByUserId, UserBriefDto? CreatedBy);
