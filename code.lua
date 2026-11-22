-- chillisaken

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TextChatService = game:GetService("TextChatService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local chillisaken = {
    Brand = "chillisaken",
    Config = {
        AutoBlock = false,
        BlockDelay = 0,
        BlockRange = 15,
        HitboxDrag = false,
        HitboxDragRange = 30,
        DragSpeed = 14,
        WallCheck = false,
        StrictVisualCheck = false,
        AutoClone = false,
        CloneDetectionRange = 20,
        AutoPunch = false,
        PunchLockMode = "CharterLock",
        PunchMode = "Normal",
        PunchPrediction = 0.08,
        PunchLockDuration = 1.4,
        BackstabEnabled = false,
        TTStartDelay = 0.05,
        TTDuration = 0.2,
        TTBehindStuds = 4,
        TTDistCheck = false,
        TTDistCheckStud = 7,
        TTAutoStuds = false,
        TTAutoStandStuds = 5.5,
        TTAutoRunStuds = 3.4,
        TTDetectPing = false,
        TTMoreDirect = false,
        TTDashstab = false,
        TTDSStartDelay = 0.1,
        AutoGenerator = false,
        MinGameStartDelay = 1.5,
        FlowCellSpeed = 50,
        ConnectPairDelay = 1000,
        GearTurnSpeed = 30,
        ChanceAim = false,
        ChancePrediction = 4,
        ChanceCoinFlip = false,
        CoinFlipTarget = 3,
        AutoSlash = false,
        AutoSlashDistance = 10,
        AutoGhostburgerLMS = false,
        HomingTripmine = false,
        AutoTrick = false,
        Sk8Control = false,
        FastSpray = false,
        SpraySpeed = 0.5,
        AutoHatchet = false,
        HatchetLevel = 2,
        HatchetRange = 13,
        AutoEscape = false,
        EscapeCooldown = 0.2,
        AutoDisarm = false,
        AutoBreakFree = false,
        AutoPullRope = false,
        AzureQte = false,
        BetterVoidRush = false,
        DeleteFakeNoli = false,
        DisableNoliNPC = false,
        Disable007n7NPC = false,
        DisableTrails = false,
        DisableFootprints = false,
        SmallSpikes = false,
        DisableKillerWalls = false,
        InfiniteStamina = false,
        AntiSlowness = false,
        EnableJumping = false,
        SpeedBoost = false,
        SpeedValue = 1,
        Flight = false,
        FlightSpeed = 1,
        ShowPing = false,
        ShowChat = false,
        EspKiller = false,
        EspSurvivor = false,
        EspGenerator = false,
        EspItem = false,
        EspPizza = false,
        EspZombie = false,
        EspMine = false,
        EspRespawn = false,
        EspSentry = false,
        EspNames = true,
        EspHealth = true,
        Fullbright = false,
        NoShadows = false,
        NoFog = false,
        DeleteRagdolls = false,
        HideInjury = false,
        DisableBlindness = false,
        FreeZoom = false,
        CameraNoclip = false,
        EnableFov = false,
        FovValue = 70
    },
    Connections = {},
    State = {
        Character = nil,
        Humanoid = nil,
        Root = nil,
        SpeedMultipliers = nil,
        LastBlock = 0,
        LastEscape = 0,
        DragToken = 0,
        ActiveAnimTrack = nil,
        AnimPackConn = nil
    }
}

-- chillisaken: Helpers & References
local function getPlayersFolder()
    return Workspace:FindFirstChild("Players")
end

local function getKillersFolder()
    local pf = getPlayersFolder()
    return pf and pf:FindFirstChild("Killers")
end

local function getSurvivorsFolder()
    local pf = getPlayersFolder()
    return pf and pf:FindFirstChild("Survivors")
end

local function getIngameFolder()
    local map = Workspace:FindFirstChild("Map")
    return map and map:FindFirstChild("Ingame")
end

local function getNetworkRemote()
    local modules = ReplicatedStorage:FindFirstChild("Modules")
    local net = modules and modules:FindFirstChild("Network", true)
    if net then
        local remote = net:FindFirstChild("RemoteEvent") or net:FindFirstChildOfClass("RemoteEvent")
        if remote then return remote end
    end
    return nil
end

local function fireAbility(abilityName, useBufferClone)
    local remote = getNetworkRemote()
    if not remote then return end
    if useBufferClone then
        remote:FireServer("UseActorAbility", { buffer.fromstring("\003\005\000\000\000Clone") })
    else
        remote:FireServer("UseActorAbility", { abilityName })
        remote:FireServer("UseActorAbility", abilityName)
    end
end

local function getClosestKiller(maxDist)
    local root = chillisaken.State.Root
    local kf = getKillersFolder()
    if not root or not kf then return nil, math.huge end
    local best, bestDist = nil, maxDist or math.huge
    for _, killer in ipairs(kf:GetChildren()) do
        if killer:IsA("Model") then
            local kRoot = killer:FindFirstChild("HumanoidRootPart") or killer.PrimaryPart
            local hum = killer:FindFirstChildOfClass("Humanoid")
            if kRoot and (not hum or hum.Health > 0) then
                local d = (kRoot.Position - root.Position).Magnitude
                if d <= bestDist then
                    best = killer
                    bestDist = d
                end
            end
        end
    end
    return best, bestDist
end

local function hasLineOfSight(fromPos, toPos, ignoreList)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = ignoreList or {}
    params.IgnoreWater = true
    local result = Workspace:Raycast(fromPos, toPos - fromPos, params)
    return result == nil
end

local function clearTaggedEsp(tagName)
    for _, desc in ipairs(game:GetDescendants()) do
        if (desc:IsA("Highlight") or desc:IsA("BillboardGui")) and desc.Name == tagName then
            desc:Destroy()
        end
    end
end

local function bindCharacter(char)
    chillisaken.State.Character = char
    if not char then
        chillisaken.State.Humanoid = nil
        chillisaken.State.Root = nil
        chillisaken.State.SpeedMultipliers = nil
        return
    end
    chillisaken.State.Humanoid = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
    chillisaken.State.Root = (chillisaken.State.Humanoid and chillisaken.State.Humanoid.RootPart)
        or char:FindFirstChild("HumanoidRootPart")
        or char:WaitForChild("HumanoidRootPart", 5)
    chillisaken.State.SpeedMultipliers = char:FindFirstChild("SpeedMultipliers")
end

if LocalPlayer then
    if LocalPlayer.Character then
        task.spawn(bindCharacter, LocalPlayer.Character)
    end
    LocalPlayer.CharacterAdded:Connect(function(char)
        bindCharacter(char)
    end)
end

