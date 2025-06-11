CREATE PROCEDURE [dbo].[sp_ClearOldSessionControlSettings]
AS
BEGIN
	SET NOCOUNT ON;

    DECLARE @AllConnections TABLE(
		SPID INT,
		Status VARCHAR(MAX),
		LOGIN VARCHAR(MAX),
		HostName VARCHAR(MAX),
		BlkBy VARCHAR(MAX),
		DBName VARCHAR(MAX),
		Command VARCHAR(MAX),
		CPUTime BIGINT,
		DiskIO BIGINT,
		LastBatch VARCHAR(MAX),
		ProgramName VARCHAR(MAX),
		SPID_1 INT,
		REQUESTID INT
	);
	INSERT INTO @AllConnections EXEC sp_who2;	

	DELETE FROM [dbo].[SessionControlSettings]
	WHERE [SPID] IN (
		SELECT 
			ISNULL([AC].[SPID],[SCS].[SPID]) AS [SPID]
		FROM @AllConnections AS [AC]
			FULL JOIN [dbo].[SessionControlSettings] AS [SCS]
			ON [AC].[SPID] = [SCS].[SPID]
				AND ISNULL([AC].[Login], '') = ISNULL([SCS].[Login], '')
				AND ISNULL([AC].[HostName], '') = ISNULL([SCS].[HostName], '')
				AND ISNULL([AC].[ProgramName], '') = ISNULL([SCS].[ProgramName], '')
		WHERE -- Есть подходящие настройки ограничений для соединения
			[SCS].[SPID] IS NOT NULL	
			AND (
				-- Исключаем статусы соединений
				UPPER([Status]) IN (
					'BACKGROUND' -- Фоновые процессы
					,'SLEEPING' -- Ожидающие команды, не активные
				)

				OR

				-- Настройка была добавлена 24 часа назад
				DATEDIFF(HOUR, [Created], GETDATE()) >= 24

				OR

				-- Соединения уже не существует
				[AC].[SPID] IS NULL
			)
	)
END