local Samson = require("samson")
local Environment = require("environment")
local Philistine = require("philistine")
local UI = require("ui")
local HealthPack = require("healthpack")
local wf = require('lib/windfield')

-- 🎮 Game State
local gameState = "menu"  -- "menu" or "playing"

local player
local environment
local world
local ui
local enemies = {}
local healthPacks = {}  -- Track all health pack drops
local spawnTimer = 0
local spawnInterval = 2.0

-- 🌊 Wave System
local currentWave = 0  -- Start at 0 so wave 1 prompt shows
local totalKills = 0
local totalSpawns = 0  -- Track total spawns (max 10 per wave)
local enemiesPerSpawnPoint = 1  -- How many to spawn at each point

-- Wave thresholds (10 kills per wave)
local WAVE_1_END = 10   -- Switch to wave 2 at 10 kills
local WAVE_2_END = 20   -- Switch to wave 3 at 20 kills
local WAVE_3_END = 30   -- Victory at 30 kills
local MAX_SPAWNS_PER_WAVE = 10  -- Max 10 spawns per wave

-- Wave prompt tracking
local gameStarted = false  -- Track if game has started

-- 🎯 Spawn points (3 locations around the map)
local spawnPoints = {
    {x = 626, y = 170, instant = false, spawnFrom = {x = 626, y = 140}},  -- Cave (top-center) - walk in from top
    {x = 990, y = 70, instant = false, spawnFrom = {x = 990, y = 40}},   -- Cave 2 (top-right) - walk in from top
    {x = 123, y = 80, instant = false, spawnFrom = {x = 123, y = 20}}  -- Top-left (sand hill) - walk in from top
}
local currentSpawnIndex = 1  -- Track which spawn point to use next

function love.load()
    love.window.setMode(1200, 720)  -- 🖥️ Match actual map content width (1200px)
    
    love.graphics.setDefaultFilter("nearest", "nearest") -- Pixel-perfect scaling
    
    -- Initialize Windfield physics world
    world = wf.newWorld(0, 0)
    
    environment = Environment:new()
    ui = UI:new()  -- Initialize UI system
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
    
    -- Set target and world reference
    enemy.target = player
    enemy.world = world  -- For raycast wall detection
    
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
    -- Only update game when playing
    if gameState ~= "playing" then
        return
    end
    
    world:update(dt)  -- Update physics world
    environment:update(dt)  -- 🆕 Update environment (STI needs this)
    
    -- Give player reference to enemies for attack damage
    player.enemiesRef = enemies
    
    player:update(dt)
    
    -- 🌊 Update UI (including wave prompt)
    ui:updateWavePrompt(dt)
    
    -- 🌊 Wave System Logic
    -- Show wave 1 prompt at start
    if not gameStarted and not ui.wavePromptActive and currentWave == 0 then
        ui:showWavePrompt(1, function()
            gameStarted = true
            currentWave = 1
        end)
    end
    
    -- Update wave based on kills (only if game has started)
    if gameStarted then
        if currentWave == 1 and totalKills >= WAVE_1_END and not ui.wavePromptActive then
            ui:showWavePrompt(2, function()
                -- Reset spawn counter for wave 2
                totalSpawns = 0
            end)
            currentWave = 2
        elseif currentWave == 2 and totalKills >= WAVE_2_END and not ui.wavePromptActive then
            ui:showWavePrompt(3, function()
                -- Reset spawn counter for wave 3
                totalSpawns = 0
            end)
            currentWave = 3
        elseif currentWave == 3 and totalKills >= WAVE_3_END and not ui.wavePromptActive then
            ui:showWavePrompt("victory")
        end
    end
    
    -- 🎯 Spawn timer system (only if game has started, no prompt showing, and under spawn limit)
    local maxEnemies = #spawnPoints * enemiesPerSpawnPoint
    if gameStarted and not ui.wavePromptActive and #enemies < maxEnemies and totalSpawns < MAX_SPAWNS_PER_WAVE and totalKills < WAVE_3_END then
        spawnTimer = spawnTimer + dt
        if spawnTimer >= spawnInterval then
            -- Get next spawn point
            local spawnPoint = spawnPoints[currentSpawnIndex]
            
            -- Spawn multiple enemies at this point based on current wave
            for i = 1, enemiesPerSpawnPoint do
                spawnEnemy(spawnPoint.x, spawnPoint.y, currentWave, spawnPoint)
            end
            
            -- Increment spawn counter
            totalSpawns = totalSpawns + 1
            
            -- Move to next spawn point
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
            -- 20% chance for regular heart, 8% chance for BIG heart
            local dropChance = math.random()
            local ex, ey = enemy.physics:getX(), enemy.physics:getY()
            
            if dropChance <= 0.08 then  -- 8% - BIG heart (heals more)
                local healthPack = HealthPack:new(ex, ey, true)  -- true = big heart
                table.insert(healthPacks, healthPack)
                print("✨💖 BIG Health pack dropped!")
            elseif dropChance <= 0.28 then  -- 20% - Regular heart (8% + 20% = 28%)
                local healthPack = HealthPack:new(ex, ey, false)  -- false = regular heart
                table.insert(healthPacks, healthPack)
                print("✨ Health pack dropped!")
            end
            -- Else: 72% chance of no drop
            
            -- Fade out finished, remove enemy
            if enemy.physics then
                enemy.physics:destroy()
            end
            table.remove(enemies, i)
            
            -- Increment kill counter
            totalKills = totalKills + 1
            print("💀 Kill #" .. totalKills .. " (Wave " .. currentWave .. ")")
        end
    end
    
    -- 💚 Update health packs
    for i, pack in ipairs(healthPacks) do
        pack:update(dt)
    end
    
    -- 💚 Check health pack pickups
    for i = #healthPacks, 1, -1 do
        local pack = healthPacks[i]
        if pack:checkPickup(player) then
            -- Heal player
            player.health = math.min(player.health + pack.healAmount, player.maxHealth)
            table.remove(healthPacks, i)
            print("💚 Picked up health pack! Health: " .. player.health)
        elseif pack.collected then
            -- Despawned (time expired)
            table.remove(healthPacks, i)
        end
    end
