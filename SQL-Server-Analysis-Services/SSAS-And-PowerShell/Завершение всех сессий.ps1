# Пример скрипта для завершения всех сессий
# Плюс есть примеры условий, которые можно делать для выборочного завершения.

# Базовые настройки
$errorActionPreference = 'Stop'

# SSAS настройки
$ssasServer = "localhost"
$ssasQuery = 'SELECT * FROM $SYSTEM.DISCOVER_SESSIONS'

[XML]$sessionsData = Invoke-ASCmd -Server:$ssasServer -Query $ssasQuery

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
    $rowData

    # Условие на время работы сессии. Если меньше 30 секунд, то ничего не делаем
    #if ($rowData.SESSION_ELAPSED_TIME_MS -le 60000)
    #{
    #    continue
    #}

    # Подготавливаем и отправляем команду отмены сессии
    $xmla = {
    <Cancel xmlns="http://schemas.microsoft.com/analysisservices/2003/engine">  

       <SessionID><<<sessionId>>></SessionID>  

    <CancelAssociated>1</CancelAssociated>  
    </Cancel>  
    }.ToString()
    $xmla = $xmla.Replace("<<<sessionId>>>", $rowData.SESSION_ID)
    $xmlaTempFile = New-TemporaryFile
    $xmla | Out-File $xmlaTempFile

    Invoke-ASCmd -Server:localhost -InputFile $xmlaTempFile >> $null

    # Удаляем временные файлы
    Remove-Item -Path $xmlaTempFile
}