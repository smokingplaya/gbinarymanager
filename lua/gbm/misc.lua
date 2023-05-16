gbinarymanager.misc = {}

gbinarymanager.misc.paths = {
	main = "gbm",
	images = "gbm/images"
}

local pref = "[GBM %s] "
local color_log = Color(255, 185, 120)
gbinarymanager.log = function(prefix, ...)
    MsgC(color_log, pref:format(prefix), color_white, ..., "\n")
end

for _, v in pairs(gbinarymanager.misc.paths) do
	file.CreateDir(v)
end

gbinarymanager.misc.get_platform = function()
    local iswindows = system.IsWindows()
	local is64 = BRANCH == "x86-64" or BRANCH == "chromium"

	if iswindows then
		return "win" .. (is64 and "64" or "32")
	else
		return "linux" .. (is64 and "64" or "")
	end
end

gbinarymanager.misc.locals = {
	list_url = "https://raw.githubusercontent.com/smokingplaya/gbinarymanager-list/main/list.json",
	dll_url = "https://github.com/smokingplaya/gbinarymanager"
}

local blur = Material("pp/blurscreen")
gbinarymanager.misc.draw_blur = function(panel, amount)
    local x, y = panel:LocalToScreen(0, 0)
    local scrW, scrH = ScrW(), ScrH()
    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(blur)
    for i = 1, 3 do
        blur:SetFloat("$blur", (i / 3) * (amount or 6))
        blur:Recompute()
        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(x * -1, y * -1, scrW, scrH)
    end
end