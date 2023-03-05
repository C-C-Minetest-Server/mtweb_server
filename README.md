# mtweb_server
Server backend of Minetest Web Panel. This mod does not contain the web panel, which is a set of static website and JavaScript scripts.

## Installation of dependencies
1. [Install luarocks on our computer](https://github.com/luarocks/luarocks/wiki/Download).
2. Install Lua 5.1 on your computer (even if you use LuaJIT).
3. Run the following command to install HTTP from luarocks: `sudo luarocks --lua-version 5.1 install http`

## Install this mod
1. [Follow the instruction on the wiki](https://wiki.minetest.net/Installing_Mods). You may also search for this mod in the "Browse online content" button.
2. Add `mtweb_server` into `secure.trusted_mods` in your `minetest.conf`. `secure.trusted_mods` is a command-seperated list of mod names, if there were anything, add a comma before appending this mod's name.
3. Configure this mod:
	* `mtweb.port`: The port the server is binding to. It should be larger than 1024 (as those between 0 and 1024 inclusively are reserved by the superuser), and must not higher than 65535 (that's the protocol's limit).
	* `mtweb.auth.idle_limit`: The time, in second, allowed to have no action taken with this token before the token is invalidated. `0` means they will never expire.
4. **Proxy the MTweb server through a server software with SSL encryptions.** This is important as MTweb does not provide SSL-encrypted communications.