-- chillisaken: Attack & Block ID Sets
local AttackSoundIds = {
    ["12222216"] = true, ["70845653728841"] = true, ["71310583817000"] = true, ["71805956520207"] = true,
    ["71834552297085"] = true, ["72425554233832"] = true, ["74842815979546"] = true, ["75330693422988"] = true,
    ["79980897195554"] = true, ["80516583309685"] = true, ["81702359653578"] = true, ["82221759983649"] = true,
    ["84116622032112"] = true, ["84307400688050"] = true, ["85853080745515"] = true, ["86174610237192"] = true,
    ["95079963655241"] = true, ["101199185291628"] = true, ["102228729296384"] = true, ["104910828105172"] = true,
    ["105840448036441"] = true, ["106300477136129"] = true, ["107444859834748"] = true, ["108610718831698"] = true,
    ["108907358619313"] = true, ["109348678063422"] = true, ["109431876587852"] = true, ["112395455254818"] = true,
    ["112809109188560"] = true, ["114742322778642"] = true, ["115026634746636"] = true, ["116581754553533"] = true,
    ["117173212095661"] = true, ["119583605486352"] = true, ["119942598489800"] = true, ["121293883585738"] = true,
    ["121954639447247"] = true, ["127793641088496"] = true, ["128856426573270"] = true, ["131123355704017"] = true,
    ["131406927389838"] = true, ["136323728355613"] = true, ["140242176732868"] = true
}

local AttackAnimIds = {
    ["87259391926321"] = true, ["140703210927645"] = true, ["136007065400978"] = true, ["129843313690921"] = true,
    ["86709774283672"] = true, ["108807732150251"] = true, ["138040001965654"] = true, ["86096387000557"] = true,
    ["96959123077498"] = true, ["72722244508749"] = true, ["89448354637442"] = true, ["106086955212611"] = true,
    ["107640065977686"] = true, ["119583605486352"] = true, ["79980897195554"] = true, ["74842815979546"] = true
}

-- chillisaken: Auto Block & Hitbox Drag
local function dragTowardTarget(targetPart)
    local cfg = chillisaken.Config
    local root = chillisaken.State.Root
    local hum = chillisaken.State.Humanoid
    if not cfg.HitboxDrag or not root or not hum or not targetPart then return end
    local dist = (targetPart.Position - root.Position).Magnitude
    if dist > cfg.HitboxDragRange then return end

    chillisaken.State.DragToken += 1
    local token = chillisaken.State.DragToken
    local startClock = os.clock()
    local duration = 0.35

    task.spawn(function()
        while token == chillisaken.State.DragToken and (os.clock() - startClock) < duration do
            local dt = RunService.Heartbeat:Wait()
            if not root.Parent or not targetPart.Parent or not hum.Parent then break end
            local flatDir = Vector3.new(targetPart.Position.X - root.Position.X, 0, targetPart.Position.Z - root.Position.Z)
            if flatDir.Magnitude <= 3 then break end
            local ramp = math.sin(math.pi * ((os.clock() - startClock) / duration))
            hum:Move(flatDir.Unit, false)
            root.CFrame = root.CFrame + flatDir.Unit * cfg.DragSpeed * ramp * dt
            root.CFrame = CFrame.lookAt(root.Position, root.Position + flatDir.Unit)
        end
        if hum and hum.Parent then
            hum:Move(Vector3.zero, false)
        end
    end)
end

local function triggerBlock(targetPart)
    local cfg = chillisaken.Config
    if os.clock() - chillisaken.State.LastBlock < 0.05 then return end
    chillisaken.State.LastBlock = os.clock()
    if cfg.HitboxDrag and targetPart then
        dragTowardTarget(targetPart)
    end
    local delaySec = (cfg.BlockDelay or 0) / 1000
    if delaySec > 0 then
        task.delay(delaySec, function()
            if chillisaken.State.Character and chillisaken.State.Character.Parent then
                fireAbility("Block", false)
            end
        end)
    else
        fireAbility("Block", false)
    end
end

local function checkHitboxOverlap(queryHitbox)
    local cfg = chillisaken.Config
    local char = chillisaken.State.Character
    local root = chillisaken.State.Root
    if not cfg.AutoBlock or not char or not root or not queryHitbox then return end

    if cfg.WallCheck and not hasLineOfSight(root.Position, queryHitbox.Position, { char, queryHitbox.Parent }) then
        return
    end
    if cfg.StrictVisualCheck then
        local look = Vector3.new(queryHitbox.CFrame.LookVector.X, 0, queryHitbox.CFrame.LookVector.Z)
        local toMe = Vector3.new(root.Position.X - queryHitbox.Position.X, 0, root.Position.Z - queryHitbox.Position.Z)
        if look.Magnitude <= 0.01 or toMe.Magnitude <= 0.01 or look.Unit:Dot(toMe.Unit) <= 0.6 then
            return
        end
    end

    local localQuery = char:FindFirstChild("QueryHitbox")
    if localQuery then
        local params = OverlapParams.new()
        params.MaxParts = 1
        params.BruteForceAllSlow = true
        params.IncludeInstances = { localQuery }
        for _ = 1, 10 do
            if not cfg.AutoBlock or not queryHitbox.Parent then break end
            local boxCFrame = queryHitbox.CFrame * CFrame.new(0, 0, -3.5)
            local boxSize = Vector3.new(5.2, 6, 5.65) * 2.2
            if #Workspace:GetPartBoundsInBox(boxCFrame, boxSize, params) > 0 then
                triggerBlock(queryHitbox)
                return
            end
            task.wait(0.02)
        end
    elseif (queryHitbox.Position - root.Position).Magnitude <= cfg.BlockRange then
        triggerBlock(queryHitbox)
    end
end

function chillisaken.SetAutoBlock(enabled)
    chillisaken.Config.AutoBlock = enabled
    if chillisaken.Connections.AutoBlock then
        for _, conn in ipairs(chillisaken.Connections.AutoBlock) do
            if conn and conn.Connected then conn:Disconnect() end
        end
        chillisaken.Connections.AutoBlock = nil
    end
    if not enabled then return end

    local conns = {}
    local function hookKiller(killer)
        if not killer:IsA("Model") then return end
        local qBox = killer:FindFirstChild("QueryHitbox") or killer:FindFirstChild("HumanoidRootPart")
        local hum = killer:FindFirstChildOfClass("Humanoid")
        local anim = hum and hum:FindFirstChildOfClass("Animator")
        if anim then
            table.insert(conns, anim.AnimationPlayed:Connect(function(track)
                if not chillisaken.Config.AutoBlock or not track or not track.Animation then return end
                local id = tostring(track.Animation.AnimationId):match("%d+")
                if id and AttackAnimIds[id] then
                    task.spawn(checkHitboxOverlap, qBox)
                end
            end))
        end
        table.insert(conns, killer.DescendantAdded:Connect(function(desc)
            if not chillisaken.Config.AutoBlock then return end
            if desc:IsA("Sound") then
                local sid = tostring(desc.SoundId):match("%d+")
                if sid and AttackSoundIds[sid] then
                    task.spawn(checkHitboxOverlap, qBox)
                end
            end
        end))
    end

    local kf = getKillersFolder()
    if kf then
        for _, killer in ipairs(kf:GetChildren()) do
            hookKiller(killer)
        end
        table.insert(conns, kf.ChildAdded:Connect(hookKiller))
    end
    chillisaken.Connections.AutoBlock = conns
