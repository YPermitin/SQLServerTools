/*
Пример создания связанного сервера с базой данных ClickHouse и использование ее в запросах.

Пример основан на информации из репозитория ODBC-драйвера для ClickHouse:
https://github.com/ClickHouse/clickhouse-odbc/blob/master/test/mssql.linked.server.sql
*/

-- 1. Создаем связанный сервер и задаем настройки подключения
-- EXEC master.dbo.sp_dropserver N'clickhouse_with_love';
EXEC master.dbo.sp_addlinkedserver
        @server = N'clickhouse_with_love'
       ,@srvproduct=N'Clickhouse'
       ,@provider=N'MSDASQL'
       ,@provstr=N'Driver={ClickHouse ODBC Driver (Unicode)};SERVER=localhost;DATABASE=system;stringmaxlength=8000;'

-- 2. Разрешаем RPC
EXEC sp_serveroption 'clickhouse_link_test','rpc','true';
EXEC sp_serveroption 'clickhouse_link_test','rpc out','true';

-- 3. Примеры простых запросов
EXEC('select * from system.numbers limit 10;') at [clickhouse_with_love];
select count(*) as cnt from OPENQUERY(clickhouse_with_love, 'select * from system.numbers limit 10;') 