# DU Crafting Hud

## Special Thanks
- Wolfe: for his great work on [du-luac](https://github.com/wolfe-labs/DU-LuaC)
- Jericho: for the tons of code I stole from his [DU-Industry-HUD](https://github.com/Jericho1060/DU-Industry-HUD)
  and [du-storage-monitoring](https://github.com/Jericho1060/du-storage-monitoring) projects.

## Features
- **Show/Hide Hud**: Alt + 2. Also, useful to avoid key presses to be interpreted by the Hud.
- **Calculate Crafting Costs**:
  - Calculation Modes: Cycle using Alt + 3 once a product is selected.
    - Direct: costs directly from the recipe (adjusted for talents)
    - Ores Only: recursive costs but displays only the ores instead of including intermediate products.
    - Full: recursive costs including intermediate products.
    - All modes include schematics costs and byproducts.
  - Calculation Amount/Timeframe: Change using Alt + 4 once a product is selected.
    - Unit: cost for a single unit.
    - Day: cost for a full day of production in a single factory.
  - Select Product:
    - Navigate groups/products using Ctrl + Up/Down/Right/Left
    - When a product (as opposed to a group) is selected using Ctrl + Right Crafting Costs table will be displayed.
    - You can then cycle through Calculation Modes and Amount/Timeframes as described above for different views of the data.
    - Use Up/Down/Left/Right to navigate the Calculation Costs table.
  - Notes:
    - Most production speed talents are not taken into account atm.
    - All input/output talents are taken into account.
- **Databank Huds to update talent levels, ores and schematics costs**: Cycle using Alt + 1.
  - Talent Levels Db Hud: Set talent levels for the player running the factory.
  - Ores Cost Db Hud: Set estimated ore cost for each ore. Used to estimate quanta cost of products.
  - Schematics Cost Db Hud: Current cost of schematic copies. Note this is per schematic copy, not per schematic copy batch,
   so you'll have to do that calculation yourself before entering the value.
  - To record a value on any of this:
    - Navigate groups using Ctrl + Up/Down (does not apply to all Db Hud screens)
    - Navigate entries using Up/Down/Left/Right.
    - Press Alt + Left. Prompt should appear in lua console.
    - Type value in lua console and hit Enter.
  - Notes:
    - In most cases the calculator will error out and print an error message to the lua console when a value from one of
     these Dbs is required but not yet entered.
    - For easiest use, you should fill out as many of these values as possible from the beginning, or you'll be stopped by
     the calculator repeatedly on each value it needs you haven't yet entered that it requires for the current calculation.

## Known Limitations
- This is limited by computing power and size allowed within DU as well as my laziness ofc. 
 For a more feature rich crafting tool take a look at:
  - [DU-Industry-Tool](https://github.com/tobitege/DU-Industry-Tool)
  - [du-factory-generator](https://github.com/tvwenger/du-factory-generator)

## Parts Required
- Programming Board: 1
- Databanks: 3

## Setup Instructions
- Deploy Programming Board
- Connect in the following order:
  - databanks
- Update lua parameters as needed.

## Developer Notes
### Compile Project
- Install [du-luac](https://github.com/wolfe-labs/DU-LuaC).
- Clone the lib repo on [github](https://github.com/josecponce/du-lib).
- Either copy or symlink the `src` folder from the lib repo inside the `src` folder in this repo with the name `du_lib`.
- Compile using dua-lua: `du-lua build`
