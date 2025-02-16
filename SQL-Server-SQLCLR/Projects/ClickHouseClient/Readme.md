# ClickHouseClient

Расширение SQL CLR для SQL Server для работы с СУБД ClickHouse из T-SQL в качестве клиента.

## Собранное решение

Собранную DLL для установки расширения SQLCLR можно скачать в разделе [релизы](https://github.com/YPermitin/SQLServerTools/releases).

## Обратная связь и новости

Вопросы, предложения и любую другую информацию [отправляйте на электронную почту](mailto:i.need.ypermitin@yandex.ru).

Новости по проектам или новым материалам в [Telegram-канале](https://t.me/TinyDevVault).

## Функциональность



## Окружение для разработки

Для окружение разработчика необходимы:

* [.NET Framework 4.8 SDK](https://support.microsoft.com/ru-ru/topic/microsoft-net-framework-4-8-автономный-установщик-для-windows-9d23f658-3b97-68ab-d013-aa3c3e7495e0)
* [.NET 6 SDK](https://dotnet.microsoft.com/en-us/download/dotnet/6.0)
* [Visual Studio 2022](https://visualstudio.microsoft.com/ru/vs/)
* [Microsoft SQL Server 2012+](https://www.microsoft.com/ru-ru/sql-server/sql-server-downloads)

## Состав проекта

Проекты и библиотеки в составе решения:

* **Apps** - библиотеки и вспомогательные проекты.

	* **ClickHouseClient.CLI** - консольное приложение для отладки использования расширения SQLCLR и демонстрации вызова методов расширения.

* **Libs** - библиотеки и вспомогательные проекты.

	* **ClickHouseClient** - клиентская библиотека [ClickHouse.Client от Oleg V. Kozlyuk](https://github.com/DarkWanderer/ClickHouse.Client), адаптированная под .NET Framework 4.8 для возможности запуска в среде .NET Framework, совместимой с SQLCLR.
	* **ClickHouseClient.Entry** - библиотека расширение SQLCLR для работы с ClickHouse из T-SQL.

## Установка

Для установки на стороне SQL Server нужно выполнить несколько шагов:

1. Собрать проект **ClickHouseClient.Entry** в режиме **Release**.
2. Полученную DLL **ClickHouseClient.Entry.dll** и ВСЕ другие файлы в каталоге сборки скопировать на сервер, где установлен экземпляр SQL Server. Пусть для примера путь к DLL на сервере будет **"C:\Share\SQLCLR\ClickHouseClient.Entry.dll"**. Там же в каталоге будут файлы **ClickHouseClient.dll**, **Newtonsoft.Json.dll**, **NodaTime.dll**.
3. Выбрать базу для установки. Например, пусть она называется **PowerSQLCLR**.

4. [Включим интеграцию с CLR](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration/clr-integration-enabling?view=sql-server-ver16), а также настроим права, установим зависимости от глобальных сборок из GAC .NET Framwork, а после создадим объекты процедур и функций для работы с расширениями.

```sql
-- Этап 1. Включаем поддержку SQLCLR для инстанса SQL Server и доверие для базы данных.
EXEC sp_configure 'clr enabled', 1;  
RECONFIGURE;  
GO  
ALTER DATABASE [PowerSQLCLR] SET TRUSTWORTHY ON;
GO

-- Этап 2. Подготавливаем сертификаты Microsoft для сборок .NET Framework.
-- Этот шаг необходим для подключения стандартных сборок .NET
-- к инстансу SQL Server. Для добавленного сертификата создаем
-- служебную учетную запись и разрешаем работать со сборками.
USE [master];

CREATE CERTIFICATE [MS.NETcer]
FROM EXECUTABLE FILE =
   'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\System.Net.Http.dll';
GO
CREATE LOGIN [MS.NETcer] FROM CERTIFICATE [MS.NETcer];
GO 
GRANT UNSAFE ASSEMBLY TO [MS.NETcer];
GO
DENY CONNECT SQL TO [MS.NETcer]
GO
ALTER LOGIN [MS.NETcer] DISABLE
GO

-- Этап 3. Добавляем стандартные сборки .NET Framework в служебную базу.
-- Эти сборки необходимы для работы клиента ClickHouse.
USE [PowerSQLCLR];

CREATE ASSEMBLY [System.Net.Http]
FROM 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\System.Net.Http.dll'
WITH PERMISSION_SET = UNSAFE;
GO

CREATE ASSEMBLY [System.Web]
FROM 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\System.Web.dll'
WITH PERMISSION_SET = UNSAFE;
GO

-- Этап 4. Удаляем объекты расширения SQLCLR клиента ClickHouse,
-- если они уже существуют. Ниже они будут созданы заново.
USE [PowerSQLCLR];
DROP FUNCTION IF EXISTS [dbo].[fn_CHExecuteScalar];
DROP FUNCTION IF EXISTS [dbo].[fn_CHExecuteSimple];
DROP FUNCTION IF EXISTS [dbo].[fn_CHGetCreateTempDbTableCommand];
DROP PROCEDURE IF EXISTS [dbo].[sp_CHExecuteToTempTable];
DROP PROCEDURE IF EXISTS [dbo].[sp_CHExecuteToGlobalTempTable];
DROP PROCEDURE IF EXISTS [dbo].[sp_CHExecuteStatement];
DROP PROCEDURE IF EXISTS [dbo].[sp_CHExecuteBulkInsertFromTempTable];
DROP ASSEMBLY IF EXISTS [ClickHouseClient.Entry];
DROP ASSEMBLY IF EXISTS [ClickHouseClient];
GO

-- Этап 5. Создаем сборку клиента ClickHouse и расширения SQLCLR в служебной базе,
-- а также все объекты для работы с ней.
-- ВНИМАНИЕ!!! Путь к файлу DLL нужно актуализировать под ваше окружение.
USE [PowerSQLCLR];

CREATE ASSEMBLY [ClickHouseClient]
	FROM 'C:\Share\SQLCLR\ClickHouseClient.dll'
	WITH PERMISSION_SET = UNSAFE;
GO

CREATE ASSEMBLY [ClickHouseClient.Entry]
	FROM 'C:\Share\SQLCLR\ClickHouseClient.Entry.dll'
	WITH PERMISSION_SET = UNSAFE;
GO

CREATE FUNCTION [fn_CHExecuteScalar](
	@connectionString nvarchar(max),
	@queryText nvarchar(max)
) 
RETURNS nvarchar(max)   
AS EXTERNAL NAME [ClickHouseClient.Entry].[YPermitin.SQLCLR.ClickHouseClient.Entry.EntryClickHouseClient].[ExecuteScalar];   
GO

CREATE FUNCTION [dbo].[fn_CHExecuteSimple](
	@connectionString nvarchar(max),
	@queryText nvarchar(max)
)  
RETURNS TABLE (
	[ResultValue] nvarchar(max)
)
AS   
EXTERNAL NAME [ClickHouseClient.Entry].[YPermitin.SQLCLR.ClickHouseClient.Entry.EntryClickHouseClient].[ExecuteSimple];
GO

CREATE FUNCTION [fn_CHGetCreateTempDbTableCommand](
	@connectionString nvarchar(max),
	@queryText nvarchar(max),
	@tempTableName nvarchar(max)
) 
RETURNS nvarchar(max)   
AS EXTERNAL NAME [ClickHouseClient.Entry].[YPermitin.SQLCLR.ClickHouseClient.Entry.EntryClickHouseClient].[GetCreateTempDbTableCommand];   
GO

CREATE PROCEDURE [dbo].[sp_CHExecuteStatement]
(
	@connectionString nvarchar(max),
	@queryText nvarchar(max)
)
AS EXTERNAL NAME [ClickHouseClient.Entry].[YPermitin.SQLCLR.ClickHouseClient.Entry.EntryClickHouseClient].[ExecuteStatement];
GO

CREATE PROCEDURE [dbo].[sp_CHExecuteToTempTable]
(
	@connectionString nvarchar(max),
	@queryText nvarchar(max),
	@tempTableName nvarchar(max)
)
AS EXTERNAL NAME [ClickHouseClient.Entry].[YPermitin.SQLCLR.ClickHouseClient.Entry.EntryClickHouseClient].[ExecuteToTempTable];
GO

CREATE PROCEDURE [dbo].[sp_CHExecuteToGlobalTempTable]
(
	@connectionString nvarchar(max),
	@queryText nvarchar(max),
	@tempTableName nvarchar(max),
	@sqlServerConnectionString nvarchar(max)
)
AS EXTERNAL NAME [ClickHouseClient.Entry].[YPermitin.SQLCLR.ClickHouseClient.Entry.EntryClickHouseClient].[ExecuteToGlobalTempTable];
GO

CREATE PROCEDURE [dbo].[sp_CHExecuteBulkInsertFromTempTable]
(
	@connectionString nvarchar(max),
	@sourceTempTableName nvarchar(max),
	@destinationTableName nvarchar(max)
)
AS EXTERNAL NAME [ClickHouseClient.Entry].[YPermitin.SQLCLR.ClickHouseClient.Entry.EntryClickHouseClient].[ExecuteBulkInsertFromTempTable];
GO
```

После все будет готово для использования расширения.

## Примеры работы

Несколько примеров работы с расширением после установки из T-SQL.

* Получаем версию ClickHouse.

```sql
SELECT [PowerSQLCLR].[dbo].[fn_CHExecuteScalar](
		-- Строка подключения
		'Host=yy-comp;Port=8123;Username=default;password=;Database=default;',
		-- текст запроса
		'select version()')

-- Пример результата:
-- 25.2.1.2434
```

* Пример выполнения простого запроса, который возвращает одну колоноку. Для возврата нескольких колонок используется кортеж, сериализованный в JSON. В T-SQL полученные элементы JSON парсятся конструкциями SQL Server.

```sql
select
	JSON_VALUE(d.ResultValue, '$.Item1') AS [DatabaseName],
	JSON_VALUE(d.ResultValue, '$.Item2') [Engine],
	JSON_VALUE(d.ResultValue, '$.Item3') AS [DataPath],
	CAST(JSON_VALUE(d.ResultValue, '$.Item4') AS uniqueidentifier) AS [UUID]
from [PowerSQLCLR].[dbo].fn_CHExecuteSimple(
	-- Строка подключения
	'Host=yy-comp;Port=8123;Username=default;password=;Database=default;',
	-- Запрос
	'
SELECT
	tuple(name, engine, data_path,uuid)
FROM `system`.`databases`
'
) d
```

* Создаем временную таблицу и сохраняем в нее результат запроса.

```sql
IF(OBJECT_ID('tempdb..#logs') IS NOT NULL)
    DROP TABLE #logs;
CREATE TABLE #logs
(
    [EventTime] datetime2(0),
    [Query] nvarchar(max),
    [Tables] nvarchar(max),
    [QueryId] uniqueidentifier
);

EXECUTE [PowerSQLCLR].[dbo].[sp_CHExecuteToTempTable]
		-- Строка подключения
		'Host=yy-comp;Port=8123;Username=default;password=;Database=default;',
		-- Текст запроса
		'
select
	event_time,
	query,
	tables,
	query_id
from `system`.query_log
limit 1000
',
		-- Имя временной таблицы для сохранения результата
		'#logs';

-- Считываем результат
SELECT * FROM #logs
```

* Создаем ГЛОБАЛЬНУЮ временную таблицу и сохраняем в нее результат запроса.

```sql
IF(OBJECT_ID('tempdb..##logs') IS NOT NULL)
    DROP TABLE ##logs;
CREATE TABLE ##logs
(
    [EventTime] datetime2(0),
    [Query] nvarchar(max),
    [Tables] nvarchar(max),
    [QueryId] uniqueidentifier
);

EXECUTE [PowerSQLCLR].[dbo].[sp_CHExecuteToGlobalTempTable]
		-- Строка подключения
		'Host=yy-comp;Port=8123;Username=default;password=;Database=default;',
		-- Текст запроса
		'
select
	event_time,
	query,
	tables,
	query_id
from `system`.query_log
limit 1000
',
		-- Имя временной таблицы для сохранения результата
		'##logs',
		-- Строка подключения к SQL Server для BULK INSERT.
		-- Строка контекстного подключения для этого не подходит.
		'server=localhost;database=master;trusted_connection=true';

-- Считываем результат
SELECT * FROM ##logs
```

При использовании глобальной таблицы можно достичь более высокой производительности за счет переноса в нее данных через BULK INSERT (если указана строка подключения к SQL Server).

* Запуск произвольной команды без возвращения результата.

```sql
EXECUTE [PowerSQLCLR].[dbo].[sp_CHExecuteStatement]
	-- Строка подключения
	'Host=yy-comp;Port=8123;Username=default;password=;Database=default;',
	-- Запрос
	'
CREATE TABLE IF NOT EXISTS SimpleTable
(
	Id UInt64,
	Period datetime DEFAULT now(),
	Name String
)
ENGINE = MergeTree
ORDER BY Id;
'
```