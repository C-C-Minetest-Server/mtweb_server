local months = {
  "Jan", "Feb", "Mar", "Apr", "May", "Jun",
  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
}
local days = {
  "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"
}

return function(date)
	local t = os.date("*t", date)
	return string.format("%s, %02d %s %04d %02d:%02d:%02d GMT",
		days[t.wday], t.day, months[t.month], t.year, t.hour, t.min, t.sec)
end
