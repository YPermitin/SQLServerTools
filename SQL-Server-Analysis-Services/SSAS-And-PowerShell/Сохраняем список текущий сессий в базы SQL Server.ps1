# Пример сохранения данных запроса из SSAS в базу данных SQL Server
# В этом конкретном примере сохраняем информацию о текущих сессиях

<#
-- Структура таблицы в базе SQL Server для записи данных.

CREATE TABLE [dbo].[SSAS_DISCOVER_SESSIONS](
	[PERIOD] [datetime2](7) NOT NULL,
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[SESSION_ID] [nvarchar](255) NULL,
	[SESSION_SPID] [bigint] NULL,
	[SESSION_CONNECTION_ID] [bigint] NULL,
	[SESSION_USER_NAME] [nvarchar](255) NULL,
	[SESSION_USED_MEMORY] [bigint] NULL,
	[SESSION_START_TIME] [datetime2](7) NULL,
	[SESSION_ELAPSED_TIME_MS] [bigint] NULL,
	[SESSION_LAST_COMMAND_START_TIME] [datetime2](7) NULL,
	[SESSION_LAST_COMMAND_END_TIME] [datetime2](7) NULL,
	[SESSION_LAST_COMMAND_ELAPSED_TIME_MS] [bigint] NULL,
	[SESSION_IDLE_TIME_MS] [bigint] NULL,
	[SESSION_CPU_TIME_MS] [bigint] NULL,
	[SESSION_LAST_COMMAND] [nvarchar](max) NULL,
	[SESSION_LAST_COMMAND_CPU_TIME_MS] [bigint] NULL,
	[SESSION_STATUS] [bigint] NULL,
	[SESSION_READS] [bigint] NULL,
	[SESSION_WRITES] [bigint] NULL,
	[SESSION_READ_KB] [bigint] NULL,
	[SESSION_WRITE_KB] [bigint] NULL,
	[SESSION_COMMAND_COUNT] [bigint] NULL,
	[THREAD_POOL_USED] [nvarchar](255) NULL,
	[REQUEST_ACTIVITY_ID] [nvarchar](255) NULL,
	[CLIENT_ACTIVITY_ID] [nvarchar](255) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

CREATE UNIQUE CLUSTERED INDEX [IX_SSAS_DISCOVER_SESSIONS_PERIOD_SESSION_USER_NAME_ID] ON [dbo].[SSAS_DISCOVER_SESSIONS]
(
	[PERIOD] ASC,
	[SESSION_USER_NAME] ASC,
	[ID] ASC
)
#>

# Базовые настройки
$errorActionPreference = 'Stop'

# Настройки подключения к SQL Server
# Строка подключения к базе
# Примеры:
#   - аутентификация средствами NTLM: "Server=<Имя сервера>;Database=<Имя базы>;Integrated Security=TRUE;"
#   - аутентификация средствами SQL Server: "Data Source=<Имя сервера>;user=<Имя пользователя>;password=<Пароль>;Initial Catalog=<Имя базы>"
$connectionString = "<Строка подключения>";
# Таймаут подключения для команд
$sqlCmdTimeoutSeconds = 180;

# SSAS настройки
$ssasServer = "localhost"
$ssasQuery = 'SELECT * FROM $SYSTEM.DISCOVER_SESSIONS'

[XML]$sessionsData = Invoke-ASCmd -Server:$ssasServer -Query $ssasQuery
$period = Get-Date

$sqlConnection = new-object system.data.SqlClient.SQLConnection($connectionString);
$sqlConnection.Open();

foreach($rowData in $sessionsData.return.root.ChildNodes)
{
    if($rowData.Name -eq "Exception")
    {
        throw "Query exec error"
    }

    if($rowData.Name -ne "row")
    {
        continue
    }
    
    # $rowData - содержит данные результата запроса
    # $rowData

    $sqlCommand = New-Object System.Data.SqlClient.SqlCommand
    $sqlCommand.Connection = $sqlConnection
    $sqlCommand.CommandTimeout = $sqlCmdTimeoutSeconds
    $sqlCommand.CommandText = 
        "INSERT INTO [dbo].[SSAS_DISCOVER_SESSIONS] " + 
        "(" +
        "    [PERIOD]," + 
        "    [SESSION_ID]," + 
        "    [SESSION_SPID]," +
        "    [SESSION_CONNECTION_ID]," +
        "    [SESSION_USER_NAME]," +
        "    [SESSION_USED_MEMORY]," +
        "    [SESSION_START_TIME]," +
        "    [SESSION_ELAPSED_TIME_MS]," +
        "    [SESSION_LAST_COMMAND_START_TIME]," +
        "    [SESSION_LAST_COMMAND_END_TIME]," +
        "    [SESSION_LAST_COMMAND_ELAPSED_TIME_MS]," +
        "    [SESSION_IDLE_TIME_MS]," +
        "    [SESSION_CPU_TIME_MS]," +
        "    [SESSION_LAST_COMMAND]," +                                      
        "    [SESSION_LAST_COMMAND_CPU_TIME_MS]," +
        "    [SESSION_STATUS]," +
        "    [SESSION_READS]," +
        "    [SESSION_WRITES]," +
        "    [SESSION_READ_KB]," +
        "    [SESSION_WRITE_KB]," +
        "    [SESSION_COMMAND_COUNT]," +
        "    [THREAD_POOL_USED]," +
        "    [REQUEST_ACTIVITY_ID]," +
        "    [CLIENT_ACTIVITY_ID]" +
        ") " +
        "VALUES " +
        "(" + 
        "    @PERIOD," +
        "    @SESSION_ID," +
        "    @SESSION_SPID," +
        "    @SESSION_CONNECTION_ID," +
        "    @SESSION_USER_NAME," +
        "    @SESSION_USED_MEMORY," +
        "    @SESSION_START_TIME," +
        "    @SESSION_ELAPSED_TIME_MS," +
        "    @SESSION_LAST_COMMAND_START_TIME," +
        "    @SESSION_LAST_COMMAND_END_TIME," +
        "    @SESSION_LAST_COMMAND_ELAPSED_TIME_MS," +
        "    @SESSION_IDLE_TIME_MS," +
        "    @SESSION_CPU_TIME_MS," +
        "    @SESSION_LAST_COMMAND," +                             
        "    @SESSION_LAST_COMMAND_CPU_TIME_MS," +
        "    @SESSION_STATUS," +
        "    @SESSION_READS," +
        "    @SESSION_WRITES," +
        "    @SESSION_READ_KB," +
        "    @SESSION_WRITE_KB," +
        "    @SESSION_COMMAND_COUNT," +
        "    @THREAD_POOL_USED," +
        "    @REQUEST_ACTIVITY_ID," +
        "    @CLIENT_ACTIVITY_ID" +
        ")"

    $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@PERIOD",[Data.SQLDBType]::DateTime2)), $period) | Out-Null | Out-Null
    $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@SESSION_ID",[Data.SQLDBType]::UniqueIdentifier)), [guid]$rowData.SESSION_ID) | Out-Null
    $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@SESSION_SPID",[Data.SQLDBType]::BigInt)), [long]$rowData.SESSION_SPID) | Out-Null
    $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@SESSION_CONNECTION_ID",[Data.SQLDBType]::BigInt)), [long]$rowData.SESSION_CONNECTION_ID) | Out-Null
    $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@SESSION_USER_NAME",[Data.SQLDBType]::NVarChar, 255)), [string]$rowData.SESSION_USER_NAME) | Out-Null
    $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@SESSION_USED_MEMORY",[Data.SQLDBType]::BigInt)), [long]$rowData.SESSION_USED_MEMORY) | Out-Null
    $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@SESSION_START_TIME",[Data.SQLDBType]::DateTime2)), [datetime]$rowData.SESSION_START_TIME) | Out-Null | Out-Null
    $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@SESSION_ELAPSED_TIME_MS",[Data.SQLDBType]::BigInt)), [long]$rowData.SESSION_ELAPSED_TIME_MS) | Out-Null
    $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@SESSION_LAST_COMMAND_START_TIME",[Data.SQLDBType]::DateTime2)), [datetime]$rowData.SESSION_LAST_COMMAND_START_TIME) | Out-Null | Out-Null
    $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@SESSION_LAST_COMMAND_END_TIME",[Data.SQLDBType]::DateTime2)), [datetime]$rowData.SESSION_LAST_COMMAND_END_TIME) | Out-Null | Out-Null
    $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@SESSION_LAST_COMMAND_ELAPSED_TIME_MS",[Data.SQLDBType]::BigInt)), [long]$rowData.SESSION_LAST_COMMAND_ELAPSED_TIME_MS) | Out-Null
    $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@SESSION_IDLE_TIME_MS",[Data.SQLDBType]::BigInt)), [long]$rowData.SESSION_IDLE_TIME_MS) | Out-Null
    $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@SESSION_CPU_TIME_MS",[Data.SQLDBType]::BigInt)), [long]$rowData.SESSION_CPU_TIME_MS) | Out-Null
    $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@SESSION_LAST_COMMAND",[Data.SQLDBType]::NVarChar, 0)), [string]$rowData.SESSION_LAST_COMMAND) | Out-Null
    $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@SESSION_LAST_COMMAND_CPU_TIME_MS",[Data.SQLDBType]::BigInt)), [long]$rowData.SESSION_LAST_COMMAND_CPU_TIME_MS) | Out-Null
    $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@SESSION_STATUS",[Data.SQLDBType]::BigInt)), [long]$rowData.SESSION_STATUS) | Out-Null
    $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@SESSION_READS",[Data.SQLDBType]::BigInt)), [long]$rowData.SESSION_READS) | Out-Null
    $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@SESSION_WRITES",[Data.SQLDBType]::BigInt)), [long]$rowData.SESSION_WRITES) | Out-Null
    $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@SESSION_READ_KB",[Data.SQLDBType]::BigInt)), [long]$rowData.SESSION_READ_KB) | Out-Null
    $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@SESSION_WRITE_KB",[Data.SQLDBType]::BigInt)), [long]$rowData.SESSION_WRITE_KB) | Out-Null
    $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@SESSION_COMMAND_COUNT",[Data.SQLDBType]::BigInt)), [long]$rowData.SESSION_COMMAND_COUNT) | Out-Null
    $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@THREAD_POOL_USED",[Data.SQLDBType]::NVarChar, 255)), [string]$rowData.THREAD_POOL_USED) | Out-Null
    $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@REQUEST_ACTIVITY_ID",[Data.SQLDBType]::NVarChar, 255)), [string]$rowData.REQUEST_ACTIVITY_ID) | Out-Null
    $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@CLIENT_ACTIVITY_ID",[Data.SQLDBType]::NVarChar, 255)), [string]$rowData.CLIENT_ACTIVITY_ID) | Out-Null

    $sqlCommand.ExecuteScalar() | Out-Null
}