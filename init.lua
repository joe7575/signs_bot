--[[

	Signs Bot
	=========

	Copyright (C) 2019-2023 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information

	A robot controlled by signs

]]--

signs_bot = {}

-- Version for compatibility checks, see readme.md/history
signs_bot.version = 1.13

-- Test for MT 5.4 new string mode
signs_bot.CLIP = minetest.features.use_texture_alpha_string_modes and "clip" or true

if minetest.global_exists("techage") and techage.version < 1.0 then
	error("[signs_bot] Signs Bot requires techage version 1.0 or newer!")
end

if tubelib2.version < 1.9 then
	error("[signs_bot] Signs Bot requires tubelib2 version 1.9 or newer!")
end

if minetest.global_exists("minecart") and minecart.version < 2.0 then
	error("[signs_bot] Signs Bot requires minecart version 2.0 or newer!")
end

-- Load support for I18n.
signs_bot.S = minetest.get_translator("signs_bot")

local MP = minetest.get_modpath("signs_bot")

dofile(MP.."/doc.lua")
dofile(MP.."/random.lua")
dofile(MP.."/lib.lua")
dofile(MP.."/basis.lua")
dofile(MP.."/robot.lua")
dofile(MP.."/signs.lua")

dofile(MP.."/commands.lua")
dofile(MP.."/cmd_move.lua")
dofile(MP.."/cmd_item.lua")
dofile(MP.."/cmd_place.lua")
dofile(MP.."/cmd_sign.lua")
dofile(MP.."/cmd_pattern.lua")
dofile(MP.."/cmd_farming.lua")
dofile(MP.."/cmd_flowers.lua")
dofile(MP.."/cmd_soup.lua")
dofile(MP.."/cmd_trees.lua")

dofile(MP.."/signal.lua")
dofile(MP.."/extender.lua")
dofile(MP.."/changer.lua")
dofile(MP.."/bot_flap.lua")

dofile(MP.."/duplicator.lua")
dofile(MP.."/nodes.lua")
dofile(MP.."/bot_sensor.lua")
dofile(MP.."/node_sensor.lua")
dofile(MP.."/crop_sensor.lua")
if minetest.global_exists("minecart") then
	dofile(MP.."/cart_sensor.lua")
end
dofile(MP.."/chest.lua")
dofile(MP.."/legacy.lua")
dofile(MP.."/techage.lua")
dofile(MP.."/timer.lua")
dofile(MP.."/delayer.lua")
dofile(MP.."/logic_and.lua")
dofile(MP.."/compost.lua")

dofile(MP.."/tool.lua")

if minetest.global_exists("techage") then
	dofile(MP.."/techage_EN.lua")
	techage.add_manual_items({signs_bot_bot_inv = "signs_bot_bot_inv.png"})
	techage.add_manual_items({signs_bot_sign_left = "signs_bot_sign_left.png"})
	techage.add_manual_items({signs_bot_sensor_crop_inv = "signs_bot_sensor_crop_inv.png"})
	techage.add_manual_items({signs_bot_tool = "signs_bot_tool.png"})
	techage.add_manual_items({signs_bot_box = "signs_bot:box"})
	techage.add_manual_items({signs_bot_bot_flap = "signs_bot:bot_flap"})
	techage.add_manual_items({signs_bot_duplicator = "signs_bot:duplicator"})
	techage.add_manual_items({signs_bot_bot_sensor = "signs_bot:bot_sensor"})
	techage.add_manual_items({signs_bot_node_sensor = "signs_bot:node_sensor"})
	techage.add_manual_items({signs_bot_crop_sensor = "signs_bot:crop_sensor"})
	techage.add_manual_items({signs_bot_chest = "signs_bot:chest"})
	techage.add_manual_items({signs_bot_timer = "signs_bot:timer"})
	techage.add_manual_items({signs_bot_sensor_extender = "signs_bot:sensor_extender"})
	techage.add_manual_items({signs_bot_changer = "signs_bot:changer1"})
	techage.add_manual_items({signs_bot_sensor_extender = "signs_bot:sensor_extender"})
	techage.add_manual_items({signs_bot_and1 = "signs_bot:and1"})
	techage.add_manual_items({signs_bot_delayer = "signs_bot:delayer"})
	techage.add_manual_items({signs_bot_farming = "signs_bot:farming"})
	techage.add_manual_items({signs_bot_pattern = "signs_bot:pattern"})
	techage.add_manual_items({signs_bot_copy = "signs_bot:copy3x3x3"})
	techage.add_manual_items({signs_bot_flowers = "signs_bot:flowers"})
	techage.add_manual_items({signs_bot_aspen = "signs_bot:aspen"})
	techage.add_manual_items({signs_bot_sign_cmnd = "signs_bot:sign_cmnd"})
	techage.add_manual_items({signs_bot_sign_right = "signs_bot:sign_right"})
	techage.add_manual_items({signs_bot_sign_left = "signs_bot:sign_left"})
	techage.add_manual_items({signs_bot_sign_take = "signs_bot:sign_take"})
	techage.add_manual_items({signs_bot_sign_add = "signs_bot:sign_add"})
	techage.add_manual_items({signs_bot_sign_stop = "signs_bot:sign_stop"})
	techage.add_manual_items({signs_bot_sign_add_cart = "signs_bot:sign_add_cart"})
	techage.add_manual_items({signs_bot_sign_take_cart = "signs_bot:sign_take_cart"})
	techage.add_manual_items({signs_bot_water = "signs_bot:water"})
	techage.add_manual_items({signs_bot_soup = "signs_bot:soup"})
end