end

-- chillisaken: Auto Clone (007n7)
function chillisaken.SetAutoClone(enabled)
    chillisaken.Config.AutoClone = enabled
    if chillisaken.Connections.AutoClone then
        chillisaken.Connections.AutoClone:Disconnect()
        chillisaken.Connections.AutoClone = nil
    end
    if not enabled then return end

    chillisaken.Connections.AutoClone = game.DescendantAdded:Connect(function(desc)
        if not chillisaken.Config.AutoClone or not desc:IsA("Sound") then return end
        local sid = tostring(desc.SoundId):match("%d+")
        if not sid or not AttackSoundIds[sid] then return end
        local root = chillisaken.State.Root
        local char = chillisaken.State.Character
        if not root or not char then return end
        local parentPart = desc.Parent and (desc.Parent:IsA("BasePart") and desc.Parent or desc.Parent:FindFirstAncestorWhichIsA("BasePart"))
        if not parentPart then return end
        local range = chillisaken.Config.CloneDetectionRange
        if (parentPart.Position - root.Position).Magnitude > range then return end
        if chillisaken.Config.WallCheck and not hasLineOfSight(root.Position, parentPart.Position, { char, parentPart }) then
            return
        end
        fireAbility("Block", true)
    end)
end

-- chillisaken: Auto Punch & Aimbot
function chillisaken.SetAutoPunch(enabled)
    chillisaken.Config.AutoPunch = enabled
    if chillisaken.Connections.AutoPunch then
        for _, conn in ipairs(chillisaken.Connections.AutoPunch) do
            if conn and conn.Connected then conn:Disconnect() end
        end
        chillisaken.Connections.AutoPunch = nil
    end
    if not enabled then return end

    local lockUntil = 0
    local history = {}
    local conns = {}

    local function getTargetRoot()
        local root = chillisaken.State.Root
        local kf = getKillersFolder()
        if not root or not kf then return nil end
        local best, bestDist = nil, 25
        for _, killer in ipairs(kf:GetChildren()) do
            local kRoot = killer:FindFirstChild("HumanoidRootPart")
            if kRoot then
                local d = (kRoot.Position - root.Position).Magnitude
                if d < bestDist then
                    best = kRoot
                    bestDist = d
                end
            end
        end
        return best
    end

    local function lockAim(targetRoot)
        local root = chillisaken.State.Root
        if not root or not targetRoot then return end
        local now = os.clock()
        table.insert(history, { pos = targetRoot.Position, t = now })
        while #history > 8 do table.remove(history, 1) end
        local aimPos = targetRoot.Position
        if #history >= 2 then
            local dt = history[#history].t - history[1].t
            if dt > 0.01 then
                local vel = (history[#history].pos - history[1].pos) / dt
                aimPos = aimPos + vel * (chillisaken.Config.PunchPrediction or 0.08)
            end
        end

        local mode = chillisaken.Config.PunchLockMode
        if mode == "CharterLock" or mode == "CamLock+CharterLock" then
            local flat = Vector3.new(aimPos.X, root.Position.Y, aimPos.Z)
            if (flat - root.Position).Magnitude > 0.01 then
                root.CFrame = CFrame.new(root.Position, root.Position + (flat - root.Position).Unit)
            end
        end
        if (mode == "CamLock" or mode == "CamLock+CharterLock") and Camera then
            local camPos = Camera.CFrame.Position
            if (aimPos - camPos).Magnitude > 0.01 then
                Camera.CFrame = CFrame.lookAt(camPos, camPos + (aimPos - camPos).Unit)
            end
        end
    end

    table.insert(conns, RunService.RenderStepped:Connect(function()
        if not chillisaken.Config.AutoPunch then return end
        if os.clock() < lockUntil then
            local targetRoot = getTargetRoot()
            if targetRoot then lockAim(targetRoot) end
        end
    end))

    table.insert(conns, RunService.Heartbeat:Connect(function()
        if not chillisaken.Config.AutoPunch or chillisaken.Config.PunchMode ~= "Normal" then return end
        local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
        local mainUi = pg and pg:FindFirstChild("MainUI")
        local punchBtn = mainUi and mainUi:FindFirstChild("AbilityContainer") and mainUi.AbilityContainer:FindFirstChild("Punch")
        local charges = punchBtn and punchBtn:FindFirstChild("Charges")
        if charges and charges.Text == "1" and getTargetRoot() then
            lockUntil = os.clock() + (chillisaken.Config.PunchLockDuration or 1.4)
            if typeof(getconnections) == "function" then
                for _, c in ipairs(getconnections(punchBtn.MouseButton1Click)) do
                    pcall(function() c:Fire() end)
                end
            else
                fireAbility("Punch", false)
            end
        end
    end))

    chillisaken.Connections.AutoPunch = conns
end

-- chillisaken: Two Time Backstab & Dashstab
function chillisaken.SetTwoTime(enabled)
    chillisaken.Config.BackstabEnabled = enabled
    if chillisaken.Connections.TwoTime then
        chillisaken.Connections.TwoTime:Disconnect()
        chillisaken.Connections.TwoTime = nil
    end
    if not enabled then return end

    local function executeStab(isDash)
        local cfg = chillisaken.Config
        local char = chillisaken.State.Character
        local root = chillisaken.State.Root
        local killer = getClosestKiller(cfg.TTDistCheck and cfg.TTDistCheckStud or 30)
        local kRoot = killer and killer:FindFirstChild("HumanoidRootPart")
        if not char or not root or not kRoot then return end

        task.wait(isDash and cfg.TTDSStartDelay or cfg.TTStartDelay)
        local behind = cfg.TTBehindStuds or 4
        if cfg.TTAutoStuds then
            local speed = math.clamp(kRoot.AssemblyLinearVelocity.Magnitude, 0, 30)
            local runStuds = cfg.TTAutoRunStuds or 3.4
            if cfg.TTDetectPing and LocalPlayer then
                local pingMs = LocalPlayer:GetNetworkPing() * 1000
                runStuds = math.max(1.0, runStuds - (math.max(pingMs, 20) - 20) / 100 * 1.5)
            end
            local slope = ((cfg.TTAutoStandStuds or 5.5) - runStuds) / 26.0
            behind = (cfg.TTAutoStandStuds or 5.5) - speed * slope
        end

        local startClock = os.clock()
        local dur = cfg.TTDuration or 0.2
        while (os.clock() - startClock) < dur do
            if not root.Parent or not kRoot.Parent then break end
            root.CFrame = kRoot.CFrame * CFrame.new(0, 0, behind)
            RunService.PreRender:Wait()
        end
    end

    chillisaken.Connections.TwoTime = RunService.Heartbeat:Connect(function()
        if not chillisaken.Config.BackstabEnabled and not chillisaken.Config.TTDashstab then return end
        local hum = chillisaken.State.Humanoid
        local anim = hum and hum:FindFirstChildOfClass("Animator")
        if not anim then return end
        for _, track in ipairs(anim:GetPlayingAnimationTracks()) do
            local id = track.Animation and tostring(track.Animation.AnimationId):match("%d+")
            if id == "100725497418533" or id == "106086955212611" then
                if chillisaken.Config.BackstabEnabled then
                    task.spawn(executeStab, false)
                end
            elseif id == "89448354637442" or id == "107640065977686" then
                if chillisaken.Config.TTDashstab then
                    task.spawn(executeStab, true)
                end
            end
        end
    end)
end

-- chillisaken: Flow Board Solver & Minigame Automation
local function solveFlowBoard(board, flowBoardMod)
    if not board or not flowBoardMod then return nil end
    local size, pairMap = board.Size, board.Pairs
    local occupied, answer = {}, {}
    local directions = { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }
    local endpointOwner = {}
    for color, pair in pairs(pairMap) do
        endpointOwner[pair[1]], endpointOwner[pair[2]] = color, color
    end
    local remaining = {}
    for color in pairs(pairMap) do table.insert(remaining, color) end

    local function candidates(color, limit)
        local pair = pairMap[color]
        local from, target = pair[1], pair[2]
        local results, path, seen = {}, { from }, { [from] = true }
        local function dist(cell)
            local r, c = flowBoardMod.ToRowCol(size, cell)
            local tr, tc = flowBoardMod.ToRowCol(size, target)
            return math.abs(r - tr) + math.abs(c - tc)
        end
        local function walk(cell)
            if #results >= limit then return end
            if cell == target then
                table.insert(results, table.clone(path))
                return
            end
            local row, col = flowBoardMod.ToRowCol(size, cell)
            local nextCells = {}
            for _, d in ipairs(directions) do
                local nr, nc = row + d[1], col + d[2]
                if nr >= 1 and nr <= size and nc >= 1 and nc <= size then
                    local n = flowBoardMod.ToIndex(size, nr, nc)
                    local owner = endpointOwner[n]
                    if not seen[n] and not occupied[n] and (not owner or (owner == color and n == target)) then
                        table.insert(nextCells, n)
                    end
                end
            end
            table.sort(nextCells, function(a, b) return dist(a) < dist(b) end)
            for _, n in ipairs(nextCells) do
                seen[n] = true
                table.insert(path, n)
                walk(n)
                path[#path] = nil
                seen[n] = nil
                if #results >= limit then break end
            end
        end
        walk(from)
        table.sort(results, function(a, b) return #a < #b end)
        return results
    end

    local function search(colors)
        if #colors == 0 then return true end
        local bestIdx, bestPaths
        for i, color in ipairs(colors) do
            local list = candidates(color, 300)
            if #list == 0 then return false end
            if not bestPaths or #list < #bestPaths then
                bestIdx, bestPaths = i, list
            end
        end
        local chosen = colors[bestIdx]
        local nextColors = table.clone(colors)
        table.remove(nextColors, bestIdx)
        for _, path in ipairs(bestPaths) do
            for _, cell in ipairs(path) do occupied[cell] = true end
            answer[chosen] = path
            if search(nextColors) then return true end
            answer[chosen] = nil
            for _, cell in ipairs(path) do occupied[cell] = nil end
        end
        return false
    end

    return search(remaining) and answer or nil
end

function chillisaken.SetAutoGenerator(enabled)
    chillisaken.Config.AutoGenerator = enabled
    if chillisaken.Connections.AutoGenerator then
        chillisaken.Connections.AutoGenerator:Disconnect()
        chillisaken.Connections.AutoGenerator = nil
    end
    if not enabled then return end

    local flowBoardMod
    pcall(function()
        flowBoardMod = require(ReplicatedStorage.Modules.Minigames.FlowBoard)
    end)

    chillisaken.Connections.AutoGenerator = RunService.Heartbeat:Connect(function()
        if not chillisaken.Config.AutoGenerator then return end
        local ig = getIngameFolder()
        local mapFolder = ig and ig:FindFirstChild("Map")
        if not mapFolder then return end
        for _, child in ipairs(mapFolder:GetChildren()) do
            if child.Name == "Generator" then
                local remotes = child:FindFirstChild("Remotes")
                local re = remotes and remotes:FindFirstChild("RE")
                if re and re:IsA("RemoteEvent") then
                    re:FireServer()
                end
            end
        end
    end)
    chillisaken.SolveFlowBoard = function(board)
        return solveFlowBoard(board, flowBoardMod)
    end
end

-- chillisaken: Chance & Survivor Combat Automation
function chillisaken.SetChanceCoinFlip(enabled)
    chillisaken.Config.ChanceCoinFlip = enabled
    if chillisaken.Connections.ChanceCoinFlip then
        task.cancel(chillisaken.Connections.ChanceCoinFlip)
        chillisaken.Connections.ChanceCoinFlip = nil
    end
    if not enabled then return end

    chillisaken.Connections.ChanceCoinFlip = task.spawn(function()
        while chillisaken.Config.ChanceCoinFlip do
            local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
            local mainUi = pg and pg:FindFirstChild("MainUI")
            local abilityContainer = mainUi and mainUi:FindFirstChild("AbilityContainer")
            local shoot = abilityContainer and abilityContainer:FindFirstChild("Shoot")
            local charges = shoot and shoot:FindFirstChild("Charges")
            if charges and tonumber(charges.Text) ~= chillisaken.Config.CoinFlipTarget then
                fireAbility("CoinFlip", false)
            end
            task.wait(2)
        end
    end)
end

function chillisaken.SetAutoSlash(enabled)
    chillisaken.Config.AutoSlash = enabled
    if chillisaken.Connections.AutoSlash then
        chillisaken.Connections.AutoSlash:Disconnect()
        chillisaken.Connections.AutoSlash = nil
    end
    if not enabled then return end

    chillisaken.Connections.AutoSlash = RunService.Heartbeat:Connect(function()
        if not chillisaken.Config.AutoSlash then return end
        local root = chillisaken.State.Root
        local kf = getKillersFolder()
        if not root or not kf then return end
        for _, killer in ipairs(kf:GetChildren()) do
            if killer:IsA("Model") and killer.PrimaryPart then
                if (killer.PrimaryPart.Position - root.Position).Magnitude <= chillisaken.Config.AutoSlashDistance then
                    fireAbility("Slash", false)
                    break
                end
            end
        end
    end)
end

function chillisaken.SetAutoGhostburgerLMS(enabled)
    chillisaken.Config.AutoGhostburgerLMS = enabled
    if chillisaken.Connections.AutoGhostburgerLMS then
        chillisaken.Connections.AutoGhostburgerLMS:Disconnect()
        chillisaken.Connections.AutoGhostburgerLMS = nil
    end
    if not enabled then return end

    local sf = getSurvivorsFolder()
    local function checkLMS()
        if chillisaken.Config.AutoGhostburgerLMS and sf and #sf:GetChildren() == 1 then
            fireAbility("Ghostburger", false)
        end
    end
    if sf then
        chillisaken.Connections.AutoGhostburgerLMS = sf.ChildRemoved:Connect(checkLMS)
        checkLMS()
    end
end

function chillisaken.SetHomingTripmine(enabled)
    chillisaken.Config.HomingTripmine = enabled
    if chillisaken.Connections.HomingTripmine then
        chillisaken.Connections.HomingTripmine:Disconnect()
        chillisaken.Connections.HomingTripmine = nil
    end
    if not enabled then return end

    chillisaken.Connections.HomingTripmine = RunService.Heartbeat:Connect(function()
        if not chillisaken.Config.HomingTripmine then return end
        local ig = getIngameFolder()
        local mine = ig and ig:FindFirstChild("SubspaceTripmine")
        local center = mine and mine:FindFirstChild("SubspaceCenter")
        local killer = getClosestKiller(math.huge)
        local kTarget = killer and (killer:FindFirstChild("Torso") or killer:FindFirstChild("UpperTorso") or killer:FindFirstChild("HumanoidRootPart"))
        if center and center:IsA("BasePart") and kTarget then
            local bp = center:FindFirstChildOfClass("BodyPosition") or Instance.new("BodyPosition")
            bp.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            bp.D = 1000
            bp.P = 10000
            bp.Position = kTarget.Position + Vector3.new(0, 2, 0)
            bp.Parent = center
        end
    end)
end

-- chillisaken: Killer & Map Tweaks
function chillisaken.ApplyMapTweaks()
    local cfg = chillisaken.Config
    local ig = getIngameFolder()
    local kf = getKillersFolder()

    if cfg.DeleteFakeNoli and kf then
        for _, m in ipairs(kf:GetChildren()) do
            if m:IsA("Model") and m:GetAttribute("IsFakeNoli") == true then
                m:Destroy()
            end
        end
    end

    if ig then
        for _, obj in ipairs(ig:GetChildren()) do
            local lower = obj.Name:lower()
            if cfg.DisableTrails and obj:IsA("Folder") and obj.Name:find("JohnDoeTrail") then
                for _, part in ipairs(obj:GetChildren()) do
                    if part:IsA("BasePart") then part.CanTouch = false end
                end
            elseif cfg.DisableFootprints and obj:IsA("Folder") and (lower:find("shadows") or lower:find("footprint")) then
                for _, part in ipairs(obj:GetChildren()) do
                    if part:IsA("BasePart") then part.CanTouch = false end
                end
            elseif obj.Name == "SpikeCollision" and obj:IsA("BasePart") then
                obj.Size = cfg.SmallSpikes and Vector3.new(11, 3.5, 3.5) or Vector3.new(11, 5, 5)
                obj.Shape = cfg.SmallSpikes and Enum.PartType.Cylinder or Enum.PartType.Block
            end
        end
    end

    if cfg.DisableKillerWalls then
        for _, desc in ipairs(Workspace:GetDescendants()) do
            if desc.Name == "KillerDoors" then
                for _, wall in ipairs(desc:GetChildren()) do
                    if wall:IsA("BasePart") then wall.CanCollide = false end
                end
            end
        end
    end
end

-- chillisaken: Stamina, Movement & World Visuals
function chillisaken.SetInfiniteStamina(enabled)
    chillisaken.Config.InfiniteStamina = enabled
    if chillisaken.Connections.InfiniteStamina then
        chillisaken.Connections.InfiniteStamina:Disconnect()
        chillisaken.Connections.InfiniteStamina = nil
    end
    if not enabled then return end

    local sprintMod
    pcall(function()
        sprintMod = require(ReplicatedStorage.Systems.Character.Game.Sprinting)
    end)
    chillisaken.Connections.InfiniteStamina = RunService.Heartbeat:Connect(function()
        if not chillisaken.Config.InfiniteStamina then return end
        if sprintMod then
            sprintMod.StaminaLossDisabled = true
            if sprintMod.MaxStamina then
                sprintMod.Stamina = sprintMod.MaxStamina
            end
        end
    end)
end

function chillisaken.SetSpeedBoost(enabled)
    chillisaken.Config.SpeedBoost = enabled
    if chillisaken.Connections.SpeedBoost then
        chillisaken.Connections.SpeedBoost:Disconnect()
        chillisaken.Connections.SpeedBoost = nil
    end
    if not enabled then return end

    chillisaken.Connections.SpeedBoost = RunService.Heartbeat:Connect(function(dt)
        if not chillisaken.Config.SpeedBoost then return end
        local char = chillisaken.State.Character
        local hum = chillisaken.State.Humanoid
        if char and hum and hum.MoveDirection.Magnitude > 0 then
            char:TranslateBy(hum.MoveDirection * (chillisaken.Config.SpeedValue or 1) * dt)
        end
    end)
end

function chillisaken.SetFlight(enabled)
    chillisaken.Config.Flight = enabled
    if chillisaken.Connections.Flight then
        chillisaken.Connections.Flight:Disconnect()
        chillisaken.Connections.Flight = nil
    end
    local hum = chillisaken.State.Humanoid
    local head = chillisaken.State.Character and chillisaken.State.Character:FindFirstChild("Head")
    if not enabled then
        if hum then hum.PlatformStand = false end
        if head then head.Anchored = false end
        return
    end
    if not hum or not head then return end
    hum.PlatformStand = true
    head.Anchored = true

    chillisaken.Connections.Flight = RunService.Heartbeat:Connect(function(dt)
        if not chillisaken.Config.Flight or not head.Parent then return end
        if not Camera then return end
        local move = hum.MoveDirection * ((chillisaken.Config.FlightSpeed or 1) * dt)
        local camPos = Camera.CFrame.Position
        local headPos = head.CFrame.Position
        local moved = CFrame.new(camPos, Vector3.new(headPos.X, camPos.Y, headPos.Z)):VectorToObjectSpace(move)
        head.CFrame = CFrame.new(headPos) * (Camera.CFrame - camPos) * CFrame.new(moved)
    end)
end

function chillisaken.SetFullbright(enabled)
    chillisaken.Config.Fullbright = enabled
    if chillisaken.Connections.Fullbright then
        chillisaken.Connections.Fullbright:Disconnect()
        chillisaken.Connections.Fullbright = nil
    end
    if not enabled then return end

    local function applyBright()
        Lighting.TimeOfDay = "12:00:00"
        Lighting.ClockTime = 12
        Lighting.Brightness = 2.5
        Lighting.FogStart = 100000
        Lighting.FogEnd = 300000
        Lighting.Ambient = Color3.fromRGB(230, 230, 230)
        Lighting.OutdoorAmbient = Color3.fromRGB(220, 220, 220)
        Lighting.GlobalShadows = false
    end
    applyBright()
    chillisaken.Connections.Fullbright = RunService.Heartbeat:Connect(function()
        if chillisaken.Config.Fullbright then
            applyBright()
        end
    end)
end

-- chillisaken: ESP System
local EspColors = {
    Killer = Color3.fromRGB(255, 60, 60),
    Survivor = Color3.fromRGB(60, 255, 100),
    Generator = Color3.fromRGB(0, 255, 255),
    Item = Color3.fromRGB(255, 215, 0),
    Pizza = Color3.fromRGB(255, 170, 0),
    Zombie = Color3.fromRGB(0, 200, 90),
    Mine = Color3.fromRGB(255, 0, 255),
    Respawn = Color3.fromRGB(0, 150, 255),
    Sentry = Color3.fromRGB(255, 165, 0)
}

local function attachEsp(target, adorneePart, color, labelText, tagName)
    if not target or not adorneePart then return end
    if not target:FindFirstChild(tagName) then
        local hl = Instance.new("Highlight")
        hl.Name = tagName
        hl.FillColor = color
        hl.OutlineColor = color
        hl.FillTransparency = 0.65
        hl.OutlineTransparency = 0
        hl.Adornee = target
        hl.Parent = target
    end
    if chillisaken.Config.EspNames and not adorneePart:FindFirstChild(tagName .. "_Label") then
        local bb = Instance.new("BillboardGui")
        bb.Name = tagName .. "_Label"
        bb.Adornee = adorneePart
        bb.Size = UDim2.new(0, 140, 0, 24)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        bb.Parent = adorneePart

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = color
        lbl.TextStrokeTransparency = 0.3
        lbl.Font = Enum.Font.GothamBold
        lbl.TextScaled = true
        lbl.Text = labelText
        lbl.Parent = bb
    end
end

function chillisaken.RefreshEsp()
    clearTaggedEsp("chillisaken_ESP")
    local cfg = chillisaken.Config

    if cfg.EspKiller then
        local kf = getKillersFolder()
        if kf then
            for _, m in ipairs(kf:GetChildren()) do
                if m:IsA("Model") and m ~= chillisaken.State.Character then
                    local root = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
                    local hum = m:FindFirstChildOfClass("Humanoid")
                    local txt = m.Name
                    if cfg.EspHealth and hum then
                        txt = txt .. " [" .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth) .. "]"
                    end
                    attachEsp(m, root, EspColors.Killer, txt, "chillisaken_ESP")
                end
            end
        end
    end

    if cfg.EspSurvivor then
        local sf = getSurvivorsFolder()
        if sf then
            for _, m in ipairs(sf:GetChildren()) do
                if m:IsA("Model") and m ~= chillisaken.State.Character then
                    local root = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
                    local hum = m:FindFirstChildOfClass("Humanoid")
                    local txt = m.Name
                    if cfg.EspHealth and hum then
                        txt = txt .. " [" .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth) .. "]"
                    end
                    attachEsp(m, root, EspColors.Survivor, txt, "chillisaken_ESP")
                end
            end
        end
    end

    local ig = getIngameFolder()
    local mapFolder = ig and ig:FindFirstChild("Map")
    if cfg.EspGenerator and mapFolder then
        for _, gen in ipairs(mapFolder:GetChildren()) do
            if gen.Name == "Generator" and gen:IsA("Model") then
                local mainPart = gen:FindFirstChild("Main") or gen.PrimaryPart or gen:FindFirstChildWhichIsA("BasePart")
                local fixed = mainPart and mainPart:FindFirstChild("generatorActivate") ~= nil
                local status = fixed and "Fixed" or "Not Fixed"
                attachEsp(gen, mainPart, EspColors.Generator, "Generator (" .. status .. ")", "chillisaken_ESP")
            end
        end
    end

    if cfg.EspItem and ig then
        for _, desc in ipairs(ig:GetDescendants()) do
            if desc:IsA("Model") and (desc.Name == "BloxyCola" or desc.Name == "Medkit" or (desc.Name == "SubspaceTripmine" and not desc:IsDescendantOf(getSurvivorsFolder() or Workspace))) then
                local part = desc:FindFirstChildWhichIsA("BasePart")
                attachEsp(desc, part, EspColors.Item, desc.Name, "chillisaken_ESP")
            end
        end
    end

    if ig then
        for _, obj in ipairs(ig:GetChildren()) do
            if cfg.EspPizza and obj.Name == "Pizza" then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                attachEsp(obj, part, EspColors.Pizza, "Pizza", "chillisaken_ESP")
            elseif cfg.EspZombie and obj.Name == "1x1x1x1Zombie" then
                local part = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
                attachEsp(obj, part, EspColors.Zombie, "1x1x1x1 Zombie", "chillisaken_ESP")
            elseif cfg.EspMine and obj.Name == "SubspaceTripmine" then
                local part = obj:FindFirstChild("SubspaceCenter") or obj:FindFirstChildWhichIsA("BasePart")
                attachEsp(obj, part, EspColors.Mine, "Subspace Tripmine", "chillisaken_ESP")
            elseif cfg.EspRespawn and obj.Name:lower():find("respawnlocation") then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                attachEsp(obj, part, EspColors.Respawn, "Respawn Point", "chillisaken_ESP")
            elseif cfg.EspSentry and (obj.Name == "BuildermanSentry" or obj.Name == "BuildermanDispenser") then
                local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                attachEsp(obj, part, EspColors.Sentry, obj.Name, "chillisaken_ESP")
            end
        end
    end
end

-- chillisaken: Animation Packs & Movement Animations
function chillisaken.ApplyAnimationPack(idleId, walkId, runId)
    if chillisaken.State.AnimPackConn then
        chillisaken.State.AnimPackConn:Disconnect()
        chillisaken.State.AnimPackConn = nil
    end
    local char = chillisaken.State.Character
    local hum = chillisaken.State.Humanoid
    if not char or not hum then return end
    local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)

    local function loadTrack(assetId)
        if not assetId or assetId == "" then return nil end
        local anim = Instance.new("Animation")
        anim.AnimationId = assetId
        local track = animator:LoadAnimation(anim)
        track.Priority = Enum.AnimationPriority.Movement
        return track
    end

    local idleTrack = loadTrack(idleId)
    local walkTrack = loadTrack(walkId)
    local runTrack = loadTrack(runId)

    chillisaken.State.AnimPackConn = RunService.RenderStepped:Connect(function()
        if not char.Parent then return end
        local speed = hum.MoveDirection.Magnitude > 0.1 and hum.WalkSpeed or 0
        local desired
        if speed < 1 then
            desired = idleTrack
        elseif speed >= 20 then
            desired = runTrack or walkTrack
        else
            desired = walkTrack or runTrack
        end
        for _, tr in ipairs({ idleTrack, walkTrack, runTrack }) do
            if tr and tr.IsPlaying and tr ~= desired then
                tr:Stop(0.2)
            end
        end
        if desired and not desired.IsPlaying then
            desired:Play()
        end
    end)
end

-- chillisaken: Background Loops
task.spawn(function()
    while true do
        pcall(chillisaken.RefreshEsp)
        pcall(chillisaken.ApplyMapTweaks)
        task.wait(1)
    end
end)

-- chillisaken: Rayfield UI Integration
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "chillisaken",
    Icon = 0,
    LoadingTitle = "chillisaken",
    LoadingSubtitle = "by chill",
    Theme = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "chillisaken",
        FileName = "Config"
    },
    KeySystem = false
})

