local Samson = require("samson")
local Environment = require("environment")
local Philistine = require("philistine")
local wf = require('lib/windfield')

local player
local environment
local world
local enemies = {}
local spawnTimer = 0
local spawnInterval = 2.0
local maxEnemies = 3  -- One per spawn point

-- 🎯 Spawn points (3 locations around the map)
local spawnPoints = {
    {x = 626, y = 170, instant = false, spawnFrom = {x = 626, y = 140}},  -- Cave (top-center) - walk in from top
    {x = 990, y = 70, instant = false, spawnFrom = {x = 990, y = 40}},   -- Cave 2 (top-right) - walk in from top
    {x = 125, y = 50, instant = false, spawnFrom = {x = 125, y = 10}}  -- Top-left (sand hill) - walk in from top
}
local currentSpawnIndex = 1  -- Track which spawn point to use next

function love.load()
    love.window.setMode(1200, 720)  -- 🖥️ Match actual map content width (1200px)
    
    love.graphics.setDefaultFilter("nearest", "nearest") -- Pixel-perfect scaling
    
    -- Initialize Windfield physics world
    world = wf.newWorld(0, 0)
    
    environment = Environment:new()
    player = Samson:new(400, 300)
    player.environment = environment  -- Connect environment for collision detection
    
    -- Create player collider with smaller size and cave corners
    local colliderWidth = 15   -- Smaller width (was 32)
    local colliderHeight = 40  -- Adjusted height to cover full body (was 24)
    local caveAmount = 4       -- Cave corners (was 0)
    
    player.collider = world:newBSGRectangleCollider(player.x, player.y, colliderWidth, colliderHeight, caveAmount)
    player.collider:setFixedRotation(true)
    
    -- Create collision objects from Tiled map
    environment:createCollisionObjects(world)
end

-- 🎯 Spawn enemy function
function spawnEnemy(x, y, level, spawnData)
    local enemy = Philistine:new(x, y, level or 1)
    
    -- Set up physics collider (dynamic = can collide with walls)
    enemy.physics = world:newBSGRectangleCollider(enemy.x, enemy.y, 15, 22.5, 4)
    enemy.physics:setFixedRotation(true)
    enemy.physics:setType('dynamic')  -- Can collide with walls
    enemy.physics:setFriction(0.8)
    enemy.physics:setLinearDamping(0.9)
    
    -- Set target and add to enemies list
    enemy.target = player
    
    -- Handle spawn animation (walk-in + fade)
    if spawnData and not spawnData.instant then
        enemy.isSpawning = true
        enemy.spawnTarget = {x = x, y = y}  -- Where to walk to
        enemy.alpha = 0  -- Start invisible
        enemy.spawnFadeDuration = 0.8  -- Fade in over 0.8 seconds
        enemy.spawnFadeTimer = 0
        
        -- Move enemy to spawn-from position
        enemy.x = spawnData.spawnFrom.x
        enemy.y = spawnData.spawnFrom.y
        enemy.physics:setPosition(spawnData.spawnFrom.x, spawnData.spawnFrom.y)
        
        -- Disable collision with walls while spawning (ghost mode)
        enemy.physics:setType('kinematic')  -- Kinematic = no collision with static objects
        
        print("Spawned Level " .. (level or 1) .. " Philistine (walking in from " .. spawnData.spawnFrom.x .. ", " .. spawnData.spawnFrom.y .. " to " .. x .. ", " .. y .. ")")
    else
        print("Spawned Level " .. (level or 1) .. " Philistine at (" .. x .. ", " .. y .. ")")
    end
    
    table.insert(enemies, enemy)
end

