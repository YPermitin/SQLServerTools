SELECT  @@Servername AS ServerName ,
        DB_NAME() AS DBName ,
        o.name AS ViewName ,
        o.Type ,
        o.create_date
FROM    sys.objects o
WHERE   o.[Type] = 'SN' -- Synonym 
ORDER BY o.NAME;

--OR 
-- дополнительная информация о синонимах

SELECT  @@Servername AS ServerName ,
        DB_NAME() AS DBName ,
        s.name AS synonyms ,
        s.create_date ,
        s.base_object_name
FROM    sys.synonyms s
ORDER BY s.name;

GO