-- All credits go to chillisaken
-- chillisaken merged with CatLeaks_Catsaken features

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
	name = "chillisaken",
	subtitle = "chill",
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
		chillisakenItemEsp = false,
		chillisakenGroupEsp = false,
		chillisakenAutoDodge = false,
		chillisakenSeeRadius = false,
		chillisakenDodgeMode = "Legit",
		chillisakenDetectionRadius = 50,
		chillisakenDodgeDistance = 25,
		chillisakenDodgeCooldown = 0.3,
		chillisakenAimbot = false,
		chillisakenAimPart = "Head",
		chillisakenAimPrediction = 0.13,
		chillisakenAimFOV = 100,
		chillisakenFlipKey = Enum.KeyCode.Z,
		chillisakenFlipHeight = 10,
		chillisakenFlipDistance = 30,
		chillisakenStaminaGain = 100,
		chillisakenStaminaLoss = 0,
		chillisakenSprintSpeed = 29,
		chillisakenSpeedSpoofer = false,
		chillisakenSpoofSpeed = 16,
		chillisakenForceJump = false,
		chillisakenChatVisibility = false,
		chillisakenStealItems = false,
		chillisakenGenDelay = 1.5,
		chillisakenMustard = false,
		chillisakenKanye = false
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

-- Shared Helpers
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
		return net:FindFirstChild("RemoteEvent") or net:FindFirstChildOfClass("RemoteEvent")
	end
	return nil
end

local function fireAbility(abilityName, useBuffer)
	local remote = getNetworkRemote()
	if not remote then return end
	if useBuffer then
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
	LocalPlayer.CharacterAdded:Connect(bindCharacter)
end

-- Rayfield UI Initialization
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "chillisaken",
	Icon = 0,
	LoadingTitle = "chillisaken",
	LoadingSubtitle = "by chillisaken",
	ShowText = "chillisaken",
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
local MovementTab = Window:CreateTab("Movement & Map", "zap")
local VisualsTab = Window:CreateTab("Visuals & ESP", "eye")
local CreditsTab = Window:CreateTab("Credits", "clipboard")
local SettingsTab = Window:CreateTab("Settings", "settings")

-- Core chillisaken Combat, Automation, Movement, Map & Visuals Logic
function chillisaken.SetAutoBlock(enabled)
	chillisaken.Config.AutoBlock = enabled
end

function chillisaken.SetAutoClone(enabled)
	chillisaken.Config.AutoClone = enabled
	if chillisaken.Connections.AutoClone then
		chillisaken.Connections.AutoClone:Disconnect()
		chillisaken.Connections.AutoClone = nil
	end
	if not enabled then return end
	chillisaken.Connections.AutoClone = game.DescendantAdded:Connect(function(desc)
		if not chillisaken.Config.AutoClone or not desc:IsA("Sound") then return end
		local root = chillisaken.State.Root
		local part = desc.Parent and (desc.Parent:IsA("BasePart") and desc.Parent or desc.Parent:FindFirstAncestorWhichIsA("BasePart"))
		if root and part and (part.Position - root.Position).Magnitude <= chillisaken.Config.CloneDetectionRange then
			fireAbility("Block", true)
		end
	end)
end

function chillisaken.SetAutoPunch(enabled)
	chillisaken.Config.AutoPunch = enabled
end

function chillisaken.SetTwoTime(enabled)
	chillisaken.Config.BackstabEnabled = enabled
end

function chillisaken.SetAutoGenerator(enabled)
	chillisaken.Config.AutoGenerator = enabled
	if chillisaken.Connections.AutoGenerator then
		chillisaken.Connections.AutoGenerator:Disconnect()
		chillisaken.Connections.AutoGenerator = nil
	end
	if not enabled then return end
	chillisaken.Connections.AutoGenerator = RunService.Heartbeat:Connect(function()
		if not chillisaken.Config.AutoGenerator then return end
		local ig = getIngameFolder()
		local mapFolder = ig and ig:FindFirstChild("Map")
		if not mapFolder then return end
		for _, child in ipairs(mapFolder:GetChildren()) do
			if child.Name == "Generator" and child:FindFirstChild("Remotes") and child.Remotes:FindFirstChild("RE") then
				child.Remotes.RE:FireServer()
			end
		end
	end)
end

function chillisaken.SetChanceCoinFlip(enabled)
	chillisaken.Config.ChanceCoinFlip = enabled
end

function chillisaken.SetAutoSlash(enabled)
	chillisaken.Config.AutoSlash = enabled
end

function chillisaken.SetAutoGhostburgerLMS(enabled)
	chillisaken.Config.AutoGhostburgerLMS = enabled
end

function chillisaken.SetHomingTripmine(enabled)
	chillisaken.Config.HomingTripmine = enabled
end

function chillisaken.SetInfiniteStamina(enabled)
	chillisaken.Config.InfiniteStamina = enabled
	local sprintMod
	pcall(function()
		sprintMod = require(ReplicatedStorage.Systems.Character.Game.Sprinting)
	end)
	if sprintMod then
		sprintMod.StaminaLossDisabled = enabled
		if enabled and sprintMod.MaxStamina then
			sprintMod.Stamina = sprintMod.MaxStamina
		end
	end
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
		if not chillisaken.Config.Flight or not head.Parent or not Camera then return end
		local move = hum.MoveDirection * ((chillisaken.Config.FlightSpeed or 1) * dt)
		local camPos = Camera.CFrame.Position
		local headPos = head.CFrame.Position
		local moved = CFrame.new(camPos, Vector3.new(headPos.X, camPos.Y, headPos.Z)):VectorToObjectSpace(move)
		head.CFrame = CFrame.new(headPos) * (Camera.CFrame - camPos) * CFrame.new(moved)
	end)
end

function chillisaken.SetFullbright(enabled)
	chillisaken.Config.Fullbright = enabled
	if enabled then
		Lighting.TimeOfDay = "12:00:00"
		Lighting.ClockTime = 12
		Lighting.Brightness = 2.5
		Lighting.FogStart = 100000
		Lighting.FogEnd = 300000
		Lighting.GlobalShadows = false
	end
