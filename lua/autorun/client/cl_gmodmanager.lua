if util.IsBinaryModuleInstalled("gbinarymanager") and not gbinarymanager then
	require("gbinarymanager")
end

local installed = {}
local paths = {
	main = "gbm",
	images = "gbm/images"
}

for _, v in pairs(paths) do
	file.CreateDir(v)
end

-- platform

local function get_platform()
	local iswindows = system.IsWindows()
	local is64 = BRANCH == "x86-64" or BRANCH == "chromium"

	if iswindows then
		return "win" .. (is64 and "64" or "32")
	else
		return "linux" .. (is64 and "64" or "")
	end
end

-- sql
local db = {}
local db_str = sql.SQLStr
if not sql.TableExists("gbm") then
	sql.Query("CREATE TABLE IF NOT EXISTS gbm(id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, version REAL NOT NULL, platform TEXT NOT NULL, lua_path TEXT NOT NULL, dll_name TEXT NOT NULL)")
end

local db_insert = "INSERT INTO gbm (name, version, platform, lua_path, dll_name) VALUES(%s, %s, %s, %s, %s);"
function db.Insert(name, version, platform, lua_path, dll_name)
	sql.Query(db_insert:format(db_str(name), db_str(version), db_str(platform), db_str(lua_path), db_str(dll_name)))
end

local db_get = "SELECT * FROM gbm WHERE name = %s"
function db.Get(name)
	local tab = sql.Query(db_get:format(db_str(name)))
	return istable(tab) and tab[1]
end

local db_remove_by_id = "DELETE FROM gbm WHERE name = %s"
function db.RemoveByName(name)
	sql.Query(db_remove_by_id:format(db_str(name)))
end


-- save
local save = {}

function save.ByTable(tab)
	local platform = get_platform()

	local download_link = tab.dll_url[platform]
	if not download_link then return end
	download_link = "https://github.com/" .. download_link

	http.Fetch(download_link, function(b)
		local db_info = db.Get(tab.name)

		if db_info then
			print(db_info.platform == platform)
			if db_info.platform == platform then return end

			if tonumber(db_info.version) ~= tonumber(tab.version) then
				gbinarymanager.RemoveBinary(tab.name)
			end
		end

		local dll_name = string.GetFileFromFilename(download_link)
		db.Insert(tab.name, tab.version, platform, "", dll_name)
		installed[tab.name] = tab
		gbinarymanager.SaveBinary(dll_name, b)
	end)
end

function save.Remove(name)
	local info = db.Get(name)
	if not info then return end

	gbinarymanager.RemoveBinary(info.dll_name)
	db.RemoveByName(name)
end

-- caching

do
	local db_info = sql.Query("SELECT * FROM gbm")
	if db_info and istable(db_info) then
		for k, v in ipairs(db_info) do
			installed[v.name] = v
		end
	end
end

-- fonts

local function create_font(size)
	surface.CreateFont("gbm_" .. size, {
		size = ScreenScale(size/2),
		font = "Roboto",
		extended = true
	})
end

create_font(12)
create_font(14)
create_font(16)
create_font(18)
create_font(24)

-- blur

local blur = Material("pp/blurscreen")
local function DrawBlur(panel, amount)
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

-- lang

local lang = {
	gbm_title = "Binary Modules Shop",
	gbm_title_version = "Binary Modules Shop v%s",
	waiting_server_respond = "Waiting for the server to respond.",
	respond_received = "Received response from server for %s sec",
	respon_error = "The server responded with error: %s",

	haventmodule = "You do not have the GBinaryManager module installed",
	install = "Install",

	unable_download_image = "Unable to download the picture. (%s)"
}

-- locals

local locals = {
	list_url = "https://raw.githubusercontent.com/smokingplaya/gbinarymanager-list/main/list.json",
	dll_url = "https://github.com/smokingplaya/gbinarymanager-dll"
}

-- materials

local mats = {}

function mats.SaveFromURL(name, link)
	if file.Find(paths.images .. "/" .. name, "DATA")[1] then return true end

	http.Fetch(link, function(b)
		file.Append(paths.images .. "/" .. name, b)
	end, function(err)
		print(lang.unable_download_image:format(err))
	end)
end

function mats.GetMat(name)
	local path = paths.images .. "/" .. name
	if file.Find(path, "DATA")[1] then
		local m = mats[name]
		if m then
			return m
		end

		mats[name] = Material("data/" .. path, "noclamp smooth")
		return mats[name]
	end
end

mats.SaveFromURL("download.png", "https://i.ibb.co/D1bxZ1X/download.png")

-- colors

