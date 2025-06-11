CREATE PROCEDURE [dbo].[sp_RestartMonitoringXEventSessions]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @xevents_name nvarchar(250),
			@cmd nvarchar(max);
	DECLARE xevents_cursor CURSOR FOR
	SELECT
	   ES.name AS [xevents_session_name]
	FROM sys.dm_xe_sessions RS
		RIGHT JOIN sys.server_event_sessions ES ON RS.name = ES.name
	WHERE iif(RS.name IS NULL, 0, 1) = 1
		AND es.name IN (
			'HeavyQueryByReads',
			'HeavyQueryByCPU',
			'Errors',
			'BlocksAndDeadlocksAnalyse'
		)
	OPEN xevents_cursor  
	FETCH NEXT FROM xevents_cursor INTO @xevents_name
	WHILE @@FETCH_STATUS = 0
	BEGIN    
  
		SET @cmd = 'ALTER EVENT SESSION ' + @xevents_name + ' ON SERVER  STATE = STOP'
		EXECUTE sp_executesql  @cmd
  
		SET @cmd = 'ALTER EVENT SESSION ' + @xevents_name + ' ON SERVER  STATE = START'
		EXECUTE sp_executesql  @cmd
  
		FETCH NEXT FROM xevents_cursor INTO @xevents_name
	END 
  
	CLOSE xevents_cursor;
	DEALLOCATE xevents_cursor;
END