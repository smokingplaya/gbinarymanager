gbinarymanager.db = {}
gbinarymanager.db.installed = {}

local db_str = sql.SQLStr

if not sql.TableExists("gbm") then
	sql.Query("CREATE TABLE IF NOT EXISTS gbm(id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, version REAL NOT NULL, platform TEXT NOT NULL, lua_path TEXT NOT NULL, dll_name TEXT NOT NULL)")
	gbinarymanager.log("Database", "Created SQLite table \"gbm\".")
end

local db_insert = "INSERT INTO gbm (name, version, platform, lua_path, dll_name) VALUES(%s, %s, %s, %s, %s);"
function gbinarymanager.db.Insert(name, version, platform, lua_path, dll_name)
	sql.Query(db_insert:format(db_str(name), db_str(version), db_str(platform), db_str(lua_path), db_str(dll_name)))
	gbinarymanager.log("Database", name .. " was added to database.")
end

local db_get = "SELECT * FROM gbm WHERE name = %s"
function gbinarymanager.db.Get(name)
	local tab = sql.Query(db_get:format(db_str(name)))
	return istable(tab) and tab[1]
end

local db_remove_by_id = "DELETE FROM gbm WHERE name = %s"
function gbinarymanager.db.RemoveByName(name)
	local b = sql.Query(db_remove_by_id:format(db_str(name)))
	gbinarymanager.log("Database", b and name .. " was removed from database." or "Couldn't remove " .. name .. " from database.")
end

do
	local db_info = sql.Query("SELECT * FROM gbm")
	if db_info and istable(db_info) then
		for k, v in ipairs(db_info) do
			gbinarymanager.log("Database", "Caching installed module \"" .. v.name .. "\"")
			gbinarymanager.db.installed[v.name] = v
		end
	end
end