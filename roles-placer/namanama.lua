script_name="Обзывалка"
script_description="Назначение ролей"
script_author="Boris Pavlenko <borpavlenko@ispovedn1k.com>"
script_version="1.4"
formates = "text files (.txt)|*.txt|All Files(.)|*.*"
gactors = {} -- список всех ролей

function process(subtitle, selected, active)
	local actors = scan_for_actors(subtitle)
	
	merge_gactors(actors)
	
	display_actors(actors, subtitle)
	
    return selected
end

function validate(subtitle, selected, active)
    return true
end


function scan_for_actors(subtitle)
	local actors = {}
	local actr_cnt = 0
	local wl = ""

	for _, line in ipairs(subtitle) do
		if line.class == "dialogue" and line.actor ~= "" then
			if not actors[line.actor] then
				actr_cnt = actr_cnt +1
				actors[line.actor] = ""
				wl = wl .. line.actor .. "\r\n"
			end
		end
	end
	
	return actors
end


function display_actors(actors_list, subtitle, mode) 
	local cfg = {};
	local y = 0
	local x = 0
	local numlines = math.floor(tablelength(actors_list) / 3)
	local r = tablelength(actors_list) % 3
	local counter = 1;
	local modeBtn = ""
	
	if (mode == "More") then 
		modeBtn = "Less"
	else
		mode = "Less"
		modeBtn = "More"
	end
	
	local sorted_actors = {}
	for k in pairs(actors_list) do table.insert(sorted_actors, k) end
	table.sort(sorted_actors)
	
	for _, actor in ipairs(sorted_actors) do
		if (y == numlines) then
			if (r > 0) then
				r = r-1
			else
				y = 0
				x = x+3
			end
		end
		if (y > numlines) then
			y = 0
			x = x+3
		end
		cfg[#cfg+1] = {class = "label", label = "# " .. counter .. " ", x = x, y = y}
		cfg[#cfg+1] = {class = "label", label = actor, x = x+1, y = y}
		cfg[#cfg+1] = {class = "edit", name = actor, x = x+2, y = y, text = gactors[actor]}
		y = y+1
		counter = counter +1
	end
	
	local btn, result = aegisub.dialog.display(
		cfg,
		{"Apply", "Open", "Save", "Cancel", modeBtn}
	)
	if btn == "Apply" then
		apply_click(result, subtitle)
	end
	if btn == "Open" then	
		merge_gactors( open_click() )
		
		display_actors(actors_list, subtitle, mode)
	end
	if btn == "Save" then 
		merge_gactors(result)
		save_click(gactors)
	end
	if btn == "Less" then
		local l_actors = scan_for_actors(subtitle)
		display_actors(l_actors, subtitle, "Less")
	end
	if btn == "More" then 
		display_actors(gactors, subtitle, "More")
	end
end


function apply_click(result, subtitle)
	merge_gactors(result)
	
	for line_index, line in ipairs(subtitle) do
		if line.class == "dialogue" and line.actor ~= "" then
			line.text = "[" .. gactors[line.actor] .. "] " .. line.text
			subtitle[line_index] = line
		end
	end
	
	aegisub.set_undo_point(script_description)
end


function save_click(result)
	local filename = aegisub.dialog.save("Select filename to save roles", "roles.txt", "", formates)
	
	if not filename then 
		return
	end
	
	local wl = ""
	
	for actor, voice in pairs(result) do
		wl = wl .. actor .. " = " .. voice .. "\r\n"
	end
	
	wl = wl .. ""
	
	file = assert(io.open(filename, "w"))
	io.output(file)
	io.write("-- Aegisub::Roles save\r\n")
	io.write(wl)
	io.write("-- End")
	
	io.close(file)
end


function open_click()
	-- @todo проверку на несохранённые данные
	local filename = aegisub.dialog.open("Select filename to load roles", "roles.txt", "", formates)
	local actors = {}
	
	if not filename then
		return actors
	end
	
	local f = assert(io.open(filename,"r"))
	
	if f == nil then 
		MsgBox("File doesn't exists. Canceled.")
		return nil 
	end
	
	local line = ""
	
	repeat
		line = f:read("*line")
		if line then 
			if string.match(line, "^%s*%-%-") then
			else
				local a, v = string.match(line, "^%s*(.-)%s*=%s*(.-)%s*$")
				actors[a] = v
			end
		end
	until not line
	
	io.close(f)
	
	return actors
end


function merge_gactors(actors)
	for actor, voice in pairs(actors) do
		gactors[actor] = (function() if voice ~= "" then return voice else if not gactors[actor] then return "" else return gactors[actor] end end end)()
	end
end


function MsgBox(msg)
	aegisub.dialog.display({{class = "label", label = msg}}, {"Ok"})
end


function tablelength(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

aegisub.register_macro(script_name, script_description, process, validate)