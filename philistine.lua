-- philistine.lua
-- Philistine enemy class with 3 progressive difficulty levels

local anim8 = require 'lib.anim8'

local Philistine = {}
Philistine.__index = Philistine

-- 🆕 Constructor
function Philistine:new(x, y, level)
    local self = setmetatable({}, Philistine)
    
    self.x = x
    self.y = y
    self.level = level or 1  -- 1, 2, or 3
    self.enemyType = "philistine_level_" .. self.level
    
    -- 🟢 Progressive stats based on level
    if self.level == 1 then
        self.health = 40
        self.maxHealth = 40
        self.speed = 50
        self.attackDamage = 12
        self.attackRange = 35
        self.detectionRange = 100
    elseif self.level == 2 then
        self.health = 60
        self.maxHealth = 60
        self.speed = 65
        self.attackDamage = 18
        self.attackRange = 40
        self.detectionRange = 120
    else -- level 3
        self.health = 80
        self.maxHealth = 80
        self.speed = 80
        self.attackDamage = 25
        self.attackRange = 45
        self.detectionRange = 140
    end
    
    self.width = 32
    self.height = 32
    
    -- 🟢 Movement and state control
    self.state = "idle"         -- Options: idle, walk, run, attack, hurt, death
    self.direction = "down"     -- Options: down, left, right, up
    self.isAttacking = false    -- Track if currently attacking
    self.isHurt = false         -- Track if currently hurt
    self.isDead = false         -- Track if dead
    self.lastAttackTime = 0     -- Attack cooldown timer
    self.attackCooldown = 1.5   -- Seconds between attacks
    
    -- 🎯 AI variables
    self.target = nil           -- Player reference
    self.lastSeenPlayerPos = nil
    self.patrolPoints = {}
    self.currentPatrolIndex = 1
    
    -- 🔧 Physics
    self.collider = nil         -- Will be set by main.lua
    
    -- 🖼️ Load sprite sheets based on level
    local levelPath = "assets/sprites/philistines/lvl" .. self.level .. "_philistine/"
    self.images = {}
    
    if self.level == 1 then
        -- Level 1: Basic Philistine (no run animations)
        self.images = {
            idle = love.graphics.newImage(levelPath .. "lvl1_idle.png"),
            walk = love.graphics.newImage(levelPath .. "lvl1_walk.png"),
            attack = love.graphics.newImage(levelPath .. "lvl1_attack.png"),
            walk_attack = love.graphics.newImage(levelPath .. "lvl1_walk_attack.png"),
            hurt = love.graphics.newImage(levelPath .. "lvl1_hurt.png"),
            death = love.graphics.newImage(levelPath .. "lvl1_death.png")
        }
    elseif self.level == 2 then
        -- Level 2: Intermediate Philistine (no run animations)
        self.images = {
            idle = love.graphics.newImage(levelPath .. "lvl2_idle.png"),
            walk = love.graphics.newImage(levelPath .. "lvl2_walk.png"),
            attack = love.graphics.newImage(levelPath .. "lvl2_attack.png"),
            walk_attack = love.graphics.newImage(levelPath .. "lvl2_walk_attack.png"),
            hurt = love.graphics.newImage(levelPath .. "lvl2_hurt.png"),
            death = love.graphics.newImage(levelPath .. "lvl2_death.png")
        }
    else -- level 3
        -- Level 3: Elite Philistine (has run animations)
        self.images = {
            idle = love.graphics.newImage(levelPath .. "lvl3_idle.png"),
            walk = love.graphics.newImage(levelPath .. "lvl3_walk.png"),
            run = love.graphics.newImage(levelPath .. "lvl3_run.png"),
            attack = love.graphics.newImage(levelPath .. "lvl3_attack.png"),
            walk_attack = love.graphics.newImage(levelPath .. "lvl3_walk_attack.png"),
            run_attack = love.graphics.newImage(levelPath .. "lvl3_run_attack.png"),
            hurt = love.graphics.newImage(levelPath .. "lvl3_hurt.png"),
            death = love.graphics.newImage(levelPath .. "lvl3_death.png")
        }
    end
    
    -- 🔲 Create animation grids
    local function makeGrid(image)
        return anim8.newGrid(32, 32, image:getWidth(), image:getHeight())
    end
    
    self.grids = {}
    for state, image in pairs(self.images) do
        self.grids[state] = makeGrid(image)
    end
    
    -- 🌀 Animations (progressive based on level)
    self.animations = {}
    
    if self.level <= 2 then
        -- Levels 1 & 2: Basic animations (no run)
        self.animations = {
            idle = {
                down = anim8.newAnimation(self.grids.idle('1-4', 1), 0.2),
                left = anim8.newAnimation(self.grids.idle('1-4', 2), 0.2),
                right = anim8.newAnimation(self.grids.idle('1-4', 3), 0.2),
                up = anim8.newAnimation(self.grids.idle('1-4', 4), 0.2)
            },
            walk = {
                down = anim8.newAnimation(self.grids.walk('1-6', 1), 0.15),
                left = anim8.newAnimation(self.grids.walk('1-6', 2), 0.15),
                right = anim8.newAnimation(self.grids.walk('1-6', 3), 0.15),
                up = anim8.newAnimation(self.grids.walk('1-6', 4), 0.15)
            },
            attack = {
                down = anim8.newAnimation(self.grids.attack('1-8', 1), 0.1, 'pauseAtEnd'),
                left = anim8.newAnimation(self.grids.attack('1-8', 2), 0.1, 'pauseAtEnd'),
                right = anim8.newAnimation(self.grids.attack('1-8', 3), 0.1, 'pauseAtEnd'),
                up = anim8.newAnimation(self.grids.attack('1-8', 4), 0.1, 'pauseAtEnd')
            },
            walk_attack = {
                down = anim8.newAnimation(self.grids.walk_attack('1-6', 1), 0.1, 'pauseAtEnd'),
                left = anim8.newAnimation(self.grids.walk_attack('1-6', 2), 0.1, 'pauseAtEnd'),
                right = anim8.newAnimation(self.grids.walk_attack('1-6', 3), 0.1, 'pauseAtEnd'),
                up = anim8.newAnimation(self.grids.walk_attack('1-6', 4), 0.1, 'pauseAtEnd')
            },
            hurt = {
                down = anim8.newAnimation(self.grids.hurt('1-4', 1), 0.2, 'pauseAtEnd'),
                left = anim8.newAnimation(self.grids.hurt('1-4', 2), 0.2, 'pauseAtEnd'),
                right = anim8.newAnimation(self.grids.hurt('1-4', 3), 0.2, 'pauseAtEnd'),
                up = anim8.newAnimation(self.grids.hurt('1-4', 4), 0.2, 'pauseAtEnd')
            },
            death = {
                down = anim8.newAnimation(self.grids.death('1-6', 1), 0.2, 'pauseAtEnd'),
                left = anim8.newAnimation(self.grids.death('1-6', 2), 0.2, 'pauseAtEnd'),
                right = anim8.newAnimation(self.grids.death('1-6', 3), 0.2, 'pauseAtEnd'),
                up = anim8.newAnimation(self.grids.death('1-6', 4), 0.2, 'pauseAtEnd')
            }
        }
    else
        -- Level 3: Elite animations (includes run)
        self.animations = {
            idle = {
                down = anim8.newAnimation(self.grids.idle('1-4', 1), 0.2),
                left = anim8.newAnimation(self.grids.idle('1-4', 2), 0.2),
                right = anim8.newAnimation(self.grids.idle('1-4', 3), 0.2),
                up = anim8.newAnimation(self.grids.idle('1-4', 4), 0.2)
            },
            walk = {
                down = anim8.newAnimation(self.grids.walk('1-6', 1), 0.15),
                left = anim8.newAnimation(self.grids.walk('1-6', 2), 0.15),
                right = anim8.newAnimation(self.grids.walk('1-6', 3), 0.15),
                up = anim8.newAnimation(self.grids.walk('1-6', 4), 0.15)
            },
            run = {
                down = anim8.newAnimation(self.grids.run('1-8', 1), 0.1),
                left = anim8.newAnimation(self.grids.run('1-8', 2), 0.1),
                right = anim8.newAnimation(self.grids.run('1-8', 3), 0.1),
                up = anim8.newAnimation(self.grids.run('1-8', 4), 0.1)
            },
            attack = {
                down = anim8.newAnimation(self.grids.attack('1-8', 1), 0.1, 'pauseAtEnd'),
                left = anim8.newAnimation(self.grids.attack('1-8', 2), 0.1, 'pauseAtEnd'),
                right = anim8.newAnimation(self.grids.attack('1-8', 3), 0.1, 'pauseAtEnd'),
                up = anim8.newAnimation(self.grids.attack('1-8', 4), 0.1, 'pauseAtEnd')
            },
            walk_attack = {
                down = anim8.newAnimation(self.grids.walk_attack('1-6', 1), 0.1, 'pauseAtEnd'),
                left = anim8.newAnimation(self.grids.walk_attack('1-6', 2), 0.1, 'pauseAtEnd'),
                right = anim8.newAnimation(self.grids.walk_attack('1-6', 3), 0.1, 'pauseAtEnd'),
                up = anim8.newAnimation(self.grids.walk_attack('1-6', 4), 0.1, 'pauseAtEnd')
            },
            run_attack = {
                down = anim8.newAnimation(self.grids.run_attack('1-8', 1), 0.08, 'pauseAtEnd'),
                left = anim8.newAnimation(self.grids.run_attack('1-8', 2), 0.08, 'pauseAtEnd'),
                right = anim8.newAnimation(self.grids.run_attack('1-8', 3), 0.08, 'pauseAtEnd'),
                up = anim8.newAnimation(self.grids.run_attack('1-8', 4), 0.08, 'pauseAtEnd')
            },
            hurt = {
                down = anim8.newAnimation(self.grids.hurt('1-4', 1), 0.2, 'pauseAtEnd'),
                left = anim8.newAnimation(self.grids.hurt('1-4', 2), 0.2, 'pauseAtEnd'),
                right = anim8.newAnimation(self.grids.hurt('1-4', 3), 0.2, 'pauseAtEnd'),
                up = anim8.newAnimation(self.grids.hurt('1-4', 4), 0.2, 'pauseAtEnd')
            },
            death = {
                down = anim8.newAnimation(self.grids.death('1-6', 1), 0.2, 'pauseAtEnd'),
                left = anim8.newAnimation(self.grids.death('1-6', 2), 0.2, 'pauseAtEnd'),
                right = anim8.newAnimation(self.grids.death('1-6', 3), 0.2, 'pauseAtEnd'),
                up = anim8.newAnimation(self.grids.death('1-6', 4), 0.2, 'pauseAtEnd')
            }
        }
    end
    
    -- ▶️ Set initial animation
    self.currentAnimation = self.animations.idle.down
    
    return self
