if (isnull(object_id('tempdb..##tables'), 0) != 0)										
	drop table ##tables									
SELECT 										
		object_id = o.object_id,								
		tname = OBJECT_NAME (o.object_id),								
        schema_id = o.schema_id,
        sname = SCHEMA_NAME(o.schema_id),
		reserved = SUM (s.reserved_page_count)* 8,								
		used = SUM (s.used_page_count)* 8,								
		data =  SUM (								
			CASE							
				WHEN (s.index_id < 2) THEN (s.in_row_data_page_count + s.lob_used_page_count + s.row_overflow_used_page_count)						
				ELSE s.lob_used_page_count + s.row_overflow_used_page_count						
			END							
			)* 8,							
		rows = convert (char(11), SUM (								
		CASE								
			WHEN (s.index_id < 2) THEN s.row_count							
			ELSE 0							
		END								
		))								
into ##tables										
FROM sys.dm_db_partition_stats s join sys.objects o 										
on o.object_id = s.object_id and o.type = 'u' 										
group by o.object_id, o.schema_id									
										
update t										
set t.used = t.used + it.used_page_count, 										
	t.reserved = t.reserved + it.reserved_page_count									
-- select it.parent_id, it.used_page_count, it.reserved_page_count										
from ##tables t join (SELECT it.parent_id, 										
				sum(reserved_page_count) as reserved_page_count, 						
				sum(used_page_count) as used_page_count						
		FROM sys.dm_db_partition_stats p, sys.internal_tables it								
		WHERE it.internal_type IN (202,204) AND p.object_id = it.object_id								
		group by it.parent_id) it 								
on t.object_id = it.parent_id										
										
select db_name() as [db name], sum(used) as [all used (kb)], sum(data) as [data size (kb)],
	sum(used) - sum(data) as [index size (kb)], sum(reserved) as [reserved (kb)], sum(reserved) - sum(used) as [not use (kb)],sum(used)/1024./1024. as [all usage (Gb)]
from ##tables										
										
SELECT 										
		'table name' = tname,	
        'shema_name' = sname,        
		'row count' = rows,								
		'used pages (Mb)' = cast (used / 1024. as numeric (17,3)),								
		'data only (Mb)' = cast (data / 1024. as numeric (17,3)),								
		'indexes (Mb) ' = cast ((used - data) / 1024. as numeric (17,3)),								
		'reserved (Mb)' = cast (reserved / 1024. as numeric (17,3)),								
		'not use (Mb)' = cast ((reserved - used) / 1024. as numeric (17,3)),								
		'data by row' = str(100.00 * data / (select sum(data) from ##tables), 5, 2) + '%',								
		'data from top' = str(100.00 * (select sum(data) from ##tables where used >= a.used) 								
										/ (select sum(data) from ##tables), 5, 2) + '%',
		'used by row' = str(100.00 * used / (select sum(used) from ##tables), 5, 2) + '%',								
		'used from top' = str(100.00 * (select sum(used) from ##tables where used >= a.used) 								
										/ (select sum(used) from ##tables), 5, 2) + '%'
										
from ##tables a										
order by 3 desc										
										
										
/*										
SELECT 										
		name = OBJECT_NAME (o.object_id),								
--		reserved = LTRIM (STR (SUM (s.reserved_page_count)* 8, 15, 0) + ' KB'),								
		usedpages = LTRIM (STR (SUM (s.used_page_count)* 8, 15, 0) + ' KB'),								
		data = LTRIM (STR ( SUM (								
			CASE							
				WHEN (s.index_id < 2) THEN (s.in_row_data_page_count + s.lob_used_page_count + s.row_overflow_used_page_count)						
				ELSE s.lob_used_page_count + s.row_overflow_used_page_count						
			END							
			)* 8, 15, 0) + ' KB'),							
		rows = convert (char(11), SUM (								
		CASE								
			WHEN (s.index_id < 2) THEN s.row_count							
			ELSE 0							
		END								
		))								
FROM sys.dm_db_partition_stats s join sys.objects o 										
on o.object_id = s.object_id and o.type = 'u' 										
group by o.object_id										
*/										
										
										
/*										
select datediff(ss,lag(logdatetime) over(order by id),logdatetime)/60. Duration_Mi,* 										
from [$GM_CompactDBComplete] nolock										
where step != 'CompressIndexes' and step != 'step_8'										
order by 2										
*/										
