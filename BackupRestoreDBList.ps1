$BackupPath="\\lg-ns-fs-dev\_TMP_BackUp\lg-ns-db-dev_231015"
$DBSrv="lg-ns-db-dev"
$DBList= @("MecomsAxDev_model"
#,"LGAP_MIGR"
#,"upe"
#,"MecomsAxTest_model"
#,"MecomsAxTestQA_model"
#,"IntermediateBalanceQA"
#,"IntermediateBalanceTest"
#,"MecomsAxSave"
#,"MecomsAxTest"
)
$Date=(Get-Date -format "yyMMdd")

$DBList | ForEach-Object {
  $BackupDir = ($BackupPath+"\"+$_+"\")
  New-Item -Path "$BackupDir" -ItemType Directory -Force | Out-Null
  
  Backup-SqlDatabase -ServerInstance $DBSrv -Database $_ -BackupFile ($BackupDir+$_+"_"+$Date+".bak") -CompressionOption On
}

-----

$BackupPath="\\lg-ns-fs-dev\_TMP_BackUp\lg-ns-db-dev_231015"
$DataPath="E:\SQLData\"
$LogPath="E:\SQLData\"
$DBSrv="lg-ns-db-dev"
$DBList= @("MecomsAxDev_model"
#,"LGAP_MIGR"
#,"upe"
#,"MecomsAxTest_model"
#,"MecomsAxTestQA_model"
#,"IntermediateBalanceQA"
#,"IntermediateBalanceTest"
#,"MecomsAxSave"
#,"MecomsAxTest"
)
$Date=(Get-Date -format "yyMMdd")

$DBList | ForEach-Object {
  $BackupDir = ($BackupPath+"\"+$_+"\")
  $RelocateData = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile($_, ($DataPath+$_+".mdf"))
  $RelocateLog = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile(($_+"_Log"), ($LogPath+$_+"_log.ldf"))
  
  Restore-SqlDatabase -ServerInstance $DBSrv -Database "MecomsAxDev_model" -BackupFile ($BackupDir+$_+"_"+$Date+".bak") -RelocateFile @($RelocateData,$RelocateLog)
}
