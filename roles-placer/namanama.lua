script_name="Обзывалка"
script_description="Назначение ролей"
script_author="Boris Pavlenko <borpavlenko@ispovedn1k.com>"
script_version="1.1"
formates = "text files (.txt)|*.txt|All Files(.)|*.*"
gactors = {}

function process(subtitle, selected, active)
	local actors = scan_for_actors(subtitle)
	
	merge_gactors(actors)
	
	display_actors(gactors, subtitle)

	-- aegisub.set_undo_point(script_description)
	
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


function display_actors(actors_list, subtitle) 
	local cfg = {};
	local y = 0
	
	for actor, voice in pairs(actors_list) do
		cfg[#cfg+1] = {class = "label", label = "# " .. y+1 .. " ", y = y}
		cfg[#cfg+1] = {class = "label", label = actor, x = 1, y = y}
		cfg[#cfg+1] = {class = "edit", name = actor, x = 2, y = y, text = voice}
		y = y+1
	end
	
	local btn, result = aegisub.dialog.display(
		cfg,
		{"Apply", "Open", "Save", "Cancel"}
	)
	if btn == "Apply" then
		apply_click(result, subtitle)
	end
	if btn == "Open" then
		open_click(actors_list)
		merge_gactors(actors_list)
		
		display_actors(gactors, subtitle)
	end
	if btn == "Save" then 
		merge_gactors(result)
		save_click(result)
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


function open_click(actors)
	-- @todo проверку на несохранённые данные
	local filename = aegisub.dialog.open("Select filename to load roles", "roles.txt", "", formates)
	
	if not filename then
		return nil
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


aegisub.register_macro(script_name, script_description, process, validate)