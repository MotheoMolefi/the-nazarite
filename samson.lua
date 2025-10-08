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
    self.isAttacking = false    -- Track if currently attacking

    -- 🖼️ Load sprite sheets
    self.images = {
        -- 🔴 Idle state
        idle = love.graphics.newImage("assets/sprites/samson/idle.png"),
        attack = love.graphics.newImage("assets/sprites/samson/attack.png"),

        -- 🟢 Walking state
        walk = love.graphics.newImage("assets/sprites/samson/walk.png"),
        walk_attack = love.graphics.newImage("assets/sprites/samson/walk_attack.png"),

        -- 🔵 Running state
        run = love.graphics.newImage("assets/sprites/samson/run.png"),
        run_attack = love.graphics.newImage("assets/sprites/samson/run_attack.png"),

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
        attack = makeGrid(self.images.attack),
        
        walk = makeGrid(self.images.walk),
        walk_attack = makeGrid(self.images.walk_attack),
        
        run = makeGrid(self.images.run),
        run_attack = makeGrid(self.images.run_attack),
        
        -- hurt = makeGrid(self.images.hurt),
        -- death = makeGrid(self.images.death),
    }

    -- 🌀 Animations
    self.animations = {
        -- 🔴 Idle state animations
        idle = {
            down  = anim8.newAnimation(self.grids.idle('1-12', 1), 0.1),  -- Full blinking animation
            left  = anim8.newAnimation(self.grids.idle('1-12', 2), 0.1),  -- Full blinking animation  
            right = anim8.newAnimation(self.grids.idle('1-12', 3), 0.1),  -- Full blinking animation
            up    = anim8.newAnimation(self.grids.idle('1-4', 4), 0.3),   -- Simple idle, same total duration
        },
        attack = {  -- ⚔️ Idle attack
            down  = anim8.newAnimation(self.grids.attack('1-8', 1), 0.08, 'pauseAtEnd'),
            left  = anim8.newAnimation(self.grids.attack('1-8', 2), 0.08, 'pauseAtEnd'),
            right = anim8.newAnimation(self.grids.attack('1-8', 3), 0.08, 'pauseAtEnd'),
            up    = anim8.newAnimation(self.grids.attack('1-8', 4), 0.08, 'pauseAtEnd'),
        },

        -- 🟢 Walking state animations
        walk = {
            down  = anim8.newAnimation(self.grids.walk('1-6', 1), 0.1),
            left  = anim8.newAnimation(self.grids.walk('1-6', 2), 0.1),
            right = anim8.newAnimation(self.grids.walk('1-6', 3), 0.1),
            up    = anim8.newAnimation(self.grids.walk('1-6', 4), 0.1),
        },
        walk_attack = {  -- ⚔️ Walk attack
            down  = anim8.newAnimation(self.grids.walk_attack('1-6', 1), 0.08, 'pauseAtEnd'),
            left  = anim8.newAnimation(self.grids.walk_attack('1-6', 2), 0.08, 'pauseAtEnd'),
            right = anim8.newAnimation(self.grids.walk_attack('1-6', 3), 0.08, 'pauseAtEnd'),
            up    = anim8.newAnimation(self.grids.walk_attack('1-6', 4), 0.08, 'pauseAtEnd'),
        },

        -- 🔵 Running state animations
        run = {
            down  = anim8.newAnimation(self.grids.run('1-8', 1), 0.08),
            left  = anim8.newAnimation(self.grids.run('1-8', 2), 0.08),
            right = anim8.newAnimation(self.grids.run('1-8', 3), 0.08),
            up    = anim8.newAnimation(self.grids.run('1-8', 4), 0.08),
        },
        run_attack = {  -- ⚔️ Run attack
            down  = anim8.newAnimation(self.grids.run_attack('1-8', 1), 0.06, 'pauseAtEnd'),
            left  = anim8.newAnimation(self.grids.run_attack('1-8', 2), 0.06, 'pauseAtEnd'),
            right = anim8.newAnimation(self.grids.run_attack('1-8', 3), 0.06, 'pauseAtEnd'),
            up    = anim8.newAnimation(self.grids.run_attack('1-8', 4), 0.06, 'pauseAtEnd'),
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
    -- ═══════════════════════════════════════════════════════════════
    -- 🎮 GAME CONTROLS
    -- ═══════════════════════════════════════════════════════════════
    -- Movement: WASD / Arrow Keys
    -- Run: Shift + Movement
    -- Attack: Spacebar (idle/walk/run attack based on movement state)
    -- ═══════════════════════════════════════════════════════════════
    
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

    -- ⚔️ Attack input
    local spacePressed = love.keyboard.isDown("space")
    
    if spacePressed and not self.isAttacking then
        self.isAttacking = true
        
        -- Choose attack type based on current movement state
        local attackState = "attack"  -- Default: idle attack
        if isMoving then
            if isRunning then
                attackState = "run_attack"
            else
                attackState = "walk_attack"
            end
        end
        
        self:setState(attackState)
    end
    
    -- If spacebar is released while attacking, allow attack to finish
    if not spacePressed and self.isAttacking then
        -- Do nothing, let animation complete naturally
    end
    
    -- If attacking and user starts moving, switch to appropriate attack
    if self.isAttacking and spacePressed then
        if isMoving then
            if isRunning and self.state ~= "run_attack" then
                self:setState("run_attack")
            elseif not isRunning and self.state ~= "walk_attack" then
                self:setState("walk_attack")
            end
        elseif not isMoving and self.state ~= "attack" then
            -- User stopped moving while attacking, switch to idle attack
            self:setState("attack")
        end
    end

    -- 🏃 Movement and state transition (only if not attacking)
    if not self.isAttacking then
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
    else
        -- Continue movement during all attack animations
        local norm = math.sqrt(dx * dx + dy * dy)
        if norm > 0 then
            dx = dx / norm
            dy = dy / norm
            
            -- Apply speed based on attack type
            local speedMultiplier = 1
            if self.state == "run_attack" then
                speedMultiplier = 2  -- Running speed
            elseif self.state == "walk_attack" then
                speedMultiplier = 1  -- Walking speed
            else
                speedMultiplier = 0  -- Idle attack = no movement
            end
            
            self.x = self.x + dx * self.speed * speedMultiplier * dt
            self.y = self.y + dy * self.speed * speedMultiplier * dt
        end
    end

    -- 🎞️ Update animation
    if self.currentAnimation then
        self.currentAnimation:update(dt)
        
        -- Check if attack animation finished
        if self.isAttacking and self.currentAnimation.status == "paused" then
            -- If spacebar is still held, restart attack animation
            if spacePressed then
                self.currentAnimation:gotoFrame(1)
                self.currentAnimation:resume()
            else
                -- Spacebar released, end attack
                self.isAttacking = false
                self:setState("idle")
            end
        end
    end
end

-- 🟥 DRAW FUNCTION
function Samson:draw()
    if self.currentAnimation then
        self.currentAnimation:draw(self.images[self.state], self.x, self.y, 0, 3, 3, 32, 32)
    end
end


return Samson
