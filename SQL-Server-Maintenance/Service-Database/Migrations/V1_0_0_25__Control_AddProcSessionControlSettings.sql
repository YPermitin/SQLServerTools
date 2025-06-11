CREATE PROCEDURE [dbo].[sp_AddSessionControlSetting]
	@databaseName nvarchar(250) = null,
	@workFrom time(7) = null,
	@workTo time(7) = null,
	@timeTimeoutSec int = null,
	@maxLogUsagePercent int = null,
	@maxLogUsageMb int = null,
	@abortIfLockOtherSessions bit = 0,
	@abortIfLockOtherSessionsTimeoutSec int = 0
AS
BEGIN
	SET NOCOUNT ON;

	EXEC [dbo].[sp_RemoveSessionControlSetting];

	DECLARE @currentSpid smallint;
	SELECT @currentSpid = @@SPID

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

	INSERT INTO [dbo].[SessionControlSettings]
	(
		[SPID],
		[Login],
		[HostName],
		[ProgramName],
		[WorkFrom],
		[WorkTo],
		[MaxLogUsagePercent],
		[MaxLogUsageMb],
		[Created],
		[DatabaseName],
		[WorkTimeoutSec],
		[AbortIfLockOtherSessions],
		[AbortIfLockOtherSessionsTimeoutSec]
	)
	SELECT TOP 1
		[SPID],
		[Login],
		[HostName],
		[ProgramName],
		@workFrom,
		@workTo,
		@maxLogUsagePercent,
		@MaxLogUsageMb,
		GetDate(),
		@databaseName,
		@timeTimeoutSec,
		@abortIfLockOtherSessions,
		@abortIfLockOtherSessionsTimeoutSec
	FROM @AllConnections
	WHERE SPID = @currentSpid;	
END