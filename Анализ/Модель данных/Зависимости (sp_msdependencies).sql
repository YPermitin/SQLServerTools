-- Sp_msdependencies – это недокументированная хранимая процедура, которая может быть очень полезна для разбора сложных взаимозависимостей таблиц.


EXEC sp_msdependencies '?' -- Displays Help 

/*
sp_MSobject_dependencies name = NULL, type = NULL, flags = 0x01fd
  name:  name or null (all objects of type)
  type:  type number (see below) or null
         if both null, get all objects in database
  flags is a bitmask of the following values:
         0x10000  = return multiple parent/child rows per object
         0x20000  = descending return order
         0x40000  = return children instead of parents
         0x80000  = Include input object in output result set
         0x100000 = return only firstlevel (immediate) parents/children
         0x200000 = return only DRI dependencies
         power(2, object type number(s))  to return in results set:
                0 (1        - 0x0001)     - UDF
                1 (2        - 0x0002)     - system tables or MS-internal objects
                2 (4        - 0x0004)     - view
                3 (8        - 0x0008)     - user table
                4 (16       - 0x0010)     - procedure
                5 (32       - 0x0020)     - log
                6 (64       - 0x0040)     - default
                7 (128      - 0x0080)     - rule
                8 (256      - 0x0100)     - trigger
                12 (1024     - 0x0400) - uddt
         shortcuts:
                29   (0x011c) - trig, view, user table, procedure
                448  (0x00c1) - rule, default, datatype
                4606 (0x11fd) - all but systables/objects
                4607 (0x11ff) – all
*/

-- Примеры

EXEC sp_msdependencies NULL    -- Все зависимости в БД

EXEC sp_msdependencies NULL, 3 -- Зависимости определённой таблицы

-- sp_MSdependencies — Только верхний уровень
-- Объекты, которые зависят от указанного объекта

EXEC sp_msdependencies N'Sales.Customer',null, 1315327 -- Change Table Name

-- sp_MSdependencies - Все уровни
-- Объекты, которые зависят от указанного объекта

EXEC sp_MSdependencies N'Sales.Customer', NULL, 266751 -- Change Table Name

-- Объекты, от которых зависит указанный объект

EXEC sp_MSdependencies N'Sales.Customer', null, 1053183 -- Change Table

-- Если вы хотите получить список зависимостей таблиц, вы можете использовать временную таблицу

CREATE TABLE #TempTable1
    (
      Type INT ,
      ObjName VARCHAR(256) ,
      Owner VARCHAR(25) ,
      Sequence INT
    ); 

INSERT  INTO #TempTable1
        EXEC sp_MSdependencies NULL 

SELECT  *
FROM     #TempTable1
WHERE   Type = 8 --Tables 
ORDER BY Sequence ,
        ObjName 

DROP TABLE #TempTable1;