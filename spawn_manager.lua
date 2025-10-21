-- spawn_manager.lua
-- Handles Philistine spawning from caves and map borders

local SpawnManager = {}
SpawnManager.__index = SpawnManager

function SpawnManager:new()
    local self = setmetatable({}, SpawnManager)
    
    -- 🏛️ Spawn points (coordinates in world space)
    self.spawnPoints = {
        -- Cave spawns (enemies spawn inside caves)
        cave1 = {x = 600, y = 200, type = "cave"},      -- Upper central cave
        cave2 = {x = 1000, y = 500, type = "cave"},     -- Lower right cave
        
        -- Border spawns (enemies spawn off-screen and walk in)
        border_top_left = {x = 100, y = -50, type = "border"},     -- Near sand hill
        border_top = {x = 600, y = -50, type = "border"},          -- Top center
        border_right = {x = 1250, y = 300, type = "border"},       -- Right side
        border_bottom = {x = 600, y = 750, type = "border"}        -- Bottom
    }
    
    -- 🎯 Spawn settings
    self.spawnTimer = 0
    self.spawnInterval = 3.0  -- seconds between spawns
    self.maxEnemies = 10       -- maximum enemies on screen
    self.currentEnemies = 0
    
    -- 📊 Spawn progression
    self.waveNumber = 1
    self.enemiesSpawned = 0
    self.enemiesKilled = 0
    
    return self
end

function SpawnManager:update(dt, enemies, world, player)
    self.spawnTimer = self.spawnTimer + dt
    
    -- Count current living enemies
    self.currentEnemies = 0
    for i, enemy in ipairs(enemies) do
        if not enemy.isDead then
            self.currentEnemies = self.currentEnemies + 1
        end
    end
    
    -- Spawn new enemy if conditions are met
    if self.spawnTimer >= self.spawnInterval and self.currentEnemies < self.maxEnemies then
        self:spawnEnemy(enemies, world, player)
        self.spawnTimer = 0
    end
end

function SpawnManager:spawnEnemy(enemies, world, player)
    -- 🎲 Choose spawn point
    local spawnPoint = self:chooseSpawnPoint()
    
    -- 🎯 Choose enemy level based on wave progression
    local enemyLevel = self:chooseEnemyLevel()
    
    -- 🏛️ Create new Philistine
    local Philistine = require("philistine")
    local enemy = Philistine:new(spawnPoint.x, spawnPoint.y, enemyLevel)
    
    -- 🔧 Set up physics collider
    enemy.collider = world:newBSGRectangleCollider(enemy.x, enemy.y, enemy.width, enemy.height, 2)
    enemy.collider:setFixedRotation(true)
    enemy.collider:setType('dynamic')
    
    -- 🎯 Set target to player
    enemy.target = player
    
    -- 📝 Add to enemies list
    table.insert(enemies, enemy)
    
    -- 📊 Update stats
    self.enemiesSpawned = self.enemiesSpawned + 1
    
    print("Spawned Level " .. enemyLevel .. " Philistine at " .. spawnPoint.type .. " spawn point")
end

function SpawnManager:chooseSpawnPoint()
    -- 🎲 Randomly choose between cave and border spawns
    local spawnTypes = {"cave", "border"}
    local chosenType = spawnTypes[math.random(1, #spawnTypes)]
    
    -- Get all spawn points of chosen type
    local availableSpawns = {}
    for name, point in pairs(self.spawnPoints) do
        if point.type == chosenType then
            table.insert(availableSpawns, point)
        end
    end
    
    -- Return random spawn point of chosen type
    return availableSpawns[math.random(1, #availableSpawns)]
end

function SpawnManager:chooseEnemyLevel()
    -- 📈 Progressive difficulty based on wave number
    if self.waveNumber <= 2 then
        return 1  -- Only Level 1 enemies for first 2 waves
    elseif self.waveNumber <= 5 then
        return math.random(1, 2)  -- Mix of Level 1 and 2
    else
        return math.random(1, 3)  -- All levels possible
    end
end

function SpawnManager:onEnemyKilled()
    self.enemiesKilled = self.enemiesKilled + 1
    
    -- 🏆 Check for wave completion
    if self.enemiesKilled >= 10 then  -- 10 enemies per wave
        self:nextWave()
    end
end

function SpawnManager:nextWave()
    self.waveNumber = self.waveNumber + 1
    self.enemiesKilled = 0
    
    -- 📈 Increase difficulty
    self.maxEnemies = math.min(self.maxEnemies + 2, 20)  -- Cap at 20
    self.spawnInterval = math.max(self.spawnInterval - 0.2, 1.0)  -- Faster spawning
    
    print("🌊 WAVE " .. self.waveNumber .. " BEGINS!")
    print("Max enemies: " .. self.maxEnemies .. " | Spawn rate: " .. self.spawnInterval .. "s")
end

function SpawnManager:draw()
    -- 🎯 Draw spawn point indicators (for debugging)
    love.graphics.setColor(1, 0, 0, 0.5)  -- Semi-transparent red
    
    for name, point in pairs(self.spawnPoints) do
        if point.type == "cave" then
            -- Draw cave spawn points
            love.graphics.rectangle("fill", point.x - 10, point.y - 10, 20, 20)
        else
            -- Draw border spawn points
            love.graphics.circle("fill", point.x, point.y, 8)
        end
    end
    
    -- 📊 Draw wave info
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Wave: " .. self.waveNumber, 10, 400)
    love.graphics.print("Enemies: " .. self.currentEnemies .. "/" .. self.maxEnemies, 10, 420)
    love.graphics.print("Killed: " .. self.enemiesKilled .. "/10", 10, 440)
    
    love.graphics.setColor(1, 1, 1, 1)  -- Reset color
end

return SpawnManager
