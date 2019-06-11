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
else
	function signs_bot.formspec_battery_capa(max_capa, current_capa)
		return ""
	end
end