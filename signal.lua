--[[

	Signs Bot
	=========

	Copyright (C) 2019 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information
	
	Signal function

]]--

-- for lazy programmers
local S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local P = minetest.string_to_pos
local M = minetest.get_meta

local lib = signs_bot.lib

function signs_bot.get_node_type(pos)
	local node = lib.get_node_lvm(pos)
	if minetest.registered_nodes[node.name] 
	and minetest.registered_nodes[node.name].signs_bot_get_signal then
		return "actuator"
	elseif minetest.get_item_group(node.name, "sign_bot_sensor") == 1 then
		return "sensor"
	end
end

function signs_bot.get_signal(actuator_pos)
	if actuator_pos then
		local node = lib.get_node_lvm(actuator_pos)
		if minetest.registered_nodes[node.name] 
		and minetest.registered_nodes[node.name].signs_bot_get_signal then
			return minetest.registered_nodes[node.name].signs_bot_get_signal(actuator_pos, node)
		end
	end
end
		
function signs_bot.store_signal(sensor_pos, dest_pos, signal)
	local meta = M(sensor_pos)
	meta:set_string("signal_pos", S(dest_pos))
	meta:set_string("signal_data", signal)
end

function signs_bot.send_signal(sensor_pos)
	local meta = M(sensor_pos)
	local dest_pos = meta:get_string("signal_pos")
	local signal = meta:get_string("signal_data")
	if dest_pos ~= "" and signal ~= "" then
		local pos = P(dest_pos)
		local node = lib.get_node_lvm(pos)
		if minetest.registered_nodes[node.name] 
		and minetest.registered_nodes[node.name].signs_bot_on_signal then
			minetest.registered_nodes[node.name].signs_bot_on_signal(pos, node, signal)
		end
	end
end