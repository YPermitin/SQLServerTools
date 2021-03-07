<#
Пример выполнения запроса на нескольких сервера SQL Server удаленно и возращение результата.

Альтернативный путь - выполнение запроса с подключением напрямую к СУБД, но в этом случае нужен открытый порт.
Если такое возможно, то можно использовать инструмент DBATools (https://dbatools.io/).
#>

$script = {
    $connectionString = "Server=localhost;Database=master;Integrated Security=TRUE;";
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

    New-Object -TypeName PSCustomObject -Property @{Host=$env:computername; Sessions=$table;}
}

# В параметре "ComputerName" указываем список серверов, для которых нужно выполнить запрос
$results = Invoke-Command -ComputerName ServerName1, ServerName2 -ScriptBlock $script

foreach($server in $results)
{
    $hostname = $server.Host

    Write-Host "Hostname: $hostname"
    Write-Host ""
    foreach($sessionInfo in $server.Sessions)
    {
        $sessionInfo
    }
}