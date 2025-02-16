using System.Net.Http;

namespace YPermitin.SQLCLR.ClickHouseClient.Http
{
    public interface IHttpClientFactory
    {
        HttpClient CreateClient(string name);
    }
}
