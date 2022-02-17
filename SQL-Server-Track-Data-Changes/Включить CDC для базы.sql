-- ================================
-- Enable Database for CDC
-- https://docs.microsoft.com/ru-ru/sql/relational-databases/system-stored-procedures/sys-sp-cdc-enable-db-transact-sql?view=sql-server-ver15
-- ================================

USE [<Database_Name>]
GO

EXEC sys.sp_cdc_enable_db
GO