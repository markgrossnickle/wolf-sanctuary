--!strict
--[=[
	@class SanctuaryController
	Procedural sanctuary environment: Den, Meadow, Forest zones.
	Built from Roblox Parts, Terrain, lighting, and atmospheric effects.
	No external assets — everything is procedural.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- Zone boundaries (in studs from origin)
local ZONES = {
	Den = { center = Vector3.new(0, 0, 0), radius = 30 },
	Meadow = { center = Vector3.new(80, 0, 0), radius = 60 },
	Forest = { center = Vector3.new(0, 0, -100), radius = 70 },
}

local function createPart(name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

local SanctuaryController = Knit.CreateController({
	Name = "SanctuaryController",
})

SanctuaryController._trove = Trove.new()
SanctuaryController._sanctuaryFolder = nil :: Folder?
SanctuaryController._dayNightConnection = nil :: RBXScriptConnection?
SanctuaryController._timeOfDay = 0 -- 0-24 hours

function SanctuaryController:KnitInit()
	-- Create folder for all sanctuary objects
	local folder = Instance.new("Folder")
	folder.Name = "Sanctuary"
	folder.Parent = workspace
	self._sanctuaryFolder = folder
	self._trove:Add(folder)
end

function SanctuaryController:KnitStart()
	self:_buildGround()
	self:_buildDen()
	self:_buildMeadow()
	self:_buildForest()
	self:_setupLighting()
	self:_startDayNightCycle()

	-- Position wolf in the den
	local WolfController = Knit.GetController("WolfController")
	WolfController:SetSpawnPosition(CFrame.new(0, 3, 0))
end

-- ============================================================================
-- Ground
-- ============================================================================

function SanctuaryController:_buildGround()
	local folder = self._sanctuaryFolder
	if not folder then
		return
	end

	-- Large base ground plane
	local ground = createPart(
		"Ground",
		Vector3.new(400, 1, 400),
		Vector3.new(0, -0.5, -50),
		Color3.fromRGB(85, 130, 60),
		Enum.Material.Grass
	)
	ground.Parent = folder

	-- Rocky terrain around den
	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2
		local dist = 25 + math.random() * 10
		local rock = createPart(
			`DenRock{i}`,
			Vector3.new(3 + math.random() * 4, 2 + math.random() * 3, 3 + math.random() * 4),
			Vector3.new(math.cos(angle) * dist, 1, math.sin(angle) * dist),
			Color3.fromRGB(100 + math.random(30), 95 + math.random(25), 85 + math.random(20)),
			Enum.Material.Slate
		)
		rock.Parent = folder
	end
end

-- ============================================================================
-- Den Zone
-- ============================================================================

function SanctuaryController:_buildDen()
	local folder = self._sanctuaryFolder
	if not folder then
		return
	end

	local denFolder = Instance.new("Folder")
	denFolder.Name = "DenZone"
	denFolder.Parent = folder

	-- Den walls (arched rock enclosure)
	-- Back wall
	local backWall = createPart(
		"BackWall",
		Vector3.new(16, 6, 3),
		Vector3.new(0, 3, -8),
		Color3.fromRGB(90, 80, 70),
		Enum.Material.Slate
	)
	backWall.Parent = denFolder

	-- Side walls
	for _, side in { -1, 1 } do
		local sideWall = createPart(
			if side == -1 then "LeftWall" else "RightWall",
			Vector3.new(3, 5, 12),
			Vector3.new(side * 8, 2.5, -3),
			Color3.fromRGB(95, 85, 75),
			Enum.Material.Slate
		)
		sideWall.Parent = denFolder
	end

	-- Den floor (dirt/earth)
	local denFloor = createPart(
		"DenFloor",
		Vector3.new(14, 0.5, 14),
		Vector3.new(0, 0.1, -2),
		Color3.fromRGB(120, 95, 65),
		Enum.Material.Ground
	)
	denFloor.Parent = denFolder

	-- Cozy log inside den
	local log = createPart(
		"Log",
		Vector3.new(6, 1.2, 1.2),
		Vector3.new(-3, 0.6, -5),
		Color3.fromRGB(100, 70, 40),
		Enum.Material.WoodPlanks
	)
	local logMesh = Instance.new("SpecialMesh")
	logMesh.MeshType = Enum.MeshType.Cylinder
	logMesh.Parent = log
	log.Parent = denFolder

	-- Warm point light (campfire glow)
	local warmLight = Instance.new("PointLight")
	warmLight.Name = "DenWarmLight"
	warmLight.Color = Color3.fromRGB(255, 200, 120)
	warmLight.Brightness = 1.5
	warmLight.Range = 25
	warmLight.Parent = backWall

	-- Small warm rock (pretend fire pit area)
	local firePit = createPart(
		"FirePit",
		Vector3.new(2, 0.3, 2),
		Vector3.new(2, 0.15, -3),
		Color3.fromRGB(60, 55, 50),
		Enum.Material.Slate
	)
	firePit.Parent = denFolder

	-- Glowing embers
	local emberAttachment = Instance.new("Attachment")
	emberAttachment.Position = Vector3.new(0, 0.5, 0)
	emberAttachment.Parent = firePit

	local embers = Instance.new("ParticleEmitter")
	embers.Name = "Embers"
	embers.Rate = 5
	embers.Lifetime = NumberRange.new(1, 3)
	embers.Speed = NumberRange.new(0.5, 2)
	embers.SpreadAngle = Vector2.new(30, 30)
	embers.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 150, 30)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 80, 20)),
	})
	embers.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.5, 0.15),
		NumberSequenceKeypoint.new(1, 0),
	})
	embers.LightEmission = 1
	embers.Parent = emberAttachment

	-- Glowing warm light from embers
	local emberLight = Instance.new("PointLight")
	emberLight.Color = Color3.fromRGB(255, 140, 40)
	emberLight.Brightness = 0.8
	emberLight.Range = 12
	emberLight.Parent = firePit
