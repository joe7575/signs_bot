--[[

	Signs Bot
	=========

	Copyright (C) 2019 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information
	
	Node Sensor

]]--

-- for lazy programmers
local S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local P = minetest.string_to_pos
local M = minetest.get_meta

-- Load support for intllib.
local MP = minetest.get_modpath("signs_bot")
local I,_ = dofile(MP.."/intllib.lua")

local lib = signs_bot.lib

local CYCLE_TIME = 4

local function update_infotext(pos, dest_pos, cmnd)
	M(pos):set_string("infotext", I("Node Sensor: Connected with ")..S(dest_pos).." / "..cmnd)
end	

local function swap_node(pos, name)
	local node = minetest.get_node(pos)
	if node.name == name then
		return false
	end
	node.name = name
	minetest.swap_node(pos, node)
	return true
end
	
local function any_node_changed(pos)
	local mem = tubelib2.get_mem(pos)
	if not mem.pos1 or not mem.pos2 or not mem.num then
		local node = minetest.get_node(pos)
		local param2 = (node.param2 + 2) % 4
		mem.pos1 = lib.dest_pos(pos, param2, {0})
		mem.pos2 = lib.dest_pos(pos, param2, {0,0,0})
		mem.num = #minetest.find_nodes_in_area(mem.pos1, mem.pos2, {"air"})
		return false
	end
	local num = #minetest.find_nodes_in_area(mem.pos1, mem.pos2, {"air"})
	if mem.num ~= num then
		mem.num = num
		return true
	end
	return false
end

local function node_timer(pos)
	if any_node_changed(pos)then
		if swap_node(pos, "signs_bot:node_sensor_on") then
			signs_bot.send_signal(pos)
			signs_bot.lib.activate_extender_nodes(pos, true)
		end
	else
		swap_node(pos, "signs_bot:node_sensor")
	end
	return true
end

minetest.register_node("signs_bot:node_sensor", {
	description = I("Node Sensor"),
	inventory_image = "signs_bot_sensor_node_inv.png",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -11/32, -1/2, -11/32, 11/32, -5/16, 11/32},
		},
	},
	tiles = {
		-- up, down, right, left, back, front
		"signs_bot_sensor1.png^signs_bot_sensor_node.png",
		"signs_bot_sensor1.png",
		"signs_bot_sensor1.png^[transformFXR90",
		"signs_bot_sensor1.png^[transformFXR90",
		"signs_bot_sensor1.png^[transformFXR90",
		"signs_bot_sensor1.png^[transformFXR180",
	},
	
	after_place_node = function(pos, placer)
		local meta = M(pos)
		local mem = tubelib2.init_mem(pos)
		meta:set_string("infotext", "Node Sensor: Not connected")
		minetest.get_node_timer(pos):start(CYCLE_TIME)
		any_node_changed(pos)
	end,
	
	on_timer = node_timer,
	update_infotext = update_infotext,
	on_rotate = screwdriver.disallow,
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {sign_bot_sensor = 1, cracky = 1},
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("signs_bot:node_sensor_on", {
	description = I("Node Sensor"),
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -11/32, -1/2, -11/32, 11/32, -5/16, 11/32},
		},
	},
	tiles = {
		-- up, down, right, left, back, front
		"signs_bot_sensor1.png^signs_bot_sensor_node_on.png",
		"signs_bot_sensor1.png",
		"signs_bot_sensor1.png^[transformFXR90",
		"signs_bot_sensor1.png^[transformFXR90",
		"signs_bot_sensor1.png^[transformFXR90",
		"signs_bot_sensor1.png^[transformFXR180",
	},
			
	on_timer = node_timer,
	update_infotext = update_infotext,
	on_rotate = screwdriver.disallow,
	paramtype = "light",
	sunlight_propagates = true,
	paramtype2 = "facedir",
	is_ground_content = false,
	diggable = false,
	groups = {sign_bot_sensor = 1, not_in_creative_inventory = 1},
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_craft({
	output = "signs_bot:node_sensor",
	recipe = {
		{"", "", ""},
		{"dye:black", "group:stone", "dye:grey"},
		{"default:steel_ingot", "default:mese_crystal_fragment", "default:steel_ingot"}
	}
})

minetest.register_lbm({
	label = "[signs_bot] Restart timer",
	name = "signs_bot:node_sensor_restart",
	nodenames = {"signs_bot:node_sensor", "signs_bot:node_sensor_on"},
	run_at_every_load = true,
	action = function(pos, node)
		minetest.get_node_timer(pos):start(CYCLE_TIME)
	end
})
