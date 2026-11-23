-- chillisaken (Rayfield UI + Merged Unique Features)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TextChatService = game:GetService("TextChatService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

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
		FovValue = 70,
		Invisibility = false,
		ItemAura = false,
		SurvivorAimbot = false,
		SurvivorAimPrediction = 0.25,
		SurvivorAimSmoothness = 0.1,
		KillerAimbot = false,
		KillerAimPrediction = 0.25,
		KillerAimSmoothness = 0.1,
		AutoTpPizza = false,
		Auto1x1Popup = false
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
		AnimPackConn = nil,
		InvisTrack = nil,
		InstantGenGui = nil
	}
}

-- Helpers & References
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

-- Attack & Block ID Sets
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

-- Auto Block & Hitbox Drag
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

-- Auto Clone (007n7)
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

-- Auto Punch & Aimbot
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

-- Two Time Backstab & Dashstab
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

-- Flow Board Solver & Generator Automation
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

-- Chance & Survivor Combat Automation
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

-- Killer & Map Tweaks
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

-- Stamina, Movement & World Visuals
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

-- ESP System
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

-- Animation Packs
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

-- PlaceId Startup Notifications
if game.PlaceId == 18687417158 then
	task.spawn(function()
		pcall(function()
			StarterGui:SetCore("SendNotification", {
				Title = "Hello!",
				Text = "Welcome to B0bby Hub!",
				Image = "",
				Duration = 5
			})
			task.wait(2)
			StarterGui:SetCore("SendNotification", {
				Title = "Script Loading..",
				Text = "Please wait for the script to load.",
				Image = "",
				Duration = 5
			})
		end)
	end)
end

-- Rayfield UI Setup
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "chillisaken",
	Icon = 0,
	LoadingTitle = "chillisaken",
	LoadingSubtitle = "Feature Suite",
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

-- Floating Rayfield Visibility Button (BobbyScreengui)
function chillisaken.CreateFloatingToggleGui()
	if not LocalPlayer then return end
	local pg = LocalPlayer:WaitForChild("PlayerGui")
	if pg:FindFirstChild("BobbyScreengui") then return end

	local sg = Instance.new("ScreenGui")
	sg.Name = "BobbyScreengui"
	sg.Parent = pg
	sg.ResetOnSpawn = false

	local imgBtn = Instance.new("ImageButton")
	imgBtn.Name = "ToggleButton"
	imgBtn.Parent = sg
	imgBtn.Position = UDim2.new(0.65, 0.3, -0.15, 0)
	imgBtn.Size = UDim2.new(0, 60, 0, 60)
	imgBtn.BackgroundTransparency = 1
	imgBtn.Image = "rbxassetid://105780464700717"
	imgBtn.Draggable = true

	imgBtn.MouseButton1Click:Connect(function()
		Rayfield:SetVisibility(true)
	end)
end
chillisaken.CreateFloatingToggleGui()

-- EmoteGui System
function chillisaken.InitEmoteGui()
	if not LocalPlayer then return end
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")
	if playerGui:FindFirstChild("EmoteGui") then return end

	local emoteActive = false
	local animating = false

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "EmoteGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local frameSize = UDim2.new(0, 600, 0, 300)
	local emoteFrame = Instance.new("Frame")
	emoteFrame.Name = "Emote"
	emoteFrame.Size = frameSize
	emoteFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	emoteFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	emoteFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	emoteFrame.BorderSizePixel = 0
	emoteFrame.Visible = false
	emoteFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 15)
	corner.Parent = emoteFrame

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 35)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 15))
	})
	gradient.Parent = emoteFrame

	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.Size = frameSize
	shadow.Position = UDim2.new(0, 5, 0, 5)
	shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	shadow.BackgroundTransparency = 0.5
	shadow.BorderSizePixel = 0
	shadow.ZIndex = emoteFrame.ZIndex - 1
	shadow.Parent = emoteFrame

	local shadowCorner = Instance.new("UICorner")
	shadowCorner.CornerRadius = corner.CornerRadius
	shadowCorner.Parent = shadow

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Text = "Emotes"
	titleLabel.Size = UDim2.new(1, 0, 0, 30)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextScaled = true
	titleLabel.Parent = emoteFrame

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "EmoteScroll"
	scrollFrame.Size = UDim2.new(1, -20, 1, -45)
	scrollFrame.Position = UDim2.new(0, 10, 0, 35)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.Parent = emoteFrame

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 50, 0, 50)
	gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = scrollFrame

	gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y)
	end)

	local function openEmotes()
		if animating then return end
		animating = true
		emoteFrame.Visible = true
		emoteFrame.BackgroundTransparency = 1
		emoteFrame.Size = UDim2.new(0, 0, 0, 0)
		emoteFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		emoteFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

		local t1 = TweenService:Create(emoteFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 50, 0, 25),
			BackgroundTransparency = 0
		})
		t1:Play()
		t1.Completed:Wait()

		local t2 = TweenService:Create(emoteFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = frameSize
		})
		t2:Play()
		t2.Completed:Wait()
		animating = false
	end

	local function closeEmotes()
		if animating then return end
		animating = true
		local t1 = TweenService:Create(emoteFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 50, 0, 25)
		})
		t1:Play()
		t1.Completed:Wait()

		local t2 = TweenService:Create(emoteFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1
		})
		t2:Play()
		t2.Completed:Wait()

		emoteFrame.Visible = false
		emoteFrame.BackgroundTransparency = 0
		emoteFrame.Size = frameSize
		animating = false
	end

	local function createEmoteButton(emoteName)
		local btn = Instance.new("TextButton")
		btn.Name = "EmoteButton_" .. emoteName
		btn.Size = UDim2.new(0, 50, 0, 50)
		btn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
		btn.Text = emoteName
		btn.Font = Enum.Font.GothamBold
		btn.TextScaled = true
		btn.TextColor3 = Color3.fromRGB(240, 240, 240)
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		btn.Parent = scrollFrame

		local bCorner = Instance.new("UICorner")
		bCorner.CornerRadius = UDim.new(0, 10)
		bCorner.Parent = btn

		local bStroke = Instance.new("UIStroke")
		bStroke.Thickness = 2
		bStroke.Color = Color3.fromRGB(30, 30, 30)
		bStroke.Parent = btn

		local hoverInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad)
		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, hoverInfo, { BackgroundColor3 = Color3.fromRGB(75, 75, 75) }):Play()
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, hoverInfo, { BackgroundColor3 = Color3.fromRGB(55, 55, 55) }):Play()
		end)
		btn.MouseButton1Click:Connect(function()
			local remote = getNetworkRemote()
			if remote then
				remote:FireServer("PlayEmote", "Animations", emoteName)
			end
			emoteActive = true
			closeEmotes()
		end)
	end

	local playerData = LocalPlayer:FindFirstChild("PlayerData")
	local purchased = playerData and playerData:FindFirstChild("Purchased")
	local emotesFolder = purchased and purchased:FindFirstChild("Emotes")
	if emotesFolder then
		for _, em in ipairs(emotesFolder:GetChildren()) do
			createEmoteButton(em.Name)
		end
	end

	local toggleBtn = Instance.new("ImageButton")
	toggleBtn.Name = "ToggleButton"
	toggleBtn.Size = UDim2.new(0, 50, 0, 50)
	toggleBtn.Position = UDim2.new(1, -320, 0, -50)
	toggleBtn.BackgroundTransparency = 1
	toggleBtn.Image = "rbxassetid://117823860306601"
	toggleBtn.Parent = screenGui

	local tCorner = Instance.new("UICorner")
	tCorner.CornerRadius = UDim.new(1, 0)
	tCorner.Parent = toggleBtn

	local tStroke = Instance.new("UIStroke")
	tStroke.Thickness = 2
	tStroke.Color = Color3.fromRGB(30, 30, 30)
	tStroke.Parent = toggleBtn

	toggleBtn.MouseButton1Click:Connect(function()
		if animating then return end
		if emoteActive then
			local ef = LocalPlayer:FindFirstChild("PlayerData")
				and LocalPlayer.PlayerData:FindFirstChild("Purchased")
				and LocalPlayer.PlayerData.Purchased:FindFirstChild("Emotes")
			local remote = getNetworkRemote()
			if ef and remote then
				for _, em in ipairs(ef:GetChildren()) do
					remote:FireServer("StopEmote", "Animations", em.Name)
				end
			end
			emoteActive = false
			closeEmotes()
		elseif emoteFrame.Visible then
			closeEmotes()
		else
			openEmotes()
		end
	end)