end

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

function chillisaken.RefreshEsp()
	clearTaggedEsp("chillisaken_ESP")
	local cfg = chillisaken.Config
	local function markModel(model, color, text)
		local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
		if not model or not root then return end
		local hl = Instance.new("Highlight")
		hl.Name = "chillisaken_ESP"
		hl.FillColor = color
		hl.OutlineColor = color
		hl.FillTransparency = 0.65
		hl.Adornee = model
		hl.Parent = model
		if cfg.EspNames then
			local bb = Instance.new("BillboardGui")
			bb.Name = "chillisaken_ESP"
			bb.Adornee = root
			bb.Size = UDim2.new(0, 140, 0, 24)
			bb.StudsOffset = Vector3.new(0, 3, 0)
			bb.AlwaysOnTop = true
			bb.Parent = root
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, 0, 1, 0)
			lbl.BackgroundTransparency = 1
			lbl.TextColor3 = color
			lbl.Font = Enum.Font.GothamBold
			lbl.TextScaled = true
			lbl.Text = text
			lbl.Parent = bb
		end
	end

	if cfg.EspKiller then
		local kf = getKillersFolder()
		if kf then
			for _, m in ipairs(kf:GetChildren()) do
				if m:IsA("Model") and m ~= chillisaken.State.Character then
					local hum = m:FindFirstChildOfClass("Humanoid")
					local label = m.Name .. (cfg.EspHealth and hum and (" [" .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth) .. "]") or "")
					markModel(m, Color3.fromRGB(255, 60, 60), label)
				end
			end
		end
	end
	if cfg.EspSurvivor then
		local sf = getSurvivorsFolder()
		if sf then
			for _, m in ipairs(sf:GetChildren()) do
				if m:IsA("Model") and m ~= chillisaken.State.Character then
					local hum = m:FindFirstChildOfClass("Humanoid")
					local label = m.Name .. (cfg.EspHealth and hum and (" [" .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth) .. "]") or "")
					markModel(m, Color3.fromRGB(60, 255, 100), label)
				end
			end
		end
	end
end

-- Base Controls
CombatTab:CreateSection("Combat")
CombatTab:CreateToggle({ Name = "Auto Block", CurrentValue = false, Flag = "AutoBlock", Callback = function(v) chillisaken.SetAutoBlock(v) end })
CombatTab:CreateToggle({ Name = "Auto Punch", CurrentValue = false, Flag = "AutoPunch", Callback = function(v) chillisaken.SetAutoPunch(v) end })
CombatTab:CreateToggle({ Name = "Two Time Backstab", CurrentValue = false, Flag = "BackstabEnabled", Callback = function(v) chillisaken.SetTwoTime(v) end })

AutoTab:CreateSection("Automation")
AutoTab:CreateToggle({ Name = "Auto Clone (007n7)", CurrentValue = false, Flag = "AutoClone", Callback = function(v) chillisaken.SetAutoClone(v) end })
AutoTab:CreateToggle({ Name = "Auto Generator", CurrentValue = false, Flag = "AutoGenerator", Callback = function(v) chillisaken.SetAutoGenerator(v) end })
AutoTab:CreateToggle({ Name = "Auto Slash", CurrentValue = false, Flag = "AutoSlash", Callback = function(v) chillisaken.SetAutoSlash(v) end })

MovementTab:CreateSection("Movement & Map")
MovementTab:CreateToggle({ Name = "Infinite Stamina", CurrentValue = false, Flag = "InfiniteStamina", Callback = function(v) chillisaken.SetInfiniteStamina(v) end })
MovementTab:CreateToggle({ Name = "Speed Boost", CurrentValue = false, Flag = "SpeedBoost", Callback = function(v) chillisaken.SetSpeedBoost(v) end })
MovementTab:CreateSlider({ Name = "Speed Value", Range = { 1, 50 }, Increment = 1, Suffix = "", CurrentValue = 1, Flag = "SpeedValue", Callback = function(v) chillisaken.Config.SpeedValue = v end })
MovementTab:CreateToggle({ Name = "Flight", CurrentValue = false, Flag = "Flight", Callback = function(v) chillisaken.SetFlight(v) end })
MovementTab:CreateSlider({ Name = "Flight Speed", Range = { 1, 80 }, Increment = 1, Suffix = "", CurrentValue = 1, Flag = "FlightSpeed", Callback = function(v) chillisaken.Config.FlightSpeed = v end })
MovementTab:CreateToggle({ Name = "Delete Fake Noli", CurrentValue = false, Flag = "DeleteFakeNoli", Callback = function(v) chillisaken.Config.DeleteFakeNoli = v chillisaken.ApplyMapTweaks() end })
MovementTab:CreateToggle({ Name = "Disable Killer Walls", CurrentValue = false, Flag = "DisableKillerWalls", Callback = function(v) chillisaken.Config.DisableKillerWalls = v chillisaken.ApplyMapTweaks() end })

VisualsTab:CreateSection("Visuals & ESP")
VisualsTab:CreateToggle({ Name = "Fullbright", CurrentValue = false, Flag = "Fullbright", Callback = function(v) chillisaken.SetFullbright(v) end })
VisualsTab:CreateToggle({ Name = "ESP Killer", CurrentValue = false, Flag = "EspKiller", Callback = function(v) chillisaken.Config.EspKiller = v chillisaken.RefreshEsp() end })
VisualsTab:CreateToggle({ Name = "ESP Survivor", CurrentValue = false, Flag = "EspSurvivor", Callback = function(v) chillisaken.Config.EspSurvivor = v chillisaken.RefreshEsp() end })

-- ============================================================================
-- Merged Features from CatLeaks_Catsaken (All credits go to chillisaken)
-- ============================================================================

local _chillisakenDrawing = Drawing

local chillisakenItemEspData = {
	Items = {
		Medkit = { Enabled = true, Color = Color3.fromRGB(0, 255, 0), Transparency = 0.5, Tracers = true, ShowText = true },
		BloxyCola = { Enabled = true, Color = Color3.fromRGB(0, 150, 255), Transparency = 0.5, Tracers = true, ShowText = true }
	},
	ShowTracers = true,
	ShowTexts = true
}

