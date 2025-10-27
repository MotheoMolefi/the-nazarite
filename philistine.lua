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
    self.deathFadeDelay = 0.6  -- Wait before fading (seconds)
    self.deathFadeTimer = 0  -- Timer for fade out effect
    self.deathFadeDuration = 0.5  -- How long to fade (seconds)
    self.alpha = 1.0  -- Transparency (1 = solid, 0 = invisible)
    self.chase = true
    self.dir = {x = 0, y = 1}  -- Movement direction vector
    self.animTimer = 0  -- Alert timer
    self.direction = "down"  -- Direction for animation (like Samson)
    
    -- ⚔️ Attack system (like Samson)
    self.isAttacking = false
    self.attackRange = 60  -- Distance to start attacking
    self.attackDamage = 10  -- Damage per attack
    self.lastAttackDamageFrame = 0  -- Track which frames have dealt damage
    self.attackCooldown = 0  -- Cooldown before can attack again
    self.minCooldown = 1.5  -- Minimum seconds between attacks
    self.maxCooldown = 3.0  -- Maximum seconds between attacks
    
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
            down  = anim8.newAnimation(self.grids.attack('1-7', 1), 0.1, 'pauseAtEnd'),
            left  = anim8.newAnimation(self.grids.attack('1-7', 2), 0.1, 'pauseAtEnd'),
            right = anim8.newAnimation(self.grids.attack('1-7', 3), 0.1, 'pauseAtEnd'),
            up    = anim8.newAnimation(self.grids.attack('1-7', 4), 0.1, 'pauseAtEnd'),
        },
        walk_attack = {
            down  = anim8.newAnimation(self.grids.walk_attack('1-6', 1), 0.1, 'pauseAtEnd'),
            left  = anim8.newAnimation(self.grids.walk_attack('1-6', 2), 0.1, 'pauseAtEnd'),
            right = anim8.newAnimation(self.grids.walk_attack('1-6', 3), 0.1, 'pauseAtEnd'),
            up    = anim8.newAnimation(self.grids.walk_attack('1-6', 4), 0.1, 'pauseAtEnd'),
        },
            hurt = {
                down  = anim8.newAnimation(self.grids.hurt('1-5', 1), 0.1, 'pauseAtEnd'),
                left  = anim8.newAnimation(self.grids.hurt('1-5', 2), 0.1, 'pauseAtEnd'),
                right = anim8.newAnimation(self.grids.hurt('1-5', 3), 0.1, 'pauseAtEnd'),
                up    = anim8.newAnimation(self.grids.hurt('1-5', 4), 0.1, 'pauseAtEnd'),
            },
        death = {
            down  = anim8.newAnimation(self.grids.death('1-7', 1), 0.15, 'pauseAtEnd'),
            left  = anim8.newAnimation(self.grids.death('1-7', 2), 0.15, 'pauseAtEnd'),
            right = anim8.newAnimation(self.grids.death('1-7', 3), 0.15, 'pauseAtEnd'),
            up    = anim8.newAnimation(self.grids.death('1-7', 4), 0.15, 'pauseAtEnd'),
        }
    }
    
    
    -- ▶️ Set initial animation (exact same way as Samson)
    self.currentAnimation = self.animations.idle.down
    
    return self
end

function Philistine:setDirection(newDir)
    if self.direction ~= newDir and self.currentAnimation then
        self.direction = newDir
        
        -- Update to correct directional animation based on current state
        if self.isAttacking then
            self.currentAnimation = self.animations.walk_attack[newDir]
        elseif self.currentAnimation == self.animations.idle.down or
               self.currentAnimation == self.animations.idle.left or
               self.currentAnimation == self.animations.idle.right or
               self.currentAnimation == self.animations.idle.up then
            self.currentAnimation = self.animations.idle[newDir]
        else
            self.currentAnimation = self.animations.walk[newDir]
        end
        
        self.currentAnimation:gotoFrame(1)
    end
end

