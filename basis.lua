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

function signs_bot.output(pos, text)
	local meta = minetest.get_meta(pos)
	text = meta:get_string("output") .. "\n" .. (text or "")
	text = text:sub(-500,-1)
	meta:set_string("output", text)
end

local function formspec1(pos, mem)
	mem.running = mem.running or false
	local cmnd = mem.running and "stop;"..I("Stop") or "start;"..I("Start") 
	return "size[10,8]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"tabheader[0,0;tab;"..I("Inventory,Output")..";1;;true]"..
	"label[3.8,0;"..I("Signs").."]label[6.3,0;"..I("Other items").."]"..
	"label[3.8,0.5;1]label[4.8,0.5;2]"..
	"list[context;sign;3.5,1;2,2;]"..
	"label[3.8,3;3]label[4.8,3;4]"..
	"label[6.3,0.5;1]label[7.3,0.5;2]label[8.3,0.5;3]label[9.3,0.5;4]"..
	"list[context;main;6,1;4,2;]"..
	"label[6.3,3;5]label[7.3,3;6]label[8.3,3;7]label[9.3,3;8]"..
	"button[0.5,1.7;1.8,1;"..cmnd.."]"..
	"list[current_player;main;1,4;8,4;]"..
	"listring[context;main]"..
	"listring[current_player;main]"
end

local function formspec2(pos, mem)
	mem.running = mem.running or false
	local cmnd = mem.running and "stop;"..I("Stop") or "start;"..I("Start") 
	local output = M(pos):get_string("output")
	output = minetest.formspec_escape(output)
	return "size[10,8]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"tabheader[0,0;tab;"..I("Inventory,Output")..";2;;true]"..
	"textarea[0.3,0.2;10,8.3;help;"..I("Output")..":;"..output.."]"..
	"button[4.4,7.5;1.8,1;clear;"..I("Clear").."]"..
	"button[6.3,7.5;1.8,1;update;"..I("Update").."]"..
	"button[8.2,7.5;1.8,1;"..cmnd.."]"
end

local function error(pos, err)
	local mem = tubelib2.get_mem(pos)
	output(pos, err)
	local number = M(pos):get_string("number")
	mem.running = false
	minetest.get_node_timer(pos):stop()
	minetest.sound_play('signs_bot_error', {pos = mem.robot_pos})
	return false
end

local function reset_robot(pos, mem)
--	if mem.robot_pos then
--		minetest.after(5, minetest.remove_node, table.copy(mem.robot_pos))
--	end
	
	mem.robot_param2 = (minetest.get_node(pos).param2 + 1) % 4
	mem.robot_pos = lib.next_pos(pos, mem.robot_param2, 1)
	local pos_below = {x=mem.robot_pos.x, y=mem.robot_pos.y-1, z=mem.robot_pos.z}
	signs_bot.place_robot(mem.robot_pos, pos_below, mem.robot_param2)	
end

local function start_robot(pos)
	local mem = tubelib2.get_mem(pos)
	local meta = minetest.get_meta(pos)
	local number = meta:get_string("number")
	
--	print("start_robot")
--	if not check_fuel(pos, meta) then 
--		local number = meta:get_string("number")
--		meta:set_string("infotext", "Robot Base "..number..": no fuel")
--		return false 
--	end
	mem.running = true
	meta:set_string("formspec", formspec1(pos, mem))
	reset_robot(pos, mem)
	minetest.get_node_timer(pos):start(CYCLE_TIME)
	meta:set_string("infotext", I("Robot Box ")..number..I(": running"))
	return true
end

function signs_bot.stop_robot(base_pos, mem)
	local meta = minetest.get_meta(base_pos)
	local number = meta:get_string("number")
	mem.running = false
	mem.lCmnd = nil
	minetest.get_node_timer(base_pos):stop()
	meta:set_string("infotext", I("Robot Box ")..number..I(": stopped"))
	meta:set_string("formspec", formspec1(base_pos, mem))
	signs_bot.remove_robot(mem.robot_pos)
end

local function node_timer(pos, elapsed)
	local mem = tubelib2.get_mem(pos)
	return signs_bot.run_next_command(pos, mem)
end

local function on_receive_fields(pos, formname, fields, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return
	end
	local mem = tubelib2.get_mem(pos)
	local meta = minetest.get_meta(pos)
	
	if fields.update then
		meta:set_string("formspec", formspec1(pos, mem))
	elseif fields.tab == "1" then
		meta:set_string("formspec", formspec1(pos, mem))
	elseif fields.tab == "2" then
		meta:set_string("formspec", formspec2(pos, mem))
	elseif fields.start == I("Start") then
		start_robot(pos)
	elseif fields.stop == I("Stop") then
		signs_bot.stop_robot(pos, mem)
	end
end

local function allow_metadata_inventory(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	return stack:get_count()
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
		inv:set_size('sign', 4)
	end,
	
	after_place_node = function(pos, placer)
		local mem = tubelib2.init_mem(pos)
		mem.running = false
		local meta = minetest.get_meta(pos)
		local number = "0000" --tubelib.add_node(pos, "signs_bot:base")
		meta:set_string("owner", placer:get_player_name())
		meta:set_string("number", number)
		meta:set_string("formspec", formspec1(pos, mem))
		meta:set_string("infotext", I("Robot Box ")..number..I(": stopped"))
		meta:set_string("signs_bot_cmnd", "turn_off")
	end,

	on_receive_fields = on_receive_fields,
	allow_metadata_inventory_put = allow_metadata_inventory,
	allow_metadata_inventory_take = allow_metadata_inventory,
	
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
	
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {cracky = 1},
	sounds = default.node_sound_metal_defaults(),
})


--minetest.register_craft({
--	type = "shapeless",
--	output = "signs_bot:robot",
--	recipe = {"smartline:controller"}
--})

