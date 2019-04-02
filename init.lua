--[[

	Signs Bot
	=========

	Copyright (C) 2019 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information
	
	A robot controlled by signs

]]--

signs_bot = {}

local MP = minetest.get_modpath("signs_bot")
dofile(MP.."/intllib.lua")
dofile(MP.."/lib.lua")
dofile(MP.."/robot.lua")
dofile(MP.."/signs.lua")
dofile(MP.."/move_func.lua")
dofile(MP.."/item_func.lua")
dofile(MP.."/sign_func.lua")
dofile(MP.."/commands.lua")
dofile(MP.."/basis.lua")
dofile(MP.."/duplicator.lua")
dofile(MP.."/signal.lua")
dofile(MP.."/changer.lua")
dofile(MP.."/tool.lua")
dofile(MP.."/bot_flap.lua")
dofile(MP.."/more_cmnds.lua")
dofile(MP.."/nodes.lua")
dofile(MP.."/bot_sensor.lua")
dofile(MP.."/node_sensor.lua")
dofile(MP.."/crop_sensor.lua")
