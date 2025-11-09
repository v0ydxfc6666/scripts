
-- ============================================================
-- ASTRIONHUB V2.5 - COMPLETE SCRIPT
-- ============================================================
-- CORE (fungsi asli + log/notify)
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
local hrp = nil
local Packs = {
    lucide = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua"))(),
    craft  = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/craft/dist/Icons.lua"))(),
    geist  = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/geist/dist/Icons.lua"))(),
}

local function refreshHRP(char)
    if not char then
        char = player.Character or player.CharacterAdded:Wait()
    end
    hrp = char:WaitForChild("HumanoidRootPart")
end
if player.Character then refreshHRP(player.Character) end
player.CharacterAdded:Connect(refreshHRP)

-- ============================================================
-- ASTRION JSON STRUCTURE VARIABLES
-- ============================================================
local mainFolder = "ASTRIONHUB"
local jsonFolder = mainFolder .. "/json_routes"
if not isfolder(mainFolder) then makefolder(mainFolder) end
if not isfolder(jsonFolder) then makefolder(jsonFolder) end

local playbackRate = 1.0
local isRunning = false
local routes = {}
local isLooping = false
local heightOffset = 0

-- Smoothing constants
local POSITION_SMOOTH = 0.96
local VELOCITY_SMOOTH = 0.94
local MOVE_SMOOTH = 0.93
local ROTATION_SMOOTH = 0.15

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================
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

-- ============================================================
-- IMPROVED SMOOTH RUNNING TO POSITION (WITH RUNNING STATE)
-- ============================================================
local function smoothRunToPosition(targetPos, timeout)
    local char = player.Character
    if not char then return false end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChild("Humanoid")
    if not hrp or not humanoid then return false end
    
    local startTime = tick()
    local maxTime = timeout or 15
    local reached = false
    
    print("🏃 Running to position...")
    
    -- Force running state
    humanoid:ChangeState(Enum.HumanoidStateType.Running)
    
    local moveConnection
    moveConnection = RunService.Heartbeat:Connect(function(dt)
        if not hrp or not hrp.Parent or not humanoid or not humanoid.Parent then
            if moveConnection then moveConnection:Disconnect() end
            return
        end
        
        local currentPos = hrp.Position
        local direction = (targetPos - currentPos)
        local distance = direction.Magnitude
        
        -- Check if reached (toleran 5 studs)
        if distance < 5 then
            reached = true
            humanoid:Move(Vector3.zero, false)
            if moveConnection then moveConnection:Disconnect() end
            print("✅ Reached position!")
            return
        end
        
        -- Check timeout
        if tick() - startTime > maxTime then
            print("⏱️ Timeout reaching position, continuing anyway...")
            reached = true
            humanoid:Move(Vector3.zero, false)
            if moveConnection then moveConnection:Disconnect() end
            return
        end
        
        -- Calculate target direction (flat, ignore Y)
        local flatDirection = Vector3.new(direction.X, 0, direction.Z)
        if flatDirection.Magnitude > 0.1 then
            flatDirection = flatDirection.Unit
            
            -- Rotate towards target
            local lookPos = Vector3.new(targetPos.X, currentPos.Y, targetPos.Z)
            local targetCFrame = CFrame.lookAt(currentPos, lookPos)
            hrp.CFrame = hrp.CFrame:Lerp(targetCFrame, 0.3)
            
            -- Move forward
            humanoid:Move(flatDirection, false)
            
            -- Apply velocity boost
            local forwardVel = flatDirection * 18
            hrp.AssemblyLinearVelocity = Vector3.new(forwardVel.X, hrp.AssemblyLinearVelocity.Y, forwardVel.Z)
        end
    end)
    
    -- Wait for completion
    while not reached and (tick() - startTime) < maxTime do
        task.wait(0.1)
    end
    
    if moveConnection then
        moveConnection:Disconnect()
    end
    
    -- Stop all movement
    if humanoid and humanoid.Parent then
        humanoid:Move(Vector3.zero, false)
    end
    
    return reached
