--[[

	Signs Bot
	=========

	Copyright (C) 2019 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information
	
	Signs Bot: Signs related functions

]]--

-- for lazy programmers
local S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local P = minetest.string_to_pos
local M = minetest.get_meta

-- Load support for intllib.
local MP = minetest.get_modpath("signs_bot")
local I,_ = dofile(MP.."/intllib.lua")

local lib = signs_bot.lib

local HELP = I([[Robot Commands
 
The robot can place and dig items on
levels. <lvl> is one of:
    -1 - one level below the robot height
     0 - robot y-position
    +1 - one level above the robot height

Supported commands:

]])

local lHelp = {}
local sHelp = ""
local function gen_help_text()
	local text = HELP..signs_bot.get_help_text()
	text = minetest.formspec_escape(text)
	sHelp = text:gsub("\n", ", ")
	lHelp = string.split(sHelp, ",")
end
minetest.after(2, gen_help_text)


local function formspec1(meta)
	local cmnd = meta:get_string("signs_bot_cmnd")
	local name = meta:get_string("sign_name")
	local err_msg = meta:get_string("err_msg")
	cmnd = minetest.formspec_escape(cmnd)
	name = minetest.formspec_escape(name)
	return "size[9,8]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"tabheader[0,0;tab;"..I("Commands,Help")..";1;;true]"..
	"field[0.3,0.5;9,1;name;"..I("Sign name:")..";"..name.."]"..
	"textarea[0.3,1.2;9,7.2;cmnd;;"..cmnd.."]"..
	"label[0.3,7.5;"..err_msg.."]"..
	"button_exit[5,7.5;2,1;cancel;"..I("Cancel").."]"..
	"button[7,7.5;2,1;check;"..I("Check").."]"
end

local function formspec2()
	return "size[9,8]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"tabheader[0,0;tab;"..I("Commands,Help")..";2;;true]"..
	"table[0.1,0.1;8.6,7.2;help;"..sHelp..";1]"..
	"button[3.5,7.5;2,1;copy;"..I("Copy").."]"
end

local function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function trim_text(text)
	local tbl = {}
	for idx,line in ipairs(string.split(text, "\n", true)) do
		tbl[#tbl+1]	= trim(line)
	end
	return table.concat(tbl, "\n")
end

local function append_line(pos, meta, line)
	line = trim(line or "") 
	local text = meta:get_string("signs_bot_cmnd").."\n"..line
	meta:set_string("signs_bot_cmnd", text)
	local res,err_msg = signs_bot.check_commands(pos, text)
	meta:set_int("err_code", res and 0 or 1) -- zero means OK
	meta:set_string("err_msg", err_msg)
end	
	
local function check_and_store(pos, meta, fields)	
	meta:set_string("signs_bot_cmnd", trim_text(fields.cmnd))
	meta:set_string("sign_name", fields.name)
	local res,err_msg = signs_bot.check_commands(pos, fields.cmnd)
	meta:set_int("err_code", res and 0 or 1) -- zero means OK
	meta:set_string("err_msg", err_msg)
	meta:set_string("formspec", formspec1(meta))
end

minetest.register_node("signs_bot:sign_cmnd", {
	description = I('Sign "command"'),
	drawtype = "nodebox",
	inventory_image = "signs_bot_sign_cmnd.png",
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
		"default_wood.png^signs_bot_sign_cmnd.png",
	},
	after_place_node = function(pos, placer, itemstack)
		local imeta = itemstack:get_meta()
		local nmeta = minetest.get_meta(pos)
		if imeta:get_string("description") ~= ""  then
			nmeta:set_string("signs_bot_cmnd", imeta:get_string("cmnd"))
			nmeta:set_string("sign_name", imeta:get_string("description"))
			nmeta:set_string("err_msg", imeta:get_string("err_msg"))
			nmeta:set_int("err_code", imeta:get_int("err_code"))
		else
			nmeta:set_string("sign_name", I('Sign "command"'))
			nmeta:set_string("signs_bot_cmnd", I("-- enter or copy commands from help page"))
			nmeta:set_int("err_code", 0)
		end
		nmeta:set_string("formspec", formspec1(nmeta))
	end,
	
	on_receive_fields = function(pos, formname, fields, player)
		if minetest.is_protected(pos, player:get_player_name()) then
			return
		end
		local meta = minetest.get_meta(pos)
		if fields.check then
			check_and_store(pos, meta, fields)
		elseif fields.key_enter_field then
			check_and_store(pos, meta, fields)
		elseif fields.copy then
			append_line(pos, meta, lHelp[meta:get_int("help_pos")])
		elseif fields.tab == "1" then
			meta:set_string("formspec", formspec1(meta))
		elseif fields.tab == "2" then
			check_and_store(pos, meta, fields)
			meta:set_string("formspec", formspec2(meta))
		elseif fields.help then
			local evt = minetest.explode_table_event(fields.help)
			if evt.type == "DCL" then
				append_line(pos, meta, lHelp[tonumber(evt.row)])
			elseif evt.type == "CHG" then
				meta:set_int("help_pos", tonumber(evt.row))
			end
		end
	end,
	
	on_dig = function(pos, node, digger)
		if not minetest.is_protected(pos, digger:get_player_name()) then
			local sign = lib.dig_sign(pos, node)
			if sign then
				local inv = minetest.get_inventory({type="player", name=digger:get_player_name()})
				inv:add_item("main", sign)
			end
		end
	end,
	
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	drop = "",
	groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 2, sign_bot_sign = 1},
	sounds = default.node_sound_wood_defaults(),
})


