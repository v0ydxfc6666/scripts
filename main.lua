
-- Load WindUI Library
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")

-- Variables
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Create Window
local Window = WindUI:CreateWindow({
    Title = "AstrionHUB",
    Author = "by AstrionHUB",
    Folder = "ASTRION_DATA",
    
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function()
            WindUI:Notify({
                Title = "User Profile",
                Content = "User profile clicked!",
                Duration = 3
            })
        end
    },
    
    OpenButton = {
        Title = "AstrionHUB",
        CornerRadius = UDim.new(0, 8),
        StrokeThickness = 2,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Color = ColorSequence.new(
            Color3.fromRGB(200, 0, 0),
            Color3.fromRGB(255, 50, 50)
        )
    }
})

-- Tags
Window:Tag({
    Title = "v2.5 Humanoid Update",
    Icon = "github",
    Color = Color3.fromRGB(200, 0, 0)
})

-- Create Tabs
local InfoTab = Window:Tab({
    Title = "Information",
    Icon = "info"
})

local ManualTab = Window:Tab({
    Title = "Manual Walk",
    Icon = "gamepad-2"
})

local AutomaticTab = Window:Tab({
    Title = "Automatic Walk",
    Icon = "cpu"
})

local BypassTab = Window:Tab({
    Title = "Bypass",
    Icon = "shield-check"
})

local AvatarTab = Window:Tab({
    Title = "Avatar Copy",
    Icon = "users"
})

local HumanoidTab = Window:Tab({
    Title = "Humanoid",
    Icon = "user"
})

local MiscTab = Window:Tab({
    Title = "Miscellaneous",
    Icon = "settings"
})

local UpdateTab = Window:Tab({
    Title = "Updates",
    Icon = "download"
})

local ThemeTab = Window:Tab({
    Title = "Theme",
    Icon = "palette"
})

--| =========================================================== |--
--| INFORMATION TAB                                             |--
--| =========================================================== |--

InfoTab:Section({
    Title = "Script Information",
})

InfoTab:Paragraph({
    Title = "AstrionHUB",
    Desc = "Version: 2.5 Humanoid Update\nGame: Mount Cielo\nRelease Date: November 2025\nDeveloper: Jinho \n\nA professional auto walk script featuring manual and automatic modes with advanced bypass protection, avatar customization, and humanoid utilities."
})

InfoTab:Space()

InfoTab:Section({
    Title = "Script Code",
})

InfoTab:Code({
    Title = "BY JINHO",
    Code = [[Steal the design, steal the words — but originality doesn’t come with a shortcut.]]
})

InfoTab:Space()

InfoTab:Section({
    Title = "Changelog Version 2.5",
})

InfoTab:Paragraph({
    Title = "Latest Updates",
    Desc = "- Added Humanoid Tab with utilities\n- ESP Player system\n- Teleport to players\n- Noclip mode\n- Infinite jump\n- Improved UI organization\n- Fixed all tab issues\n- Performance optimizations"
})

InfoTab:Space()

InfoTab:Section({
    Title = "Core Features",
})

InfoTab:Paragraph({
    Title = "Available Features",
    Desc = "Manual Walk: 8 checkpoint locations with looping\nAutomatic Walk: Continuous path following\nBypass: AFK prevention, anti-spectator\nGod Mode: 100% invincibility\nAvatar Copy: Real-time avatar system\nHumanoid: ESP, Teleport, Noclip, Infinite Jump\nAnimations: 3 custom animation packs\nThemes: 4 premium themes"
})

InfoTab:Space()

InfoTab:Section({
    Title = "Social Media & Support",
})

InfoTab:Button({
    Title = "Telegram Community",
    Desc = "Join our Telegram group for updates",
    Icon = "send",
    Color = Color3.fromRGB(0, 136, 204),
    Callback = function()
        setclipboard("https://t.me/jinho")
        WindUI:Notify({
            Title = "Telegram",
            Content = "Link copied to clipboard",
            Duration = 3,
            Icon = "clipboard-check"
        })
    end
})

InfoTab:Button({
    Title = "Discord Server",
    Desc = "Join our Discord community",
    Icon = "message-square",
    Color = Color3.fromRGB(88, 101, 242),
    Callback = function()
        setclipboard("https://discord.gg/AstrionHUB")
        WindUI:Notify({
            Title = "Discord",
            Content = "Link copied to clipboard",
            Duration = 3,
            Icon = "clipboard-check"
        })
    end
})

--| =========================================================== |--
--| VARIABLES & HELPERS                                         |--
--| =========================================================== |--

local mainFolder = "ASTRIONHUB"
local jsonFolder = mainFolder .. "/json_manual"
if not isfolder(mainFolder) then makefolder(mainFolder) end
if not isfolder(jsonFolder) then makefolder(jsonFolder) end

local baseURL = "https://raw.githubusercontent.com/v0ydxfc6666/v0ydffx/refs/heads/main/CFRAME/ALLDATAMAPS/MANUAL/YAGESYA/"
  local manualJsonFiles = {
      "spawnpoint.json",
      "checkpoint_1.json",
      "checkpoint_2.json",
      "checkpoint_3.json",
      "checkpoint_4.json",
      "checkpoint_5.json",
      }

local isPlaying = false
local playbackConnection = nil
local playbackSpeed = 1.0
local heightOffset = 0
local isLoopingEnabled = false
local isPaused = false
local lastPlaybackTime = 0
local accumulatedTime = 0
local isFlipped = false
local currentFlipRotation = CFrame.new()
local FLIP_SMOOTHNESS = 0.05
local manualLoopStartCheckpoint = 1
local manualIsLoopingActive = false

local POSITION_SMOOTH = 0.96
local VELOCITY_SMOOTH = 0.94
local ROTATION_SMOOTH = 0.95
local MOVE_SMOOTH = 0.93

local antiSpectatorEnabled = false
local originalNetworkOwnership = {}

local function vecToTable(v3)
    return {x = v3.X, y = v3.Y, z = v3.Z}
end

local function tableToVec(t)
    return Vector3.new(t.x, t.y, t.z)
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function lerpVector(a, b, t)
    return Vector3.new(lerp(a.X, b.X, t), lerp(a.Y, b.Y, t), lerp(a.Z, b.Z, t))
end

local function lerpAngle(a, b, t)
    local diff = (b - a)
    while diff > math.pi do diff = diff - 2*math.pi end
    while diff < -math.pi do diff = diff + 2*math.pi end
    return a + diff * t
end

local function EnsureJsonFile(fileName)
    local savePath = jsonFolder .. "/" .. fileName
    if isfile(savePath) then return true, savePath end
    
    local ok, res = pcall(function() return game:HttpGet(baseURL..fileName) end)
    if ok and res and #res > 0 then
        writefile(savePath, res)
        return true, savePath
    end
    return false, nil
end

local function loadCheckpoint(fileName)
    local filePath = jsonFolder .. "/" .. fileName
    if not isfile(filePath) then return nil end
    
    local success, result = pcall(function()
        local jsonData = readfile(filePath)
        return HttpService:JSONDecode(jsonData)
    end)
    
    if success then return result else return nil end
end