end

function love.draw()
    -- 🎮 MENU STATE
    if gameState == "menu" then
        -- Draw background
        environment:draw()
        environment:drawForeground()
        
        -- Draw menu UI
        ui:drawMenu()
        return
    end
    
    -- 🎮 PLAYING STATE
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
    
    -- 💚 Draw health packs (on ground, before foreground)
    for i, pack in ipairs(healthPacks) do
        pack:draw()
    end
    
    -- Draw foreground layer (trees, rocks, etc.) on top of all entities
    environment:drawForeground()
    
    -- ═══════════════════════════════════════════════════════════════
    -- 💚 UI LAYER - Health Bar, Wave Prompts, Kills Banner
    -- ═══════════════════════════════════════════════════════════════
    ui:drawHealth(player.health, player.maxHealth, 20, 20)
    ui:drawKillsBanner(totalKills, WAVE_3_END)
    ui:drawWavePrompt()
    
    -- Draw physics world for debugging (temporary)
    -- world:draw()  -- Show colliders for debugging
    
    -- ═══════════════════════════════════════════════════════════════
    -- 🛠️ DEBUG INFO (COMMENTED OUT FOR SCREENSHOTS)
    -- ═══════════════════════════════════════════════════════════════
    --[[ Use smaller font for debug info
    local debugFont = love.graphics.newFont(10)
    love.graphics.setFont(debugFont)
    
    love.graphics.setColor(1, 1, 1)
    local debugY = 150  -- Just below the hearts
    love.graphics.print("State: " .. player.state, 10, debugY)
    love.graphics.print("Direction: " .. player.direction, 10, debugY + 15)
    
    -- Wave system info
    love.graphics.setColor(1, 0.8, 0.2)  -- Gold color for wave info
    love.graphics.print("WAVE " .. currentWave .. " | Kills: " .. totalKills .. "/30", 10, debugY + 30)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Enemies: " .. #enemies .. "/" .. (#spawnPoints * enemiesPerSpawnPoint), 10, debugY + 45)
    
    -- Show invincibility status
    if player.invincible then
        love.graphics.setColor(1, 1, 0)  -- Yellow
        love.graphics.print("⚡ INVINCIBLE ⚡ (" .. string.format("%.1f", player.invincibleTimer) .. "s)", 10, debugY + 60)
        love.graphics.setColor(1, 1, 1)  -- Reset color
    end
    
    love.graphics.print("=== DEBUG CONTROLS ===", 10, debugY + 75)
    love.graphics.print("H - Take 25 damage", 10, debugY + 90)
    love.graphics.print("R - Reset/Respawn", 10, debugY + 105)
    love.graphics.print("K - Instant kill", 10, debugY + 120)
    love.graphics.print("F - Full heal", 10, debugY + 135)
    --]]
end

-- ═══════════════════════════════════════════════════════════════
-- 🛠️ DEBUG CONTROLS (REMOVE ONCE ENEMIES ARE IMPLEMENTED)
-- ═══════════════════════════════════════════════════════════════
function love.keypressed(key)
    -- Menu: Start game
    if gameState == "menu" and key == "return" then
        gameState = "playing"
        print("🎮 Game started!")
        return
    end
    
    -- Game controls (only when playing)
    if gameState ~= "playing" then
        return
    end
    
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
        
        -- Update all enemies to target the new player
        for i, enemy in ipairs(enemies) do
            enemy.target = player
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
