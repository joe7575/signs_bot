-- Load support for intllib.
local MP = minetest.get_modpath("signs_bot")
local S, NS = dofile(MP.."/intllib.lua")

if minetest.global_exists("techage") then
	signs_bot.register_inventory({"techage:chest_ta2", "techage:chest_ta3", "techage:chest_ta4"}, {
		allow_inventory_put = function(pos, stack, player_name)
			return not minetest.is_protected(pos, player_name)
		end, 
		allow_inventory_take = function(pos, stack, player_name)
			return not minetest.is_protected(pos, player_name)
		end, 
		put = {
			listname = "main",
		},
		take = {
			listname = "main",
		},
	})
	signs_bot.register_inventory({"techage:meltingpot", "techage:meltingpot_active"}, {
		allow_inventory_put = function(pos, stack, player_name)
			return not minetest.is_protected(pos, player_name)
		end, 
		allow_inventory_take = function(pos, stack, player_name)
			return not minetest.is_protected(pos, player_name)
		end, 
		put = {
			listname = "src",
		},
		take = {
			listname = "dst",
		},
	})

	local function percent_value(max_val, curr_val)
		return math.min(math.ceil(((curr_val or 0) * 100.0) / (max_val or 1.0)), 100)
	end
	signs_bot.percent_value = percent_value
	
	function signs_bot.formspec_battery_capa(max_capa, current_capa)
		local percent = percent_value(max_capa, current_capa)
		return "image[0.1,0;0.5,1;signs_bot_form_level_bg.png^[lowpart:"..
				percent..":signs_bot_form_level_fg.png]"
	end

	signs_bot.register_botcommand("ignite", {
		mod = "techage",
		params = "",	
		description = S("Ignite the techage charcoal lighter"),
		cmnd = function(base_pos, mem)
			local pos = signs_bot.lib.dest_pos(mem.robot_pos, mem.robot_param2, {0})
			local node = signs_bot.lib.get_node_lvm(pos)
			if minetest.registered_nodes[node.name]
			and minetest.registered_nodes[node.name].on_ignite then
				minetest.registered_nodes[node.name].on_ignite(pos)
			end
			return true
		end,
	})

	signs_bot.register_botcommand("low_batt", {
		mod = "techage",
		params = "<percent>",	
		description = S("Turn the bot off if the\nbattery power is below the\ngiven value (1..99)"),
		check = function(val)
			val = tonumber(val or 5)
			return val and val > 0 and val < 100
		end,
		cmnd = function(base_pos, mem, val)
			val = tonumber(val or 5)
			local pwr = percent_value(signs_bot.MAX_CAPA, mem.capa)
			if pwr < val then
				signs_bot.stop_robot(base_pos, mem)
				return signs_bot.lib.TURN_OFF
			end
			return true
		end,
	})
	
	local Cable = techage.ElectricCable
	local power = techage.power

	local PWR_NEEDED = 8

	local function on_power(pos, mem)
		mem.power_available = true
		if not mem.running then
			signs_bot.infotext(pos, S("charging"))
		end
	end

	local function on_nopower(pos, mem)
		mem.power_available = false
		if not mem.running then
			signs_bot.infotext(pos, S("no power"))
		end
	end

    -- Bot in the box
	function signs_bot.while_charging(pos, mem)
		mem.capa = mem.capa or 0
		if mem.power_available then
			if mem.capa < signs_bot.MAX_CAPA then
				power.consumer_alive(pos, mem)
				mem.capa = mem.capa + 4
			else
				power.consumer_stop(pos, mem)
				minetest.get_node_timer(pos):stop()
				mem.charging = false
				if not mem.running then
					signs_bot.infotext(pos, S("fully charged"))
				end
				return false
			end
		else
			power.consumer_start(pos, mem, 2, PWR_NEEDED)
		end
		return true
	end

	techage.power.enrich_node({"signs_bot:box"}, {
		power_network  = Cable,
		conn_sides = {"L", "U", "D", "F", "B"},
		on_power = on_power,
		on_nopower = on_nopower,
	})
else
	function signs_bot.formspec_battery_capa(max_capa, current_capa)
		return ""
	end
end