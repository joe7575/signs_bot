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
local tValidSlots = {["1"] = 1, ["2"] = 2, ["3"] = 3, ["4"] = 4}

local HELP = I([[Robot Commands
 
Robot move commands:
    move <steps>
    turn_left
    turn_right
    turn_back
    backward  
    move_up
    move_down
    pause <sec>
    stop  
    turn_off
  
Node inventory related commands:
    take_item <slot>
    add_item <slot>  
  
Item related commands:
    place_item <slot> <pos> <lvl>
    dig_item <slot> <pos> <lvl>
    pick_item <slot>
    drop_item <slot>
	rotate_item <pos> <lvl> <steps>

Signs related commands:
    place_sign <slot>
    dig_sign <slot>
    place_sign_behind <slot>
    trash_sign <slot>  
	
Farming related commands:
    cut_tree
    pick flowers
    harvest_crops
	
--------------------------------------------------
Legend:
<pos>...Positions (in front of the Robot):
    l - left
    r - right
    f - front
    2 - both sides (l+r)
    3 - all 3 pos (l+f+r)
  
<slot>...Robot inventory slot (1..8) or (1..4)
              for signs inventory
  
<lvl>...placement level based on Robot 
            position: -1, 0, +1
			
<steps>..rotation steps of placed nodes (1..3)			
OR:
<steps>..robot movement steps (1..100)
]])

HELP = minetest.formspec_escape(HELP):gsub("\n", ", ")
local lHelp = string.split(HELP, ",")


local function formspec1(meta)
	local cmnd = meta:get_string("signs_bot_cmnd")
	local name = meta:get_string("sign_name")
	cmnd = minetest.formspec_escape(cmnd)
	name = minetest.formspec_escape(name)
	return "size[9,8]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"tabheader[0,0;tab;"..I("Commands,Help")..";1;;true]"..
	"field[0.3,0.5;8,1;name;"..I("Sign name:")..";"..name.."]"..
	"textarea[0.3,1.2;9,7.2;cmnd;;"..cmnd.."]"..
	"button_exit[2.5,7.5;2,1;cancel;"..I("Cancel").."]"..
	"button[4.5,7.5;2,1;save;"..I("Save").."]"
end

local function formspec2()
	return "size[9,8]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"tabheader[0,0;tab;"..I("Commands,Help")..";2;;true]"..
	"table[0.1,0.1;8.6,7.2;help;"..HELP..";1]"..
	"button[3.5,7.5;2,1;copy;"..I("Copy").."]"
end

local function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function append_line(meta, line)
	line = trim(line or "") 
	local text = meta:get_string("signs_bot_cmnd").."\n"..line
	meta:set_string("signs_bot_cmnd", text)
end	
	
minetest.register_node("signs_bot:sign_cmnd", {
	description = I("Robot Command Sign"),
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
		else
			nmeta:set_string("sign_name", I("Sign commands"))
			nmeta:set_string("signs_bot_cmnd", I("-- enter or copy commands from help page"))
		end
		nmeta:set_string("formspec", formspec1(nmeta))
	end,
	
	on_receive_fields = function(pos, formname, fields, player)
		local meta = minetest.get_meta(pos)
		if fields.save then
			meta:set_string("signs_bot_cmnd", fields.cmnd)
			meta:set_string("sign_name", fields.name)
			meta:set_string("formspec", formspec1(meta))
		elseif fields.key_enter_field then
			meta:set_string("signs_bot_cmnd", fields.cmnd)
			meta:set_string("sign_name", fields.name)
			meta:set_string("formspec", formspec1(meta))
		elseif fields.copy then
			append_line(meta, lHelp[meta:get_int("help_pos")])
		elseif fields.tab == "1" then
			meta:set_string("formspec", formspec1(meta))
		elseif fields.tab == "2" then
			meta:set_string("signs_bot_cmnd", fields.cmnd)
			meta:set_string("sign_name", fields.name)
			meta:set_string("formspec", formspec2(meta))
		elseif fields.help then
			local evt = minetest.explode_table_event(fields.help)
			print(dump(evt))
			if evt.type == "DCL" then
				append_line(meta, lHelp[tonumber(evt.row)])
			elseif evt.type == "CHG" then
				meta:set_int("help_pos", tonumber(evt.row))
			end
		end
	end,
	
	on_dig = function(pos, node, digger)
		if not minetest.is_protected(pos, digger:get_player_name()) then
			local nmeta = minetest.get_meta(pos)
			local cmnd = nmeta:get_string("signs_bot_cmnd")
			local name = nmeta:get_string("sign_name")
			local sign = ItemStack("signs_bot:sign_cmnd")
			local smeta = sign:get_meta()
			smeta:set_string("cmnd", cmnd)
			smeta:set_string("description", name)
			minetest.remove_node(pos)
			local inv = minetest.get_inventory({type="player", name=digger:get_player_name()})
			inv:add_item("main", sign)
		end
	end,
	
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	drop = "",
	groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 2, wood = 1},
	sounds = default.node_sound_wood_defaults(),
})


