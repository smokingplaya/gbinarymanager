local function create_font(size)
	local size2 = ScreenScale(size/2)
	surface.CreateFont("gbm_" .. size, {
		size = size2,
		font = "Roboto",
		extended = true
	})

	gbinarymanager.log("Fonts", "Created font " .. size .. " with size of " .. size2)
end

create_font(12)
create_font(14)
create_font(16)
create_font(18)
create_font(24)