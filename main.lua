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
local maxEnemies = 1  -- Just one for debugging

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
function spawnEnemy(x, y, level)
    local enemy = Philistine:new(x, y, level or 1)
    
    -- Set up physics collider (dynamic = can collide with walls)
    enemy.physics = world:newBSGRectangleCollider(enemy.x, enemy.y, 15, 22.5, 4)
    enemy.physics:setFixedRotation(true)
    enemy.physics:setType('dynamic')  -- Can collide with walls
    enemy.physics:setFriction(0.8)
    enemy.physics:setLinearDamping(0.9)
    
    -- Set target and add to enemies list
    enemy.target = player
    table.insert(enemies, enemy)
    
    print("Spawned Level " .. (level or 1) .. " Philistine at (" .. x .. ", " .. y .. ")")
end

function love.update(dt)
    world:update(dt)  -- Update physics world
    environment:update(dt)  -- 🆕 Update environment (STI needs this)
    player:update(dt)
    
    -- 🎯 Spawn timer system
    if #enemies == 0 then
        spawnTimer = spawnTimer + dt
        if spawnTimer >= spawnInterval then
            spawnEnemy(616, 150, 1)
            spawnTimer = 0
        end
    end
    
    -- 🎯 Update enemies
    for i, enemy in ipairs(enemies) do
        enemy:update(dt)
        enemy:checkAttackDamage(player)
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
    world:draw()  -- Show colliders for debugging
    
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