local csItemHighlights = {}
local csItemTracers = {}
local csItemLabels = {}

local function csDarkenColor(color, factor)
	factor = factor or 0.7
	return Color3.new(math.clamp(color.R * factor, 0, 1), math.clamp(color.G * factor, 0, 1), math.clamp(color.B * factor, 0, 1))
end

local function csGetItemPart(item)
	if not item then return nil end
	local handle = item:FindFirstChild("Handle")
	if handle and handle:IsA("BasePart") then return handle end
	for _, child in ipairs(item:GetChildren()) do
		if child:IsA("BasePart") then return child end
	end
	return nil
end

local function csClearItemEsp(key)
	if csItemHighlights[key] then csItemHighlights[key]:Destroy() csItemHighlights[key] = nil end
	if csItemTracers[key] then csItemTracers[key]:Remove() csItemTracers[key] = nil end
	if csItemLabels[key] then csItemLabels[key]:Remove() csItemLabels[key] = nil end
end

local function csCreateHighlight(adornee, color, transparency, alwaysOnTop)
	local hl = Instance.new("Highlight")
	hl.Name = "chillisakenESPHighlight"
	hl.Adornee = adornee
	hl.FillColor = color
	hl.FillTransparency = 0.7
	hl.OutlineColor = csDarkenColor(color)
	hl.OutlineTransparency = math.clamp(transparency, 0, 1)
	if alwaysOnTop then
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	end
	hl.Parent = adornee
	return hl
end

local function csNewLine(thickness, color)
	local line = _chillisakenDrawing.new("Line")
	line.Thickness = thickness or 1.5
	line.Transparency = 1
	line.Color = color or Color3.new(1, 1, 1)
	line.Visible = false
	return line
end

local function csNewText(size, color)
	local txt = _chillisakenDrawing.new("Text")
	txt.Center = true
	txt.Outline = true
	txt.Font = 2
	txt.Size = size or 16
	txt.Color = color or Color3.new(1, 1, 1)
	txt.Visible = false
	return txt
end

function chillisaken.SetchillisakenItemEsp(enabled)
	chillisaken.Config.chillisakenItemEsp = enabled
	if not enabled then
		for k in pairs(chillisakenItemEspData.Items) do
			csClearItemEsp(k)
		end
	end
end

RunService.RenderStepped:Connect(function()
	if not chillisaken.Config.chillisakenItemEsp or not Camera then return end
	local ig = getIngameFolder()
	if not ig then return end
	for k, v in pairs(chillisakenItemEspData.Items) do
		local item = ig:FindFirstChild(k)
		if not item or not item:IsA("Tool") or not v.Enabled then
			csClearItemEsp(k)
		else
			local part = csGetItemPart(item)
			if not part then
				csClearItemEsp(k)
			else
				if csItemHighlights[k] then
					csItemHighlights[k].FillColor = v.Color
					csItemHighlights[k].OutlineColor = csDarkenColor(v.Color)
					csItemHighlights[k].OutlineTransparency = v.Transparency
					csItemHighlights[k].Enabled = true
				else
					csItemHighlights[k] = csCreateHighlight(part, v.Color, v.Transparency, true)
				end

				if chillisakenItemEspData.ShowTracers and v.Tracers then
					local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
					if onScreen then
						if not csItemTracers[k] then csItemTracers[k] = csNewLine(1.5, v.Color) end
						csItemTracers[k].From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
						csItemTracers[k].To = Vector2.new(pos.X, pos.Y)
						csItemTracers[k].Color = v.Color
						csItemTracers[k].Visible = true
					elseif csItemTracers[k] then
						csItemTracers[k].Visible = false
					end
				elseif csItemTracers[k] then
					csItemTracers[k].Visible = false
				end

				if chillisakenItemEspData.ShowTexts and v.ShowText then
					local pos, onScreen = Camera:WorldToViewportPoint(part.Position + Vector3.new(0, 1.5, 0))
					if onScreen then
						if not csItemLabels[k] then csItemLabels[k] = csNewText(16, v.Color) end
						csItemLabels[k].Position = Vector2.new(pos.X, pos.Y)
						csItemLabels[k].Text = k
						csItemLabels[k].Color = v.Color
						csItemLabels[k].Visible = true
					elseif csItemLabels[k] then
						csItemLabels[k].Visible = false
					end
				elseif csItemLabels[k] then
					csItemLabels[k].Visible = false
				end
			end
		end
	end
end)

local chillisakenGroupEspData = {
	Groups = {
		Killers = { Enabled = true, Color = Color3.fromRGB(255, 0, 0), Transparency = 0.5, Tracers = false, ShowName = true, ShowHealth = true },
		Survivors = { Enabled = true, Color = Color3.fromRGB(0, 255, 0), Transparency = 0.5, Tracers = false, ShowName = true, ShowHealth = true },
		Generators = { Enabled = true, Color = Color3.fromRGB(255, 255, 0), Transparency = 0.5, Tracers = false }
	}
}

local csGroupHighlights = {}
local csGenProgressTexts = {}
local csGroupTracers = {}
local csGroupNames = {}
local csGroupHealths = {}

local function csClearGroupEsp(target)
	if csGroupHighlights[target] then csGroupHighlights[target]:Destroy() csGroupHighlights[target] = nil end
	if csGenProgressTexts[target] then csGenProgressTexts[target]:Remove() csGenProgressTexts[target] = nil end
	if csGroupTracers[target] then csGroupTracers[target]:Remove() csGroupTracers[target] = nil end
	if csGroupNames[target] then csGroupNames[target]:Remove() csGroupNames[target] = nil end
	if csGroupHealths[target] then csGroupHealths[target]:Remove() csGroupHealths[target] = nil end
end

function chillisaken.SetchillisakenGroupEsp(enabled)
	chillisaken.Config.chillisakenGroupEsp = enabled
	if not enabled then
		for target in pairs(csGroupHighlights) do
			csClearGroupEsp(target)
		end
		for _, txt in pairs(csGenProgressTexts) do txt:Remove() end
		csGenProgressTexts = {}
	end
