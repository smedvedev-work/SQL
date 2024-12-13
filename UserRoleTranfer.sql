---https://www.sqlshack.com/move-or-copy-sql-logins-with-assigning-roles-and-permissions/

SELECT 'IF (SUSER_ID('+QUOTENAME(SP.name,'''')+') IS NULL) BEGIN CREATE LOGIN ' +QUOTENAME(SP.name)+
               CASE 
                    WHEN SP.type_desc = 'SQL_LOGIN' THEN ' WITH PASSWORD = ' +CONVERT(NVARCHAR(MAX),SL.password_hash,1)+ ' HASHED, CHECK_EXPIRATION = ' 
                        + CASE WHEN SL.is_expiration_checked = 1 THEN 'ON' ELSE 'OFF' END +', CHECK_POLICY = ' +CASE WHEN SL.is_policy_checked = 1 THEN 'ON,' ELSE 'OFF,' END
                    ELSE ' FROM WINDOWS WITH'
                END 
       +' DEFAULT_DATABASE=[' +SP.default_database_name+ '], DEFAULT_LANGUAGE=[' +SP.default_language_name+ '] END;' COLLATE SQL_Latin1_General_CP1_CI_AS AS [-- Logins To Be Created --]
FROM sys.server_principals AS SP 
LEFT JOIN sys.sql_logins AS SL ON SP.principal_id = SL.principal_id
WHERE SP.type IN ('S','G','U')
        AND SP.name NOT LIKE '##%##'
        AND SP.name NOT LIKE 'NT AUTHORITY%'
        AND SP.name NOT LIKE 'NT SERVICE%'
        AND SP.name <> ('sa')
        AND SP.name <> 'distributor_admin'

-----

SELECT 
'EXEC master..sp_addsrvrolemember @loginame = N''' + SL.name + ''', @rolename = N''' + SR.name + ''';
' AS [-- Roles To Be Assigned --]
FROM master.sys.server_role_members SRM
INNER JOIN master.sys.server_principals SR ON SR.principal_id = SRM.role_principal_id
    JOIN master.sys.server_principals SL ON SL.principal_id = SRM.member_principal_id
WHERE SL.type IN ('S','G','U')
        AND SL.name NOT LIKE '##%##'
        AND SL.name NOT LIKE 'NT AUTHORITY%'
        AND SL.name NOT LIKE 'NT SERVICE%'
        AND SL.name <> ('sa')
        AND SL.name <> 'distributor_admin';

-----FOR EVERY DB

SELECT 'USE '+ DB_NAME()+'; CREATE USER ['+dp.name+'] FOR LOGIN ['+dp.name+'];'+ 
        'ALTER USER ['+dp.name+'] WITH DEFAULT_SCHEMA=['+dp.default_schema_name+'];' AS [-- Logins To Be Created --]
FROM sys.database_principals AS dp
INNER JOIN sys.server_principals sp ON dp.sid = sp.sid
WHERE (dp.type in ('S','G','U'))
        AND dp.name NOT LIKE '##%##'
        AND dp.name NOT LIKE 'NT AUTHORITY%'
        AND dp.name NOT LIKE 'NT SERVICE%'
        AND dp.name <> ('sa')
        AND dp.default_schema_name IS NOT NULL
        AND dp.name <> 'distributor_admin'
        AND dp.principal_id > 4

SELECT 'USE '+ DB_NAME()+'; '+CASE WHEN dp.state <> 'W' THEN dp.state_desc ELSE 'GRANT' END +' ' + 
        dp.permission_name + ' TO ' + QUOTENAME(dpg.name) COLLATE database_default + 
        CASE WHEN dp.state <> 'W' THEN '' ELSE ' WITH GRANT OPTION' END +';' AS [-- Permission To Be Assign to the User --]
FROM    sys.database_permissions AS dp
INNER JOIN sys.database_principals AS dpg ON dp.grantee_principal_id = dpg.principal_id
WHERE   dp.major_id = 0 AND dpg.principal_id > 4
        AND (dpg.type in ('S','G','U'))
        AND dpg.name NOT LIKE '##%##'
        AND dpg.name NOT LIKE 'NT AUTHORITY%'
        AND dpg.name NOT LIKE 'NT SERVICE%'
        AND dpg.name <> ('sa')
        AND dpg.default_schema_name IS NOT NULL
        AND dpg.name <> 'distributor_admin'
        AND dpg.principal_id > 4
ORDER BY dpg.name