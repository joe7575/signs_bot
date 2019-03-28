--[[

	Signs Bot
	=========

	Copyright (C) 2019 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information
	
	Signs Bot: Logic Nodes

]]--

-- for lazy programmers
local S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local P = minetest.string_to_pos
local M = minetest.get_meta

-- Load support for intllib.
local MP = minetest.get_modpath("signs_bot")
local I,_ = dofile(MP.."/intllib.lua")

local lib = signs_bot.lib

local formspec = "size[8,7]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"label[1,1.3;"..I("Signs:").."]"..
	"label[2.6,0.7;1]label[5.1,0.7;2]"..
	"list[context;sign;3,0.5;2,2;]"..
	"label[2.6,1.7;3]label[5.1,1.7;4]"..
	"list[current_player;main;0,3;8,4;]"..
	"listring[context;main]"..
	"listring[current_player;main]"


-- Get one sign from the robot signs inventory
local function get_inv_sign(pos, slot)
	local inv = minetest.get_inventory({type="node", pos=pos})
	local stack = inv:get_stack("sign", slot)
	local taken = stack:take_item(1)
	inv:set_stack("sign", slot, stack)
	return taken
end

local function put_inv_sign(pos, slot, sign)
	local inv = minetest.get_inventory({type="node", pos=pos})
	inv:set_stack("sign", slot, sign)
end


local function switch_sign_changer(pos, new_idx)
	-- swap changer
	local node = lib.get_node_lvm(pos)
	local pos1 = lib.next_pos(pos, (node.param2 + 1) % 4)
	local old_idx = tonumber(string.sub(node.name, 18))
	node.name = "signs_bot:changer"..new_idx
	minetest.swap_node(pos, node)
	-- swap sign
	local param2 = minetest.get_node(pos).param2
	local sign = lib.dig_sign(pos1)
	if sign then
		M(pos):set_int("sign_param2", param2)
		put_inv_sign(pos, old_idx, sign)
	end
	sign = get_inv_sign(pos, new_idx)
	if sign:get_count() == 1 then
		lib.place_sign(pos1, sign, M(pos):get_int("sign_param2"))
	end
end

local function swap_node(pos, node)
	local slot = tonumber(string.sub(node.name, 18))
	local new_idx = (slot % 4) + 1
	switch_sign_changer(pos, new_idx)
end

local function allow_metadata_inventory()
	return 0
end

for idx = 1,4 do
	local not_in_inv = idx == 1 and 0 or 1
	minetest.register_node("signs_bot:changer"..idx, {
		description = "Sign Changer",
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {
				{ -11/32, -1/2, -11/32, 11/32, -5/16, 11/32},
			},
		},
		tiles = {
			-- up, down, right, left, back, front
			"signs_bot_changer.png^signs_bot_changer"..idx..".png",
			"signs_bot_changer.png^signs_bot_changer"..idx..".png",
			"signs_bot_changer.png^signs_bot_changer"..idx..".png^[transformFXR90",
			"signs_bot_changer.png^signs_bot_changer"..idx..".png",
			"signs_bot_changer.png^signs_bot_changer"..idx..".png",
			"signs_bot_changer.png^signs_bot_changer"..idx..".png",
		},
		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			inv:set_size('sign', 4)
		end,
		
		after_place_node = function(pos, placer)
			local meta = minetest.get_meta(pos)
			meta:set_string("formspec", formspec)
		end,
		
		allow_metadata_inventory_put = allow_metadata_inventory,
		allow_metadata_inventory_take = allow_metadata_inventory,
		on_punch = swap_node,

		on_rotate = screwdriver.disallow,
		paramtype2 = "facedir",
		is_ground_content = false,
		groups = {cracky = 1, not_in_creative_inventory = not_in_inv},
		drop = "signs_bot:changer1",
		sounds = default.node_sound_metal_defaults(),
	})
end