end

-- ============================================================
-- JUMP DETECTOR
-- ============================================================
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

-- ============================================================
-- LOAD JSON ROUTES
-- ============================================================
local function loadRoute(url, routeName)
    local fileName = routeName:gsub("%s+", "_") .. ".json"
    local savePath = jsonFolder .. "/" .. fileName
    
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
        return game:HttpGet(url) 
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
    
    warn("Gagal load route: " .. routeName)
    return nil
end

-- ============================================================
-- ROUTE CONFIGURATION
-- ============================================================
routes = {
    {
        name = "BASE → CP8",
        url = "https://raw.githubusercontent.com/v0ydxfc6666/json/refs/heads/main/merged_173031.json",
        data = nil
    },
}

-- Load semua routes
for i, route in ipairs(routes) do
    route.data = loadRoute(route.url, route.name)
end

-- ============================================================
-- FIND NEAREST FUNCTIONS
-- ============================================================
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

local function getNearestRoute()
    local nearestIdx, dist = 1, math.huge
    if hrp then
        local pos = hrp.Position
        for i, route in ipairs(routes) do
            if route.data then
                for _, frame in ipairs(route.data) do
                    local framePos = tableToVec(frame.position)
                    local d = (framePos - pos).Magnitude
                    if d < dist then
                        dist = d
                        nearestIdx = i
                    end
                end
            end
        end
    end
    return nearestIdx
end

-- ============================================================
-- ASTRION PLAYBACK SYSTEM
-- ============================================================
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