end

local function csDrawName(model, cam, color)
	local hrp = model:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local pos, onScreen = cam:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
	if onScreen then
		if not csGroupNames[model] then csGroupNames[model] = csNewText(20, color) end
		csGroupNames[model].Text = model.Name
		csGroupNames[model].Position = Vector2.new(pos.X, pos.Y)
		csGroupNames[model].Color = color
		csGroupNames[model].Visible = true
		csGroupNames[model].Transparency = 1
	elseif csGroupNames[model] then
		csGroupNames[model].Visible = false
	end
end

local function csDrawHealth(model, cam, color)
	local hrp = model:FindFirstChild("HumanoidRootPart")
	local hum = model:FindFirstChild("Humanoid")
	if not hrp or not hum then return end
	local pos, onScreen = cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
	if onScreen then
		if not csGroupHealths[model] then csGroupHealths[model] = csNewText(18, color) end
		csGroupHealths[model].Text = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
		csGroupHealths[model].Position = Vector2.new(pos.X, pos.Y)
		csGroupHealths[model].Color = color
		csGroupHealths[model].Visible = true
		csGroupHealths[model].Transparency = 1
	elseif csGroupHealths[model] then
		csGroupHealths[model].Visible = false
	end
end

local function csDrawTracer(target, cam, color)
	local worldPos
	if target.Name == "Generator" then
		local part = target.PrimaryPart or target:FindFirstChild("Main") or target:FindFirstChildWhichIsA("BasePart")
		if not part then return end
		worldPos = part.Position
	else
		local hrp = target:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		worldPos = hrp.Position
	end
	local pos, onScreen = cam:WorldToViewportPoint(worldPos)
	if onScreen then
		if not csGroupTracers[target] then csGroupTracers[target] = csNewLine(1, color) end
		csGroupTracers[target].From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
		csGroupTracers[target].To = Vector2.new(pos.X, pos.Y)
		csGroupTracers[target].Color = color
		csGroupTracers[target].Visible = true
	elseif csGroupTracers[target] then
		csGroupTracers[target].Visible = false
	end
end

RunService.RenderStepped:Connect(function()
	if not chillisaken.Config.chillisakenGroupEsp or not Camera then return end
	for target in pairs(csGroupHighlights) do
		if not target:IsDescendantOf(game) then
			csClearGroupEsp(target)
		end
	end

	local pf = getPlayersFolder()
	for _, groupName in ipairs({ "Killers", "Survivors" }) do
		local grp = chillisakenGroupEspData.Groups[groupName]
		local folder = pf and pf:FindFirstChild(groupName)
		if not grp.Enabled then
			if folder then
				for _, child in ipairs(folder:GetChildren()) do
					if csGroupHighlights[child] then csClearGroupEsp(child) end
				end
			end
		elseif folder then
			for _, child in ipairs(folder:GetChildren()) do
				if child:IsA("Model") and child:FindFirstChild("Humanoid") and child:FindFirstChild("HumanoidRootPart") then
					if csGroupHighlights[child] then
						csGroupHighlights[child].FillColor = grp.Color
						csGroupHighlights[child].OutlineColor = csDarkenColor(grp.Color)
						csGroupHighlights[child].OutlineTransparency = grp.Transparency
						csGroupHighlights[child].Enabled = grp.Enabled
					else
						csGroupHighlights[child] = csCreateHighlight(child, grp.Color, grp.Transparency, false)
					end
					if grp.ShowName then csDrawName(child, Camera, grp.Color) elseif csGroupNames[child] then csGroupNames[child]:Remove() csGroupNames[child] = nil end
					if grp.ShowHealth then csDrawHealth(child, Camera, grp.Color) elseif csGroupHealths[child] then csGroupHealths[child]:Remove() csGroupHealths[child] = nil end
					if grp.Tracers then csDrawTracer(child, Camera, grp.Color) elseif csGroupTracers[child] then csGroupTracers[child]:Remove() csGroupTracers[child] = nil end
				end
			end
		end
	end

	local genGrp = chillisakenGroupEspData.Groups.Generators
	if not genGrp.Enabled then
		for target in pairs(csGroupHighlights) do
			if target.Name == "Generator" then csClearGroupEsp(target) end
		end
		for _, txt in pairs(csGenProgressTexts) do txt:Remove() end
		csGenProgressTexts = {}
	else
		local ig = getIngameFolder()
		local mapFolder = ig and ig:FindFirstChild("Map")
		if mapFolder then
			for _, child in ipairs(mapFolder:GetChildren()) do
				if child:IsA("Model") and child.Name == "Generator" then
					local progress = child:FindFirstChild("Progress")
					local mainPart = child.PrimaryPart or child:FindFirstChild("Main") or child:FindFirstChildWhichIsA("BasePart")
					if not progress or not mainPart or not (progress.Value < 100) then
						if csGroupHighlights[child] then csClearGroupEsp(child) end
						if csGenProgressTexts[child] then csGenProgressTexts[child]:Remove() csGenProgressTexts[child] = nil end
					else
						if csGroupHighlights[child] then
							csGroupHighlights[child].FillColor = genGrp.Color
							csGroupHighlights[child].OutlineColor = csDarkenColor(genGrp.Color)
							csGroupHighlights[child].OutlineTransparency = genGrp.Transparency
							csGroupHighlights[child].Enabled = genGrp.Enabled
						else
							csGroupHighlights[child] = csCreateHighlight(child, genGrp.Color, genGrp.Transparency, false)
						end
						local pos, onScreen = Camera:WorldToViewportPoint(mainPart.Position)
						if onScreen then
							if not csGenProgressTexts[child] then csGenProgressTexts[child] = csNewText(20, genGrp.Color) end
							csGenProgressTexts[child].Text = math.floor(progress.Value) .. "%"
							csGenProgressTexts[child].Position = Vector2.new(pos.X, pos.Y)
							csGenProgressTexts[child].Color = genGrp.Color
							csGenProgressTexts[child].Visible = true
							csGenProgressTexts[child].Transparency = 1
						elseif csGenProgressTexts[child] then
							csGenProgressTexts[child].Visible = false
						end
						if genGrp.Tracers then csDrawTracer(child, Camera, genGrp.Color) elseif csGroupTracers[child] then csGroupTracers[child]:Remove() csGroupTracers[child] = nil end
					end
				end
			end
		end
	end
end)