end
task.spawn(chillisaken.InitEmoteGui)

-- Unique ESPs: John Doe Spike & Pizza Delivery Minion
function chillisaken.EspJohnDoeSpike()
	local ig = getIngameFolder()
	if not ig then return end
	local color = Color3.fromRGB(255, 140, 0)
	local function addSpikeEsp(obj)
		if obj and obj.Name == "Spike" and not obj:FindFirstChildOfClass("Highlight") then
			local hl = Instance.new("Highlight")
			hl.Name = "SpikeESP"
			hl.Parent = obj
			hl.Adornee = obj
			hl.FillTransparency = 0.75
			hl.FillColor = color
			hl.OutlineColor = color
			hl.OutlineTransparency = 0
		end
	end
	for _, child in ipairs(ig:GetChildren()) do
		addSpikeEsp(child)
	end
	ig.ChildAdded:Connect(addSpikeEsp)
end

function chillisaken.EspPizzaMinion()
	local ig = getIngameFolder()
	if not ig then return end
	local color = Color3.fromRGB(139, 0, 0)
	local function addMinionEsp(obj)
		if obj and obj.Name == "PizzaDeliveryRig" and not obj:FindFirstChildOfClass("Highlight") then
			local hl = Instance.new("Highlight")
			hl.Name = "PizzaDeliveryMinionEsp"
			hl.Parent = obj
			hl.Adornee = obj
			hl.FillTransparency = 0.75
			hl.FillColor = color
			hl.OutlineColor = color
			hl.OutlineTransparency = 0

			local bb = Instance.new("BillboardGui")
			bb.Name = "PizzaDeliveryMinionEsp"
			bb.Size = UDim2.new(0, 100, 0, 50)
			bb.AlwaysOnTop = true
			bb.MaxDistance = math.huge
			bb.Parent = obj
			bb.StudsOffset = Vector3.new(0, 3, 0)

			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, 0, 1, 0)
			lbl.BackgroundTransparency = 1
			lbl.TextScaled = true
			lbl.Text = "Pizza Delivery Minion"
			lbl.TextColor3 = color
			lbl.Font = Enum.Font.Antique
			lbl.Parent = bb
		end
	end
	for _, child in ipairs(ig:GetChildren()) do
		addMinionEsp(child)
	end
	ig.ChildAdded:Connect(addMinionEsp)
end

-- Invisibility Toggle
local function bindInvisCharacter(char)
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://75804462760596"
	local animator = hum:FindFirstChildOfClass("Animator") or hum:WaitForChild("Animator", 5)
	if animator then
		chillisaken.State.InvisTrack = animator:LoadAnimation(anim)
		if chillisaken.Config.Invisibility then
			chillisaken.State.InvisTrack:Play()
			task.wait(0.00025)
			chillisaken.State.InvisTrack:AdjustSpeed(0)
		end
	end
end

function chillisaken.SetInvisibility(enabled)
	chillisaken.Config.Invisibility = enabled
	if chillisaken.State.InvisTrack then
		if enabled then
			chillisaken.State.InvisTrack:Play()
			task.wait(0.00025)
			chillisaken.State.InvisTrack:AdjustSpeed(0)
		else
			chillisaken.State.InvisTrack:Stop()
		end
	elseif enabled and LocalPlayer and LocalPlayer.Character then
		bindInvisCharacter(LocalPlayer.Character)
	end
end

if LocalPlayer then
	if LocalPlayer.Character then
		task.spawn(bindInvisCharacter, LocalPlayer.Character)
	end
	LocalPlayer.CharacterAdded:Connect(bindInvisCharacter)
end

-- Instant Proximity Prompt
function chillisaken.EnableInstantProximityPrompt()
	local function hookPrompt(prompt)
		if prompt:IsA("ProximityPrompt") then
			prompt.PromptButtonHoldBegan:Connect(function()
				if prompt.HoldDuration > 0 and typeof(fireproximityprompt) == "function" then
					fireproximityprompt(prompt, 0)
				end
			end)
		end
	end
	for _, desc in ipairs(Workspace:GetDescendants()) do
		hookPrompt(desc)
	end
	Workspace.DescendantAdded:Connect(hookPrompt)
end

-- Anti Stun & Status Effect Removers
function chillisaken.AntiStun()
	local statusEffects = ReplicatedStorage:FindFirstChild("Modules")
		and ReplicatedStorage.Modules:FindFirstChild("StatusEffects")
	local stunned = statusEffects and statusEffects:FindFirstChild("Stunned")
	if stunned then
		stunned:Destroy()
	else
		Rayfield:Notify({
			Title = "Already unstunable",
			Content = "Your already unstunable. no need to activate it again.",
			Duration = 3,
			Image = "shield-off"
		})
	end
end

function chillisaken.RemoveStatusEffect(subFolder, effectName, extraDestroyName)
	local statusEffects = ReplicatedStorage:FindFirstChild("Modules")
		and ReplicatedStorage.Modules:FindFirstChild("StatusEffects")
	local container = subFolder and (statusEffects and statusEffects:FindFirstChild(subFolder)) or statusEffects
	local target = container and container:FindFirstChild(effectName)
	if target then
		if extraDestroyName and statusEffects and statusEffects:FindFirstChild(extraDestroyName) then
			statusEffects[extraDestroyName]:Destroy()
		end
		target:Destroy()
	else
		Rayfield:Notify({
			Title = "Already Removed",
			Content = effectName .. " effect is already removed.",
			Duration = 3,
			Image = 4483362458
		})
	end
end