end

-- ============================================================================
-- Meadow Zone
-- ============================================================================

function SanctuaryController:_buildMeadow()
	local folder = self._sanctuaryFolder
	if not folder then
		return
	end

	local meadowFolder = Instance.new("Folder")
	meadowFolder.Name = "MeadowZone"
	meadowFolder.Parent = folder

	local meadowCenter = ZONES.Meadow.center

	-- Flower patches
	local flowerColors = {
		Color3.fromRGB(255, 100, 120), -- Pink
		Color3.fromRGB(255, 220, 80), -- Yellow
		Color3.fromRGB(180, 130, 255), -- Purple
		Color3.fromRGB(255, 180, 100), -- Orange
		Color3.fromRGB(120, 180, 255), -- Blue
	}

	for i = 1, 25 do
		local angle = math.random() * math.pi * 2
		local dist = math.random() * 50
		local x = meadowCenter.X + math.cos(angle) * dist
		local z = meadowCenter.Z + math.sin(angle) * dist

		-- Flower stem
		local stem = createPart(
			`Flower{i}Stem`,
			Vector3.new(0.15, 0.8 + math.random() * 0.5, 0.15),
			Vector3.new(x, 0.5, z),
			Color3.fromRGB(60, 140, 45)
		)
		stem.Parent = meadowFolder

		-- Flower head
		local head = createPart(
			`Flower{i}Head`,
			Vector3.new(0.5, 0.3, 0.5),
			Vector3.new(x, stem.Position.Y + stem.Size.Y / 2 + 0.1, z),
			flowerColors[(i % #flowerColors) + 1]
		)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = head
		head.Parent = meadowFolder
	end

	-- Scattered small rocks
	for i = 1, 6 do
		local angle = math.random() * math.pi * 2
		local dist = 20 + math.random() * 30
		local rock = createPart(
			`MeadowRock{i}`,
			Vector3.new(1 + math.random() * 2, 0.5 + math.random(), 1 + math.random() * 2),
			Vector3.new(meadowCenter.X + math.cos(angle) * dist, 0.5, meadowCenter.Z + math.sin(angle) * dist),
			Color3.fromRGB(130, 125, 115),
			Enum.Material.Slate
		)
		rock.Parent = meadowFolder
	end

	-- Bright area light for meadow
	local meadowLight = Instance.new("PointLight")
	meadowLight.Name = "MeadowLight"
	meadowLight.Color = Color3.fromRGB(255, 250, 230)
	meadowLight.Brightness = 0.5
	meadowLight.Range = 60
	local lightPart =
		createPart("MeadowLightHolder", Vector3.new(1, 1, 1), meadowCenter + Vector3.new(0, 20, 0), Color3.new(1, 1, 1))
	lightPart.Transparency = 1
	lightPart.CanCollide = false
	meadowLight.Parent = lightPart
	lightPart.Parent = meadowFolder
end

-- ============================================================================
-- Forest Zone
-- ============================================================================

function SanctuaryController:_buildForest()
	local folder = self._sanctuaryFolder
	if not folder then
		return
	end

	local forestFolder = Instance.new("Folder")
	forestFolder.Name = "ForestZone"
	forestFolder.Parent = folder

	local forestCenter = ZONES.Forest.center

	-- Trees (trunk + canopy)
	for i = 1, 18 do
		local angle = math.random() * math.pi * 2
		local dist = 10 + math.random() * 55
		local x = forestCenter.X + math.cos(angle) * dist
		local z = forestCenter.Z + math.sin(angle) * dist
		local trunkHeight = 8 + math.random() * 6
		local trunkWidth = 0.8 + math.random() * 0.6

		-- Trunk (cylinder)
		local trunk = createPart(
			`Tree{i}Trunk`,
			Vector3.new(trunkWidth, trunkHeight, trunkWidth),
			Vector3.new(x, trunkHeight / 2, z),
			Color3.fromRGB(100 + math.random(20), 70 + math.random(15), 40 + math.random(10)),
			Enum.Material.WoodPlanks
		)
		local trunkMesh = Instance.new("SpecialMesh")
		trunkMesh.MeshType = Enum.MeshType.Cylinder
		trunkMesh.Parent = trunk
		trunk.CFrame = trunk.CFrame * CFrame.Angles(0, 0, math.rad(90))
		-- Fix orientation after rotation
		trunk.CFrame = CFrame.new(x, trunkHeight / 2, z) * CFrame.Angles(0, 0, math.rad(90))
		trunk.Size = Vector3.new(trunkHeight, trunkWidth, trunkWidth)
		trunk.Parent = forestFolder

		-- Canopy (sphere, multiple layers)
		local canopySize = 4 + math.random() * 4
		for layer = 0, 1 do
			local canopy = createPart(
				`Tree{i}Canopy{layer}`,
				Vector3.new(
					canopySize * (1 - layer * 0.3),
					canopySize * 0.8 * (1 - layer * 0.2),
					canopySize * (1 - layer * 0.3)
				),
				Vector3.new(x, trunkHeight + canopySize * 0.3 * (1 + layer * 0.5), z),
				Color3.fromRGB(
					40 + math.random(30) - layer * 10,
					100 + math.random(40) + layer * 15,
					35 + math.random(20)
				),
				Enum.Material.Grass
			)
			canopy.CanCollide = false
			local canopyMesh = Instance.new("SpecialMesh")
			canopyMesh.MeshType = Enum.MeshType.Sphere
			canopyMesh.Parent = canopy
			canopy.Parent = forestFolder
		end
	end

	-- Forest floor details: fallen logs, mushrooms
	for i = 1, 4 do
		local angle = math.random() * math.pi * 2
		local dist = 15 + math.random() * 40
		local fallenLog = createPart(
			`FallenLog{i}`,
			Vector3.new(5 + math.random() * 3, 0.8, 0.8),
			Vector3.new(forestCenter.X + math.cos(angle) * dist, 0.4, forestCenter.Z + math.sin(angle) * dist),
			Color3.fromRGB(80, 55, 35),
			Enum.Material.WoodPlanks
		)
		fallenLog.CFrame = fallenLog.CFrame * CFrame.Angles(0, math.random() * math.pi, 0)
		local logMesh = Instance.new("SpecialMesh")
		logMesh.MeshType = Enum.MeshType.Cylinder
		logMesh.Parent = fallenLog
		fallenLog.Parent = forestFolder
	end

	-- Fog effect in forest
	local fogPart =
		createPart("ForestFogHolder", Vector3.new(1, 1, 1), forestCenter + Vector3.new(0, 3, 0), Color3.new(1, 1, 1))
	fogPart.Transparency = 1
	fogPart.CanCollide = false
	fogPart.Parent = forestFolder

	local fogAttachment = Instance.new("Attachment")
	fogAttachment.Parent = fogPart

	local fog = Instance.new("ParticleEmitter")
	fog.Name = "ForestFog"
	fog.Rate = 3
	fog.Lifetime = NumberRange.new(8, 15)
	fog.Speed = NumberRange.new(0.3, 1)
	fog.SpreadAngle = Vector2.new(180, 10)
	fog.Color = ColorSequence.new(Color3.fromRGB(200, 210, 190))
	fog.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 5),
		NumberSequenceKeypoint.new(0.5, 12),
		NumberSequenceKeypoint.new(1, 8),
	})
	fog.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.7),
		NumberSequenceKeypoint.new(0.8, 0.75),
		NumberSequenceKeypoint.new(1, 1),
	})
	fog.LightEmission = 0.1
	fog.Parent = fogAttachment
