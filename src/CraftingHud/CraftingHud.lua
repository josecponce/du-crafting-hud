require('du_lib/requires/service')
require('du_lib/requires/dataHud')
require('du_lib/crafting/CraftingCalculator')
require('du_lib/data/ItemGroups')

---@class ItemGroupBreadcrumb
---@field name string
---@field groupNames string[]
---@field groups ItemGroupBreadcrumb[]
---@field itemIds number[]
---@field itemNames string[]

---@param name string
---@param groups table<string, ItemGroup>
---@param items number[] | nil
---@param system System
---@return ItemGroupBreadcrumb
local function breadcrumb(name, groups, items, system)
    ---@type ItemGroupBreadcrumb[]
    local itemGroups
    local groupNames
    if groups then
        itemGroups = {}
        groupNames = {}
        for name, group in pairs(groups) do
            table.insert(groupNames, name)
            table.insert(itemGroups, breadcrumb(name, group.groups, group.items, system))
        end
        table.sort(groupNames)
        table.sort(itemGroups, function(l, r) return l.name < r.name end)
    end

    ---@type any[]
    local itemsTmp
    local itemNames, itemIds
    if items then
        itemsTmp = {}
        for _, itemId in ipairs(--[[---@type number[] ]] items) do
            local item = system.getItem(itemId)
            table.insert(itemsTmp, item)
        end
        table.sort(itemsTmp, function(l, r) return l.displayNameWithSize < r.displayNameWithSize end)

        itemIds = {}
        itemNames = {}
        for _, item in ipairs(itemsTmp) do
            table.insert(itemIds, item.id)
            table.insert(itemNames, item.displayNameWithSize)
        end
    end

    return --[[---@type ItemGroupBreadcrumb]] {
        name = name,
        groupNames = groupNames,
        groups = itemGroups,
        itemIds = itemIds,
        itemNames = itemNames
    }
end

---@class CraftingHud : Service
CraftingHud = {}
CraftingHud.__index = CraftingHud

local HEADERS = { 'Type', 'Item', 'Quantity', 'Cost', 'Industries' }