-- Item Aura Toggle
function chillisaken.SetItemAura(enabled)
	chillisaken.Config.ItemAura = enabled
	if not enabled then return end
	task.spawn(function()
		while chillisaken.Config.ItemAura do
			local ig = getIngameFolder()
			if ig and typeof(fireproximityprompt) == "function" then
				for _, item in ipairs(ig:GetChildren()) do
					local itemRoot = item:FindFirstChild("ItemRoot")
					local prompt = itemRoot and itemRoot:FindFirstChild("ProximityPrompt")
					if prompt then
						fireproximityprompt(prompt)
					end
				end
			end
			task.wait(1)
		end
	end)
end

-- Instant Generator Fix Helper (for GUI button & keybind)
local function triggerAllGeneratorsOnce()
	local ig = getIngameFolder()
	local mapFolder = ig and ig:FindFirstChild("Map")
	if not mapFolder then return end
	for _, gen in ipairs(mapFolder:GetChildren()) do
		if gen.Name == "Generator" then
			local remotes = gen:FindFirstChild("Remotes")
			local re = remotes and remotes:FindFirstChild("RE")
			if re and re:IsA("RemoteEvent") then
				re:FireServer()
			end
		end
	end
end

function chillisaken.SetInstantGenGui(enabled)
	if enabled then
		if chillisaken.State.InstantGenGui then return end
		local sg = Instance.new("ScreenGui")
		sg.Name = "InstantGenGui"
		sg.Parent = LocalPlayer:WaitForChild("PlayerGui")
		sg.ResetOnSpawn = false

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 100, 0, 50)
		btn.Font = Enum.Font.FredokaOne
		btn.Position = UDim2.new(0.5, -50, 0.8, 0)
		btn.Text = "Instant fix"
		btn.BackgroundColor3 = Color3.fromRGB(0, 119, 255)
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Parent = sg
		btn.Draggable = true
		btn.TextSize = 15

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 20)
		corner.Parent = btn

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Color = Color3.fromRGB(0, 0, 0)
		stroke.Parent = btn
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		local cooling = false
		btn.MouseEnter:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
		end)
		btn.MouseLeave:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(0, 119, 255)
		end)
		btn.MouseButton1Click:Connect(function()
			if cooling then return end
			cooling = true
			triggerAllGeneratorsOnce()
			local left = 2.5
			while left > 0 do
				btn.Text = string.format("%.1f", left)
				task.wait(0.1)
				left -= 0.1
			end
			cooling = false
			btn.Text = "Instant fix"
		end)
		chillisaken.State.InstantGenGui = sg
	elseif chillisaken.State.InstantGenGui then
		chillisaken.State.InstantGenGui:Destroy()
		chillisaken.State.InstantGenGui = nil
	end
end

-- Survivor Aimbot & Killer Aimbot
local SurvivorTriggerAnims = {
	["rbxassetid://87259391926321"] = true, ["rbxassetid://106014898528300"] = true,
	["rbxassetid://86545133269813"] = true, ["rbxassetid://89448354637442"] = true,
	["rbxassetid://90499469533503"] = true, ["rbxassetid://116618003477002"] = true,
	["rbxassetid://106086955212611"] = true, ["rbxassetid://107640065977686"] = true,
	["rbxassetid://77124578197357"] = true, ["rbxassetid://101771617803133"] = true,
	["rbxassetid://134958187822107"] = true, ["rbxassetid://111313169447787"] = true,
	["rbxassetid://71685573690338"] = true, ["rbxassetid://129843313690921"] = true,
	["rbxassetid://97623143664485"] = true, ["rbxassetid://136007065400978"] = true,
	["rbxassetid://86096387000557"] = true, ["rbxassetid://108807732150251"] = true,
	["rbxassetid://138040001965654"] = true, ["rbxassetid://73502073176819"] = true,
	["rbxassetid://86709774283672"] = true, ["rbxassetid://140703210927645"] = true,
	["rbxassetid://96173857867228"] = true, ["rbxassetid://121255898612475"] = true,
	["rbxassetid://98031287364865"] = true, ["rbxassetid://119462383658044"] = true,
	["rbxassetid://77448521277146"] = true, ["rbxassetid://103741352379819"] = true,
	["rbxassetid://131696603025265"] = true, ["rbxassetid://122503338277352"] = true,
	["rbxassetid://97648548303678"] = true, ["rbxassetid://133491532453922"] = true
}

local KillerTriggerAnims = {
	["rbxassetid://131430497821198"] = true, ["rbxassetid://83829782357897"] = true,
	["rbxassetid://126830014841198"] = true, ["rbxassetid://126355327951215"] = true,
	["rbxassetid://121086746534252"] = true, ["rbxassetid://105458270463374"] = true,
	["rbxassetid://127172483138092"] = true, ["rbxassetid://18885919947"] = true,
	["rbxassetid://18885909645"] = true, ["rbxassetid://94162446513587"] = true,
	["rbxassetid://84426150435898"] = true, ["rbxassetid://93069721274110"] = true,
	["rbxassetid://114620047310688"] = true, ["rbxassetid://97433060861952"] = true,
	["rbxassetid://82183356141401"] = true, ["rbxassetid://100592913030351"] = true,
	["rbxassetid://121293883585738"] = true, ["rbxassetid://70447634862911"] = true,
	["rbxassetid://92173139187970"] = true, ["rbxassetid://106847695270773"] = true,
	["rbxassetid://125403313786645"] = true, ["rbxassetid://81639435858902"] = true,
	["rbxassetid://137314737492715"] = true, ["rbxassetid://120112897026015"] = true,
	["rbxassetid://82113744478546"] = true, ["rbxassetid://118298475669935"] = true,
	["rbxassetid://126681776859538"] = true, ["rbxassetid://129976080405072"] = true,
	["rbxassetid://109667959938617"] = true, ["rbxassetid://74707328554358"] = true,
	["rbxassetid://133336594357903"] = true, ["rbxassetid://86204001129974"] = true,
	["rbxassetid://124243639579224"] = true, ["rbxassetid://70371667919898"] = true,
	["rbxassetid://131543461321709"] = true, ["rbxassetid://136323728355613"] = true,
	["rbxassetid://109230267448394"] = true
}

function chillisaken.SetSurvivorAimbot(enabled)
	chillisaken.Config.SurvivorAimbot = enabled
	if chillisaken.Connections.SurvivorAimbot then
		for _, c in ipairs(chillisaken.Connections.SurvivorAimbot) do
			if c.Connected then c:Disconnect() end
		end
		chillisaken.Connections.SurvivorAimbot = nil
	end
	if not enabled then return end

	local active = false
	local lockedTarget = nil
	local conns = {}

	local function triggerLock()
		local k = getClosestKiller(math.huge)
		if k and k:FindFirstChild("HumanoidRootPart") then
			lockedTarget = k
			active = true
			task.delay(2, function()
				active = false
				lockedTarget = nil
			end)
		end
	end

	local function hookChar(char)
		local hum = char:FindFirstChild("Humanoid") or char:WaitForChild("Humanoid", 5)
		if hum then
			table.insert(conns, hum.AnimationPlayed:Connect(function(track)
				if chillisaken.Config.SurvivorAimbot and track.Animation and SurvivorTriggerAnims[track.Animation.AnimationId] then
					triggerLock()
				end
			end))
		end
	end

	table.insert(conns, RunService.RenderStepped:Connect(function()
		if active and lockedTarget and lockedTarget:FindFirstChild("HumanoidRootPart") and Camera then
			local hrp = lockedTarget.HumanoidRootPart
			local aimPos = hrp.Position + hrp.Velocity * (chillisaken.Config.SurvivorAimPrediction or 0.25)
			local goal = CFrame.new(Camera.CFrame.Position, aimPos)
			Camera.CFrame = Camera.CFrame:Lerp(goal, chillisaken.Config.SurvivorAimSmoothness or 0.1)
		end
	end))

	if LocalPlayer and LocalPlayer.Character then
		hookChar(LocalPlayer.Character)
	end
	if LocalPlayer then
		table.insert(conns, LocalPlayer.CharacterAdded:Connect(hookChar))
	end
	chillisaken.Connections.SurvivorAimbot = conns
