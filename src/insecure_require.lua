return function(IE)
	local p = {}
	function p.pcall_require_with_IE_env(...)
		-- be sure that there is no hook, otherwise one could get IE via getfenv
		IE.debug.sethook()

		local old_thread_env = IE.getfenv(0)
		local old_string_metatable = IE.debug.getmetatable("")

		-- set env of thread
		-- (the loader used by IE.require will probably use the thread env for
		-- the loaded functions)
		IE.setfenv(0, IE)

		-- also set the string metatable because the lib might use it while loading
		-- (actually, we probably have to do this every time we call a `require()`d
		-- function, but for performance reasons we only do it if the function
		-- uses the string metatable)
		-- (Maybe it would make sense to set the string metatable __index field
		-- to a function that grabs the string table from the thread env.)
		IE.debug.setmetatable("", {__index = IE.string})

		-- (IE.require's env is neither _G, nor IE. we need to leave it like this,
		-- otherwise it won't find the loaders (it uses the global `loaders`, not
		-- `package.loaders` btw. (see luajit/src/lib_package.c)))

		-- we might be pcall()ed, so we need to pcall to make sure that we reset
		-- the thread env afterwards
		local ok, ret = IE.pcall(IE.require, ...)

		-- reset env of thread
		IE.setfenv(0, old_thread_env)

		-- also reset the string metatable
		IE.debug.setmetatable("", old_string_metatable)

		return ok, ret
	end
	function p.require_with_IE_env(...)
		local ok, ret = p.pcall_require_with_IE_env(...)
		if not ok then IE.error(ret) end
		return ret
	end
	return p
end
