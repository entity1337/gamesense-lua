--local variables for API. Automatically generated by https://github.com/simpleavaster/gslua/blob/master/authors/sapphyrus/generate_api.lua 
local client_latency, client_log, client_draw_rectangle, client_draw_circle_outline, client_userid_to_entindex, client_draw_gradient, client_set_event_callback, client_screen_size, client_draw_indicator, client_eye_position = client.latency, client.log, client.draw_rectangle, client.draw_circle_outline, client.userid_to_entindex, client.draw_gradient, client.set_event_callback, client.screen_size, client.draw_indicator, client.eye_position 
local client_color_log, client_draw_circle, client_draw_text, client_visible, client_exec, client_delay_call, client_trace_line, client_world_to_screen = client.color_log, client.draw_circle, client.draw_text, client.visible, client.exec, client.delay_call, client.trace_line, client.world_to_screen 
local client_draw_hitboxes, client_get_cvar, client_draw_line, client_camera_angles, client_draw_debug_text, client_random_int, client_random_float = client.draw_hitboxes, client.get_cvar, client.draw_line, client.camera_angles, client.draw_debug_text, client.random_int, client.random_float 
local entity_get_local_player, entity_is_enemy, entity_get_player_name, entity_get_all, entity_set_prop, entity_get_player_weapon, entity_hitbox_position, entity_get_prop, entity_get_players, entity_get_classname = entity.get_local_player, entity.is_enemy, entity.get_player_name, entity.get_all, entity.set_prop, entity.get_player_weapon, entity.hitbox_position, entity.get_prop, entity.get_players, entity.get_classname 
local globals_realtime, globals_absoluteframetime, globals_tickcount, globals_curtime, globals_mapname, globals_tickinterval, globals_framecount, globals_frametime, globals_maxplayers = globals.realtime, globals.absoluteframetime, globals.tickcount, globals.curtime, globals.mapname, globals.tickinterval, globals.framecount, globals.frametime, globals.maxplayers 
local ui_new_slider, ui_new_combobox, ui_reference, ui_set_visible, ui_new_color_picker, ui_set_callback, ui_set, ui_new_checkbox, ui_new_hotkey, ui_new_button, ui_new_multiselect, ui_get = ui.new_slider, ui.new_combobox, ui.reference, ui.set_visible, ui.new_color_picker, ui.set_callback, ui.set, ui.new_checkbox, ui.new_hotkey, ui.new_button, ui.new_multiselect, ui.get 
local math_ceil, math_tan, math_log10, math_randomseed, math_cos, math_sinh, math_random, math_huge, math_pi, math_max, math_atan2, math_ldexp, math_floor, math_sqrt, math_deg, math_atan, math_fmod = math.ceil, math.tan, math.log10, math.randomseed, math.cos, math.sinh, math.random, math.huge, math.pi, math.max, math.atan2, math.ldexp, math.floor, math.sqrt, math.deg, math.atan, math.fmod 
local math_acos, math_pow, math_abs, math_min, math_sin, math_frexp, math_log, math_tanh, math_exp, math_modf, math_cosh, math_asin, math_rad = math.acos, math.pow, math.abs, math.min, math.sin, math.frexp, math.log, math.tanh, math.exp, math.modf, math.cosh, math.asin, math.rad 
local table_maxn, table_foreach, table_sort, table_remove, table_foreachi, table_move, table_getn, table_concat, table_insert = table.maxn, table.foreach, table.sort, table.remove, table.foreachi, table.move, table.getn, table.concat, table.insert 
local string_find, string_format, string_rep, string_gsub, string_len, string_gmatch, string_dump, string_match, string_reverse, string_byte, string_char, string_upper, string_lower, string_sub = string.find, string.format, string.rep, string.gsub, string.len, string.gmatch, string.dump, string.match, string.reverse, string.byte, string.char, string.upper, string.lower, string.sub 
--end of local variables 