end

function chillisaken.SetKillerAimbot(enabled)
	chillisaken.Config.KillerAimbot = enabled
	if chillisaken.Connections.KillerAimbot then
		for _, c in ipairs(chillisaken.Connections.KillerAimbot) do
			if c.Connected then c:Disconnect() end
		end
		chillisaken.Connections.KillerAimbot = nil
	end
	if not enabled then return end

	local active = false
	local lockedPlayer = nil
	local conns = {}

	local function getNearestPlayerChar()
		local root = chillisaken.State.Root
		if not root then return nil end
		local best, bestDist = nil, math.huge
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
				local d = (plr.Character.HumanoidRootPart.Position - root.Position).Magnitude
				if d < bestDist then
					bestDist = d
					best = plr.Character
				end
			end
		end
		return best
	end

	local function triggerLock()
		local targetChar = getNearestPlayerChar()
		if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
			lockedPlayer = targetChar
			active = true
			task.delay(2, function()
				active = false
				lockedPlayer = nil
			end)
		end
	end

	local function hookChar(char)
		local hum = char:WaitForChild("Humanoid", 5)
		if hum then
			table.insert(conns, hum.AnimationPlayed:Connect(function(track)
				if chillisaken.Config.KillerAimbot and track.Animation and KillerTriggerAnims[track.Animation.AnimationId] then
					triggerLock()
				end
			end))
		end
	end

	table.insert(conns, RunService.RenderStepped:Connect(function()
		if active and lockedPlayer and lockedPlayer:FindFirstChild("HumanoidRootPart") and Camera then
			local hrp = lockedPlayer.HumanoidRootPart
			local aimPos = hrp.Position + hrp.Velocity * (chillisaken.Config.KillerAimPrediction or 0.25)
			local goal = CFrame.new(Camera.CFrame.Position, aimPos)
			Camera.CFrame = Camera.CFrame:Lerp(goal, chillisaken.Config.KillerAimSmoothness or 0.1)
		end
	end))

	if LocalPlayer and LocalPlayer.Character then
		hookChar(LocalPlayer.Character)
	end
	if LocalPlayer then
		table.insert(conns, LocalPlayer.CharacterAdded:Connect(hookChar))
	end
	chillisaken.Connections.KillerAimbot = conns
end

-- Dusekarr Switchable Aimbot
function chillisaken.CreateDusekarrSwitchableAimbot()
	if not LocalPlayer then return end
	local pg = LocalPlayer:WaitForChild("PlayerGui")
	local sg = Instance.new("ScreenGui")
	sg.Name = "DusekarrAimbotGui"
	sg.Parent = pg

	local btn = Instance.new("TextButton")
	btn.Parent = sg
	btn.Size = UDim2.new(0, 200, 0, 50)
	btn.Position = UDim2.new(0.5, -100, 0.1, 0)
	btn.Text = "Target: Survivors"
	btn.BackgroundColor3 = Color3.fromRGB(34, 139, 34)
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.SourceSansBold
	btn.TextSize = 24
	btn.Draggable = true

	local mode = "Survivor"
	local pred = 0.25
	local hum = (LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()):WaitForChild("Humanoid")
	local animator = hum:FindFirstChildOfClass("Animator") or hum:WaitForChild("Animator")
	local lockConn = nil

	local function centerScreen()
		local cam = Workspace.CurrentCamera
		return Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
	end

	local function nearestScreenSurvivor()
		local best, bestDist = nil, math.huge
		local cam = Workspace.CurrentCamera
		local ctr = centerScreen()
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
				local pt, onScreen = cam:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
				if onScreen then
					local dist = (ctr - Vector2.new(pt.X, pt.Y)).Magnitude
					if dist < bestDist then
						bestDist = dist
						best = plr
					end
				end
			end
		end
		return best
	end

	local function nearestScreenKiller()
		local best, bestDist = nil, math.huge
		local cam = Workspace.CurrentCamera
		local ctr = centerScreen()
		local kf = getKillersFolder()
		if kf then
			for _, k in ipairs(kf:GetChildren()) do
				if k:IsA("Model") and k:FindFirstChild("HumanoidRootPart") then
					local pt = cam:WorldToScreenPoint(k.HumanoidRootPart.Position)
					local dist = (ctr - Vector2.new(pt.X, pt.Y)).Magnitude
					if dist < bestDist then
						bestDist = dist
						best = k
					end
				end
			end
		end
		return best
	end

	local function startLock()
		if lockConn then lockConn:Disconnect() lockConn = nil end
		local targetPart
		if mode == "Survivor" then
			local p = nearestScreenSurvivor()
			targetPart = p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		else
			local k = nearestScreenKiller()
			targetPart = k and k:FindFirstChild("HumanoidRootPart")
		end
		if targetPart then
			lockConn = RunService.RenderStepped:Connect(function()
				if targetPart and targetPart.Parent and Workspace.CurrentCamera then
					local goalPos = targetPart.Position + targetPart.Velocity * pred
					Workspace.CurrentCamera.CFrame = CFrame.new(Workspace.CurrentCamera.CFrame.Position, goalPos)
				end
			end)
			task.delay(2, function()
				if lockConn then lockConn:Disconnect() lockConn = nil end
			end)
		end
	end

	btn.MouseButton1Click:Connect(function()
		if mode == "Survivor" then
			mode = "Killer"
			btn.Text = "Target: Killer"
			btn.BackgroundColor3 = Color3.fromRGB(220, 0, 0)
		else
			mode = "Survivor"
			btn.Text = "Target: Survivors"
			btn.BackgroundColor3 = Color3.fromRGB(34, 139, 34)
		end
	end)

	animator.AnimationPlayed:Connect(function(track)
		if track.Animation and track.Animation.AnimationId == "rbxassetid://77894750279891" then
			startLock()
		end
	end)
end

-- Auto TP to Pizza
function chillisaken.SetAutoTpPizza(enabled)
	chillisaken.Config.AutoTpPizza = enabled
	if not enabled then return end
	task.spawn(function()
		while chillisaken.Config.AutoTpPizza do
			local ig = getIngameFolder()
			local pizza = ig and ig:FindFirstChild("Pizza")
			local hrp = LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if pizza and hrp and ig then
				local oldPos = hrp.Position
				task.wait(1)
				if pizza and pizza:IsDescendantOf(ig) and hrp.Parent then
					hrp.CFrame = pizza.CFrame
				end
				task.wait(0.5)
				if hrp.Parent then
					hrp.CFrame = CFrame.new(oldPos)
				end
			end
			task.wait(1)
		end
	end)
