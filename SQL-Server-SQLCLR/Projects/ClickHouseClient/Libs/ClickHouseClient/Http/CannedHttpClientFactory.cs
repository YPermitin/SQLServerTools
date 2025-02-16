using System;
using System.Net.Http;

namespace YPermitin.SQLCLR.ClickHouseClient.Http
{
    internal class CannedHttpClientFactory : IHttpClientFactory
    {
        private readonly HttpClient client;

        public CannedHttpClientFactory(HttpClient client)
        {
            this.client = client ?? throw new ArgumentNullException(nameof(client));
        }

        public HttpClient CreateClient(string name) => client;
    }

}