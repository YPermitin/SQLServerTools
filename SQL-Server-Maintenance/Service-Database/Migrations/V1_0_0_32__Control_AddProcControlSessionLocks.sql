CREATE PROCEDURE [dbo].[sp_ControlSessionLocks]
AS
BEGIN
	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#connectionsInfo') IS NOT NULL
		DROP TABLE #connectionsInfo;
	CREATE TABLE #connectionsInfo
	(
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

	IF OBJECT_ID('tempdb..#connectionsInfoExtended') IS NOT NULL
		DROP TABLE #connectionsInfoExtended;
	CREATE TABLE #connectionsInfoExtended
	(
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
		REQUESTID INT,
		WaitType nvarchar(max),
		BlockingSessionId INT,
		WaitDurationMs BIGINT
	);

	-- Проверку выполняем пока есть настройки с контролем блокировки
	WHILE(EXISTS(SELECT * FROM [dbo].[SessionControlSettings]
			WHERE [AbortIfLockOtherSessions] = 1))
	BEGIN
		TRUNCATE TABLE #connectionsInfo;
		INSERT INTO #connectionsInfo EXEC sp_who2;

		TRUNCATE TABLE #connectionsInfoExtended;
		INSERT INTO #connectionsInfoExtended
		SELECT SPID, Status, LOGIN,	HostName, BlkBy, DBName, Command, CPUTime, DiskIO, LastBatch, ProgramName, SPID_1, REQUESTID,
			wait_type AS [WaitType], blocking_session_id AS [BlockingSessionId], wait_duration_ms AS [WaitDurationMs]
		FROM #connectionsInfo c
			LEFT JOIN sys.dm_os_waiting_tasks w
				ON c.SPID = [w].[session_id];
		TRUNCATE TABLE #connectionsInfo;

		DECLARE badSessions CURSOR FOR
		SELECT
			REASONE.SPID,
			REASONE.DatabaseName
		FROM (
			SELECT [AC].[SPID],
				[SCS].[DatabaseName],
				[SCS].[AbortIfLockOtherSessions],
				[SCS].[AbortIfLockOtherSessionsTimeoutSec]
			FROM #connectionsInfoExtended AS [AC]
				FULL JOIN [dbo].[SessionControlSettings] AS [SCS]
				ON [AC].[SPID] = [SCS].[SPID]
					AND ISNULL([AC].[Login], '') = ISNULL([SCS].[Login], '')
					AND ISNULL([AC].[HostName], '') = ISNULL([SCS].[HostName], '')
					AND ISNULL([AC].[ProgramName], '') = ISNULL([SCS].[ProgramName], '')
			WHERE -- Есть подходящие настройки ограничений для соединения
				[SCS].[SPID] IS NOT NULL	
				-- Исключаем статусы соединений
				AND NOT UPPER([Status]) IN (
					'BACKGROUND' -- Фоновые процессы
				)
				-- Только с контролем блокировку соединений
				AND [SCS].[AbortIfLockOtherSessions] = 1) REASONE
			LEFT JOIN (
				SELECT
					SPID AS [BlockedSessionId],
					BlockingSessionId,
					WaitType,
					WaitDurationMs
				FROM #connectionsInfoExtended blk
				WHERE WaitType IS NOT NULL
			) BLOCKED
			ON REASONE.SPID = BLOCKED.BlockingSessionId
			-- Учитываем только ожидания на блокировках
			WHERE WaitType LIKE 'LCK_%'
				-- И ожидания выше указанного таймаута
				AND ((WaitDurationMs/1000) >= REASONE.AbortIfLockOtherSessionsTimeoutSec)
				-- Блокируемый сеанс и блокирующий сеанс не должны совпадать.
				-- Такое возможно, когда соединения в разных потоках выполняет работу и эти потоки ждут друг друга.
				AND REASONE.SPID <> BLOCKED.[BlockedSessionId];
		OPEN badSessions;
	
		DECLARE @killCommand VARCHAR(15);
		DECLARE 
			@badSessionId int,
			@sessionDatabaseName nvarchar(max),
			@comment nvarchar(max),
			@RunDate datetime = GetDate(),
			@startDate datetime = GetDate(),
			@finishDate datetime = GetDate(),
			@MaintenanceActionLogId bigint;
		FETCH NEXT FROM badSessions INTO @badSessionId, @sessionDatabaseName;
		WHILE @@FETCH_STATUS = 0  
		BEGIN
			SET @killCommand = 'KILL ' + CAST(@badSessionId AS VARCHAR(5));
			SET @comment = 'Соединение ' + CAST(@badSessionId AS VARCHAR(5)) +' блокирует работы других запросов и будет завершено.'

			EXECUTE [dbo].[sp_add_maintenance_action_log]
				''
				,''
				,'BLOCKING SESSION CONTROL'
				,@RunDate
				,@startDate
				,@finishDate
				,@sessionDatabaseName
				,0
				,@comment
				,0
				,0
				,@killCommand
				,@MaintenanceActionLogId OUTPUT;
						
			EXEC(@killCommand)

			EXEC [dbo].[sp_RemoveSessionControlSetting]
				@spid = @badSessionId;

			FETCH NEXT FROM badSessions INTO @badSessionId, @sessionDatabaseName;
		END

		CLOSE badSessions;  
		DEALLOCATE badSessions;

        WAITFOR DELAY '00:00:03'
	END
END