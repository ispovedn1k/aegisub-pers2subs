script_name="Фильтр по ролям"
script_description="Фильтрует субтитры по выделенным ролям"
script_author="Boris Pavlenko <ispovedn1k>"
script_version="1.0"
script_priority=0

function process(subtitles, settings)
	
	for i = #subtitles, 1, -1 do
		local line = subtitles[i]
		if line.class == "dialogue" then
			local actor = line.actor
			if actor == "" then actor = "<empty>" end
			if not settings[actor] then 
				subtitles.delete(i)
			end
		end
	end
	
end


function scan_for_actors(subtitles)
	local actors = {}

	for _, line in ipairs(subtitles) do
		if line.class == "dialogue" then 
			if line.actor ~= "" then
				if not actors[line.actor] then
					actors[line.actor] = false
				end
			else
				actors["<empty>"] = false
			end
		end
	end
	
	return actors
end


function tablelength(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end


function get_filter_configuration_panel(subtitles, old_settings)
	local cfg = {};
	local y = 0
	local x = 0
	local numlines = 0
	local r = 0
	local actors = scan_for_actors(subtitles)
	
	-- merge
	for actor, check in pairs(actors) do
		actors[actor] = (function() if not old_settings[actor] then return false else return old_settings[actor] end end)()
	end
	
	-- sorting
	local sorted_actors = {}
	for k in pairs(actors) do table.insert(sorted_actors, k) end
	table.sort(sorted_actors)
	
	numlines = math.floor(tablelength(actors) / 3)
	r = tablelength(actors) % 3
			
	for k, actor in ipairs(sorted_actors) do
		if (y == numlines) then
			if (r > 0) then
				r = r-1
			else
				y = 0
				x = x+2
			end
		end
		if (y > numlines) then
			y = 0
			x = x+2
		end
		cfg[#cfg+1] = {class = "label", label = "# " .. k .. " ", x = x, y = y}
		cfg[#cfg+1] = {name = actor, class = "checkbox", label = actor, x = x+1, y = y, value = false}
		y = y+1
	end
	
	return cfg
end


aegisub.register_filter(script_name, 
	script_description, 
	script_priority, 
	process,
	get_filter_configuration_panel
)