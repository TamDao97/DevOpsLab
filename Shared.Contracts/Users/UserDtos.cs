namespace Shared.Contracts.Users;
public record UserCreateDto(string Name, string Email);
public record UserUpdateDto(string Name, string Email);
public record UserDto(int Id, string Name, string Email);
public record UserBriefDto(int Id, string Name, string Email);
public record TokenRequest(string Name, string Email);
public record TokenResponse(string access_token, long expires_in);
