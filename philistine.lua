-- philistine.lua
-- Philistine enemy class using legend-of-lua skeleton logic

local anim8 = require 'lib.anim8'
local Philistine = {}
Philistine.__index = Philistine

-- 🆕 Constructor
function Philistine:new(x, y, level)
    local self = setmetatable({}, Philistine)
    self.x = x
    self.y = y
    self.level = level or 1
    
    -- 🟢 Progressive stats based on level
    if self.level == 1 then
        self.health = 3
        self.maxHealth = 3
        self.speed = 50  -- Slower than Samson
        self.magnitude = 50
        self.viewDistance = 200  -- Bigger detection radius
    elseif self.level == 2 then
        self.health = 5
        self.maxHealth = 5
        self.speed = 60  -- Slower than Samson
        self.magnitude = 60
        self.viewDistance = 220  -- Bigger detection radius
    else -- level 3
        self.health = 7
        self.maxHealth = 7
        self.speed = 70  -- Slower than Samson
        self.magnitude = 70
        self.viewDistance = 240  -- Bigger detection radius
    end
    
    -- 🎯 Legend-of-lua state system
    self.state = 1  -- 1=wander stopped, 1.1=wander moving, 99=alert, 100=chase
    self.dead = false
    self.chase = true
    self.dir = {x = 0, y = 1}  -- Movement direction vector
    self.animTimer = 0  -- Alert timer
    self.direction = "down"  -- Direction for animation (like Samson)
    
    -- 🚶 Wander behavior (exact legend-of-lua logic)
    self.startX = x
    self.startY = y
    self.wanderRadius = 30
    self.wanderSpeed = 15
    self.wanderTimer = 0.5 + math.random() * 2
    self.wanderBufferTimer = 0
    self.wanderDir = {x = 1, y = 1}
    
    -- 🎭 Animation control (legend-of-lua style)
    self.moving = 0  -- 0=still, 1=walk, 2=run
    self.scaleX = 1
    if math.random() < 0.5 then self.scaleX = -1 end
    
    -- 🔧 Physics (will be set by main.lua)
    self.physics = nil
    
    -- 🖼️ Load sprite sheets (exact same way as Samson)
    self.images = {
        idle = love.graphics.newImage("assets/sprites/philistines/lvl1_philistine/lvl1_idle.png"),
        walk = love.graphics.newImage("assets/sprites/philistines/lvl1_philistine/lvl1_walk.png"),
        attack = love.graphics.newImage("assets/sprites/philistines/lvl1_philistine/lvl1_attack.png"),
        walk_attack = love.graphics.newImage("assets/sprites/philistines/lvl1_philistine/lvl1_walk_attack.png"),
        hurt = love.graphics.newImage("assets/sprites/philistines/lvl1_philistine/lvl1_hurt.png"),
        death = love.graphics.newImage("assets/sprites/philistines/lvl1_philistine/lvl1_death.png")
    }
    
    -- 🔲 Create animation grids (exact same way as Samson)
    local function makeGrid(image)
        return anim8.newGrid(64, 64, image:getWidth(), image:getHeight())
    end

    self.grids = {
        idle = makeGrid(self.images.idle),
        walk = makeGrid(self.images.walk),
        attack = makeGrid(self.images.attack),
        walk_attack = makeGrid(self.images.walk_attack),
        hurt = makeGrid(self.images.hurt),
        death = makeGrid(self.images.death)
    }
    
    
    -- 🌀 Animations (exact same way as Samson)
    self.animations = {
        idle = {
            down  = anim8.newAnimation(self.grids.idle('1-12', 1), 0.1),
            left  = anim8.newAnimation(self.grids.idle('1-12', 2), 0.1),
            right = anim8.newAnimation(self.grids.idle('1-12', 3), 0.1),
            up    = anim8.newAnimation(self.grids.idle('1-12', 4), 0.1),
        },
        walk = {
            down  = anim8.newAnimation(self.grids.walk('1-6', 1), 0.1),
            left  = anim8.newAnimation(self.grids.walk('1-6', 2), 0.1),
            right = anim8.newAnimation(self.grids.walk('1-6', 3), 0.1),
            up    = anim8.newAnimation(self.grids.walk('1-6', 4), 0.1),
        },
        attack = {
            down  = anim8.newAnimation(self.grids.attack('1-7', 1), 0.08),
            left  = anim8.newAnimation(self.grids.attack('1-7', 2), 0.08),
            right = anim8.newAnimation(self.grids.attack('1-7', 3), 0.08),
            up    = anim8.newAnimation(self.grids.attack('1-7', 4), 0.08),
        },
        walk_attack = {
            down  = anim8.newAnimation(self.grids.walk_attack('1-6', 1), 0.08),
            left  = anim8.newAnimation(self.grids.walk_attack('1-6', 2), 0.08),
            right = anim8.newAnimation(self.grids.walk_attack('1-6', 3), 0.08),
            up    = anim8.newAnimation(self.grids.walk_attack('1-6', 4), 0.08),
        },
        hurt = {
            down  = anim8.newAnimation(self.grids.hurt('1-5', 1), 0.1),
            left  = anim8.newAnimation(self.grids.hurt('1-5', 2), 0.1),
            right = anim8.newAnimation(self.grids.hurt('1-5', 3), 0.1),
            up    = anim8.newAnimation(self.grids.hurt('1-5', 4), 0.1),
        },
        death = {
            down  = anim8.newAnimation(self.grids.death('1-7', 1), 0.15),
            left  = anim8.newAnimation(self.grids.death('1-7', 2), 0.15),
            right = anim8.newAnimation(self.grids.death('1-7', 3), 0.15),
            up    = anim8.newAnimation(self.grids.death('1-7', 4), 0.15),
        }
    }
    
    
    -- ▶️ Set initial animation (exact same way as Samson)
    self.currentAnimation = self.animations.idle.down
    
    return self
