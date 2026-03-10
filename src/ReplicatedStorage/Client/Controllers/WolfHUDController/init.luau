--!strict
--[=[
	@class WolfHUDController
	Persistent HUD showing wolf name, stage, and stat bars (Hunger/Energy/Happiness).
	Color-coded: green (high), yellow (mid), red (low).
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

local function statColor(value: number): Color3
	if value >= 65 then
		return Color3.fromRGB(75, 180, 75) -- Green
	elseif value >= 35 then
		return Color3.fromRGB(220, 185, 50) -- Yellow
	end
	return Color3.fromRGB(200, 60, 50) -- Red
end

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

local WolfHUDController = Knit.CreateController({
	Name = "WolfHUDController",
})

WolfHUDController._trove = Trove.new()
WolfHUDController._gui = nil :: ScreenGui?
WolfHUDController._nameLabel = nil :: TextLabel?
WolfHUDController._stageLabel = nil :: TextLabel?
WolfHUDController._statBars = {} :: { [string]: { fill: Frame, label: TextLabel } }
WolfHUDController._stageProgressBar = nil :: Frame?

function WolfHUDController:_buildUI()
	local baseTextSize = if IS_CONSOLE then 20 elseif IS_MOBILE then 13 else 14

	local gui = createInstance("ScreenGui", {
		Name = "WolfHUD",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Enabled = true,
		Parent = PlayerGui,
	}) :: ScreenGui
	self._gui = gui

	-- HUD container (top-left)
	local hudWidth = if IS_MOBILE then 180 else 220
	local container = createInstance("Frame", {
		Name = "HUDContainer",
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.new(0, 10, 0, 10),
		Size = UDim2.new(0, hudWidth, 0, 140),
		BackgroundColor3 = Color3.fromRGB(20, 20, 25),
		BackgroundTransparency = 0.3,
		Parent = gui,
	}) :: Frame
	createInstance("UICorner", { CornerRadius = UDim.new(0, 10), Parent = container })
	createInstance("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		Parent = container,
	})

	-- Wolf name
	self._nameLabel = createInstance("TextLabel", {
		Name = "WolfName",
		Text = "Your Wolf",
		Font = Enum.Font.GothamBold,
		TextSize = baseTextSize + 4,
		TextColor3 = Color3.new(1, 1, 1),
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = container,
	}) :: TextLabel

	-- Stage label
	self._stageLabel = createInstance("TextLabel", {
		Name = "Stage",
		Text = "Newborn",
		Font = Enum.Font.Gotham,
		TextSize = baseTextSize,
		TextColor3 = Color3.fromRGB(200, 180, 100),
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 0, 0, 22),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = container,
	}) :: TextLabel

	-- Stage progress bar
	local stageProgressBg = createInstance("Frame", {
		Name = "StageProgress",
		Size = UDim2.new(1, 0, 0, 4),
		Position = UDim2.new(0, 0, 0, 40),
		BackgroundColor3 = Color3.fromRGB(60, 60, 60),
		Parent = container,
	}) :: Frame
	createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = stageProgressBg })

	self._stageProgressBar = createInstance("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.fromRGB(200, 180, 100),
		Parent = stageProgressBg,
	}) :: Frame
	createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = self._stageProgressBar })

	-- Stat bars
	local stats = { "Hunger", "Energy", "Happiness" }
	local statIcons = { Hunger = "H", Energy = "E", Happiness = "J" }
	local yOffset = 50

	for _, statName in stats do
		local barHeight = 14
		local row = createInstance("Frame", {
			Name = statName .. "Row",
			Size = UDim2.new(1, 0, 0, barHeight + 6),
			Position = UDim2.new(0, 0, 0, yOffset),
			BackgroundTransparency = 1,
			Parent = container,
		}) :: Frame

		-- Stat label
		local label = createInstance("TextLabel", {
			Name = "Label",
			Text = `{statIcons[statName]} {statName}`,
			Font = Enum.Font.Gotham,
			TextSize = baseTextSize - 1,
			TextColor3 = Color3.fromRGB(180, 180, 180),
			Size = UDim2.new(0, 70, 1, 0),
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		}) :: TextLabel

		-- Bar background
		local barBg = createInstance("Frame", {
			Name = "BarBg",
			Size = UDim2.new(1, -75, 0, barHeight),
			Position = UDim2.new(0, 72, 0.5, -barHeight / 2),
			BackgroundColor3 = Color3.fromRGB(40, 40, 40),
			Parent = row,
		}) :: Frame
		createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = barBg })

		-- Bar fill
		local fill = createInstance("Frame", {
			Name = "Fill",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = statColor(100),
			Parent = barBg,
		}) :: Frame
		createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })

		self._statBars[statName] = { fill = fill, label = label }
		yOffset += barHeight + 10
	end
end

function WolfHUDController:_updateStats(stats: { Hunger: number, Energy: number, Happiness: number })
	for statName, value in stats do
		local bar = self._statBars[statName]
		if bar then
			local pct = math.clamp(value / 100, 0, 1)
			TweenService:Create(bar.fill, TweenInfo.new(0.3), {
				Size = UDim2.fromScale(pct, 1),
				BackgroundColor3 = statColor(value),
			}):Play()
		end
	end
end

function WolfHUDController:_updateWolfInfo(wolfData: any)
	if not wolfData then
		return
	end

	if self._nameLabel then
		local name = wolfData.Name
		self._nameLabel.Text = if name and name ~= "" then name else "Your Wolf"
	end

	if self._stageLabel then
		local stageDef = WolfData.Stages[wolfData.Stage]
		self._stageLabel.Text = if stageDef then stageDef.Name else wolfData.Stage
	end

	-- Stage progress bar
	if self._stageProgressBar then
		local nextStage = WolfData.GetNextStage(wolfData.Stage)
		if nextStage then
			local nextDef = WolfData.Stages[nextStage]
			local currentDef = WolfData.Stages[wolfData.Stage]
			if nextDef and currentDef then
				local start = currentDef.PlayDaysRequired
				local target = nextDef.PlayDaysRequired
				local progress = if target > start
					then math.clamp((wolfData.PlayDays - start) / (target - start), 0, 1)
					else 1
				TweenService:Create(self._stageProgressBar, TweenInfo.new(0.3), {
					Size = UDim2.fromScale(progress, 1),
				}):Play()
			end
		else
			-- FullGrown — show 100%
			self._stageProgressBar.Size = UDim2.fromScale(1, 1)
		end
	end

	if wolfData.Stats then
		self:_updateStats(wolfData.Stats)
	end
end

function WolfHUDController:KnitInit()
	self:_buildUI()
end

function WolfHUDController:KnitStart()
	local WolfController = Knit.GetController("WolfController")

	-- Initial data load
	task.spawn(function()
		-- Wait a moment for WolfController to load data
		task.wait(1)
		local wolfData = WolfController:GetWolfData()
		if wolfData then
			self:_updateWolfInfo(wolfData)
		end
	end)

	-- Listen for stats updates
	WolfController.StatsUpdated:Connect(function(stats)
		self:_updateStats(stats)
	end)

	-- Listen for stage advances
	WolfController.StageAdvanced:Connect(function(_prev, _newStage, _factText)
		local wolfData = WolfController:GetWolfData()
		if wolfData then
			self:_updateWolfInfo(wolfData)
		end
	end)

	-- Listen for name changes
	local WolfService = Knit.GetService("WolfService")
	WolfService.WolfNameSet:Connect(function(name)
		if self._nameLabel then
			self._nameLabel.Text = if name and name ~= "" then name else "Your Wolf"
		end
	end)
end

return WolfHUDController
