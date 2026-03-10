--!strict
--[=[
	@class HowlWheelController
	Radial menu for howl selection (Rally, LocationPing).
	Shows cooldown per howl type, triggers howl sound ring VFX.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)

local HowlData = require(ReplicatedStorage.Shared.Data.HowlData)

local Player = Knit.Player
local PlayerGui = Player:WaitForChild("PlayerGui")

local IS_MOBILE = UserInputService.TouchEnabled
local IS_CONSOLE = GuiService:IsTenFootInterface()
local BUTTON_MIN_SIZE = 48

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

local HowlWheelController = Knit.CreateController({
	Name = "HowlWheelController",
})

HowlWheelController._trove = Trove.new()
HowlWheelController._gui = nil :: ScreenGui?
HowlWheelController._isOpen = false
HowlWheelController._wheelFrame = nil :: Frame?
HowlWheelController._howlButtons = {} :: { [string]: { btn: TextButton, cooldownLabel: TextLabel } }
HowlWheelController._updateConnection = nil :: RBXScriptConnection?

function HowlWheelController:_buildUI()
	local baseTextSize = if IS_CONSOLE then 20 elseif IS_MOBILE then 14 else 16

	local gui = createInstance("ScreenGui", {
		Name = "HowlWheelGui",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Enabled = false,
		Parent = PlayerGui,
	}) :: ScreenGui
	self._gui = gui

	-- Semi-transparent backdrop
	local backdrop = createInstance("Frame", {
		Name = "Backdrop",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.6,
		Parent = gui,
	}) :: Frame

	self._trove:Connect((backdrop :: any).InputBegan, function(input: InputObject)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			self:Close()
		end
	end)

	-- Radial wheel container
	local wheelSize = if IS_MOBILE then 280 else 320
	local wheel = createInstance("Frame", {
		Name = "Wheel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, wheelSize, 0, wheelSize),
		BackgroundColor3 = Color3.fromRGB(25, 30, 50),
		BackgroundTransparency = 0.2,
		Parent = gui,
	}) :: Frame
	createInstance("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = wheel })
	createInstance("UIStroke", {
		Color = Color3.fromRGB(100, 140, 220),
		Thickness = 2,
		Transparency = 0.3,
		Parent = wheel,
	})
	self._wheelFrame = wheel

	-- Center label
	createInstance("TextLabel", {
		Name = "CenterLabel",
		Text = "Howl",
		Font = Enum.Font.GothamBold,
		TextSize = baseTextSize + 4,
		TextColor3 = Color3.fromRGB(180, 200, 255),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 80, 0, 30),
		BackgroundTransparency = 1,
		Parent = wheel,
	})

	-- Build howl option buttons in a circle
	local howlTypes = {}
	for id, def in HowlData do
		table.insert(howlTypes, { id = id, def = def })
	end

	local count = #howlTypes
	local radius = wheelSize * 0.3
	local btnSize = math.max(BUTTON_MIN_SIZE, if IS_MOBILE then 80 else 90)

	for i, howl in howlTypes do
		local angle = ((i - 1) / count) * math.pi * 2 - math.pi / 2
		local x = 0.5 + math.cos(angle) * (radius / wheelSize)
		local y = 0.5 + math.sin(angle) * (radius / wheelSize)

		local btnFrame = createInstance("Frame", {
			Name = howl.id .. "Frame",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(x, y),
			Size = UDim2.new(0, btnSize, 0, btnSize),
			BackgroundTransparency = 1,
			Parent = wheel,
		}) :: Frame

		local btn = createInstance("TextButton", {
			Name = howl.id,
			Text = howl.def.name,
			Font = Enum.Font.GothamBold,
			TextSize = baseTextSize,
			TextColor3 = Color3.new(1, 1, 1),
			Size = UDim2.fromScale(1, 0.65),
			BackgroundColor3 = Color3.fromRGB(60, 80, 140),
			TextWrapped = true,
			Parent = btnFrame,
		}) :: TextButton
		createInstance("UICorner", { CornerRadius = UDim.new(0, 10), Parent = btn })

		-- Description below button
		createInstance("TextLabel", {
			Name = "Desc",
			Text = howl.def.description,
			Font = Enum.Font.Gotham,
			TextSize = baseTextSize - 4,
			TextColor3 = Color3.fromRGB(160, 170, 200),
			Size = UDim2.new(1, 0, 0.3, 0),
			Position = UDim2.fromScale(0, 0.68),
			BackgroundTransparency = 1,
			TextWrapped = true,
			Parent = btnFrame,
		})

		-- Cooldown label
		local cooldownLabel = createInstance("TextLabel", {
			Name = "Cooldown",
			Text = "",
			Font = Enum.Font.GothamBold,
			TextSize = baseTextSize - 1,
			TextColor3 = Color3.fromRGB(255, 100, 100),
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, -14),
			Size = UDim2.new(1, 0, 0, 14),
			BackgroundTransparency = 1,
			Visible = false,
			Parent = btnFrame,
		}) :: TextLabel

		self._howlButtons[howl.id] = { btn = btn, cooldownLabel = cooldownLabel }

		self._trove:Connect(btn.Activated, function()
			self:_onHowlSelected(howl.id)
		end)
	end
