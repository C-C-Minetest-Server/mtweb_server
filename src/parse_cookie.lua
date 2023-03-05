return function(cookie_str)
    local cookie_table = {}
    for cookie in cookie_str:gmatch('([^;]+)') do
        local name, value = cookie:match('^%s*(.-)%s*=%s*(.-)%s*$')
        if name then
            cookie_table[name] = value
        end
    end
    return cookie_table
end
