mtweb = {}
mtweb.NF = function(req_headers,res_headers)
	res_headers:append(":status", "40")
	return {
		success = false,
		detail = "NOT FOUND"
	}
end
mtweb.METHOD_NOT_ALLOWED = function(allowed)
	return function(req_method,req_headers,res_headers)
		res_headers:append(":status", "405")
		res_headers:append("allow", allowed)
		return {
			success = false,
			detail = "METHOD NOT ALLOWED",
			allowed = allowed,
			used = req_method,
		}
	end
end

local MP = minetest.get_modpath("mtweb_server")

local insecure = minetest.request_insecure_environment()
if not insecure then
	error("Please add `mtweb_server` to `secure.trusted_mods`!")
end

local ie_require = dofile(MP .. "/src/insecure_require.lua")(insecure)

local status_server,http_server = ie_require.pcall_require_with_IE_env("http.server")
local status_headers,http_headers = ie_require.pcall_require_with_IE_env("http.headers")
local status_util,http_util = ie_require.pcall_require_with_IE_env("http.util")
if not(status_server and status_headers and status_util) then
	if not status_server then minetest.log("error","[MTweb] Failed to load HTTP server: " .. http_server) end
	if not status_headers then minetest.log("error","[MTweb] Failed to load HTTP headers: " .. http_headers) end
	if not status_util then minetest.log("error","[MTweb] Failed to load HTTP util: " .. http_util) end
	error("Please install `http`!")
end

local port = minetest.settings:get("mtweb.port")
if port == "" then port = "8000" end
port = tonumber(port)
if not port then
	error("Please configure `mtweb.port`!")
elseif port < 1 or port > 65535 then
	error("Inappropriate `mtweb.port`!")
end

local methods = dofile(MP .. "/methods/init.lua")({insecure=insecure,ie_require=ie_require})

local function onstream(myserver, stream)
	local req_headers = stream:get_headers()
	if not req_headers then return end
	local req_method = req_headers:get ":method"
	local path = req_headers:get(":path") or "/"

	minetest.log("action",string.format('[MTweb] "%s %s HTTP/%g"  "%s" "%s"',
		req_method or "ERR-METHOD",
		path,
		stream.connection.version,
		req_headers:get("referer") or "-",
		req_headers:get("user-agent") or "-"
	))
	local starttime = os.time()

	local res_headers = http_headers.new()
	res_headers:append("cache-control", "no-cache")
	res_headers:append("server", "MTweb-server")
	res_headers:append("content-type", "application/json; charset=utf-8")

	local pathseg = {}
	for seg in string.gmatch(path, '([^/]+)') do
		table.insert(pathseg,seg)
	end

	local func = methods[pathseg[1]] or mtweb.NF
	if req_method == "POST" then
		local body = stream:get_body_as_string(3)

		local form = {}
		for x,y in http_util.query_args(body) do
			form[x] = y
		end
		local return_data = func(req_method,req_headers,res_headers,pathseg,form)
		local success_whead = stream:write_headers(res_headers, req_method == "HEAD")
		if success_whead and req_method ~= "HEAD" then
			stream:write_chunk(minetest.write_json(return_data), true)
		end
	else
		local return_data = func(req_method,req_headers,res_headers,pathseg)

		local success_whead = stream:write_headers(res_headers, req_method == "HEAD")
		if success_whead and req_method ~= "HEAD" then
			stream:write_chunk(minetest.write_json(return_data), true)
		end
	end
	local usedtime = os.time() - starttime
	if usedtime > 2 then
		minetest.log("warning",string.format("Process request used up %d seconds.",usedtime))
	end
end

local myserver = assert(http_server.listen {
	host = "localhost";
	port = port;
	onstream = onstream;
	onerror = function(myserver, context, op, err, errno) -- luacheck: ignore 212
		local msg = op .. " on " .. tostring(context) .. " failed"
		if err then
			msg = msg .. ": " .. tostring(err)
		end
		minetest.log("error","[MTweb] " .. msg)
	end;
})

assert(myserver:listen())

do
	local bound_port = select(3, myserver:localname())
	minetest.log("action",string.format("[MTweb] Now listening on port %d", bound_port))
end

local function mainloop()
	myserver:step(2)
	minetest.after(0,mainloop)
end
minetest.after(0,mainloop)

minetest.register_on_shutdown(function()
	myserver:close()
	minetest.log("action","[MTweb] Server closed.")
end)
