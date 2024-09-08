EXEC sp_configure 'clr enabled', 1;  
RECONFIGURE;  
GO  
ALTER DATABASE PowerSQLCLR SET TRUSTWORTHY ON;
GO

IF(OBJECT_ID('dbo.fn_GetHttpMethods') IS NOT NULL)
BEGIN
	DROP FUNCTION [fn_GetHttpMethods];
END

IF(OBJECT_ID('dbo.fn_HttpQuery') IS NOT NULL)
BEGIN
	DROP FUNCTION [fn_HttpQuery];
END

IF(OBJECT_ID('dbo.fn_GetUserAgentExamples') IS NOT NULL)
BEGIN
	DROP FUNCTION [fn_GetUserAgentExamples];
END

IF(OBJECT_ID('dbo.fn_GetHttpHelperInstanceCreateDateUtc') IS NOT NULL)
BEGIN
	DROP FUNCTION [fn_GetHttpHelperInstanceCreateDateUtc];
END

IF(OBJECT_ID('dbo.fn_GetHttpHelperInstanceId') IS NOT NULL)
BEGIN
	DROP FUNCTION [fn_GetHttpHelperInstanceId];
END

IF(OBJECT_ID('dbo.fn_GetClrVersion') IS NOT NULL)
BEGIN
	DROP FUNCTION [fn_GetClrVersion];
END

IF(OBJECT_ID('dbo.sp_SetupSecurityProtocol') IS NOT NULL)
BEGIN
	DROP PROCEDURE [sp_SetupSecurityProtocol];
END

IF(OBJECT_ID('dbo.fn_GetAvailableSecurityProtocols') IS NOT NULL)
BEGIN
	DROP FUNCTION [fn_GetAvailableSecurityProtocols];
END

IF(OBJECT_ID('dbo.fn_GetCurrentSecurityProtocols') IS NOT NULL)
BEGIN
	DROP FUNCTION [fn_GetCurrentSecurityProtocols];
END

IF(OBJECT_ID('dbo.fn_HttpGet') IS NOT NULL)
BEGIN
	DROP FUNCTION [fn_HttpGet];
END

IF(OBJECT_ID('dbo.sp_EnableLoggingToDatabase') IS NOT NULL)
BEGIN
	DROP PROCEDURE [sp_EnableLoggingToDatabase];
END

IF(OBJECT_ID('dbo.sp_DisableLoggingToDatabase') IS NOT NULL)
BEGIN
	DROP PROCEDURE [sp_DisableLoggingToDatabase];
END

IF(OBJECT_ID('dbo.sp_HttpQueryProc') IS NOT NULL)
BEGIN
	DROP PROCEDURE [sp_HttpQueryProc];
END

if(EXISTS(select * from sys.assemblies WHERE [name] = 'HttpHelper'))
BEGIN
	DROP ASSEMBLY [HttpHelper];
END

CREATE ASSEMBLY [HttpHelper]
	FROM 'C:\Share\SQLCLR\HttpHelper.dll'
	WITH PERMISSION_SET = UNSAFE;
GO

	CREATE PROCEDURE [dbo].[sp_SetupSecurityProtocol](
		@protocols nvarchar(max)
	)
	AS EXTERNAL NAME [HttpHelper].[YPermitin.SQLCLR.HttpHelper.EntryHttpClient].[SetupSecurityProtocol];
	GO

	CREATE FUNCTION fn_GetHttpHelperInstanceCreateDateUTC() 
	RETURNS datetime   
	AS EXTERNAL NAME [HttpHelper].[YPermitin.SQLCLR.HttpHelper.EntryHttpClient].[GetHttpHelperInstanceCreateDateUtc];   
	GO

	CREATE FUNCTION fn_GetHttpHelperInstanceId() 
	RETURNS uniqueidentifier   
	AS EXTERNAL NAME [HttpHelper].[YPermitin.SQLCLR.HttpHelper.EntryHttpClient].[GetHttpHelperInstanceId];   
	GO

	CREATE FUNCTION fn_GetClrVersion() 
	RETURNS nvarchar(50)   
	AS EXTERNAL NAME [HttpHelper].[YPermitin.SQLCLR.HttpHelper.EntryHttpClient].[GetClrVersion];   
	GO

	CREATE FUNCTION fn_HttpQuery (
		@url nvarchar(max),
		@method nvarchar(150) = 'GET',
		@headers xml,
		@body nvarchar(max),
		@timeoutMs int = 0,
		@ignoreCertificateValidation bit = 0	
	) 
	RETURNS xml   
	AS EXTERNAL NAME [HttpHelper].[YPermitin.SQLCLR.HttpHelper.EntryHttpClient].[HttpQuery];   
	GO

	CREATE FUNCTION [dbo].[fn_GetHttpMethods]()  
	RETURNS TABLE (
		[Name] nvarchar(150)
	)
	AS   
	EXTERNAL NAME [HttpHelper].[YPermitin.SQLCLR.HttpHelper.EntryHttpClient].[GetHttpMethods];
	GO

	CREATE FUNCTION [dbo].[fn_GetUserAgentExamples]()  
	RETURNS TABLE (
		[Browser] nvarchar(max),
		[OperationSystem] nvarchar(max),
		[UserAgent] nvarchar(max)
	)
	AS   
	EXTERNAL NAME [HttpHelper].[YPermitin.SQLCLR.HttpHelper.EntryHttpClient].[GetUserAgentExamples];
	GO

	CREATE FUNCTION [dbo].[fn_GetAvailableSecurityProtocols]()  
	RETURNS TABLE (
		[Name] nvarchar(150)
	)
	AS   
	EXTERNAL NAME [HttpHelper].[YPermitin.SQLCLR.HttpHelper.EntryHttpClient].[GetAvailableSecurityProtocols];
	GO

	CREATE FUNCTION [dbo].[fn_GetCurrentSecurityProtocols]()  
	RETURNS TABLE (
		[Name] nvarchar(150)
	)
	AS   
	EXTERNAL NAME [HttpHelper].[YPermitin.SQLCLR.HttpHelper.EntryHttpClient].[GetCurrentSecurityProtocols];
	GO

	CREATE FUNCTION fn_HttpGet 
	(
		@url nvarchar(max)
	)
	RETURNS nvarchar(max)
	AS
	BEGIN
		DECLARE @response xml,
			@bodyJson nvarchar(max);

		SELECT @response = [dbo].[fn_HttpQuery] (
			@url,
			DEFAULT,
			null,
			null,
			60000,
			DEFAULT
		);

		SELECT @bodyJson = @response.value('(/Response/Body)[1]', 'nvarchar(max)');

		RETURN @bodyJson;
	END
	GO

	CREATE PROCEDURE [dbo].[sp_EnableLoggingToDatabase]
	AS EXTERNAL NAME [HttpHelper].[YPermitin.SQLCLR.HttpHelper.EntryHttpClient].[EnableLoggingToDatabase];
	GO

	CREATE PROCEDURE [dbo].[sp_DisableLoggingToDatabase]
	AS EXTERNAL NAME [HttpHelper].[YPermitin.SQLCLR.HttpHelper.EntryHttpClient].[DisableLoggingToDatabase];
	GO

	CREATE PROCEDURE sp_HttpQueryProc (
		@url nvarchar(max),
		@method nvarchar(150) = 'GET',
		@headers xml,
		@body nvarchar(max),
		@timeoutMs int = 0,
		@ignoreCertificateValidation bit = 0,
		@result xml out
	)  
	AS EXTERNAL NAME [HttpHelper].[YPermitin.SQLCLR.HttpHelper.EntryHttpClient].[HttpQueryProc];   
	GO