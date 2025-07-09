ALTER PROCEDURE [dbo].[sp_CompressAndShrinkDataFile] 
	@databaseName sysname,
	@timeFrom TIME = null,
	@timeTo TIME = null,
	@useOnlineRebuild bit = 1,
	@userResumableRebuild bit = 1,
	@maxDop int = 4,
	@databaseFileNameForShrink nvarchar(512) = null,		
	@delayBetweenShrinkSteps nvarchar(8) = '00:00:10',
	@shrinkStepMb int = 10240,
	@stopShrinkThresholdByDataFileFreeSpacePercent numeric(15,3) = 1.0
AS
BEGIN
	SET NOCOUNT ON;

    EXECUTE [dbo].[sp_CompressDatabaseObjects] 
		@databaseName = @databaseName,
		@timeFrom = @timeFrom,
		@timeTo = @timeTo,
		@useOnlineRebuild = @useOnlineRebuild,
		@userResumableRebuild = @userResumableRebuild,
		@maxDop = @maxDop
	
	EXECUTE [dbo].[sp_ShrinkDatabaseDataFile]
		@databaseName = @databaseName,
		@databaseFileName = @databaseFileNameForShrink,
		@delayBetweenSteps = @delayBetweenShrinkSteps,
		@timeFrom = @timeFrom,
		@timeTo = @timeTo,
		@shrinkStepMb = @shrinkStepMb,
		@stopShrinkThresholdByDataFileFreeSpacePercent = @stopShrinkThresholdByDataFileFreeSpacePercent;
END