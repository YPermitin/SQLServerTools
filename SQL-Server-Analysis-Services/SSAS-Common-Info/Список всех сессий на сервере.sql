-- Список всех сеансов на сервере. Используется для сопоставления команд и соединений.
-- https://docs.microsoft.com/ru-ru/openspecs/sql_server_protocols/ms-ssas/d1e6f251-ec9c-4414-b8fd-25c07ae79e19

SELECT
	SESSION_ID AS [Идентификатор сессии],
	SESSION_SPID AS [ID сессии],
	SESSION_CONNECTION_ID AS [ID соединения],
	SESSION_USER_NAME AS [Пользователь],
	SESSION_CURRENT_DATABASE AS [База данных],
	SESSION_USED_MEMORY AS [Использовано памяти],
	SESSION_PROPERTIES AS [Произволные свойства],
	SESSION_START_TIME AS [Начало сессии],
	SESSION_ELAPSED_TIME_MS AS [Время работы сессии (мс)],
	SESSION_LAST_COMMAND_START_TIME AS [Время запуска последней команды],
	SESSION_LAST_COMMAND_END_TIME AS [Время завершения последней команды],
	SESSION_LAST_COMMAND_ELAPSED_TIME_MS AS  [Время выполнения последний команды (мс)],
	SESSION_IDLE_TIME_MS AS [Время простоя сессии (мс)],
	SESSION_CPU_TIME_MS AS [CPU (мс)],
	SESSION_LAST_COMMAND AS [Текст последний команды],
	SESSION_LAST_COMMAND_CPU_TIME_MS AS [CPU последней команды (мс)],
	SESSION_STATUS AS [Статус],
	SESSION_READS AS [Чтений],
	SESSION_WRITES AS [Записи],
	SESSION_READ_KB AS [Объем чтений (КБ)],
	SESSION_WRITE_KB AS [Объем записи (КБ)],
	SESSION_COMMAND_COUNT AS [Количество команд]	
FROM $System.Discover_Sessions