local CombatTab = Window:CreateTab("Combat", "swords")
local AutoTab = Window:CreateTab("Automation", "bot")
local MovementTab = Window:CreateTab("Misc", "zap")
local VisualsTab = Window:CreateTab("Visuals & ESP", "eye")

-- Combat Tab
CombatTab:CreateSection("Auto Block & Hitbox Drag")

CombatTab:CreateToggle({
    Name = "Auto Block",
    CurrentValue = chillisaken.Config.AutoBlock,
    Flag = "AutoBlock",
    Callback = function(Value)
        chillisaken.SetAutoBlock(Value)
    end
})

CombatTab:CreateToggle({
    Name = "Hitbox Drag",
    CurrentValue = chillisaken.Config.HitboxDrag,
    Flag = "HitboxDrag",
    Callback = function(Value)
        chillisaken.Config.HitboxDrag = Value
    end
})

CombatTab:CreateToggle({
    Name = "Wall Check",
    CurrentValue = chillisaken.Config.WallCheck,
    Flag = "WallCheck",
    Callback = function(Value)
        chillisaken.Config.WallCheck = Value
    end
})

CombatTab:CreateToggle({
    Name = "Strict Visual Check",
    CurrentValue = chillisaken.Config.StrictVisualCheck,
    Flag = "StrictVisualCheck",
    Callback = function(Value)
        chillisaken.Config.StrictVisualCheck = Value
    end
})