end

-- Auto 1x1x1x1 Popup
function chillisaken.SetAuto1x1Popup(enabled)
	chillisaken.Config.Auto1x1Popup = enabled
	if not enabled then return end
	task.spawn(function()
		while chillisaken.Config.Auto1x1Popup do
			local tempUi = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("TemporaryUI")
			if tempUi then
				for _, child in ipairs(tempUi:GetChildren()) do
					if child.Name == "1x1x1x1Popup" then
						local cx = child.AbsolutePosition.X + child.AbsoluteSize.X / 2
						local cy = child.AbsolutePosition.Y + child.AbsoluteSize.Y / 2 + 50
						pcall(function()
							VirtualInputManager:SendMouseButtonEvent(cx, cy, Enum.UserInputType.MouseButton1.Value, true, LocalPlayer.PlayerGui, 1)
							VirtualInputManager:SendMouseButtonEvent(cx, cy, Enum.UserInputType.MouseButton1.Value, false, LocalPlayer.PlayerGui, 1)
						end)
					end
				end
			end
			task.wait(0.1)
		end
	end)
end

-- Fun Buttons & Flip/Slide Actions
local function ensureFunScreenGui()
	local pg = LocalPlayer:WaitForChild("PlayerGui")
	local sg = pg:FindFirstChild("ScreenGui")
	if not sg then
		sg = Instance.new("ScreenGui")
		sg.Name = "ScreenGui"
		sg.Parent = pg
	end
	return sg
end

local function createDraggableAnimButton(imageId, animId)
	local sg = ensureFunScreenGui()
	local btn = Instance.new("ImageButton")
	btn.Size = UDim2.new(0, 100, 0, 100)
	btn.Position = UDim2.new(0.5, -50, 0.5, -50)
	btn.Image = imageId
	btn.BackgroundTransparency = 1
	btn.Parent = sg

	local anim = Instance.new("Animation")
	anim.AnimationId = animId

	btn.MouseButton1Click:Connect(function()
		local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum:LoadAnimation(anim):Play()
		end
	end)

	local dragging, dragInput, dragStart, startPos
	btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = btn.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	btn.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

function chillisaken.PerformFlip(isBackflip)
	local char = LocalPlayer and (LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())
	if not char then return end
	local hrp = char:WaitForChild("HumanoidRootPart")
	local hum = char:WaitForChild("Humanoid")
	hum:ChangeState(Enum.HumanoidStateType.Physics)
	hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Running, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)

	local duration = 0.45
	local steps = 120
	local startCf = hrp.CFrame
	local dir = isBackflip and -startCf.LookVector or startCf.LookVector
	local up = Vector3.new(0, 1, 0)

	task.spawn(function()
		local t0 = tick()
		for i = 1, steps do
			local alpha = i / steps
			local arc = 4 * (alpha - alpha ^ 2) * 10
			local pos = startCf.Position + dir * (35 * alpha) + up * arc
			local rot = startCf.Rotation * CFrame.Angles(-math.rad(i * (360 / steps)), 0, 0)
			hrp.CFrame = CFrame.new(pos) * rot
			local waitTime = (duration / steps) * i - (tick() - t0)
			if waitTime > 0 then
				task.wait(waitTime)
			end
		end
		hrp.CFrame = CFrame.new(startCf.Position + dir * 35) * startCf.Rotation
		hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
		hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
		hum:SetStateEnabled(Enum.HumanoidStateType.Running, true)
		hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
		hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
		hum:ChangeState(Enum.HumanoidStateType.Running)
	end)
end

local function createFlipGuiButton(imageId, isBackflip)
	local sg = ensureFunScreenGui()
	local btn = Instance.new("ImageButton")
	btn.Size = UDim2.new(0, 100, 0, 100)
	btn.Position = UDim2.new(0.5, -50, 0.5, -50)
	btn.Image = imageId
	btn.BackgroundTransparency = 1
	btn.Parent = sg
	btn.MouseButton1Click:Connect(function()
		chillisaken.PerformFlip(isBackflip)
	end)

	local dragging, dragInput, dragStart, startPos
	btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = btn.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	btn.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

function chillisaken.CreateSlideButton()
	local sg = ensureFunScreenGui()
	local btn = Instance.new("ImageButton")
	btn.Size = UDim2.new(0, 100, 0, 100)
	btn.Position = UDim2.new(0.5, -50, 0.5, -50)
	btn.Image = "rbxassetid://110777561976075"
	btn.BackgroundTransparency = 1
	btn.Parent = sg
	btn.Draggable = true

	btn.MouseButton1Click:Connect(function()
		local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		local hrp = char:WaitForChild("HumanoidRootPart")
		local hum = char:WaitForChild("Humanoid")
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://182749109"
		local track = hum:LoadAnimation(anim)
		track:Play()
		local goalCf = hrp.CFrame * CFrame.new(0, 0, -20)
		local tw = TweenService:Create(hrp, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { CFrame = goalCf })
		tw:Play()
		tw.Completed:Connect(function()
			track:Stop()
		end)
	end)
end

-- Tabs & Controls
local CombatTab = Window:CreateTab("Combat", "swords")
local AutoTab = Window:CreateTab("Automation", "bot")
local MovementTab = Window:CreateTab("Movement & Map", "zap")
local VisualsTab = Window:CreateTab("Visuals & ESP", "eye")
local FunTab = Window:CreateTab("Fun", "smile")
local CreditsTab = Window:CreateTab("Credits", "clipboard")
local SettingsTab = Window:CreateTab("Settings", "settings")

-- Combat Tab
CombatTab:CreateSection("Auto Block & Hitbox Drag")
CombatTab:CreateToggle({ Name = "Auto Block", CurrentValue = chillisaken.Config.AutoBlock, Flag = "AutoBlock", Callback = function(Value) chillisaken.SetAutoBlock(Value) end })
CombatTab:CreateToggle({ Name = "Hitbox Drag", CurrentValue = chillisaken.Config.HitboxDrag, Flag = "HitboxDrag", Callback = function(Value) chillisaken.Config.HitboxDrag = Value end })
CombatTab:CreateToggle({ Name = "Wall Check", CurrentValue = chillisaken.Config.WallCheck, Flag = "WallCheck", Callback = function(Value) chillisaken.Config.WallCheck = Value end })
CombatTab:CreateToggle({ Name = "Strict Visual Check", CurrentValue = chillisaken.Config.StrictVisualCheck, Flag = "StrictVisualCheck", Callback = function(Value) chillisaken.Config.StrictVisualCheck = Value end })
CombatTab:CreateSlider({ Name = "Block Delay (ms)", Range = { 0, 500 }, Increment = 10, Suffix = "ms", CurrentValue = chillisaken.Config.BlockDelay, Flag = "BlockDelay", Callback = function(Value) chillisaken.Config.BlockDelay = Value end })
CombatTab:CreateSlider({ Name = "Block Range", Range = { 5, 40 }, Increment = 1, Suffix = "studs", CurrentValue = chillisaken.Config.BlockRange, Flag = "BlockRange", Callback = function(Value) chillisaken.Config.BlockRange = Value end })
CombatTab:CreateSlider({ Name = "Hitbox Drag Range", Range = { 5, 60 }, Increment = 1, Suffix = "studs", CurrentValue = chillisaken.Config.HitboxDragRange, Flag = "HitboxDragRange", Callback = function(Value) chillisaken.Config.HitboxDragRange = Value end })
CombatTab:CreateSlider({ Name = "Drag Speed", Range = { 1, 50 }, Increment = 1, Suffix = "", CurrentValue = chillisaken.Config.DragSpeed, Flag = "DragSpeed", Callback = function(Value) chillisaken.Config.DragSpeed = Value end })

