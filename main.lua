local Samson = require("samson")
local Environment = require("environment")
local wf = require('lib/windfield')

local player
local environment
local world

function love.load()
    love.window.setMode(1200, 720)  -- 🖥️ Match actual map content width (1200px)
    
    love.graphics.setDefaultFilter("nearest", "nearest") -- Pixel-perfect scaling
    
    -- Initialize Windfield physics world
    world = wf.newWorld(0, 0)
    
    environment = Environment:new()
    player = Samson:new(400, 300)
    player.environment = environment  -- Connect environment for collision detection
    
    -- Create player collider with smaller size and cave corners
    local colliderWidth = 20   -- Smaller width (was 32)
    local colliderHeight = 50  -- Adjusted height to cover full body (was 24)
    local caveAmount = 4       -- Cave corners (was 0)
    
    player.collider = world:newBSGRectangleCollider(player.x, player.y, colliderWidth, colliderHeight, caveAmount)
    player.collider:setFixedRotation(true)
    
    -- Create collision objects from Tiled map
    environment:createCollisionObjects(world)
end

function love.update(dt)
    world:update(dt)  -- Update physics world
    environment:update(dt)  -- 🆕 Update environment (STI needs this)
    player:update(dt)
end

function love.draw()
    -- Draw environment first (background layer)
    environment:draw()
    
    -- Draw player on top
    player:draw()
    
    -- Draw foreground layer (trees, rocks, etc.) on top of player
    environment:drawForeground()
    
    -- Draw physics world for debugging (temporary)
    -- world:draw()  -- Commented out to hide debug colliders
    
    -- ═══════════════════════════════════════════════════════════════
    -- 🛠️ DEBUG INFO (REMOVE ONCE ENEMIES ARE IMPLEMENTED)
    -- ═══════════════════════════════════════════════════════════════
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Health: " .. player.health, 10, 10)
    love.graphics.print("State: " .. player.state, 10, 30)
    love.graphics.print("Direction: " .. player.direction, 10, 50)
    
    -- Show invincibility status
    if player.invincible then
        love.graphics.setColor(1, 1, 0)  -- Yellow
        love.graphics.print("⚡ INVINCIBLE ⚡ (" .. string.format("%.1f", player.invincibleTimer) .. "s)", 10, 70)
        love.graphics.setColor(1, 1, 1)  -- Reset color
    end
    
    love.graphics.print("=== DEBUG CONTROLS ===", 10, 90)
    love.graphics.print("H - Take 25 damage", 10, 110)
    love.graphics.print("R - Reset/Respawn", 10, 130)
    love.graphics.print("K - Instant kill", 10, 150)
    love.graphics.print("F - Full heal", 10, 170)
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
        player = Samson:new(400, 300)
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
