local anim8 = require 'lib.anim8'

local Samson = {}
Samson.__index = Samson

-- 🆕 Constructor
function Samson:new(x, y)
    local self = setmetatable({}, Samson)

    self.x = x
    self.y = y
    self.speed = 100
    self.health = 100

    -- 🟢 Movement and state control
    self.state = "idle"         -- Options: idle, walk, run, hurt, death, etc.
    self.direction = "down"     -- Options: down, left, right, up

    -- 🖼️ Load sprite sheets
    self.images = {
        -- 🔴 Idle state
        idle = love.graphics.newImage("assets/sprites/samson/idle.png"),

        -- 🟢 Walking state
        walk = love.graphics.newImage("assets/sprites/samson/walk.png"),

        -- 🔵 Running state
        run = love.graphics.newImage("assets/sprites/samson/run.png"),

        -- ⚫ Damage state
        -- hurt = love.graphics.newImage("assets/sprites/samson/hurt.png"),
        -- death = love.graphics.newImage("assets/sprites/samson/death.png"),
    }

    -- 🔲 Create animation grids
    local function makeGrid(image)
        return anim8.newGrid(64, 64, image:getWidth(), image:getHeight())
    end

    self.grids = {
        idle = makeGrid(self.images.idle),
        walk = makeGrid(self.images.walk),
        run = makeGrid(self.images.run),
        -- hurt = makeGrid(self.images.hurt),
        -- death = makeGrid(self.images.death),
    }

    -- 🌀 Animations
    self.animations = {
        -- 🔴 Idle animations
        idle = {
            down  = anim8.newAnimation(self.grids.idle('1-12', 1), 0.1),  -- Full blinking animation
            left  = anim8.newAnimation(self.grids.idle('1-12', 2), 0.1),  -- Full blinking animation  
            right = anim8.newAnimation(self.grids.idle('1-12', 3), 0.1),  -- Full blinking animation
            up    = anim8.newAnimation(self.grids.idle('1-4', 4), 0.3),   -- Simple idle, same total duration
        },

        -- 🟢 Walking animations (to be added later)
        walk = {
            down  = anim8.newAnimation(self.grids.walk('1-6', 1), 0.1),
            left  = anim8.newAnimation(self.grids.walk('1-6', 2), 0.1),
            right = anim8.newAnimation(self.grids.walk('1-6', 3), 0.1),
            up    = anim8.newAnimation(self.grids.walk('1-6', 4), 0.1),
        },

        -- 🔵 Running animations
        run = {
            down  = anim8.newAnimation(self.grids.run('1-8', 1), 0.08),
            left  = anim8.newAnimation(self.grids.run('1-8', 2), 0.08),
            right = anim8.newAnimation(self.grids.run('1-8', 3), 0.08),
            up    = anim8.newAnimation(self.grids.run('1-8', 4), 0.08),
        },

        -- ⚫ Hurt / Death animations (to be added later)
        -- hurt = { ... }
        -- death = { ... }
    }

    -- ▶️ Set initial animation
    self.currentAnimation = self.animations.idle.down

    return self
end

-- 🟧 STATE SWITCH FUNCTION
function Samson:setState(newState)
    if self.state ~= newState and self.animations[newState] and self.animations[newState][self.direction] then
        self.state = newState
        self.currentAnimation = self.animations[self.state][self.direction]
        self.currentAnimation:gotoFrame(1)
    end
end

-- 🧭 DIRECTION SWITCH FUNCTION
function Samson:setDirection(newDir)
    if self.direction ~= newDir and self.animations[self.state] and self.animations[self.state][newDir] then
        self.direction = newDir
        self.currentAnimation = self.animations[self.state][self.direction]
        self.currentAnimation:gotoFrame(1)
    end
end

-- 🟨 UPDATE LOOP
function Samson:update(dt)
    -- 🕹️ Movement input
    local isMoving = false
    local isRunning = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
    local dx, dy = 0, 0

    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then 
        dx = dx - 1 
        isMoving = true 
    end
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then 
        dx = dx + 1 
        isMoving = true 
    end
    if love.keyboard.isDown("up") or love.keyboard.isDown("w") then 
        dy = dy - 1 
        isMoving = true 
    end
    if love.keyboard.isDown("down") or love.keyboard.isDown("s") then 
        dy = dy + 1 
        isMoving = true 
    end

    -- 🧭 Set direction based on primary movement
    if isMoving then
        if math.abs(dx) > math.abs(dy) then
            -- Horizontal movement is stronger
            if dx > 0 then
                self:setDirection("right")
            else
                self:setDirection("left")
            end
        else
            -- Vertical movement is stronger
            if dy > 0 then
                self:setDirection("down")
            else
                self:setDirection("up")
            end
        end
    end

    -- 🏃 Movement and state transition
    local norm = math.sqrt(dx * dx + dy * dy)
    if norm > 0 then
        dx = dx / norm
        dy = dy / norm
        
        -- Apply speed multiplier for running
        local speedMultiplier = isRunning and 2 or 1
        self.x = self.x + dx * self.speed * speedMultiplier * dt
        self.y = self.y + dy * self.speed * speedMultiplier * dt
        
        -- Set animation state based on movement type
        if isRunning then
            if self.state ~= "run" then
                self:setState("run")
            end
        else
            if self.state ~= "walk" then
                self:setState("walk")
            end
        end
    else
        if self.state ~= "idle" then
            self:setState("idle")
        end
    end

    -- 🎞️ Update animation
    if self.currentAnimation then
        self.currentAnimation:update(dt)
    end
end

-- 🟥 DRAW FUNCTION
function Samson:draw()
    if self.currentAnimation then
        self.currentAnimation:draw(self.images[self.state], self.x, self.y, 0, 3, 3, 32, 32)
    end
end


return Samson
