# Пример выполнения запроса с обработкой результата, который возвращается в виде XML
# В данном случае мы получаем список активных сессий и их характеристики (нагрузку по CPU, памяти, текст команды и др.)

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
}