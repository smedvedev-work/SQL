declare @AX_sessionNum nvarchar(128) = ''
select  @AX_sessionNum+= convert(nvarchar(10), [session id])+','from tempdb..AOS_sessions
where [Client type]='User' and Recordtype='START'
select @AX_sessionNum=left(@AX_sessionNum,len(@AX_sessionNum)-1)
select @AX_sessionNum

select * from tempdb..AOS_sessions
where [Client type]='User' and Recordtype='START'
order by [Login date and time] 
