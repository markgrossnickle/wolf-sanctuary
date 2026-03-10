--!strict
--[=[
	@class CareUIController
	Care interaction buttons (Feed, Groom, Play) near the wolf with cooldown timers
	and visual feedback (particles, animations).
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)

local Player = Knit.Player
local PlayerGui = Player:WaitForChild("PlayerGui")

local IS_MOBILE = UserInputService.TouchEnabled
local IS_CONSOLE = GuiService:IsTenFootInterface()
local BUTTON_MIN_SIZE = 48

local CARE_ACTIONS = {
	{ name = "Feed", icon = "F", color = Color3.fromRGB(220, 150, 50), label = "Feed" },
	{ name = "Groom", icon = "G", color = Color3.fromRGB(100, 170, 220), label = "Groom" },
	{ name = "Play", icon = "P", color = Color3.fromRGB(120, 200, 100), label = "Play" },
}

local function createInstance<T>(className: string, props: { [string]: any }): T
	local inst = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			(inst :: any)[key] = value
		end
	end
	if props.Parent then
		inst.Parent = props.Parent
	end
	return inst :: any
end

local CareUIController = Knit.CreateController({
	Name = "CareUIController",
})

CareUIController._trove = Trove.new()
CareUIController._gui = nil :: ScreenGui?
CareUIController._buttons = {} :: { [string]: { btn: TextButton, cooldownLabel: TextLabel, cooldownOverlay: Frame } }
CareUIController._updateConnection = nil :: RBXScriptConnection?

function CareUIController:_buildUI()
	local baseTextSize = if IS_CONSOLE then 20 elseif IS_MOBILE then 14 else 16

	local gui = createInstance("ScreenGui", {
		Name = "CareUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Enabled = true,
		Parent = PlayerGui,
	}) :: ScreenGui
	self._gui = gui

	-- Care buttons container (bottom-right area)
	local btnSize = math.max(BUTTON_MIN_SIZE, if IS_MOBILE then 60 else 70)
	local spacing = 8
	local containerWidth = (#CARE_ACTIONS * btnSize) + ((#CARE_ACTIONS - 1) * spacing)

	local container = createInstance("Frame", {
		Name = "CareButtons",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -20),
		Size = UDim2.new(0, containerWidth, 0, btnSize + 24),
		BackgroundColor3 = Color3.fromRGB(20, 20, 25),
		BackgroundTransparency = 0.4,
		Parent = gui,
	}) :: Frame
	createInstance("UICorner", { CornerRadius = UDim.new(0, 12), Parent = container })
	createInstance("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, spacing),
		Parent = container,
	})
	createInstance("UIPadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		Parent = container,
	})

	for _, action in CARE_ACTIONS do
		local btnFrame = createInstance("Frame", {
			Name = action.name .. "Frame",
			Size = UDim2.new(0, btnSize, 0, btnSize + 16),
			BackgroundTransparency = 1,
			Parent = container,
		}) :: Frame

		local btn = createInstance("TextButton", {
			Name = action.name,
			Text = action.icon,
			Font = Enum.Font.GothamBold,
			TextSize = baseTextSize + 6,
			TextColor3 = Color3.new(1, 1, 1),
			Size = UDim2.new(1, 0, 0, btnSize),
			BackgroundColor3 = action.color,
			Parent = btnFrame,
		}) :: TextButton
		createInstance("UICorner", { CornerRadius = UDim.new(0, 10), Parent = btn })

		-- Cooldown overlay
		local cooldownOverlay = createInstance("Frame", {
			Name = "CooldownOverlay",
			Size = UDim2.fromScale(1, 0),
			Position = UDim2.fromScale(0, 1),
			AnchorPoint = Vector2.new(0, 1),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.5,
			Visible = false,
			Parent = btn,
		}) :: Frame
		createInstance("UICorner", { CornerRadius = UDim.new(0, 10), Parent = cooldownOverlay })

		-- Cooldown text
		local cooldownLabel = createInstance("TextLabel", {
			Name = "CooldownText",
			Text = "",
			Font = Enum.Font.GothamBold,
			TextSize = baseTextSize,
			TextColor3 = Color3.new(1, 1, 1),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Visible = false,
			Parent = btn,
		}) :: TextLabel

		-- Label below button
		createInstance("TextLabel", {
			Name = "Label",
			Text = action.label,
			Font = Enum.Font.Gotham,
			TextSize = baseTextSize - 2,
			TextColor3 = Color3.fromRGB(200, 200, 200),
			Size = UDim2.new(1, 0, 0, 14),
			Position = UDim2.new(0, 0, 0, btnSize + 2),
			BackgroundTransparency = 1,
			Parent = btnFrame,
		})

		self._buttons[action.name] = {
			btn = btn,
			cooldownLabel = cooldownLabel,
			cooldownOverlay = cooldownOverlay,
		}

		self._trove:Connect(btn.Activated, function()
			self:_onCareAction(action.name)
		end)
	end