local function playRouteData(data, onComplete)
    if not data or #data == 0 then 
        if onComplete then onComplete() end
        return 
    end
    if not hrp then refreshHRP() end
    
    local char = player.Character
    if not char then 
        if onComplete then onComplete() end
        return 
    end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then 
        if onComplete then onComplete() end
        return 
    end
    
    isRunning = true
    
    -- AUTO DETECT HIP HEIGHT
    if data[1] then
        local firstFrame = data[1]
        local currentHipHeight = humanoid.HipHeight
        local recordedHipHeight = data[1].hipHeight or 2
        heightOffset = currentHipHeight - recordedHipHeight
        
        print(string.format("🎭 Avatar Detected - Current: %.2f | Recorded: %.2f | Offset: %.2f", 
            currentHipHeight, recordedHipHeight, heightOffset))
    end
    
    -- Find closest frame to current position
    local startIndex, distance = findClosestFrameIndex(data, hrp.Position)
    
    print("📍 Distance to nearest point: " .. math.floor(distance) .. " studs")
    
    -- Smart distance detection: only run if distance > 5 studs
    if distance > 5 then
        print("🏃 Distance > 5 studs, running to nearest point...")
        local startPos = tableToVec(data[startIndex].position)
        local reached = smoothRunToPosition(startPos, 15)
        if reached then
            task.wait(0.3)
        end
    else
        print("✅ Already near track (< 5 studs), starting immediately!")
    end
    
    -- Start from nearest frame
    local accumulatedTime = data[startIndex].time or 0
    local lastPlaybackTime = tick()
    
    local jumpDetector = JumpDetector.new()
    
    -- Buffers untuk smoothing
    local positionBuffer = {}
    local velocityBuffer = {}
    local rotationBuffer = {}
    local bufferSize = 5
    
    local playbackConnection
    playbackConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not isRunning then
            if playbackConnection then
                playbackConnection:Disconnect()
            end
            if onComplete then onComplete() end
            return
        end
        
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then
            isRunning = false
            if onComplete then onComplete() end
            return
        end
        
        local hrp = char.HumanoidRootPart
        local hum = char.Humanoid
        
        local currentTime = tick()
        local actualDelta = math.min(currentTime - lastPlaybackTime, 0.1)
        lastPlaybackTime = currentTime
        accumulatedTime = accumulatedTime + (actualDelta * playbackRate)
        
        if accumulatedTime > data[#data].time then
            isRunning = false
            if playbackConnection then
                playbackConnection:Disconnect()
            end
            if onComplete then onComplete() end
            return
        end
        
        local i0, i1, alpha = findSurroundingFrames(data, accumulatedTime)
        local f0, f1 = data[i0], data[i1]
        if not f0 or not f1 then return end
        
        -- Position interpolation
        local pos0, pos1 = tableToVec(f0.position), tableToVec(f1.position)
        local interpPos = lerpVector(pos0, pos1, alpha)
        
        -- Velocity interpolation
        local vel0 = f0.velocity and tableToVec(f0.velocity) or Vector3.new(0,0,0)
        local vel1 = f1.velocity and tableToVec(f1.velocity) or Vector3.new(0,0,0)
        local interpVel = lerpVector(vel0, vel1, alpha)
        
        -- Move direction interpolation
        local move0 = f0.moveDirection and tableToVec(f0.moveDirection) or Vector3.new(0,0,0)
        local move1 = f1.moveDirection and tableToVec(f1.moveDirection) or Vector3.new(0,0,0)
        local interpMove = lerpVector(move0, move1, alpha)
        
        -- Rotation interpolation
        local yaw0, yaw1 = f0.rotation or 0, f1.rotation or 0
        local interpYaw = lerpAngle(yaw0, yaw1, alpha)
        
        -- Add to buffers
        table.insert(positionBuffer, interpPos)
        table.insert(velocityBuffer, interpVel)
        table.insert(rotationBuffer, interpYaw)
        
        if #positionBuffer > bufferSize then table.remove(positionBuffer, 1) end
        if #velocityBuffer > bufferSize then table.remove(velocityBuffer, 1) end
        if #rotationBuffer > bufferSize then table.remove(rotationBuffer, 1) end
        
        -- Average buffers
        local avgPos = Vector3.new(0, 0, 0)
        local avgVel = Vector3.new(0, 0, 0)
        local avgYaw = 0
        
        for _, pos in ipairs(positionBuffer) do avgPos = avgPos + pos end
        avgPos = avgPos / #positionBuffer
        
        for _, vel in ipairs(velocityBuffer) do avgVel = avgVel + vel end
        avgVel = avgVel / #velocityBuffer
        
        for _, yaw in ipairs(rotationBuffer) do avgYaw = avgYaw + yaw end
        avgYaw = avgYaw / #rotationBuffer
        
        -- Apply height offset for different avatar sizes
        local correctedY = avgPos.Y + heightOffset
        local targetCFrame = CFrame.new(avgPos.X, correctedY, avgPos.Z) * CFrame.Angles(0, avgYaw, 0)
        
        hrp.CFrame = hrp.CFrame:Lerp(targetCFrame, POSITION_SMOOTH)
        
        -- Apply smooth velocity
        local targetVelocity = avgVel * 0.97
        local currentVel = hrp.AssemblyLinearVelocity
        hrp.AssemblyLinearVelocity = currentVel:Lerp(targetVelocity, VELOCITY_SMOOTH)
        
        -- Apply move direction
        if hum then
            local currentMove = hum.MoveDirection
            local smoothMove = currentMove:Lerp(interpMove, MOVE_SMOOTH)
            hum:Move(smoothMove, false)
        end
        
        -- Jump detection
        if jumpDetector:ShouldJump(data, i0, f0, f1, interpVel, accumulatedTime) then
            jumpDetector:ExecuteJump(hum)
        end
    end)
end