end

-- 🟧 STATE SWITCH FUNCTION
function Philistine:setState(newState)
    if self.state ~= newState and self.animations[newState] and self.animations[newState][self.direction] then
        self.state = newState
        self.currentAnimation = self.animations[self.state][self.direction]
        self.currentAnimation:gotoFrame(1)
    end
end

-- 🧭 DIRECTION SWITCH FUNCTION
function Philistine:setDirection(newDir)
    if self.direction ~= newDir and self.animations[self.state] and self.animations[self.state][newDir] then
        self.direction = newDir
        self.currentAnimation = self.animations[self.state][self.direction]
        self.currentAnimation:gotoFrame(1)
    end
end

-- 🟨 UPDATE LOOP
function Philistine:update(dt)
    -- 💀 Death state - override everything
    if self.isDead then
        self.currentAnimation:update(dt)
        return -- Can't do anything when dead
    end
    
    -- 🩹 Hurt state - override movement and attacks
    if self.isHurt then
        self.currentAnimation:update(dt)
        
        -- Check if hurt animation finished
        if self.currentAnimation.status == "paused" then
            self.isHurt = false
            self:setState("idle")
        end
        return -- Can't move or attack while hurt
    end
    
    -- 🎞️ Update animation
    if self.currentAnimation then
        self.currentAnimation:update(dt)
        
        -- Check if attack animation finished
        if self.isAttacking and self.currentAnimation.status == "paused" then
            self.isAttacking = false
            self:setState("idle")
        end
    end
    
    -- 🔄 Sync position with collider
    if self.collider then
        self.x = self.collider:getX()
        self.y = self.collider:getY()
    end
    
    -- 🧠 AI Logic
    self:updateAI(dt)
