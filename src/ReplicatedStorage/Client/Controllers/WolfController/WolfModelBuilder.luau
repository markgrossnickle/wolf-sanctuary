--!strict
--[=[
	@class WolfModelBuilder
	Procedural wolf model from Roblox Parts. Sizes scale with WolfStage.
	No external meshes — body, head, legs, tail, ears from Parts.
]=]

local TweenService = game:GetService("TweenService")

local WolfModelBuilder = {}

-- Stage scale multipliers (Newborn is tiny, FullGrown is large)
local STAGE_SCALES: { [string]: number } = {
	Newborn = 0.3,
	EyesOpen = 0.35,
	FirstSteps = 0.4,
	OutsideDen = 0.5,
	FirstHowl = 0.6,
	Rendezvous = 0.7,
	HuntTraining = 0.85,
	YoungAdult = 0.95,
	FullGrown = 1.0,
}

-- Wolf coat colors
local COAT_COLORS: { [string]: Color3 } = {
	Gray = Color3.fromRGB(120, 115, 105),
	Black = Color3.fromRGB(40, 38, 35),
	White = Color3.fromRGB(230, 225, 215),
	Brown = Color3.fromRGB(140, 100, 65),
	Red = Color3.fromRGB(160, 95, 55),
}

local BELLY_COLOR = Color3.fromRGB(195, 185, 170)
local NOSE_COLOR = Color3.fromRGB(30, 25, 20)
local EYE_COLOR_PUP = Color3.fromRGB(100, 150, 210) -- Blue for pups
local EYE_COLOR_ADULT = Color3.fromRGB(210, 180, 50) -- Amber for adults

local function getEyeColor(stage: string): Color3
	if stage == "Newborn" or stage == "EyesOpen" then
		return EYE_COLOR_PUP
	end
	return EYE_COLOR_ADULT
end

