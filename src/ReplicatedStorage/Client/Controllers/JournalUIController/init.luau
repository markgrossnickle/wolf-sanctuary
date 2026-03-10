--!strict
--[=[
	@class JournalUIController
	Full-screen journal book UI. The educational core of the game.
	Shows 5 sections of wolf facts with locked/unlocked states,
	progress tracking, and new entry notifications.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)

local Player = Knit.Player
local PlayerGui = Player:WaitForChild("PlayerGui")

local IS_MOBILE = UserInputService.TouchEnabled
local IS_CONSOLE = GuiService:IsTenFootInterface()
local BUTTON_MIN_SIZE = 48

-- Journal theme colors
local COLORS = {
	Parchment = Color3.fromRGB(245, 235, 210),
	ParchmentDark = Color3.fromRGB(220, 205, 175),
	Leather = Color3.fromRGB(100, 65, 35),
	LeatherLight = Color3.fromRGB(140, 95, 55),
	LeatherDark = Color3.fromRGB(70, 45, 22),
	Ink = Color3.fromRGB(35, 30, 25),
	InkLight = Color3.fromRGB(90, 80, 65),
	AccentGold = Color3.fromRGB(200, 170, 80),
	Locked = Color3.fromRGB(160, 150, 135),
	LockedBg = Color3.fromRGB(210, 200, 180),
	ProgressFill = Color3.fromRGB(85, 140, 70),
	ProgressBg = Color3.fromRGB(190, 180, 160),
}

-- Section display info
local SECTION_INFO = {
	{ id = "WolfBasics", name = "Wolf Basics", icon = "🐺" },
	{ id = "PackLife", name = "Pack Life", icon = "🐾" },
	{ id = "Senses", name = "Senses", icon = "👃" },
	{ id = "PhysicalAbilities", name = "Abilities", icon = "💨" },
	{ id = "Diet", name = "Diet", icon = "🥩" },
}

local function textSize(): number
	if IS_CONSOLE then
		return 22
	elseif IS_MOBILE then
		return 15
	end
	return 17
end

local function titleTextSize(): number
	if IS_CONSOLE then
		return 28
	elseif IS_MOBILE then
		return 20
	end
	return 22
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

local JournalUIController = Knit.CreateController({
	Name = "JournalUIController",
})

JournalUIController._trove = Trove.new()
JournalUIController._isOpen = false
JournalUIController._gui = nil :: ScreenGui?
JournalUIController._entriesFrame = nil :: ScrollingFrame?
JournalUIController._sectionButtons = {} :: { [string]: TextButton }
JournalUIController._selectedSection = "WolfBasics"
JournalUIController._totalProgressLabel = nil :: TextLabel?
JournalUIController._sectionProgressLabel = nil :: TextLabel?
JournalUIController._notificationFrame = nil :: Frame?

-- ============================================================================
-- UI Construction
-- ============================================================================

function JournalUIController:_buildUI()
	local gui = createInstance("ScreenGui", {
		Name = "JournalGui",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Enabled = false,
		Parent = PlayerGui,
	}) :: ScreenGui
	self._gui = gui

	-- Background overlay
	local overlay = createInstance("Frame", {
		Name = "Overlay",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.4,
		Parent = gui,
	}) :: Frame

	self._trove:Connect((overlay :: any).InputBegan, function(input: InputObject)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			self:Close()
		end
	end)

	-- Main journal container (book shape)
	local containerWidth = if IS_MOBILE then 0.95 else 0.8
	local containerHeight = if IS_MOBILE then 0.92 else 0.85
	local container = createInstance("Frame", {
		Name = "JournalBook",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(containerWidth, containerHeight),
		BackgroundColor3 = COLORS.Parchment,
		Parent = gui,
	}) :: Frame
	createInstance("UICorner", { CornerRadius = UDim.new(0, 8), Parent = container })
	createInstance("UIStroke", {
		Color = COLORS.Leather,
		Thickness = 3,
		Parent = container,
	})

	-- Book spine (left border accent)
	createInstance("Frame", {
		Name = "Spine",
		Size = UDim2.new(0, 6, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = COLORS.LeatherDark,
		BorderSizePixel = 0,
		Parent = container,
	})

	self:_buildHeader(container)
	self:_buildSidebar(container)
	self:_buildEntriesPanel(container)
	self:_buildCloseButton(container)
	self:_buildNotificationFrame(gui)
end

function JournalUIController:_buildHeader(container: Frame)
	local header = createInstance("Frame", {
		Name = "Header",
		Size = UDim2.new(1, -10, 0, if IS_MOBILE then 55 else 65),
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundColor3 = COLORS.Leather,
		BackgroundTransparency = 0.9,
		BorderSizePixel = 0,
		Parent = container,
	}) :: Frame

	-- Title
	createInstance("TextLabel", {
		Name = "Title",
		Text = "Wolf Field Journal",
		Font = Enum.Font.Antique,
		TextSize = titleTextSize() + 6,
		TextColor3 = COLORS.Leather,
		Size = UDim2.new(0.5, 0, 1, 0),
		Position = UDim2.new(0, 20, 0, 0),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})

	-- Total progress
	local progressFrame = createInstance("Frame", {
		Name = "TotalProgress",
		Size = UDim2.new(0.35, 0, 0, 20),
		Position = UDim2.new(0.5, 0, 0.5, -10),
		BackgroundTransparency = 1,
		Parent = header,
	}) :: Frame

	self._totalProgressLabel = createInstance("TextLabel", {
		Name = "ProgressText",
		Text = "0 / 0 discovered",
		Font = Enum.Font.Gotham,
		TextSize = textSize() - 2,
		TextColor3 = COLORS.InkLight,
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = progressFrame,
	}) :: TextLabel

	-- Decorative line under header
	createInstance("Frame", {
		Name = "Divider",
		Size = UDim2.new(1, -30, 0, 2),
		Position = UDim2.new(0, 15, 1, -2),
		BackgroundColor3 = COLORS.LeatherLight,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Parent = header,
	})
end

function JournalUIController:_buildSidebar(container: Frame)
	local sidebarWidth = if IS_MOBILE then 0.22 else 0.2
	local headerHeight = if IS_MOBILE then 55 else 65

	local sidebar = createInstance("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(sidebarWidth, 0, 1, -headerHeight - 10),
		Position = UDim2.new(0, 10, 0, headerHeight + 5),
		BackgroundColor3 = COLORS.ParchmentDark,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		Parent = container,
	}) :: Frame
	createInstance("UICorner", { CornerRadius = UDim.new(0, 4), Parent = sidebar })

	createInstance("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
		Parent = sidebar,
	})
	createInstance("UIPadding", {
		PaddingTop = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
		Parent = sidebar,
	})

	for i, info in SECTION_INFO do
		local btnHeight = math.max(BUTTON_MIN_SIZE, if IS_MOBILE then 52 else 48)
		local btn = createInstance("TextButton", {
			Name = info.id,
			Text = if IS_MOBILE then info.icon else `{info.icon} {info.name}`,
			Font = Enum.Font.GothamMedium,
			TextSize = textSize(),
			TextColor3 = COLORS.Ink,
			Size = UDim2.new(1, 0, 0, btnHeight),
			BackgroundColor3 = COLORS.Parchment,
			LayoutOrder = i,
			TextWrapped = true,
			Parent = sidebar,
		}) :: TextButton
		createInstance("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })

		self._sectionButtons[info.id] = btn
		self._trove:Connect(btn.Activated, function()
			self:_selectSection(info.id)
		end)
	end
end

function JournalUIController:_buildEntriesPanel(container: Frame)
	local sidebarWidth = if IS_MOBILE then 0.22 else 0.2
	local headerHeight = if IS_MOBILE then 55 else 65

	local panel = createInstance("Frame", {
		Name = "EntriesPanel",
		Size = UDim2.new(1 - sidebarWidth, -30, 1, -headerHeight - 10),
		Position = UDim2.new(sidebarWidth, 18, 0, headerHeight + 5),
		BackgroundTransparency = 1,
		Parent = container,
	}) :: Frame

	-- Section header with progress
	local sectionHeader = createInstance("Frame", {
		Name = "SectionHeader",
		Size = UDim2.new(1, 0, 0, 35),
		BackgroundTransparency = 1,
		Parent = panel,
	}) :: Frame

	self._sectionProgressLabel = createInstance("TextLabel", {
		Name = "SectionProgress",
		Text = "Wolf Basics — 0/10 discovered",
		Font = Enum.Font.GothamBold,
		TextSize = titleTextSize(),
		TextColor3 = COLORS.Leather,
		Size = UDim2.new(0.7, 0, 1, 0),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = sectionHeader,
	}) :: TextLabel

	-- Progress bar
	local progressBg = createInstance("Frame", {
		Name = "ProgressBarBg",
		Size = UDim2.new(0.25, 0, 0, 10),
		Position = UDim2.new(0.73, 0, 0.5, -5),
		BackgroundColor3 = COLORS.ProgressBg,
		Parent = sectionHeader,
	}) :: Frame
	createInstance("UICorner", { CornerRadius = UDim.new(1, 0), Parent = progressBg })

	createInstance("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = COLORS.ProgressFill,
		Parent = progressBg,
	})
	createInstance("UICorner", {
		CornerRadius = UDim.new(1, 0),
		Parent = progressBg:FindFirstChild("Fill") :: Instance,
	})

	-- Scrolling entries list
	local scroll = createInstance("ScrollingFrame", {
		Name = "Entries",
		Size = UDim2.new(1, 0, 1, -42),
		Position = UDim2.new(0, 0, 0, 40),
		BackgroundTransparency = 1,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = COLORS.LeatherLight,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = panel,
	}) :: ScrollingFrame

	createInstance("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = scroll,
	})
	createInstance("UIPadding", {
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 8),
		Parent = scroll,
	})

	self._entriesFrame = scroll