CombatTab:CreateSection("Auto Punch & Two Time")
CombatTab:CreateToggle({ Name = "Auto Punch", CurrentValue = chillisaken.Config.AutoPunch, Flag = "AutoPunch", Callback = function(Value) chillisaken.SetAutoPunch(Value) end })
CombatTab:CreateDropdown({ Name = "Punch Lock Mode", Options = { "CharterLock", "CamLock", "CamLock+CharterLock" }, CurrentOption = { chillisaken.Config.PunchLockMode }, MultipleOptions = false, Flag = "PunchLockMode", Callback = function(Options) chillisaken.Config.PunchLockMode = Options[1] or "CharterLock" end })
CombatTab:CreateSlider({ Name = "Punch Prediction", Range = { 0, 0.5 }, Increment = 0.01, Suffix = "s", CurrentValue = chillisaken.Config.PunchPrediction, Flag = "PunchPrediction", Callback = function(Value) chillisaken.Config.PunchPrediction = Value end })
CombatTab:CreateSlider({ Name = "Punch Lock Duration", Range = { 0.2, 3 }, Increment = 0.1, Suffix = "s", CurrentValue = chillisaken.Config.PunchLockDuration, Flag = "PunchLockDuration", Callback = function(Value) chillisaken.Config.PunchLockDuration = Value end })
CombatTab:CreateToggle({ Name = "Two Time Backstab", CurrentValue = chillisaken.Config.BackstabEnabled, Flag = "BackstabEnabled", Callback = function(Value) chillisaken.SetTwoTime(Value) end })
CombatTab:CreateToggle({ Name = "Two Time Dashstab", CurrentValue = chillisaken.Config.TTDashstab, Flag = "TTDashstab", Callback = function(Value) chillisaken.Config.TTDashstab = Value if Value and not chillisaken.Config.BackstabEnabled then chillisaken.SetTwoTime(true) end end })
CombatTab:CreateSlider({ Name = "Behind Studs", Range = { 1, 10 }, Increment = 0.5, Suffix = "studs", CurrentValue = chillisaken.Config.TTBehindStuds, Flag = "TTBehindStuds", Callback = function(Value) chillisaken.Config.TTBehindStuds = Value end })
CombatTab:CreateToggle({ Name = "Auto Studs Scaling", CurrentValue = chillisaken.Config.TTAutoStuds, Flag = "TTAutoStuds", Callback = function(Value) chillisaken.Config.TTAutoStuds = Value end })
CombatTab:CreateToggle({ Name = "Detect Ping for Auto Studs", CurrentValue = chillisaken.Config.TTDetectPing, Flag = "TTDetectPing", Callback = function(Value) chillisaken.Config.TTDetectPing = Value end })

CombatTab:CreateSection("Separate Aimbots")
CombatTab:CreateToggle({ Name = "Survivor Aimbot", CurrentValue = false, Flag = "B0bbySurvivorAimbot", Callback = function(Value) chillisaken.SetSurvivorAimbot(Value) end })
CombatTab:CreateSlider({ Name = "Survivor Aimbot Prediction", Range = { 0.25, 1 }, Increment = 0.25, Suffix = "", CurrentValue = 0.25, Flag = "B0bbySurvivorAimPred", Callback = function(Value) chillisaken.Config.SurvivorAimPrediction = Value end })
CombatTab:CreateSlider({ Name = "Survivor Aimbot Smoothness", Range = { 0.05, 1 }, Increment = 0.05, Suffix = "", CurrentValue = 0.1, Flag = "B0bbySurvivorAimSmooth", Callback = function(Value) chillisaken.Config.SurvivorAimSmoothness = Value end })
CombatTab:CreateToggle({ Name = "Killer Aimbot", CurrentValue = false, Flag = "B0bbyKillerAimbot", Callback = function(Value) chillisaken.SetKillerAimbot(Value) end })
CombatTab:CreateSlider({ Name = "Killer Aimbot Prediction", Range = { 0.25, 1 }, Increment = 0.25, Suffix = "", CurrentValue = 0.25, Flag = "B0bbyKillerAimPred", Callback = function(Value) chillisaken.Config.KillerAimPrediction = Value end })
CombatTab:CreateSlider({ Name = "Killer Aimbot Smoothness", Range = { 0.05, 1 }, Increment = 0.05, Suffix = "", CurrentValue = 0.1, Flag = "B0bbyKillerAimSmooth", Callback = function(Value) chillisaken.Config.KillerAimSmoothness = Value end })
CombatTab:CreateButton({ Name = "Dusekarr Switchable Aimbot", Callback = function() chillisaken.CreateDusekarrSwitchableAimbot() end })

-- Automation Tab
AutoTab:CreateSection("Abilities & Generators")
AutoTab:CreateToggle({ Name = "Auto Clone (007n7)", CurrentValue = chillisaken.Config.AutoClone, Flag = "AutoClone", Callback = function(Value) chillisaken.SetAutoClone(Value) end })
AutoTab:CreateSlider({ Name = "Clone Detection Range", Range = { 5, 60 }, Increment = 1, Suffix = "studs", CurrentValue = chillisaken.Config.CloneDetectionRange, Flag = "CloneDetectionRange", Callback = function(Value) chillisaken.Config.CloneDetectionRange = Value end })
AutoTab:CreateToggle({ Name = "Auto Generator", CurrentValue = chillisaken.Config.AutoGenerator, Flag = "AutoGenerator", Callback = function(Value) chillisaken.SetAutoGenerator(Value) end })
AutoTab:CreateToggle({ Name = "Chance Coin Flip Target", CurrentValue = chillisaken.Config.ChanceCoinFlip, Flag = "ChanceCoinFlip", Callback = function(Value) chillisaken.SetChanceCoinFlip(Value) end })
AutoTab:CreateSlider({ Name = "Coin Flip Target Charges", Range = { 1, 5 }, Increment = 1, Suffix = "", CurrentValue = chillisaken.Config.CoinFlipTarget, Flag = "CoinFlipTarget", Callback = function(Value) chillisaken.Config.CoinFlipTarget = Value end })
AutoTab:CreateToggle({ Name = "Auto Slash", CurrentValue = chillisaken.Config.AutoSlash, Flag = "AutoSlash", Callback = function(Value) chillisaken.SetAutoSlash(Value) end })
AutoTab:CreateSlider({ Name = "Auto Slash Distance", Range = { 3, 25 }, Increment = 1, Suffix = "studs", CurrentValue = chillisaken.Config.AutoSlashDistance, Flag = "AutoSlashDistance", Callback = function(Value) chillisaken.Config.AutoSlashDistance = Value end })
AutoTab:CreateToggle({ Name = "Auto Ghostburger (LMS)", CurrentValue = chillisaken.Config.AutoGhostburgerLMS, Flag = "AutoGhostburgerLMS", Callback = function(Value) chillisaken.SetAutoGhostburgerLMS(Value) end })
AutoTab:CreateToggle({ Name = "Homing Tripmine", CurrentValue = chillisaken.Config.HomingTripmine, Flag = "HomingTripmine", Callback = function(Value) chillisaken.SetHomingTripmine(Value) end })

