-- =============================================================================================================
-- Author:		Permitin Y.A. (ypermitin@yandex.ru)
-- Create date: 2018-10-15
-- Description:	Скрипт для проверки необходимых прав на служебную базу данных
-- =============================================================================================================
USE [ExtendedSettingsFor1C];

SELECT
	ISNULL(current_right.permission_name, need_right.permission_name) permission_name,
	ISNULL(current_right.state_desc, 'NEED TO BE CONFIGURE!!!') status
FROM
	(SELECT DISTINCT rp.name, 
					ObjectType = rp.type_desc, 
					PermissionType = pm.class_desc, 
					pm.permission_name, 
					pm.state_desc
	FROM   sys.database_principals rp 
		   INNER JOIN sys.database_permissions pm 
				   ON pm.grantee_principal_id = rp.principal_id 
	WHERE rp.Name = 'public'
		AND rp.type_desc = 'DATABASE_ROLE' 
		AND pm.class_desc = 'DATABASE' 
		AND pm.class_desc = 'DATABASE'
		AND pm.state_desc = 'GRANT') current_right
	FULL JOIN
	(Select
		'CONNECT' AS permission_name
		UNION ALL
	Select 'EXECUTE' AS permission_name
		UNION ALL
	Select 'SELECT' AS permission_name) need_right
	ON current_right.permission_name = need_right.permission_name