local function csCreateRadiusPad(color)
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Cylinder
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Material = Enum.Material.Neon
	part.Size = Vector3.new(1, 0.2, 1)
	part.Color = color
	part.Rotation = Vector3.new(90, 0, 0)
	part.Name = "chillisakenAutoDodgePad"
	part.Parent = Workspace
	return part
end

local csDetectPad = csCreateRadiusPad(Color3.fromRGB(255, 0, 0))
local csDodgePad = csCreateRadiusPad(Color3.fromRGB(0, 255, 0))

local function csUpdateDodgePads()
	local hrp = LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local pos = hrp.Position - Vector3.new(0, hrp.Size.Y / 2 + 0.05, 0)
	csDetectPad.Size = Vector3.new(chillisaken.Config.chillisakenDetectionRadius * 2, 0.2, chillisaken.Config.chillisakenDetectionRadius * 2)
	csDodgePad.Size = Vector3.new(chillisaken.Config.chillisakenDodgeDistance * 2, 0.2, chillisaken.Config.chillisakenDodgeDistance * 2)
	csDetectPad.CFrame = CFrame.new(pos)
	csDodgePad.CFrame = CFrame.new(pos)
end

local function csFindDodgeSpot(hrp)
	local dist = chillisaken.Config.chillisakenDodgeDistance
	for _, dir in ipairs({ Vector3.new(dist, 0, 0), Vector3.new(-dist, 0, 0) }) do
		local ray = Ray.new(hrp.Position, dir.Unit * dist)
		if not Workspace:FindPartOnRay(ray, LocalPlayer and LocalPlayer.Character) then
			return hrp.Position + dir
		end
	end
	return nil
end

local csLastDodge = 0
RunService.Heartbeat:Connect(function()
	if not chillisaken.Config.chillisakenAutoDodge then
		csDetectPad.Transparency = 1
		csDodgePad.Transparency = 1
		return
	end
	if chillisaken.Config.chillisakenSeeRadius then csUpdateDodgePads() end
	local now = tick()
	if now - csLastDodge < chillisaken.Config.chillisakenDodgeCooldown then return end
	local char = LocalPlayer and LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hitboxes = Workspace:FindFirstChild("Hitboxes")
	if not hrp or not hum or not hitboxes then return end

	local myName = LocalPlayer.Name:lower()
	local found = false
	for _, desc in ipairs(hitboxes:GetDescendants()) do
		if desc:IsA("BasePart") and not desc.Name:lower():find(myName) and (hrp.Position - desc.Position).Magnitude <= chillisaken.Config.chillisakenDetectionRadius then
			found = true
			local spot = csFindDodgeSpot(hrp)
			if spot then
				if chillisaken.Config.chillisakenDodgeMode == "Legit" then
					hum:MoveTo(spot)
				else
					hrp.CFrame = CFrame.new(spot)
				end
				csLastDodge = now
				break
			end
		end
	end
	if not found then hum:MoveTo(hrp.Position) end
end)

local csFovCircle = _chillisakenDrawing.new("Circle")
csFovCircle.Radius = chillisaken.Config.chillisakenAimFOV
csFovCircle.Color = Color3.fromRGB(255, 255, 255)
csFovCircle.Thickness = 1
csFovCircle.Filled = false
csFovCircle.Visible = false

RunService.RenderStepped:Connect(function()
	if not Camera then return end
	csFovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	csFovCircle.Radius = chillisaken.Config.chillisakenAimFOV
	csFovCircle.Visible = chillisaken.Config.chillisakenAimbot
end)

local function csGetEnemyFolder()
	local char = LocalPlayer and LocalPlayer.Character
	if not char then return nil end
	local pf = getPlayersFolder()
	local killers = pf and pf:FindFirstChild("Killers")
	local survivors = pf and pf:FindFirstChild("Survivors")
	if killers and table.find(killers:GetChildren(), char) then return survivors end
	if survivors and table.find(survivors:GetChildren(), char) then return killers end
	return nil
end

local function csGetBestAimTarget()
	local folder = csGetEnemyFolder()
	if not folder or not Camera then return nil end
	local bestPart, bestDist = nil, math.huge
	local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Model") and child:FindFirstChild(chillisaken.Config.chillisakenAimPart) then
			local part = child[chillisaken.Config.chillisakenAimPart]
			local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
			if onScreen then
				local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
				if dist < bestDist and dist <= chillisaken.Config.chillisakenAimFOV then
					bestPart = part
					bestDist = dist
				end
			end
		end
	end
	return bestPart
end

RunService.RenderStepped:Connect(function()
	if not chillisaken.Config.chillisakenAimbot or not Camera then return end
	local target = csGetBestAimTarget()
	if target and target:IsA("BasePart") then
		local aimPos = target.Position
		local hrp = target.Parent and target.Parent:FindFirstChild("HumanoidRootPart")
		if hrp and hrp.Velocity then
			aimPos = aimPos + hrp.Velocity * chillisaken.Config.chillisakenAimPrediction
		end
		Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimPos)
	end
end)

local csFlipping = false
local csFlipSounds = { 9111926008, 14671871879, 9111926008 }

local function csSetCollisions(char, noCollide)
	if not char then return end
	for _, desc in ipairs(char:GetDescendants()) do
		if desc:IsA("BasePart") then desc.CanCollide = not noCollide end
	end
end