AutoTab:CreateSection("Utilities & Status Removers")
AutoTab:CreateToggle({ Name = "Invisibility", CurrentValue = false, Flag = "B0bbyInvisibility", Callback = function(Value) chillisaken.SetInvisibility(Value) end })
AutoTab:CreateButton({ Name = "Instant Proximity Prompt", Callback = function() chillisaken.EnableInstantProximityPrompt() end })
AutoTab:CreateButton({ Name = "Anti Stun", Callback = function() chillisaken.AntiStun() end })
AutoTab:CreateToggle({ Name = "Item Aura", CurrentValue = false, Flag = "B0bbyItemAura", Callback = function(Value) chillisaken.SetItemAura(Value) end })
AutoTab:CreateToggle({ Name = "Instant Fix Generator (GUI Button)", CurrentValue = false, Flag = "B0bbyInstantGenGui", Callback = function(Value) chillisaken.SetInstantGenGui(Value) end })
AutoTab:CreateKeybind({ Name = "Instant Fix Generator Keybind", CurrentKeybind = "Q", HoldToInteract = false, Flag = "B0bbyInstantGenKeybind", Callback = function() triggerAllGeneratorsOnce() end })
AutoTab:CreateToggle({ Name = "Auto TP to Pizza", CurrentValue = false, Flag = "B0bbyAutoTpPizza", Callback = function(Value) chillisaken.SetAutoTpPizza(Value) end })
AutoTab:CreateToggle({ Name = "Auto 1x1x1x1 Popup", CurrentValue = false, Flag = "B0bbyAuto1x1Popup", Callback = function(Value) chillisaken.SetAuto1x1Popup(Value) end })
AutoTab:CreateButton({ Name = "Remove Subspaced Effect", Callback = function() chillisaken.RemoveStatusEffect("SurvivorExclusive", "Subspaced") end })
AutoTab:CreateButton({ Name = "Remove Glitched Effect", Callback = function() chillisaken.RemoveStatusEffect("KillerExclusive", "Glitched") end })
AutoTab:CreateButton({ Name = "Remove Blindness Effect", Callback = function() chillisaken.RemoveStatusEffect(nil, "Blindness") end })
AutoTab:CreateButton({ Name = "Remove Slowness Effect", Callback = function() chillisaken.RemoveStatusEffect(nil, "Slowness", "Slateskin") end })
AutoTab:CreateButton({ Name = "Remove Nausea Effect", Callback = function() chillisaken.RemoveStatusEffect(nil, "Nausea") end })
AutoTab:CreateButton({ Name = "Remove Confusion Effect", Callback = function() chillisaken.RemoveStatusEffect(nil, "Confusion") end })

-- Movement & Map Tab
MovementTab:CreateSection("Movement")
MovementTab:CreateToggle({ Name = "Infinite Stamina", CurrentValue = chillisaken.Config.InfiniteStamina, Flag = "InfiniteStamina", Callback = function(Value) chillisaken.SetInfiniteStamina(Value) end })
MovementTab:CreateToggle({ Name = "Speed Boost", CurrentValue = chillisaken.Config.SpeedBoost, Flag = "SpeedBoost", Callback = function(Value) chillisaken.SetSpeedBoost(Value) end })
MovementTab:CreateSlider({ Name = "Speed Value", Range = { 1, 50 }, Increment = 1, Suffix = "", CurrentValue = chillisaken.Config.SpeedValue, Flag = "SpeedValue", Callback = function(Value) chillisaken.Config.SpeedValue = Value end })
MovementTab:CreateToggle({ Name = "Flight", CurrentValue = chillisaken.Config.Flight, Flag = "Flight", Callback = function(Value) chillisaken.SetFlight(Value) end })
MovementTab:CreateSlider({ Name = "Flight Speed", Range = { 1, 80 }, Increment = 1, Suffix = "", CurrentValue = chillisaken.Config.FlightSpeed, Flag = "FlightSpeed", Callback = function(Value) chillisaken.Config.FlightSpeed = Value end })

MovementTab:CreateSection("Map & Killer Tweaks")
MovementTab:CreateToggle({ Name = "Delete Fake Noli", CurrentValue = chillisaken.Config.DeleteFakeNoli, Flag = "DeleteFakeNoli", Callback = function(Value) chillisaken.Config.DeleteFakeNoli = Value chillisaken.ApplyMapTweaks() end })
MovementTab:CreateToggle({ Name = "Disable John Doe Trails", CurrentValue = chillisaken.Config.DisableTrails, Flag = "DisableTrails", Callback = function(Value) chillisaken.Config.DisableTrails = Value chillisaken.ApplyMapTweaks() end })
MovementTab:CreateToggle({ Name = "Disable Footprints / Shadows", CurrentValue = chillisaken.Config.DisableFootprints, Flag = "DisableFootprints", Callback = function(Value) chillisaken.Config.DisableFootprints = Value chillisaken.ApplyMapTweaks() end })
MovementTab:CreateToggle({ Name = "Small Spikes", CurrentValue = chillisaken.Config.SmallSpikes, Flag = "SmallSpikes", Callback = function(Value) chillisaken.Config.SmallSpikes = Value chillisaken.ApplyMapTweaks() end })
MovementTab:CreateToggle({ Name = "Disable Killer Walls", CurrentValue = chillisaken.Config.DisableKillerWalls, Flag = "DisableKillerWalls", Callback = function(Value) chillisaken.Config.DisableKillerWalls = Value chillisaken.ApplyMapTweaks() end })

-- Visuals & ESP Tab
VisualsTab:CreateSection("World Visuals")
VisualsTab:CreateToggle({ Name = "Fullbright", CurrentValue = chillisaken.Config.Fullbright, Flag = "Fullbright", Callback = function(Value) chillisaken.SetFullbright(Value) end })

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

VisualsTab:CreateSection("Extra Map ESPs")
VisualsTab:CreateButton({ Name = "John Doe Spike ESP", Callback = function() chillisaken.EspJohnDoeSpike() end })
VisualsTab:CreateButton({ Name = "Pizza Delivery Minion ESP", Callback = function() chillisaken.EspPizzaMinion() end })

