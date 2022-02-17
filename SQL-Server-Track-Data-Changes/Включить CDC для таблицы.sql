-- ===================================================
-- Enable a Table CDC
-- https://docs.microsoft.com/ru-ru/sql/relational-databases/system-stored-procedures/sys-sp-cdc-enable-table-transact-sql?view=sql-server-ver15
-- ===================================================

USE [<Database_Name>]
GO

EXEC sys.sp_cdc_enable_table
    -- Схема
    @source_schema = N'<source_schema,sysname,source_schema>',
    -- Имя таблицы
    @source_name   = N'<source_name,sysname,source_name>',
    -- Имя роли для доступа к данным изменений
    @role_name     = NULL, -- N'<role_name,sysname,role_name>',
    -- Включение поддержки запросов для суммарных изменений (не обязателен)
    @supports_net_changes = 1,
    -- Имя уникального индекса для идентификации строк (не обязателен)
	@index_name    = N'<index_name,sysname,index_name>',
    -- Файловая группа для хранения таблиц изменений (не обязателен)
    @filegroup_name = N'<filegroup_name,sysname,filegroup_name>'
GO