# LSN (log sequence number)

LSN (log sequence number) - порядковый номер журнала транзакций, состоящий из трех частей и имеющий уникальное возрастающее значение. Используется для поддержания последовательности записей журнала транзакций в базе данных. Последнее позволяет поддерживать свойства ACID и выполнять действия по корректному восстановлению логов транзакций.

## Полезные ссылки

* [Introduction to Log Sequence Numbers](https://docs.microsoft.com/en-us/previous-versions/sql/sql-server-2008-r2/ms190411(v=sql.105)?redirectedfrom=MSDN) - общая информация об LSN (log sequence number).
* [Go LSN in SQL Server](https://www.sqlshack.com/go-lsn-in-sql-server/) - полезная информация при восстановлении логов транзакций.
* [Log Sequence Numbers and Restore Planning](https://docs.microsoft.com/en-us/previous-versions/sql/sql-server-2008-r2/ms190729(v=sql.105)) - LSN и план восстановления логов транзакций.
