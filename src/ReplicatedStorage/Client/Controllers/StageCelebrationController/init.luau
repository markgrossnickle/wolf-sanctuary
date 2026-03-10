--!strict
--[=[
	@class StageCelebrationController
	Stage advancement celebration: camera zoom, particle burst,
	stage name display, fact text, wolf growth.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)

local WolfData = require(ReplicatedStorage.Shared.Data.WolfData)

local Player = Knit.Player
local PlayerGui = Player:WaitForChild("PlayerGui")

local IS_MOBILE = UserInputService.TouchEnabled
local IS_CONSOLE = GuiService:IsTenFootInterface()

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

local StageCelebrationController = Knit.CreateController({
	Name = "StageCelebrationController",
})

StageCelebrationController._trove = Trove.new()
StageCelebrationController._gui = nil :: ScreenGui?
StageCelebrationController._celebrating = false

function StageCelebrationController:_buildUI()
	local gui = createInstance("ScreenGui", {
		Name = "StageCelebrationGui",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 10,
		Enabled = false,
		Parent = PlayerGui,
	}) :: ScreenGui
	self._gui = gui

	-- Full-screen dim overlay
	createInstance("Frame", {
		Name = "Overlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.6,
		Parent = gui,
	})

	-- Stage name (large, centered)
	local baseTextSize = if IS_CONSOLE then 48 elseif IS_MOBILE then 32 else 40

	createInstance("TextLabel", {
		Name = "StageName",
		Text = "",
		Font = Enum.Font.Antique,
		TextSize = baseTextSize,
		TextColor3 = Color3.fromRGB(255, 220, 120),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.new(0.8, 0, 0, 50),
		BackgroundTransparency = 1,
		TextStrokeTransparency = 0.5,
		TextStrokeColor3 = Color3.fromRGB(80, 50, 10),
		Parent = gui,
	})

	-- Subtitle "Your wolf has grown!"
	createInstance("TextLabel", {
		Name = "Subtitle",
		Text = "Your wolf has grown!",
		Font = Enum.Font.GothamMedium,
		TextSize = baseTextSize * 0.5,
		TextColor3 = Color3.fromRGB(230, 210, 170),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.3, 30),
		Size = UDim2.new(0.6, 0, 0, 30),
		BackgroundTransparency = 1,
		Parent = gui,
	})

	-- Fact text panel
	local factPanel = createInstance("Frame", {
		Name = "FactPanel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.6),
		Size = UDim2.new(if IS_MOBILE then 0.85 else 0.6, 0, 0, 120),
		BackgroundColor3 = Color3.fromRGB(50, 40, 25),
		BackgroundTransparency = 0.2,
		Parent = gui,
	}) :: Frame
	createInstance("UICorner", { CornerRadius = UDim.new(0, 10), Parent = factPanel })
	createInstance("UIStroke", {
		Color = Color3.fromRGB(200, 170, 80),
		Thickness = 2,
		Parent = factPanel,
	})

	createInstance("TextLabel", {
		Name = "FactHeader",
		Text = "Did You Know?",
		Font = Enum.Font.GothamBold,
		TextSize = if IS_CONSOLE then 20 elseif IS_MOBILE then 15 else 17,
		TextColor3 = Color3.fromRGB(255, 220, 120),
		Size = UDim2.new(1, -20, 0, 24),
		Position = UDim2.new(0, 10, 0, 8),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = factPanel,
	})

	createInstance("TextLabel", {
		Name = "FactText",
		Text = "",
		Font = Enum.Font.Gotham,
		TextSize = if IS_CONSOLE then 18 elseif IS_MOBILE then 14 else 16,
		TextColor3 = Color3.fromRGB(230, 220, 200),
		Size = UDim2.new(1, -20, 1, -40),
		Position = UDim2.new(0, 10, 0, 36),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		LineHeight = 1.3,
		Parent = factPanel,
	})

	-- Continue button
	local continueBtn = createInstance("TextButton", {
		Name = "Continue",
		Text = "Continue",
		Font = Enum.Font.GothamBold,
		TextSize = if IS_CONSOLE then 22 elseif IS_MOBILE then 16 else 18,
		TextColor3 = Color3.new(1, 1, 1),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.6, 80),
		Size = UDim2.new(0, 200, 0, 50),
		BackgroundColor3 = Color3.fromRGB(100, 65, 35),
		Parent = gui,
	}) :: TextButton
	createInstance("UICorner", { CornerRadius = UDim.new(0, 10), Parent = continueBtn })

	self._trove:Connect(continueBtn.Activated, function()
		self:_dismiss()
	end)
