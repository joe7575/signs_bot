# Signs Bot – Mod Overview

**Version:** 1.16 | **License:** GPL v3 | **Author:** Joachim Stolberg  
**Dependencies:** default, farming, basic_materials, tubelib2  
**Optional:** techage, minecart, node_io, xdecor, compost, doclib

---

## What is Signs Bot?

A programmable robot for Luanti (Minetest), controlled by **signs**.  
The bot leaves its box, walks straight ahead and executes commands when it
reaches a sign. Without techage it needs no power; with techage it must be charged.

---

## Physical System

### Bot Box
- Starts/stops the bot via button or sensor signal
- Inventory: 8 item stacks + 6 sign stacks
- Inventory is only accessible when the bot is inside the box

### Movement
- Walks forward, detects signs and obstacles
- Climbs steps (1 block up/down)
- Can pass through **Bot Flaps** (automatic trapdoor-style doors)

### Signs (predefined)
| Sign | Function |
|---|---|
| Turn left / Turn right | Bot turns |
| Take item / Add item | Take/place items from/into chest |
| Stop | Bot waits until sign is removed |
| Farming | Harvest & sow a 3×3 field |
| Flowers | Cut a 3×3 flower field |
| Pattern / Copy 3×3×3 | Copy a 3×3×3 cube |
| Aspen/Pine | Harvest tree trunk |
| Add/Take to/from cart | Load/unload minecart |
| Take water | Fill bucket with water (xdecor) |
| Cook soup | Cook soup in cauldron (xdecor) |
| **Command** | **Freely programmable sign** |

---

## Sensors & Actuators

### Sensors
| Sensor | Trigger |
|---|---|
| Bot Sensor | Bot is nearby |
| Node Sensor | Node appears / disappears (3-block range) |
| Crop Sensor | Plant is fully grown |
| Bot Chest | Chest empty / not empty / almost full |
| Bot Timer | Time-triggered (configurable seconds) |

### Actuators
| Actuator | Function |
|---|---|
| Signs Bot Box | Switch bot on/off |
| Bot Control Unit | Switch active sign (up to 4 signs) |

### Auxiliary blocks
- **Sensor Connection Tool** – connects sensor to actuator (ping/pong sound as confirmation)
- **Sensor Extender** – forward one sensor signal to multiple actuators
- **Signal AND** – sends only when *all* input signals are present
- **Signal Delayer** – delays signal forwarding by a configurable time
- **Signs Duplicator** – copy signs (books can also serve as templates)

---

## Programming (Command Sign)

The **Command sign** (`signs_bot:sign_cmnd`) is the central programming tool.  
The bot executes the sign's commands one by one. After the last command it
continues walking in its current direction.

### Syntax rules
- Comments with `--`
- One command per line
- Parameters separated by spaces
- `<slot>` = bot inventory slot 1–8
- `<lvl>` = vertical offset of the target block (always in the direction of the command):
  - `-1` = one level lower than the bot (e.g. floor in front)
  - `0` = same height as the bot (e.g. wall in front)
  - `+1` = one level higher than the bot (e.g. above head height in front)

---

### Movement commands

```
move <steps>        -- walk N steps forward
cond_move           -- walk forward until obstacle or sign
backward            -- one step back
turn_left           -- turn left
turn_right          -- turn right
turn_around         -- turn around
move_up             -- move up (max. 2×)
move_down           -- move down
fall_down           -- fall into a pit (up to 10 blocks)
pause <sec>         -- wait N seconds
turn_off            -- switch bot off (returns to box)
stop                -- halt bot until sign is removed
```

---

### Item Handling

```
take_item <num> <slot>    -- take items from chest/node
add_item  <num> <slot>    -- put items into chest/node
add_fuel  <num> <slot>    -- add fuel to furnace
pickup_items <slot>       -- pick up items in 3×3 area
drop_items <num> <slot>   -- drop items
```

**Slot logic:**
- Slot 0 or no slot → all 8 slots are checked in order
- Pre-configured slots are preferred when filling
- Items that don't fit are returned or dropped

---

### Block Manipulation

```
place_front <slot> <lvl>    -- place block in front of bot
place_left  <slot> <lvl>    -- place block to the left
place_right <slot> <lvl>    -- place block to the right
place_below <slot>          -- place block below the bot
place_above <slot>          -- place block above the bot
dig_front   <slot> <lvl>    -- dig block in front of bot
dig_left    <slot> <lvl>    -- dig block to the left
dig_right   <slot> <lvl>    -- dig block to the right
dig_below   <slot>          -- dig block below the bot
dig_above   <slot>          -- dig block above the bot
rotate_item <lvl> <steps>   -- rotate block in front of bot
set_param2  <lvl> <param2>  -- set param2 of block in front of bot
```

---

### Signs & Farming

```
place_sign        <slot>    -- place sign in front of bot
place_sign_behind <slot>    -- place sign behind the bot
dig_sign          <slot>    -- remove sign in front of bot
trash_sign        <slot>    -- clear sign data and add to inventory

harvest                     -- harvest a 3×3 field
sow_seed          <slot>    -- sow a 3×3 field
cutting                     -- cut flowers on a 3×3 field
plant_sapling     <slot>    -- plant sapling in front of bot
pattern                     -- save 3×3×3 pattern behind sign
copy              <size>    -- copy saved pattern

add_compost  <slot>         -- put 2 leaves into compost barrel
take_compost <slot>         -- take compost from barrel
```

