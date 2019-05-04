# Строка подключения к базе
$connectionString = "<строка подключения к базе с логами>";
# Таблица с логами Extended Events
$tableWithLogName = "<имя таблицы с логами>";
# Размер порции для обработки записей
$portion = 100;

$sqlConnection = new-object system.data.SqlClient.SQLConnection($connectionString);
$sqlConnection.Open();
$sqlConnectionForUpdate = new-object system.data.SqlClient.SQLConnection($connectionString);
$sqlConnectionForUpdate.Open();

# Проверяем наличие колонок в логах
$batch_text_exist = $false;
$sql_text_exist = $false;
$statement_exist = $false;
$database_name_exist = $false;
$sqlCmd = New-Object System.Data.SqlClient.SqlCommand
$sqlCmd.Connection = $sqlConnection
$sqlCmd.CommandText = "
    SELECT 
	    cls.column_for_check AS [Name]
	    ,CASE WHEN cl_info.column_id IS NOT NULL THEN 1 ELSE 0 END AS [exist]
    FROM (
		    SELECT 'batch_text' column_for_check
		    UNION ALL
		    SELECT 'sql_text' column_for_check
		    UNION ALL
		    SELECT 'statement' column_for_check
		    UNION ALL
		    SELECT 'database_name' column_for_check
	    ) cls 
	    LEFT JOIN sys.columns cl_info
	    ON cls.column_for_check = cl_info.[name]
		    AND cl_info.[Object_ID] = Object_ID(N'dbo." + $tableWithLogName + "')";
$paramLastRowId = $sqlCmd.Parameters.Add("@lastRowID", $lastRowID);
$reader = $sqlCmd.ExecuteReader()
if($reader.HasRows -eq $true)
{
    while ($reader.Read()) 
    {
        if($reader["Name"] -eq "batch_text")
        {
            if($reader["exist"] -eq 1)
            {
                $batch_text_exist = $true;
            }
        } elseif($reader["Name"] -eq "sql_text")
        {
            if($reader["exist"] -eq 1)
            {
                $sql_text_exist = $true;
            }
        } elseif($reader["Name"] -eq "statement")
        {
            if($reader["exist"] -eq 1)
            {
                $statement_exist = $true;
            }
        } elseif($reader["Name"] -eq "database_name")
        {
            if($reader["exist"] -eq 1)
            {
                $database_name_exist = $true;
            }
        }
    }
}
$reader.Close()  

if($batch_text_exist -eq $false -and
    $sql_text_exist -eq $false -and
    $statement_exist -eq $false)
{
    $sqlConnection.Close();
    $sqlConnectionForUpdate.Close();
    return;
}

$lastRowID = 0;
$finish = $false;

Do
{    
    $sqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $sqlCmd.Connection = $sqlConnection
    $sqlCmd.CommandText = "
        SELECT TOP (" + $portion + ")
	          -- Ключевые поля
	          [ID]
              " + $(if ($database_name_exist) {",[database_name]"} Else {""}) +  "	          
              ,[timestamp (UTC)] AS [timestamp]
              -- Поля для обработки
              " + $(if ($batch_text_exist) {",[batch_text]"} Else {""}) +  "
	          " + $(if ($statement_exist) {",[sql_text]"} Else {""}) +  "    
	          " + $(if ($sql_text_exist) {",[statement]"} Else {""}) +  "       
          FROM [dbo].[" + $tableWithLogName + "]
          WHERE [ID] > @lastRowID
          ORDER BY
	          -- Сортировка по ключевым полям
	          [ID]
	          ,[timestamp (UTC)]";
    $paramLastRowId = $sqlCmd.Parameters.Add("@lastRowID", $lastRowID);
    $reader = $sqlCmd.ExecuteReader()
    
    if($reader.HasRows -eq $true)
    {
        while ($reader.Read()) 
        {
           
            $rowID = $reader["ID"];
            $DatabaseName =  $(if ($database_name_exist) { $reader["database_name"] } Else { "" });
            $timestamp = $reader["timestamp"];                       

            if($batch_text_exist -eq $true)
            {
                $batch_text = $reader["batch_text"];
                $batch_text = $batch_text -replace "#tt[\d]+", "ttN";
                $batch_text = $batch_text -replace "@P[\d]+", "@PN";
            }

            if($sql_text_exist -eq $true)
            {
                $sql_text = $reader["sql_text"];
                $sql_text = $sql_text -replace "#tt[\d]+", "ttN";
                $sql_text = $sql_text -replace "@P[\d]+", "@PN";
            }

            if($statement_exist -eq $true)
            {
                $statement = $reader["statement"];
                $statement = $statement -replace "#tt[\d]+", "ttN";
                $statement = $statement -replace "@P[\d]+", "@PN";
            }

            # Обновляем данные в записи
            $sqlCmd_updateLogRecord = New-Object System.Data.SqlClient.SqlCommand
            $sqlCmd_updateLogRecord.Connection = $sqlConnectionForUpdate
            $sqlCmd_updateLogRecord.CommandText = "
                UPDATE [dbo].[QueryAnalysis] SET
                " + $(if ($batch_text_exist) {"     [batch_text] = @new_batch_text,"} Else {""}) +  "
	            " + $(if ($statement_exist) {"     [statement] = @new_statement,"} Else {""}) +  "    
	            " + $(if ($sql_text_exist) {"     [sql_text] = @new_sql_text"} Else {""}) +  "       
                WHERE [timestamp (UTC)] = @timestamp
                " + $(if ($database_name_exist) {"AND [database_name] = @databaseName"} Else {""}) +  "	                
	                AND [ID] = @RowID";
            $newParam = $sqlCmd_updateLogRecord.Parameters.Add("RowID", $rowID);
            if($database_name_exist)
            {
                $newParam = $sqlCmd_updateLogRecord.Parameters.Add("databaseName", $DatabaseName);
            }
            $newParam = $sqlCmd_updateLogRecord.Parameters.Add("timestamp", $timestamp);
            if($batch_text_exist)
            {
                $newParam = $sqlCmd_updateLogRecord.Parameters.Add("new_batch_text", $batch_text);
            }
            if($statement_exist)
            {
                $newParam = $sqlCmd_updateLogRecord.Parameters.Add("new_statement", $statement);
            }
            if($sql_text_exist)
            {
                $newParam = $sqlCmd_updateLogRecord.Parameters.Add("new_sql_text", $sql_text);
            }
            $resultExec = $sqlCmd_updateLogRecord.ExecuteNonQuery();

            $lastRowID = $rowID;

            $finish = $true;
        }
    } Else 
    {
        $finish = $true;
    } 
    
    $reader.Close()  

} while($finish -ne $true)


$sqlConnection.Close();
$sqlConnectionForUpdate.Close();