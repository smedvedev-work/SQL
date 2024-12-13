select s.last_batch, s.spid, s.blocked, s.waittime, s.waittype, 
db_name(s.dbid) db_name, 
s.open_tran, s.status, s.cmd, 
s.loginame, s.program_name, s.hostname, s.hostprocess, 
s.cpu, s.physical_io, s.memusage, s.login_time, a.TEXT,
* from master..sysprocesses S CROSS APPLY SYS.DM_EXEC_SQL_TEXT(S.SQL_HANDLE)AS A 
where s.blocked <> 0 or s.spid in (select blocked from master..sysprocesses)
or open_tran > 0 -- эту строку закомментировать если нужны только цепочки блокировок
--order by 15 desc
order by 3, 1 desc