-- ============================================================
-- MAIN PLAYBACK FUNCTIONS (AUTO LOOP DENGAN KEMBALI KE AWAL)
-- ============================================================
local function runAllRoutes()
    if #routes == 0 then return end
    if isLooping then return end
    
    isLooping = true
    
    task.spawn(function()
        while isLooping do
            if not hrp then refreshHRP() end
            
            -- Jalankan semua route
            for r = 1, #routes do
                if not isLooping then break end
                if not routes[r].data then continue end
                
                local finished = false
                playRouteData(routes[r].data, function()
                    finished = true
                end)
                
                -- Wait until finished
                while not finished and isLooping do
                    task.wait(0.1)
                end
                
                if not isLooping then break end
                task.wait(0.5)
            end
            
            -- AUTO LOOP: Kembali ke titik awal dengan RUNNING
            if isLooping and routes[1] and routes[1].data then
                print("🔄 Loop selesai, kembali ke titik awal...")
                
                -- Ambil titik awal dari route pertama
                local startPoint = tableToVec(routes[1].data[1].position)
                
                -- Cek jarak dari titik awal
                local currentPos = hrp.Position
                local distance = (currentPos - startPoint).Magnitude
                
                print(string.format("📍 Jarak dari titik awal: %.0f studs", distance))
                
                -- Selalu gunakan RUNNING untuk kembali ke titik awal
                if distance > 5 then
                    print("🏃‍♂️ RUNNING kembali ke titik awal...")
                    local reached = smoothRunToPosition(startPoint, 20)
                    
                    if reached then
                        print("✅ Sampai di titik awal!")
                        task.wait(1)
                    else
                        print("⚠️ Gagal mencapai titik awal, lanjut loop...")
                        task.wait(0.5)
                    end
                else
                    print("✅ Sudah dekat dengan titik awal, lanjut loop!")
                    task.wait(1)
                end
            end
        end
        
        isLooping = false
    end)
end

local function stopRoute()
    isRunning = false
    isLooping = false
end

local function runSpecificRoute(routeIdx)
    if not routes[routeIdx] then return end
    if not routes[routeIdx].data then return end
    if not hrp then refreshHRP() end
    
    -- Stop any existing loop
    isLooping = false
    task.wait(0.2)
    
    -- Start auto loop with this route
    isLooping = true
    task.spawn(function()
        while isLooping do
            local finished = false
            playRouteData(routes[routeIdx].data, function()
                finished = true
            end)
            
            while not finished and isLooping do
                task.wait(0.1)
            end
            
            -- Kembali ke titik awal route ini dengan RUNNING
            if isLooping and routes[routeIdx].data then
                print("🔄 Route selesai, kembali ke titik awal...")
                
                local startPoint = tableToVec(routes[routeIdx].data[1].position)
                local currentPos = hrp.Position
                local distance = (currentPos - startPoint).Magnitude
                
                print(string.format("📍 Jarak dari titik awal: %.0f studs", distance))
                
                if distance > 5 then
                    print("🏃‍♂️ RUNNING kembali ke titik awal...")
                    smoothRunToPosition(startPoint, 20)
                    task.wait(1)
                else
                    task.wait(1)
                end
            end
        end
        isLooping = false
    end)
end

-- ===============================
-- Anti Beton Ultra-Smooth
-- ===============================
local antiBetonActive = false
local antiBetonConn

local function enableAntiBeton()
    if antiBetonConn then antiBetonConn:Disconnect() end

    antiBetonConn = RunService.Stepped:Connect(function(_, dt)
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChild("Humanoid")
        if not hrp or not humanoid then return end

        if antiBetonActive and humanoid.FloorMaterial == Enum.Material.Air then
            local targetY = -50
            local currentY = hrp.Velocity.Y
            local newY = currentY + (targetY - currentY) * math.clamp(dt * 2.5, 0, 1)
            hrp.Velocity = Vector3.new(hrp.Velocity.X, newY, hrp.Velocity.Z)
        end
    end)
end

local function disableAntiBeton()
    if antiBetonConn then
        antiBetonConn:Disconnect()
        antiBetonConn = nil
    end
end

-- ===============================
-- Anti Idle
-- ===============================
local antiIdleActive = true
local antiIdleConn

local function enableAntiIdle()
    if antiIdleConn then antiIdleConn:Disconnect() end
    antiIdleConn = player.Idled:Connect(function()
        if antiIdleActive then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end)
end

enableAntiIdle()

