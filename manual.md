Signs Bot [signs_bot] User Manual
=================================

After you have placed the Signs Bot Box, you can start the bot by means of the "On" button in the box menu.
The bot then runs straight up until it reaches an obstacle (a step with two or more blocks up or down)
or a sign. If the bot first reaches a sign it will execute the commands on the sign.
If the command(s) on the sign is e.g. "turn_around", the bot turns and goes back.
In this case, the bot reaches his box again and turns off.

The Signs Bot Box has an inventory with 6 stacks for signs and 8 stacks for other items (to be placed/dug by the bot).
This inventory simulates the bot internal inventory. That means you will only have access to the inventory if the
bot is turned off ('sitting' in his box).

Control the bot by means of signs
---------------------------------

You simply can control the direction of the bot by means of the "turn left" and "turn right" signs (signs with the arrow).
The bot can run over steps (one block up/down). But there are also commands to move the bot up and down.
It is not necessary to mark a way back to the box. With the command "turn_off" the bot will turn off and be back in his box
from every position. The same applies if you turn off the bot by the box menu.
If the bot reaches a sign from the wrong direction (from back or sides) the sign will be ignored. The bot will walk over.

All predefined signs have a menu with a list of the bot commands. These signs can't be changed, but you can craft and program your own signs. For this you have to use the "command" sign. This sign has an edit field for your commands and a help page with all available
commands. The help page has a copy button to simplify the programming.

Also for your own signs it is important to know: After the execution of the last command of the sign, the bot falls back into its default behaviour and runs in its taken direction.

A standard job for the bot is to move items from one chest to another (chest or node with a chest like inventory).
This can be done by means of the two signs "take item" and "add item". These signs have to be placed on top of the chest node.

With 3 of the 4 featured signs, you can implement your first bot job. 

![Example1](https://github.com/joe7575/signs_bot/blob/master/doc/example01.png)

When started, the bot will run to the "turn right" sign and will go on to the first chest. Than the bot will execute the commands from the "take item" sign:

    take_item 99
    turn_around
    
The bot will take a stack from the chest, make a turn and run to the second chest on the left. Here the bot will execute the commands:

    add_item 99
    turn_around

This will lead the bot back to the first chest and so on. 

Control the bot by means of additional sensors
----------------------------------------------

In addition to the signs the bot can be controlled by means of sensors. Sensors like the Bot Sensor have two states: on/off.
If the Bot Sensor detects a bot it will switch to the state "on" and sends a signal to a connected block, called an actuator.

The following sensors are available:
- Bot Sensor: Sends a signal when the robot passes by (range is one block)
- Node Sensor: Sends a signal when it detects a change (tree, cactus, flower, etc.) in front of the sensor (range is 3 blocks)
- Crop Sensor: Sends a signal when, for example, the wheat is fully grown (range is one block)
- Bot Chest: Sends a signal depending on the chest state. Possible states are "empty", "not empty", "almost full".

Actuators are:
- Signs Bot Box: Can turn the bot off and on
- Control Unit: Can be used to exchange the sign in front of the Control Unit and therefore, steer the bot eg. in different direction

To send a signal from a sensor to an actuator, the sensor has to be connected (paired) with actuator. The Connection Tool is used to perform the pairing. Simply click on both blocks one after the other and the sensor is connected with the actuator.
A successful pairing is indicated by a ping / pong noise.

I will explain that with the next example, automated farming:

![Example2](https://github.com/joe7575/signs_bot/blob/master/doc/example02.png)

to be finished...