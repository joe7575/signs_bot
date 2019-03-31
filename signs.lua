--[[

	Signs Bot
	=========

	Copyright (C) 2019 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information
	
	Signs Bot: Signs

]]--

-- for lazy programmers
local S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local P = minetest.string_to_pos
local M = minetest.get_meta

-- Load support for intllib.
local MP = minetest.get_modpath("signs_bot")
local I,_ = dofile(MP.."/intllib.lua")

local function formspec(cmnd)
	cmnd = minetest.formspec_escape(cmnd)
	return "size[6,5]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"label[0.3,0.3;"..cmnd.."]"..
	"button_exit[2.5,5.5;2,1;exit;"..I("Exit").."]"
end

local function register_sign(def)
	minetest.register_node("signs_bot:"..def.name, {
		description = def.description,
		inventory_image = def.image,
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {
				{ -1/16, -8/16, -1/16,   1/16, 4/16, 1/16},
				{ -6/16, -5/16, -2/16,   6/16, 3/16, -1/16},
			},
		},
		paramtype2 = "facedir",
		tiles = {
			"default_wood.png",
			"default_wood.png",
			"default_wood.png",
			"default_wood.png",
			"default_wood.png",
			"default_wood.png^"..def.image,
		},
		after_place_node = function(pos, placer)
			local meta = minetest.get_meta(pos)
			meta:set_string("signs_bot_cmnd", def.commands)
			meta:set_string("formspec", formspec(def.commands))
		end,
		on_rotate = screwdriver.disallow,
		paramtype = "light",
		sunlight_propagates = true,
		is_ground_content = false,
		groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 2, sign_bot_sign = 1},
		sounds = default.node_sound_wood_defaults(),
	})
end

register_sign({
	name = "sign_right", 
	description = I('Sign "turn right"'), 
	commands = "turn_right", 
	image = "signs_bot_sign_right.png",
})

minetest.register_craft({
	output = "signs_bot:sign_right 6",
	recipe = {
		{"group:wood", "default:stick", "group:wood"},
		{"dye:yellow", "default:stick", "dye:black"},
		{"", "", ""}
	}
})

register_sign({
	name = "sign_left", 
	description = I('Sign "turn left"'), 
	commands = "turn_left", 
	image = "signs_bot_sign_left.png",
})

minetest.register_craft({
	output = "signs_bot:sign_left 6",
	recipe = {
		{"group:wood", "default:stick", "group:wood"},
		{"dye:yellow", "default:stick", ""},
		{"dye:black", "", ""}
	}
})

register_sign({
	name = "sign_take", 
	description = I('Sign "take item"'), 
	commands = "take_item 99\nturn_around", 
	image = "signs_bot_sign_take.png",
})

minetest.register_craft({
	output = "signs_bot:sign_take 6",
	recipe = {
		{"group:wood", "default:stick", "group:wood"},
		{"dye:yellow", "default:stick", ""},
		{"", "dye:black", ""}
	}
})

register_sign({
	name = "sign_add", 
	description = I('Sign "add item"'), 
	commands = "add_item 99\nturn_around", 
	image = "signs_bot_sign_add.png",
})

minetest.register_craft({
	output = "signs_bot:sign_add 6",
	recipe = {
		{"group:wood", "default:stick", "group:wood"},
		{"dye:yellow", "default:stick", ""},
		{"", "", "dye:black"}
	}
})

register_sign({
	name = "sign_stop", 
	description = I('Sign "stop"'), 
	commands = "stop", 
	image = "signs_bot_sign_stop.png",
})

minetest.register_craft({
	output = "signs_bot:sign_stop 6",
	recipe = {
		{"group:wood", "default:stick", "group:wood"},
		{"dye:black", "default:stick", "dye:yellow"},
		{"", "", ""}
	}
})
