ALTER PROCEDURE [dbo].[sp_StatisticMaintenance]
    @databaseName sysname,
    @timeFrom TIME = '00:00:00',
    @timeTo TIME = '23:59:59',
	@timeTimeoutSec int = 600,
    @mode int = 0,
    @ConditionTableName nvarchar(max) = 'LIKE ''%''',
	@ConditionIndexName nvarchar(max) = 'LIKE ''%''',
	@ConditionStatisticName nvarchar(max) = 'LIKE ''%''',
	@MinRowsChangedToMaintenance bigint = 1,
	@abortIfLockOtherSessions bit = 0,
	@abortIfLockOtherSessionsTimeoutSec int = 0
AS
BEGIN
    SET NOCOUNT ON;

	DECLARE 			
		@monitoringDatabaseName sysname = DB_NAME(),
		@useMonitoringDatabase bit = 1;

	-- Проверка доступен ли запуск обслуживания в текущее время
	DECLARE @timeNow TIME = CAST(GETDATE() AS TIME);
	IF (@timeTo >= @timeFrom) BEGIN
		IF(NOT (@timeFrom <= @timeNow AND @timeTo >= @timeNow))
			RETURN;
		END ELSE BEGIN
			IF(NOT ((@timeFrom <= @timeNow AND '23:59:59' >= @timeNow)
				OR (@timeTo >= @timeNow AND '00:00:00' <= @timeNow))) 
					RETURN;
	END
 
 	-- Включаем контроль потребления ресурсов текущим соединением
	EXEC [dbo].[sp_AddSessionControlSetting]
		@databaseName = @databaseName,
		@workFrom = @timeFrom,
		@workTo = @timeTo,
		@timeTimeoutSec = @timeTimeoutSec,
		@abortIfLockOtherSessions = @abortIfLockOtherSessions,
		@abortIfLockOtherSessionsTimeoutSec = @abortIfLockOtherSessionsTimeoutSec;

    IF(@mode = 0)
    BEGIN
        EXECUTE [dbo].[sp_StatisticMaintenance_Sampled]
           @databaseName
          ,@timeFrom
          ,@timeTo
          ,@ConditionTableName
		  ,@ConditionIndexName
		  ,@ConditionStatisticName
		  ,@MinRowsChangedToMaintenance
          ,@useMonitoringDatabase
          ,@monitoringDatabaseName
    END ELSE IF(@mode = 1)
    BEGIN
        EXECUTE [dbo].[sp_StatisticMaintenance_Detailed]
           @databaseName
          ,@timeFrom
          ,@timeTo
          ,@ConditionTableName
		  ,@ConditionIndexName
		  ,@ConditionStatisticName
		  ,@MinRowsChangedToMaintenance
          ,@useMonitoringDatabase
          ,@monitoringDatabaseName
    END

	-- Удаляем контроль для текущей сессии
	EXEC [dbo].[sp_RemoveSessionControlSetting];
 
    RETURN 0
END