-- ============================================================
-- UI: WindUI
-- ============================================================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "ASTRIONHUB",
    Icon = "lucide:mountain-snow",
    Author = "Jinho",
    Folder = "ASTRhub",
    Size = UDim2.fromOffset(580, 460),
    Theme = "Midnight",
    Resizable = true,
    SideBarWidth = 200,
    Watermark = "Jinho",
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function() end
    }
})

-- Tabs
local MainTab = Window:Tab({
    Title = "Main",
    Icon = "geist:shareplay",
    Default = true
})
local SettingsTab = Window:Tab({
    Title = "Tools",
    Icon = "geist:settings-sliders",
})
local tampTab = Window:Tab({
    Title = "Tampilan",
    Icon = "lucide:app-window",
})
local InfoTab = Window:Tab({
    Title = "Info",
    Icon = "lucide:info",
})

-- ============================================================
-- Main Tab
-- ============================================================
local speeds = {}
for v = 0.25, 3, 0.25 do
    table.insert(speeds, string.format("%.2fx", v))
end

MainTab:Dropdown({
    Title = "Speed",
    Icon = "lucide:zap",
    Values = speeds,
    Value = "1.00x",
    Callback = function(option)
        local num = tonumber(option:match("([%d%.]+)"))
        if num then
            playbackRate = num
        end
    end
})

MainTab:Toggle({
    Title = "Anti Beton Ultra-Smooth",
    Icon = "lucide:shield",
    Desc = "Mencegah jatuh secara kaku saat melayang",
    Value = false,
    Callback = function(state)
        antiBetonActive = state
        if state then
            enableAntiBeton()
        else
            disableAntiBeton()
        end
    end
})

MainTab:Button({
    Title = "START (Auto Loop + Return)",
    Icon = "craft:back-to-start-stroke",
    Desc = "Mulai dari terdekat, auto loop & kembali ke awal",
    Callback = function() 
        pcall(runAllRoutes)
    end
})

MainTab:Button({
    Title = "Stop track",
    Icon = "geist:stop-circle",
    Desc = "Hentikan semua route & loop",
    Callback = function() 
        pcall(stopRoute)
    end
})

for idx, route in ipairs(routes) do
    MainTab:Button({
        Title = "TRACK " .. route.name .. " (Loop + Return)",
        Icon = "lucide:train-track",
        Desc = "Loop dari " .. route.name .. " + kembali ke awal",
        Callback = function()
            pcall(function() runSpecificRoute(idx) end)
        end
    })
end

-- ============================================================
-- Settings Tab
-- ============================================================
SettingsTab:Button({
    Title = "TIMER GUI",
    Icon = "lucide:layers-2",
    Desc = "Timer untuk hitung BT",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Bardenss/YAHAYUK/refs/heads/main/TIMER"))()
    end
})

SettingsTab:Button({
    Title = "PRIVATE SERVER",
    Icon = "lucide:layers-2",
    Desc = "Klik untuk pindah ke private server",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Bardenss/PS/refs/heads/main/ps"))()
    end
})

SettingsTab:Slider({
    Title = "WalkSpeed",
    Icon = "lucide:zap",
    Desc = "Atur kecepatan berjalan karakter",
    Value = { 
        Min = 10,
        Max = 500,
        Default = 16
    },
    Step = 1,
    Suffix = "Speed",
    Callback = function(val)
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = val
        end
    end
})

SettingsTab:Slider({
    Title = "Jump Height",
    Icon = "lucide:zap",
    Desc = "Atur kekuatan lompat karakter",
    Value = { 
        Min = 10,
        Max = 500,
        Default = 50
    },
    Step = 1,
    Suffix = "Height",
    Callback = function(val)
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.JumpPower = val
        end
    end
})

SettingsTab:Button({
    Title = "Respawn Player",
    Icon = "lucide:refresh-ccw",
    Desc = "Respawn karakter saat ini",
    Callback = function()
        player.Character:BreakJoints()
    end
})