local colors = {
	main = Color(45, 45, 45),
	white = Color(255, 255, 255),
	grey = Color(200, 200, 200),
	info_bg = Color(40, 40, 40, 128),

	light_yellow = Color(240, 215, 140),
	yellow_outline = Color(240, 190, 50),

	light_green = Color(217, 249, 203),
	green_outline = Color(132, 188, 107),

	light_red = Color(250, 185, 185),
	red_outline = Color(250, 50, 50),

	button_blue = Color(0, 0, 150, 32),
	button_blue_hovered = Color(0, 0, 150, 8),
	button_blue_text = Color(106, 103, 188),
}

local rows_per_column = 4

-- menu

local function create_list_panel()
	local panel = vgui.Create("Panel")
	panel.Paint = function(self, w, h)
		draw.RoundedBox(3, 0, 0, w, h, colors.main)
	end

	local margin1 = ScreenScale(10)

	local title = panel:Add("DLabel")
	title:SetFont("gbm_24")
	title:SetText(lang.gbm_title_version:format(gbinarymanager.version))
	title:SetTextColor(colors.white)
	title:Dock(TOP)
	title:SetContentAlignment(5)
	title:SetTall(ScreenScale(12))
	title:DockMargin(margin1, margin1, margin1, margin1)

	local offset2 = ScreenScale(4)

	local query = panel:Add("DPanel")
	query:SetTall(0, 0, 0, 0)
	query:Dock(TOP)
	query:DockMargin(margin1, 0, margin1, 0)
	query.SetColors = function(self, color, colorOutline)
		self.m_Color = color
		self.m_ColorOutline = colorOutline
	end

	query.SetText = function(self, text)
		self.m_Text = text

		local tall = ScreenScale(6)+offset2*2

		if self:GetTall() == tall then return end

		self:SizeTo(-1, tall, 0.3)
	end

	query.Paint = function(self, w, h)
		if not (self.m_ColorOutline and self.m_Color and self.m_Text) then return end
		draw.RoundedBox(8, 0, 0, w, h, self.m_ColorOutline)
		draw.RoundedBox(8, 2, 2, w-4, h-4, self.m_Color)

		draw.SimpleText(self.m_Text, "gbm_12", h/2, h/2, color_black, 0, 1)
	end

	local margin2 = ScreenScale(2)
	local list_save = panel:Add("Panel")
	list_save:Dock(FILL)
	list_save:DockMargin(margin1, margin1, margin1, margin1)

	if not gbinarymanager then
		surface.SetFont("gbm_18")
		local fontTitleW, fontTitleH = surface.GetTextSize(lang.haventmodule)

		surface.SetFont("gbm_14")
		local fontInstallW, fontInstallH = surface.GetTextSize(lang.install)

		local m = ScreenScale(6)

		local warning = panel:Add("Panel")
		warning:SetSize(fontTitleW, fontTitleH+fontInstallH+m*3)
		warning.Paint = function(self, w, h)
			draw.SimpleText(lang.haventmodule, "gbm_18", w/2, 0, colors.white, 1, 0)
		end

		warning.Install = warning:Add("DButton")
		warning.Install:SetText(lang.install)
		warning.Install:SetTextColor(colors.button_blue_text)
		warning.Install:SetFont("gbm_14")
		warning.Install:SetY(warning:GetTall()-fontInstallH-m*2)
		warning.Install:SetSize(fontInstallW+m*6, fontInstallH+m*2)
		warning.Install:CenterHorizontal()
		warning.Install.Paint = function(self, w, h)
			draw.RoundedBox(3, 0, 0, w, h, self:IsHovered() and colors.button_blue_hovered or colors.button_blue)
		end

		warning.Install.DoClick = function()
			gui.OpenURL(locals.dll_url)
		end

		list_save.OnSizeChanged = function()
			warning:Center()
		end

		return panel
	end

	local list = list_save:Add("DGrid")
	list:Dock(FILL)
	list.SetList = function(self, tab)
		self.m_List = tab
	end

	panel.OnSizeChanged = function(self, w, h)
		list:Clear()

		local wide = math.floor(w/rows_per_column)
		local tall = wide*0.6

		list:SetCols(rows_per_column)
		list:SetColWide(wide)
		list:SetRowHeight(tall)

		for _, tab in ipairs(list.m_List) do
			local platform = get_platform()

			if tab.dll_url and not tab.dll_url[platform] then return end

			local panel = vgui.Create("Panel") -- list:Add("DPanel")
			panel:SetSize(wide, tall)
			list:AddItem(panel)

			local panel = panel:Add("Panel")
			panel:Dock(FILL)
			panel:DockMargin(margin2, margin2, margin2, margin2)
			panel.Paint = function(self, w, h)
				if self.m_Mat then
					surface.SetDrawColor(255, 255, 255)
					surface.SetMaterial(self.m_Mat)
					surface.DrawTexturedRect(0, 0,  w, h)
					return
				end
				draw.RoundedBox(0, 0, 0, w, h, colors.info_bg)
			end

			local margin, text_margin = ScreenScale(4), -2
			surface.SetFont("gbm_16")
			local nameW, nameH = surface.GetTextSize(tab.name)
			surface.SetFont("gbm_14")
			local authorW, authorH = surface.GetTextSize(tab.author)
			panel.Info = panel:Add("DPanel")
			panel.Info:Dock(BOTTOM)
			panel.Info:SetTall(ScreenScale(20))
			panel.Info.Name = tab.name .. " (v" .. tab.version .. ")"
			panel.Info.Author = tab.author
			panel.Info.Paint = function(self, w, h)
				DrawBlur(self, 1)
				draw.RoundedBox(0, 0, 0, w, h, colors.info_bg)

				local absoletle_x = h/2-(nameH+text_margin+authorH)/2

				draw.SimpleText(self.Name, "gbm_16", margin, absoletle_x, colors.white)
				draw.SimpleText(self.Author, "gbm_14", margin, absoletle_x+nameH+text_margin, colors.grey)
			end

			if tab.image and tab.image ~= "" then
				local b = false
				panel.Think = function(self)
					local mat = mats[tab.name .. ".png"]
					if not mat then
						if b then return end
						local a = mats.SaveFromURL(tab.name .. ".png", tab.image)
						if a then
							mats.GetMat(tab.name .. ".png")
						end

						b = true

						return
					end

					self.m_Mat = mat
					self.Think = nil
				end
			end

			panel.Info.Download = panel.Info:Add("DButton")
			panel.Info.Download:SetText("")
			panel.Info.Download:Dock(RIGHT)
			panel.Info.Download:DockMargin(margin2, margin2, margin2, margin2)
			panel.Info.Download.OnSizeChanged = function(self, w, h)
				self:SetWide(h)
				self.IconSize = h*.7
			end

			panel.Info.Download.Paint = function(self, w, h)
				draw.RoundedBox(3, 0, 0, w, h, colors.info_bg)

				local size = self.IconSize

				if not mats["download.png"] then
					mats.GetMat("download.png")

					return
				end

				surface.SetDrawColor(255, 255, 255)
				surface.SetMaterial(mats["download.png"])
				surface.DrawTexturedRect(w/2-size/2, h/2-size/2, size, size)
			end

			panel.Info.Download.DoClick = function(self)
				save.ByTable(tab)
			end
		end
	end

	list:InvalidateLayout(false)

	local time = SysTime()
	query:SetText(lang.waiting_server_respond)
	query:SetColors(colors.light_yellow, colors.yellow_outline)

	http.Fetch(locals.list_url, function(body, _, _, c)
		if c ~= 200 then
			query:SetColors(colors.light_red, colors.red_outline)
			query:SetText(Format(lang.respon_error, c))
			return
		end

		local json = util.JSONToTable(body)
		list:SetList(json)

		query:SetText(Format(lang.respond_received, math.Round(SysTime()-time, 4)))
		query:SetColors(colors.light_green, colors.green_outline)
	end, function(error)
		query:SetColors(colors.light_red, colors.red_outline)
		query:SetText(Format(lang.respon_error, error))
	end)

	return panel
