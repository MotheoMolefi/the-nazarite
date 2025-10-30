-- ui.lua
-- UI system for The Nazarite

local UI = {}

function UI:new()
    local self = setmetatable({}, {__index = UI})
    
    -- Load heart sprites
    self.heartFull = love.graphics.newImage("assets/Icons/heart.png")
    self.heartHalf = love.graphics.newImage("assets/Icons/heart-half.png")
    self.heartEmpty = love.graphics.newImage("assets/Icons/heart-empty.png")
    
    -- 🎮 Menu system fonts
    local success1, titleFont = pcall(love.graphics.newFont, "assets/Font/Planes_ValMore.ttf", 80)
    if success1 then
        self.titleFont = titleFont
    else
        self.titleFont = love.graphics.newFont(80)
    end
    
    local success2, menuFont = pcall(love.graphics.newFont, "assets/Font/Planes_ValMore.ttf", 32)
    if success2 then
        self.menuFont = menuFont
    else
        self.menuFont = love.graphics.newFont(32)
    end
    
    -- 💀 Load sword icon for kills banner
    self.swordIcon = love.graphics.newImage("assets/Icons/sword.png")
    
    -- 🌊 Wave prompt system
    self.wavePromptImage = love.graphics.newImage("assets/Icons/wave_prompt.png")
    
    -- Try to load custom font with error handling
    local success, fontOrError = pcall(love.graphics.newFont, "assets/Font/Planes_ValMore.ttf", 36)
    if success and fontOrError then
        self.wavePromptFont = fontOrError
        print("✅ Custom font loaded successfully")
    else
        print("⚠️ Failed to load custom font: " .. tostring(fontOrError))
        print("⚠️ Using default font instead")
        self.wavePromptFont = nil  -- Will use default in draw
    end
    self.wavePromptActive = false
    self.wavePromptTimer = 0
    self.wavePromptDelay = 1.0     -- Delay before showing banner (1 second)
    self.wavePromptDuration = 3.0  -- Show for 3 seconds (after delay)
    self.wavePromptFadeIn = 0.5    -- Fade in over 0.5s
    self.wavePromptFadeOut = 0.5   -- Fade out over 0.5s
    self.wavePromptAlpha = 0
    self.wavePromptText = ""
    self.onPromptComplete = nil  -- Callback when prompt finishes
    
    return self
end

