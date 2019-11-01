--[[

	Signs Bot
	=========

	Copyright (C) 2019 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information
	
	Signs Bot: Robot basis block

]]--

-- for lazy programmers
local S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local P = minetest.string_to_pos
local M = minetest.get_meta

-- Load support for intllib.
local MP = minetest.get_modpath("signs_bot")
local I,_ = dofile(MP.."/intllib.lua")

local lib = signs_bot.lib

local CYCLE_TIME = 1
signs_bot.MAX_CAPA = 600

local function in_range(val, min, max)
	if val < min then return min end
	if val > max then return max end
	return val
end

-- determine item name from the given Bot inventory slot
function signs_bot.bot_inv_item_name(pos, slot)
	if slot == 0 then return nil end -- invalid num
	local inv = M(pos):get_inventory()
	local name = inv:get_stack("filter", slot):get_name()
	if name ~= "" then return name end
end
	
-- put items into the bot inventory and return leftover
function signs_bot.bot_inv_put_item(pos, slot, items)
	if not items then return end
	local inv = M(pos):get_inventory()
	if slot and slot > 0 then
		local name = inv:get_stack("filter", slot):get_name()
		if name == "" or name == items:get_name() then
			local stack = inv:get_stack("main", slot)
			items = stack:add_item(items)
			inv:set_stack("main", slot, stack)
		end
	else
		for idx = 1,8 do
			local name = inv:get_stack("filter", idx):get_name()
			if name == "" or name == items:get_name() then
				local stack = inv:get_stack("main", idx)
				items = stack:add_item(items)
				inv:set_stack("main", idx, stack)
				if items:get_count() == 0 then return items end
			end
		end
	end
	return items
end

-- take items from the bot inventory
function signs_bot.bot_inv_take_item(pos, slot, num)
	local inv = M(pos):get_inventory()
	if slot and slot > 0 then
		local stack = inv:get_stack("main", slot)
		if stack:get_count() > 0 then
			local taken = inv:remove_item("main", ItemStack(stack:get_name().." "..num)) 
			return taken
		end
	else
		for idx = 1,8 do
			local stack = inv:get_stack("main", idx)
			if stack:get_count() > 0 then
				local taken = inv:remove_item("main", ItemStack(stack:get_name().." "..num)) 
				return taken
			end
		end
	end
end

local bot_inv_item_name = signs_bot.bot_inv_item_name

