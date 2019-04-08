--[[

	Signs Bot
	=========

	Copyright (C) 2019 Joachim Stolberg

	LGPLv2.1+
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

local function formspec(pos, mem)
	mem.running = mem.running or false
	local cmnd = mem.running and "stop;"..I("Off") or "start;"..I("On") 
	return "size[10,8]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"label[2.8,0;"..I("Signs").."]label[6.3,0;"..I("Other items").."]"..
	"label[2.8,0.5;1]label[3.8,0.5;2]label[4.8,0.5;3]"..
	"list[context;sign;2.5,1;3,2;]"..
	"label[2.8,3;4]label[3.8,3;5]label[4.8,3;6]"..
	"label[6.3,0.5;1]label[7.3,0.5;2]label[8.3,0.5;3]label[9.3,0.5;4]"..
	"list[context;main;6,1;4,2;]"..
	"label[6.3,3;5]label[7.3,3;6]label[8.3,3;7]label[9.3,3;8]"..
	"button[0.4,2;1.8,1;"..cmnd.."]"..
	"list[current_player;main;1,4;8,4;]"..
	"listring[context;main]"..
	"listring[current_player;main]"
end

function signs_bot.infotext(pos, state)
	local meta = minetest.get_meta(pos)
	local number = meta:get_string("number")
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
	local meta = minetest.get_meta(base_pos)
	mem.lCmnd1 = {}
	mem.lCmnd2 = {}
	mem.running = true
	meta:set_string("formspec", formspec(base_pos, mem))
	signs_bot.infotext(base_pos, I("running"))
	reset_robot(base_pos, mem)
	minetest.get_node_timer(base_pos):start(CYCLE_TIME)
	return true
end

function signs_bot.stop_robot(base_pos, mem)
	local meta = minetest.get_meta(base_pos)
	mem.running = false
	minetest.get_node_timer(base_pos):stop()
	signs_bot.infotext(base_pos, I("stopped"))
	meta:set_string("formspec", formspec(base_pos, mem))
	signs_bot.remove_robot(mem.robot_pos)
end

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
	end
end


local function node_timer(pos, elapsed)
	local mem = tubelib2.get_mem(pos)
	--local t = minetest.get_us_time()
	local res = signs_bot.run_next_command(pos, mem)
	--t = minetest.get_us_time() - t
	--print("node_timer", t)
	return res
end

local function on_receive_fields(pos, formname, fields, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return
	end
	local mem = tubelib2.get_mem(pos)
	local meta = minetest.get_meta(pos)
	
	if fields.update then
		meta:set_string("formspec", formspec(pos, mem))
	elseif fields.start == I("On") then
		start_robot(pos)
	elseif fields.stop == I("Off") then
		signs_bot.stop_robot(pos, mem)
	end
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
	return count
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
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size('main', 8)
		inv:set_size('sign', 6)
	end,
	
	after_place_node = function(pos, placer)
		local mem = tubelib2.init_mem(pos)
		mem.running = false
		local meta = minetest.get_meta(pos)
		local number = "0000" --tubelib.add_node(pos, "signs_bot:base")
		meta:set_string("owner", placer:get_player_name())
		meta:set_string("number", number)
		meta:set_string("formspec", formspec(pos, mem))
		meta:set_string("signs_bot_cmnd", "turn_off")
		meta:set_int("err_code", 0)
		signs_bot.infotext(pos, I("stopped"))
	end,

	signs_bot_get_signal = signs_bot_get_signal,
	signs_bot_on_signal = signs_bot_on_signal,
	on_receive_fields = on_receive_fields,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	
	on_dig = function(pos, node, puncher, pointed_thing)
		if minetest.is_protected(pos, puncher:get_player_name()) then
			return
		end
		local mem = tubelib2.init_mem(pos)
		if mem.running then
			return
		end
		minetest.node_dig(pos, node, puncher, pointed_thing)
		--tubelib.remove_node(pos)
	end,
	
	on_timer = node_timer,
	
	on_rotate = screwdriver.disallow,
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {cracky = 1},
	sounds = default.node_sound_metal_defaults(),
})


minetest.register_craft({
	output = "signs_bot:box",
	recipe = {
		{"default:steel_ingot", "group:wood", "default:steel_ingot"},
		{"basic_materials:motor", "default:mese_crystal", "basic_materials:gear_steel"},
		{"default:tin_ingot", "", "default:tin_ingot"}
	}
})

