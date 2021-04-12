-- Получаем последний текст запроса по идентификатору соединения

DECLARE @sqltext VARBINARY(128)
SELECT @sqltext = sql_handle
FROM sys.sysprocesses
WHERE spid = 55
SELECT TEXT
FROM sys.dm_exec_sql_text(@sqltext)