-- 🗡️ Check if attack should damage player
function Philistine:checkAttackDamage(player)
    if not self.isAttacking or not self.currentAnimation or not self.physics then
        return
    end
    
    -- Don't damage dead players
    if player.isDead then
        return
    end
    
    -- Get positions
    local ex, ey = self.physics:getX(), self.physics:getY()
    local px, py = player.x, player.y
    
    -- Dynamic hit range: extend forward in attack direction
    local hitRange = 50  -- Base range
    local directionOffset = 0
    
    -- Extend range in attack direction (sword reach)
    if self.direction == "down" then
        directionOffset = 20  -- Sword extends downward
    elseif self.direction == "up" then
        directionOffset = 20  -- Sword extends upward
    elseif self.direction == "left" then
        directionOffset = 20  -- Sword extends left
    elseif self.direction == "right" then
        directionOffset = 20  -- Sword extends right
    end
    
    local totalHitRange = hitRange + directionOffset
    
    local distance = math.sqrt((px - ex)^2 + (py - ey)^2)
    
    -- Check if close enough and dealing damage on first check
    if distance < totalHitRange and self.lastAttackDamageFrame == 0 then
        -- Apply damage with knockback (pass Philistine's position)
        player:takeDamage(self.attackDamage, ex, ey)
        self.lastAttackDamageFrame = 1
        print("Philistine hit Samson for " .. self.attackDamage .. " damage!")
    elseif distance >= totalHitRange and self.lastAttackDamageFrame > 0 then
        -- Reset when player moves away
        self.lastAttackDamageFrame = 0
    end
end

-- 🟨 UPDATE LOOP (simple like Samson)
function Philistine:update(dt)
    -- Check if death animation is playing
    if self.dead then
        -- Update death animation
        if self.currentAnimation then
            self.currentAnimation:update(dt)
            
            -- Check if death animation finished
            if self.currentAnimation.status == "paused" then
                -- Wait for delay, then start fading out
                self.deathFadeTimer = self.deathFadeTimer + dt
                
                if self.deathFadeTimer > self.deathFadeDelay then
                    -- Calculate fade (subtract delay from timer)
                    local fadeProgress = (self.deathFadeTimer - self.deathFadeDelay) / self.deathFadeDuration
                    self.alpha = 1.0 - fadeProgress
                    
                    -- Clamp alpha to 0-1 range
                    if self.alpha < 0 then
                        self.alpha = 0
                    end
                end
            end
        end
        return  -- Don't do anything else while dead
    end
    
    -- Check if hurt animation is playing
    if self.currentAnimation == self.animations.hurt.down or
       self.currentAnimation == self.animations.hurt.left or
       self.currentAnimation == self.animations.hurt.right or
       self.currentAnimation == self.animations.hurt.up then
        -- Update hurt animation
        self.currentAnimation:update(dt)
        
        -- Check if hurt animation finished
        if self.currentAnimation.status == "paused" then
            -- Return to idle
            local newAnimation = self.animations.idle[self.direction]
            self.currentAnimation = newAnimation
            self.currentAnimation:gotoFrame(1)
            self.currentAnimation:resume()
        end
        return  -- Don't do anything else while hurt
    end
    
    -- Check if target is dead
    if self.target and self.target.isDead then
        -- Stop attacking and go idle
        self.isAttacking = false
        self.physics:setLinearVelocity(0, 0)
        local newAnimation = self.animations.idle[self.direction]
        if self.currentAnimation ~= newAnimation then
            self.currentAnimation = newAnimation
            self.currentAnimation:gotoFrame(1)
        end
        return
    end
    
    -- Update cooldown
    if self.attackCooldown > 0 then
        self.attackCooldown = self.attackCooldown - dt
    end
    
    -- Simple detection and chase
    if self.physics and self.target then
        local ex, ey = self.physics:getX(), self.physics:getY()
        local px, py = self.target.x, self.target.y
        local distance = math.sqrt((px - ex)^2 + (py - ey)^2)
        
        -- Detection radius
        if distance < self.viewDistance then
            -- Always chase player
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
                
                -- Set direction based on movement (exact same as Samson)
                local newDir = "down"
                if math.abs(dx) > math.abs(dy) then
                    newDir = dx > 0 and "right" or "left"
                    self.scaleX = 1
                else
                    newDir = dy > 0 and "down" or "up"
                end
                
                -- Use setDirection helper
                self:setDirection(newDir)
            end
            
            -- Update animation based on state and direction (direction takes priority)
            if distance < self.attackRange and not self.isAttacking and self.attackCooldown <= 0 then
                -- Start attacking
                print("🗡️ ATTACK CONDITIONS MET! Distance: " .. distance .. ", isAttacking: " .. tostring(self.isAttacking) .. ", cooldown: " .. self.attackCooldown)
                self.isAttacking = true
                self.lastAttackDamageFrame = 0  -- Reset damage counter for new attack
                
                local newAnimation = self.animations.walk_attack[self.direction]
                self.currentAnimation = newAnimation
                self.currentAnimation:gotoFrame(1)
                self.currentAnimation:resume()  -- Make sure it starts fresh!
                print("🗡️ Attack animation started!")
            elseif distance >= self.attackRange and self.isAttacking then
                -- Out of range, stop attacking
                self.isAttacking = false
                local newAnimation = self.animations.walk[self.direction]
                if self.currentAnimation ~= newAnimation then
                    self.currentAnimation = newAnimation
                    self.currentAnimation:gotoFrame(1)
                end
                print("Philistine stopped attacking (out of range)")
            elseif not self.isAttacking then
                -- Not attacking, use walk animation
                local newAnimation = self.animations.walk[self.direction]
                if self.currentAnimation ~= newAnimation then
                    self.currentAnimation = newAnimation
                    self.currentAnimation:gotoFrame(1)
                end
            end
        else
            -- Stop movement when not chasing
            self.physics:setLinearVelocity(0, 0)
            self.isAttacking = false
            
            -- Switch to idle animation when not chasing
            local newAnimation = self.animations.idle[self.direction]
            if self.currentAnimation ~= newAnimation then
                self.currentAnimation = newAnimation
                self.currentAnimation:gotoFrame(1)
            end
        end
        
        -- Handle attack animation finishing - switch to walk
        if self.isAttacking and self.currentAnimation and self.currentAnimation.status == "paused" then
            -- Attack animation finished - always switch back to walk
            self.isAttacking = false
            
            -- Random cooldown between min and max
            local randomCooldown = self.minCooldown + math.random() * (self.maxCooldown - self.minCooldown)
            self.attackCooldown = randomCooldown
            
            -- Switch to walk animation and resume it
            local newAnimation = self.animations.walk[self.direction]
            self.currentAnimation = newAnimation
            self.currentAnimation:gotoFrame(1)
            self.currentAnimation:resume()  -- Make sure it's playing!
            
            print("Philistine attack finished, returning to walk (cooldown: " .. string.format("%.1f", randomCooldown) .. "s)")
        end
        
        -- Update animation (ALWAYS at the end, like Samson)
        if self.currentAnimation then
            self.currentAnimation:update(dt)
        end
    end
end


-- 💥 TAKE DAMAGE FUNCTION
function Philistine:takeDamage(amount, attackerX, attackerY)
    if self.dead then return false end  -- Can't damage the dead
    
    -- Take damage
    self.health = self.health - amount
    
    if self.health <= 0 then
        -- Death
        self.health = 0
        self.dead = true
        self.isAttacking = false
        
        -- Stop movement
        if self.physics then
            self.physics:setLinearVelocity(0, 0)
        end
        
        -- Switch to death animation
        self.currentAnimation = self.animations.death[self.direction]
        self.currentAnimation:gotoFrame(1)
        self.currentAnimation:resume()
        
        print("💀 Philistine killed!")
    else
        -- Hurt - play hurt animation
        self.isAttacking = false  -- Cancel attack when hurt
        
        -- Apply knockback away from attacker
        if self.physics and attackerX and attackerY then
            local ex, ey = self.physics:getX(), self.physics:getY()
            local dx = ex - attackerX
            local dy = ey - attackerY
            local distance = math.sqrt(dx^2 + dy^2)
            
            if distance > 0 then
                -- Normalize and apply knockback force
                dx = dx / distance
                dy = dy / distance
                local knockbackForce = 200  -- Adjust this for stronger/weaker knockback
                self.physics:applyLinearImpulse(dx * knockbackForce, dy * knockbackForce)
            end
        end
        
        -- Switch to hurt animation
        self.currentAnimation = self.animations.hurt[self.direction]
        self.currentAnimation:gotoFrame(1)
        self.currentAnimation:resume()
        
        print("🩸 Philistine took " .. amount .. " damage! (" .. self.health .. "/" .. self.maxHealth .. " HP)")
    end
    
    return true  -- Damage was applied
end

-- 🟥 DRAW FUNCTION (chase and attack)
function Philistine:draw()
    if self.currentAnimation and self.physics then
        local ex, ey = self.physics:getX(), self.physics:getY()
        
        -- Choose image based on current animation (like Samson)
        local imageToUse = self.images.idle
        if self.currentAnimation == self.animations.walk[self.direction] then
            imageToUse = self.images.walk
        elseif self.currentAnimation == self.animations.walk_attack[self.direction] then
            imageToUse = self.images.walk_attack
        elseif self.currentAnimation == self.animations.hurt[self.direction] then
            imageToUse = self.images.hurt
        elseif self.currentAnimation == self.animations.death[self.direction] then
            imageToUse = self.images.death
        end
        
        -- Apply transparency (for death fade)
        love.graphics.setColor(1, 1, 1, self.alpha)
        
        -- Draw with scaling (exact same as Samson)
        self.currentAnimation:draw(imageToUse, math.floor(ex), math.floor(ey + 4), 0, 2, 2, 32, 32)
        
        -- Reset color
        love.graphics.setColor(1, 1, 1, 1)
    end
end

return Philistine