local function createPart(name: string, size: Vector3, color: Color3, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function weld(part0: Part, part1: Part, offset: CFrame)
	local weldConstraint = Instance.new("WeldConstraint")
	weldConstraint.Part0 = part0
	weldConstraint.Part1 = part1
	weldConstraint.Parent = part0
	part1.CFrame = part0.CFrame * offset
	part1.Anchored = false
end

--[=[
	Build a procedural wolf model.
	@param stage string -- WolfStage enum value
	@param coatColor string -- Coat color name
	@return Model
]=]
function WolfModelBuilder.Build(stage: string, coatColor: string): Model
	local scale = STAGE_SCALES[stage] or 1.0
	local coat = COAT_COLORS[coatColor] or COAT_COLORS.Gray
	local eyeColor = getEyeColor(stage)

	local model = Instance.new("Model")
	model.Name = "WolfModel"

	-- Base dimensions at full scale
	local bodyLength = 4.5 * scale
	local bodyWidth = 1.8 * scale
	local bodyHeight = 2.0 * scale
	local headSize = 1.4 * scale
	local legWidth = 0.5 * scale
	local legHeight = 2.2 * scale
	local tailLength = 2.0 * scale
	local earSize = 0.5 * scale

	-- Body (main torso)
	local body = createPart("Body", Vector3.new(bodyLength, bodyHeight, bodyWidth), coat, model)
	model.PrimaryPart = body

	-- Body rounding
	local bodyMesh = Instance.new("SpecialMesh")
	bodyMesh.MeshType = Enum.MeshType.Sphere
	bodyMesh.Scale = Vector3.new(1, 0.75, 0.85)
	bodyMesh.Parent = body

	-- Chest/front torso (slightly wider)
	local chest = createPart("Chest", Vector3.new(bodyLength * 0.5, bodyHeight * 1.05, bodyWidth * 1.1), coat, model)
	local chestMesh = Instance.new("SpecialMesh")
	chestMesh.MeshType = Enum.MeshType.Sphere
	chestMesh.Scale = Vector3.new(1, 0.8, 0.9)
	chestMesh.Parent = chest
	weld(body, chest, CFrame.new(bodyLength * 0.3, 0.05 * scale, 0))

	-- Head
	local head = createPart("Head", Vector3.new(headSize * 1.3, headSize, headSize * 0.95), coat, model)
	local headMesh = Instance.new("SpecialMesh")
	headMesh.MeshType = Enum.MeshType.Sphere
	headMesh.Parent = head
	weld(body, head, CFrame.new(bodyLength * 0.55, bodyHeight * 0.4, 0))

	-- Snout
	local snoutSize = headSize * 0.55
	local snout = createPart("Snout", Vector3.new(snoutSize * 1.4, snoutSize * 0.6, snoutSize * 0.7), coat, model)
	local snoutMesh = Instance.new("SpecialMesh")
	snoutMesh.MeshType = Enum.MeshType.Sphere
	snoutMesh.Scale = Vector3.new(1, 0.7, 0.8)
	snoutMesh.Parent = snout
	weld(head, snout, CFrame.new(headSize * 0.65, -headSize * 0.15, 0))

	-- Nose
	local nose = createPart("Nose", Vector3.new(0.25 * scale, 0.2 * scale, 0.25 * scale), NOSE_COLOR, model)
	local noseMesh = Instance.new("SpecialMesh")
	noseMesh.MeshType = Enum.MeshType.Sphere
	noseMesh.Parent = nose
	weld(snout, nose, CFrame.new(snoutSize * 0.65, 0.05 * scale, 0))

	-- Eyes
	local eyeSize = 0.2 * scale
	for _, side in { -1, 1 } do
		local eye = createPart(
			if side == -1 then "LeftEye" else "RightEye",
			Vector3.new(eyeSize, eyeSize * 1.1, eyeSize * 0.5),
			eyeColor,
			model
		)
		local eyeMesh = Instance.new("SpecialMesh")
		eyeMesh.MeshType = Enum.MeshType.Sphere
		eyeMesh.Parent = eye

		-- Pupil
		local pupil = createPart(
			if side == -1 then "LeftPupil" else "RightPupil",
			Vector3.new(eyeSize * 0.5, eyeSize * 0.6, eyeSize * 0.3),
			NOSE_COLOR,
			model
		)
		local pupilMesh = Instance.new("SpecialMesh")
		pupilMesh.MeshType = Enum.MeshType.Sphere
		pupilMesh.Parent = pupil

		weld(head, eye, CFrame.new(headSize * 0.35, headSize * 0.1, side * headSize * 0.35))
		weld(eye, pupil, CFrame.new(eyeSize * 0.15, 0, side * eyeSize * 0.1))
	end

	-- Ears (triangular, pointed)
	for _, side in { -1, 1 } do
		local ear = createPart(
			if side == -1 then "LeftEar" else "RightEar",
			Vector3.new(earSize * 0.5, earSize * 1.2, earSize * 0.8),
			coat,
			model
		)
		local earMesh = Instance.new("SpecialMesh")
		earMesh.MeshType = Enum.MeshType.Wedge
		earMesh.Parent = ear
		weld(
			head,
			ear,
			CFrame.new(-headSize * 0.1, headSize * 0.55, side * headSize * 0.25)
				* CFrame.Angles(0, if side == -1 then math.rad(10) else math.rad(-10), 0)
		)

		-- Inner ear (lighter color)
		local innerEar = createPart(
			if side == -1 then "LeftInnerEar" else "RightInnerEar",
			Vector3.new(earSize * 0.3, earSize * 0.8, earSize * 0.5),
			BELLY_COLOR,
			model
		)
		local innerEarMesh = Instance.new("SpecialMesh")
		innerEarMesh.MeshType = Enum.MeshType.Wedge
		innerEarMesh.Parent = innerEar
		weld(ear, innerEar, CFrame.new(earSize * 0.05, 0, 0))
	end

	-- Legs (4 legs)
	local legPositions = {
		{ name = "FrontLeftLeg", x = bodyLength * 0.3, z = -bodyWidth * 0.35 },
		{ name = "FrontRightLeg", x = bodyLength * 0.3, z = bodyWidth * 0.35 },
		{ name = "BackLeftLeg", x = -bodyLength * 0.3, z = -bodyWidth * 0.35 },
		{ name = "BackRightLeg", x = -bodyLength * 0.3, z = bodyWidth * 0.35 },
	}

	for _, legInfo in legPositions do
		-- Upper leg
		local upperLeg = createPart(legInfo.name, Vector3.new(legWidth, legHeight * 0.55, legWidth), coat, model)
		weld(body, upperLeg, CFrame.new(legInfo.x, -bodyHeight * 0.35 - legHeight * 0.2, legInfo.z))

		-- Lower leg (slightly thinner)
		local lowerLeg = createPart(
			legInfo.name .. "Lower",
			Vector3.new(legWidth * 0.85, legHeight * 0.5, legWidth * 0.85),
			coat,
			model
		)
		weld(upperLeg, lowerLeg, CFrame.new(0, -legHeight * 0.5, 0))

		-- Paw
		local paw =
			createPart(legInfo.name .. "Paw", Vector3.new(legWidth * 1.2, 0.2 * scale, legWidth * 1.3), coat, model)
		local pawMesh = Instance.new("SpecialMesh")
		pawMesh.MeshType = Enum.MeshType.Sphere
		pawMesh.Scale = Vector3.new(1, 0.3, 1.1)
		pawMesh.Parent = paw
		weld(lowerLeg, paw, CFrame.new(0.05 * scale, -legHeight * 0.25, 0))
	end

	-- Tail (bushy, using multiple parts)
	local tailBase = createPart("TailBase", Vector3.new(tailLength * 0.6, 0.4 * scale, 0.4 * scale), coat, model)
	local tailBaseMesh = Instance.new("SpecialMesh")
	tailBaseMesh.MeshType = Enum.MeshType.Sphere
	tailBaseMesh.Scale = Vector3.new(1.5, 0.6, 0.7)
	tailBaseMesh.Parent = tailBase
	weld(
		body,
		tailBase,
		CFrame.new(-bodyLength * 0.5 - tailLength * 0.15, bodyHeight * 0.15, 0) * CFrame.Angles(0, 0, math.rad(-15))
	)

	local tailTip = createPart("TailTip", Vector3.new(tailLength * 0.5, 0.35 * scale, 0.35 * scale), coat, model)
	local tailTipMesh = Instance.new("SpecialMesh")
	tailTipMesh.MeshType = Enum.MeshType.Sphere
	tailTipMesh.Scale = Vector3.new(1.5, 0.5, 0.6)
	tailTipMesh.Parent = tailTip
	weld(tailBase, tailTip, CFrame.new(-tailLength * 0.4, -0.15 * scale, 0) * CFrame.Angles(0, 0, math.rad(-20)))

	-- Belly underside (lighter color)
	local belly =
		createPart("Belly", Vector3.new(bodyLength * 0.6, bodyHeight * 0.3, bodyWidth * 0.7), BELLY_COLOR, model)
	local bellyMesh = Instance.new("SpecialMesh")
	bellyMesh.MeshType = Enum.MeshType.Sphere
	bellyMesh.Parent = belly
	weld(body, belly, CFrame.new(0, -bodyHeight * 0.3, 0))

	return model
end

--[=[
	Get the scale multiplier for a given stage.
]=]
function WolfModelBuilder.GetStageScale(stage: string): number
	return STAGE_SCALES[stage] or 1.0
end

--[=[
	Smoothly scale an existing wolf model to a new stage size.
	Uses TweenService for smooth growth transition.
]=]
function WolfModelBuilder.TweenToStage(model: Model, newStage: string, duration: number?)
	local newScale = STAGE_SCALES[newStage] or 1.0
	local tweenDuration = duration or 2.0

	-- We rebuild at new size and tween the old model's transparency out
	-- while tweening the new model in
	local tweenInfo = TweenInfo.new(tweenDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			local targetSize = part.Size
				* (newScale / (STAGE_SCALES[model:GetAttribute("Stage") or "FullGrown"] or 1.0))
			TweenService:Create(part, tweenInfo, { Size = targetSize }):Play()
		end
	end

	model:SetAttribute("Stage", newStage)
end

--[=[
	Update eye color for a wolf model (pup blue -> adult amber transition).
]=]
function WolfModelBuilder.UpdateEyeColor(model: Model, stage: string)
	local color = getEyeColor(stage)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and (part.Name == "LeftEye" or part.Name == "RightEye") then
			part.Color = color
		end
	end
end

return WolfModelBuilder
