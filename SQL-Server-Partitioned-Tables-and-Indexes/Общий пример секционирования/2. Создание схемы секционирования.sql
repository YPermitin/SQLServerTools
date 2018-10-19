-- Более подробная информация здесь:
-- https://docs.microsoft.com/ru-ru/sql/t-sql/statements/create-partition-scheme-transact-sql?view=sql-server-2017

create partition scheme [SchemeName] -- Имя схемы
as partition [FunctionName] -- Имя функции секционирования
to ([FG_1], [FG_2], [FG_3], [PRIMARY]); -- Перечисление файловых групп для каждой секции