end

-- ============================================================================
-- Lighting
-- ============================================================================

function SanctuaryController:_setupLighting()
	-- Atmosphere for overall feel
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = Lighting
	end
	atmosphere.Density = 0.3
	atmosphere.Offset = 0.1
	atmosphere.Color = Color3.fromRGB(200, 210, 220)
	atmosphere.Decay = Color3.fromRGB(180, 170, 160)
	atmosphere.Glare = 0.2
	atmosphere.Haze = 3

	-- Bloom for warmth
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	if not bloom then
		bloom = Instance.new("BloomEffect")
		bloom.Parent = Lighting
	end
	bloom.Intensity = 0.3
	bloom.Size = 24
	bloom.Threshold = 1.5

	-- Color correction
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	if not cc then
		cc = Instance.new("ColorCorrectionEffect")
		cc.Parent = Lighting
	end
	cc.Brightness = 0.02
	cc.Contrast = 0.05
	cc.Saturation = 0.15
	cc.TintColor = Color3.fromRGB(255, 250, 240) -- Warm tint

	-- Sun rays
	local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect")
	if not sunRays then
		sunRays = Instance.new("SunRaysEffect")
		sunRays.Parent = Lighting
	end
	sunRays.Intensity = 0.1
	sunRays.Spread = 0.5
