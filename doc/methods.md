## Return format
All responses are in JSON format. The `success` boolean field always presents, indicating a successful or failed execution. If failed, `details` will contain further error messages.
## API methods
### `GET /status`
Return server status in `"status"` field. Under most cases, it is identical to execute `/status` in-game.

### Methods that require authentication
The following methods involves/requires authentication.

#### `POST /auth/login`
Login to a player's account. A cookie, `mtweb-login-token`, will be set if success. The following POST form data should be set:

* `uname`: The player's username.
* `passwd`: The player's password.

Note that in singleplayer mode, every login attempts to the "singleplayer" account will be accepted unconditionally (even if password is not set), and none will be accepted in multiplayer servers.

#### `GET /auth/csrf`
Get a CSRF token, which will be returned to the `csrf` field. It should be set in the `csrf` field in the POST body, if required.

#### `GET /auth/whoami`
Return the currently logged in user information. The following details are avaliable in the returned JSON:

* `name`: The username of the logged in user.
* `privs`: A table with keys as the privileges names, and `true` as their value.
* `last_ingame_login`: Last time the player logged into the game, in [Unix time](https://en.wikipedia.org/wiki/Unix_time).

The error message "INVALID TOKEN" will be raised if the user is not logged in.

#### `POST /auth/chpasswd`
**Requires CSRF token.** Change the current user's password. The following POST form data should be set:

* `old_password`: The password used previously.
* `new_password`: The password willing to be changed to.

The following error message may be raised:

* `INVALID CSRF AND-OR LOGIN TOKEN`: Either or both login and/or CSRF token is invalid.
* `MISMATCH OLD PASSWORD`: The old password provided does not match the actual one.
* `NO NEW PASSWORD`: The new password is empty. Currently, empty passwords are not allowed.

#### `POST /auth/logout`
**Requires CSRF token.** Logout the current user, which in behind invalidate the login token.

The following error message may be raised:

* `INVALID CSRF AND-OR LOGIN TOKEN`: Either or both login and/or CSRF token is invalid.
* `ALREADY LOGGED OUT`: The user is not logged in.

#### Methods related to area protection
MTweb has intergrations with [areas](https://github.com/minetest-mods/areas).

##### `GET /auth/areas/list`
Get the list of your areas, return a key-value pair of area IDs and area objects in `area_list` field. The following options can be set as URL parameters:

* `admin`: If present and the user is an admin (as defined by areas mod), list all areas instead of only theirs.
* `upper` and `lower`: List out `upper` to `lower` areas, inclusively.
