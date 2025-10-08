local Samson = require("samson")
local player

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest") -- Pixel-perfect scaling
    player = Samson:new(400, 300)
end

function love.update(dt)
    player:update(dt)
end

function love.draw()
    player:draw()
end