minetest.register_node("signs_bot:bot_sensor", {
	description = "Bot Sensor",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -11/32, -1/2, -11/32, 11/32, -5/16, 11/32},
		},
	},
	tiles = {
		-- up, down, right, left, back, front
		"signs_bot_changer.png^signs_bot_sensor.png",
		"signs_bot_changer.png^signs_bot_sensor.png",
		"signs_bot_changer.png^signs_bot_sensor.png^[transformFXR90",
		"signs_bot_changer.png^signs_bot_sensor.png",
		"signs_bot_changer.png^signs_bot_sensor.png",
		"signs_bot_changer.png^signs_bot_sensor.png",
	},
	
	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Bot Sensor: Not connected")
	end,
	
	switch_sign_changer = switch_sign_changer,
	on_rotate = screwdriver.disallow,
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {cracky = 1},
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("signs_bot:bot_sensor_on", {
	description = "Bot Sensor",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -11/32, -1/2, -11/32, 11/32, -5/16, 11/32},
		},
	},
	tiles = {
		-- up, down, right, left, back, front
		"signs_bot_sensor.png^signs_bot_sensor_on.png",
		"signs_bot_sensor.png",
		"signs_bot_sensor.png^[transformFXR90",
		"signs_bot_sensor.png",
		"signs_bot_sensor.png",
		"signs_bot_sensor.png",
	},
	
	after_place_node = function(pos)
		minetest.get_node_timer(pos):start(1)
	end,
		
	on_timer = function(pos)
		local node = lib.get_node_lvm(pos)
		node.name = "signs_bot:bot_sensor"
		minetest.swap_node(pos, node)
		return false
	end,
	
	switch_sign_changer = switch_sign_changer,
	on_rotate = screwdriver.disallow,
	paramtype2 = "facedir",
	is_ground_content = false,
	diggable = false,
	groups = {not_in_creative_inventory = 1},
	sounds = default.node_sound_metal_defaults(),
})

local function get_current_data(pointed_thing)
	local pos = pointed_thing.under
	local node = lib.get_node_lvm(pos)
	if string.sub(node.name, 1, 17) == "signs_bot:changer" then
		return pos, "changer"
	elseif node.name == "signs_bot:bot_sensor" then
		return pos, "sensor"
	end
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

-- Write changer_pos data to sensor_pos
local function pairing(changer_pos, sensor_pos)
	local dest_idx = string.sub(lib.get_node_lvm(changer_pos).name, 18)
	local dest_pos = minetest.pos_to_string(changer_pos)
	local meta = M(sensor_pos)
	meta:set_string("dest_pos", dest_pos)
	meta:set_int("dest_idx", tonumber(dest_idx))
	meta:set_string("infotext", "Bot Sensor: Connected with "..dest_pos.." / "..dest_idx)
end

local function use_tool(itemstack, placer, pointed_thing)
	if pointed_thing.type == "node" then
		local pos1,name1 = get_stored_data(placer)
		local pos2,name2 = get_current_data(pointed_thing)
		
		if name1 == "changer" and name2 == "sensor" then
			pairing(pos1, pos2)
			store_data(placer, nil, nil)
			minetest.sound_play('signs_bot_pong', {to_player = placer:get_player_name()})
		elseif name2 == "changer" and name1 == "sensor" then
			pairing(pos2, pos1)
			store_data(placer, nil, nil)
			minetest.sound_play('signs_bot_pong', {to_player = placer:get_player_name()})
		elseif name2 == "changer" or name2 == "sensor" then
			store_data(placer, pos2, name2)
			minetest.sound_play('signs_bot_ping', {to_player = placer:get_player_name()})
		else
			store_data(placer, nil, nil)
			minetest.sound_play('signs_bot_error', {to_player = placer:get_player_name()})
		end
		return
	end
end
			

minetest.register_node("signs_bot:connector", {
	description = "Sensor Connector Tool",
	inventory_image = "signs_bot_tool.png",
	wield_image = "signs_bot_tool.png",
	groups = {cracky=1, book=1},
	on_use = use_tool,
	on_place = use_tool,
	node_placement_prediction = "",
	stack_max = 1,
})
