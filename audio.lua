-- audio.lua
-- Audio manager for The Nazarite

local Audio = {}

function Audio:new()
    local self = setmetatable({}, {__index = Audio})
    
    -- 🎵 Background Music
    self.music = {}
    self.currentMusic = nil
    
    -- 🔊 Sound Effects
    self.sfx = {}
    
    -- 🎚️ Volume levels (0.0 to 1.0)
    self.musicVolume = 0.3
    self.sfxVolume = 0.5
    self.masterVolume = 1.0
    
    -- Load music
    self:loadMusic()
    
    -- Load sound effects (add more later)
    -- self:loadSFX()
    
    return self
end

function Audio:loadMusic()
    -- Load background music
    self.music.background = love.audio.newSource("assets/sound/The Astounding Eyes Of Rita.mp3", "stream")
    self.music.background:setLooping(true)
    self.music.background:setVolume(self.musicVolume * self.masterVolume)
end

function Audio:loadSFX()
    -- 🔊 Load sound effects here (example structure)
    -- self.sfx.swordSwing = love.audio.newSource("assets/sound/sfx/sword_swing.wav", "static")
    -- self.sfx.enemyHit = love.audio.newSource("assets/sound/sfx/enemy_hit.wav", "static")
    -- self.sfx.pickup = love.audio.newSource("assets/sound/sfx/pickup.wav", "static")
end

-- 🎵 Play background music
function Audio:playMusic(musicName, startTime)
    musicName = musicName or "background"
    startTime = startTime or 0  -- Default: start from beginning
    
    -- Stop current music if playing
    if self.currentMusic then
        self.currentMusic:stop()
    end
    
    -- Play new music
    if self.music[musicName] then
        self.currentMusic = self.music[musicName]
        self.currentMusic:seek(startTime, "seconds")  -- Jump to timestamp
        self.currentMusic:play()
    end
end

-- 🔊 Play sound effect
function Audio:playSFX(sfxName)
    if self.sfx[sfxName] then
        -- Clone the sound so multiple instances can play
        local sound = self.sfx[sfxName]:clone()
        sound:setVolume(self.sfxVolume * self.masterVolume)
        sound:play()
    end
end

-- 🎚️ Set music volume
function Audio:setMusicVolume(volume)
    self.musicVolume = math.max(0, math.min(1, volume))  -- Clamp 0-1
    if self.currentMusic then
        self.currentMusic:setVolume(self.musicVolume * self.masterVolume)
    end
end

-- 🎚️ Set SFX volume
function Audio:setSFXVolume(volume)
    self.sfxVolume = math.max(0, math.min(1, volume))  -- Clamp 0-1
end

-- 🎚️ Set master volume
function Audio:setMasterVolume(volume)
    self.masterVolume = math.max(0, math.min(1, volume))  -- Clamp 0-1
    if self.currentMusic then
        self.currentMusic:setVolume(self.musicVolume * self.masterVolume)
    end
end

-- 🔇 Mute/Unmute all audio
function Audio:toggleMute()
    if self.masterVolume > 0 then
        self.previousVolume = self.masterVolume
        self:setMasterVolume(0)
    else
        self:setMasterVolume(self.previousVolume or 1.0)
    end
end

-- ⏸️ Pause music
function Audio:pauseMusic()
    if self.currentMusic then
        self.currentMusic:pause()
    end
end

-- ▶️ Resume music
function Audio:resumeMusic()
    if self.currentMusic then
        self.currentMusic:play()
    end
end

return Audio

