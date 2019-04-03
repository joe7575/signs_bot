--[[

	Signs Bot
	=========

	Copyright (C) 2019 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information
	
	Node information tables for the Bot

]]--

signs_bot.FarmingSeed = {}
signs_bot.FarmingCrop = {}
--signs_bot.FarmingTrees = {}
	
---- default trees which require the node timer
--function signs_bot.register_tree_node(name, drop, plant)
--	signs_bot.FarmingTrees[name] = {drop = drop or name, plant = plant, t1= 166, t2 = 288}
--end

--function signs_bot.register_ground_node(name, drop)
--	signs_bot.GroundNodes[name] = {drop = drop or name}
--end

--local tn = signs_bot.register_tree_node
--local dn = signs_bot.register_default_farming_node
--local gn = signs_bot.register_ground_node


-- inv_seed is the seed inventory name
-- seed is what has to be placed on the ground
-- t1/t2 is needed for farming nodes which require the node timer
function signs_bot.register_farming_seed(inv_seed, seed, t1, t2)
	signs_bot.FarmingSeed[inv_seed] = {seed = seed or inv_seed, t1 = 2400, t2 = 4800}
end

-- crop is the farming crop in the final stage
-- inv_crop is the the inventory item name of the crop result
-- inv_seed is the the inventory item name of the seed result
function signs_bot.register_farming_crop(crop, inv_crop, inv_seed)
	signs_bot.FarmingCrop[crop] = {inv_crop = inv_crop or crop, inv_seed = inv_seed or crop}
end

local fs = signs_bot.register_farming_seed
local fc = signs_bot.register_farming_crop

-------------------------------------------------------------------------------
-- Default Farming
-------------------------------------------------------------------------------
--tn("default:tree",        "default:tree",        "default:sapling")
--tn("default:aspen_tree",  "default:aspen_tree",  "default:aspen_sapling")
--tn("default:pine_tree",   "default:pine_tree",   "default:pine_sapling")
--tn("default:acacia_tree", "default:acacia_tree", "default:acacia_sapling")
--tn("default:jungletree",  "default:jungletree",  "default:junglesapling")

--fn("default:leaves")
--fn("default:aspen_leaves")
--fn("default:pine_needles")
--signs_bot.["default:pine_needles"].leaves = true  -- accepted as leaves
--fn("default:acacia_leaves")
--fn("default:jungleleaves")

--fn("default:bush_leaves")
--fn("default:acacia_bush_leaves")

--fn("default:cactus", "default:cactus", "default:cactus")
--fn("default:papyrus", "default:papyrus", "default:papyrus")

--fn("default:apple")

if farming.mod ~= "redo" then
	fs("farming:seed_wheat", "farming:wheat_1")
	fc("farming:wheat_8",  "farming:wheat", "farming:seed_wheat")
	fs("farming:seed_cotton", "farming:cotton_1")
	fc("farming:cotton_8", "farming:cotton", "farming:seed_cotton")
end

-------------------------------------------------------------------------------
-- Farming Redo
-------------------------------------------------------------------------------
--if farming.mod == "redo" then
--	fn("farming:wheat_8",     "farming:wheat",          "farming:wheat_1")
--	fn("farming:cotton_8",    "farming:cotton",         "farming:cotton_1")
--	fn("farming:carrot_8",    "farming:carrot 2",       "farming:carrot_1")
--	fn("farming:potato_4",    "farming:potato 3",       "farming:potato_1")
--	fn("farming:tomato_8",    "farming:tomato 3",       "farming:tomato_1")
--	fn("farming:cucumber_4",  "farming:cucumber 2",     "farming:cucumber_1")
--	fn("farming:corn_8",      "farming:corn 2",         "farming:corn_1")
--	fn("farming:coffee_5",    "farming:coffee_beans 2", "farming:coffee_1")
--	fn("farming:melon_8",     "farming:melon_slice 9",  "farming:melon_1")
--	fn("farming:pumpkin_8",   "farming:pumpkin_slice 9","farming:pumpkin_1")
--	fn("farming:raspberry_4", "farming:raspberries",    "farming:raspberry_1")
--	fn("farming:blueberry_4", "farming:blueberries",    "farming:blueberry_1")
--	fn("farming:rhubarb_3",   "farming:rhubarb 2",      "farming:rhubarb_1")
--	fn("farming:beanpole_5",  "farming:beans 3",        "farming:beanpole_1")
--	fn("farming:grapes_8",    "farming:grapes 3",       "farming:grapes_1")
--	fn("farming:barley_7",    "farming:barley",         "farming:barley_1")
--	fn("farming:chili_8",     "farming:chili_pepper 2", "farming:chili_1")
--	fn("farming:hemp_8",      "farming:hemp_leaf",      "farming:hemp_1")
--	fn("farming:oat_8",       "farming:oat",            "farming:oat_1")
--	fn("farming:rye_8",       "farming:rye",            "farming:rye_1")
--	fn("farming:rice_8",      "farming:rice",           "farming:rice_1")
--end

-------------------------------------------------------------------------------
-- Ethereal Farming
-------------------------------------------------------------------------------
--fn("ethereal:strawberry_8",   "ethereal:strawberry 2",	     "ethereal:strawberry 1")
--fn("ethereal:onion_5",		  "ethereal:wild_onion_plant 2", "ethereal:onion_1")


--fn("ethereal:willow_trunk",   "ethereal:willow_trunk", "ethereal:willow_sapling")
--fn("ethereal:redwood_trunk",  "ethereal:redwood_trunk",  "ethereal:redwood_sapling")
--fn("ethereal:frost_tree",     "ethereal:frost_tree",  "ethereal:frost_tree_sapling")
--fn("ethereal:yellow_trunk",   "ethereal:yellow_trunk",  "ethereal:yellow_tree_sapling")
--fn("ethereal:palm_trunk",     "ethereal:palm_trunk",  "ethereal:palm_sapling")
--fn("ethereal:banana_trunk",   "ethereal:banana_trunk",  "ethereal:banana_tree_sapling")
--fn("ethereal:mushroom_trunk", "ethereal:mushroom_trunk",  "ethereal:mushroom_sapling")
--fn("ethereal:birch_trunk",    "ethereal:birch_trunk",  "ethereal:birch_sapling")
--fn("ethereal:bamboo",         "ethereal:bamboo",       "ethereal:bamboo_sprout")

--fn("ethereal:willow_twig")
--fn("ethereal:redwood_leaves")
--fn("ethereal:orange_leaves")
--fn("ethereal:bananaleaves")
--fn("ethereal:yellowleaves")
--fn("ethereal:palmleaves")
--fn("ethereal:birch_leaves")
--fn("ethereal:frost_leaves")
--fn("ethereal:bamboo_leaves")
--fn("ethereal:mushroom")
--fn("ethereal:mushroom_pore")
--fn("ethereal:bamboo_leaves")
--fn("ethereal:bamboo_leaves")
--fn("ethereal:banana")
--fn("ethereal:orange")
--fn("ethereal:coconut")