end

function JournalUIController:_buildCloseButton(container: Frame)
	local closeBtn = createInstance("TextButton", {
		Name = "Close",
		Text = "X",
		Font = Enum.Font.GothamBold,
		TextSize = titleTextSize(),
		TextColor3 = COLORS.Parchment,
		Size = UDim2.new(0, math.max(BUTTON_MIN_SIZE, 40), 0, math.max(BUTTON_MIN_SIZE, 40)),
		Position = UDim2.new(1, -50, 0, 8),
		BackgroundColor3 = COLORS.Leather,
		Parent = container,
	}) :: TextButton
	createInstance("UICorner", { CornerRadius = UDim.new(0, 8), Parent = closeBtn })

	self._trove:Connect(closeBtn.Activated, function()
		self:Close()
	end)
end

function JournalUIController:_buildNotificationFrame(gui: ScreenGui)
	-- Slide-in notification for new entries
	local notif = createInstance("Frame", {
		Name = "Notification",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -120),
		Size = UDim2.new(if IS_MOBILE then 0.9 else 0.5, 0, 0, 100),
		BackgroundColor3 = COLORS.Leather,
		Visible = false,
		Parent = gui,
	}) :: Frame
	createInstance("UICorner", { CornerRadius = UDim.new(0, 10), Parent = notif })
	createInstance("UIStroke", { Color = COLORS.AccentGold, Thickness = 2, Parent = notif })

	createInstance("TextLabel", {
		Name = "Header",
		Text = "New Journal Entry!",
		Font = Enum.Font.GothamBold,
		TextSize = textSize() + 2,
		TextColor3 = COLORS.AccentGold,
		Size = UDim2.new(1, -16, 0, 24),
		Position = UDim2.new(0, 8, 0, 8),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = notif,
	})

	createInstance("TextLabel", {
		Name = "Title",
		Text = "",
		Font = Enum.Font.GothamBold,
		TextSize = textSize(),
		TextColor3 = COLORS.Parchment,
		Size = UDim2.new(1, -16, 0, 20),
		Position = UDim2.new(0, 8, 0, 32),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = notif,
	})

	createInstance("TextLabel", {
		Name = "Fact",
		Text = "",
		Font = Enum.Font.Gotham,
		TextSize = textSize() - 2,
		TextColor3 = Color3.fromRGB(230, 220, 200),
		Size = UDim2.new(1, -16, 0, 36),
		Position = UDim2.new(0, 8, 0, 54),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = notif,
	})

	self._notificationFrame = notif
