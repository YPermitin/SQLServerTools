# HttpHelper

Расширение SQL CLR для SQL Server c функциями работы с HTTP-запросами.

## Собранное решение

Собранную DLL для установки расширения SQLCLR можно скачать в разделе [релизы](https://github.com/YPermitin/SQLServerTools/releases).

## Обратная связь и новости

Вопросы, предложения и любую другую информацию [отправляйте на электронную почту](mailto:i.need.ypermitin@yandex.ru).

Новости по проектам или новым материалам в [Telegram-канале](https://t.me/TinyDevVault).

## Функциональность

В текущей версии расширение SQL CLR позволяет выполнять HTTP-запросы в скриптах T-SQL с обработкой результата.

В модуле **EntryHttpClient** содержатся следующие методы по категориям:

* **Catalogs** - базовая справочная информация.
	* **GetHttpMethods** - список доступных для использования методов HTTP-запросов.
	* **GetUserAgentExamples** - примеры заголовка "User-Agent"

* **SecurityProtocol** - управление протоколом безопасности для HTTP-запросов.
	* **GetAvailableSecurityProtocols** - список всех доступных протоколов безопасности.
	* **GetCurrentSecurityProtocols** - список протоколов безопасности, включенных для запросов в текущий момент времени.
	* **SetupSecurityProtocol** - процедура для установки использования протоколов безопасности. Задается через запятую в виде строки.

* **HttpQuery** - процедуры и функции для выполнения HTTP-запросов.
	* **HttpQuery** - функция для выполнения HTTP-запроса с параметрами:
		* **url** - адрес для выполнения запроса.
		* **method** - метод HTTP-запроса. Список доступных методов смотрите в функции  **GetHttpMethods**.
		* **headers** - XML с настройками заголовков запроса в виде:
		
		```xml
		<Headers>
			<Header Name="Accept">application/json</Header>
			<Header Name="Content-Type">application/json</Header>
		</Headers>
		```

		* **body** - тело запроса в виде строки.
		* **timeoutMs** - таймаут выполнения запроса в миллисекундах.
		* **ignoreCertificateValidation** - отключить проверку SSL-сертификатов.

		Результат возвращается в виде XML с информацией о результате выполнения запроса (тело, заголовки и др.). Например:

		```xml
		<Response>
			<QueryId>d3aec9f5-a7c0-42a0-8300-6bdec8f89605</QueryId>
			<CharacterSet>utf-8</CharacterSet>
			<ContentEncoding />
			<ContentLength>-1</ContentLength>
			<ContentType>application/json; charset=utf-8</ContentType>
			<CookiesCount>0</CookiesCount>
			<HeadersCount>4</HeadersCount>
			<Headers>
				<Header>
				<Name>Transfer-Encoding</Name>
				<Values>
					<Value>chunked</Value>
				</Values>
				</Header>
				<Header>
				<Name>Content-Type</Name>
				<Values>
					<Value>application/json; charset=utf-8</Value>
				</Values>
				</Header>
				<Header>
				<Name>Date</Name>
				<Values>
					<Value>Sun, 08 Sep 2024 08:49:58 GMT</Value>
				</Values>
				</Header>
				<Header>
				<Name>Server</Name>
				<Values>
					<Value>Kestrel</Value>
				</Values>
				</Header>
			</Headers>
			<IsFromCache>false</IsFromCache>
			<IsMutuallyAuthenticated>false</IsMutuallyAuthenticated>
			<LastModified>2024-09-08T13:49:58.7867246+05:00</LastModified>
			<Method>GET</Method>
			<ProtocolVersion>1.1</ProtocolVersion>
			<ResponseUri>https://api.tinydevtools.ru/myip</ResponseUri>
			<Server>Kestrel</Server>
			<StatusCode>OK</StatusCode>
			<StatusNumber>200</StatusNumber>
			<StatusDescription>OK</StatusDescription>
			<SupportsHeaders>true</SupportsHeaders>
			<Body>{"IP":"8.8.8.8","UserAgent":null,"ClientRequestHeaders":[{"Key":"Connection","Value":"keep-alive"},{"Key":"Host","Value":"api.tinydevtools.ru"},{"Key":"X-Forwarded-Host","Value":"api.tinydevtools.ru"},{"Key":"X-Forwarded-Server","Value":"api.tinydevtools.ru"},{"Key":"X-Original-For","Value":"127.0.0.1:54876"}]}</Body>
		</Response>
		```

		В случае возникновения ошибки выполнения будет возвращена информация об исключении:

		```xml
		<Exception>
			<QueryId>3b05bed5-7c71-4c7d-af63-0e0624d64fad</QueryId>
			<Message>Время ожидания операции истекло</Message>
			<StackTrace>   в System.Net.HttpWebRequest.GetResponse()
		в YPermitin.SQLCLR.HttpHelper.EntryHttpClient.HttpQuery(SqlChars url, SqlChars method, SqlXml headers, SqlInt32 timeoutMs, SqlBoolean ignoreCertificateValidation)</StackTrace>
			<Source>System</Source>
			<ToString>System.Net.WebException: Время ожидания операции истекло
		в System.Net.HttpWebRequest.GetResponse()
		в YPermitin.SQLCLR.HttpHelper.EntryHttpClient.HttpQuery(SqlChars url, SqlChars method, SqlXml headers, SqlInt32 timeoutMs, SqlBoolean ignoreCertificateValidation)</ToString>
		</Exception>
		```

		Имеет смысл проверять код возврата HTTP и при возникновении ошибки запроса обрабатывать его. То есть требуется обрабатывать не только ошибки выполнения, но и некорректные результаты выполнения HTTP-запросов.
		
	* **HttpQueryProc** - хранимая процедура для выполнения HTTP-запроса. Работает аналогично функции **HttpQuery**, кроме логирования запросов в базу данных. Возвращает XML с результатами работы той же структуры, что и в примере выше.  
		Поле **QueryId** позволяет идентифицировать запрос и получить по этому ID запись в таблице базы с логами.

* **LoggingToDatabase** - логирование выполняемых запросов в базу данных.
	* **EnableLoggingToDatabase** - включение логирования запросов. При включении в базе создается служебная таблица "HttpQueriesLog" для логирования. Логирование работает только при использовании процедуры **HttpQueryProc**. Т.к. **HttpQuery** является функцией, то запись логов в базу данных из нее недоступна.
	* **DisableLoggingToDatabase** - отключение логирования запросов.
	
* **Service** - служебные процедуры и функции для диагностики работы.
	* **GetHttpHelperInstanceId** - идентификатор текущего объекта расширения.
	* **GetHttpHelperInstanceCreateDateUtc** - дата создания по UTC текущего объекта расширения.
	* **GetClrVersion** - версия исполняемой среды CLR.

В целом этой функциональности достаточно для решения большинства задач по отправке HTTP-запросов.

## Окружение для разработки

Для окружение разработчика необходимы:

* [.NET Framework 4.8 SDK](https://support.microsoft.com/ru-ru/topic/microsoft-net-framework-4-8-автономный-установщик-для-windows-9d23f658-3b97-68ab-d013-aa3c3e7495e0)
* [.NET 6 SDK](https://dotnet.microsoft.com/en-us/download/dotnet/6.0)
* [Visual Studio 2022](https://visualstudio.microsoft.com/ru/vs/)
* [Microsoft SQL Server 2012+](https://www.microsoft.com/ru-ru/sql-server/sql-server-downloads)

## Состав проекта

Проекты и библиотеки в составе решения:

* **Libs** - библиотеки и вспомогательные проекты.

	* **HttpHelper** - проект библиотеки для расширения SQLCLR.

* **Tests** - модульные тесты и связанные проверки.

	* **HttpHelperTests** - проект тестов для библиотеки DevAdmHelpers.

## Установка

Для установки нужно выполнить несколько шагов:

1. Собрать проект **HttpHelper** в режиме **Release**.
2. Полученную DLL **HttpHelper.dll** скопировать на сервер, где установлен экземпляр SQL Server. Пусть для примера путь к DLL на сервере будет **"C:\Share\SQLCLR\HttpHelper.dll"**.
3. Выбрать базу для установки. Например, пусть она называется **PowerSQLCLR**.

4. [Включим интеграцию с CLR](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration/clr-integration-enabling?view=sql-server-ver16). Для упрощения настройки опустим некоторые аспекты безопасности и разрешим установку неподписанных расширений.

```sql
EXEC sp_configure 'clr enabled', 1;  
RECONFIGURE;  
GO  
ALTER DATABASE PowerSQLCLR SET TRUSTWORTHY ON;
GO
```

Также разрешим текущему пользователю доступ к внешним ресурсам. Например, это пользователь **YY\ypermitin**.

```sql
use [master]; GRANT EXTERNAL ACCESS ASSEMBLY TO [YY\ypermitin];
```

5. Далее добавим сборку SQLCLR в базу **PowerSQLCLR**.

```sql
USE [PowerSQLCLR]
GO

CREATE ASSEMBLY [HttpHelper]
	FROM 'C:\Share\SQLCLR\HttpHelper.dll'
	WITH PERMISSION_SET = UNSAFE;
GO
```

6. Теперь добавим функции, чтобы обращаться к методам сборки из T-SQL.

```sql
CREATE PROCEDURE [dbo].[sp_SetupSecurityProtocol](
	@protocols nvarchar(max)
)
AS EXTERNAL NAME [HttpHelper].[YPermitin.SQLCLR.HttpHelper.EntryHttpClient].[SetupSecurityProtocol];
GO

CREATE FUNCTION fn_GetHttpHelperInstanceCreateDateUTC() 
RETURNS datetime   
AS EXTERNAL NAME [HttpHelper].[YPermitin.SQLCLR.HttpHelper.EntryHttpClient].[GetHttpHelperInstanceCreateDateUtc];   
GO

CREATE FUNCTION fn_GetHttpHelperInstanceId() 
RETURNS uniqueidentifier   
AS EXTERNAL NAME [HttpHelper].[YPermitin.SQLCLR.HttpHelper.EntryHttpClient].[GetHttpHelperInstanceId];   
GO

CREATE FUNCTION fn_GetClrVersion() 
RETURNS nvarchar(50)   
AS EXTERNAL NAME [HttpHelper].[YPermitin.SQLCLR.HttpHelper.EntryHttpClient].[GetClrVersion];   
GO

CREATE FUNCTION fn_HttpQuery (
	@url nvarchar(max),
	@method nvarchar(150) = 'GET',
	@headers xml,
	@timeoutMs int = 0,
	@ignoreCertificateValidation bit = 0	
) 
RETURNS xml   
AS EXTERNAL NAME [HttpHelper].[YPermitin.SQLCLR.HttpHelper.EntryHttpClient].[HttpQuery];   
GO

CREATE FUNCTION [dbo].[fn_GetHttpMethods]()  
RETURNS TABLE (
	[Name] nvarchar(150)
)
AS   
EXTERNAL NAME [HttpHelper].[YPermitin.SQLCLR.HttpHelper.EntryHttpClient].[GetHttpMethods];
GO

CREATE FUNCTION [dbo].[fn_GetUserAgentExamples]()  
RETURNS TABLE (
	[Browser] nvarchar(max),
	[OperationSystem] nvarchar(max),
	[UserAgent] nvarchar(max)
)
AS   
EXTERNAL NAME [HttpHelper].[YPermitin.SQLCLR.HttpHelper.EntryHttpClient].[GetUserAgentExamples];
GO

CREATE FUNCTION [dbo].[fn_GetAvailableSecurityProtocols]()  
RETURNS TABLE (
	[Name] nvarchar(150)
)
AS   
EXTERNAL NAME [HttpHelper].[YPermitin.SQLCLR.HttpHelper.EntryHttpClient].[GetAvailableSecurityProtocols];
GO

CREATE FUNCTION [dbo].[fn_GetCurrentSecurityProtocols]()  
RETURNS TABLE (
	[Name] nvarchar(150)
)
AS   
EXTERNAL NAME [HttpHelper].[YPermitin.SQLCLR.HttpHelper.EntryHttpClient].[GetCurrentSecurityProtocols];
GO

CREATE FUNCTION fn_HttpGet 
(
	@url nvarchar(max)
)
RETURNS nvarchar(max)
AS
BEGIN
	DECLARE @response xml,
		@bodyJson nvarchar(max);

	SELECT @response = [dbo].[fn_HttpQuery] (
		@url,
		DEFAULT,
		null,
		60000,
		DEFAULT
	);

	SELECT @bodyJson = @response.value('(/Response/Body)[1]', 'nvarchar(max)');

	RETURN @bodyJson;
END
GO

CREATE PROCEDURE [dbo].[sp_EnableLoggingToDatabase]
AS EXTERNAL NAME [HttpHelper].[YPermitin.SQLCLR.HttpHelper.EntryHttpClient].[EnableLoggingToDatabase];
GO

CREATE PROCEDURE [dbo].[sp_DisableLoggingToDatabase]
AS EXTERNAL NAME [HttpHelper].[YPermitin.SQLCLR.HttpHelper.EntryHttpClient].[DisableLoggingToDatabase];
GO

CREATE PROCEDURE sp_HttpQueryProc (
	@url nvarchar(max),
	@method nvarchar(150) = 'GET',
	@headers xml,
	@timeoutMs int = 0,
	@ignoreCertificateValidation bit = 0,
	@result xml out
)  
AS EXTERNAL NAME [HttpHelper].[YPermitin.SQLCLR.HttpHelper.EntryHttpClient].[HttpQueryProc];   
GO
```

Полный скрипт команд T-SQL для установки [можно найти здесь](./Scripts/Deploy.sql).

7. Все готово для использования.

Ниже пример использования упрощенного синтаксиса через функцию **fn_HttpGet**:

```sql
USE [PowerSQLCLR]
GO

SELECT 
	*
FROM OPENJSON([dbo].[fn_HttpGet](N'https://api.tinydevtools.ru/myip')) WITH (
	IP nvarchar(max) '$.IP'
)
```

Этот же результат можно достичь при использовании процедуры **sp_HttpQueryProc**:

```sql
USE [PowerSQLCLR]
GO

DECLARE @url nvarchar(max) = N'https://api.tinydevtools.ru/myip';
DECLARE @method nvarchar(150) = 'GET';
DECLARE @headers xml = null;
DECLARE @timeoutMs int = 60000;
DECLARE @body nvarchar(max) = null;
DECLARE @ignoreCertificateValidation bit = 0;
DECLARE @result xml;

EXECUTE [dbo].[sp_HttpQueryProc] 
   @url
  ,@method
  ,@headers
  ,@body
  ,@timeoutMs
  ,@ignoreCertificateValidation
  ,@result OUTPUT;

SELECT 
	[IP]
FROM OPENJSON(@result.value('(/Response/Body)[1]', 'nvarchar(max)')) WITH (
	IP nvarchar(max) '$.IP'
)
```

В более сложных случаях, когда запрос должежн содержать тело запроса и различные заголовке, плюс использовать метод отличный от GET (например, POST) целесообразно использовать либо процедуру **sp_HttpQueryProc**, либо **fn_HttpQuery**, где все эти параметры можно указать. Вот пример POST-запроса в публичный тестовый REST API [petstore.swagger.io](https://petstore.swagger.io) для [создания пользователя](https://petstore.swagger.io/#/user/createUser).

```sql
USE [PowerSQLCLR]
GO

DECLARE @url nvarchar(max) = N'https://petstore.swagger.io/v2/user';
DECLARE @method nvarchar(150) = 'POST';
DECLARE @headers xml = N'
<Headers>
    <Header Name="Content-Type">application/json</Header>
</Headers>
';
DECLARE @timeoutMs int = 60000;
DECLARE @body nvarchar(max) = N'
{  
  "username": "Joe",
  "firstName": "Joe",
  "lastName": "Peshi",
  "email": "joe.peshi@yandex.ru",
  "password": "123456",
  "phone": "+1111111111",
  "userStatus": 1
}';
DECLARE @ignoreCertificateValidation bit = 0;
DECLARE @result xml;

EXECUTE [dbo].[sp_HttpQueryProc] 
   @url
  ,@method
  ,@headers
  ,@body
  ,@timeoutMs
  ,@ignoreCertificateValidation
  ,@result OUTPUT;

SELECT 
	*
FROM OPENJSON(@result.value('(/Response/Body)[1]', 'nvarchar(max)')) WITH (
	Message nvarchar(max) '$.message',
	Code nvarchar(max) '$.code'
)
```

Подробнее о настройках и разработке расширений SQLCLR можно найти материалы [здесь](../../).