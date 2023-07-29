require('du_lib/requires/stateManager')
require('du_lib/data/Talents')
require('du_lib/crafting/RecipeManager')
require('du_lib/crafting/SchematicCopiesManager')
require('du_lib/crafting/CraftingCalculator')
require('du_lib/requires/dataHud')
require('du_lib/general/DatabankHud')
require('du_lib/data_hud/TalentLevelsDbHud')
require('du_lib/data_hud/OresCostDbHud')
require('du_lib/data_hud/SchematicsCostDbHud')

require('CraftingHud/CraftingHud')


---@type number
workPerTick = 1000 --export: coroutine amount of work done per tick
---@type number
workTickInterval = 0.1 --export: coroutine interval between ticks
---@type number
contentFontSize = 30 --export
---@type number
elementsByPage = 15 --export
---@type number
groupsByPage = 10 --export


talentsDb = talentsDb
oresCostDb = oresCostDb
schemCostDb = schemCostDb


--Crafting Hud State
local talentsRepo = TalentsRepo.new(system, talentsDb)
local recipeManager = RecipeManager.new(system, talentsRepo)
local schematicCopiesManager = SchematicCopiesManager.new(system, schemCostDb)
local craftingCalculator = CraftingCalculator.new(system, recipeManager, schematicCopiesManager, oresCostDb)

local dataHud = FullDataHud.new(system, contentFontSize, elementsByPage, groupsByPage)
local craftingHud = CraftingHud.new(system, dataHud, craftingCalculator)
local craftingHudState = State.new({ craftingHud, craftingCalculator, recipeManager, talentsRepo, schematicCopiesManager, dataHud },
        unit, system, workPerTick, workTickInterval)


--Talent Levels Db Hud State
local dataHud = FullDataHud.new(system, contentFontSize, elementsByPage, groupsByPage)
local dbHud = DatabankHud.new(system, talentsDb, 'int', dataHud, 'Talent Levels Db')
local talentsDbHud = TalentLevelsDbHud.new(dbHud, talentsRepo)
local talentsDbHudState = State.new({ talentsDbHud, talentsRepo, dbHud, dataHud },
        unit, system, workPerTick, workTickInterval)


--Ores Cost Db Hud State
local dataHud = FullDataHud.new(system, contentFontSize, elementsByPage, groupsByPage)
local dbHud = DatabankHud.new(system, oresCostDb, 'float', dataHud, 'Ores Cost Db')
local oresDbHud = OresCostDbHud.new(dbHud, system)
local oresDbHudState = State.new({ oresDbHud, dbHud, dataHud },
        unit, system, workPerTick, workTickInterval)


--Schematics Cost Db Hud State
local dataHud = FullDataHud.new(system, contentFontSize, elementsByPage, groupsByPage)
local dbHud = DatabankHud.new(system, schemCostDb, 'float', dataHud, 'Schematics Cost Db')
local schemCostDbHud = SchematicsCostDbHud.new(dbHud, system)
local schemCostDbHudState = State.new({ schemCostDbHud, dbHud, dataHud },
        unit, system, workPerTick, workTickInterval)


local states = { craftingHudState, talentsDbHudState, oresDbHudState, schemCostDbHudState }
StateManager.new(states, system).start()