end

function HowlWheelController:_onHowlSelected(howlType: string)
	self:Close()

	local HowlController = Knit.GetController("HowlController")
	local WolfController = Knit.GetController("WolfController")

	-- Play howl animation
	local howlDef = HowlData[howlType]
	local duration = if howlDef then howlDef.cooldown * 0.3 else 3
	WolfController:PlayHowlAnimation(math.min(duration, 4))

	-- Spawn sound ring VFX
	self:_spawnHowlRings()

	-- Send to server
	task.spawn(function()
		local success, err = HowlController:PerformHowl(howlType)
		if not success then
			warn(`Howl failed: {err or "unknown"}`)
		end
	end)
end

function HowlWheelController:_spawnHowlRings()
	local WolfController = Knit.GetController("WolfController")
	local wolfModel = WolfController:GetModel()
	if not wolfModel or not wolfModel.PrimaryPart then
		return
	end

	local origin = wolfModel.PrimaryPart.Position + Vector3.new(0, 2, 0)

	-- Create expanding ring parts
	for i = 0, 2 do
		task.delay(i * 0.3, function()
			local ring = Instance.new("Part")
			ring.Name = "HowlRing"
			ring.Shape = Enum.PartType.Cylinder
			ring.Size = Vector3.new(0.1, 2, 2)
			ring.CFrame = CFrame.new(origin) * CFrame.Angles(0, 0, math.rad(90))
			ring.Color = Color3.fromRGB(140, 180, 255)
			ring.Material = Enum.Material.Neon
			ring.Transparency = 0.3
			ring.Anchored = true
			ring.CanCollide = false
			ring.Parent = workspace

			-- Expand and fade
			local expandTween =
				TweenService:Create(ring, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = Vector3.new(0.05, 30, 30),
					Transparency = 1,
				})
			expandTween:Play()
			expandTween.Completed:Wait()
			ring:Destroy()
		end)
	end
end

function HowlWheelController:_startCooldownUpdates()
	if self._updateConnection then
		return
	end

	self._updateConnection = RunService.Heartbeat:Connect(function()
		if not self._isOpen then
			return
		end

		local HowlController = Knit.GetController("HowlController")
		for howlType, ui in self._howlButtons do
			local remaining = HowlController:GetCooldownRemaining(howlType)
			if remaining > 0 then
				ui.cooldownLabel.Visible = true
				ui.cooldownLabel.Text = `{math.ceil(remaining)}s`
				ui.btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
			else
				ui.cooldownLabel.Visible = false
				ui.btn.BackgroundColor3 = Color3.fromRGB(60, 80, 140)
			end
		end
	end)
	self._trove:Add(self._updateConnection)
end

function HowlWheelController:Open()
	if self._isOpen then
		return
	end
	self._isOpen = true
	if self._gui then
		self._gui.Enabled = true
	end

	-- Animate wheel scale in
	if self._wheelFrame then
		self._wheelFrame.Size = UDim2.new(0, 0, 0, 0)
		local targetSize = if IS_MOBILE then 280 else 320
		TweenService:Create(
			self._wheelFrame,
			TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Size = UDim2.new(0, targetSize, 0, targetSize) }
		):Play()
	end
end

function HowlWheelController:Close()
	if not self._isOpen then
		return
	end
	self._isOpen = false
	if self._gui then
		self._gui.Enabled = false
	end
end

function HowlWheelController:Toggle()
	if self._isOpen then
		self:Close()
	else
		self:Open()
	end
end

function HowlWheelController:KnitInit()
	self:_buildUI()
end

function HowlWheelController:KnitStart()
	self:_startCooldownUpdates()

	-- Listen for incoming howls from other players
	local HowlController = Knit.GetController("HowlController")
	HowlController.HowlTriggered:Connect(function(_playerName, _howlType, position)
		-- Spawn howl ring at the howling player's position
		for i = 0, 1 do
			task.delay(i * 0.4, function()
				local ring = Instance.new("Part")
				ring.Name = "RemoteHowlRing"
				ring.Shape = Enum.PartType.Cylinder
				ring.Size = Vector3.new(0.1, 2, 2)
				ring.CFrame = CFrame.new(position + Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
				ring.Color = Color3.fromRGB(200, 180, 140)
				ring.Material = Enum.Material.Neon
				ring.Transparency = 0.4
				ring.Anchored = true
				ring.CanCollide = false
				ring.Parent = workspace

				local expandTween = TweenService:Create(
					ring,
					TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Size = Vector3.new(0.05, 25, 25), Transparency = 1 }
				)
				expandTween:Play()
				expandTween.Completed:Wait()
				ring:Destroy()
			end)
		end
	end)

	-- Keybind: H to toggle howl wheel
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.KeyCode == Enum.KeyCode.H then
			self:Toggle()
		end
		-- Gamepad: left bumper
		if input.KeyCode == Enum.KeyCode.ButtonL1 then
			self:Toggle()
		end
	end)
end

return HowlWheelController
