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

	function signs_bot.formspec_battery_capa(max_capa, current_capa)
		local percent = percent_value(max_capa, current_capa)
		return "image[0.1,1;0.5,1;signs_bot_form_level_bg.png^[lowpart:"..
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

	local Cable = techage.ElectricCable
	local consume_power = techage.power.consume_power
	local power_available = techage.power.power_available

	local PWR_NEEDED = 8

	local function on_power(pos)
		local mem = tubelib2.get_mem(pos)
		mem.capa = mem.capa or 0
		if not mem.running and mem.capa < signs_bot.MAX_CAPA then  -- Bot in the box
			local got = consume_power(pos, PWR_NEEDED)
			if got >= PWR_NEEDED then
				mem.capa = mem.capa + 4
			end
		end
	end

	techage.power.register_node({"signs_bot:box"}, {
		power_network  = Cable,
		conn_sides = {"L", "U", "D", "F", "B"},
		on_power = on_power,
	})
else
	function signs_bot.formspec_battery_capa(max_capa, current_capa)
		return ""
	end
end