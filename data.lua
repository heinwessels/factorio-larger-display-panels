
local base_entity = data.raw["display-panel"]["display-panel"]
assert(base_entity)
local base_item = data.raw["item"]["display-panel"]
assert(base_item)
local base_recipe = data.raw["recipe"]["display-panel"]
assert(base_recipe)

local technology = data.raw["technology"]["circuit-network"]

---@class (exact) PanelConfiguration
---@field name string
---@field scale int
---@field order_postix string
---@field icon_overlay string

---@param config PanelConfiguration
---@return data.DisplayPanelPrototype
---@return data.ItemPrototype
---@return data.RecipePrototype
local function make_panel(config)
    -- ENTITY --------------------
    local entity = table.deepcopy(base_entity)
    entity.name = config.name

    if entity.minable then
        entity.minable.result = config.name
        entity.minable.mining_time = entity.minable.mining_time * config.scale
    end

    local ics = entity.icon_draw_specification or { }
    entity.icon_draw_specification = entity.icon_draw_specification or ics
    ics.scale = (ics.scale or 1) * config.scale
    ics.shift = util.mul_shift(ics.shift, config.scale)

    --TODO Corpse

    for _, sprite in pairs(entity.sprites) do
        for _, layer in pairs(sprite.layers) do -- TODO Not all sprites have layers. Just like ogers.
            layer.scale = (layer.scale or 1) * config.scale
            layer.shift = util.mul_shift(layer.shift, config.scale)

            -- Attempt to have the sprites not be compressed in medium quality
            -- TODO Does this work?
            layer.flags = layer.flags or { }
            table.insert(layer.flags, "no-scale")
        end
    end

    for _, definition in pairs(entity.circuit_connector) do
        for _, point in pairs(definition.points) do
            for colour in pairs(point) do
                point[colour] = util.mul_shift(point[colour], config.scale)
            end
        end
    end

    local padding = (config.scale - 1) / 2
    for _, box_type in pairs{"collision_box", "selection_box"} do
        local box = entity[box_type]
        box[1][1] = box[1][1] - padding
        box[1][2] = box[1][2] - padding
        box[2][1] = box[2][1] + padding
        box[2][2] = box[2][2] + padding
    end

    entity.text_shift = util.mul_shift(entity.text_shift, config.scale)

    -- ITEM --------------------
    local item = table.deepcopy(base_item)
    item.name = config.name
    item.place_result = config.name
    item.order = item.order .. config.order_postix
    item.icons = {
        {
            icon = item.icon,
            icon_size = item.icon_size,
            scale = 1,
        },
        {
            icon = "__larger-display-panels__/graphics/icons/"..config.icon_overlay..".png",
            icon_size = 64,
            scale = 0.7,
            shift = { -8, -8}
        }
    }

    -- RECIPE --------------------
    local recipe = table.deepcopy(base_recipe)
    recipe.name = config.name
    recipe.results[1].name = config.name -- TODO Be smarter
    recipe.enabled = technology == nil -- Enabled as fallback for now
    recipe.energy_required = (recipe.energy_required or 0.5) * config.scale
    for _, ingredient in pairs(recipe.ingredients) do
        ingredient.amount = ingredient.amount * config.scale * config.scale
    end

    -- TECHNOLOGY --------------------
    if technology then
        -- TODO Add it in the array just after the display-panel
        -- so it shows nicely in the technology GUI
        table.insert(technology.effects, {
            type = "unlock-recipe",
            recipe = config.name
        })
    end

    data:extend{entity, item, recipe}
    return entity, item, recipe
end


make_panel({name = "medium-display-panel", scale = 2, order_postix="-a", icon_overlay="m"})
make_panel({name = "big-display-panel",    scale = 4, order_postix="-b", icon_overlay="b"})
make_panel({name = "giant-display-panel",  scale = 6, order_postix="-c", icon_overlay="g"})
