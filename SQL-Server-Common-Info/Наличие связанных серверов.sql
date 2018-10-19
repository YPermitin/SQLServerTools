EXEC sp_helpserver; 

--OR 

EXEC sp_linkedservers; 

--OR 

SELECT  @@SERVERNAME AS Server ,
        Server_Id AS  LinkedServerID ,
        name AS LinkedServer ,
        Product ,
        Provider ,
        Data_Source ,
        Modify_Date
FROM    sys.servers
ORDER BY name; 

GO