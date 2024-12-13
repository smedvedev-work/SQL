USE [master]
RESTORE DATABASE [MecomsAxTest] FROM  DISK = N'E:\SQLBackups\MecomsAxProdMinusDay_backup_2020_05_16_075344_2310238.bak' WITH  FILE = 1,  MOVE N'MecomsAxProd' TO N'E:\SQLData\MecomsAxTest.mdf',  MOVE N'MecomsAxProd_log' TO N'E:\SQLData\MecomsAxTest_log.LDF',  NOUNLOAD,  REPLACE,  STATS = 5

GO


