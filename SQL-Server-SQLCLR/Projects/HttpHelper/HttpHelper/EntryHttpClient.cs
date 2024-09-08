using System;
using System.Collections;
using Microsoft.SqlServer.Server;
using System.Data.SqlTypes;
using System.Net;
using System.IO;
using System.Collections.Generic;
using System.Threading;
using YPermitin.SQLCLR.HttpHelper.Models;
using System.Xml.Linq;
using System.Data.SqlClient;
using System.Text;
using System.Xml;

namespace YPermitin.SQLCLR.HttpHelper
{
    public sealed class EntryHttpClient : EntryBase
    {
        private static readonly Guid InstanceId = Guid.NewGuid();
        private static readonly DateTime InstanceCreateDateUtc = DateTime.UtcNow;
        private static long _loggingToDatabase = 0;

        static EntryHttpClient()
        {
            InitSecurityProtocol();
        }

        #region Service

        [SqlFunction(DataAccess = DataAccessKind.Read)]
        public static SqlGuid GetHttpHelperInstanceId()
        {
            return new SqlGuid(InstanceId.ToByteArray());
        }

        [SqlFunction(DataAccess = DataAccessKind.Read)]
        public static SqlDateTime GetHttpHelperInstanceCreateDateUtc()
        {
            return new SqlDateTime(InstanceCreateDateUtc);
        }

        [SqlFunction(DataAccess = DataAccessKind.Read)]
        public static SqlChars GetClrVersion()
        {
            var version = Environment.Version.ToString();

            return new SqlChars(version);
        }

        #endregion

        #region GetHttpMethods

        [SqlFunction(
            FillRowMethodName = "GetHttpMethodsFillRow",
            SystemDataAccess = SystemDataAccessKind.Read,
            DataAccess = DataAccessKind.Read)]
        public static IEnumerable GetHttpMethods()
        {
            List<string> httpMethods = new List<string>
            {
                "GET",
                "HEAD",
                "POST",
                "PUT",
                "DELETE",
                "CONNECT",
                "OPTIONS",
                "TRACE",
                "PATCH",
            };

            return httpMethods;
        }
        public static void GetHttpMethodsFillRow(object methodNameAsString, out SqlChars methodName)
        {
            methodName = new SqlChars((string)methodNameAsString);
        }

        #endregion

        #region GetUserAgentExamples

        [SqlFunction(
            FillRowMethodName = "GetUserAgentExamplesFillRow",
            SystemDataAccess = SystemDataAccessKind.Read,
            DataAccess = DataAccessKind.Read)]
        public static IEnumerable GetUserAgentExamples()
        {
            List<UserAgentExample> httpMethods = new List<UserAgentExample>
            {
                new UserAgentExample()
                {
                    Browser = "Microsoft Edge",
                    OperationSystem = "Windows",
                    UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36 Edg/119.0.0.0",
                },
                new UserAgentExample()
                {
                    Browser = "Google Chrome",
                    OperationSystem = "Mac OS X",
                    UserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36",
                },
                new UserAgentExample()
                {
                    Browser = "Google Chrome",
                    OperationSystem = "WindowsWindows",
                    UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36",
                },
                new UserAgentExample()
                {
                    Browser = "Mozilla Firefox",
                    OperationSystem = "Windows",
                    UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/119.0",
                },
                new UserAgentExample()
                {
                    Browser = "Safari",
                    OperationSystem = "iPhone (iOS)",
                    UserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Mobile/15E148 Safari/604.1",
                },
                new UserAgentExample()
                {
                    Browser = "Safari",
                    OperationSystem = "iPad (iPadOS)",
                    UserAgent = "Mozilla/5.0 (iPad; CPU OS 16_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Mobile/15E148 Safari/604.1",
                },
                new UserAgentExample()
                {
                    Browser = "Chrome",
                    OperationSystem = "Android",
                    UserAgent = "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36",
                },
                new UserAgentExample()
                {
                    Browser = "Chrome (on Samsung Galaxy S22 5G)",
                    OperationSystem = "Android",
                    UserAgent = "Mozilla/5.0 (Linux; Android 13; SM-S901B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36",
                }
            };

            return httpMethods;
        }
        public static void GetUserAgentExamplesFillRow(object userAgentExample, 
            out SqlChars browser, out SqlChars operationSystem, out SqlChars userAgent)
        {
            var userAgentExampleObject = (UserAgentExample)userAgentExample;
            browser = new SqlChars(userAgentExampleObject.Browser);
            operationSystem = new SqlChars(userAgentExampleObject.OperationSystem);
            userAgent = new SqlChars(userAgentExampleObject.UserAgent);
        }

