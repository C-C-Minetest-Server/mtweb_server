return function(params)
	local MP = minetest.get_modpath("mtweb_server")
	local http_cookie = params.http_cookie

	return {
		list = function(req_method,req_headers,res_headers,pathseg,form)
			local cookies = http_cookie.parse_cookies(req_headers)
			local token = cookies["mtweb-login-token"]
			if not(token and params.auth.token_valid(token)) then
				res_headers:append(":status", "401")
				return {
					success = false,
					detail = "INVALID TOKEN",
				}
			else
				res_headers:append(":status", "200")
				local session = params.auth.sessions[token]
				local uname = session.uname
				local admin = form.admin and minetest.check_player_privs(uname, areas.adminPrivs)

				local list_areas = {}
				for id, area in pairs(areas.areas) do
					if admin or areas:isAreaOwner(id, uname) then
						table.insert(list_areas,{id,area})
					end
				end

				local lowerlimit = form.lower and tonumber(form.lower) or 1
				local upperlimit = form.upper and tonumber(form.upper) or #list_areas
				local return_areas = {}
				for i=lowerlimit, upperlimit do
					local entry = list_areas[i]
					return_areas[tostring(entry[1])] = entry[2]
				end

				return {
					success = true,
					areas_list = return_areas
				}
			end
		end,
	}
end
