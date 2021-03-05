-- Список открытых соединений
-- https://docs.microsoft.com/ru-ru/openspecs/sql_server_protocols/ms-ssas/79a1f1e8-92d6-41f4-894a-c83c5047ba3b

SELECT 
	CONNECTION_ID AS [ID соединения],
	CONNECTION_USER_NAME AS [Пользователь],
	CONNECTION_IMPERSONATED_USER_NAME AS [Персональное имя пользователя],
	CONNECTION_HOST_NAME AS [Компьютер],
	CONNECTION_HOST_APPLICATION AS [Приложение],
	CONNECTION_START_TIME AS [Начало подключения],
	CONNECTION_ELAPSED_TIME_MS AS [Время работы (мс)],
	CONNECTION_LAST_COMMAND_START_TIME AS [Дата старта последней команды], 
	CONNECTION_LAST_COMMAND_END_TIME AS [Дата завершения последней команды],
	CONNECTION_LAST_COMMAND_ELAPSED_TIME_MS AS [Время выполненияпоследней команды (мс)],
	CONNECTION_IDLE_TIME_MS AS [Время простоя (мс)],
	CONNECTION_BYTES_SENT AS [Байт передано],
	CONNECTION_DATA_BYTES_SENT AS [Байт данных отправлено],
	CONNECTION_BYTES_RECEIVED AS [Байт принято],
	CONNECTION_DATA_BYTES_RECEIVED AS [Байт данных принято]
FROM $System.Discover_Connections