end

-- 🧠 AI SYSTEM
function Philistine:updateAI(dt)
    if not self.target then return end
    
    local dx = self.target.x - self.x
    local dy = self.target.y - self.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    if distance <= self.detectionRange then
        -- Player detected!
        self.lastSeenPlayerPos = {x = self.target.x, y = self.target.y}
        
        -- Determine movement speed based on level
        local isRunning = false
        if self.level == 3 and distance > self.attackRange then
            isRunning = true -- Level 3 can run when chasing
        end
        
        -- Move towards player
        if self.collider then
            local moveX = (dx / distance) * self.speed
            local moveY = (dy / distance) * self.speed
            self.collider:setLinearVelocity(moveX, moveY)
        end
        
        -- Set direction based on movement
        if math.abs(dx) > math.abs(dy) then
            if dx > 0 then
                self:setDirection("right")
            else
                self:setDirection("left")
            end
        else
            if dy > 0 then
                self:setDirection("down")
            else
                self:setDirection("up")
            end
        end
        
        -- Set animation state based on movement and level
        if distance <= self.attackRange then
            -- Close enough to attack
            if love.timer.getTime() - self.lastAttackTime > self.attackCooldown then
                self:attack()
            end
        else
            -- Moving towards player
            if self.level == 3 and isRunning then
                self:setState("run")
            else
                self:setState("walk")
            end
        end
    else
        -- Player not detected - idle
        self:setState("idle")
        if self.collider then
            self.collider:setLinearVelocity(0, 0)
        end
    end
