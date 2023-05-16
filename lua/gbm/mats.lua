gbinarymanager.mats = {}

function gbinarymanager.mats.SaveFromURL(name, link)
	if file.Find(gbinarymanager.misc.paths.images .. "/" .. name, "DATA")[1] then return true end

	http.Fetch(link, function(b)
		gbinarymanager.log("Materials", "Save image " .. name)
		file.Append(gbinarymanager.misc.paths.images .. "/" .. name, b)
	end, function(err)
		print(lang.unable_download_image:format(err))
	end)
end

function gbinarymanager.mats.GetMat(name)
	local path = gbinarymanager.misc.paths.images .. "/" .. name
	if file.Find(path, "DATA")[1] then
		local m = gbinarymanager.mats[name]
		if m then
			return m
		end

		gbinarymanager.log("Materials", "Caching image " .. name)
		gbinarymanager.mats[name] = Material("data/" .. path, "noclamp smooth")
		return gbinarymanager.mats[name]
	end
end

gbinarymanager.mats.SaveFromURL("download.png", "https://i.ibb.co/D1bxZ1X/download.png")