end

-- ============================================================================
-- Day/Night Cycle
-- ============================================================================

function SanctuaryController:_startDayNightCycle()
	-- Gentle day/night cycle: 1 in-game day = 12 real minutes
	local CYCLE_MINUTES = 12
	local cycleSpeed = 24 / (CYCLE_MINUTES * 60) -- hours per second

	-- Start at morning
	self._timeOfDay = 9
	Lighting.ClockTime = self._timeOfDay

	self._dayNightConnection = RunService.Heartbeat:Connect(function(dt)
		self._timeOfDay = (self._timeOfDay + cycleSpeed * dt) % 24
		Lighting.ClockTime = self._timeOfDay

		-- Adjust ambient based on time
		local isNight = self._timeOfDay < 6 or self._timeOfDay > 20
		local isDusk = (self._timeOfDay >= 18 and self._timeOfDay <= 20)
			or (self._timeOfDay >= 5 and self._timeOfDay <= 7)

		if isNight then
			Lighting.Ambient = Color3.fromRGB(30, 35, 50)
			Lighting.OutdoorAmbient = Color3.fromRGB(40, 45, 60)
		elseif isDusk then
			Lighting.Ambient = Color3.fromRGB(120, 100, 80)
			Lighting.OutdoorAmbient = Color3.fromRGB(150, 120, 90)
		else
			Lighting.Ambient = Color3.fromRGB(100, 105, 110)
			Lighting.OutdoorAmbient = Color3.fromRGB(130, 135, 140)
		end
	end)
	self._trove:Add(self._dayNightConnection)
end

return SanctuaryController
