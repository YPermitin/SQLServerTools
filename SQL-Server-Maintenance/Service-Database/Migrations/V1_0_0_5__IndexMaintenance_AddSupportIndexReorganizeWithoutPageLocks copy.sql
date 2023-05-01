IF (NOT EXISTS (SELECT * 
                 FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                 AND  TABLE_NAME = 'MaintenanceActionsToRun'))
BEGIN
	DECLARE @sql nvarchar(max)
			
		SET @sql = '
CREATE TABLE [dbo].[MaintenanceActionsToRun](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[DatabaseName] [nvarchar](255) NOT NULL,
	[Period] [datetime2](0) NOT NULL,
	[Operation] [nvarchar](100) NOT NULL,
	[SQLCommand] [nvarchar](max) NOT NULL,
	[RunAttempts] [int] NOT NULL,
	[Comment] [nvarchar](255) NULL,
	[SourceConnectionId] [smallint] NOT NULL,
 CONSTRAINT [PK_MaintenanceActionsToRun] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]'
		EXECUTE sp_executesql @sql

		SET @sql = '
ALTER TABLE [dbo].[MaintenanceActionsToRun] ADD  CONSTRAINT [DF_MaintenanceActionsToRun_RunAttempts]  DEFAULT ((0)) FOR [RunAttempts]'
		EXECUTE sp_executesql @sql
END

SET @sql = '
IF EXISTS (
        SELECT type_desc, type
        FROM sys.procedures WITH(NOLOCK)
        WHERE NAME = ''sp_add_maintenance_action_to_run''
            AND type =''P''
      )
BEGIN
	DROP PROCEDURE [dbo].[sp_add_maintenance_action_to_run] 
END'
EXECUTE sp_executesql @sql

SET @sql = '
IF EXISTS (
        SELECT type_desc, type
        FROM sys.procedures WITH(NOLOCK)
        WHERE NAME = ''sp_remove_maintenance_action_to_run''
            AND type =''P''
      )
BEGIN
	DROP PROCEDURE [dbo].[sp_remove_maintenance_action_to_run] 
END'
EXECUTE sp_executesql @sql

SET @sql = '
IF EXISTS (
        SELECT type_desc, type
        FROM sys.procedures WITH(NOLOCK)
        WHERE NAME = ''sp_apply_maintenance_action_to_run''
            AND type =''P''
      )
BEGIN
	DROP PROCEDURE [dbo].[sp_apply_maintenance_action_to_run] 
END'
EXECUTE sp_executesql @sql

