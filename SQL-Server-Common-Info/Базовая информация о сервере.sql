-- Имена сервера и экземпляра 
Select @@SERVERNAME as [Server\Instance]; 

-- версия SQL Server 
Select @@VERSION as SQLServerVersion; 

-- экземпляр SQL Server 
Select @@ServiceName AS ServiceInstance;

 -- Текущая БД (БД, в контексте которой выполняется запрос)
Select DB_NAME() AS CurrentDB_Name;