end

-- other
spawnmenu.AddCreationTab(lang.gbm_title, create_list_panel, "icon16/script_add.png", 5)

RunConsoleCommand("spawnmenu_reload")

--

local t = {
	{
		name = "Lanes",
		desc = "Modules for Garry's Mod that add threads through Lua Lanes.",
		author = "danielga",
		version = "1",
		repo = "danielga/gmod_lanes",
		dll_url = {
			win32 = "danielga/gmod_lanes/releases/download/downloadables/gmcl_lanes.core_win32.dll"
		},
		lua = {
			{["autorun/client"] = "danielga/gmod_lanes/master/lanes.lua"} -- https://raw.githubusercontent.com/danielga/gmod_lanes/master/lanes.lua
		},
		image = "https://mobimg.b-cdn.net/v3/fetch/5c/5c667b51332990f7af3d3b20b4548883.jpeg?w=1470&r=0.5625"
	},

	{
		name = "CPU Info",
		desc = "Modules for Garry's Mod that add threads through Lua Lanes.",
		author = "TheFUlDeep",
		version = "0.2",
		repo = "TheFUlDeep/gmod_cpu_info",
		dll_url = {
			win32 = "TheFUlDeep/gmod_cpu_info/releases/download/v0.2/gmcl_cpu_info_win32.dll"
		},
		lua = {
			{["autorun/client"] = "danielga/gmod_lanes/master/lanes.lua"} -- https://raw.githubusercontent.com/danielga/gmod_lanes/master/lanes.lua
		},
		image = "https://i.pinimg.com/originals/29/ad/06/29ad06fbaa3f80f154d4d3044486d12a.jpg"
	}
}

--print(util.TableToJSON(t,  true))