        #endregion

        #region SecurityProtocol

        [SqlFunction(
            FillRowMethodName = "GetAvailableSecurityProtocolsFillRow",
            SystemDataAccess = SystemDataAccessKind.Read,
            DataAccess = DataAccessKind.Read)]
        public static IEnumerable GetAvailableSecurityProtocols()
        {
            List<string> securityProtocols = new List<string>();

            var availableProtocols = Enum.GetValues(SecurityProtocolType.SystemDefault.GetType());
            foreach (var availableProtocol in availableProtocols)
            {
                securityProtocols.Add(availableProtocol.ToString());
            }

            return securityProtocols;
        }
        public static void GetAvailableSecurityProtocolsFillRow(object securityProtocolAsString, out SqlChars securityProtocol)
        {
            securityProtocol = new SqlChars((string)securityProtocolAsString);
        }

        [SqlFunction(
            FillRowMethodName = "GetCurrentSecurityProtocolsFillRow",
            SystemDataAccess = SystemDataAccessKind.Read,
            DataAccess = DataAccessKind.Read)]
        public static IEnumerable GetCurrentSecurityProtocols()
        {
            List<string> securityProtocols = new List<string>();

            var availableProtocols = Enum.GetValues(SecurityProtocolType.SystemDefault.GetType());
            foreach (var availableProtocol in availableProtocols)
            {
                if (ServicePointManager.SecurityProtocol.HasFlag((Enum)availableProtocol))
                {
                    securityProtocols.Add(availableProtocol.ToString());
                }
            }

            return securityProtocols;
        }
        public static void GetCurrentSecurityProtocolsFillRow(object securityProtocolAsString, out SqlChars securityProtocol)
        {
            securityProtocol = new SqlChars((string)securityProtocolAsString);
        }

        [SqlProcedure]
        public static void SetupSecurityProtocol(SqlChars protocols)
        {
            string protocolsAsString = new string(protocols.Value);

            SecurityProtocolType? securityProtocol = null;
            foreach (var protocol in protocolsAsString.Split(','))
            {
                if (securityProtocol == null)
                {
                    securityProtocol = (SecurityProtocolType)Enum.Parse(typeof(SecurityProtocolType), protocol);
                }
                else
                {
                    securityProtocol = securityProtocol | (SecurityProtocolType)Enum.Parse(typeof(SecurityProtocolType), protocol);
                }

            }

            if (securityProtocol == null)
            {
                ServicePointManager.SecurityProtocol = SecurityProtocolType.SystemDefault;
            }
            else
            {
                ServicePointManager.SecurityProtocol = (SecurityProtocolType)securityProtocol;
            }
        }

        #endregion

        #region LoggingToDatabase

        [SqlProcedure]
        public static void EnableLoggingToDatabase()
        {
            var loggingEnabled = Interlocked.Read(ref _loggingToDatabase) == 1;

            if (!loggingEnabled)
            {
                Interlocked.Exchange(ref _loggingToDatabase, 1);

                using (SqlConnection connection = new SqlConnection(ConnectionString))
                {
                    connection.Open();

                    var command = connection.CreateCommand();
                    command.CommandText =
@"IF(OBJECT_ID('dbo.HttpQueriesLog') IS NULL)
BEGIN
	CREATE TABLE [dbo].[HttpQueriesLog](
		[Id] [uniqueidentifier] NOT NULL,
		[Period] [datetime2](7) NOT NULL,
		[Response] [xml] NULL,
		[Exception] [xml] NULL,
	 CONSTRAINT [PK_HttpQueriesLog] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	) ON [PRIMARY]
	) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END";
                    command.ExecuteNonQuery();
                }
            }
        }

        [SqlProcedure]
        public static void DisableLoggingToDatabase()
        {
            Interlocked.Exchange(ref _loggingToDatabase, 0);
        }

        #endregion

        #region HttpQuery

