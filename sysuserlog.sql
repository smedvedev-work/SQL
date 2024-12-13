declare @begindate datetime = '2021-01-11'
declare @enddate datetime = '2021-01-12'
select  computername, clienttype, type, TERMINATEDOK, 
convert(nvarchar(40), case when logoutdatetime < @begindate then 'without logout date' else 'logout ok' end) logout_status,
count(*)
 as count
 from sysuserlog 
 where createddatetime between @begindate and @enddate
--and logoutdatetime < @begindate 
--and (clienttype != 1 or type != 0)
and clienttype = 1 and type = 0 --only user sessions
group by computername, clienttype, type, TERMINATEDOK, case when logoutdatetime < @begindate then 'without logout date' else 'logout ok' end
order by 1, 2, 3, 4, 5 

declare @begindate datetime = '2021-01-12'
declare @enddate datetime = '2021-01-13'
select * from sysuserlog
where userid ='ILAUKSTE'
 and createddatetime between @begindate and @enddate --and TERMINATEDOK=0
order by CREATEDDATETIME desc

select * from SYSCLIENTSESSIONS
where userid ='ILAUKSTE'
order by LOGINDATETIME desc
select * from SYSSERVERSESSIONS

select * from sysuserlog
order by CREATEDDATETIME desc
