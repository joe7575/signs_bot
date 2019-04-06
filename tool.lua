--[[

	Signs Bot
	=========

	Copyright (C) 2019 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information
	
	Sensor/Actuator Connection Tool

]]--

-- for lazy programmers
local S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local P = minetest.string_to_pos
local M = minetest.get_meta

-- Load support for intllib.
local MP = minetest.get_modpath("signs_bot")
local I,_ = dofile(MP.."/intllib.lua")

local lib = signs_bot.lib

local function get_current_data(pointed_thing)
	local pos = pointed_thing.under
	local ntype = signs_bot.get_node_type(pos)
	return pos, ntype
end

local function get_stored_data(placer)
	local spos = placer:get_attribute("signs_bot_spos")
	local name = placer:get_attribute("signs_bot_name")
	if spos ~= "" then
		return minetest.string_to_pos(spos), name
	end
end
	
local function store_data(placer, pos, name)
	if pos then
		local spos = minetest.pos_to_string(pos)
		placer:set_attribute("signs_bot_spos", spos)
		placer:set_attribute("signs_bot_name", name)
	else
		placer:set_attribute("signs_bot_spos", nil)
		placer:set_attribute("signs_bot_name", nil)
	end
end

-- Write actuator_pos data to sensor_pos
local function pairing(actuator_pos, sensor_pos)
	local signal = signs_bot.get_signal(actuator_pos)
	signs_bot.store_signal(sensor_pos, actuator_pos, signal)
	local node = lib.get_node_lvm(sensor_pos)
	minetest.registered_nodes[node.name].update_infotext(sensor_pos, actuator_pos, signal)
end

local function use_tool(itemstack, placer, pointed_thing)
	if pointed_thing.type == "node" then
		local pos1,ntype1 = get_stored_data(placer)
		local pos2,ntype2 = get_current_data(pointed_thing)
		
		if ntype1 == "actuator" and ntype2 == "sensor" then
			pairing(pos1, pos2)
			store_data(placer, nil, nil)
			minetest.sound_play('signs_bot_pong', {to_player = placer:get_player_name()})
		elseif ntype2 == "actuator" and ntype1 == "sensor" then
			pairing(pos2, pos1)
			store_data(placer, nil, nil)
			minetest.sound_play('signs_bot_pong', {to_player = placer:get_player_name()})
		elseif ntype2 == "actuator" or ntype2 == "sensor" then
			store_data(placer, pos2, ntype2)
			minetest.sound_play('signs_bot_ping', {to_player = placer:get_player_name()})
		else
			store_data(placer, nil, nil)
			minetest.sound_play('signs_bot_error', {to_player = placer:get_player_name()})
		end
		return
	end
end
			
local Param2Matrix = {
	{0,1,2,3},  -- y+
	{6,15,8,17},  -- z+
	{4,13,10,19},  -- z-
	{5,14,11,16},  -- x+
	{7,12,9,18},  -- x-
	{22,21,20,23},  -- y-
}

local tRotation = {}
local Wallmounted = {[0]=3,5,4,2}

for _,row in ipairs(Param2Matrix) do
	for idx,elem in ipairs(row) do
		local tbl = {}
		for i = 0,3 do
			tbl[i] = row[((i+idx-1) % 4) + 1]
		end
		tRotation[elem] = tbl
	end
end

local function param2_conversion(node, offs) 
	local ndef = minetest.registered_nodes[node.name]
	if not ndef or not ndef.paramtype2 then	return end
	if ndef.paramtype2 == "facedir" then
		node.param2 = tRotation[node.param2][offs]
	elseif ndef.paramtype2 == "wallmounted" and node.param2 > 1 then
		node.param2 = Wallmounted[(node.param2 + offs - 2) % 4]
	end
end

local function test(itemstack, placer, pointed_thing)
	if pointed_thing.type == "node" then
		local pos = pointed_thing.under
		local node = minetest.get_node(pos)
		param2_conversion(node, 1) 
		minetest.swap_node(pos, node)
	end
end
		
minetest.register_node("signs_bot:connector", {
	description = I("Sensor Connection Tool"),
	inventory_image = "signs_bot_tool.png",
	wield_image = "signs_bot_tool.png",
	groups = {cracky=1, book=1},
	on_use = test,
	on_place = test,
	node_placement_prediction = "",
	stack_max = 1,
})

minetest.register_craft({
	output = "signs_bot:connector",
	recipe = {
		{"basic_materials:plastic_strip", "dye:black", ""},
		{"", "basic_materials:silicon", ""},
		{"", "", "basic_materials:plastic_strip"}
	}
})

minetest.register_node("signs_bot:cube", {
	description = "Cube",
	-- up, down, right, left, back, front
	tiles = {
		"signs_bot_yp.png",
		"signs_bot_ym.png",
		"signs_bot_xp.png",
		"signs_bot_xm.png",
		"signs_bot_zp.png",
		"signs_bot_zm.png",
	},
	is_ground_content = false,
	paramtype2 = "facedir",
	groups = {snappy=3,cracky=3,oddly_breakable_by_hand=3},
	drop = "",
	sounds = default.node_sound_glass_defaults(),
})
