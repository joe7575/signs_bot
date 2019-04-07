Signs Bot [signs_bot]
=====================

## THIS IS WORK IN PROGRESS!

**A robot controlled by signs.**

Browse on: ![GitHub](https://github.com/joe7575/signs_bot)

Download: ![GitHub](https://github.com/joe7575/signs_bot/archive/master.zip)

![Signs Bot](https://github.com/joe7575/signs_bot/blob/master/screenshot.png)


The bot can only be controlled by signs that are placed in its path.
The bot starts running after starting until it encounters a sign. There, the commands are then processed on the sign.
The bot can also put himself signs in the way, which he then works off.
There is also a sign that can be programmed by the player, which then are processed by the bot.

There are also the following blocks:
- Sensors: These can send a signal to an actuator if they are connected to the actuator.
- Actuators: These perform an action when they receive a signal from a sensor.

Sensors must be connected (paired) with actuators. This is what the Connection Tool does. Click on both blocks one after the other.
A successful pairing is indicated by a ping / pong noise.
When pairing, the state of the actuator is important. In the case of the bot box, for example, the states "on" and "off", in the case of the control unit 1,2,3,4, etc.
The state of the actuator is saved with the pairing and restored by the signal. For example, the robot can be switched on via a node sensor.

An actuator can receive signals from many sensors. A sensor can only be connected to an actuator. However, if several actuators are to be controlled by one sensor, a signal extender block must be used. This connects to a sensor when it is placed next to the sensor. This extender can then be paired with another actuator.

Sensors are:
- Bot Sensor: sends a signal when the robot passes by
- Node Sensor: sends a signal when it detects a block (tree, cactus, flower, etc.)
- Crop Sendor: Sends a signal when, for example, the wheat is fully grown

Actuators are:
- Control Unit: Can place up to 4 signs and steer the bot e.g. in different directions.
- Signs Bot Box: Can be turned off and on

In addition, there are currently the following blocks:
- The duplicator is used to copy Command Signs, i.e. the signs with their own commands.
- Bot Flap: The "cat flap" is a door for the bot, which he opens automatically and closes behind him.
- Sensor Extender for controlling additional actuators from one sensor signal

More information:
- Using the signs "take" and "add", the bot can pick items from Chests and put them in. The signs must be placed on the box. So far, only a few blocks are supported with Inventory.
- The Control Unit can be charged with up to 4 labels. To do this, place a label next to the Control Unit and click on the Control Unit. The sign is only stored under this number.
- The inventory of the Signs Bot Box is intended to represent the inventory of the Robot. As long as the robot is on the road, of course you have no access.

The copy function can be used to clone node cubes up to 5x3x3 nodes. There is the pattern shield for the template position and the copy shield for the "3x3x3" copy. Since the bot also copies air blocks, the function can also be used for mining or tunnels. The items to be placed must be in the inventory. Items that the bot degrades are in Inventory afterwards. If there are missing items in the inventory during copying, he will set "missing items" blocks, which dissolve into air when degrading.

Commands:
The commands are also all described as help in the "Sign command" node.
All blocks or signs that are set are taken from the bot inventory.
Any blocks or signs removed will be added back to the Bot Inventory.
For all Inventory commands applies: If the inventory stack specified by <slot> is full, so that nothing more can be done, or just empty, so that nothing more can be removed, the next slot will automatically be used.

    move <steps>              - to follow one or more steps forward without signs
    cond_move                 - walk to the next sign and work it off
    turn_left                 - turn left
    turn_right                - turn right
    turn_around               - turn around
    backward                  - one step backward
    turn_off                  - Turn off the robot / back to the box
    pause <sec>               - wait one or more seconds
    move_up                   - move up (maximum 2 times)
    move_down                 - Move down
    take_item <num> <slot>    - take one or more items from a box
    add_item <num> <slot>     - put one or more items in a box
    add_fuel <num> <slot>     - for furnaces or similar
    place_front <slot> <lvl>  - Set block in front of the robot
    place_left <slot> <lvl>   - Set block to the left
    place_right <slot> <lvl>  - set block to the right
    dig_front <slot> <lvl>    - remove block in front of the robot
    dig_left <slot> <lvl>     - remove block on the left
    dig_right <slot> <lvl>    - remove block on the right
    place_sign <slot>         - set sign
    place_sign_behind <slot>  - Put a sign behind the bot
    dig_sign <slot>           - remove the sign
    trash_sign <slot>         - Remove the sign, clear data and add to the item Inventory
    stop                      - Bot stops until the shield is removed
    pickup_items <slot>       - pickup items (in a 3x3 field)
    drop_items <slot>         - drop items
    harvest                   - harvest a 3x3 field (farming)
    plant_seed                - a 3x3 field sowing / planting
    pattern                   - Save the blocks behind the shield (up to 5x3x3) as template
    copy <size>               - Make a copy of "pattern". Size is e.g. 3x3 (see ingame help)


### License
Copyright (C) 2019 Joachim Stolberg  
Code: Licensed under the GNU LGPL version 2.1 or later. See LICENSE.txt  


### Dependencies 
default, farming, basic_materials, tubelib2
optional: farming redo


### History
- 2019-03-23  v0.01  * first draft
- 2019-04-06  v0.02  * completely reworked

