return function(params)
	local insecure = params.insecure
	local ie_require = params.ie_require

	local idle_limit = minetest.settings:get("mtweb.auth.idle_limit")
	if idle_limit == "" then idle_limit = "300" end
	idle_limit = tonumber(idle_limit) or 300

	local sessions = {}
	local function token_valid(token)
		if not sessions[token] then return false end
		local session = sessions[token]
		local now = os.time()
		if not session.logged_out then
			if idle_limit ~= 0 and (now - session.last_used > idle_limit) then
				minetest.log("action",string.format("Idle time exceed; logging out %s (Token: %s))",session.user,token))
				session.logged_out = true
				session.last_used = now
				return false
			else
				session.last_used = now
				return true
			end

		else
			if now - session.last_used > 120 then
				minetest.log("action",string.format("Expired; removing %s (Token: %s))",session.user,token))
				sessions[token] = nil
			end
			return false
		end
	end
	local function token_occupied(token)
		if not sessions[token] then return false end
		local session = sessions[token]
		local now = os.time()
		if not session.logged_out then
			if idle_limit ~= 0 and (now - session.last_used > idle_limit) then
				minetest.log("action",string.format("Idle time exceed; logging out %s (Token: %s))",session.user,token))
				session.logged_out = true
				session.last_used = now
			end
			return true
		else
			if now - session.last_used > 120 then
				minetest.log("action",string.format("Expired; removing %s (Token: %s))",session.user,token))
				sessions[token] = nil
				return false
			end
		end
	end
	local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
	local function random_token() -- TODO: Make use of cryptographic safe methods.
		local ranstr = ""
		for i = 1, 20 do
			local ranindex = math.random(#chars)
			ranstr = ranstr .. string.sub(chars,ranindex, ranindex)
		end
		if token_occupied(ranstr) then -- Don't give a duplicated one, though not likely to happen
			return random_token()
		end
		return ranstr
	end

	local MP = minetest.get_modpath("mtweb_server")
	local auth_handler = minetest.get_auth_handler()
	local parse_cookie = dofile(MP .. "/src/parse_cookie.lua")
	local gendate = dofile(MP .. "/src/gendate.lua")

	return {
		login = function(req_method,req_headers,res_headers,pathseg,form)
			if req_method ~= "POST" then
				return mtweb.METHOD_NOT_ALLOWED("POST")(req_method,req_headers,res_headers)
			end
			local uname = form.uname
			local passwd = form.passwd
			if not(uname and passwd) then
				res_headers:append(":status","400")
				return {
					success = false,
					detail = "Username (uname) or Password (passwd) missing"
				}
			elseif minetest.check_password_entry(uname, auth_handler.get_auth(uname).password, passwd) then
				local token = random_token()
				local now = os.time()
				local session = {
					uname = uname,
					last_used = now
				}
				sessions[token] = session
				res_headers:append(":status","200")
				res_headers:append("set-cookie",string.format("mtweb-login-token=%s; Expires=%s; Path=/",
					token,
					gendate(now + 63072000)
				))
				return {
					success = true,
					uname = uname,
				}
			else
				res_headers:append(":status", "401")
				return {
					success = false,
					detail = "INVALID UNAME OR PASSWD",
				}
			end
		end,
		whoami = function(req_method,req_headers,res_headers,pathseg)
			local cookie_header = req_headers:get("cookie") or ""
			local cookies = parse_cookie(cookie_header)
			local token = cookies["mtweb-login-token"]
			if not(token and token_valid(token)) then
				res_headers:append(":status", "401")
				return {
					success = false,
					detail = "TOKEN EXPIRED",
				}
			else
				res_headers:append(":status", "200")
				local session = sessions[token]
				local uname = session.uname
				local auth_details = auth_handler.get_auth(session.uname)
				return {
					success = true,
					whoami = {
						name = session.uname,
						privileges = auth_details.privileges,
						last_ingame_login = auth_details.last_login,
					}
				}
			end
		end,
		logout = function(req_method,req_headers,res_headers,pathseg)
			if req_method ~= "POST" then
				return mtweb.METHOD_NOT_ALLOWED("POST")(req_method,req_headers,res_headers)
			end
			local cookie_header = req_headers:get("cookie") or ""
			local cookies = parse_cookie(cookie_header)
			local token = cookies["mtweb-login-token"]
			local session = sessions[token]
			if not session then
				res_headers:append(":status", "404")
				return {
					success = false,
					logout = true,
					details = "TOKEN NOT FOUND",
				}
			elseif session.logged_out then
				res_headers:append(":status", "400")
				return {
					success = false,
					logout = true,
					details = "ALREADY LOGGED OUT",
				}
			else
				session.logged_out = true
				session.last_used = os.time()
				res_headers:append(":status", "200")
				return {
					success = true,
					logout = true,
				}
			end
		end,
	}
end
