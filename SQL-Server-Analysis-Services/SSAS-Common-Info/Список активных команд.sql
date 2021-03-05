-- Список всех запущенных в данный момент команд на сервере, включая команды, выполняемые самим сервером.
-- https://docs.microsoft.com/ru-ru/openspecs/sql_server_protocols/ms-ssas/c36a7837-027d-49e0-9df8-bb1f5246a7c4

SELECT 
	SESSION_SPID AS [Идентификатор сессии],
	SESSION_COMMAND_COUNT AS [Количество команд],
	COMMAND_START_TIME AS [Время запуска команды],
	COMMAND_ELAPSED_TIME_MS AS [Время выполнения (мс)],
	COMMAND_CPU_TIME_MS AS [CPU (мс)],
	COMMAND_READS AS [Чтений],
	COMMAND_READ_KB AS [Объем чтений (КБ)],
	COMMAND_WRITES AS [Записи],
	COMMAND_WRITE_KB AS [Объем записи (КБ)],
	COMMAND_TEXT AS [Текст команды],
	COMMAND_END_TIME AS [Время завершения команды]
FROM $System.Discover_Commands