end

function StageCelebrationController:_celebrate(_prevStage: string, newStage: string, factText: string)
	if self._celebrating then
		return
	end
	self._celebrating = true

	local gui = self._gui
	if not gui then
		return
	end

	local stageDef = WolfData.Stages[newStage]
	local stageName = if stageDef then stageDef.Name else newStage

	-- Set text content
	local stageLabel = gui:FindFirstChild("StageName", true) :: TextLabel?
	if stageLabel then
		stageLabel.Text = stageName
		stageLabel.TextTransparency = 1
	end

	local factLabel = gui:FindFirstChild("FactText", true) :: TextLabel?
	if factLabel then
		factLabel.Text = factText
	end

	local factPanel = gui:FindFirstChild("FactPanel", true) :: Frame?
	if factPanel then
		factPanel.BackgroundTransparency = 1
	end

	local continueBtn = gui:FindFirstChild("Continue", true) :: TextButton?
	if continueBtn then
		continueBtn.Visible = false
	end

	gui.Enabled = true

	-- Spawn particle burst at wolf
	self:_spawnCelebrationParticles()

	-- Animate stage name fade in
	if stageLabel then
		TweenService:Create(stageLabel, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = 0,
		}):Play()
	end

	-- Delay then show fact panel
	task.delay(1.5, function()
		if factPanel then
			TweenService:Create(factPanel, TweenInfo.new(0.5), { BackgroundTransparency = 0.2 }):Play()
		end

		task.delay(0.5, function()
			if continueBtn then
				continueBtn.Visible = true
			end
		end)
	end)
end

function StageCelebrationController:_dismiss()
	self._celebrating = false
	if self._gui then
		self._gui.Enabled = false
	end
end

function StageCelebrationController:_spawnCelebrationParticles()
	local WolfController = Knit.GetController("WolfController")
	local wolfModel = WolfController:GetModel()
	if not wolfModel or not wolfModel.PrimaryPart then
		return
	end

	local body = wolfModel.PrimaryPart

	-- Golden sparkle burst
	local attachment = Instance.new("Attachment")
	attachment.Parent = body

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "CelebrationParticle"
	emitter.Lifetime = NumberRange.new(1, 3)
	emitter.Rate = 0
	emitter.Speed = NumberRange.new(5, 15)
	emitter.SpreadAngle = Vector2.new(360, 360)
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 80)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 180, 50)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 200)),
	})
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.3, 0.8),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.LightEmission = 1
	emitter.Parent = attachment

	emitter:Emit(40)

	-- Second emitter — white sparkles
	local emitter2 = Instance.new("ParticleEmitter")
	emitter2.Name = "CelebrationSparkle"
	emitter2.Lifetime = NumberRange.new(0.8, 2)
	emitter2.Rate = 0
	emitter2.Speed = NumberRange.new(3, 10)
	emitter2.SpreadAngle = Vector2.new(360, 360)
	emitter2.Color = ColorSequence.new(Color3.fromRGB(255, 255, 240))
	emitter2.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.5, 0.4),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter2.LightEmission = 1
	emitter2.Parent = attachment

	emitter2:Emit(25)

	task.delay(4, function()
		attachment:Destroy()
	end)
end

function StageCelebrationController:KnitInit()
	self:_buildUI()
end

function StageCelebrationController:KnitStart()
	local WolfController = Knit.GetController("WolfController")

	WolfController.StageAdvanced:Connect(function(prevStage, newStage, factText)
		self:_celebrate(prevStage, newStage, factText)
	end)
end

return StageCelebrationController