-- ============================================================
-- Info Tab
-- ============================================================
InfoTab:Button({
    Title = "Copy Discord",
    Icon = "geist:logo-discord",
    Desc = "Salin link Discord ke clipboard",
    Callback = function()
        if setclipboard then
            setclipboard("https://discord.gg/cjZPqHRV")
        end
    end
})

InfoTab:Section({
    Title = "INFO SC",
    TextSize = 20,
})

InfoTab:Section({
    Title = [[
Replay system dengan Astrion JSON format.

✨ FITUR BARU V2.5:
- 🏃‍♂️ RUNNING Mode untuk kembali ke titik awal
- 🔄 Auto Loop dengan Return System
- ⚡ Toleransi 5 studs untuk mulai running
- 📍 Smart Navigation yang lebih cepat

FITUR EXISTING:
- 🏃 Smart Running (>5 studs = berlari)
- 🔄 Smooth Flip rotation
- ⚡ Running state untuk movement cepat
- 🎭 Auto Detect Avatar Height

AVATAR SUPPORT:
- Ava Kecil ✓
- Mini ✓
- Beacon ✓
- Zeppeto ✓
- Besar ✓
- Tinggi ✓

CARA KERJA AUTO LOOP + RUNNING:
1. Jalankan semua checkpoint
2. Setelah selesai, cek jarak dari titik awal
3. Jika >5 studs: RUNNING kembali ke titik awal
4. Jika <5 studs: Langsung mulai loop lagi
5. Loop terus sampai di-stop

PERUBAHAN V2.5:
- Walking → RUNNING saat kembali ke awal
- Lebih cepat dan efisien
- Toleransi jarak dikurangi jadi 5 studs

Own Jinho x Astrion System
    ]],
    TextSize = 16,
    TextTransparency = 0.25,
})

-- ============================================================
-- Tampilan Tab
-- ============================================================
tampTab:Paragraph({
    Title = "Customize Interface",
    Desc = "Personalize your experience",
    Image = "palette",
    ImageSize = 20,
    Color = "White"
})

local themes = {}
for themeName, _ in pairs(WindUI:GetThemes()) do
    table.insert(themes, themeName)
end
table.sort(themes)

tampTab:Dropdown({
    Title = "Pilih tema",
    Values = themes,
    SearchBarEnabled = true,
    MenuWidth = 280,
    Value = "Dark",
    Callback = function(theme)
        WindUI:SetTheme(theme)
    end
})

-- Open button
Window:EditOpenButton({
    Title = "ASTRIONHUB",
    Icon = "geist:logo-nuxt",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new(
        Color3.fromHex("FF0F7B"), 
        Color3.fromHex("F89B29")
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})

Window:Tag({
    Title = "V2.5 Loop+Running",
    Color = Color3.fromHex("#30ff6a"),
    Radius = 10,
})

-- Rainbow clock
local TimeTag = Window:Tag({
    Title = "--:--:--",
    Icon = "lucide:timer",
    Radius = 10,
    Color = WindUI:Gradient({
        ["0"]   = { Color = Color3.fromHex("#FF0F7B"), Transparency = 0 },
        ["100"] = { Color = Color3.fromHex("#F89B29"), Transparency = 0 },
    }, {
        Rotation = 45,
    }),
})

local hue = 0
task.spawn(function()
    while true do
        local now = os.date("*t")
        local hours   = string.format("%02d", now.hour)
        local minutes = string.format("%02d", now.min)
        local seconds = string.format("%02d", now.sec)

        hue = (hue + 0.01) % 1
        local color = Color3.fromHSV(hue, 1, 1)

        TimeTag:SetTitle(hours .. ":" .. minutes .. ":" .. seconds)
        TimeTag:SetColor(color)

        task.wait(0.06)
    end
end)

-- Theme switcher button
Window:CreateTopbarButton("theme-switcher", "moon", function()
    WindUI:SetTheme(WindUI:GetCurrentTheme() == "Dark" and "Light" or "Dark")
end, 990)

pcall(function()
    Window:Show()
    MainTab:Show()
end)
