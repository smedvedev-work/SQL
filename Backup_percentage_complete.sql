select r.session_id,r.command,convert(numeric(6,2),r.percent_complete)
as [percent complete],convert(varchar(20),dateadd(ms,r.estimated_completion_time,getdate()),20) as [eta completion time],
convert(numeric(10,2),r.total_elapsed_time/1000.0/60.0) as [elapsed min],
convert(numeric(10,2),r.estimated_completion_time/1000.0/60.0) as [eta min],
convert(numeric(10,2),r.estimated_completion_time/1000.0/60.0/60.0) as [eta hours],
convert(varchar(1000),(select substring(text,(r.statement_start_offset+2)/2,
	(case when r.statement_end_offset = -1 then 1000 else r.statement_end_offset end -r.statement_start_offset+2)/2 )
from sys.dm_exec_sql_text(sql_handle))) as [query]
from sys.dm_exec_requests r where session_id = 21