end

function CareUIController:_onCareAction(actionName: string)
	local CareController = Knit.GetController("CareController")
	local WolfController = Knit.GetController("WolfController")

	if CareController:IsOnCooldown(actionName) then
		return
	end

	-- Play animation on wolf
	WolfController:PlayCareAnimation(actionName)

	-- Spawn particles at wolf
	self:_spawnCareParticles(actionName)

	-- Call server
	task.spawn(function()
		local success, err = CareController[actionName](CareController)
		if not success then
			warn(`Care action {actionName} failed: {err or "unknown"}`)
		end
	end)
end

function CareUIController:_spawnCareParticles(actionName: string)
	local WolfController = Knit.GetController("WolfController")
	local wolfModel = WolfController:GetModel()
	if not wolfModel or not wolfModel.PrimaryPart then
		return
	end

	-- Create a temporary particle emitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "CareParticle"
	emitter.Lifetime = NumberRange.new(0.5, 1.5)
	emitter.Rate = 0 -- burst only
	emitter.Speed = NumberRange.new(3, 8)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 0),
	})

	if actionName == "Feed" then
		emitter.Color = ColorSequence.new(Color3.fromRGB(255, 200, 80))
	elseif actionName == "Groom" then
		emitter.Color = ColorSequence.new(Color3.fromRGB(180, 220, 255))
	else -- Play
		emitter.Color = ColorSequence.new(Color3.fromRGB(150, 255, 150))
	end

	-- Attach to wolf body
	local attachment = Instance.new("Attachment")
	attachment.Parent = wolfModel.PrimaryPart
	emitter.Parent = attachment

	emitter:Emit(15)

	-- Clean up after particles fade
	task.delay(2, function()
		attachment:Destroy()
	end)
end

function CareUIController:_startCooldownUpdates()
	if self._updateConnection then
		return
	end

	self._updateConnection = RunService.Heartbeat:Connect(function()
		local CareController = Knit.GetController("CareController")

		for actionName, ui in self._buttons do
			local remaining = CareController:GetCooldownRemaining(actionName)
			if remaining > 0 then
				ui.cooldownOverlay.Visible = true
				ui.cooldownLabel.Visible = true
				ui.cooldownLabel.Text = tostring(math.ceil(remaining))
				ui.cooldownOverlay.Size = UDim2.fromScale(1, remaining / 30)
			else
				ui.cooldownOverlay.Visible = false
				ui.cooldownLabel.Visible = false
			end
		end
	end)
	self._trove:Add(self._updateConnection)
end

function CareUIController:KnitInit()
	self:_buildUI()
end

function CareUIController:KnitStart()
	self:_startCooldownUpdates()

	-- Flash button green on successful care action
	local CareController = Knit.GetController("CareController")
	CareController.CareActionCompleted:Connect(function(actionName)
		local ui = self._buttons[actionName]
		if ui then
			local original = ui.btn.BackgroundColor3
			ui.btn.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
			TweenService:Create(ui.btn, TweenInfo.new(0.5), { BackgroundColor3 = original }):Play()
		end
	end)
end

return CareUIController
