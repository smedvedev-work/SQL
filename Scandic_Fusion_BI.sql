use [MecomsAxTest]
exec sp_change_users_login 'update_one', 'Scandic_Fusion_BI', 'Scandic_Fusion_BI'
exec sp_addrolemember 'db_owner', 'Scandic_Fusion_BI'
