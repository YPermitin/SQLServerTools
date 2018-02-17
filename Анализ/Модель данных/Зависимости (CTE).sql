-- How to find the hierarchical dependencies
-- Solve recursive queries using Common Table Expressions (CTE)

WITH     TableHierarchy (  ParentTable, DependentTable, Level )
          AS (

-- Anchor member definition (First level group to start the process)
               SELECT DISTINCT
                        CAST(NULL AS  INT) AS ParentTable ,
                        e.referenced_object_id AS DependentTable ,
                        0 AS Level
               FROM     sys.foreign_key_columns AS e
               WHERE    e.referenced_object_id NOT IN (
                        SELECT  parent_object_id
                        FROM    sys.foreign_key_columns )

-- Add filter dependents of only one parent table
-- AND Object_Name(e.referenced_object_id) = 'User'

               UNION ALL

-- Recursive member definition (Find all the layers of dependents)
               SELECT --Distinct
                        e.referenced_object_id AS ParentTable ,
                        e.parent_object_id AS DependentTable ,
                        Level + 1
               FROM     sys.foreign_key_columns AS e
                        INNER JOIN TableHierarchy AS d
                               ON ( e.referenced_object_id ) = 
                                                      d.DependentTable
             )

    -- Statement that executes the CTE

SELECT DISTINCT
        OBJECT_NAME(ParentTable) AS ParentTable ,
        OBJECT_NAME(DependentTable) AS DependentTable ,
        Level
FROM     TableHierarchy
ORDER BY Level ,
        ParentTable ,
        DependentTable;