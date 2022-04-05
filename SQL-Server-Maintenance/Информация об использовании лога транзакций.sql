/*
Получение информации об использовании лога транзакций
https://docs.microsoft.com/ru-ru/sql/t-sql/database-console-commands/dbcc-sqlperf-transact-sql?view=sql-server-ver15
https://www.mssqltips.com/sqlservertip/1225/how-to-determine-sql-server-database-transaction-log-usage/

В итоге получим набор данных вида:
* База данных
* Размер лога транзакций (МБ)
* Процент использования лога транзакций (%)
* Статус

Пример:
Database Name Log Size (MB) Log Space Used (%) Status        
------------- ------------- ------------------ -----------   
master         3.99219      14.3469            0   
tempdb         1.99219      1.64216            0   
model          1.0          12.7953            0   
msdb           3.99219      17.0132            0   
AdventureWorks 19.554688    17.748701          0  
*/

DBCC SQLPERF(logspace)