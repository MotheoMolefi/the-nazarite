-- healthpack.lua
-- Health pack pickup system (Spirit of the Lord orbs)

local anim8 = require 'lib.anim8'

local HealthPack = {}
HealthPack.__index = HealthPack

function HealthPack:new(x, y, isBig)
    local self = setmetatable({}, HealthPack)
    
    self.x = x
    self.y = y
    self.isBig = isBig or false  -- Default to regular heart
    
    -- Big hearts heal more and are larger
    if self.isBig then
        self.healAmount = 40  -- Restore 40 HP (two hearts)
        self.scale = 3.0  -- Bigger size
    else
        self.healAmount = 20  -- Restore 20 HP (one heart)
        self.scale = 2.0  -- Regular size
    end
    
    self.lifetime = 5.0  -- Despawn after 5 seconds
    self.timer = 0
    self.collected = false
    
    -- Load animated heart sprite (1 row, 4 columns)
    self.image = love.graphics.newImage("assets/Icons/heartAnim.png")
    
    -- Create animation grid (same pattern as Samson)
    local w = self.image:getWidth()
    local h = self.image:getHeight()
    print("Heart image size: " .. w .. "x" .. h)
    
    -- Calculate frame size: width / 4 frames = frame width
    local frameW = math.floor(w / 4)
    local frameH = h  -- Assume single row
    print("Calculated frame size: " .. frameW .. "x" .. frameH)
    
    local grid = anim8.newGrid(frameW, frameH, w, h)
    self.animation = anim8.newAnimation(grid('1-4', 1), 0.15)
    
    return self
end

function HealthPack:update(dt)
    if self.collected then return end
    
    -- Update lifetime timer
    self.timer = self.timer + dt
    if self.timer >= self.lifetime then
        self.collected = true  -- Mark for removal
        return
    end
    
    -- Update animation (beating heart effect)
    self.animation:update(dt)
end

function HealthPack:draw()
    if self.collected then return end
    
    -- Draw the animated beating heart
    love.graphics.setColor(1, 1, 1, 1)
    self.animation:draw(
        self.image,
        math.floor(self.x),
        math.floor(self.y),
        0,  -- No rotation
        self.scale,
        self.scale,
        self.image:getWidth() / 8,  -- origin X (center of frame)
        self.image:getHeight() / 2  -- origin Y (center of frame)
    )
end

function HealthPack:checkPickup(player)
    if self.collected then return false end
    
    -- Check distance to player
    local dx = self.x - player.x
    local dy = self.y - player.y
    local distance = math.sqrt(dx^2 + dy^2)
    
    -- Pickup radius
    if distance < 30 then
        self.collected = true
        return true
    end
    
    return false
end

return HealthPack