end

-- ============================================================================
-- Section & Entry Display
-- ============================================================================

function JournalUIController:_selectSection(sectionId: string)
	self._selectedSection = sectionId

	-- Update tab highlights
	for id, btn in self._sectionButtons do
		if id == sectionId then
			btn.BackgroundColor3 = COLORS.AccentGold
			btn.TextColor3 = COLORS.LeatherDark
		else
			btn.BackgroundColor3 = COLORS.Parchment
			btn.TextColor3 = COLORS.Ink
		end
	end

	self:_populateEntries(sectionId)
end

function JournalUIController:_populateEntries(sectionId: string)
	local scroll = self._entriesFrame
	if not scroll then
		return
	end

	-- Clear existing entries
	for _, child in scroll:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local JournalController = Knit.GetController("JournalController")
	local entries = JournalController:GetSectionEntries(sectionId)
	local unlocked, total = JournalController:GetSectionProgress(sectionId)

	-- Update section header
	local sectionName = sectionId
	for _, info in SECTION_INFO do
		if info.id == sectionId then
			sectionName = info.name
			break
		end
	end

	if self._sectionProgressLabel then
		self._sectionProgressLabel.Text = `{sectionName} — {unlocked}/{total} discovered`
	end

	-- Update progress bar
	local gui = self._gui
	if gui then
		local progressFill = gui:FindFirstChild("JournalBook", true) and gui:FindFirstChild("Fill", true) :: Frame?
		if progressFill then
			local pct = if total > 0 then unlocked / total else 0
			TweenService:Create(progressFill, TweenInfo.new(0.3), { Size = UDim2.fromScale(pct, 1) }):Play()
		end
	end

	-- Update total progress
	local totalUnlocked, totalEntries = JournalController:GetTotalProgress()
	if self._totalProgressLabel then
		self._totalProgressLabel.Text = `{totalUnlocked} / {totalEntries} discovered`
	end

	local baseTextSize = textSize()

	for i, item in entries do
		local isUnlocked = item.unlocked
		local entry = item.entry
		local cardHeight = if isUnlocked then (if IS_MOBILE then 110 else 100) else 60

		local card = createInstance("Frame", {
			Name = entry.id,
			Size = UDim2.new(1, 0, 0, cardHeight),
			BackgroundColor3 = if isUnlocked then COLORS.Parchment else COLORS.LockedBg,
			LayoutOrder = i,
			Parent = scroll,
		}) :: Frame
		createInstance("UICorner", { CornerRadius = UDim.new(0, 6), Parent = card })
		createInstance("UIStroke", {
			Color = if isUnlocked then COLORS.LeatherLight else COLORS.Locked,
			Thickness = 1,
			Transparency = 0.5,
			Parent = card,
		})

		if isUnlocked then
			-- Unlocked entry: show title and full fact text
			createInstance("TextLabel", {
				Name = "Title",
				Text = entry.title,
				Font = Enum.Font.GothamBold,
				TextSize = baseTextSize + 2,
				TextColor3 = COLORS.Leather,
				Size = UDim2.new(1, -16, 0, 24),
				Position = UDim2.new(0, 12, 0, 8),
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = card,
			})

			-- Small gold accent line
			createInstance("Frame", {
				Name = "Accent",
				Size = UDim2.new(0, 40, 0, 2),
				Position = UDim2.new(0, 12, 0, 34),
				BackgroundColor3 = COLORS.AccentGold,
				BorderSizePixel = 0,
				Parent = card,
			})

			-- Fact text — the real educational content
			createInstance("TextLabel", {
				Name = "FactText",
				Text = entry.factText,
				Font = Enum.Font.Gotham,
				TextSize = baseTextSize,
				TextColor3 = COLORS.Ink,
				Size = UDim2.new(1, -24, 1, -44),
				Position = UDim2.new(0, 12, 0, 40),
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextWrapped = true,
				LineHeight = 1.3,
				Parent = card,
			})
		else
			-- Locked entry: show ??? with unlock hint
			createInstance("TextLabel", {
				Name = "LockedTitle",
				Text = "???",
				Font = Enum.Font.GothamBold,
				TextSize = baseTextSize + 2,
				TextColor3 = COLORS.Locked,
				Size = UDim2.new(0, 50, 1, 0),
				Position = UDim2.new(0, 12, 0, 0),
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = card,
			})

			createInstance("TextLabel", {
				Name = "Hint",
				Text = entry.unlockCondition,
				Font = Enum.Font.Gotham,
				TextSize = baseTextSize - 2,
				TextColor3 = COLORS.Locked,
				Size = UDim2.new(1, -80, 1, 0),
				Position = UDim2.new(0, 60, 0, 0),
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				Parent = card,
			})
		end
	end
