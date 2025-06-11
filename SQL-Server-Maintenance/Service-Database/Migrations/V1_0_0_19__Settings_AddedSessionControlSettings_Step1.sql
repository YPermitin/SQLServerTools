CREATE TABLE [dbo].[SessionControlSettings](
	[SPID] [int] NOT NULL,
	[Login] [nvarchar](250) NULL,
	[HostName] [nvarchar](250) NULL,
	[ProgramName] [nvarchar](250) NULL,
	[WorkFrom] [time](7) NULL,
	[WorkTo] [time](7) NULL,
	[MaxLogUsagePercent] [int] NULL,
	[MaxLogUsageMb] [int] NULL,
	[Created] [datetime] NOT NULL,
	[DatabaseName] [nvarchar](250) NULL,
	[WorkTimeoutSec] [int] NULL,
	[AbortIfLockOtherSessions] [bit] NOT NULL,
	[AbortIfLockOtherSessionsTimeoutSec] [int] NOT NULL,
 CONSTRAINT [PK_SessionControlSettings] PRIMARY KEY CLUSTERED 
(
	[SPID] ASC
) ON [PRIMARY]
) ON [PRIMARY]