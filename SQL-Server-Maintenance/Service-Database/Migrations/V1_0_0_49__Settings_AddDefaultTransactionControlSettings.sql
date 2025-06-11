SET IDENTITY_INSERT [dbo].[LogTransactionControlSettings] ON 
INSERT [dbo].[LogTransactionControlSettings] ([Id], [DatabaseName], [MinDiskFreeSpace], [MaxLogUsagePercentThreshold], [MinAllowDataFileFreeSpaceForResumableRebuildMb]) VALUES (1, NULL, 307200, 75, 307200)
SET IDENTITY_INSERT [dbo].[LogTransactionControlSettings] OFF