        [SqlProcedure]
        public static void HttpQueryProc(SqlChars url, SqlChars method, SqlXml headers, SqlChars body,
            SqlInt32 timeoutMs, SqlBoolean ignoreCertificateValidation, out SqlXml result)
        {
            result = HttpQuery(url, method, headers, body, timeoutMs, ignoreCertificateValidation);

            var loggingEnabled = Interlocked.Read(ref _loggingToDatabase) == 1;
            if (loggingEnabled)
            {
                using (SqlConnection connection = new SqlConnection(ConnectionString))
                {
                    connection.Open();

                    var command = connection.CreateCommand();
                    command.CommandText =
                        @"
INSERT INTO [dbo].[HttpQueriesLog]
           ([Id]
           ,[Period]
           ,[Response]
           ,[Exception])
     VALUES
           (@ID
           ,GETDATE()
           ,@RESPONSE
           ,@EXCEPTION)";

                    command.Parameters.AddWithValue("@ID", Guid.NewGuid());

                    XmlDocument xmlDocument = new XmlDocument();
                    xmlDocument.LoadXml(result.Value);
                    XmlNodeList nodeException = xmlDocument.SelectNodes("//Exception");
                    if (nodeException == null || nodeException.Count == 0)
                    {
                        command.Parameters.AddWithValue("@RESPONSE", result);
                        command.Parameters.AddWithValue("@EXCEPTION", DBNull.Value);
                    }
                    else
                    {
                        command.Parameters.AddWithValue("@RESPONSE", DBNull.Value);
                        command.Parameters.AddWithValue("@EXCEPTION", result);
                    }
                    
                    command.ExecuteNonQuery();
                }
            }
        }