---@param outputId number
---@param outputQuantity number
---@param outputCost number
---@param outputIndustries number
---@param byproducts table<number, CraftingCostItem>
---@param ingredients table<number, CraftingCostItem>
---@param schematics table<number, CraftingCostItem>
---@param system System
---@return string[][]
local function renderCost(outputId, outputQuantity, outputCost, outputIndustries, byproducts, ingredients, schematics, system)
    local item = system.getItem(outputId)
    local blankRow = { '', '', '', '', '' }

    local function numFormat(num)
        local formatted = string.format('%.2f', num)
        local k
        while true do
            formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
            if (k==0) then
                break
            end
        end
        return formatted
    end

    local rows = { }
    local output = { 'Output', item.displayNameWithSize, numFormat(outputQuantity), numFormat(outputCost), numFormat(outputIndustries) }
    table.insert(rows, output)
    table.insert(rows, blankRow)

    for ingredientId, ingredient in pairs(ingredients) do
        local item = system.getItem(ingredientId)
        local industries = '-'
        if ingredient.industries then
            industries = numFormat(ingredient.industries)
        end
        local ingredient = { 'Ingredients', item.displayNameWithSize, numFormat(ingredient.quantity),
                             numFormat(ingredient.cost), industries }
        table.insert(rows, ingredient)
    end
    table.insert(rows, blankRow)

    local rowsSchematics = {}
    table.insert(rowsSchematics, blankRow)
    for schematicId, schematic in pairs(schematics) do
        local item = system.getItem(schematicId)
        local schematic = { 'Schematics', item.displayNameWithSize,
                            numFormat(schematic.quantity), numFormat(schematic.cost), '-' }
        table.insert(rowsSchematics, schematic)
    end
    if #rowsSchematics > 1 then
        table.move(rowsSchematics, 1, #rowsSchematics, #rows + 1, rows)
    end

    local rowsByproducts = {}
    table.insert(rowsByproducts, blankRow)
    for byproductId, byproduct in pairs(byproducts) do
        local item = system.getItem(byproductId)
        local byproduct = { 'Byproducts', item.displayNameWithSize,
                            numFormat(byproduct.quantity), numFormat(byproduct.cost), '-' }
        table.insert(rowsByproducts, byproduct)
    end
    if #rowsByproducts > 1 then
        table.move(rowsByproducts, 1, #rowsByproducts, #rows + 1, rows)
    end

    return rows
end

local BASE_HUD_TITLE = 'Crafting HUD'
---@param system System
---@param hud FullDataHud
---@param craftingCalculator CraftingCalculator
---@return CraftingHud
function CraftingHud.new(system, hud, craftingCalculator)
    local self = --[[---@type self]] Service.new()

    local craftingCalculatorReady

    local itemId
    local previousItemId
    ---@type 'day' | 'unit'
    local calculationMode = 'unit'
    local previousCalculationMode
    ---@type CraftingCost
    local craftingCost
    ---@param permit CoroutinePermit
    local function calculateCost(permit)
        while not (craftingCalculatorReady and itemId) or (previousItemId == itemId and previousCalculationMode == calculationMode) do
            permit.yield()
        end
        craftingCost = craftingCalculator.calculate(itemId, calculationMode,  permit)
        previousItemId = itemId
        previousCalculationMode = calculationMode
    end

    ---@type ItemGroupBreadcrumb[]
    local breadcrumbs = { breadcrumb('All', ITEM_GROUPS, nil, system) }
    local viewMode = 1
    local function updateHud()
        local title = BASE_HUD_TITLE
        local rows
        if craftingCost then
            if viewMode == 1 then
                --direct mode
                title = title .. ' - Direct'
                local directCost = craftingCost.directCost
                rows = renderCost(craftingCost.itemId, craftingCost.quantity, craftingCost.totalCost, craftingCost.industries, directCost.byproducts,
                        directCost.ingredients, directCost.schematics, system)
            elseif viewMode == 2 then
                --ores only mode
                title = title .. ' - Ores Only'
                local ingredients = craftingCost.ingredients
                ---@type table<number, CraftingCostItem>
                local ores = {}
                local itemGroup = ItemGroup.findItemGroup(I_GROUP_ORE)
                local oreIds = ItemGroup.getItemsInGroup(system, itemGroup, nil, nil)
                for _, oreId in ipairs(oreIds) do
                    local ore = ingredients[oreId]
                    if ore then
                        ores[oreId] = ore
                    end
                end
                rows = renderCost(craftingCost.itemId, craftingCost.quantity, craftingCost.totalCost, craftingCost.industries, craftingCost.byproducts, ores,
                        craftingCost.schematics, system)
            elseif viewMode == 3 then
                --full view mode
                title = title .. ' - Full'
                rows = renderCost(craftingCost.itemId, craftingCost.quantity, craftingCost.totalCost, craftingCost.industries, craftingCost.byproducts,
                        craftingCost.ingredients, craftingCost.schematics, system)
            end
        end

        local currentGroup = breadcrumbs[#breadcrumbs]
        title = title .. ' - ' .. calculationMode:upper() .. ' - ' .. currentGroup.name

        local groups
        if currentGroup.itemNames then
            groups = currentGroup.itemNames
        else
            groups = currentGroup.groupNames
        end

        local data = FullDataHudData.new(title, HEADERS, rows, groups)
        hud.updateData(data)
    end

    local function setItemId(_, text)
        itemId = tonumber(text)
    end

    local function craftingCalculatorInit()
        craftingCalculatorReady = true
    end

    local function switchViewMode()
        if viewMode > 2 then
            viewMode = 1
        else
            viewMode = viewMode + 1
        end
    end

    local function switchCalculationMode()
        if calculationMode == 'unit' then
            calculationMode = 'day'
        else
            calculationMode = 'unit'
        end
    end

    local function onGroupActionLeft(_, _)
        if #breadcrumbs > 1 then
            table.remove(breadcrumbs, #breadcrumbs)
            hud.setSelected(1, 1)
        end
    end

    ---@param index number
    local function onGroupActionRight(_, index)
        local previous = breadcrumbs[#breadcrumbs]
        local previousGroups = previous.groups
        if previousGroups then
            local current = previousGroups[index]
            table.insert(breadcrumbs, current)
            hud.setSelected(1, 1)
        end

        local previousItemIds = previous.itemIds
        if previousItemIds then
            itemId = previousItemIds[index]
        end
    end

    ---@param state State
    function self.start(state)
        state.registerTimer('CraftingHud_updateHud', 0.2, updateHud)
        state.registerCoroutine(self, 'CraftingHud_calculateCost', calculateCost, true)

        state.registerHandler(hud, FULL_DATA_HUD_EVENTS.GROUP_ACTION_LEFT, onGroupActionLeft)
        state.registerHandler(hud, FULL_DATA_HUD_EVENTS.GROUP_ACTION_RIGHT, onGroupActionRight)

        state.registerHandler(craftingCalculator, CRAFTING_CALCULATOR_EVENT.INIT, craftingCalculatorInit)

        state.registerHandler(system, SYSTEM_EVENTS.INPUT_TEXT, setItemId)
        state.registerHandler(system, SYSTEM_EVENTS.ACTION_START, DuLuacUtils.createHandler({
            [LUA_ACTIONS.OPTION3] = switchViewMode,
            [LUA_ACTIONS.OPTION4] = switchCalculationMode
        }))
    end

    return setmetatable(self, CraftingHud)
end