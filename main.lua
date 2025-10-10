local Samson = require("samson")
local player

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest") -- Pixel-perfect scaling
    player = Samson:new(400, 300)
end

function love.update(dt)
    player:update(dt)
end

function love.draw()
    player:draw()
    
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