end

-- 🟨 UPDATE LOOP (simple chase)
function Philistine:update(dt)
    if self.dead then return end
    
    -- Simple detection and chase
    if self.physics and self.target then
        local ex, ey = self.physics:getX(), self.physics:getY()
        local px, py = self.target.x, self.target.y
        local distance = math.sqrt((px - ex)^2 + (py - ey)^2)
        
        -- Detection radius
        if distance < self.viewDistance then
            -- Chase player
            local dx = px - ex
            local dy = py - ey
            local norm = math.sqrt(dx^2 + dy^2)
            
            if norm > 0 then
                dx = dx / norm
                dy = dy / norm
                
                -- Use setLinearVelocity like Samson
                local vx = dx * self.speed
                local vy = dy * self.speed
                self.physics:setLinearVelocity(vx, vy)
                
                -- Set direction based on movement (like Samson)
                if math.abs(dx) > math.abs(dy) then
                    -- Horizontal movement is stronger
                    if dx > 0 then
                        self.direction = "right"
                        self.scaleX = 1
                    else
                        self.direction = "left"
                        self.scaleX = 1  -- Don't flip, use proper left animation
                    end
                else
                    -- Vertical movement is stronger
                    if dy > 0 then
                        self.direction = "down"
                    else
                        self.direction = "up"
                    end
                end
                
                -- Debug output
                print("Philistine direction: " .. self.direction .. " (dx: " .. dx .. ", dy: " .. dy .. ")")
            end
            
            -- Switch to walk animation when chasing
            local newAnimation = self.animations.walk[self.direction]
            if self.currentAnimation ~= newAnimation then
                self.currentAnimation = newAnimation
                self.currentAnimation:gotoFrame(1)
            end
        else
            -- Stop movement when not chasing
            self.physics:setLinearVelocity(0, 0)
            
            -- Switch to idle animation when not chasing
            local newAnimation = self.animations.idle[self.direction]
            if self.currentAnimation ~= newAnimation then
                self.currentAnimation = newAnimation
                self.currentAnimation:gotoFrame(1)
            end
        end
    end
    
    -- Update animation
    if self.currentAnimation then
        self.currentAnimation:update(dt)
    end
end


-- 🟥 DRAW FUNCTION (simple chase)
function Philistine:draw()
    if self.currentAnimation and self.physics then
        local ex, ey = self.physics:getX(), self.physics:getY()
        
        -- Choose image based on current animation
        local imageToUse = self.images.idle
        if self.currentAnimation == self.animations.walk[self.direction] then
            imageToUse = self.images.walk
        end
        
        -- Draw with scaling
        self.currentAnimation:draw(imageToUse, math.floor(ex), math.floor(ey), 0, self.scaleX * 2, 2, 32, 32)
    end
end

return Philistine