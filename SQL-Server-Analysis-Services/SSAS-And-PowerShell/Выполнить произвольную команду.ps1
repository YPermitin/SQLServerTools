# Позволяет выполнять сценарий XMLA, сценарий TMSL, запрос выражений анализа данных (DAX), 
# запрос многомерных выражений (MDX) или оператор расширения интеллектуального анализа данных (DMX) для экземпляра служб Analysis Services.
# Подробнее:
# https://docs.microsoft.com/en-us/powershell/module/sqlserver/invoke-ascmd?view=sqlserver-ps

Invoke-ASCmd -Server:localhost -Query "SELECT * FROM $System.Discover_Commands"