-- Draw health bar (5 hearts system)
function UI:drawHealth(health, maxHealth, x, y)
    local heartWidth = 32  -- Width of each heart sprite (includes transparent padding)
    local heartSpacing = -15  -- Large negative to compensate for sprite padding
    local scale = 2  -- Scale up the hearts (bigger)
    
    -- Calculate how many full, half, and empty hearts to show
    local totalHearts = 5  -- 5 hearts = 100 HP
    local hpPerHeart = maxHealth / totalHearts  -- 20 HP per heart
    
    for i = 1, totalHearts do
        local heartX = x + ((i - 1) * (heartWidth + heartSpacing) * scale)
        local heartY = y
        
        -- Calculate which heart sprite to use
        local heartMinHP = (i - 1) * hpPerHeart  -- Start of this heart's HP range
        local heartMaxHP = i * hpPerHeart         -- End of this heart's HP range
        local heartMidHP = heartMinHP + (hpPerHeart / 2)  -- Middle point (half heart)
        
        if health >= heartMaxHP then
            -- Full heart (health covers this entire heart)
            love.graphics.draw(self.heartFull, heartX, heartY, 0, scale, scale)
        elseif health > heartMidHP then
            -- More than half but not full
            love.graphics.draw(self.heartFull, heartX, heartY, 0, scale, scale)
        elseif health > heartMinHP then
            -- Between min and mid = half heart
            love.graphics.draw(self.heartHalf, heartX, heartY, 0, scale, scale)
        else
            -- Empty heart (health doesn't reach this heart)
            love.graphics.draw(self.heartEmpty, heartX, heartY, 0, scale, scale)
        end
    end
end

-- 🌊 Show wave prompt
function UI:showWavePrompt(waveNumber, onComplete)
    self.wavePromptActive = true
    self.wavePromptTimer = 0
    self.wavePromptAlpha = 0
    self.onPromptComplete = onComplete
    
    if waveNumber == 1 then
        self.wavePromptText = "WAVE 1"
    elseif waveNumber == 2 then
        self.wavePromptText = "WAVE 2"
    elseif waveNumber == 3 then
        self.wavePromptText = "WAVE 3"
    elseif waveNumber == "victory" then
        self.wavePromptText = "VICTORY!"
    end
    
    print("🌊 Showing wave prompt: " .. self.wavePromptText)
end

-- Update wave prompt
function UI:updateWavePrompt(dt)
    if not self.wavePromptActive then return end
    
    self.wavePromptTimer = self.wavePromptTimer + dt
    
    -- Delay before showing banner
    if self.wavePromptTimer < self.wavePromptDelay then
        self.wavePromptAlpha = 0
    -- Fade in
    elseif self.wavePromptTimer < self.wavePromptDelay + self.wavePromptFadeIn then
        local fadeInProgress = (self.wavePromptTimer - self.wavePromptDelay) / self.wavePromptFadeIn
        self.wavePromptAlpha = fadeInProgress
    -- Hold
    elseif self.wavePromptTimer < self.wavePromptDelay + self.wavePromptDuration - self.wavePromptFadeOut then
        self.wavePromptAlpha = 1.0
    -- Fade out
    elseif self.wavePromptTimer < self.wavePromptDelay + self.wavePromptDuration then
        local fadeOutProgress = (self.wavePromptTimer - (self.wavePromptDelay + self.wavePromptDuration - self.wavePromptFadeOut)) / self.wavePromptFadeOut
        self.wavePromptAlpha = 1.0 - fadeOutProgress
    else
        -- Prompt finished
        self.wavePromptActive = false
        self.wavePromptAlpha = 0
        
        -- Call completion callback if provided
        if self.onPromptComplete then
            self.onPromptComplete()
            self.onPromptComplete = nil
        end
    end
end

-- Draw wave prompt
function UI:drawWavePrompt()
    if not self.wavePromptActive or self.wavePromptAlpha <= 0 then return end
    
    love.graphics.setColor(1, 1, 1, self.wavePromptAlpha)
    
    -- Draw skull banner centered
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local bannerScale = 1.5  -- Smaller banner
    local bannerW = self.wavePromptImage:getWidth() * bannerScale
    local bannerH = self.wavePromptImage:getHeight() * bannerScale
    local bannerX = (screenW - bannerW) / 2
    local bannerY = screenH / 2 - bannerH / 2
    
    love.graphics.draw(self.wavePromptImage, bannerX, bannerY, 0, bannerScale, bannerScale)
    
    -- Draw wave text on the banner (centered inside the brown bar)
    local font = self.wavePromptFont
    if not font then
        -- Font failed to load, use default
        font = love.graphics.newFont(36)
    end
    love.graphics.setFont(font)
    local textW = font:getWidth(self.wavePromptText)
    local textH = font:getHeight()
    local textX = screenW / 2 - textW / 2 + 12  -- Slightly to the right
    -- Position text lower to center it in the brown bar
    local textY = bannerY + (bannerH * 0.6725) - (textH / 2)
    
    -- Draw text shadow
    love.graphics.setColor(0, 0, 0, self.wavePromptAlpha * 0.5)
    love.graphics.print(self.wavePromptText, textX + 2, textY + 2)
    
    -- Draw main text
    love.graphics.setColor(1, 1, 1, self.wavePromptAlpha)
    love.graphics.print(self.wavePromptText, textX, textY)
    
    -- Reset color (font will persist but that's fine)
    love.graphics.setColor(1, 1, 1, 1)
end

-- 🎮 Draw main menu
function UI:drawMenu()
    -- Draw semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(1, 1, 1)
    
    -- Draw title
    love.graphics.setFont(self.titleFont)
    local titleText = "THE NAZARITE"
    local titleW = self.titleFont:getWidth(titleText)
    local titleH = self.titleFont:getHeight()
    local titleX = (love.graphics.getWidth() - titleW) / 2
    local titleY = (love.graphics.getHeight() - titleH) / 2 - 50  -- Centered vertically, slightly above center
    
    -- Title shadow
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.print(titleText, titleX + 4, titleY + 4)
    
    -- Title text (golden color)
    love.graphics.setColor(1, 0.84, 0)
    love.graphics.print(titleText, titleX, titleY)
    
    -- Draw start prompt
    love.graphics.setFont(self.menuFont)
    local promptText = "PRESS ENTER TO START"
    local promptW = self.menuFont:getWidth(promptText)
    local promptH = self.menuFont:getHeight()
    local promptX = (love.graphics.getWidth() - promptW) / 2
    local promptY = titleY + titleH + 40  -- Position below title
    
    -- Blinking effect
    local blinkAlpha = (math.sin(love.timer.getTime() * 3) + 1) / 2
    love.graphics.setColor(1, 1, 1, blinkAlpha)
    love.graphics.print(promptText, promptX, promptY)
    
    love.graphics.setColor(1, 1, 1)
end

-- 💀 Draw kills banner (bottom left corner)
function UI:drawKillsBanner(kills, maxKills)
    -- Don't show while wave prompt is active
    if self.wavePromptActive then
        return
    end
    
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local bannerScale = 0.35  -- Slightly bigger
    local bannerW = self.wavePromptImage:getWidth() * bannerScale
    local bannerH = self.wavePromptImage:getHeight() * bannerScale
    local bannerX = 20  -- 20 pixels from left edge
    local bannerY = screenH - bannerH - 20  -- 20 pixels from bottom
    
    -- Draw banner (original colors)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.wavePromptImage, bannerX, bannerY, 0, bannerScale, bannerScale)
    
    -- Draw sword icon and kills count
    local killsFont = love.graphics.newFont(11)
    love.graphics.setFont(killsFont)
    local killsText = tostring(kills)
    
    -- Calculate icon size and position
    local iconScale = 1.0  -- Bigger sword icon
    local iconW = self.swordIcon:getWidth() * iconScale
    local iconH = self.swordIcon:getHeight() * iconScale
    
    -- Calculate total width (icon + small gap + text)
    local textW = killsFont:getWidth(killsText)
    local textH = killsFont:getHeight()
    local gap = -2
    local totalW = iconW + gap + textW
    
    -- Center the group horizontally
    local startX = bannerX + (bannerW / 2) - (totalW / 2)
    local centerY = bannerY + (bannerH * 0.675)
    
    -- Draw sword icon
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.swordIcon, startX, centerY - iconH / 2, 0, iconScale, iconScale)
    
    -- Draw kills number
    local textX = startX + iconW + gap
    local textY = centerY - textH / 2
    
    -- Text shadow
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.print(killsText, textX + 1, textY + 1)
    
    -- Main text (white)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(killsText, textX, textY)
    
    love.graphics.setColor(1, 1, 1)
end

return UI