-- Get one sign from the robot inventory
local function get_inv_sign(base_pos, slot)
	local inv = minetest.get_inventory({type="node", pos=base_pos})
	local stack = inv:get_stack("sign", slot or 1)
	local taken = stack:take_item(1)
	if taken:get_count() == 1 then
		inv:set_stack("sign", slot, stack)
		return taken
	end
end
			
-- Put one sign into the robot inventory
local function put_inv_sign(base_pos, slot, item)
	local inv = minetest.get_inventory({type="node", pos=base_pos})
	local stack = inv:get_stack("sign", slot)
	local leftovers = stack:add_item(item)
	if leftovers:get_count() == 0 then
		inv:set_stack("sign", slot, stack)
		return true
	end
	return false
end

-- Put one sign into the robot inventory
local function put_inv_main(base_pos, slot, item)
	local inv = minetest.get_inventory({type="node", pos=base_pos})
	local stack = inv:get_stack("main", slot)
	local leftovers = stack:add_item(item)
	if leftovers:get_count() == 0 then
		inv:set_stack("main", slot, stack)
		return true
	end
	return false
end

function signs_bot.place_sign(base_pos, robot_pos, param2, slot)
	local owner = M(base_pos):get_string("owner")
	slot = tValidSlots[slot]
	local pos1 = lib.work_pos(robot_pos, param2, "f")
	if not minetest.is_protected(pos1, owner) and lib.is_air_like(pos1) then
		local sign = get_inv_sign(base_pos, slot)
		if sign then
			local meta = sign:get_meta()
			local cmnd = meta:get_string("cmnd")
			local name = meta:get_string("description")
			minetest.set_node(pos1, {name=sign:get_name(), param2=param2})
			local under = {x=pos1.x, y=pos1.y-1, z=pos1.z}
			local pointed_thing = {type="node", under=under, above=pos1}
			minetest.registered_nodes[sign:get_name()].after_place_node(pos1, nil, sign, pointed_thing)
			--pcall(minetest.after_place_node, pos1, nil, sign, pointed_thing)
			M(pos1):set_string("signs_bot_cmnd", cmnd)
			M(pos1):set_string("sign_name", name)
		end
	end
end

function signs_bot.dig_sign(base_pos, robot_pos, param2, slot)
	local owner = M(base_pos):get_string("owner")
	slot = tValidSlots[slot]
	local pos1 = lib.work_pos(robot_pos, param2, "f")
	local cmnd = M(pos1):get_string("signs_bot_cmnd")
	local name = M(pos1):get_string("sign_name")
	if slot and not minetest.is_protected(pos1, owner) and cmnd ~= "" then
		local node = lib.get_node_lvm(pos1)
		local sign = ItemStack(node.name)
		local meta = sign:get_meta()
		meta:set_string("description", name)
		meta:set_string("cmnd", cmnd)
		minetest.remove_node(pos1)
		return put_inv_sign(base_pos, slot, sign)
	end
end

function signs_bot.trash_sign(base_pos, robot_pos, param2, slot)
	local owner = M(base_pos):get_string("owner")
	slot = tValidSlots[slot]
	local pos1 = lib.work_pos(robot_pos, param2, "f")
	local cmnd = M(pos1):get_string("signs_bot_cmnd")
	if slot and not minetest.is_protected(pos1, owner) and cmnd ~= "" then
		local node = lib.get_node_lvm(pos1)
		local sign = ItemStack("signs_bot:sign_cmnd")
		minetest.remove_node(pos1)
		return put_inv_main(base_pos, slot, sign)
	end
end
