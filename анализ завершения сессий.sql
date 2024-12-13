declare @startdate datetime = convert(datetime, '2020-01-01', 121)
declare @enddate datetime = convert(datetime, '2020-12-31', 121)
declare @nulldate datetime = convert(datetime, '1900-01-01', 121)
declare @livetime datetime = dateadd(mi,-15,getutcdate())
 select count ( * ) 'all sessions' from sysuserlog
 where --TERMINATEDOK = 1  and 
 CREATEDDATETIME between @startdate and @enddate
 select count ( * ) 'terminated sessions' from sysuserlog
 where TERMINATEDOK = 0 
 and ((LOGOUTDATETIME = @nulldate and CREATEDDATETIME < @livetime) or (LOGOUTDATETIME < @livetime and LOGOUTDATETIME != @nulldate))
 and CREATEDDATETIME between @startdate and @enddate
 select count ( * ) 'closed sessions' from sysuserlog
 where TERMINATEDOK = 1 
 and CREATEDDATETIME between @startdate and @enddate
 select count ( * ) 'potential live sessions' from sysuserlog
 where TERMINATEDOK = 0 
 and ((LOGOUTDATETIME = @nulldate and CREATEDDATETIME >= @livetime) or (LOGOUTDATETIME >= @livetime))
 and CREATEDDATETIME between @startdate and @enddate

 select COMPUTERNAME, --USERID, 
 convert(nvarchar(7), CREATEDDATETIME, 121) 'period',
 sum(case when TERMINATEDOK = 0 
		and ((LOGOUTDATETIME = @nulldate and CREATEDDATETIME < @livetime) or (LOGOUTDATETIME < @livetime and LOGOUTDATETIME != @nulldate))
		then 1 else 0 end) as 'terminated sessions',
 sum(case when TERMINATEDOK = 1
		then 1 else 0 end) as 'closed sessions',
 sum(case when TERMINATEDOK = 0 
		and ((LOGOUTDATETIME = @nulldate and CREATEDDATETIME > @livetime) or (LOGOUTDATETIME > @livetime))
		then 1 else 0 end) as 'potential live sessions'
 from sysuserlog
 where CREATEDDATETIME between @startdate and @enddate
 group by COMPUTERNAME, --USERID, 
 convert(nvarchar(7), CREATEDDATETIME, 121)