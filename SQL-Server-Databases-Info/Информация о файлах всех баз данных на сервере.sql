create table #db_files(
    db_files varchar(300),
    file_loc varchar(300),
    filesizeMB decimal(9,2),
    spaceUsedMB decimal(9,2),
    FreespaceMB decimal(9,2)
)
    
 declare @strSQL nvarchar(2000)
 DECLARE @dbName varchar(MAX)
 DECLARE @getDBname CURSOR
    
 SET @getDBname = CURSOR FOR
 select name from sys.databases
    
 OPEN @getDBname
 FETCH NEXT
 FROM @getDBname INTO @dbName
 WHILE @@FETCH_STATUS = 0
 BEGIN
 PRINT @dbName
    
 select @strSQL =
     '
         use ' + @dbname + '
         INSERT INTO #db_files
         select
       name
     , filename
     , convert(decimal(12,2),round(a.size/128.000,2)) as FileSizeMB
     , convert(decimal(12,2),round(fileproperty(a.name,''SpaceUsed'')/128.000,2)) as SpaceUsedMB
     , convert(decimal(12,2),round((a.size-fileproperty(a.name,''SpaceUsed''))/128.000,2)) as FreeSpaceMB
     from dbo.sysfiles a
     '
     exec sp_executesql @strSQL
    
 FETCH NEXT
 FROM @getDBname INTO @dbName
    
 END
 CLOSE @getDBname
 DEALLOCATE @getDBname
 GO
    
 select 
    * 
 from #db_files