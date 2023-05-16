gbinarymanager.save = {}

function gbinarymanager.save.ByTable(tab)
	local platform = gbinarymanager.misc.get_platform()

	local download_link = tab.dll_url[platform]
	if not download_link then return end
	download_link = "https://github.com/" .. download_link

	http.Fetch(download_link, function(b)
		local db_info = gbinarymanager.db.Get(tab.name)

		if db_info then
            local v1, v2 = tonumber(db_info.version), tonumber(tab.version)

            if v1 == v2 and gbinarymanager.db.info.platform == platform then return end

            if v1 > v2 then
				gbinarymanager.RemoveBinary(tab.name)
			end
		end

		local dll_name = string.GetFileFromFilename(download_link)
		gbinarymanager.db.Insert(tab.name, tab.version, platform, "", dll_name)
		gbinarymanager.db.installed[tab.name] = tab
		gbinarymanager.SaveBinary(dll_name, b)
        gbinarymanager.log("Saving", "Saved " .. dll_name)
	end)
end

function gbinarymanager.save.Remove(name)
	local info = gbinarymanager.db.Get(name)
	if not info then return end

	gbinarymanager.RemoveBinary(info.dll_name)
	gbinarymanager.db.RemoveByName(name)
    gbinarymanager.log("Saving", "Removed " .. info.dll_name)
end