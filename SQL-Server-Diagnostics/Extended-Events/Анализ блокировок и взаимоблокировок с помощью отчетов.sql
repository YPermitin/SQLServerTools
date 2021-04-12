-- Анализ блокировок и взаимоблокировок с помощью отчетов

-- Предварительно нужно включить события отчетов заблокированных процессов
-- https://docs.microsoft.com/ru-ru/sql/relational-databases/event-classes/blocked-process-report-event-class?view=sql-server-ver15
EXEC sp_configure 'show advanced options', 1 ;
GO
RECONFIGURE ;
GO
EXEC sp_configure 'blocked process threshold', '5';
RECONFIGURE
GO

-- Далее создаем сессию сбор данных событий заблокированных процессов и взаимоблокировок

CREATE EVENT SESSION [BlocksAndDeadlocksAnalyse] ON SERVER
ADD EVENT sqlserver.blocked_process_report(
    ACTION(sqlserver.client_app_name,
           sqlserver.client_hostname,
           sqlserver.database_name)) ,
ADD EVENT sqlserver.xml_deadlock_report (
    ACTION(sqlserver.client_app_name,
           sqlserver.client_hostname,
           sqlserver.database_name))
ADD TARGET package0.asynchronous_file_target
(SET filename = N'LockAndDeadlockAnalyzeReports.xel',
     metadatafile = N'LockAndDeadlockAnalyzeReports.xem',
     max_file_size=(5000),
     max_rollover_files=10)
WITH (MAX_DISPATCH_LATENCY = 5SECONDS)
GO

/*
Результат сессии содержит подробную информацию о событиях блокировок и взаимоблокировок:
- Какая сессия какие блокировала
- Сколько происходило ожидание на блокироваке
- Какие запросы участвовали с обоих сторон
- И другая информация
*/

ALTER EVENT SESSION [BlocksAndDeadlocksAnalyse] ON SERVER 
 WITH (STARTUP_STATE=ON)
GO