function love.update(dt)
    world:update(dt)  -- Update physics world
    environment:update(dt)  -- 🆕 Update environment (STI needs this)
    
    -- Give player reference to enemies for attack damage
    player.enemiesRef = enemies
    
    player:update(dt)
    
    -- 🎯 Spawn timer system (spawn up to maxEnemies)
    if #enemies < maxEnemies then
        spawnTimer = spawnTimer + dt
        if spawnTimer >= spawnInterval then
            -- Get next spawn point
            local spawnPoint = spawnPoints[currentSpawnIndex]
            spawnEnemy(spawnPoint.x, spawnPoint.y, 1, spawnPoint)
            
            -- Move to next spawn point (rotate through all 4)
            currentSpawnIndex = currentSpawnIndex + 1
            if currentSpawnIndex > #spawnPoints then
                currentSpawnIndex = 1
            end
            
            spawnTimer = 0
        end
    end
    
    -- 🎯 Update enemies
    for i, enemy in ipairs(enemies) do
        enemy:update(dt)
        enemy:checkAttackDamage(player)
    end
    
    -- 🎯 Remove dead enemies after fade out completes
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]
        if enemy.dead and enemy.alpha <= 0 then
            -- Fade out finished, remove enemy
            if enemy.physics then
                enemy.physics:destroy()
            end
            table.remove(enemies, i)
            print("💀 Removed dead Philistine (faded out)")
        end
    end
end

function love.draw()
    -- Draw environment first (background layer)
    environment:draw()
    
    -- 🎯 Depth layering: Create entity list and sort by Y position
    local entities = {player}
    for i, enemy in ipairs(enemies) do
        table.insert(entities, enemy)
    end
    
    -- Sort by Y position (lower Y = drawn first/behind, higher Y = drawn last/in front)
    table.sort(entities, function(a, b)
        local aY = a.y
        local bY = b.y
        
        -- Use physics position if available (for enemies)
        if a.physics then
            aY = a.physics:getY()
        end
        if b.physics then
            bY = b.physics:getY()
        end
        
        return aY < bY
    end)
    
    -- Draw entities in sorted order (depth layering)
    for i, entity in ipairs(entities) do
        entity:draw()
    end
    
    -- Draw foreground layer (trees, rocks, etc.) on top of all entities
    environment:drawForeground()
    
    -- Draw physics world for debugging (temporary)
    -- world:draw()  -- Show colliders for debugging
    
    -- ═══════════════════════════════════════════════════════════════
    -- 🛠️ DEBUG INFO (REMOVE ONCE ENEMIES ARE IMPLEMENTED)
    -- ═══════════════════════════════════════════════════════════════
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Health: " .. player.health, 10, 10)
    love.graphics.print("State: " .. player.state, 10, 30)
    love.graphics.print("Direction: " .. player.direction, 10, 50)
    love.graphics.print("Enemies: " .. #enemies .. "/" .. maxEnemies, 10, 70)
    
    -- Show invincibility status
    if player.invincible then
        love.graphics.setColor(1, 1, 0)  -- Yellow
        love.graphics.print("⚡ INVINCIBLE ⚡ (" .. string.format("%.1f", player.invincibleTimer) .. "s)", 10, 90)
        love.graphics.setColor(1, 1, 1)  -- Reset color
    end
    
    love.graphics.print("=== DEBUG CONTROLS ===", 10, 110)
    love.graphics.print("H - Take 25 damage", 10, 130)
    love.graphics.print("R - Reset/Respawn", 10, 150)
    love.graphics.print("K - Instant kill", 10, 170)
    love.graphics.print("F - Full heal", 10, 190)
end

-- ═══════════════════════════════════════════════════════════════
-- 🛠️ DEBUG CONTROLS (REMOVE ONCE ENEMIES ARE IMPLEMENTED)
-- ═══════════════════════════════════════════════════════════════
function love.keypressed(key)
    if key == "h" then
        -- Take damage
        local damaged = player:takeDamage(25)
        if not damaged then
            print("⚡ Damage blocked! (I-frames active)")
        end
    elseif key == "r" then
        -- Reset/Respawn player
        local oldCollider = player.collider
        player = Samson:new(400, 300)
        player.environment = environment
        player.collider = world:newBSGRectangleCollider(player.x, player.y, 15, 40, 4)
        player.collider:setFixedRotation(true)
        player.collider:setFriction(0.8)
        player.collider:setLinearDamping(0.9)
        if oldCollider then
            oldCollider:destroy()
        end
        print("🔄 Player respawned!")
    elseif key == "k" then
        -- Instant kill (for testing death animation)
        player:takeDamage(999)
    elseif key == "f" then
        -- Full heal
        player.health = 100
        player.isDead = false
        player.isHurt = false
        player.invincible = false
        player.invincibleTimer = 0
        if player.state == "death" or player.state == "hurt" then
            player:setState("idle")
        end
        print("💚 Fully healed!")
    end
end
