-- Второй метод «реверс-инжиниринга» зависимостей в вашей БД – это запросы к системным представлениям каталога, связанным со внешними ключами.

--Independent tables

SELECT  Name AS InDependentTables
FROM    sys.tables
WHERE   object_id NOT IN ( SELECT  referenced_object_id
                             FROM   sys.foreign_key_columns )
                                                -- Check for parents
        AND object_id NOT IN ( SELECT parent_object_id
                                 FROM   sys.foreign_key_columns )
                                               -- Check for Dependents
ORDER BY Name 

-- Tables with dependencies.

SELECT DISTINCT
        OBJECT_NAME(referenced_object_id) AS ParentTable ,
        OBJECT_NAME(parent_object_id) AS DependentTable ,
        OBJECT_NAME(constraint_object_id) AS ForeignKeyName
FROM    sys.foreign_key_columns
ORDER BY ParentTable ,
        DependentTable 

-- Top level of the pyramid tables. Tables with no parents.

SELECT DISTINCT
        OBJECT_NAME(referenced_object_id) AS TablesWithNoParent
FROM    sys.foreign_key_columns
WHERE    referenced_object_id NOT IN ( SELECT  parent_object_id
                                        FROM    sys.foreign_key_columns )
ORDER BY 1 

-- Bottom level of the pyramid tables. 
-- Tables with no dependents. (These are the leaves on a tree.)

SELECT DISTINCT
        OBJECT_NAME(parent_object_id) AS TablesWithNoDependents
FROM    sys.foreign_key_columns
WHERE   parent_object_id NOT IN ( SELECT  referenced_object_id
                                    FROM    sys.foreign_key_columns )
ORDER BY 1

-- Tables with both parents and dependents. 
-- Tables in the middle of the hierarchy

SELECT DISTINCT
        OBJECT_NAME(referenced_object_id) AS MiddleTables
FROM    sys.foreign_key_columns
WHERE    referenced_object_id IN ( SELECT  parent_object_id
                                    FROM    sys.foreign_key_columns )
        AND parent_object_id  NOT IN ( SELECT   referenced_object_id
                                        FROM    sys.foreign_key_columns )
ORDER BY 1;

-- in rare cases, you might find a self-referencing dependent table.
-- Recursive (self) referencing table dependencies. 

SELECT DISTINCT
        OBJECT_NAME(referenced_object_id) AS ParentTable ,
        OBJECT_NAME(parent_object_id) AS ChildTable ,
        OBJECT_NAME(constraint_object_id) AS ForeignKeyName
FROM    sys.foreign_key_columns
WHERE    referenced_object_id = parent_object_id
ORDER BY 1 ,
        2;