---

### Special commands (xdecor)

```
take_water    <slot>    -- fill empty bucket with water
fill_cauldron <slot>    -- fill xdecor cauldron with water
take_soup     <slot>    -- fill cooked soup from cauldron into bowl
flame_on                -- light a fire
flame_off               -- extinguish fire
punch_cart              -- push minecart
```

---

### Debug

```
print <text>    -- print chat message (debug)
debug_mode      -- activate single-step debugger (can also be written on a sign)
```

---

## Flow Control (Programming Logic)

Signs Bot has a complete **interpreter** with a compiler (2-pass) and stack-based
execution. Programs can contain up to 1000 tokens.

### Loops

```lua
repeat <num>       -- loop head, num = 1..999
  -- commands
end                -- loop end
```

### Jumps & Labels

```lua
jump <label>       -- unconditional jump
<label>:           -- jump target (label definition)
```

### Subroutines (Functions)

```lua
call <label>       -- call subroutine (return address pushed to stack)
return             -- return from subroutine
```

### Conditional Jumps

```lua
-- Jump to <label> if fewer than <num> items of the type in <slot> are in the chest
jump_check_item <num> <slot> <label>

-- Jump to <label> if the block in front of the bot at level <lvl> equals <nodename>
jump_if_block <lvl> <nodename> <label>

-- Jump to <label> if the block in front of the bot at level <lvl> does NOT equal <nodename>
jump_ifnot_block <lvl> <nodename> <label>

-- (techage) Jump to <label> if battery level is below <percent>%
jump_low_batt <percent> <label>
```

### Program end

```lua
exit    -- explicitly end program
```

---

### Complete Example

```lua
-- Define function at end, main program at beginning

-- Harvest a 3×3 area 5 times and deposit harvest in chest
repeat 5
  move 3
  harvest
  move 3
  call deposit
  turn_around
end
turn_off

-- Subroutine: store items in chest to the right
deposit:
  turn_right
  add_item 0 0
  turn_left
return
```

---

## Techage Integration

When **techage** is installed, the mod is significantly extended:

| Feature | Description |
|---|---|
| Power supply | Bot must be charged via ElectricCable (8 EU/step) |
| Techage chests | ta2/ta3/ta4 chests, silos, reactor etc. are supported |
| `ignite` | Ignite techage coal lighter |
| `low_batt <percent>` | Switch off bot when battery below X% |
| `jump_low_batt <percent> <label>` | Conditional jump on low battery |
| `send_cmnd <num> <command>` | Send techage command to node number |
| `move_platform <ctrl_num> <x,y,z>` | Move a TA4 Move Controller II platform and ride on it (requires techage v1.25) |
| Bot Control Unit | Switch sign via sensor signal |

**`send_cmnd` example:**
```
send_cmnd 3465 pull*default:dirt*2
-- asterisk (*) replaces spaces in the techage command
```

---

## Beduino Integration (BEP-006)

The bot can be remote-controlled via the **Beduino** protocol (microcontroller mod):

| Action | Topic | Payload |
|---|---|---|
| Switch bot on/off | 1 | `[0]` = off, `[1]` = on |
| Query bot status | 128 | – → `[num]` |

Bot states: `RUNNING=1`, `BLOCKED=2`, `STANDBY=3`, `NOPOWER=4`, `FAULT=5`, `STOPPED=6`, `CHARGING=7`

---

## Extensibility (Lua API)

Other mods can register their own bot commands:

```lua
signs_bot.register_botcommand("my_command", {
    mod = "my_mod",           -- group name in help menu
    params = "<slot>",        -- parameter description
    num_param = 1,            -- number of parameters (0–3)
    description = "...",      -- help texts
    check = function(slot)    -- compile-time validation
        return tonumber(slot) ~= nil
    end,
    cmnd = function(base_pos, mem, slot)
        -- execution logic
        return signs_bot.DONE  -- or BUSY, ERROR, TURN_OFF
    end,
})
```

**Return values:**
- `signs_bot.DONE` – command finished, proceed to next command
- `signs_bot.BUSY` – command not yet done, call again next tick
- `signs_bot.ERROR` – error, bot stops
- `signs_bot.TURN_OFF` – switch bot off

---

## Summary of Programming Capabilities

| Capability | Details |
|---|---|
| **Scripting language** | Custom text-based command language on the Command sign |
| **Loops** | `repeat N … end` (1–999 iterations, nestable) |
| **Functions** | `call label` / `return`, stack-based, up to 50 levels deep |
| **Jumps** | `jump label`, conditional jumps via `jump_check_item`, `jump_low_batt` |
| **Inventory logic** | 8 slots, pre-configurable, automatic slot search |
| **Sensor events** | Sensors trigger actuators (start bot, switch sign) |
| **External control** | Techage `send_cmnd`, Beduino BEP-006 |
| **Lua API** | Register custom commands for mod integration |
| **Debugging** | `print <text>` (chat), `debug_mode` (single-step debugger via box UI or sign) |
