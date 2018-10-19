-- Более подробная информация здесь: 
-- https://docs.microsoft.com/ru-ru/sql/t-sql/statements/create-partition-function-transact-sql?view=sql-server-2017
CREATE PARTITION FUNCTION 
                        [FunctionName] -- Имя функции секционирования
                        (numeric(15,2)) -- Тип поля разделителя секций
AS RANGE LEFT -- Каким образом определяется принадлежность значения секции
FOR VALUES (1, 100, 1000);
