local rows_per_column = 4

-- menu

local function create_list_panel()
	local panel = vgui.Create("Panel")
	panel.Paint = function(self, w, h)
		draw.RoundedBox(3, 0, 0, w, h, gbinarymanager.colors.main)
	end

	local margin1 = ScreenScale(10)

	local title = panel:Add("DLabel")
	title:SetFont("gbm_24")
	title:SetText(gbinarymanager.lang.gbm_title_version:format(gbinarymanager.version))
	title:SetTextColor(gbinarymanager.colors.white)
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

	if not gbinarymanager.version then
		surface.SetFont("gbm_18")
		local fontTitleW, fontTitleH = surface.GetTextSize(gbinarymanager.lang.haventmodule)

		surface.SetFont("gbm_14")
		local fontInstallW, fontInstallH = surface.GetTextSize(gbinarymanager.lang.install)

		local m = ScreenScale(6)

		local warning = panel:Add("Panel")
		warning:SetSize(fontTitleW, fontTitleH+fontInstallH+m*3)
		warning.Paint = function(self, w, h)
			draw.SimpleText(gbinarymanager.lang.haventmodule, "gbm_18", w/2, 0, gbinarymanager.colors.white, 1, 0)
		end

		warning.Install = warning:Add("DButton")
		warning.Install:SetText(gbinarymanager.lang.install)
		warning.Install:SetTextColor(gbinarymanager.colors.button_blue_text)
		warning.Install:SetFont("gbm_14")
		warning.Install:SetY(warning:GetTall()-fontInstallH-m*2)
		warning.Install:SetSize(fontInstallW+m*6, fontInstallH+m*2)
		warning.Install:CenterHorizontal()
		warning.Install.Paint = function(self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and gbinarymanager.colors.button_blue_hovered or gbinarymanager.colors.button_blue)
		end

		warning.Install.DoClick = function()
			gui.OpenURL(gbinarymanager.misc.locals.dll_url)
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
			local platform = gbinarymanager.misc.get_platform()

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
				draw.RoundedBox(0, 0, 0, w, h, gbinarymanager.colors.info_bg)
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
				gbinarymanager.misc.draw_blur(self, 1)
				draw.RoundedBox(0, 0, 0, w, h, gbinarymanager.colors.info_bg)

				local absoletle_x = h/2-(nameH+text_margin+authorH)/2

				draw.SimpleText(self.Name, "gbm_16", margin, absoletle_x, gbinarymanager.colors.white)
				draw.SimpleText(self.Author, "gbm_14", margin, absoletle_x+nameH+text_margin, gbinarymanager.colors.grey)
			end

			if tab.image and tab.image ~= "" then
				local b = false
				panel.Think = function(self)
					local mat = gbinarymanager.mats[tab.name .. ".png"]
					if not mat then
						if b then return end
						local a = gbinarymanager.mats.SaveFromURL(tab.name .. ".png", tab.image)
						if a then
							gbinarymanager.mats.GetMat(tab.name .. ".png")
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
				draw.RoundedBox(3, 0, 0, w, h, gbinarymanager.colors.info_bg)

				local size = self.IconSize

				if not gbinarymanager.mats["download.png"] then
					gbinarymanager.mats.GetMat("download.png")

					return
				end

				surface.SetDrawColor(255, 255, 255)
				surface.SetMaterial(gbinarymanager.mats["download.png"])
				surface.DrawTexturedRect(w/2-size/2, h/2-size/2, size, size)
			end

			panel.Info.Download.DoClick = function(self)
				gbinarymanager.save.ByTable(tab)
			end
		end
	end

	list:InvalidateLayout(false)

	local time = SysTime()
	query:SetText(gbinarymanager.lang.waiting_server_respond)
	query:SetColors(gbinarymanager.colors.light_yellow, gbinarymanager.colors.yellow_outline)

	http.Fetch(gbinarymanager.misc.locals.list_url, function(body, _, _, c)
		if c ~= 200 then
			query:SetColors(gbinarymanager.colors.light_red, gbinarymanager.colors.red_outline)
			query:SetText(Format(gbinarymanager.lang.respon_error, c))
			return
		end

		local json = util.JSONToTable(body)
		list:SetList(json)

		query:SetText(Format(gbinarymanager.lang.respond_received, math.Round(SysTime()-time, 4)))
		query:SetColors(gbinarymanager.colors.light_green, gbinarymanager.colors.green_outline)
	end, function(error)
		query:SetColors(gbinarymanager.colors.light_red, gbinarymanager.colors.red_outline)
		query:SetText(Format(gbinarymanager.lang.respon_error, error))
	end)

	return panel
end

spawnmenu.AddCreationTab(gbinarymanager.lang.gbm_title, create_list_panel, "icon16/script_add.png", 5)

RunConsoleCommand("spawnmenu_reload")