end

-- ============================================================================
-- Notification
-- ============================================================================

function JournalUIController:_showNotification(title: string, factText: string)
	local notif = self._notificationFrame
	if not notif then
		return
	end

	local titleLabel = notif:FindFirstChild("Title") :: TextLabel?
	local factLabel = notif:FindFirstChild("Fact") :: TextLabel?
	if titleLabel then
		titleLabel.Text = title
	end
	if factLabel then
		factLabel.Text = factText
	end

	notif.Visible = true
	notif.Position = UDim2.new(0.5, 0, 0, -120)

	-- Slide in
	local slideIn = TweenService:Create(
		notif,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 0, 20) }
	)
	slideIn:Play()

	-- Hold then slide out
	task.delay(5, function()
		local slideOut = TweenService:Create(
			notif,
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(0.5, 0, 0, -120) }
		)
		slideOut:Play()
		slideOut.Completed:Wait()
		notif.Visible = false
	end)
end

-- ============================================================================
-- Open / Close
-- ============================================================================

function JournalUIController:Open()
	if self._isOpen then
		return
	end
	self._isOpen = true
	if self._gui then
		self._gui.Enabled = true
	end
	self:_selectSection(self._selectedSection)
end

function JournalUIController:Close()
	if not self._isOpen then
		return
	end
	self._isOpen = false
	if self._gui then
		self._gui.Enabled = false
	end
end

function JournalUIController:Toggle()
	if self._isOpen then
		self:Close()
	else
		self:Open()
	end
end

function JournalUIController:IsOpen(): boolean
	return self._isOpen
end

-- ============================================================================
-- Lifecycle
-- ============================================================================

function JournalUIController:KnitInit()
	self:_buildUI()
end

function JournalUIController:KnitStart()
	local JournalController = Knit.GetController("JournalController")

	-- Listen for new entry unlocks — show notification
	JournalController.EntryUnlocked:Connect(function(_entryId, _section, title, factText)
		self:_showNotification(title, factText)

		-- Refresh current view if journal is open
		if self._isOpen then
			self:_selectSection(self._selectedSection)
		end
	end)

	-- Listen for section completions
	JournalController.SectionCompleted:Connect(function(_section)
		if self._isOpen then
			self:_selectSection(self._selectedSection)
		end
	end)

	-- Keybind: J to toggle journal
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.KeyCode == Enum.KeyCode.J then
			self:Toggle()
		end
		-- Gamepad: X button
		if input.KeyCode == Enum.KeyCode.ButtonX then
			self:Toggle()
		end
	end)
end

return JournalUIController
