declare @AX_sessionNum int = 76 -- use 0 value for init log session, use AX session number for log AX session SQL data


declare @AX_SessionStr nvarchar(24) = '% ' +convert(nvarchar(20),@AX_sessionNum)  + ' %'
declare @logDateTime datetime
--select @AX_SessionStr

if @AX_sessionNum = 0
begin
	if object_id('tempdb..AX_sessions') is not null
		drop table tempdb..AX_sessions
	if object_id('tempdb..AX_sessions_locks') is not null
		drop table tempdb..AX_sessions_locks
end
else
begin
	if object_id('tempdb..#spid') is not null
		drop table #spid
	if object_id('tempdb..#AX_sessions') is not null
			drop table #AX_sessions
	if object_id('tempdb..#AX_sessions_locks') is not null
			drop table #AX_sessions_locks


	select * into #spid from
	(
	select s.spid from master..sysprocesses S 
	where exists (select 1 from sys.dm_exec_sessions ES where ES.session_id = S.spid and cast(ES.context_info as varchar(128)) like @AX_SessionStr)
	) a

	set @logDateTime = getdate()
	select @logDateTime as LogDateTime, 
		s.last_batch, cast(ES.context_info as varchar(128)) as context_info, s.spid, s.blocked, s.waittime, s.waittype, 
		db_name(s.dbid) db_name, 
		s.open_tran, s.status, s.cmd, 
		s.loginame, s.program_name, s.hostname, s.hostprocess,  
		s.cpu, s.physical_io, s.memusage, s.login_time, case when s.sql_handle IS NULL
					then ' '
					else ( substring(st.text,(s.stmt_start+2)/2,(case when s.stmt_end = -1        
								then len(convert(nvarchar(MAX),st.text))*2      
								else s.stmt_end    
									end - s.stmt_start + 2) /2  ) )
			end as query_text, qp.query_plan
	 into #AX_sessions
	from master..sysprocesses S OUTER APPLY SYS.DM_EXEC_SQL_TEXT(S.SQL_HANDLE)AS ST
	LEFT JOIN sys.dm_exec_sessions as ES on ES.session_id = S.spid
	left join sys.dm_exec_requests as ER on er.session_id = es.session_id
	OUTER APPLY sys.dm_exec_query_plan (er.plan_handle) as qp 
	where s.spid in (select spid from #spid) 

 
	if exists (select 1 from #AX_sessions where last_batch > dateadd(mi, -1, getdate()))
	begin
		waitfor delay '00:01:00'
		truncate table #AX_sessions
		set @logDateTime = getdate()
		insert #AX_sessions
		select @logDateTime as LogDateTime, 
			s.last_batch, cast(ES.context_info as varchar(128)) as context_info, s.spid, s.blocked, s.waittime, s.waittype, 
			db_name(s.dbid) db_name, 
			s.open_tran, s.status, s.cmd, 
			s.loginame, s.program_name, s.hostname, s.hostprocess,  
			s.cpu, s.physical_io, s.memusage, s.login_time, case when s.sql_handle IS NULL
						then ' '
						else ( substring(st.text,(s.stmt_start+2)/2,(case when s.stmt_end = -1        
									then len(convert(nvarchar(MAX),st.text))*2      
									else s.stmt_end    
										end - s.stmt_start + 2) /2  ) )
				end as query_text, qp.query_plan
		from master..sysprocesses S OUTER APPLY SYS.DM_EXEC_SQL_TEXT(S.SQL_HANDLE)AS ST
		LEFT JOIN sys.dm_exec_sessions as ES on ES.session_id = S.spid
		left join sys.dm_exec_requests as ER on er.session_id = es.session_id
		OUTER APPLY sys.dm_exec_query_plan (er.plan_handle) as qp 
		where s.spid in (select spid from #spid) 
	end	

	select req_spid, 
	case req_mode when 0 then 'NULL' when 1 then 'Sch-S' 
		when 2 then 'Sch-M' when 3 then 'S'when 4 then 'U' 
		when 5 then 'X' when 6 then 'IS' when 7 then 'IU' 
		when 8 then 'IX' when 9 then 'SIU' 
		when 10 then 'SIX' when 11 then 'UIX' 
		when 12 then 'BU' when 13 then 'RangeS_S' 
		when 14 then 'RangeS_U' when 15 then 'RangeI_N' 
		when 16 then 'RangeI_S' when 17 then 'RangeI_U' 
		when 18 then 'RangeI_X' when 19 then 'RangeX_S' 
		when 20 then 'RangeX_U' when 21 then 'RangeX_X' 
		else convert(varchar(9), req_mode) end req_mode, 
	case req_status when 1 then 'Granted' when 2 then 'Converting' 
			when 3 then 'Waiting' else convert(varchar(10), req_status) end req_status, 
	case rsc_type when 1 then 'NULL' when 2 then 'Database' when 3 then 'File' when 4 then 'Index' 
			when 5 then 'Table' when 6 then 'Page' when 7 then 'Key' when 8 then 'Extent' 
			when 9 then 'RID (Row ID)' when 10 then 'Application' else convert(varchar(12), rsc_type) end rsc_type,
	--db_name(rsc_dbid) db_name, object_name(rsc_objid, rsc_dbid) object_name,  count(*)  count
	db_name(rsc_dbid) db_name, 
	case db_name(rsc_dbid) when 'tempdb' then convert(nvarchar(30),rsc_objid) else object_name(rsc_objid, rsc_dbid) end object_name,  
	count(*) "count"
	into #AX_sessions_locks
	from master..syslockinfo 
	where req_spid  in (select spid from #spid) 
	group by req_spid, req_mode, req_status, rsc_type, rsc_dbid, rsc_objid
	order by 1, 2, 5

	if object_id('tempdb..AX_sessions') is null
		select * into tempdb..AX_sessions from #AX_sessions where 1=0
	if object_id('tempdb..AX_sessions_locks') is null
		select * into tempdb..AX_sessions_locks from #AX_sessions_locks where 1=0

	insert tempdb..AX_sessions select * from #AX_sessions
	insert tempdb..AX_sessions_locks select * from #AX_sessions_locks 
end

/*
--for get result
	select * from tempdb..AX_sessions
	select * from tempdb..AX_sessions_locks
*/