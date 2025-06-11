BEGIN TRANSACTION
GO
ALTER TABLE dbo.LogTransactionControlSettings
	DROP CONSTRAINT DF_LogTransactionControlSettings_MinLogUsagePercentThreshold
GO
ALTER TABLE dbo.LogTransactionControlSettings
	DROP CONSTRAINT DF_LogTransactionControlSettings_MinAllowDataFileFreeSpaceForResumableRebuildMb
GO
CREATE TABLE dbo.Tmp_LogTransactionControlSettings
	(
	Id int NOT NULL IDENTITY (1, 1),
	DatabaseName nvarchar(250) NULL,
	MinDiskFreeSpace int NOT NULL,
	MaxLogUsagePercentThreshold int NOT NULL,
	MinAllowDataFileFreeSpaceForResumableRebuildMb int NOT NULL
	)  ON [PRIMARY]
GO
ALTER TABLE dbo.Tmp_LogTransactionControlSettings SET (LOCK_ESCALATION = TABLE)
GO
ALTER TABLE dbo.Tmp_LogTransactionControlSettings ADD CONSTRAINT
	DF_LogTransactionControlSettings_MinLogUsagePercentThreshold DEFAULT ((90)) FOR MaxLogUsagePercentThreshold
GO
ALTER TABLE dbo.Tmp_LogTransactionControlSettings ADD CONSTRAINT
	DF_LogTransactionControlSettings_MinAllowDataFileFreeSpaceForResumableRebuildMb DEFAULT ((0)) FOR MinAllowDataFileFreeSpaceForResumableRebuildMb
GO
SET IDENTITY_INSERT dbo.Tmp_LogTransactionControlSettings ON
GO
IF EXISTS(SELECT * FROM dbo.LogTransactionControlSettings)
	 EXEC('INSERT INTO dbo.Tmp_LogTransactionControlSettings (Id, DatabaseName, MinDiskFreeSpace, MaxLogUsagePercentThreshold, MinAllowDataFileFreeSpaceForResumableRebuildMb)
		SELECT Id, DatabaseName, MinDiskFreeSpace, MaxLogUsagePercentThreshold, MinAllowDataFileFreeSpaceForResumableRebuildMb FROM dbo.LogTransactionControlSettings WITH (HOLDLOCK TABLOCKX)')
GO
SET IDENTITY_INSERT dbo.Tmp_LogTransactionControlSettings OFF
GO
DROP TABLE dbo.LogTransactionControlSettings
GO
EXECUTE sp_rename N'dbo.Tmp_LogTransactionControlSettings', N'LogTransactionControlSettings', 'OBJECT' 
GO
ALTER TABLE dbo.LogTransactionControlSettings ADD CONSTRAINT
	PK_LogTransactionControlSettings PRIMARY KEY CLUSTERED 
	(
	Id
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
CREATE UNIQUE NONCLUSTERED INDEX IX_LogTransactionControlSettings_DatabaseName ON dbo.LogTransactionControlSettings
	(
	DatabaseName
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
COMMIT