end

-- ⚔️ ATTACK FUNCTION
function Philistine:attack()
    if self.isDead or self.isAttacking then return end
    
    self.isAttacking = true
    self.lastAttackTime = love.timer.getTime()
    
    -- Choose attack animation based on movement and level
    local attackState = "attack" -- Default: idle attack
    
    if self.level == 3 and self.state == "run" then
        attackState = "run_attack"
    elseif self.state == "walk" then
        attackState = "walk_attack"
    end
    
    self:setState(attackState)
    
    -- Attack logic will be implemented with combat system
    print("Philistine Level " .. self.level .. " attacks!")
end

-- 💥 TAKE DAMAGE FUNCTION
function Philistine:takeDamage(amount)
    if self.isDead then return false end
    
    self.health = self.health - amount
    if self.health <= 0 then
        self.health = 0
        self.isDead = true
        self.isAttacking = false
        self.isHurt = false
        self.state = "death"
        self.currentAnimation = self.animations.death[self.direction]
        self.currentAnimation:gotoFrame(1)
        self.currentAnimation:resume()
        
        -- Stop movement
        if self.collider then
            self.collider:setLinearVelocity(0, 0)
        end
        
        return true
    else
        self.isHurt = true
        self.isAttacking = false
        self.state = "hurt"
        self.currentAnimation = self.animations.hurt[self.direction]
        self.currentAnimation:gotoFrame(1)
        self.currentAnimation:resume()
        return true
    end
end

-- 🟥 DRAW FUNCTION
function Philistine:draw()
    if self.currentAnimation then
        -- Draw Philistine sprite
        self.currentAnimation:draw(self.images[self.state], math.floor(self.x), math.floor(self.y), 0, 2, 2, 16, 16)
        
        -- Draw health bar above enemy
        local barWidth = 40
        local barHeight = 6
        local barX = self.x - barWidth/2
        local barY = self.y - 25
        
        -- Background (red)
        love.graphics.setColor(0.8, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
        
        -- Health (green)
        local healthPercent = self.health / self.maxHealth
        love.graphics.setColor(0.2, 0.8, 0.2, 0.8)
        love.graphics.rectangle("fill", barX, barY, barWidth * healthPercent, barHeight)
        
        -- Level indicator
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("L" .. self.level, self.x - 8, self.y - 40)
        
        -- Reset color
        love.graphics.setColor(1, 1, 1, 1)
    end
end

return Philistine
