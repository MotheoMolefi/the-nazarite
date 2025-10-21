-- environment.lua

local sti = require("lib.sti")

local Environment = {}
Environment.__index = Environment

function Environment:new()
    local self = setmetatable({}, Environment)

    print("Loading Tiled map...")
    self.map = sti("assets/environment/desertMap.lua")
    print("Tiled map loaded!")
    
    -- Initialize collision objects array
    self.objectColliders = {}

    return self
end

function Environment:createCollisionObjects(world)
    -- Create collision objects from Tiled map
    if not self.map then
        print("ERROR: No map loaded!")
        return
    end
    
    -- Debug: Print all available layers
    print("Available layers:")
    for i, layer in ipairs(self.map.layers) do
        print("  " .. i .. ": " .. layer.name .. " (type: " .. (layer.type or "unknown") .. ")")
    end
    
    local collisionLayer = self.map.layers["Collision Detection Layer"]
    if not collisionLayer then
        print("ERROR: 'Collision Detection Layer' not found!")
        return
    end
    
    if not collisionLayer.objects then
        print("ERROR: Collision layer has no objects! (It might be a tile layer, not an object layer)")
        return
    end
    
    print("Creating collision objects from Tiled map...")
    print("Found " .. #collisionLayer.objects .. " objects in collision layer")
    
    for i, obj in pairs(collisionLayer.objects) do
        local objectCollider
        
        if obj.shape == "rectangle" then
            -- Handle rectangle objects
            objectCollider = world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height)
        elseif obj.shape == "polygon" and obj.polygon then
            -- Handle polygon objects - convert to rectangle for now
            -- TODO: Implement proper polygon support later
            objectCollider = world:newRectangleCollider(obj.x, obj.y, obj.width or 32, obj.height or 32)
        else
            -- Fallback to rectangle for unknown shapes
            print("WARNING: Unknown object shape '" .. (obj.shape or "nil") .. "', using rectangle")
            objectCollider = world:newRectangleCollider(obj.x, obj.y, obj.width or 32, obj.height or 32)
        end
        
        objectCollider:setType('static')
        table.insert(self.objectColliders, objectCollider)
    end
    
    -- Add invisible walls around the map boundaries
    local mapWidth = self.map.width * self.map.tilewidth
    local mapHeight = self.map.height * self.map.tileheight
    local wallThickness = 32 -- Thickness of the invisible walls
    
    -- Top wall
    local topWall = world:newRectangleCollider(0, -wallThickness, mapWidth, wallThickness)
    topWall:setType('static')
    table.insert(self.objectColliders, topWall)
    
    -- Bottom wall
    local bottomWall = world:newRectangleCollider(0, mapHeight, mapWidth, wallThickness)
    bottomWall:setType('static')
    table.insert(self.objectColliders, bottomWall)
    
    -- Left wall
    local leftWall = world:newRectangleCollider(-wallThickness, 0, wallThickness, mapHeight)
    leftWall:setType('static')
    table.insert(self.objectColliders, leftWall)
    
    -- Right wall
    local rightWall = world:newRectangleCollider(mapWidth, 0, wallThickness, mapHeight)
    rightWall:setType('static')
    table.insert(self.objectColliders, rightWall)
    
    print("Created " .. #self.objectColliders .. " collision objects!")
    print("Added invisible boundary walls around map edges")
end

function Environment:update(dt)
    if self.map then
        self.map:update(dt)
    end
end

function Environment:draw()
    if self.map then
        -- Draw background layers (everything except collision and foreground)
        for i, layer in ipairs(self.map.layers) do
            if layer.name ~= "Collision Detection Layer" and layer.name ~= "Foreground Layer" then
                self.map:drawLayer(layer, math.floor(0), math.floor(0))
            end
        end
        
        -- 🐛 DEBUG: Show collision info (commented out for gameplay)
        -- love.graphics.setColor(1, 0, 0, 0.5) -- Semi-transparent red
        -- love.graphics.print("🚧 COLLISION SYSTEM ACTIVE", 10, 320)
        -- love.graphics.print("Using Windfield physics", 10, 340)
        
        -- Show debug info on screen
        -- if self.debugInfo then
        --     love.graphics.setColor(0, 1, 0) -- Green
        --     love.graphics.print("DEBUG: " .. self.debugInfo, 10, 360)
        --     love.graphics.setColor(1, 1, 1) -- Reset color
        -- end
        
        love.graphics.setColor(1, 1, 1, 1) -- Reset color
    end
end

function Environment:drawForeground()
    if self.map then
        -- Draw foreground layer (trees, rocks, etc.) on top of player
        for i, layer in ipairs(self.map.layers) do
            if layer.name == "Foreground Layer" then
                self.map:drawLayer(layer, math.floor(0), math.floor(0))
            end
        end
    end
end

-- 🚧 COLLISION DETECTION FUNCTIONS
function Environment:isSolid(x, y)
    if not self.map then return false end
    
    -- Convert world coordinates to tile coordinates
    local tileX = math.floor(x / self.map.tilewidth) + 1
    local tileY = math.floor(y / self.map.tileheight) + 1
    
    -- Check if coordinates are within map bounds
    if tileX < 1 or tileX > self.map.width or tileY < 1 or tileY > self.map.height then
        return true  -- Out of bounds = solid
    end
    
    -- Check the "Collision Detection Layer" specifically
    local collisionLayer = nil
    for _, layer in ipairs(self.map.layers) do
        if layer.name == "Collision Detection Layer" then
            collisionLayer = layer
            break
        end
    end
    
    if not collisionLayer or not collisionLayer.data then
        self.debugInfo = "⚠️ No valid collision layer found!"
        return false
    end
    
    local tileIndex = (tileY - 1) * self.map.width + tileX
    local tileId = collisionLayer.data[tileIndex] or 0
    
    self.debugInfo = "Layer: " .. collisionLayer.name .. " | Tile(" .. tileX .. "," .. tileY .. ") | Index: " .. tileIndex .. " | ID: " .. tileId .. " | Map: " .. self.map.width .. "x" .. self.map.height
    return tileId ~= 0
end


function Environment:checkCollision(x, y, width, height)
    -- Check collision for a rectangle
    -- Returns true if there's a collision
    local tileSize = self.map.tilewidth
    
    -- Check corners and center points
    local checkPoints = {
        {x, y},                           -- Top-left
        {x + width, y},                   -- Top-right  
        {x, y + height},                  -- Bottom-left
        {x + width, y + height},          -- Bottom-right
        {x + width/2, y + height/2}       -- Center
    }
    
    for _, point in ipairs(checkPoints) do
        if self:isSolid(point[1], point[2]) then
            return true
        end
    end
    
    return false
end

return Environment
