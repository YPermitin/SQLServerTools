<#
Получение списка всех соединений со SQL Server для работы с ними.
Пример содержит выполнение произвольного запроса.
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

$sqlConnection = new-object system.data.SqlClient.SQLConnection($connectionString);
$sqlConnection.Open();

$query = {
    DECLARE @AllConnections TABLE(
        SPID INT,
        Status VARCHAR(MAX),
        LOGIN VARCHAR(MAX),
        HostName VARCHAR(MAX),
        BlkBy VARCHAR(MAX),
        DBName VARCHAR(MAX),
        Command VARCHAR(MAX),
        CPUTime INT,
        DiskIO INT,
        LastBatch VARCHAR(MAX),
        ProgramName VARCHAR(MAX),
        SPID_1 INT,
        REQUESTID INT
    )
    INSERT INTO @AllConnections EXEC sp_who2
    SELECT * FROM @AllConnections
}.ToString();

$command = $sqlConnection.CreateCommand()
$command.CommandText = $query
$command.CommandTimeout = $sqlCmdTimeoutSeconds

$result = $command.ExecuteReader()
$table = new-object “System.Data.DataTable”
$table.Load($result)

foreach($connection in $table)
{
    $connection
}