CombatTab:CreateSlider({
    Name = "Block Delay (ms)",
    Range = { 0, 500 },
    Increment = 10,
    Suffix = "ms",
    CurrentValue = chillisaken.Config.BlockDelay,
    Flag = "BlockDelay",
    Callback = function(Value)
        chillisaken.Config.BlockDelay = Value
    end
})

CombatTab:CreateSlider({
    Name = "Block Range",
    Range = { 5, 40 },
    Increment = 1,
    Suffix = "studs",
    CurrentValue = chillisaken.Config.BlockRange,
    Flag = "BlockRange",
    Callback = function(Value)
        chillisaken.Config.BlockRange = Value
    end
})

CombatTab:CreateSlider({
    Name = "Hitbox Drag Range",
    Range = { 5, 60 },
    Increment = 1,
    Suffix = "studs",
    CurrentValue = chillisaken.Config.HitboxDragRange,
    Flag = "HitboxDragRange",
    Callback = function(Value)
        chillisaken.Config.HitboxDragRange = Value
    end
})

CombatTab:CreateSlider({
    Name = "Drag Speed",
    Range = { 1, 50 },
    Increment = 1,
    Suffix = "",
    CurrentValue = chillisaken.Config.DragSpeed,
    Flag = "DragSpeed",
    Callback = function(Value)
        chillisaken.Config.DragSpeed = Value
    end
})

