#pragma rtGlobals=3		// Use modern global access method and strict wave access.
function input()
	wave year
	wave month
	wave day
	wave hour
	wave minute
	wave second
	wave value
	
	nvar year1
	nvar month1
	nvar day1
	nvar hour1
	nvar minute1
	nvar second1
	nvar value1
	
	variable year2=year1
	variable month2=month1
	variable day2=day1
	variable hour2=hour1
	variable minute2=minute1
	variable second2=second1
	variable value2=value1
	
	prompt year2, "year:"
	prompt month2, "month:"
	prompt day2, "day:"
	prompt hour2, "hour:"
	prompt minute2, "minute:"
	prompt second2, "second:"
	prompt value2, "value:"
	
	DoPrompt "Input Data Point", year2, month2, day2, hour2, minute2, second2, value2
	
	year1=year2
	month1=month2
	day1=day2
	hour1=hour2
	minute1=minute2
	second1=second2
	value1=value2
	
	variable PrevPoints=numpnts(year)
	
	insertpoints PrevPoints,1, year
	insertpoints PrevPoints,1, month
	insertpoints PrevPoints,1, day
	insertpoints PrevPoints,1, hour
	insertpoints PrevPoints,1, minute
	insertpoints PrevPoints,1, second
	insertpoints PrevPoints,1, value
	
	year[PrevPoints]=year1
	month[prevpoints]=month1
	day[prevpoints]=day1
	hour[prevpoints]=hour1
	minute[prevpoints]=minute1
	second[prevpoints]=second1
	value[prevpoints]=value1
	
	duplicate /o year date_inseconds
	date_inseconds[] = date2secs(year[p],month[p],day[p])+hour[p]*60^2+minute[p]*60+second[p]
	setscale d, 0,0,"dat",date_inseconds
	
end