-- Fun Tab
FunTab:CreateSection("Buttons & Flips")
FunTab:CreateButton({ Name = "Fake Punch Button", Callback = function() createDraggableAnimButton("rbxassetid://110895402653848", "rbxassetid://87259391926321") end })
FunTab:CreateButton({ Name = "Fake Block Button", Callback = function() createDraggableAnimButton("rbxassetid://85125497005042", "rbxassetid://72722244508749") end })
FunTab:CreateButton({ Name = "Backflip Button", Callback = function() createFlipGuiButton("rbxassetid://108983136200755", true) end })
FunTab:CreateButton({ Name = "FrontFlip Button", Callback = function() createFlipGuiButton("rbxassetid://106469685305878", false) end })
FunTab:CreateKeybind({ Name = "Frontflip Keybind", CurrentKeybind = "P", HoldToInteract = false, Flag = "B0bbyFrontflipKey", Callback = function() chillisaken.PerformFlip(false) end })
FunTab:CreateKeybind({ Name = "Backflip Keybind", CurrentKeybind = "L", HoldToInteract = false, Flag = "B0bbyBackflipKey", Callback = function() chillisaken.PerformFlip(true) end })
FunTab:CreateButton({ Name = "Slide Button", Callback = function() chillisaken.CreateSlideButton() end })

FunTab:CreateSection("FE Animations")
local activeLoopTrack = nil
local function toggleLoopAnim(animId, looped)
	return function(enabled)
		local char = LocalPlayer and (LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum then return end
		if enabled then
			if not (activeLoopTrack and activeLoopTrack.IsPlaying) then
				local anim = Instance.new("Animation")
				anim.AnimationId = animId
				activeLoopTrack = hum:LoadAnimation(anim)
				activeLoopTrack.Looped = looped
				activeLoopTrack:Play()
			end
		elseif activeLoopTrack and activeLoopTrack.IsPlaying then
			activeLoopTrack:Stop()
		end
	end
end

FunTab:CreateToggle({ Name = "Masterbait", CurrentValue = false, Flag = "B0bbyMasterbait", Callback = toggleLoopAnim("rbxassetid://72042024", true) })
FunTab:CreateToggle({ Name = "Arms-out Spin", CurrentValue = false, Flag = "B0bbyArmsOutSpin", Callback = toggleLoopAnim("rbxassetid://235542946", false) })
FunTab:CreateToggle({ Name = "Spinning Hands", CurrentValue = false, Flag = "B0bbySpinningHands", Callback = toggleLoopAnim("rbxassetid://259438880", true) })
FunTab:CreateToggle({ Name = "Jumping Jacks", CurrentValue = false, Flag = "B0bbyJumpingJacks", Callback = toggleLoopAnim("rbxassetid://429681631", true) })

FunTab:CreateSection("Animation Packs")
FunTab:CreateButton({ Name = "2017 Animation Pack", Callback = function() chillisaken.ApplyAnimationPack("rbxassetid://124622205682529", "rbxassetid://99127941563341", "rbxassetid://99159420513149") end })
FunTab:CreateButton({ Name = "Stalker Animation Pack", Callback = function() chillisaken.ApplyAnimationPack("rbxassetid://135419935358802", "rbxassetid://95469909855529", "rbxassetid://109671225388655") end })
FunTab:CreateButton({ Name = "Chill Animation Pack", Callback = function() chillisaken.ApplyAnimationPack("rbxassetid://132811450080149", "rbxassetid://90163253241107", "rbxassetid://96194626828153") end })
FunTab:CreateButton({ Name = "John Doe Animation Pack", Callback = function() chillisaken.ApplyAnimationPack("rbxassetid://105880087711722", "rbxassetid://81193817424328", "rbxassetid://132653655520682") end })
FunTab:CreateButton({ Name = "C00lkid Animation Pack", Callback = function() chillisaken.ApplyAnimationPack("rbxassetid://18885903667", "rbxassetid://18885906143", "rbxassetid://96571077893813") end })
FunTab:CreateButton({ Name = "Noli Animation Pack", Callback = function() chillisaken.ApplyAnimationPack("rbxassetid://83465205704188", "rbxassetid://116353529220765", "rbxassetid://117451341682452") end })
FunTab:CreateButton({ Name = "Cool Animation Pack", Callback = function() chillisaken.ApplyAnimationPack("rbxassetid://115268929362938", "rbxassetid://123678890237669", "rbxassetid://132086389849889") end })
FunTab:CreateButton({ Name = "Bludude Animation Pack", Callback = function() chillisaken.ApplyAnimationPack("rbxassetid://115268929362938", "rbxassetid://18885906143", "rbxassetid://96571077893813") end })
FunTab:CreateButton({
	Name = "Jeff the Killer Animation Pack",
	Callback = function()
		local char = LocalPlayer and (LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())
		local hum = char and char:WaitForChild("Humanoid")
		if not hum then return end
		local runAnim = Instance.new("Animation")
		runAnim.AnimationId = "rbxassetid://252557606"
		local idleAnim = Instance.new("Animation")
		idleAnim.AnimationId = "rbxassetid://124622205682529"
		local runTr, idleTr
		hum.Running:Connect(function(speed)
			if speed > 0 then
				if idleTr and idleTr.IsPlaying then idleTr:Stop() end
				if not (runTr and runTr.IsPlaying) then
					runTr = hum:LoadAnimation(runAnim)
					runTr.Looped = true
					runTr:Play()
				end
			else
				if runTr and runTr.IsPlaying then runTr:Stop() end
				if not (idleTr and idleTr.IsPlaying) then
					idleTr = hum:LoadAnimation(idleAnim)
					idleTr.Looped = true
					idleTr:Play()
				end
			end
		end)
	end
})

-- Credits Tab
CreditsTab:CreateLabel("hiiamcool0066_17937: a special guy(helped through alot)", 81011198561140, Color3.fromRGB(90, 90, 90), false)
CreditsTab:CreateLabel("Creator: Bob.47", 70727208556993, Color3.fromRGB(90, 90, 90), false)
CreditsTab:CreateLabel("doitenroi_9941: helped me through setting up the discord server", 111385007873003, Color3.fromRGB(90, 90, 90), false)

-- Settings Tab
SettingsTab:CreateButton({
	Name = "Unload the Gui",
	Callback = function()
		Rayfield:Destroy()
		local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
		if pg then
			for _, guiName in ipairs({ "EmoteGui", "BobbyScreengui", "InstantGenGui", "DusekarrAimbotGui", "ScreenGui" }) do
				local g = pg:FindFirstChild(guiName)
				if g then g:Destroy() end
			end
		end
	end
})
SettingsTab:CreateSection("Themes")
SettingsTab:CreateButton({ Name = "Set Default Theme", Callback = function() Window.ModifyTheme("Default") end })
SettingsTab:CreateButton({ Name = "Set AmberGlow Theme", Callback = function() Window.ModifyTheme("AmberGlow") end })
SettingsTab:CreateToggle({
	Name = "Remove 'B0bby' Button",
	CurrentValue = false,
	Flag = "B0bbyRemoveToggleBtn",
	Callback = function(Value)
		local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
		local existing = pg and pg:FindFirstChild("BobbyScreengui")
		if Value then
			if existing then existing:Destroy() end
		else
			chillisaken.CreateFloatingToggleGui()
		end
	end
})

-- Background Loops
task.spawn(function()
	while true do
		pcall(chillisaken.RefreshEsp)
		pcall(chillisaken.ApplyMapTweaks)
		task.wait(1)
	end
end)

return chillisaken
```[cite: 8, 9]
