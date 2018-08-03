script_name="Персы в сабах"
script_description="Персы в сабах"
script_author="Boris Pavlenko <ispovedn1k>"
script_version="1.0"
script_priority=0

function process(subtitles, settings)

    for line_index, line in ipairs(subtitles) do
		if line.class == "dialogue" and line.actor ~= "" then
			line.text = "[" .. line.actor .. "] " .. line.text
			subtitles[line_index] = line
		end
	end
	
end


aegisub.register_filter(script_name, 
	script_description, 
	script_priority, 
	process
--, configuration_panel_provider
)