CombatTab:CreateSection("Auto Punch & Two Time")

CombatTab:CreateToggle({
    Name = "Auto Punch",
    CurrentValue = chillisaken.Config.AutoPunch,
    Flag = "AutoPunch",
    Callback = function(Value)
        chillisaken.SetAutoPunch(Value)
    end
})

CombatTab:CreateDropdown({
    Name = "Punch Lock Mode",
    Options = { "CharterLock", "CamLock", "CamLock+CharterLock" },
    CurrentOption = { chillisaken.Config.PunchLockMode },
    MultipleOptions = false,
    Flag = "PunchLockMode",
    Callback = function(Options)
        chillisaken.Config.PunchLockMode = Options[1] or "CharterLock"
    end
})

CombatTab:CreateSlider({
    Name = "Punch Prediction",
    Range = { 0, 0.5 },
    Increment = 0.01,
    Suffix = "s",
    CurrentValue = chillisaken.Config.PunchPrediction,
    Flag = "PunchPrediction",
    Callback = function(Value)
        chillisaken.Config.PunchPrediction = Value
    end
})

CombatTab:CreateSlider({
    Name = "Punch Lock Duration",
    Range = { 0.2, 3 },
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = chillisaken.Config.PunchLockDuration,
    Flag = "PunchLockDuration",
    Callback = function(Value)
        chillisaken.Config.PunchLockDuration = Value
    end
})

