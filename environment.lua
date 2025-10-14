-- environment.lua

local sti = require("lib.sti")

local Environment = {}
Environment.__index = Environment

function Environment:new()
    local self = setmetatable({}, Environment)

    print("Loading Tiled map...")
    self.map = sti("assets/environment/desertMap.lua")
    print("Tiled map loaded!")

    return self
end

function Environment:update(dt)
    if self.map then
        self.map:update(dt)
    end
end

function Environment:draw()
    if self.map then
        -- Scale the map to fit the window properly
        love.graphics.push()
        
        -- Calculate scale to fit window (1280x720)
        local mapWidth = self.map.width * self.map.tilewidth  -- 60 * 24 = 1440
        local mapHeight = self.map.height * self.map.tileheight  -- 30 * 24 = 720
        
        -- Scale to fit window width (1280)
        local scaleX = 1280 / mapWidth  -- 1280 / 1440 ≈ 0.89
        local scaleY = 720 / mapHeight  -- 720 / 720 = 1.0
        
        -- Use the smaller scale to fit entirely in window
        local scale = math.min(scaleX, scaleY)
        
        love.graphics.scale(scale, scale)
        self.map:draw()
        love.graphics.pop()
    end
end

return Environment