        [SqlFunction(DataAccess = DataAccessKind.Read)]
        public static SqlXml HttpQuery(SqlChars url, SqlChars method, SqlXml headers, SqlChars body,
            SqlInt32 timeoutMs, SqlBoolean ignoreCertificateValidation)
        {
            Guid queryId = Guid.NewGuid();
            XElement returnXml;

            try
            {
                string urlAsString = new string(url.Value);
                var queryUrl = new Uri(urlAsString);

                HttpWebRequest request = (HttpWebRequest)WebRequest.Create(queryUrl);

                #region ignoreCertificateValidation // Отключение проверки сертификата

                if (ignoreCertificateValidation.Value)
                {
                    request.ServerCertificateValidationCallback +=
                        (sender, certificate, chain, sslPolicyErrors) => true;
                }

                #endregion

                #region method // Метод HTTP-запроса

                if (method == null)
                {
                    method = new SqlChars("GET");
                }

                request.Method = new string(method.Value);

                #endregion

                #region headers // Заголовки HTTP-запроса

                bool contentLengthSetFromHeaders = false;
                bool contentTypeSetFromHeaders = false;
                if (headers != null && !headers.IsNull)
                {
                    foreach (XElement headerElement in XElement.Parse(headers.Value).Descendants())
                    {
                        // Retrieve headers name and value
                        var headerName = headerElement.Attribute("Name")?.Value ?? string.Empty;
                        if (string.IsNullOrEmpty(headerName))
                            continue;

                        var headerValue = headerElement.Value;

                        switch (headerName.ToUpperInvariant())
                        {
                            case "ACCEPT":
                                request.Accept = headerValue;
                                break;
                            case "CONNECTION":
                                request.Connection = headerValue;
                                break;
                            case "CONTENT-LENGTH":
                                request.ContentLength = long.Parse(headerValue);
                                contentLengthSetFromHeaders = true;
                                break;
                            case "CONTENT-TYPE":
                                request.ContentType = headerValue;
                                contentTypeSetFromHeaders = true;
                                ;
                                break;
                            case "DATE":
                                request.Date = DateTime.Parse(headerValue);
                                break;
                            case "EXPECT":
                                request.Expect = headerValue;
                                break;
                            case "HOST":
                                request.Host = headerValue;
                                break;
                            case "IF-MODIFIED-SINCE":
                                request.IfModifiedSince = DateTime.Parse(headerValue);
                                break;
                            case "RANGE":
                                var parts = headerValue.Split('-');
                                request.AddRange(int.Parse(parts[0]), int.Parse(parts[1]));
                                break;
                            case "REFERER":
                                request.Referer = headerValue;
                                break;
                            case "TRANSFER-ENCODING":
                                request.TransferEncoding = headerValue;
                                break;
                            case "USER-AGENT":
                                request.UserAgent = headerValue;
                                break;
                            default:
                                request.Headers.Add(headerName, headerValue);
                                break;
                        }
                    }
                }

                #endregion

                #region timeoutMs // Таймаут выполнения запроса

                if (!timeoutMs.IsNull && timeoutMs.Value >= 0)
                {
                    request.Timeout = timeoutMs.Value;
                }

                #endregion

                #region RequestBody // Тело запроса

                if (body != null && !body.IsNull)
                {
                    string bodyAsString = new string(body.Value);
                    if (!string.IsNullOrEmpty(bodyAsString))
                    {
                        var bodyAsBytes = Encoding.UTF8.GetBytes(bodyAsString);
                        if (!contentLengthSetFromHeaders)
                        {
                            request.ContentLength = bodyAsBytes.Length;
                        }
                        if (!contentTypeSetFromHeaders)
                        {
                            request.ContentType = "application/x-www-form-urlencoded";
                        }

                        using (var requestStream = request.GetRequestStream())
                        {
                            requestStream.Write(bodyAsBytes, 0, bodyAsBytes.Length);
                        }
                    }
                }

                #endregion

                try
                {
                    string responseBodyAsString;
                    var response = (HttpWebResponse)request.GetResponse();
                    using (Stream newStream = response.GetResponseStream())
                    {
                        using (var reader = new StreamReader(newStream))
                        {
                            responseBodyAsString = reader.ReadToEnd();
                        }
                    }

                    var responseHeadersXml = new XElement("Headers");
                    var responseHeaders = response.Headers;
                    for (int i = 0; i < responseHeaders.Count; ++i)
                    {
                        // Get values for this header
                        var valuesXml = new XElement("Values");
                        foreach (string value in responseHeaders.GetValues(i))
                        {
                            valuesXml.Add(new XElement("Value", value));
                        }

                        // Add this header with its values to the headers xml
                        responseHeadersXml.Add(
                            new XElement("Header",
                                new XElement("Name", responseHeaders.GetKey(i)),
                                valuesXml
                            )
                        );
                    }

                    returnXml = new XElement("Response",
                        new XElement("QueryId", queryId.ToString()),
                        new XElement("CharacterSet", response.CharacterSet),
                        new XElement("ContentEncoding", response.ContentEncoding),
                        new XElement("ContentLength", response.ContentLength),
                        new XElement("ContentType", response.ContentType),
                        new XElement("CookiesCount", response.Cookies.Count),
                        new XElement("HeadersCount", response.Headers.Count),
                        responseHeadersXml,
                        new XElement("IsFromCache", response.IsFromCache),
                        new XElement("IsMutuallyAuthenticated", response.IsMutuallyAuthenticated),
                        new XElement("LastModified", response.LastModified),
                        new XElement("Method", response.Method),
                        new XElement("ProtocolVersion", response.ProtocolVersion),
                        new XElement("ResponseUri", response.ResponseUri),
                        new XElement("Server", response.Server),
                        new XElement("StatusCode", response.StatusCode),
                        new XElement("StatusNumber", ((int)response.StatusCode)),
                        new XElement("StatusDescription", response.StatusDescription),
                        new XElement("SupportsHeaders", response.SupportsHeaders),
                        new XElement("Body", responseBodyAsString)
                    );

                    SqlXml result;
                    using (var responseAsStream = returnXml.CreateReader())
                    {
                        result = new SqlXml(responseAsStream);
                    }
                    
                    return result;
                }
                catch (WebException we)
                {
                    if (we.Response != null)
                    {
                        // If we got a response, generate return XML with the HTTP status code 
                        HttpWebResponse errorResponse = we.Response as HttpWebResponse;
                        returnXml =
                            new XElement("Response",
                                new XElement("QueryId", queryId.ToString()),
                                new XElement("Server", errorResponse.Server),
                                new XElement("StatusCode", errorResponse.StatusCode),
                                new XElement("StatusNumber", ((int)errorResponse.StatusCode)),
                                new XElement("StatusDescription", errorResponse.StatusDescription)
                            );
                    }
                    else
                    {
                        // Если ошибка не содержит дополнительные сведения о сбойном запросе,
                        // то обрабатываем исключение в другоим месте.
                        throw;
                    }
                }
            }
            catch (Exception ex)
            {
                returnXml = GetXmlFromException(ex, queryId);
            }

            return new SqlXml(returnXml.CreateReader());
        }

        #endregion

        private static void InitSecurityProtocol()
        {
            try
            {
                ServicePointManager.SecurityProtocol = SecurityProtocolType.Ssl3 | SecurityProtocolType.Tls |
                                                       SecurityProtocolType.Tls11 | SecurityProtocolType.Tls12;
            }
            catch
            {
                ServicePointManager.SecurityProtocol = SecurityProtocolType.SystemDefault;
            }
        }

        private static XElement GetXmlFromException(Exception ex, Guid queryId)
        {
            var returnXml =
                new XElement("Exception",
                    new XElement("QueryId", queryId.ToString()),
                    new XElement("Message", ex.Message),
                    new XElement("StackTrace", ex.StackTrace),
                    new XElement("Source", ex.Source),
                    new XElement("ToString", ex.ToString())
                );

            if (ex.InnerException != null)
            {
                returnXml.Add(new XElement("InnerException", GetXmlFromException(ex.InnerException, queryId)));
            }

            return returnXml;
        }
    }
}