CombatTab:CreateToggle({
    Name = "Two Time Backstab",
    CurrentValue = chillisaken.Config.BackstabEnabled,
    Flag = "BackstabEnabled",
    Callback = function(Value)
        chillisaken.SetTwoTime(Value)
    end
})

CombatTab:CreateToggle({
    Name = "Two Time Dashstab",
    CurrentValue = chillisaken.Config.TTDashstab,
    Flag = "TTDashstab",
    Callback = function(Value)
        chillisaken.Config.TTDashstab = Value
        if Value and not chillisaken.Config.BackstabEnabled then
            chillisaken.SetTwoTime(true)
        end
    end
})

CombatTab:CreateSlider({
    Name = "Behind Studs",
    Range = { 1, 10 },
    Increment = 0.5,
    Suffix = "studs",
    CurrentValue = chillisaken.Config.TTBehindStuds,
    Flag = "TTBehindStuds",
    Callback = function(Value)
        chillisaken.Config.TTBehindStuds = Value
    end
})

CombatTab:CreateToggle({
    Name = "Auto Studs Scaling",
    CurrentValue = chillisaken.Config.TTAutoStuds,
    Flag = "TTAutoStuds",
    Callback = function(Value)
        chillisaken.Config.TTAutoStuds = Value
    end
})

CombatTab:CreateToggle({
    Name = "Detect Ping for Auto Studs",
    CurrentValue = chillisaken.Config.TTDetectPing,
    Flag = "TTDetectPing",
    Callback = function(Value)
        chillisaken.Config.TTDetectPing = Value
    end
})

-- Automation Tab
AutoTab:CreateSection("Abilities & Generators")

AutoTab:CreateToggle({
    Name = "Auto Clone (007n7)",
    CurrentValue = chillisaken.Config.AutoClone,
    Flag = "AutoClone",
    Callback = function(Value)
        chillisaken.SetAutoClone(Value)
    end
})

AutoTab:CreateSlider({
    Name = "Clone Detection Range",
    Range = { 5, 60 },
    Increment = 1,
    Suffix = "studs",
    CurrentValue = chillisaken.Config.CloneDetectionRange,
    Flag = "CloneDetectionRange",
    Callback = function(Value)
        chillisaken.Config.CloneDetectionRange = Value
    end
})