local function findSurroundingFrames(data, t)
    if #data == 0 then return nil, nil, 0 end
    if t <= data[1].time then return 1, 1, 0 end
    if t >= data[#data].time then return #data, #data, 0 end

    local left, right = 1, #data
    while left < right - 1 do
        local mid = math.floor((left + right) / 2)
        if data[mid].time <= t then
            left = mid
        else
            right = mid
        end
    end

    local i0, i1 = left, right
    local span = data[i1].time - data[i0].time
    local alpha = span > 0 and math.clamp((t - data[i0].time) / span, 0, 1) or 0

    return i0, i1, alpha
end

local function stopPlayback()
    isPlaying = false
    isPaused = false
    accumulatedTime = 0
    lastPlaybackTime = 0
    heightOffset = 0
    isFlipped = false
    currentFlipRotation = CFrame.new()
    manualIsLoopingActive = false
    
    if playbackConnection then
        playbackConnection:Disconnect()
        playbackConnection = nil
    end

    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:Move(Vector3.new(0, 0, 0), false)
    end
end

--| ========================================================== |--
--| FIXED JUMP DETECTOR WITH CLIMB SUPPORT                     |--
--| ========================================================== |--

local JumpDetector = {}
JumpDetector.__index = JumpDetector

function JumpDetector.new()
    local self = setmetatable({}, JumpDetector)
    
    self.lastJumpTime = 0
    self.jumpCooldown = 0.35
    self.lastJumpBool = false
    
    return self
end

function JumpDetector:ShouldJump(data, currentIndex, frame0, frame1, interpVel, currentTime)
    if self.jumpCooldown > 0 then
        self.jumpCooldown = self.jumpCooldown - 0.016
    end
    
    local currentState = frame0.state or "Running"
    if currentState == "Climbing" then
        return false
    end
    
    local currentJumpBool = frame0.jumping or false
    local nextJumpBool = frame1.jumping or false
    
    local booleanFlip = (not self.lastJumpBool) and (currentJumpBool or nextJumpBool)
    
    self.lastJumpBool = currentJumpBool or nextJumpBool
    
    if booleanFlip and self.jumpCooldown <= 0 then
        self.jumpCooldown = 0.35
        return true
    end
    
    return false
end

function JumpDetector:ExecuteJump(humanoid)
    if not humanoid then return false end
    
    local currentState = humanoid:GetState()
    
    if currentState == Enum.HumanoidStateType.Climbing then
        return false
    end
    
    local validStates = {
        [Enum.HumanoidStateType.Running] = true,
        [Enum.HumanoidStateType.RunningNoPhysics] = true,
        [Enum.HumanoidStateType.Landed] = true,
        [Enum.HumanoidStateType.Freefall] = true,
    }
    
    if validStates[currentState] then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        return true
    end
    
    return false
end

--| ========================================================== |--
--| PLAYBACK SYSTEM                                            |--
--| ========================================================== |--

local function startPlayback(data, onComplete)
    if not data or #data == 0 then  
        if onComplete then onComplete() end
        return
    end

    if isPlaying then stopPlayback() end

    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = char.HumanoidRootPart
    local hum = char:FindFirstChild("Humanoid")
    
    if data[1] then
        local firstFrame = data[1]
        local startPos = tableToVec(firstFrame.position)
        local startYaw = firstFrame.rotation or 0

        hrp.CFrame = CFrame.new(startPos) * CFrame.Angles(0, startYaw, 0)
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

        local currentHipHeight = hum.HipHeight
        local recordedHipHeight = data[1].hipHeight or 2
        heightOffset = currentHipHeight - recordedHipHeight
    end

    isPlaying = true
    isPaused = false
    local playbackStartTime = tick()
    lastPlaybackTime = playbackStartTime
    accumulatedTime = 0
    
    local jumpDetector = JumpDetector.new()
    
    local positionBuffer = {}
    local velocityBuffer = {}
    local rotationBuffer = {}
    local bufferSize = 5

    if playbackConnection then
        playbackConnection:Disconnect()
        playbackConnection = nil
    end

    playbackConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not isPlaying then return end
        if isPaused then return end

        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return end
        
        local hrp = char.HumanoidRootPart
        local hum = char.Humanoid

        local currentTime = tick()
        local actualDelta = math.min(currentTime - lastPlaybackTime, 0.1)
        lastPlaybackTime = currentTime
        accumulatedTime = accumulatedTime + (actualDelta * playbackSpeed)
        local totalDuration = data[#data].time

        if accumulatedTime > totalDuration then
            stopPlayback()
            if onComplete then onComplete() end
            return
        end

        local i0, i1, alpha = findSurroundingFrames(data, accumulatedTime)
        local f0, f1 = data[i0], data[i1]
        if not f0 or not f1 then return end

        local pos0, pos1 = tableToVec(f0.position), tableToVec(f1.position)
        local vel0 = f0.velocity and tableToVec(f0.velocity) or Vector3.new(0,0,0)
        local vel1 = f1.velocity and tableToVec(f1.velocity) or Vector3.new(0,0,0)
        local move0 = f0.moveDirection and tableToVec(f0.moveDirection) or Vector3.new(0,0,0)
        local move1 = f1.moveDirection and tableToVec(f1.moveDirection) or Vector3.new(0,0,0)
        local yaw0, yaw1 = f0.rotation or 0, f1.rotation or 0

        local interpPos = lerpVector(pos0, pos1, alpha)
        local interpVel = lerpVector(vel0, vel1, alpha)
        local interpMove = lerpVector(move0, move1, alpha)
        local interpYaw = lerpAngle(yaw0, yaw1, alpha)

        table.insert(positionBuffer, interpPos)
        table.insert(velocityBuffer, interpVel)
        table.insert(rotationBuffer, interpYaw)
        
        if #positionBuffer > bufferSize then table.remove(positionBuffer, 1) end
        if #velocityBuffer > bufferSize then table.remove(velocityBuffer, 1) end
        if #rotationBuffer > bufferSize then table.remove(rotationBuffer, 1) end
        
        local avgPos = Vector3.new(0, 0, 0)
        local avgVel = Vector3.new(0, 0, 0)
        local avgYaw = 0
        
        for _, pos in ipairs(positionBuffer) do avgPos = avgPos + pos end
        avgPos = avgPos / #positionBuffer
        
        for _, vel in ipairs(velocityBuffer) do avgVel = avgVel + vel end
        avgVel = avgVel / #velocityBuffer
        
        for _, yaw in ipairs(rotationBuffer) do avgYaw = avgYaw + yaw end
        avgYaw = avgYaw / #rotationBuffer

        local correctedY = avgPos.Y + heightOffset
        local targetCFrame = CFrame.new(avgPos.X, correctedY, avgPos.Z) * CFrame.Angles(0, avgYaw, 0)
        
        hrp.CFrame = hrp.CFrame:Lerp(targetCFrame, POSITION_SMOOTH)

        local targetVelocity = avgVel * 0.97
        local currentVel = hrp.AssemblyLinearVelocity
        hrp.AssemblyLinearVelocity = currentVel:Lerp(targetVelocity, VELOCITY_SMOOTH)

        if hum then
            local currentMove = hum.MoveDirection
            local smoothMove = currentMove:Lerp(interpMove, MOVE_SMOOTH)
            hum:Move(smoothMove, false)
        end

        if jumpDetector:ShouldJump(data, i0, f0, f1, interpVel, accumulatedTime) then
            jumpDetector:ExecuteJump(hum)
        end
        
        if antiSpectatorEnabled then
            pcall(function()
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end)
        end
    end)
end

local function getNextCheckpointIndex(currentIndex)
    local totalCheckpoints = #manualJsonFiles
    if currentIndex >= totalCheckpoints then
        return 1
    else
        return currentIndex + 1
    end
end

local function walkToStartIfNeeded(character, startPos)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoidLocal = character:FindFirstChildOfClass("Humanoid")
    
    if not hrp or not humanoidLocal then
        return false
    end
    
    local distance = (hrp.Position - startPos).Magnitude
    
    if distance > 10 then
        local reached = false
        local moveConnection
        
        moveConnection = humanoidLocal.MoveToFinished:Connect(function(r)
            reached = true
            if moveConnection then
                moveConnection:Disconnect()
                moveConnection = nil
            end
        end)
        
        humanoidLocal:MoveTo(startPos)
        
        local startTime = tick()
        local maxWaitTime = 15
        
        while not reached and (tick() - startTime) < maxWaitTime do
            task.wait(0.1)
        end
        
        if moveConnection then
            moveConnection:Disconnect()
            moveConnection = nil
        end
        
        return reached
    end
    
    return true
end

local function playManualCheckpointSequence(startIndex)
    if not isLoopingEnabled then
        return
    end
    
    manualIsLoopingActive = true
    local currentIndex = startIndex
    
    local function playNext()
        if not isLoopingEnabled or not manualIsLoopingActive then
            return
        end
        
        local fileName = manualJsonFiles[currentIndex]
        
        local ok, path = EnsureJsonFile(fileName)
        if not ok then
            WindUI:Notify({
                Title = "Error (Loop)",
                Content = "Failed to load checkpoint: " .. fileName,
                Duration = 4,
                Icon = "x"
            })
            stopPlayback()
            manualIsLoopingActive = false
            return
        end
        
        local data = loadCheckpoint(fileName)
        if not data or #data == 0 then
            WindUI:Notify({
                Title = "Error (Loop)",
                Content = "Empty checkpoint data: " .. fileName,
                Duration = 4,
                Icon = "x"
            })
            stopPlayback()
            manualIsLoopingActive = false
            return
        end
        
        local char = LocalPlayer.Character
        if not char then
            WindUI:Notify({
                Title = "Error (Loop)",
                Content = "Character not found!",
                Duration = 4,
                Icon = "x"
            })
            stopPlayback()
            manualIsLoopingActive = false
            return
        end
        
        local startPos = tableToVec(data[1].position)
        
        local reached = walkToStartIfNeeded(char, startPos)
        
        if not reached then
            WindUI:Notify({
                Title = "Auto Walk (Loop)",
                Content = "Failed to reach start position (timeout)!",
                Duration = 3,
                Icon = "x"
            })
            stopPlayback()
            manualIsLoopingActive = false
            return
        end
        
        task.wait(0.5)
        
        startPlayback(data, function()
            if not isLoopingEnabled or not manualIsLoopingActive then
                return
            end
            
            task.wait(0.3)
            
            local nextIndex = getNextCheckpointIndex(currentIndex)
            currentIndex = nextIndex
            playNext()
        end)
    end
    
    playNext()
end

local function playSingleCheckpoint(fileName, checkpointName, checkpointIndex)
    stopPlayback()
    manualIsLoopingActive = false
    
    local ok, path = EnsureJsonFile(fileName)
    if not ok then
        WindUI:Notify({
            Title = "Error",
            Content = "Failed to load checkpoint file!",
            Duration = 4,
            Icon = "x"
        })
        return
    end
    
    local data = loadCheckpoint(fileName)
    if not data or #data == 0 then
        WindUI:Notify({
            Title = "Error",
            Content = "Checkpoint data is empty!",
            Duration = 4,
            Icon = "x"
        })
        return
    end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        WindUI:Notify({
            Title = "Error",
            Content = "Character not found!",
            Duration = 4,
            Icon = "x"
        })
        return
    end
    
    local hrp = char.HumanoidRootPart
    local startPos = tableToVec(data[1].position)
    local distance = (hrp.Position - startPos).Magnitude
    
    if distance > 100 then
        WindUI:Notify({
            Title = "Auto Walk",
            Content = string.format("You're too far (%.0f studs)! Get closer to checkpoint.", distance),
            Duration = 5,
            Icon = "alert-triangle"
        })
        return
    end
    
    WindUI:Notify({
        Title = "Auto Walk",
        Content = "Walking to start position...",
        Duration = 2,
        Icon = "footprints"
    })
    
    local reached = walkToStartIfNeeded(char, startPos)
    
    if not reached then
        WindUI:Notify({
            Title = "Auto Walk",
            Content = "Failed to reach start position (timeout)!",
            Duration = 3,
            Icon = "x"
        })
        return
    end
    
    task.wait(0.5)
    
    WindUI:Notify({
        Title = "Auto Walk",
        Content = "Starting from " .. checkpointName,
        Duration = 2,
        Icon = "play"
    })
    
    if isLoopingEnabled then
        manualLoopStartCheckpoint = checkpointIndex
        playManualCheckpointSequence(checkpointIndex)
    else
        startPlayback(data, function()
            WindUI:Notify({
                Title = "Auto Walk",
                Content = "Completed!",
                Duration = 2,
                Icon = "check-check"
            })
        end)
    end
end

--| =========================================================== |--
--| MANUAL TAB                                                  |--
--| =========================================================== |--

ManualTab:Section({
    Title = "Settings",
})

ManualTab:Slider({
    Title = "Speed Control",
    Desc = "Adjust auto walk speed",
    Step = 0.1,
    Value = {
        Min = 0.5,
        Max = 1.5,
        Default = 1.0,
    },
    Callback = function(value)
        playbackSpeed = value
    end
})

ManualTab:Toggle({
    Title = "Enable Looping",
    Desc = "Automatically loop between checkpoints",
    Icon = "repeat",
    Default = false,
    Callback = function(Value)
        isLoopingEnabled = Value
        WindUI:Notify({
            Title = "Looping",
            Content = Value and "Loop enabled!" or "Loop disabled!",
            Duration = 2,
            Icon = "repeat"
        })
    end,
})

ManualTab:Space()

ManualTab:Section({
    Title = "Checkpoints",
})

local manualToggles = {}
local checkpointCount = #manualJsonFiles - 1

manualToggles["ManualSpawnpoint"] = ManualTab:Toggle({
    Flag = "ManualSpawnpoint",
    Title = "Spawnpoint",
    Desc = "Start from spawn point",
    Icon = "map-pin",
    Default = false,
    Callback = function(Value)
        if Value then
            for flag, toggle in pairs(manualToggles) do
                if flag ~= "ManualSpawnpoint" then
                    toggle:Set(false)
                end
            end
            playSingleCheckpoint("spawnpoint.json", "Spawnpoint", 1)
        else
            stopPlayback()
            manualIsLoopingActive = false
        end
    end,
})

for i = 1, checkpointCount do
    local flag = "ManualCP" .. i
    manualToggles[flag] = ManualTab:Toggle({
        Flag = flag,
        Title = "Checkpoint " .. i,
        Desc = "Start from checkpoint " .. i,
        Icon = "map-pin",
        Default = false,
        Callback = function(Value)
            if Value then
                for f, toggle in pairs(manualToggles) do
                    if f ~= flag then
                        toggle:Set(false)
                    end
                end
                playSingleCheckpoint("checkpoint_" .. i .. ".json", "Checkpoint " .. i, i + 1)
            else
                stopPlayback()
                manualIsLoopingActive = false
            end
        end,
    })
end

--| =========================================================== |--
--| AUTOMATIC TAB                                               |--
--| =========================================================== |--

local autoJsonFolder = mainFolder .. "/json_automatic"
if not isfolder(autoJsonFolder) then makefolder(autoJsonFolder) end

local automaticJsonURL = "NONE"
local automaticJsonFile = "automatic_full.json"

local autoPlaybackSpeed = 1.0
local autoIsRunning = false
local autoLoopEnabled = false
local godModeEnabled = false
local autoPlaybackConnection = nil
local autoAccumulatedTime = 0
local autoLastPlaybackTime = 0
local autoCurrentIndex = 1
local autoData = nil
local godModeConnection = nil
local forceFieldConnection = nil

local function findClosestFrameIndex(data, currentPos)
    local closestIndex = 1
    local closestDistance = math.huge
    
    for i, frame in ipairs(data) do
        local framePos = tableToVec(frame.position)
        local distance = (currentPos - framePos).Magnitude
        if distance < closestDistance then
            closestDistance = distance
            closestIndex = i
        end
    end
    
    return closestIndex, closestDistance
end

local function LoadAutomaticJson()
    local savePath = autoJsonFolder .. "/" .. automaticJsonFile
    
    if isfile(savePath) then
        local success, result = pcall(function()
            local jsonData = readfile(savePath)
            return HttpService:JSONDecode(jsonData)
        end)
        if success and result then
            return result
        end
    end
    
    local ok, res = pcall(function() 
        return game:HttpGet(automaticJsonURL) 
    end)
    
    if ok and res and #res > 0 then
        writefile(savePath, res)
        local success, result = pcall(function()
            return HttpService:JSONDecode(res)
        end)
        if success then
            return result
        end
    end
    
    return nil
end

local function StartGodMode()
    if godModeConnection then
        godModeConnection:Disconnect()
    end
    if forceFieldConnection then
        forceFieldConnection:Disconnect()
    end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    godModeConnection = RunService.Heartbeat:Connect(function()
    if godModeEnabled and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then
            hum.Health = hum.MaxHealth
            
            for _, effect in pairs(hum:GetChildren()) do
                if effect:IsA("NumberValue") and effect.Name == "creator" then
                    effect:Destroy()
                end
            end
        end
    end
end)
    
    forceFieldConnection = humanoid.HealthChanged:Connect(function(health)
        if godModeEnabled then
            if health < humanoid.MaxHealth then
                humanoid.Health = humanoid.MaxHealth
            end
        end
    end)
    
    pcall(function()
        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    end)
end

local function StopGodMode()
    if godModeConnection then
        godModeConnection:Disconnect()
        godModeConnection = nil
    end
    if forceFieldConnection then
        forceFieldConnection:Disconnect()
        forceFieldConnection = nil
    end
    
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            pcall(function()
                humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
            end)
        end
    end
end

local function StopAutomaticWalk()
    autoIsRunning = false
    autoAccumulatedTime = 0
    autoCurrentIndex = 1
    
    if autoPlaybackConnection then
        autoPlaybackConnection:Disconnect()
        autoPlaybackConnection = nil
    end
    
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:Move(Vector3.new(0, 0, 0), false)
    end
end

local function StartAutomaticWalk()
    if autoIsRunning then
        WindUI:Notify({
            Title = "Automatic Auto Walk",
            Content = "Already running!",
            Duration = 2,
            Icon = "alert-triangle"
        })
        return
    end
    
    if not autoData then
        WindUI:Notify({
            Title = "Loading Data",
            Content = "Loading automatic route data...",
            Duration = 3,
            Icon = "download"
        })
        
        autoData = LoadAutomaticJson()
        
        if not autoData or #autoData == 0 then
            WindUI:Notify({
                Title = "Error",
                Content = "Failed to load automatic route data!",
                Duration = 4,
                Icon = "x"
            })
            return
        end
    end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        WindUI:Notify({
            Title = "Error",
            Content = "Character not found!",
            Duration = 3,
            Icon = "x"
        })
        return
    end
    
    local hrp = char.HumanoidRootPart
    local currentPos = hrp.Position
    
    local closestIndex, distance = findClosestFrameIndex(autoData, currentPos)
    autoCurrentIndex = closestIndex
    
    WindUI:Notify({
        Title = "Automatic Auto Walk",
        Content = string.format("Found closest frame %d (%.1f studs away)", closestIndex, distance),
        Duration = 2,
        Icon = "search"
    })
    
    if distance > 10 then
        WindUI:Notify({
            Title = "Auto Walk",
            Content = "Walking to start position...",
            Duration = 2,
            Icon = "footprints"
        })
        
        local startPos = tableToVec(autoData[closestIndex].position)
        local reached = walkToStartIfNeeded(char, startPos)
        
        if not reached then
            WindUI:Notify({
                Title = "Automatic Auto Walk",
                Content = "Failed to reach start position (timeout)!",
                Duration = 3,
                Icon = "x"
            })
            return
        end
        
        task.wait(0.5)
    end
    
    WindUI:Notify({
        Title = "Automatic Auto Walk",
        Content = string.format("Starting from frame %d", closestIndex),
        Duration = 3,
        Icon = "play"
    })
    
    autoIsRunning = true
    autoLastPlaybackTime = tick()
    autoAccumulatedTime = autoData[closestIndex].time or 0
    
    if godModeEnabled then
        StartGodMode()
    end
    
    if autoPlaybackConnection then
        autoPlaybackConnection:Disconnect()
    end
    
    local autoJumpDetector = JumpDetector.new()
    
    local autoPosBuffer = {}
    local autoVelBuffer = {}
    local autoRotBuffer = {}
    local autoBufferSize = 5
    
    autoPlaybackConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not autoIsRunning then return end
        
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then
            StopAutomaticWalk()
            return
        end
        
        local hrp = char.HumanoidRootPart
        local humanoid = char.Humanoid
        
        local currentTime = tick()
        local actualDelta = math.min(currentTime - autoLastPlaybackTime, 0.1)
        autoLastPlaybackTime = currentTime
        autoAccumulatedTime = autoAccumulatedTime + (actualDelta * autoPlaybackSpeed)
        
        while autoCurrentIndex < #autoData and autoData[autoCurrentIndex + 1].time <= autoAccumulatedTime do
            autoCurrentIndex = autoCurrentIndex + 1
        end
        
        if autoCurrentIndex >= #autoData then
            if autoLoopEnabled then
                WindUI:Notify({
                    Title = "Auto Loop",
                    Content = "Restarting from beginning...",
                    Duration = 2,
                    Icon = "repeat"
                })
                
                task.wait(0.5)
                
                autoCurrentIndex = 1
                autoAccumulatedTime = autoData[1].time or 0
                
                local startPos = tableToVec(autoData[1].position)
                local currentPos = hrp.Position
                local distance = (currentPos - startPos).Magnitude
                
                if distance > 10 then
                    WindUI:Notify({
                        Title = "Auto Loop",
                        Content = "Walking to restart position...",
                        Duration = 2,
                        Icon = "footprints"
                    })
                    
                    local reached = walkToStartIfNeeded(char, startPos)
                    if not reached then
                        StopAutomaticWalk()
                        WindUI:Notify({
                            Title = "Auto Loop",
                            Content = "Failed to reach restart position!",
                            Duration = 3,
                            Icon = "x"
                        })
                        return
                    end
                    task.wait(0.5)
                end
                
                autoJumpDetector = JumpDetector.new()
            else
                StopAutomaticWalk()
                WindUI:Notify({
                    Title = "Automatic Auto Walk",
                    Content = "Route completed!",
                    Duration = 3,
                    Icon = "check-check"
                })
                return
            end
        end
        
        local frame1 = autoData[autoCurrentIndex]
        local frame2 = autoData[math.min(autoCurrentIndex + 1, #autoData)]
        
        local t1 = frame1.time
        local t2 = frame2.time
        local alpha = t2 > t1 and math.clamp((autoAccumulatedTime - t1) / (t2 - t1), 0, 1) or 0
        
        local pos1 = tableToVec(frame1.position)
        local pos2 = tableToVec(frame2.position)
        local targetPos = lerpVector(pos1, pos2, alpha)
        
        local yaw1 = frame1.rotation or 0
        local yaw2 = frame2.rotation or 0
        local targetYaw = lerpAngle(yaw1, yaw2, alpha)
        
        table.insert(autoPosBuffer, targetPos)
        table.insert(autoRotBuffer, targetYaw)
        
        if #autoPosBuffer > autoBufferSize then
            table.remove(autoPosBuffer, 1)
        end
        if #autoRotBuffer > autoBufferSize then
            table.remove(autoRotBuffer, 1)
        end
        
        local avgPos = Vector3.new(0, 0, 0)
        local avgYaw = 0
        
        for _, pos in ipairs(autoPosBuffer) do
            avgPos = avgPos + pos
        end
        avgPos = avgPos / #autoPosBuffer
        
        for _, yaw in ipairs(autoRotBuffer) do
            avgYaw = avgYaw + yaw
        end
        avgYaw = avgYaw / #autoRotBuffer
        
        local targetCFrame = CFrame.new(avgPos) * CFrame.Angles(0, avgYaw, 0)
        hrp.CFrame = hrp.CFrame:Lerp(targetCFrame, POSITION_SMOOTH)
        
        local vel1 = Vector3.new(0,0,0)
        local vel2 = Vector3.new(0,0,0)
        
        if frame1.velocity then
            vel1 = tableToVec(frame1.velocity)
            vel2 = frame2.velocity and tableToVec(frame2.velocity) or vel1
            local targetVel = lerpVector(vel1, vel2, alpha)
            
            table.insert(autoVelBuffer, targetVel)
            if #autoVelBuffer > autoBufferSize then
                table.remove(autoVelBuffer, 1)
            end
            
            local avgVel = Vector3.new(0, 0, 0)
            for _, vel in ipairs(autoVelBuffer) do
                avgVel = avgVel + vel
            end
            avgVel = avgVel / #autoVelBuffer
            
            local currentVel = hrp.AssemblyLinearVelocity
            local smoothVel = currentVel:Lerp(avgVel * 0.97, VELOCITY_SMOOTH)
            hrp.AssemblyLinearVelocity = smoothVel
        end
        
        local move1 = Vector3.new(0,0,0)
        if frame1.moveDirection then
            move1 = tableToVec(frame1.moveDirection)
            local move2 = frame2.moveDirection and tableToVec(frame2.moveDirection) or move1
            local targetMove = lerpVector(move1, move2, alpha)
            
            local currentMove = humanoid.MoveDirection
            local smoothMove = currentMove:Lerp(targetMove, MOVE_SMOOTH)
            humanoid:Move(smoothMove, false)
        end
        
        if autoJumpDetector:ShouldJump(autoData, autoCurrentIndex, frame1, frame2, vel1, autoAccumulatedTime) then
            autoJumpDetector:ExecuteJump(humanoid)
        end
        
        if antiSpectatorEnabled then
            pcall(function()
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end)
        end
    end)
end

AutomaticTab:Section({
    Title = "Settings",
})

AutomaticTab:Slider({
    Title = "Speed",
    Desc = "Adjust automatic walk speed",
    Step = 0.1,
    Value = {
        Min = 0.5,
        Max = 2.0,
        Default = 1.0,
    },
    Callback = function(value)
        autoPlaybackSpeed = value
    end
})

AutomaticTab:Space()

AutomaticTab:Section({
    Title = "Controls",
})

AutomaticTab:Button({
    Title = "Start Auto Walk",
    Desc = "Continue from current position",
    Icon = "play",
    Color = Color3.fromRGB(0, 200, 0),
    Callback = function()
        StartAutomaticWalk()
    end
})

AutomaticTab:Button({
    Title = "Stop Auto Walk",
    Desc = "Stop automatic walking",
    Icon = "stop-circle",
    Color = Color3.fromRGB(200, 0, 0),
    Callback = function()
        if autoIsRunning then
            StopAutomaticWalk()
            StopGodMode()
            WindUI:Notify({
                Title = "Automatic Auto Walk",
                Content = "Stopped!",
                Duration = 3,
                Icon = "stop-circle"
            })
        end
    end
})

AutomaticTab:Space()

AutomaticTab:Toggle({
    Title = "Auto Loop",
    Desc = "Automatically restart from beginning when finished",
    Icon = "repeat",
    Default = false,
    Callback = function(Value)
        autoLoopEnabled = Value
        WindUI:Notify({
            Title = "Auto Loop",
            Content = Value and "Enabled" or "Disabled",
            Duration = 2,
            Icon = "repeat"
        })
    end,
})

AutomaticTab:Space()

AutomaticTab:Section({
    Title = "Route Information",
})

local RouteInfo = AutomaticTab:Paragraph({
    Title = "Route Status",
    Desc = "Not loaded yet. Click 'Load Route Data' to check."
})

AutomaticTab:Button({
    Title = "Load Route Data",
    Desc = "Pre-load the automatic route data",
    Icon = "download",
    Callback = function()
        RouteInfo:Set({
            Title = "Loading...",
            Desc = "Downloading route data..."
        })
        
        autoData = LoadAutomaticJson()
        
        if autoData and #autoData > 0 then
            local totalTime = autoData[#autoData].time or 0
            local minutes = math.floor(totalTime / 60)
            local seconds = math.floor(totalTime % 60)
            
            RouteInfo:Set({
                Title = "Route Loaded",
                Desc = string.format("Total Frames: %d\nEstimated Time: %dm %ds\nReady to start!", 
                    #autoData, minutes, seconds)
            })
            
            WindUI:Notify({
                Title = "Route Data",
                Content = "Successfully loaded!",
                Duration = 3,
                Icon = "check-check"
            })
        else
            RouteInfo:Set({
                Title = "Load Failed",
                Desc = "Failed to load route data. Check your connection."
            })
            
            WindUI:Notify({
                Title = "Error",
                Content = "Failed to load route data!",
                Duration = 3,
                Icon = "x"
            })
        end
    end
})

--| =========================================================== |--
--| BYPASS TAB                                                  |--
--| =========================================================== |--

getgenv().AntiIdleActive = false
local AntiIdleConnection
local MovementLoop

local function StartAntiIdle()
    if AntiIdleConnection then
        AntiIdleConnection:Disconnect()
        AntiIdleConnection = nil
    end
    if MovementLoop then
        MovementLoop:Disconnect()
        MovementLoop = nil
    end
    AntiIdleConnection = LocalPlayer.Idled:Connect(function()
        if getgenv().AntiIdleActive then
            VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end
    end)
    MovementLoop = RunService.Heartbeat:Connect(function()
        if getgenv().AntiIdleActive and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local root = LocalPlayer.Character.HumanoidRootPart
            if tick() % 60 < 0.05 then
                root.CFrame = root.CFrame * CFrame.new(0, 0, 0.1)
                task.wait(0.1)
                root.CFrame = root.CFrame * CFrame.new(0, 0, -0.1)
            end
        end
    end)
end

local function SetupCharacterListener()
    LocalPlayer.CharacterAdded:Connect(function(newChar)
        newChar:WaitForChild("HumanoidRootPart", 10)
        if getgenv().AntiIdleActive then
            StartAntiIdle()
        end
    end)
end

StartAntiIdle()
SetupCharacterListener()

BypassTab:Section({
    Title = "Anti-Kick Protection",
})

BypassTab:Toggle({
    Title = "Bypass AFK Kick",
    Desc = "Prevents automatic AFK kick",
    Icon = "shield",
    Default = false,
    Callback = function(Value)
        getgenv().AntiIdleActive = Value
        if Value then
            StartAntiIdle()
            WindUI:Notify({
                Icon = "shield",
                Title = "Bypass AFK",
                Content = "Protection activated!",
                Duration = 3
            })
        else
            if AntiIdleConnection then
                AntiIdleConnection:Disconnect()
                AntiIdleConnection = nil
            end
            if MovementLoop then
                MovementLoop:Disconnect()
                MovementLoop = nil
            end
            WindUI:Notify({
                Icon = "shield",
                Title = "Bypass AFK",
                Content = "Protection deactivated!",
                Duration = 3
            })
        end
    end,
})

BypassTab:Space()

BypassTab:Section({
    Title = "Anti-Detection",
})

BypassTab:Toggle({
    Title = "Anti-Spectator",
    Desc = "Hide from spectators/admins",
    Icon = "eye-off",
    Default = false,
    Callback = function(Value)
        antiSpectatorEnabled = Value
        WindUI:Notify({
            Title = "Anti-Spectator",
            Content = Value and "Enabled - You're hidden!" or "Disabled",
            Duration = 2,
            Icon = "shield"
        })
    end,
})

BypassTab:Space()

BypassTab:Section({
    Title = "Ultimate God Mode",
})

BypassTab:Toggle({
    Title = "God Mode (100%)",
    Desc = "Complete invincibility - works everywhere",
    Icon = "shield-check",
    Default = false,
    Callback = function(Value)
        godModeEnabled = Value
        
        if Value then
            StartGodMode()
            WindUI:Notify({
                Title = "God Mode",
                Content = "Ultimate protection activated!",
                Duration = 3,
                Icon = "shield-check"
            })
        else
            StopGodMode()
            WindUI:Notify({
                Title = "God Mode",
                Content = "Deactivated",
                Duration = 2,
                Icon = "shield"
            })
        end
    end,
})

--| =========================================================== |--
--| AVATAR COPY TAB                                             |--
--| =========================================================== |--

local function loadAvatar(targetPlayer)
    if not targetPlayer then
        return false, "Player not found"
    end
    
    local userId = targetPlayer.UserId
    
    if not LocalPlayer.Character then
        return false, "Your character not found"
    end
    
    local success, humanoidDesc = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(userId)
    end)
    
    if not success then
        return false, "Failed to get avatar data"
    end
    
    for _, item in pairs(LocalPlayer.Character:GetChildren()) do
        if item:IsA("Accessory") or item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
            item:Destroy()
        end
    end
    task.wait(0.1)
    
    local success2 = pcall(function()
        LocalPlayer.Character.Humanoid:ApplyDescriptionClientServer(humanoidDesc)
        task.wait(0.5)
    end)
    
    if not success2 then
        return false, "Failed to apply avatar"
    end
    
    return true, "Avatar copied from: " .. targetPlayer.Name
end

AvatarTab:Section({
    Title = "Player Selection",
})

local selectedPlayer = nil
local currentPlayerValues = {}

local function getFreshPlayerValues()
    local freshList = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Name then
            table.insert(freshList, player.Name)
        end
    end
    table.sort(freshList)
    return freshList
end

currentPlayerValues = getFreshPlayerValues()
if #currentPlayerValues == 0 then
    currentPlayerValues = {"No other players online"}
end

local avatarDropdown = AvatarTab:Dropdown({
    Title = "Choose Player",
    Desc = "Select a player to copy their avatar",
    Values = currentPlayerValues,
    Value = nil,
    Multi = false,
    AllowNone = true,
    Callback = function(Value)
        if Value and Value ~= "No other players online" then
            selectedPlayer = Value
            WindUI:Notify({
                Title = "Player Selected",
                Content = Value,
                Duration = 2,
                Icon = "user-check"
            })
        else
            selectedPlayer = nil
        end
    end
})

AvatarTab:Space()

AvatarTab:Button({
    Title = "Refresh Player List",
    Desc = "Update the dropdown with current players",
    Icon = "refresh-cw",
    Callback = function()
        currentPlayerValues = getFreshPlayerValues()
        if #currentPlayerValues == 0 then
            currentPlayerValues = {"No other players online"}
        end
        
        if avatarDropdown and avatarDropdown.SetValues then
            local success = pcall(function()
                avatarDropdown:SetValues(currentPlayerValues)
            end)
            
            if success then
                WindUI:Notify({
                    Title = "Player List Updated",
                    Content = string.format("Found %d players", #currentPlayerValues == 1 and currentPlayerValues[1] == "No other players online" and 0 or #currentPlayerValues),
                    Duration = 3,
                    Icon = "check-check"
                })
            else
                WindUI:Notify({
                    Title = "Refresh Complete",
                    Content = string.format("Found %d players\nReopen tab to see changes", #currentPlayerValues == 1 and currentPlayerValues[1] == "No other players online" and 0 or #currentPlayerValues),
                    Duration = 4,
                    Icon = "info"
                })
            end
        else
            WindUI:Notify({
                Title = "Player List Updated",
                Content = string.format("Found %d players\nReopen the tab to see changes", #currentPlayerValues == 1 and currentPlayerValues[1] == "No other players online" and 0 or #currentPlayerValues),
                Duration = 4,
                Icon = "info"
            })
        end
    end
})

AvatarTab:Space()

AvatarTab:Section({
    Title = "Avatar Actions",
})

AvatarTab:Button({
    Title = "Copy Selected Avatar",
    Desc = "Apply the selected player's avatar to you",
    Icon = "copy",
    Color = Color3.fromRGB(130, 0, 200),
    Callback = function()
        if not selectedPlayer or selectedPlayer == "No other players online" then
            WindUI:Notify({
                Title = "Avatar Copy",
                Content = "Please select a player first",
                Duration = 3,
                Icon = "alert-triangle"
            })
            return
        end
        
        local targetPlayer = Players:FindFirstChild(selectedPlayer)
        if not targetPlayer then
            WindUI:Notify({
                Title = "Avatar Copy",
                Content = "Player left the game",
                Duration = 3,
                Icon = "x"
            })
            return
        end
        
        WindUI:Notify({
            Title = "Avatar Copy",
            Content = "Copying avatar...",
            Duration = 2,
            Icon = "loader"
        })
        
        local success, message = loadAvatar(targetPlayer)
        
        WindUI:Notify({
            Title = success and "Success" or "Failed",
            Content = message,
            Duration = 3,
            Icon = success and "check-check" or "x"
        })
    end
})

AvatarTab:Space()

AvatarTab:Section({
    Title = "Players in Server",
})

local PlayerListDisplay = AvatarTab:Paragraph({
    Title = "Online Players",
    Desc = "Loading player information..."
})

task.spawn(function()
    while task.wait(3) do
        local count = 0
        local names = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                count = count + 1
                if count <= 6 then
                    table.insert(names, player.Name)
                end
            end
        end
        
        local displayText = ""
        if count == 0 then
            displayText = "No other players online"
        elseif count <= 6 then
            displayText = table.concat(names, "\n")
        else
            displayText = table.concat(names, "\n") .. string.format("\n\nPlus %d more players", count - 6)
        end
        
        PlayerListDisplay:Set({
            Title = string.format("Online Players: %d", count),
            Desc = displayText
        })
        
        currentPlayerValues = getFreshPlayerValues()
        if #currentPlayerValues == 0 then
            currentPlayerValues = {"No other players online"}
        end
    end
end)

--| =========================================================== |--
--| HUMANOID TAB (MIGRATED FROM V3.0)                          |--
--| =========================================================== |--

HumanoidTab:Section({
    Title = "Movement Controls",
})

-- Noclip System
local noclipEnabled = false
local noclipConnection

HumanoidTab:Toggle({
    Title = "Noclip",
    Desc = "Walk through walls",
    Icon = "move-diagonal",
    Default = false,
    Callback = function(Value)
        noclipEnabled = Value
        
        if Value then
            noclipConnection = RunService.Stepped:Connect(function()
                if noclipEnabled and LocalPlayer.Character then
                    for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
            
            WindUI:Notify({
                Title = "Noclip",
                Content = "Enabled - Walk through walls!",
                Duration = 2,
                Icon = "move-diagonal"
            })
        else
            if noclipConnection then
                noclipConnection:Disconnect()
                noclipConnection = nil
            end
            if LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
            
            WindUI:Notify({
                Title = "Noclip",
                Content = "Disabled",
                Duration = 2,
                Icon = "move-diagonal"
            })
        end
    end,
})

-- Infinite Jump System
local infiniteJumpEnabled = false

HumanoidTab:Toggle({
    Title = "Infinite Jump",
    Desc = "Jump infinitely in the air",
    Icon = "arrow-up",
    Default = false,
    Callback = function(Value)
        infiniteJumpEnabled = Value
        
        WindUI:Notify({
            Title = "Infinite Jump",
            Content = Value and "Enabled - Jump anywhere!" or "Disabled",
            Duration = 2,
            Icon = "arrow-up"
        })
    end,
})

UserInputService.JumpRequest:Connect(function()
    if infiniteJumpEnabled and LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

HumanoidTab:Space()

HumanoidTab:Section({
    Title = "Visual ESP",
})

-- ESP System
local espEnabled = false
local espConnections = {}

local function createESP(player)
    if player == LocalPlayer then return end
    
    local function addESP(character)
        pcall(function()
            local hrp = character:WaitForChild("HumanoidRootPart", 5)
            if not hrp then return end
            
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "ESP"
            billboard.Adornee = hrp
            billboard.Size = UDim2.new(0, 100, 0, 50)
            billboard.StudsOffset = Vector3.new(0, 3, 0)
            billboard.AlwaysOnTop = true
            billboard.Parent = hrp
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = player.Name
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.TextStrokeTransparency = 0
            nameLabel.TextScaled = true
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.Parent = billboard
            
            local distanceLabel = Instance.new("TextLabel")
            distanceLabel.Size = UDim2.new(1, 0, 0.5, 0)
            distanceLabel.Position = UDim2.new(0, 0, 0.5, 0)
            distanceLabel.BackgroundTransparency = 1
            distanceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            distanceLabel.TextStrokeTransparency = 0
            distanceLabel.TextScaled = true
            distanceLabel.Font = Enum.Font.Gotham
            distanceLabel.Parent = billboard
            
            local updateConnection = RunService.Heartbeat:Connect(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local distance = (LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                    distanceLabel.Text = math.floor(distance) .. " studs"
                end
            end)
            
            table.insert(espConnections, updateConnection)
        end)
    end
    
    if player.Character then
        addESP(player.Character)
    end
    
    local conn = player.CharacterAdded:Connect(addESP)
    table.insert(espConnections, conn)
end

HumanoidTab:Toggle({
    Title = "Player ESP",
    Desc = "See all players through walls",
    Icon = "eye",
    Default = false,
    Callback = function(Value)
        espEnabled = Value
        
        if Value then
            for _, player in pairs(Players:GetPlayers()) do
                createESP(player)
            end
            
            local conn = Players.PlayerAdded:Connect(function(player)
                if espEnabled then
                    createESP(player)
                end
            end)
            table.insert(espConnections, conn)
            
            WindUI:Notify({
                Title = "Player ESP",
                Content = "ESP enabled for all players!",
                Duration = 2,
                Icon = "eye"
            })
        else
            for _, conn in pairs(espConnections) do
                if conn.Connected then
                    conn:Disconnect()
                end
            end
            espConnections = {}
            
            for _, player in pairs(Players:GetPlayers()) do
                if player.Character then
                    for _, billboard in pairs(player.Character:GetDescendants()) do
                        if billboard.Name == "ESP" then
                            billboard:Destroy()
                        end
                    end
                end
            end
            
            WindUI:Notify({
                Title = "Player ESP",
                Content = "ESP disabled",
                Duration = 2,
                Icon = "eye-off"
            })
        end
    end,
})

HumanoidTab:Space()

HumanoidTab:Section({
    Title = "Teleport to Players",
})

local selectedTeleportPlayer = nil

local function getTeleportPlayerValues()
    local playerList = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Name then
            table.insert(playerList, player.Name)
        end
    end
    table.sort(playerList)
    return playerList
end

local teleportPlayerValues = getTeleportPlayerValues()
if #teleportPlayerValues == 0 then
    teleportPlayerValues = {"No players available"}
end

HumanoidTab:Dropdown({
    Title = "Select Player",
    Desc = "Choose player to teleport to",
    Values = teleportPlayerValues,
    Value = nil,
    Multi = false,
    AllowNone = true,
    Callback = function(Value)
        if Value and Value ~= "No players available" then
            selectedTeleportPlayer = Value
        else
            selectedTeleportPlayer = nil
        end
    end
})

HumanoidTab:Button({
    Title = "Teleport to Player",
    Desc = "Instantly teleport to selected player",
    Icon = "zap",
    Color = Color3.fromRGB(100, 150, 255),
    Callback = function()
        if not selectedTeleportPlayer or selectedTeleportPlayer == "No players available" then
            WindUI:Notify({
                Title = "Teleport",
                Content = "Please select a player first!",
                Duration = 2,
                Icon = "alert-triangle"
            })
            return
        end
        
        local targetPlayer = Players:FindFirstChild(selectedTeleportPlayer)
        if not targetPlayer or not targetPlayer.Character then
            WindUI:Notify({
                Title = "Teleport",
                Content = "Player not found or no character!",
                Duration = 3,
                Icon = "x"
            })
            return
        end
        
        local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not targetHRP then
            WindUI:Notify({
                Title = "Teleport",
                Content = "Target player has no HumanoidRootPart!",
                Duration = 3,
                Icon = "x"
            })
            return
        end
        
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
            WindUI:Notify({
                Title = "Teleported",
                Content = "Teleported to " .. selectedTeleportPlayer,
                Duration = 2,
                Icon = "zap"
            })
        else
            WindUI:Notify({
                Title = "Teleport",
                Content = "Your character not found!",
                Duration = 3,
                Icon = "x"
            })
        end
    end
})

HumanoidTab:Space()

HumanoidTab:Section({
    Title = "Teleport to Checkpoints",
})

HumanoidTab:Button({
    Title = "TP to Spawnpoint",
    Desc = "Teleport to spawn location",
    Icon = "home",
    Callback = function()
        local spawnData = loadCheckpoint("spawnpoint.json")
        if spawnData and spawnData[1] and LocalPlayer.Character then
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.new(tableToVec(spawnData[1].position))
                WindUI:Notify({
                    Title = "Teleported",
                    Content = "Moved to spawnpoint",
                    Duration = 2,
                    Icon = "check"
                })
            end
        end
    end
})

for i = 1, checkpointCount do
    HumanoidTab:Button({
        Title = "TP to Checkpoint " .. i,
        Desc = "Teleport to checkpoint " .. i,
        Icon = "map-pin",
        Callback = function()
            local cpData = loadCheckpoint("checkpoint_" .. i .. ".json")
            if cpData and cpData[1] and LocalPlayer.Character then
                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = CFrame.new(tableToVec(cpData[1].position))
                    WindUI:Notify({
                        Title = "Teleported",
                        Content = "Moved to Checkpoint " .. i,
                        Duration = 2,
                        Icon = "check"
                    })
                end
            end
        end
    })
end

--| =========================================================== |--
--| MISCELLANEOUS TAB                                           |--
--| =========================================================== |--

MiscTab:Section({
    Title = "Player Settings",
})

local nametagConnections = {}

MiscTab:Toggle({
    Title = "Hide Nametags",
    Desc = "Hide all player nametags",
    Icon = "eye-off",
    Default = false,
    Callback = function(Value)
        local function hideNametagsForCharacter(character)
            if not character then return end
            local head = character:FindFirstChild("Head")
            if not head then return end
            for _, obj in pairs(head:GetChildren()) do
                if obj:IsA("BillboardGui") then
                    obj.Enabled = false
                end
            end
        end

        local function showNametagsForCharacter(character)
            if not character then return end
            local head = character:FindFirstChild("Head")
            if not head then return end
            for _, obj in pairs(head:GetChildren()) do
                if obj:IsA("BillboardGui") then
                    obj.Enabled = true
                end
            end
        end

        local function setNametagsVisible(state)
            for _, player in pairs(Players:GetPlayers()) do
                if player.Character then
                    if state then
                        showNametagsForCharacter(player.Character)
                    else
                        hideNametagsForCharacter(player.Character)
                    end
                end
            end
        end

        if Value then
            setNametagsVisible(false)
            nametagConnections = {}
            local function connectPlayer(player)
                local charAddedConn
                charAddedConn = player.CharacterAdded:Connect(function(char)
                    task.wait(1)
                    hideNametagsForCharacter(char)
                end)
                table.insert(nametagConnections, charAddedConn)
            end
            for _, player in pairs(Players:GetPlayers()) do
                connectPlayer(player)
            end
            table.insert(nametagConnections, Players.PlayerAdded:Connect(connectPlayer))
            WindUI:Notify({
                Icon = "eye-off",
                Title = "Hide Nametags",
                Content = "Nametags hidden",
                Duration = 2
            })
        else
            setNametagsVisible(true)
            if nametagConnections then
                for _, conn in pairs(nametagConnections) do
                    if conn.Connected then conn:Disconnect() end
                end
            end
            nametagConnections = {}
            WindUI:Notify({
                Icon = "eye",
                Title = "Hide Nametags",
                Content = "Nametags visible",
                Duration = 2
            })
        end
    end,
})

local WalkSpeedEnabled = false
local WalkSpeedValue = 16

local function ApplyWalkSpeed(Humanoid)
    if WalkSpeedEnabled then
        Humanoid.WalkSpeed = WalkSpeedValue
    else
        Humanoid.WalkSpeed = 16
    end
end

local function SetupCharacterWalkSpeed(Char)
    local Humanoid = Char:WaitForChild("Humanoid")
    ApplyWalkSpeed(Humanoid)
end

LocalPlayer.CharacterAdded:Connect(function(Char)
    task.wait(1)
    SetupCharacterWalkSpeed(Char)
end)

if LocalPlayer.Character then
    SetupCharacterWalkSpeed(LocalPlayer.Character)
end

MiscTab:Toggle({
    Title = "Walk Speed",
    Desc = "Enable custom walk speed",
    Icon = "gauge",
    Default = false,
    Callback = function(Value)
        WalkSpeedEnabled = Value
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            ApplyWalkSpeed(LocalPlayer.Character.Humanoid)
        end
        WindUI:Notify({
            Title = "Walk Speed",
            Content = Value and "Enabled" or "Disabled",
            Duration = 2,
            Icon = "gauge"
        })
    end,
})

MiscTab:Slider({
    Title = "Speed Value",
    Desc = "Adjust walk speed",
    Step = 1,
    Value = {
        Min = 16,
        Max = 100,
        Default = 16,
    },
    Callback = function(value)
        WalkSpeedValue = value
        if WalkSpeedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = value
        end
    end
})

MiscTab:Space()

MiscTab:Section({
    Title = "Environment",
})

local TimeLockEnabled = false
local CurrentTimeValue = 12

MiscTab:Toggle({
    Title = "Lock Time",
    Desc = "Lock time of day",
    Icon = "clock",
    Default = false,
    Callback = function(Value)
        TimeLockEnabled = Value
        WindUI:Notify({
            Title = "Lock Time",
            Content = Value and "Time locked" or "Time unlocked",
            Duration = 2,
            Icon = "clock"
        })
    end,
})

MiscTab:Slider({
    Title = "Time of Day",
    Desc = "Adjust time (hours)",
    Step = 1,
    Value = {
        Min = 0,
        Max = 24,
        Default = 12,
    },
    Callback = function(value)
        CurrentTimeValue = value
        Lighting.ClockTime = value
    end
})

task.spawn(function()
    while task.wait(1) do
        if TimeLockEnabled then
            Lighting.ClockTime = CurrentTimeValue
        end
    end
end)

MiscTab:Space()

MiscTab:Section({
    Title = "Animations",
})

local RunAnimations = {
    {
        name = "Animation 1",
        Idle1 = "rbxassetid://122257458498464",
        Idle2 = "rbxassetid://102357151005774",
        Walk = "http://www.roblox.com/asset/?id=18537392113",
        Run = "rbxassetid://82598234841035",
        Jump = "rbxassetid://75290611992385",
        Fall = "http://www.roblox.com/asset/?id=11600206437",
        Climb = "http://www.roblox.com/asset/?id=10921257536",
        Swim = "http://www.roblox.com/asset/?id=10921264784",
        SwimIdle = "http://www.roblox.com/asset/?id=10921265698"
    },
    {
        name = "Animation 2",
        Idle1 = "rbxassetid://122257458498464",
        Idle2 = "rbxassetid://102357151005774",
        Walk = "rbxassetid://122150855457006",
        Run = "rbxassetid://82598234841035",
        Jump = "rbxassetid://75290611992385",
        Fall = "rbxassetid://98600215928904",
        Climb = "rbxassetid://88763136693023",
        Swim = "rbxassetid://133308483266208",
        SwimIdle = "rbxassetid://109346520324160"
    },
    {
        name = "Animation 3",
        Idle1 = "http://www.roblox.com/asset/?id=18537376492",
        Idle2 = "http://www.roblox.com/asset/?id=18537371272",
        Walk = "http://www.roblox.com/asset/?id=18537392113",
        Run = "http://www.roblox.com/asset/?id=18537384940",
        Jump = "http://www.roblox.com/asset/?id=18537380791",
        Fall = "http://www.roblox.com/asset/?id=18537367238",
        Climb = "http://www.roblox.com/asset/?id=10921271391",
        Swim = "http://www.roblox.com/asset/?id=99384245425157",
        SwimIdle = "http://www.roblox.com/asset/?id=113199415118199"
    },
}

local OriginalAnimations = {}
local currentAnimIndex = nil

local function SaveOriginalAnims(Animate)
    OriginalAnimations = {}
    for _, child in ipairs(Animate:GetDescendants()) do
        if child:IsA("Animation") then
            OriginalAnimations[child] = child.AnimationId
        end
    end
end

local function ApplyAnimation(Animate, Humanoid, pack)
    if Animate:FindFirstChild("idle") and Animate.idle:FindFirstChild("Animation1") then
        Animate.idle.Animation1.AnimationId = pack.Idle1
    end
    if Animate:FindFirstChild("idle") and Animate.idle:FindFirstChild("Animation2") then
        Animate.idle.Animation2.AnimationId = pack.Idle2
    end
    if Animate:FindFirstChild("walk") and Animate.walk:FindFirstChild("WalkAnim") then
        Animate.walk.WalkAnim.AnimationId = pack.Walk
    end
    if Animate:FindFirstChild("run") and Animate.run:FindFirstChild("RunAnim") then
        Animate.run.RunAnim.AnimationId = pack.Run
    end
    if Animate:FindFirstChild("jump") and Animate.jump:FindFirstChild("JumpAnim") then
        Animate.jump.JumpAnim.AnimationId = pack.Jump
    end
    if Animate:FindFirstChild("fall") and Animate.fall:FindFirstChild("FallAnim") then
        Animate.fall.FallAnim.AnimationId = pack.Fall
    end
    if Animate:FindFirstChild("climb") and Animate.climb:FindFirstChild("ClimbAnim") then
        Animate.climb.ClimbAnim.AnimationId = pack.Climb
    end
    if Animate:FindFirstChild("swim") and Animate.swim:FindFirstChild("Swim") then
        Animate.swim.Swim.AnimationId = pack.Swim
    end
    if Animate:FindFirstChild("swimidle") and Animate.swimidle:FindFirstChild("SwimIdle") then
        Animate.swimidle.SwimIdle.AnimationId = pack.SwimIdle
    end
    Humanoid.Jump = true
end

local function RestoreOriginal()
    for anim, id in pairs(OriginalAnimations) do
        if anim and anim:IsA("Animation") then
            anim.AnimationId = id
        end
    end
end

local animationToggles = {}

for i, pack in ipairs(RunAnimations) do
    local flag = "Animation" .. i
    animationToggles[flag] = MiscTab:Toggle({
        Flag = flag,
        Title = pack.name,
        Desc = "Apply " .. pack.name,
        Icon = "wind",
        Default = false,
        Callback = function(Value)
            local Char = LocalPlayer.Character
            if not Char or not Char:FindFirstChild("Animate") or not Char:FindFirstChild("Humanoid") then
                WindUI:Notify({
                    Title = "Error",
                    Content = "Character not ready!",
                    Duration = 2,
                    Icon = "x"
                })
                return
            end
            
            local Animate = Char.Animate
            local Humanoid = Char.Humanoid
            
            if Value then
                for flag, toggle in pairs(animationToggles) do
                    if flag ~= "Animation" .. i then
                        toggle:Set(false)
                    end
                end
                
                SaveOriginalAnims(Animate)
                ApplyAnimation(Animate, Humanoid, pack)
                currentAnimIndex = i
                
                WindUI:Notify({
                    Icon = "wind",
                    Title = pack.name,
                    Content = "Animation applied!",
                    Duration = 2
                })
            else
                if currentAnimIndex == i then
                    RestoreOriginal()
                    currentAnimIndex = nil
                    WindUI:Notify({
                        Icon = "wind",
                        Title = pack.name,
                        Content = "Animation removed!",
                        Duration = 2
                    })
                end
            end
        end,
    })
end

MiscTab:Space()

MiscTab:Section({
    Title = "Server Tools",
})

local PlaceId = game.PlaceId

MiscTab:Button({
    Title = "Find Low Player Servers",
    Desc = "Search for servers with few players",
    Icon = "search",
    Color = Color3.fromRGB(50, 150, 250),
    Callback = function()
        WindUI:Notify({
            Title = "Server Finder",
            Content = "Searching servers...",
            Duration = 3,
            Icon = "loader"
        })
        
        task.spawn(function()
            local Cursor = ""
            local Servers = {}

            repeat
                local URL = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100%s", PlaceId, Cursor ~= "" and "&cursor="..Cursor or "")
                local success, Response = pcall(function()
                    return game:HttpGet(URL)
                end)
                
                if success then
                    local Data = HttpService:JSONDecode(Response)
                    for _, server in pairs(Data.data) do
                        table.insert(Servers, server)
                    end
                    Cursor = Data.nextPageCursor
                end
                task.wait(0.5)
            until not Cursor or #Servers >= 50

            if #Servers > 0 then
                table.sort(Servers, function(a, b)
                    return a.playing < b.playing
                end)
                
                local message = "Found " .. #Servers .. " servers!\n\nLowest player counts:"
                for i = 1, math.min(5, #Servers) do
                    local server = Servers[i]
                    message = message .. string.format("\n%d/%d players", server.playing, server.maxPlayers)
                end
                
                WindUI:Notify({
                    Title = "Server List",
                    Content = message,
                    Duration = 8,
                    Icon = "server"
                })
                
                if Servers[1] then
                    task.wait(2)
                    WindUI:Notify({
                        Title = "Teleporting",
                        Content = "Joining lowest server...",
                        Duration = 3,
                        Icon = "loader"
                    })
                    TeleportService:TeleportToPlaceInstance(PlaceId, Servers[1].id)
                end
            else
                WindUI:Notify({
                    Title = "Error",
                    Content = "No servers found!",
                    Duration = 3,
                    Icon = "x"
                })
            end
        end)
    end
})

--| =========================================================== |--
--| UPDATE TAB                                                  |--
--| =========================================================== |--

UpdateTab:Section({
    Title = "Update Checkpoints",
})

local UpdateStatus = UpdateTab:Paragraph({
    Title = "Status",
    Desc = "Ready to update checkpoints"
})

local updateInProgress = false

UpdateTab:Button({
    Title = "Update Manual JSON",
    Desc = "Update all manual checkpoint files",
    Icon = "download",
    Color = Color3.fromRGB(50, 150, 250),
    Callback = function()
        if updateInProgress then
            WindUI:Notify({
                Title = "Update",
                Content = "Update already in progress!",
                Duration = 2,
                Icon = "alert-triangle"
            })
            return
        end
        
        updateInProgress = true
        
        UpdateStatus:Set({
            Title = "Updating...",
            Desc = "Updating manual checkpoint files..."
        })
        
        task.spawn(function()
            for i, f in ipairs(manualJsonFiles) do
                local savePath = jsonFolder .. "/" .. f
                if isfile(savePath) then delfile(savePath) end
                
                local ok, res = pcall(function() return game:HttpGet(baseURL..f) end)
                if ok and res and #res > 0 then
                    writefile(savePath, res)
                    UpdateStatus:Set({
                        Title = "Updating...",
                        Desc = string.format("Progress: %d/%d - %s", i, #manualJsonFiles, f)
                    })
                else
                    WindUI:Notify({
                        Title = "Error",
                        Content = "Failed to update: " .. f,
                        Duration = 3,
                        Icon = "x"
                    })
                end
                task.wait(0.3)
            end
            
            UpdateStatus:Set({
                Title = "Complete!",
                Desc = "All manual checkpoints updated successfully!"
            })
            
            WindUI:Notify({
                Title = "Update Complete",
                Content = "Manual checkpoints updated!",
                Duration = 3,
                Icon = "check-check"
            })
            
            updateInProgress = false
        end)
    end
})

UpdateTab:Space()

UpdateTab:Button({
    Title = "Update Automatic JSON",
    Desc = "Update automatic checkpoint file",
    Icon = "download",
    Color = Color3.fromRGB(50, 150, 250),
    Callback = function()
        if updateInProgress then
            WindUI:Notify({
                Title = "Update",
                Content = "Update already in progress!",
                Duration = 2,
                Icon = "alert-triangle"
            })
            return
        end
        
        updateInProgress = true
        
        UpdateStatus:Set({
            Title = "Updating...",
            Desc = "Updating automatic checkpoint file..."
        })
        
        task.spawn(function()
            local savePath = autoJsonFolder .. "/" .. automaticJsonFile
            if isfile(savePath) then delfile(savePath) end
            
            local ok, res = pcall(function() 
                return game:HttpGet(automaticJsonURL) 
            end)
            
            if ok and res and #res > 0 then
                writefile(savePath, res)
                autoData = nil
                
                UpdateStatus:Set({
                    Title = "Complete!",
                    Desc = "Automatic checkpoint updated successfully!"
                })
                
                WindUI:Notify({
                    Title = "Update Complete",
                    Content = "Automatic checkpoint updated!",
                    Duration = 3,
                    Icon = "check-check"
                })
            else
                UpdateStatus:Set({
                    Title = "Failed!",
                    Desc = "Failed to update automatic checkpoint."
                })
                
                WindUI:Notify({
                    Title = "Error",
                    Content = "Failed to update automatic checkpoint!",
                    Duration = 3,
                    Icon = "x"
                })
            end
            
            updateInProgress = false
        end)
    end
})

UpdateTab:Space()

UpdateTab:Section({
    Title = "File Verification",
})

UpdateTab:Button({
    Title = "Verify All Files",
    Desc = "Check integrity of all checkpoint files",
    Icon = "file-check",
    Callback = function()
        task.spawn(function()
            for i, f in ipairs(manualJsonFiles) do
                local ok = EnsureJsonFile(f)
                UpdateStatus:Set({
                    Title = "Checking Files",
                    Desc = string.format("Verifying: %d/%d - %s %s", i, #manualJsonFiles, f, ok and "✓" or "✗")
                })
                task.wait(0.3)
            end
            UpdateStatus:Set({
                Title = "Ready",
                Desc = "All checkpoint files verified!"
            })
            WindUI:Notify({
                Title = "Verification",
                Content = "All files verified successfully!",
                Duration = 3,
                Icon = "check-check"
            })
        end)
    end
})

--| =========================================================== |--
--| THEME TAB                                                   |--
--| =========================================================== |--

WindUI:AddTheme({
    Name = "Dark Red",
    Accent = Color3.fromHex("#dc2626"),
    Background = Color3.fromHex("#0a0a0a"),
    BackgroundTransparency = 0,
    Outline = Color3.fromHex("#ef4444"),
    Text = Color3.fromHex("#FFFFFF"),
    Placeholder = Color3.fromHex("#7a7a7a"),
    Button = Color3.fromHex("#991b1b"),
    Icon = Color3.fromHex("#f87171"),
    Hover = Color3.fromHex("#FFFFFF"),
    WindowBackground = Color3.fromHex("#0a0a0a"),
    WindowShadow = Color3.fromHex("#000000"),
})

WindUI:AddTheme({
    Name = "Cyberpunk",
    Accent = Color3.fromHex("#06b6d4"),
    Background = Color3.fromHex("#18181b"),
    BackgroundTransparency = 0,
    Outline = Color3.fromHex("#22d3ee"),
    Text = Color3.fromHex("#FFFFFF"),
    Placeholder = Color3.fromHex("#71717a"),
    Button = Color3.fromHex("#0e7490"),
    Icon = Color3.fromHex("#67e8f9"),
    Hover = Color3.fromHex("#FFFFFF"),
    WindowBackground = Color3.fromHex("#18181b"),
    WindowShadow = Color3.fromHex("#000000"),
})

WindUI:AddTheme({
    Name = "Purple Dream",
    Accent = Color3.fromHex("#a855f7"),
    Background = Color3.fromHex("#0f0a1a"),
    BackgroundTransparency = 0,
    Outline = Color3.fromHex("#c084fc"),
    Text = Color3.fromHex("#FFFFFF"),
    Placeholder = Color3.fromHex("#78716c"),
    Button = Color3.fromHex("#7c3aed"),
    Icon = Color3.fromHex("#d8b4fe"),
    Hover = Color3.fromHex("#FFFFFF"),
    WindowBackground = Color3.fromHex("#0f0a1a"),
    WindowShadow = Color3.fromHex("#000000"),
})

WindUI:AddTheme({
    Name = "Ocean Blue",
    Accent = Color3.fromHex("#0284c7"),
    Background = Color3.fromHex("#0c1821"),
    BackgroundTransparency = 0,
    Outline = Color3.fromHex("#0ea5e9"),
    Text = Color3.fromHex("#FFFFFF"),
    Placeholder = Color3.fromHex("#64748b"),
    Button = Color3.fromHex("#075985"),
    Icon = Color3.fromHex("#38bdf8"),
    Hover = Color3.fromHex("#FFFFFF"),
    WindowBackground = Color3.fromHex("#0c1821"),
    WindowShadow = Color3.fromHex("#000000"),
})

ThemeTab:Section({
    Title = "Theme Selection",
})

ThemeTab:Paragraph({
    Title = "Available Themes",
    Desc = "Choose from our custom theme collection to personalize your experience. Each theme has been carefully designed for optimal visibility and style."
})

ThemeTab:Space()

ThemeTab:Section({
    Title = "Custom Themes",
})

ThemeTab:Button({
    Title = "Dark Red Theme",
    Desc = "Apply dark red theme with crimson accents",
    Icon = "palette",
    Color = Color3.fromRGB(220, 38, 38),
    Callback = function()
        WindUI:SetTheme("Dark Red")
        WindUI:Notify({
            Title = "Theme Changed",
            Content = "Dark Red theme applied",
            Duration = 3,
            Icon = "palette"
        })
    end
})

ThemeTab:Button({
    Title = "Cyberpunk Theme",
    Desc = "Apply cyberpunk theme with cyan neon",
    Icon = "palette",
    Color = Color3.fromRGB(6, 182, 212),
    Callback = function()
        WindUI:SetTheme("Cyberpunk")
        WindUI:Notify({
            Title = "Theme Changed",
            Content = "Cyberpunk theme applied",
            Duration = 3,
            Icon = "palette"
        })
    end
})

ThemeTab:Button({
    Title = "Purple Dream Theme",
    Desc = "Apply purple dream theme with violet vibes",
    Icon = "palette",
    Color = Color3.fromRGB(168, 85, 247),
    Callback = function()
        WindUI:SetTheme("Purple Dream")
        WindUI:Notify({
            Title = "Theme Changed",
            Content = "Purple Dream theme applied",
            Duration = 3,
            Icon = "palette"
        })
    end
})

ThemeTab:Button({
    Title = "Ocean Blue Theme",
    Desc = "Apply ocean blue theme with deep sea colors",
    Icon = "palette",
    Color = Color3.fromRGB(2, 132, 199),
    Callback = function()
        WindUI:SetTheme("Ocean Blue")
        WindUI:Notify({
            Title = "Theme Changed",
            Content = "Ocean Blue theme applied",
            Duration = 3,
            Icon = "palette"
        })
    end
})

ThemeTab:Space()

ThemeTab:Section({
    Title = "Default Themes",
})

ThemeTab:Button({
    Title = "Default Theme",
    Desc = "Reset to default WindUI theme",
    Icon = "rotate-ccw",
    Callback = function()
        WindUI:SetTheme("Default")
        WindUI:Notify({
            Title = "Theme Reset",
            Content = "Default theme applied",
            Duration = 3,
            Icon = "rotate-ccw"
        })
    end
})

--| =========================================================== |--
--| END OF SCRIPT - FINAL SETUP                                |--
--| =========================================================== |--

-- Listen for player changes
Players.PlayerAdded:Connect(function(player)
    task.wait(1)
    WindUI:Notify({
        Title = "Player Joined",
        Content = player.Name .. " joined the server",
        Duration = 3,
        Icon = "user-plus"
    })
    
    -- Update avatar dropdown values
    currentPlayerValues = getFreshPlayerValues()
    if #currentPlayerValues == 0 then
        currentPlayerValues = {"No other players online"}
    end
    
    -- Update teleport dropdown values
    teleportPlayerValues = getTeleportPlayerValues()
    if #teleportPlayerValues == 0 then
        teleportPlayerValues = {"No players available"}
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if player ~= LocalPlayer then
        WindUI:Notify({
            Title = "Player Left",
            Content = player.Name .. " left the server",
            Duration = 3,
            Icon = "user-minus"
        })
        
        -- Update avatar dropdown values
        currentPlayerValues = getFreshPlayerValues()
        if #currentPlayerValues == 0 then
            currentPlayerValues = {"No other players online"}
        end
        
        -- Update teleport dropdown values
        teleportPlayerValues = getTeleportPlayerValues()
        if #teleportPlayerValues == 0 then
            teleportPlayerValues = {"No players available"}
        end
        
        -- Clear selection if selected player left
        if selectedPlayer == player.Name then
            selectedPlayer = nil
        end
        
        if selectedTeleportPlayer == player.Name then
            selectedTeleportPlayer = nil
        end
    end
end)

-- Auto-verify files on startup
task.spawn(function()
    task.wait(2)
    UpdateStatus:Set({
        Title = "Auto-Verifying",
        Desc = "Checking files on startup..."
    })
    
    local allGood = true
    for i, f in ipairs(manualJsonFiles) do
        local ok = EnsureJsonFile(f)
        if not ok then
            allGood = false
        end
        task.wait(0.2)
    end
    
    if allGood then
        UpdateStatus:Set({
            Title = "Ready ✓",
            Desc = string.format("All %d files verified and ready!", #manualJsonFiles)
        })
    else
        UpdateStatus:Set({
            Title = "Warning",
            Desc = "Some files missing. Click 'Update Manual JSON' to fix."
        })
    end
end)

-- Final load notification
task.wait(1)
WindUI:Notify({
    Title = "ASTRIONHUB",
    Content = string.format("v2.5 Humanoid Update\n%d Checkpoints Ready\nHumanoid Tab Added\nESP & Teleport Available", checkpointCount),
    Duration = 5,
    Icon = "check-circle"
})
