--[[

	Signs Bot
	=========

	Copyright (C) 2019-2021 Joachim Stolberg

	GPL v3
	See LICENSE.txt for more information

	InGame Documentation for techage or doclib

]]--

local MP = minetest.get_modpath("signs_bot")

if minetest.global_exists("techage") then

	-- Use the Techage Construction Board
	local content = dofile(MP.."/manual_EN.lua")
	doclib.add_to_manual("techage", "EN", content)

elseif minetest.global_exists("doclib") then

	-- Create own manual book
	local settings = {
		symbol_item = "signs_bot_bot_inv.png",
	}

	doclib.create_manual("signs_bot", "EN", settings)
	local content = dofile(MP.."/manual_EN.lua")
	doclib.add_to_manual("signs_bot", "EN", content)

	minetest.register_node("signs_bot:manual", {
		description = "Signs Bot Manual (EN)",
		inventory_image = "doclib_book_inv.png",
		tiles = {
			-- up, down, right, left, back, front
			"doclib_book.png",
			"doclib_book.png",
			"doclib_book.png^[transformR270",
			"doclib_book.png^[transformR90",
			"doclib_book.png^[transformR180",
			"doclib_book.png"
			},
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {
				{ -8/32, -16/32, -12/32, 8/32, -12/32, 12/32},
			},
		},

		after_place_node = function(pos, placer, itemstack)
			minetest.get_meta(pos):set_string("infotext", "Signs Bot Manual (EN)")
			minetest.get_meta(pos):set_string("formspec", doclib.formspec(pos, "signs_bot", "EN"))
		end,

		on_receive_fields = function(pos, formname, fields, player)
			local player_name = player:get_player_name()
			if minetest.is_protected(pos, player_name) then
				return
			end
			minetest.get_meta(pos):set_string("formspec", doclib.formspec(pos, "signs_bot", "EN", fields))
		end,

		paramtype = "light",
		sunlight_propagates = true,
		paramtype2 = "facedir",
		use_texture_alpha = "clip",
		is_ground_content = false,
		groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 2},
	})

end
