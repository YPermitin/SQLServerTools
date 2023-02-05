select
    -- Имя пользователя
    sp.name as login,
    -- Тип учетной записи. Возможные значения:
    --  * SQL_LOGIN - учетная запись SQL Server.
    --  * WINDOWS_LOGIN - учетная запись Windows.
    --  * CERTIFICATE_MAPPED_LOGIN - учетная запись, связанная с сертификатом.
    --  * ASYMMETRIC_KEY_MAPPED_LOGIN - учетная запись, связанная с асимметричным ключом
    sp.type_desc as login_type,
    -- Хеш пароля учетной записи (SHA-512)
    sl.password_hash,
    -- Дата создания
    sp.create_date,
    -- Дата изменения
    sp.modify_date,
    -- Состояние учетной записи (включена / выключена)
    case when sp.is_disabled = 1 then 'Disabled' else 'Enabled' end as status
from sys.server_principals sp
left join sys.sql_logins sl
          on sp.principal_id = sl.principal_id
where sp.type not in ('G', 'R')
order by sp.name;