if util.IsBinaryModuleInstalled("gbinarymanager") and not gbinarymanager then
	require("gbinarymanager")
end

gbinarymanager = gbinarymanager || {}

local add = SERVER and AddCSLuaFile or include

add("gbm/colors.lua")
add("gbm/lang.lua")
add("gbm/misc.lua")
add("gbm/mats.lua")
add("gbm/fonts.lua")
add("gbm/db.lua")
add("gbm/save.lua")
add("gbm/menu.lua")