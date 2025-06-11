CREATE UNIQUE NONCLUSTERED INDEX [IX_Settings_Name_DatabaseName] ON [dbo].[Settings]
(
	[Name] ASC,
	[DatabaseName] ASC
) ON [PRIMARY]