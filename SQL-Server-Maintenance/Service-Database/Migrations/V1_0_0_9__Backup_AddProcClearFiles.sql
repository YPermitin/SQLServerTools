CREATE PROCEDURE [dbo].[sp_ClearFiles]
	@folderPath nvarchar(max),
	@fileType bit = 0,	
	@fileExtension nvarchar(10) = null,
	@cutoffDate datetime = null,
	@cutoffDateDays int = null,
	@includeSubfolders bit = 1,
	@scriptOnly bit = 0	
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @msg nvarchar(max);

	IF(@cutoffDate is not null AND @cutoffDateDays is not null)
	BEGIN
		SET @msg = 'You should setup only one parameter: @cutoffDate or @cutoffDateDays';
        THROW 51000, @msg, 1;
        RETURN -1;
	END

	IF(@cutoffDateDays IS NOT NULL)
	BEGIN
		SET @cutoffDate = DATEADD(day, -@cutoffDateDays, GETDATE())
	END ELSE IF(@cutoffDate is null)
	BEGIN
		SET @cutoffDate = GETDATE()
	END

	DECLARE @sql nvarchar(max);
	SET @sql = 'EXECUTE master.dbo.xp_delete_file ' + 
		CAST(@fileType AS nvarchar(max)) + 
		',N''' + @folderPath + '''' +
		',N''' + @fileExtension + 
		''',N''' + FORMAT(@cutoffDate, 'yyyy-MM-ddTHH:mm:ss') + ''',' + 
		CAST(@includeSubfolders AS nvarchar(max))

	IF(@scriptOnly = 1)
	BEGIN
		PRINT @sql
	END ELSE
	BEGIN
		EXECUTE sp_executesql @sql
	END	
END