local ignore_self = false
local planting_time = 3.125
local enable_reference = ui.reference("VISUALS", "Other ESP", "Bomb")

local function lerp_pos(x1, y1, z1, x2, y2, z2, percentage)
	local x = (x2 - x1) * percentage + x1
	local y = (y2 - y1) * percentage + y1
	local z = (z2 - z1) * percentage + z1
	return x, y, z
end

local function distance3d(x1, y1, z1, x2, y2, z2)
	return math_sqrt((x2-x1)^2 + (y2-y1)^2 + (z2-z1)^2)
end

local function get_site_name(site)
	local player_resource = entity_get_all("CCSPlayerResource")[1]
	local a_x, a_y, a_z = entity_get_prop(player_resource, "m_bombsiteCenterA")
	local b_x, b_y, b_z = entity_get_prop(player_resource, "m_bombsiteCenterB")

	local site_x1, site_y1, site_z1 = entity_get_prop(site, "m_vecMins")
	local site_x2, site_y2, site_z2 = entity_get_prop(site, "m_vecMaxs")
	local site_x, site_y, site_z = lerp_pos(site_x1, site_y1, site_z1, site_x2, site_y2, site_z2, 0.5)

	local distance_a, distance_b = distance3d(site_x, site_y, site_z, a_x, a_y, a_z), distance3d(site_x, site_y, site_z, b_x, b_y, b_z)

	return distance_b > distance_a and "A" or "B"
end

local planter, site, started_at
local function on_bomb_beginplant(e)
	local player = client_userid_to_entindex(e.userid)
	if ignore_self and player == entity_get_local_player() then
		return
	end

	planter = entity_get_player_name(player)
	site = get_site_name(e.site)
	started_at = globals_curtime()
end
client.set_event_callback("bomb_beginplant", on_bomb_beginplant)

local function reset(e)
	planter = nil
end
client.set_event_callback("round_end", reset)
client.set_event_callback("round_start", reset)
client.set_event_callback("bomb_abortplant", reset)
client.set_event_callback("bomb_planted", reset)

local function on_paint(ctx)
	if planter == nil then
		return
	end

	if not ui_get(enable_reference) then
		return
	end

	local plant_percentage = (globals_curtime() - started_at) / planting_time
	if plant_percentage > 0 and 1 > plant_percentage then
		local game_rules_proxy = entity_get_all("CCSGameRulesProxy")[1]
		if entity_get_prop(game_rules_proxy, "m_bBombPlanted") == 1 then
			return
		end

		local finished_at = (started_at + planting_time)

		local screen_width, screen_height = client_screen_size()
		local remove_from_height = screen_height * (1 - plant_percentage)

		local round_end_time = entity_get_prop(game_rules_proxy, "m_fRoundStartTime") + entity_get_prop(game_rules_proxy, "m_iRoundTime")
		local has_time = round_end_time > finished_at

		if not has_time then
			local restart_round_time = entity_get_prop(game_rules_proxy, "m_flRestartRoundTime")
			if restart_round_time ~= 0 and restart_round_time > finished_at then
				has_time = true
			end
		end

		local r_bar, g_bar, b_bar, a_bar = 41, 180, 33, 200
		local r_text, g_text, b_text, a_text = 255, 178, 0, 255

		if not has_time then
			r_bar, g_bar, b_bar = 255, 1, 1
			r_text, g_text, b_text = 255, 1, 1
		end

		--background
		client_draw_rectangle(ctx, 0, 0, 20, screen_height, 0, 0, 0, 196)
		--precentage bar
		client_draw_rectangle(ctx, 1, 0+remove_from_height, 18, screen_height-remove_from_height, r_bar, g_bar, b_bar, a_bar)

		client_draw_text(ctx, 5, 5, r_text, g_text, b_text, a_text, "+", 0, site, " - Planting")
		client_draw_text(ctx, 5, 30, 255, 255, 255, 255, "+", 0, planter)
	end
end
client.set_event_callback("paint", on_paint)
