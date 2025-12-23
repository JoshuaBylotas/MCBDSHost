using System.Net.Http;
using System.Net.Http.Json;
using System.Threading.Tasks;

namespace MCBDS.ClientUI.Web.Services;

public class BedrockApiService
{
    private readonly HttpClient _httpClient;

    public BedrockApiService(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<string?> GetLogAsync()
    {
        return await _httpClient.GetStringAsync("/api/runner/log");
    }

    public async Task<string?> SendLineAsync(string line)
    {
        var response = await _httpClient.PostAsJsonAsync("/api/runner/send", new { line });
        return response.IsSuccessStatusCode ? await response.Content.ReadAsStringAsync() : null;
    }

    public async Task<string?> RestartAsync()
    {
        var response = await _httpClient.PostAsync("/api/runner/restart", null);
        return response.IsSuccessStatusCode ? await response.Content.ReadAsStringAsync() : null;
    }
}