SET @sql = '
CREATE PROCEDURE [dbo].[sp_add_maintenance_action_to_run]
	@DatabaseName sysname,
	@Operation nvarchar(100),
	@SQLCommand nvarchar(max),
	@MaintenanceActionToRunId bigint OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @IdentityOutput TABLE ( Id bigint );
	DECLARE @RunDate datetime2(0) = GetDate();

	SET @DatabaseName = REPLACE(@DatabaseName, ''['', '''')
	SET @DatabaseName = REPLACE(@DatabaseName, '']'', '''')

	INSERT INTO [dbo].[MaintenanceActionsToRun]
	(
		[DatabaseName],
		[Period],
		[Operation],
		[SQLCommand],
		[SourceConnectionId]
	)
	OUTPUT inserted.Id into @IdentityOutput
	VALUES
	(
		@DatabaseName,
		@RunDate,
		@Operation,
		@SQLCommand,
		@@SPID
	)

	SET @MaintenanceActionToRunId = (SELECT MAX(Id) FROM @IdentityOutput)

	RETURN 0
END'
EXECUTE sp_executesql @sql

SET @sql = '
CREATE PROCEDURE [dbo].[sp_remove_maintenance_action_to_run]
	@Id int
AS
BEGIN
	SET NOCOUNT ON;

    DELETE FROM [dbo].[MaintenanceActionsToRun]
	WHERE [Id] = @Id
END'
EXECUTE sp_executesql @sql

SET @sql = '
CREATE PROCEDURE [dbo].[sp_apply_maintenance_action_to_run]
	@databaseName sysname
AS
BEGIN
	SET NOCOUNT ON;
	
	BEGIN TRAN;

	DECLARE 
		@period datetime2(0),
		@operation nvarchar(100),
		@id int,
		@sqlCommand nvarchar(max),
		@fullSqlCommand nvarchar(max),
		@sourceConnectionId smallint,
		@operationFull nvarchar(max),
		@RunDate datetime2(0) = GetDate(),
		@StartDate datetime2(0),
		@FinishDate datetime2(0),
		@MaintenanceActionLogId bigint;

	DECLARE commands_to_run_cursor CURSOR  
	FOR SELECT
		[Id], [Period], [Operation], [SQLCommand], [SourceConnectionId]
	FROM [dbo].[MaintenanceActionsToRun] WITH (READPAST, UPDLOCK)
	WHERE [DatabaseName] = @databaseName
		AND [RunAttempts] < 3
	ORDER BY [Period], [Id]
	OPEN commands_to_run_cursor;

	FETCH NEXT FROM commands_to_run_cursor INTO @id, @period, @operation, @sqlCommand, @sourceConnectionId;

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		IF(EXISTS(
			SELECT  *
			FROM    sys.dm_exec_sessions es
				LEFT OUTER JOIN sys.dm_exec_requests rs ON (es.session_id = rs.session_id)  
				CROSS APPLY sys.dm_exec_sql_text(rs.sql_handle) AS sqltext
			WHERE (
					rs.command like ''%ALTER INDEX%'' 
					or (rs.command like ''%DBCC%'' AND sqltext.text like ''%ALTER%INDEX%'')
					or (rs.command like ''%DBCC%'' AND sqltext.text like ''%EXECUTE%sp_IndexMaintenance%'')
				  )
				and es.session_id = @sourceConnectionId))
		BEGIN
			FETCH NEXT FROM commands_to_run_cursor INTO @id, @period, @operation, @sqlCommand, @sourceConnectionId;
			CONTINUE;
		END
						
		SET @fullSqlCommand = CAST(''USE ['' as nvarchar(max)) + CAST(@databaseName  as nvarchar(max)) + CAST(''];
		'' as nvarchar(max)) + CAST(@sqlCommand as nvarchar(max));
		
		UPDATE [dbo].[MaintenanceActionsToRun]
		SET 
			[RunAttempts] = [RunAttempts] + 1,
			[SourceConnectionId] = @@SPID
		WHERE [Id] = @id
		
		SET @StartDate = GetDate()
		SET @operationFull = ''MAINTENANCE ACTION TO RUN ('' + @Operation + '')''

		DECLARE @msg nvarchar(500);
        EXECUTE [dbo].[sp_add_maintenance_action_log]
			''''
            ,''''
            ,@operationFull
            ,@RunDate
            ,@StartDate
            ,null
            ,@databaseName
            ,0
            ,''''
            ,0
            ,0
            ,@sqlCommand
            ,@MaintenanceActionLogId OUTPUT;

		BEGIN TRY
			EXEC sp_executesql @fullSqlCommand;

			execute [dbo].[sp_remove_maintenance_action_to_run]
				@id

			SET @msg = ''''
		END TRY
		BEGIN CATCH
			SET @msg = ''Error: ''
				+ CAST(Error_message() AS NVARCHAR(500)) + '', Code: '' 
				+ CAST(Error_Number() AS NVARCHAR(500)) + '', Line: '' 
				+ CAST(Error_Line() AS NVARCHAR(500))			
			UPDATE [dbo].[MaintenanceActionsToRun]
			SET [Comment] = @msg
			WHERE [Id] = @id
		END CATCH
		
		SET @FinishDate = GetDate()
        EXECUTE [dbo].[sp_set_maintenance_action_log_finish_date]
			@MaintenanceActionLogId,
            @FinishDate,
			@msg;   

		FETCH NEXT FROM commands_to_run_cursor INTO @id, @period, @operation, @sqlCommand, @sourceConnectionId;
	END
	CLOSE commands_to_run_cursor;  
	DEALLOCATE commands_to_run_cursor;

	COMMIT TRAN;
END
'
EXECUTE sp_executesql @sql