local function preassigned_slots(pos)
	local inv = M(pos):get_inventory()
	local tbl = {}
	for idx = 1,8 do
		local item_name = inv:get_stack("filter", idx):get_name()
		if item_name ~= "" then
			local x = ((idx - 1) % 4) + 5
			local y = idx < 5 and 1 or 2
			tbl[#tbl+1] = "item_image["..x..","..y..";1,1;"..item_name.."]"
		end
	end
	return table.concat(tbl, "")
end

local function formspec(pos, mem)
	mem.running = mem.running or false
	local cmnd = mem.running and "stop;"..I("Off") or "start;"..I("On") 
	local bot = not mem.running and "image[0.6,0;1,1;signs_bot_bot_inv.png]" or ""
	local current_capa = mem.capa or (signs_bot.MAX_CAPA * 0.9)
	return "size[9,7.6]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"label[2.1,0;"..I("Signs").."]label[5.3,0;"..I("Other items").."]"..
	"image[0.6,0;1,1;signs_bot_form_mask.png]"..
	bot..
	preassigned_slots(pos)..
	signs_bot.formspec_battery_capa(signs_bot.MAX_CAPA, current_capa)..
	"label[2.1,0.5;1]label[3.1,0.5;2]label[4.1,0.5;3]"..
	"list[context;sign;1.8,1;3,2;]"..
	"label[2.1,3;4]label[3.1,3;5]label[4.1,3;6]"..
	"label[5.3,0.5;1]label[6.3,0.5;2]label[7.3,0.5;3]label[8.3,0.5;4]"..
	"list[context;main;5,1;4,2;]"..
	"label[5.3,3;5]label[6.3,3;6]label[7.3,3;7]label[8.3,3;8]"..
	"button[0.2,1;1.5,1;config;"..I("Config").."]"..
	"button[0.2,2;1.5,1;"..cmnd.."]"..
	"list[current_player;main;0.5,3.8;8,4;]"..
	"listring[context;main]"..
	"listring[current_player;main]"
end

local function formspec_cfg(pos, mem)
	return "size[9,7.6]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"label[5.3,0;"..I("Preassign slots items").."]"..
	"label[5.3,0.5;1]label[6.3,0.5;2]label[7.3,0.5;3]label[8.3,0.5;4]"..
	"list[context;filter;5,1;4,2;]"..
	"label[5.3,3;5]label[6.3,3;6]label[7.3,3;7]label[8.3,3;8]"..
	"button[0.2,1;1.5,1;back;"..I("Back").."]"..
	"list[current_player;main;0.5,3.8;8,4;]"
end

local function get_capa(itemstack)
	local meta = itemstack:get_meta()
	if meta then
		return in_range(meta:get_int("capa") * (signs_bot.MAX_CAPA/100), 0, 3000)
	end
	return 0
end

local function set_capa(pos, oldnode, digger, capa)
	local node = ItemStack(oldnode.name)
	local meta = node:get_meta()
	capa = techage.power.percent(signs_bot.MAX_CAPA, capa)
	capa = (math.floor((capa or 0) / 5)) * 5
	meta:set_int("capa", capa)
	local text = I("Robot Box ").." ("..capa.." %)"
	meta:set_string("description", text)
	local inv = minetest.get_inventory({type="player", name=digger:get_player_name()})
	local left_over = inv:add_item("main", node)
	if left_over:get_count() > 0 then
		minetest.add_item(pos, node)
	end
end

function signs_bot.infotext(pos, state)
	local meta = M(pos)
	local number = meta:get_string("number")
	state = state or "<unknown>"
	meta:set_string("infotext", I("Robot Box ")..number..": "..state)
end

local function reset_robot(pos, mem)
	mem.robot_param2 = (minetest.get_node(pos).param2 + 1) % 4
	mem.robot_pos = lib.next_pos(pos, mem.robot_param2, 1)
	mem.steps = nil
	local pos_below = {x=mem.robot_pos.x, y=mem.robot_pos.y-1, z=mem.robot_pos.z}
	signs_bot.place_robot(mem.robot_pos, pos_below, mem.robot_param2)	
end

local function start_robot(base_pos)
	local mem = tubelib2.get_mem(base_pos)
	local meta = M(base_pos)
	mem.lCmnd1 = {}
	mem.lCmnd2 = {}
	mem.running = true
	mem.charging = false
	mem.error = false
	mem.stored_node = nil
	if minetest.global_exists("techage") then
		mem.capa = mem.capa or 0 -- enable power consumption
	else
		mem.capa = nil
	end
	meta:set_string("formspec", formspec(base_pos, mem))
	signs_bot.infotext(base_pos, I("running"))
	reset_robot(base_pos, mem)
	minetest.get_node_timer(base_pos):start(CYCLE_TIME)
	return true
end

function signs_bot.stop_robot(base_pos, mem)
	local meta = M(base_pos)
	if mem.signal_request ~= true then
		mem.running = false
		if minetest.global_exists("techage") then
			minetest.get_node_timer(base_pos):start(2)
			mem.charging = true
		else
			minetest.get_node_timer(base_pos):stop()
			mem.charging = false
		end
		signs_bot.infotext(base_pos, I("stopped"))
		meta:set_string("formspec", formspec(base_pos, mem))
		signs_bot.remove_robot(mem)
	else
		mem.signal_request = false
		start_robot(base_pos)
	end
end

-- Used by the pairing tool
local function signs_bot_get_signal(pos, node)
	local mem = tubelib2.get_mem(pos)
	if mem.running then
		return "on"
	else
		return "off"
	end
end

-- To be called from sensors
local function signs_bot_on_signal(pos, node, signal)
	local mem = tubelib2.get_mem(pos)
	if signal == "on" and not mem.running then
		start_robot(pos)
	elseif signal == "off" and mem.running then
		signs_bot.stop_robot(pos, mem)
--	else
--		mem.signal_request = (signal == "on")
	end
end


local function node_timer(pos, elapsed)
	local mem = tubelib2.get_mem(pos)
	if mem.charging and signs_bot.while_charging then
		return signs_bot.while_charging(pos, mem)
	else
		local res = false
		--local t = minetest.get_us_time()
		if mem.running then
			res = signs_bot.run_next_command(pos, mem)
		end
		--t = minetest.get_us_time() - t
		--print("node_timer", t)
		return res and mem.running
	end
end

local function on_receive_fields(pos, formname, fields, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return
	end
	local mem = tubelib2.get_mem(pos)
	local meta = minetest.get_meta(pos)
	
	if fields.update then
		meta:set_string("formspec", formspec(pos, mem))
	elseif fields.config then
		meta:set_string("formspec", formspec_cfg(pos, mem))
	elseif fields.back then
		meta:set_string("formspec", formspec(pos, mem))
	elseif fields.start then
		start_robot(pos)
	elseif fields.stop then
		signs_bot.stop_robot(pos, mem)
	end
end

local function on_rightclick(pos)
	local mem = tubelib2.get_mem(pos)
	M(pos):set_string("formspec", formspec(pos, mem))
end

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	local mem = tubelib2.get_mem(pos)
	if mem.running then
		return 0
	end
	local name = stack:get_name()
	if listname == "sign" and minetest.get_item_group(name, "sign_bot_sign") ~= 1 then
		return 0
	end
	if listname == "main" and bot_inv_item_name(pos, index) and 
				name ~= bot_inv_item_name(pos, index) then
		return 0
	end
	if listname == "filter" then
		local inv = M(pos):get_inventory()
		local list = inv:get_list(listname)
		if list[index]:get_count() == 0 or stack:get_name() ~= list[index]:get_name() then
			return 1
		end
		return 0
	end
	return stack:get_count()
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	local mem = tubelib2.get_mem(pos)
	if mem.running then
		return 0
	end
	return stack:get_count()
end

local function allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	local mem = tubelib2.get_mem(pos)
	if mem.running then
		return 0
	end
	if from_list ~= to_list then
		return 0
	end
	local inv = M(pos):get_inventory()
	local name = inv:get_stack(from_list, from_index):get_name()
	if to_list == "main" and bot_inv_item_name(pos, to_index) and 
				name ~= bot_inv_item_name(pos, to_index) then
		return 0
	end
	if to_list == "filter" then
		local list = inv:get_list(to_list)
		if list[to_index]:get_count() == 0 or name ~= list[to_index]:get_name() then
			return 1
		end
		return 0
	end
	return count
end	

local drop = "signs_bot:box"
if minetest.global_exists("techage") then
	drop = ""
end

minetest.register_node("signs_bot:box", {
	description = I("Signs Bot Box"),
	stack_max = 1,
	tiles = {
		-- up, down, right, left, back, front
		'signs_bot_base_top.png',
		'signs_bot_base_top.png',
		'signs_bot_base_right.png',
		'signs_bot_base_left.png',
		'signs_bot_base_front.png',
		'signs_bot_base_front.png',
	},

	on_construct = function(pos)
		local meta = M(pos)
		local inv = meta:get_inventory()
		inv:set_size('main', 8)
		inv:set_size('sign', 6)
		inv:set_size('filter', 8)
	end,
	
	after_place_node = function(pos, placer, itemstack)
		local mem = tubelib2.init_mem(pos)
		mem.running = false
		mem.error = false
		local meta = M(pos)
		local number = ""
		if minetest.global_exists("techage") then
			number = techage.add_node(pos, "signs_bot:box")
		end
		meta:set_string("owner", placer:get_player_name())
		meta:set_string("number", number)
		meta:set_string("formspec", formspec(pos, mem))
		meta:set_string("signs_bot_cmnd", "turn_off")
		meta:set_int("err_code", 0)
		signs_bot.infotext(pos, I("stopped"))
		if minetest.global_exists("techage") then
			techage.power.after_place_node(pos)
			mem.capa = get_capa(itemstack)
		end
	end,

	signs_bot_get_signal = signs_bot_get_signal,
	signs_bot_on_signal = signs_bot_on_signal,
	on_receive_fields = on_receive_fields,
	on_rightclick = on_rightclick,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	
	can_dig = function(pos, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return
		end
		local mem = tubelib2.get_mem(pos)
		if mem.running then
			return
		end
		local inv = M(pos):get_inventory()
		return inv:is_empty("main") and inv:is_empty("sign")
	end,
	
	on_dig = function(pos, node, puncher, pointed_thing)
		minetest.node_dig(pos, node, puncher, pointed_thing)
	end,
	
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		if minetest.global_exists("techage") then
			techage.power.after_dig_node(pos, oldnode)
			local mem = tubelib2.get_mem(pos)
			set_capa(pos, oldnode, digger, mem.capa)
		end
		tubelib2.del_mem(pos)
	end,

	after_tube_update = function(node, pos, out_dir, peer_pos, peer_in_dir) 
		if minetest.global_exists("techage") then
			techage.power.after_tube_update2(node, pos, out_dir, peer_pos, peer_in_dir)
		end
	end,
	
	on_timer = node_timer,
	on_rotate = screwdriver.disallow,
	
	drop = drop,
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {cracky = 1},
	sounds = default.node_sound_metal_defaults(),
})


if minetest.global_exists("techage") then
	minetest.register_craft({
		output = "signs_bot:box",
		recipe = {
			{"default:steel_ingot", "group:wood", "default:steel_ingot"},
			{"basic_materials:motor", "techage:ta4_wlanchip", "basic_materials:gear_steel"},
			{"default:tin_ingot", "", "default:tin_ingot"}
		}
	})
else
	minetest.register_craft({
		output = "signs_bot:box",
		recipe = {
			{"default:steel_ingot", "group:wood", "default:steel_ingot"},
			{"basic_materials:motor", "default:mese_crystal", "basic_materials:gear_steel"},
			{"default:tin_ingot", "", "default:tin_ingot"}
		}
	})
end

if minetest.global_exists("techage") then
	techage.register_node({"signs_bot:box"}, {
		on_pull_item = function(pos, in_dir, num)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return techage.get_items(inv, "main", num)
		end,
		on_push_item = function(pos, in_dir, stack)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return techage.put_items(inv, "main", stack)
		end,
		on_unpull_item = function(pos, in_dir, stack)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return techage.put_items(inv, "main", stack)
		end,
		
		on_recv_message = function(pos, topic, payload)
			local mem = tubelib2.get_mem(pos)
			if topic == "state" then
				if mem.error then
					return "fault"
				elseif mem.running then
					if mem.curr_cmnd == "stop" then
						return "standby"
					elseif mem.blocked then
						return "blocked"
					else
						return "running"
					end
				elseif mem.capa then
					if mem.capa <= 0 then
						return "nopower"
					elseif mem.capa >= signs_bot.MAX_CAPA then
						return "stopped"
					else
						return "loading"
					end
				else
					return "stopped"
				end
			elseif topic == "fuel" then
				return signs_bot.percent_value(signs_bot.MAX_CAPA, mem.capa)
			else
				return "unsupported"
			end
		end,
	})	
	
end

if minetest.get_modpath("doc") then
	doc.add_entry("signs_bot", "box", {
		name = I("Signs Bot Box"),
		data = {
			item = "signs_bot:box",
			text = table.concat({
				I("The Box is the housing of the bot."),
				I("Place the box and start the bot by means of the 'On' button."), 
				I("If the mod techage is installed, the bot needs electrical power."),
				"",
				I("The bot leaves the box on the right side."),
				I("It will not start, if this position is blocked."),
				"",
				I("To stop and remove the bot, press the 'Off' button."),
				"",
				I("The box inventory simulates the inventory of the bot."),
				I("You will not be able to access the inventory, if the bot is running."),
				I("The bot can carry up to 8 stacks and 6 signs with it."),
			}, "\n")		
		},
	})
end