function chillisaken.chillisakenFrontflip()
	local char = LocalPlayer and LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if csFlipping or not hrp then return end
	csFlipping = true
	csSetCollisions(char, true)

	local snd = Instance.new("Sound", hrp)
	snd.SoundId = "rbxassetid://" .. csFlipSounds[math.random(1, #csFlipSounds)]
	snd.Volume = 1
	snd:Play()
	game:GetService("Debris"):AddItem(snd, 3)

	local startCf = hrp.CFrame
	local lookDir = startCf.LookVector
	local t0 = tick()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local alpha = math.clamp((tick() - t0) / 0.5, 0, 1)
		local eased = math.sin(alpha * math.pi * 0.5)
		local moveVec = lookDir * (chillisaken.Config.chillisakenFlipDistance * eased)
		local liftVec = Vector3.new(0, math.sin(eased * math.pi) * chillisaken.Config.chillisakenFlipHeight, 0)
		local rot = CFrame.Angles(-math.rad(360) * eased, 0, 0)
		if hrp and hrp.Parent then
			hrp.CFrame = CFrame.new(startCf.Position + moveVec + liftVec) * rot
		end
		if alpha >= 1 then
			conn:Disconnect()
			csSetCollisions(char, false)
			csFlipping = false
		end
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == chillisaken.Config.chillisakenFlipKey then
		chillisaken.chillisakenFrontflip()
	end
end)

function chillisaken.SetchillisakenStamina(enabled)
	local sprinting = ReplicatedStorage:FindFirstChild("Systems")
		and ReplicatedStorage.Systems:FindFirstChild("Character")
		and ReplicatedStorage.Systems.Character:FindFirstChild("Game")
		and ReplicatedStorage.Systems.Character.Game:FindFirstChild("Sprinting")
	if not sprinting then return end
	local ok, lib = pcall(require, sprinting)
	if not ok or not lib then return end
	if enabled then
		lib.StaminaLossDisabled = false
		lib.MinStamina = 0
		lib.StaminaGain = chillisaken.Config.chillisakenStaminaGain
		lib.StaminaLoss = chillisaken.Config.chillisakenStaminaLoss
		lib.SprintSpeed = chillisaken.Config.chillisakenSprintSpeed
	else
		lib.StaminaLossDisabled = true
		lib.MinStamina = 0
		lib.StaminaGain = 15
		lib.StaminaLoss = 5
		lib.SprintSpeed = 22
	end
end

RunService.Heartbeat:Connect(function(dt)
	if chillisaken.Config.chillisakenSpeedSpoofer then
		local hum = chillisaken.State.Humanoid
		local root = chillisaken.State.Root
		if hum and root and hum.MoveDirection.Magnitude > 0 then
			root.CFrame = root.CFrame + hum.MoveDirection.Unit * chillisaken.Config.chillisakenSpoofSpeed * dt
		end
	end
end)

local csSavedJumpPower = nil
function chillisaken.SetchillisakenForceJump(enabled)
	chillisaken.Config.chillisakenForceJump = enabled
	local hum = chillisaken.State.Humanoid or (LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"))
	if hum then
		if enabled then
			if not csSavedJumpPower then csSavedJumpPower = hum.JumpPower end
			hum.JumpPower = 50
		elseif csSavedJumpPower then
			hum.JumpPower = csSavedJumpPower
		end
	end
end

function chillisaken.SetchillisakenChatVisibility(enabled)
	chillisaken.Config.chillisakenChatVisibility = enabled
	task.spawn(function()
		while chillisaken.Config.chillisakenChatVisibility do
			local chatWin = TextChatService:FindFirstChild("ChatWindowConfiguration")
			if chatWin then chatWin.Enabled = true end
			task.wait(1)
		end
	end)
end

task.spawn(function()
	while true do
		if chillisaken.Config.chillisakenStealItems and typeof(fireproximityprompt) == "function" then
			local root = chillisaken.State.Root or (LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))
			if root then
				for _, desc in ipairs(Workspace:GetDescendants()) do
					if desc:IsA("ProximityPrompt") and (desc.ActionText == "Medkit" or desc.ActionText == "Bloxy Cola") then
						local part = desc.Parent and (desc.Parent:IsA("BasePart") and desc.Parent or desc.Parent:FindFirstChildWhichIsA("BasePart"))
						if part and (part.Position - root.Position).Magnitude <= 14 then
							fireproximityprompt(desc)
						end
					end
				end
			end
		end
		task.wait(0.2)
	end
end)

local csLastGenTick = 0
RunService.Heartbeat:Connect(function()
	if not chillisaken.Config.AutoGenerator then return end
	local now = tick()
	if now - csLastGenTick >= chillisaken.Config.chillisakenGenDelay then
		csLastGenTick = now
		local ig = getIngameFolder()
		local mapFolder = ig and ig:FindFirstChild("Map")
		if mapFolder then
			for _, child in ipairs(mapFolder:GetChildren()) do
				if child.Name == "Generator" and child:FindFirstChild("Remotes") and child.Remotes:FindFirstChild("RE") then
					child.Remotes.RE:FireServer()
				end
			end
		end
	end
end)

local function csBuildBouncer(guiName, imageId, soundId)
	if not LocalPlayer then return nil end
	local pg = LocalPlayer:WaitForChild("PlayerGui")
	local gui = pg:FindFirstChild(guiName)
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = guiName
		gui.ResetOnSpawn = false
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.Enabled = false
		gui.Parent = pg

		local img = Instance.new("ImageLabel")
		img.Name = "BouncerImage"
		img.Size = UDim2.new(0, 150, 0, 100)
		img.Position = UDim2.new(0, 100, 0, 100)
		img.BackgroundTransparency = 1
		img.Image = imageId
		img.ZIndex = 9999
		img.Parent = gui

		local snd = Instance.new("Sound")
		snd.Name = "BouncerSound"
		snd.SoundId = soundId
		snd.Volume = 3
		snd.PlaybackSpeed = 1
		snd.Parent = gui
	end
	return {
		gui = gui,
		img = gui:FindFirstChild("BouncerImage"),
		snd = gui:FindFirstChild("BouncerSound"),
		pos = Vector2.new(100, 100),
		vel = Vector2.new(300, 300),
		lastTick = tick()
	}
end

local csMustard = csBuildBouncer("chillisakenMustardGui", "rbxassetid://121212267160037", "rbxassetid://138003512682693")
local csKanye = csBuildBouncer("chillisakenKanyeGui", "rbxassetid://7371693428", "rbxassetid://6357107883")

local function csStepBouncer(state, active)
	if not active or not state or not state.img or not Camera then return end
	local now = tick()
	local dt = now - state.lastTick
	state.lastTick = now
	local vp = Camera.ViewportSize
	local sz = Vector2.new(state.img.AbsoluteSize.X, state.img.AbsoluteSize.Y)
	if sz.X == 0 or sz.Y == 0 then return end
	state.pos = state.pos + state.vel * dt
	local hit = false
	if state.pos.X < 0 then state.pos = Vector2.new(0, state.pos.Y) state.vel = Vector2.new(-state.vel.X, state.vel.Y) hit = true end
	if state.pos.X + sz.X > vp.X then state.pos = Vector2.new(vp.X - sz.X, state.pos.Y) state.vel = Vector2.new(-state.vel.X, state.vel.Y) hit = true end
	if state.pos.Y < 0 then state.pos = Vector2.new(state.pos.X, 0) state.vel = Vector2.new(state.vel.X, -state.vel.Y) hit = true end
	if state.pos.Y + sz.Y > vp.Y then state.pos = Vector2.new(state.pos.X, vp.Y - sz.Y) state.vel = Vector2.new(state.vel.X, -state.vel.Y) hit = true end
	if hit and state.snd then
		state.snd.PlaybackSpeed = math.random(80, 140) / 100
		state.snd:Play()
	end
	state.img.Position = UDim2.new(0, math.floor(state.pos.X), 0, math.floor(state.pos.Y))
end

RunService.RenderStepped:Connect(function()
	csStepBouncer(csMustard, chillisaken.Config.chillisakenMustard)
	csStepBouncer(csKanye, chillisaken.Config.chillisakenKanye)
end)

-- Merged UI Controls
VisualsTab:CreateSection("chillisaken ESP & Overlays")
VisualsTab:CreateToggle({ Name = "chillisaken Item ESP (Medkit/Cola)", CurrentValue = false, Flag = "chillisakenItemEsp", Callback = function(v) chillisaken.SetchillisakenItemEsp(v) end })
VisualsTab:CreateToggle({ Name = "chillisaken Group ESP (Killers/Survivors/Gens)", CurrentValue = false, Flag = "chillisakenGroupEsp", Callback = function(v) chillisaken.SetchillisakenGroupEsp(v) end })
for groupName, grp in pairs(chillisakenGroupEspData.Groups) do
	VisualsTab:CreateToggle({ Name = "chillisaken Tracers (" .. groupName .. ")", CurrentValue = grp.Tracers, Flag = "chillisakenTracers_" .. groupName, Callback = function(v) chillisakenGroupEspData.Groups[groupName].Tracers = v end })
	VisualsTab:CreateColorPicker({ Name = "chillisaken Color (" .. groupName .. ")", Color = grp.Color, Flag = "chillisakenColor_" .. groupName, Callback = function(c) chillisakenGroupEspData.Groups[groupName].Color = c end })
end
VisualsTab:CreateToggle({
	Name = "chillisaken Mustard Bouncer",
	CurrentValue = false,
	Flag = "chillisakenMustard",
	Callback = function(v)
		chillisaken.Config.chillisakenMustard = v
		if csMustard and csMustard.gui then
			csMustard.gui.Enabled = v
			if v then csMustard.pos = Vector2.new(100, 100) csMustard.vel = Vector2.new(300, 300) csMustard.lastTick = tick()
			elseif csMustard.snd then csMustard.snd:Stop() end
		end
	end
})
VisualsTab:CreateToggle({
	Name = "chillisaken Kanye Bouncer",
	CurrentValue = false,
	Flag = "chillisakenKanye",
	Callback = function(v)
		chillisaken.Config.chillisakenKanye = v
		if csKanye and csKanye.gui then
			csKanye.gui.Enabled = v
			if v then csKanye.pos = Vector2.new(100, 100) csKanye.vel = Vector2.new(300, 300) csKanye.lastTick = tick()
			elseif csKanye.snd then csKanye.snd:Stop() end
		end
	end
})

CombatTab:CreateSection("chillisaken Auto Dodge & Aimbot")
CombatTab:CreateToggle({
	Name = "chillisaken Auto Dodge",
	CurrentValue = false,
	Flag = "chillisakenAutoDodge",
	Callback = function(v)
		chillisaken.Config.chillisakenAutoDodge = v
		if v and chillisaken.Config.chillisakenSeeRadius then csDetectPad.Transparency = 0.5 csDodgePad.Transparency = 0.5
		else csDetectPad.Transparency = 1 csDodgePad.Transparency = 1 end
	end
})
CombatTab:CreateToggle({
	Name = "chillisaken See Dodge Radius",
	CurrentValue = false,
	Flag = "chillisakenSeeRadius",
	Callback = function(v)
		chillisaken.Config.chillisakenSeeRadius = v
		if chillisaken.Config.chillisakenAutoDodge and v then csDetectPad.Transparency = 0.5 csDodgePad.Transparency = 0.5
		else csDetectPad.Transparency = 1 csDodgePad.Transparency = 1 end
	end
})
CombatTab:CreateDropdown({ Name = "chillisaken Dodge Mode", Options = { "Legit", "Blatant" }, CurrentOption = { chillisaken.Config.chillisakenDodgeMode }, MultipleOptions = false, Flag = "chillisakenDodgeMode", Callback = function(opts) chillisaken.Config.chillisakenDodgeMode = opts[1] or "Legit" end })
CombatTab:CreateSlider({ Name = "chillisaken Detection Radius", Range = { 10, 200 }, Increment = 1, Suffix = " studs", CurrentValue = 50, Flag = "chillisakenDetectionRadius", Callback = function(v) chillisaken.Config.chillisakenDetectionRadius = v end })
CombatTab:CreateSlider({ Name = "chillisaken Dodge Distance", Range = { 5, 100 }, Increment = 1, Suffix = " studs", CurrentValue = 25, Flag = "chillisakenDodgeDistance", Callback = function(v) chillisaken.Config.chillisakenDodgeDistance = v end })
CombatTab:CreateSlider({ Name = "chillisaken Dodge Cooldown", Range = { 0.05, 1 }, Increment = 0.01, Suffix = " s", CurrentValue = 0.3, Flag = "chillisakenDodgeCooldown", Callback = function(v) chillisaken.Config.chillisakenDodgeCooldown = v end })
CombatTab:CreateToggle({ Name = "chillisaken Opposing Aimbot", CurrentValue = false, Flag = "chillisakenAimbot", Callback = function(v) chillisaken.Config.chillisakenAimbot = v end })
CombatTab:CreateDropdown({ Name = "chillisaken Aim Part", Options = { "Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso" }, CurrentOption = { chillisaken.Config.chillisakenAimPart }, MultipleOptions = false, Flag = "chillisakenAimPart", Callback = function(opts) chillisaken.Config.chillisakenAimPart = opts[1] or "Head" end })
CombatTab:CreateSlider({ Name = "chillisaken Aim Prediction", Range = { 0, 1 }, Increment = 0.01, Suffix = "s", CurrentValue = 0.13, Flag = "chillisakenAimPrediction", Callback = function(v) chillisaken.Config.chillisakenAimPrediction = v end })
CombatTab:CreateSlider({ Name = "chillisaken Aim FOV", Range = { 10, 500 }, Increment = 5, Suffix = "px", CurrentValue = 100, Flag = "chillisakenAimFOV", Callback = function(v) chillisaken.Config.chillisakenAimFOV = v end })

MovementTab:CreateSection("chillisaken Movement & Flip")
MovementTab:CreateInput({ Name = "chillisaken Frontflip Key", PlaceholderText = "Type a key (e.g. Z)", RemoveTextAfterFocusLost = false, Callback = function(txt)
	local upper = tostring(txt):upper()
	local ok, key = pcall(function() return Enum.KeyCode[upper] end)
	if ok and key then
		chillisaken.Config.chillisakenFlipKey = key
		Rayfield:Notify({ Title = "chillisaken", Content = "Frontflip key bound to: " .. upper, Duration = 2 })
	end
end })
MovementTab:CreateInput({ Name = "chillisaken Flip Height", PlaceholderText = "10", RemoveTextAfterFocusLost = false, Callback = function(txt) local n = tonumber(txt) if n then chillisaken.Config.chillisakenFlipHeight = n end end })
MovementTab:CreateInput({ Name = "chillisaken Flip Distance", PlaceholderText = "30", RemoveTextAfterFocusLost = false, Callback = function(txt) local n = tonumber(txt) if n then chillisaken.Config.chillisakenFlipDistance = n end end })
MovementTab:CreateSlider({ Name = "chillisaken Stamina Gain", Range = { 1, 100 }, Increment = 1, Suffix = "", CurrentValue = 100, Flag = "chillisakenStaminaGain", Callback = function(v) chillisaken.Config.chillisakenStaminaGain = v end })
MovementTab:CreateSlider({ Name = "chillisaken Stamina Loss", Range = { -100, 100 }, Increment = 1, Suffix = "", CurrentValue = 0, Flag = "chillisakenStaminaLoss", Callback = function(v) chillisaken.Config.chillisakenStaminaLoss = v end })
MovementTab:CreateSlider({ Name = "chillisaken Sprint Speed", Range = { 10, 30 }, Increment = 1, Suffix = " studs/s", CurrentValue = 29, Flag = "chillisakenSprintSpeed", Callback = function(v) chillisaken.Config.chillisakenSprintSpeed = v end })
MovementTab:CreateToggle({ Name = "chillisaken Custom Stamina Tunings", CurrentValue = false, Flag = "chillisakenCustomStamina", Callback = function(v) chillisaken.SetchillisakenStamina(v) end })
MovementTab:CreateToggle({ Name = "chillisaken Speed Spoofer", CurrentValue = false, Flag = "chillisakenSpeedSpoofer", Callback = function(v) chillisaken.Config.chillisakenSpeedSpoofer = v end })
MovementTab:CreateSlider({ Name = "chillisaken Spoof Speed", Range = { 0, 100 }, Increment = 1, Suffix = "studs/s", CurrentValue = 16, Flag = "chillisakenSpoofSpeed", Callback = function(v) chillisaken.Config.chillisakenSpoofSpeed = v end })
MovementTab:CreateToggle({ Name = "chillisaken Force Jump", CurrentValue = false, Flag = "chillisakenForceJump", Callback = function(v) chillisaken.SetchillisakenForceJump(v) end })

AutoTab:CreateSection("chillisaken Automation")
AutoTab:CreateSlider({ Name = "chillisaken Generator Delay", Range = { 1.5, 10 }, Increment = 0.1, Suffix = "s", CurrentValue = 1.5, Flag = "chillisakenGenDelay", Callback = function(v) chillisaken.Config.chillisakenGenDelay = math.max(1.5, v) end })
AutoTab:CreateToggle({ Name = "chillisaken Steal Medkit/BloxyCola", CurrentValue = false, Flag = "chillisakenStealItems", Callback = function(v) chillisaken.Config.chillisakenStealItems = v end })
AutoTab:CreateToggle({ Name = "chillisaken Force Chat Window", CurrentValue = false, Flag = "chillisakenChatVisibility", Callback = function(v) chillisaken.SetchillisakenChatVisibility(v) end })

-- Credits & Settings
CreditsTab:CreateLabel("All credits go to chillisaken", 0, Color3.fromRGB(255, 255, 255), false)

SettingsTab:CreateButton({
	Name = "Unload the Gui",
	Callback = function()
		Rayfield:Destroy()
		local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
		if pg then
			for _, gName in ipairs({ "chillisakenMustardGui", "chillisakenKanyeGui" }) do
				local g = pg:FindFirstChild(gName)
				if g then g:Destroy() end
			end
		end
	end
})
SettingsTab:CreateSection("Themes")
SettingsTab:CreateButton({ Name = "Set Default Theme", Callback = function() Window.ModifyTheme("Default") end })
SettingsTab:CreateButton({ Name = "Set AmberGlow Theme", Callback = function() Window.ModifyTheme("AmberGlow") end })

return chillisaken
