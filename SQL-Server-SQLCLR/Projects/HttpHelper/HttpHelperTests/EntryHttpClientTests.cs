using System.Data.SqlTypes;
using System.Xml;
using YPermitin.SQLCLR.HttpHelper;

namespace HttpHelperTests
{
    public class EntryHttpClientTests
    {
        [Fact]
        public void HttpQueryTest()
        {
            string url = "https://api.tinydevtools.ru/myip";
            XmlDocument headersXml = new XmlDocument();
            headersXml.LoadXml(
@"<Headers>
    <Header Name=""Accept"">application/json</Header>
</Headers>"
            );
            XmlReader headersXmlReader = new XmlNodeReader(headersXml);

            var responseBody = EntryHttpClient.HttpQuery(
                url: new SqlChars(url),
                method: new SqlChars("GET"),
                ignoreCertificateValidation: new SqlBoolean(false),
                body: null,
                timeoutMs: 60000,
                headers: new SqlXml(headersXmlReader));

            var responseBodyAsString = new string(responseBody.Value);

            Assert.NotNull(responseBodyAsString);
        }

        [Fact]
        public void HttpQueryPostTest()
        {
            string url = "https://petstore.swagger.io/v2/user";

            XmlDocument headersXml = new XmlDocument();
            headersXml.LoadXml(
@"<Headers>
    <Header Name=""Accept"">application/json</Header>
    <Header Name=""Content-Type"">application/json</Header>
</Headers>"
            );
            XmlReader headersXmlReader = new XmlNodeReader(headersXml);

            var responseBody = EntryHttpClient.HttpQuery(
                url: new SqlChars(url),
                method: new SqlChars("POST"),
                ignoreCertificateValidation: new SqlBoolean(false),
                body: new SqlChars(@"
{  
  ""username"": ""Joe"",
  ""firstName"": ""Joe"",
  ""lastName"": ""Peshi"",
  ""email"": ""joe.peshi@yandex.ru"",
  ""password"": ""123456"",
  ""phone"": ""+1111111111"",
  ""userStatus"": 1
}"
                ),
                timeoutMs: 60000,
                headers: new SqlXml(headersXmlReader));

            var responseBodyAsString = new string(responseBody.Value);

            Assert.NotNull(responseBodyAsString);
        }
        
        [Fact]
        public void GetCurrentSecurityProtocolsTest()
        {
            var protocolItems = EntryHttpClient.GetCurrentSecurityProtocols();

            Assert.NotNull(protocolItems);
        }
    }
}