AutoTab:CreateToggle({
    Name = "Auto Generator",
    CurrentValue = chillisaken.Config.AutoGenerator,
    Flag = "AutoGenerator",
    Callback = function(Value)
        chillisaken.SetAutoGenerator(Value)
    end
})

AutoTab:CreateToggle({
    Name = "Chance Coin Flip Target",
    CurrentValue = chillisaken.Config.ChanceCoinFlip,
    Flag = "ChanceCoinFlip",
    Callback = function(Value)
        chillisaken.SetChanceCoinFlip(Value)
    end
})

AutoTab:CreateSlider({
    Name = "Coin Flip Target Charges",
    Range = { 1, 5 },
    Increment = 1,
    Suffix = "",
    CurrentValue = chillisaken.Config.CoinFlipTarget,
    Flag = "CoinFlipTarget",
    Callback = function(Value)
        chillisaken.Config.CoinFlipTarget = Value
    end
})

AutoTab:CreateToggle({
    Name = "Auto Slash",
    CurrentValue = chillisaken.Config.AutoSlash,
    Flag = "AutoSlash",
    Callback = function(Value)
        chillisaken.SetAutoSlash(Value)
    end
})

AutoTab:CreateSlider({
    Name = "Auto Slash Distance",
    Range = { 3, 25 },
    Increment = 1,
    Suffix = "studs",
    CurrentValue = chillisaken.Config.AutoSlashDistance,
    Flag = "AutoSlashDistance",
    Callback = function(Value)
        chillisaken.Config.AutoSlashDistance = Value
    end
})

AutoTab:CreateToggle({
    Name = "Auto Ghostburger (LMS)",
    CurrentValue = chillisaken.Config.AutoGhostburgerLMS,
    Flag = "AutoGhostburgerLMS",
    Callback = function(Value)
        chillisaken.SetAutoGhostburgerLMS(Value)
    end
})

AutoTab:CreateToggle({
    Name = "Homing Tripmine",
    CurrentValue = chillisaken.Config.HomingTripmine,
    Flag = "HomingTripmine",
    Callback = function(Value)
        chillisaken.SetHomingTripmine(Value)
    end
})

-- Movement & Map Tab
MovementTab:CreateSection("Movement")

MovementTab:CreateToggle({
    Name = "Infinite Stamina",
    CurrentValue = chillisaken.Config.InfiniteStamina,
    Flag = "InfiniteStamina",
    Callback = function(Value)
        chillisaken.SetInfiniteStamina(Value)
    end
})

MovementTab:CreateToggle({
    Name = "Speed Boost",
    CurrentValue = chillisaken.Config.SpeedBoost,
    Flag = "SpeedBoost",
    Callback = function(Value)
        chillisaken.SetSpeedBoost(Value)
    end
})

MovementTab:CreateSlider({
    Name = "Speed Value",
    Range = { 1, 50 },
    Increment = 1,
    Suffix = "",
    CurrentValue = chillisaken.Config.SpeedValue,
    Flag = "SpeedValue",
    Callback = function(Value)
        chillisaken.Config.SpeedValue = Value
    end
})

MovementTab:CreateToggle({
    Name = "Flight",
    CurrentValue = chillisaken.Config.Flight,
    Flag = "Flight",
    Callback = function(Value)
        chillisaken.SetFlight(Value)
    end
})

MovementTab:CreateSlider({
    Name = "Flight Speed",
    Range = { 1, 80 },
    Increment = 1,
    Suffix = "",
    CurrentValue = chillisaken.Config.FlightSpeed,
    Flag = "FlightSpeed",
    Callback = function(Value)
        chillisaken.Config.FlightSpeed = Value
    end
})

MovementTab:CreateSection("Map & Killer Tweaks")

MovementTab:CreateToggle({
    Name = "Delete Fake Noli",
    CurrentValue = chillisaken.Config.DeleteFakeNoli,
    Flag = "DeleteFakeNoli",
    Callback = function(Value)
        chillisaken.Config.DeleteFakeNoli = Value
        chillisaken.ApplyMapTweaks()
    end
})

MovementTab:CreateToggle({
    Name = "Disable John Doe Trails",
    CurrentValue = chillisaken.Config.DisableTrails,
    Flag = "DisableTrails",
    Callback = function(Value)
        chillisaken.Config.DisableTrails = Value
        chillisaken.ApplyMapTweaks()
    end
})

MovementTab:CreateToggle({
    Name = "Disable Footprints / Shadows",
    CurrentValue = chillisaken.Config.DisableFootprints,
    Flag = "DisableFootprints",
    Callback = function(Value)
        chillisaken.Config.DisableFootprints = Value
        chillisaken.ApplyMapTweaks()
    end
})

MovementTab:CreateToggle({
    Name = "Small Spikes",
    CurrentValue = chillisaken.Config.SmallSpikes,
    Flag = "SmallSpikes",
    Callback = function(Value)
        chillisaken.Config.SmallSpikes = Value
        chillisaken.ApplyMapTweaks()
    end
})

MovementTab:CreateToggle({
    Name = "Disable Killer Walls",
    CurrentValue = chillisaken.Config.DisableKillerWalls,
    Flag = "DisableKillerWalls",
    Callback = function(Value)
        chillisaken.Config.DisableKillerWalls = Value
        chillisaken.ApplyMapTweaks()
    end
})

-- Visuals & ESP Tab
VisualsTab:CreateSection("World Visuals")

VisualsTab:CreateToggle({
    Name = "Fullbright",
    CurrentValue = chillisaken.Config.Fullbright,
    Flag = "Fullbright",
    Callback = function(Value)
        chillisaken.SetFullbright(Value)
    end
})

VisualsTab:CreateSection("ESP Toggles")

local function addEspToggle(label, configKey, flagName)
    VisualsTab:CreateToggle({
        Name = label,
        CurrentValue = chillisaken.Config[configKey],
        Flag = flagName,
        Callback = function(Value)
            chillisaken.Config[configKey] = Value
            chillisaken.RefreshEsp()
        end
    })
end

addEspToggle("ESP Killer", "EspKiller", "EspKiller")
addEspToggle("ESP Survivor", "EspSurvivor", "EspSurvivor")
addEspToggle("ESP Generator", "EspGenerator", "EspGenerator")
addEspToggle("ESP Item", "EspItem", "EspItem")
addEspToggle("ESP Pizza", "EspPizza", "EspPizza")
addEspToggle("ESP Zombie", "EspZombie", "EspZombie")
addEspToggle("ESP Mine", "EspMine", "EspMine")
addEspToggle("ESP Respawn", "EspRespawn", "EspRespawn")
addEspToggle("ESP Sentry", "EspSentry", "EspSentry")
addEspToggle("ESP Names", "EspNames", "EspNames")
addEspToggle("ESP Health", "EspHealth", "EspHealth")

return chillisaken
