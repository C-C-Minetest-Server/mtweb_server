return function(params)
	local MP = minetest.get_modpath("mtweb_server")
	local auth = dofile(MP .. "/methods/auth/init.lua")(params)

	return {
		status = function(req_method,req_headers,res_headers)
			local status = minetest.get_server_status() or ""
			res_headers:append(":status", (status ~= "") and "200" or "403")
			return {
				success = status and true or false,
				status = status,
				detail = not(status) and "Status not avaliable." or nil
			}
		end,
		auth = function(req_method,req_headers,res_headers,pathseg,form)
			local func = auth[pathseg[2]] or mtweb.NF
			return func(req_method,req_headers,res_headers,pathseg,form)
		end,
	}
end
