using System.Net.Http.Json;
using Polly;
using Polly.Extensions.Http;
using Shared.Contracts.Users;

namespace ProductService.Services;

public interface IUserClient
{
    Task<UserBriefDto?> GetUserAsync(int userId, CancellationToken ct);
}

public class UserClient : IUserClient
{
    private readonly HttpClient _http;
    public UserClient(HttpClient http) => _http = http;

    public async Task<UserBriefDto?> GetUserAsync(int userId, CancellationToken ct)
    {
        // Assumes gateway or direct UserService base address set in Program.cs
        return await _http.GetFromJsonAsync<UserBriefDto>($"/users/{userId}", ct);
    }

    public static IAsyncPolicy<HttpResponseMessage> GetRetryPolicy() =>
        HttpPolicyExtensions
            .HandleTransientHttpError()
            .OrResult(msg => (int)msg.StatusCode == 404 || (int)msg.StatusCode == 429)
            .WaitAndRetryAsync(3, retry => TimeSpan.FromMilliseconds(200 * (retry + 1)));
}