-- Get one sign from the robot signs inventory
local function get_inv_sign(base_pos, slot)
	local inv = minetest.get_inventory({type="node", pos=base_pos})
	local stack = inv:get_stack("sign", slot)
	local taken = stack:take_item(1)
	if taken:get_count() == 1 then
		inv:set_stack("sign", slot, stack)
		return taken
	end
	signs_bot.output(base_pos, I("Error: Signs inventory slot is empty"))
end
			
-- Put one sign into the robot signs inventory
local function put_inv_sign(base_pos, slot, item)
	local inv = minetest.get_inventory({type="node", pos=base_pos})
	local stack = inv:get_stack("sign", slot)
	local leftovers = stack:add_item(item)
	if leftovers:get_count() == 0 then
		inv:set_stack("sign", slot, stack)
		return true
	end
	signs_bot.output(base_pos, I("Error: Signs inventory slot is full"))
	return false
end

function signs_bot.place_sign(base_pos, robot_pos, param2, slot)
	local pos1 = lib.dest_pos(robot_pos, param2, {0})
	if lib.not_protected(base_pos, pos1) then
		if lib.is_air_like(pos1) then
			local sign = get_inv_sign(base_pos, slot)
			if sign then
				lib.place_sign(pos1, sign, param2)
				return true
			else
				signs_bot.output(base_pos, I("Error: Signs inventory empty"))
				return false
			end
		end
	end
	return false
end

function signs_bot.place_sign_behind(base_pos, robot_pos, param2, slot)
	local pos1 = lib.dest_pos(robot_pos, param2, {2})
	if lib.not_protected(base_pos, pos1) then
		if lib.is_air_like(pos1) then
			local sign = get_inv_sign(base_pos, slot)
			if sign then
				lib.place_sign(pos1, sign, param2)
				return true
			else
				signs_bot.output(base_pos, I("Error: Signs inventory empty"))
				return false
			end
		end
	end
	return false
end

function signs_bot.dig_sign(base_pos, robot_pos, param2, slot)
	local pos1 = lib.dest_pos(robot_pos, param2, {0})
	local meta =  M(pos1)
	local cmnd = meta:get_string("signs_bot_cmnd")
	local err_code = meta:get_int("err_code")
	local name = meta:get_string("sign_name")
	if cmnd == "" then
		signs_bot.output(base_pos, I("Error: No sign available"))
		return false
	end
	if lib.not_protected(base_pos, pos1) then
		local node = lib.get_node_lvm(pos1)
		local sign = ItemStack(node.name)
		local meta = sign:get_meta()
		meta:set_string("description", name)
		meta:set_string("cmnd", cmnd)
		meta:set_int("err_code", err_code)
		minetest.remove_node(pos1)
		return put_inv_sign(base_pos, slot, sign)
	end
	return false
end

function signs_bot.trash_sign(base_pos, robot_pos, param2, slot)
	local pos1 = lib.dest_pos(robot_pos, param2, {0})
	local cmnd = M(pos1):get_string("signs_bot_cmnd")
	if cmnd == "" then
		signs_bot.output(base_pos, I("Error: No sign available"))
		return false
	end
	if lib.not_protected(base_pos, pos1) then
		local node = lib.get_node_lvm(pos1)
		local sign = ItemStack("signs_bot:sign_cmnd")
		minetest.remove_node(pos1)
		return lib.put_inv_items(base_pos, slot, sign)
	end
	return false
end


minetest.register_craft({
	output = "signs_bot:sign_cmnd 4",
	recipe = {
		{"group:wood", "default:stick", "group:wood"},
		{"dye:yellow", "default:stick", "dye:yellow"},
		{"", "", ""}
	}
})
