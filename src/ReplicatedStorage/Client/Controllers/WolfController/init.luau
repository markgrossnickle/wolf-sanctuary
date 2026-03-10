--!strict
--[=[
	@class WolfController
	Client-side wolf rendering, animation, and milestone reactions.
	Listens to WolfService signals and manages the procedural wolf model.
]=]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

local WolfData = require(ReplicatedStorage.Shared.Data.WolfData)
local WolfModelBuilder = require(script.WolfModelBuilder)
local WolfAnimator = require(script.WolfAnimator)

local WolfController = Knit.CreateController({
	Name = "WolfController",
	StageAdvanced = Signal.new(), -- (prevStage, newStage, factText)
	StatsUpdated = Signal.new(), -- (stats)
})

WolfController._trove = Trove.new()
WolfController._model = nil :: Model?
WolfController._animator = nil :: WolfAnimator.WolfAnimator?
WolfController._wolfData = nil :: any
WolfController._spawnPosition = CFrame.new(0, 3, 0)

function WolfController:KnitInit() end

function WolfController:KnitStart()
	local WolfService = Knit.GetService("WolfService")

	-- Load initial wolf data and increment play day
	task.spawn(function()
		local ok, data = WolfService:GetWolfData():await()
		if ok and data then
			self._wolfData = data
			self:_spawnWolf(data.Stage, data.CoatColor)
		end

		-- Increment play day for this session
		WolfService:IncrementPlayDay()
	end)

	-- Listen for stage advancement
	WolfService.StageAdvanced:Connect(function(prevStage, newStage, factText)
		self:_onStageAdvanced(prevStage, newStage, factText)
	end)

	-- Listen for stats updates
	WolfService.StatsUpdated:Connect(function(stats)
		self._wolfData = self._wolfData or {}
		self._wolfData.Stats = stats
		self.StatsUpdated:Fire(stats)
	end)

	-- Listen for name changes
	WolfService.WolfNameSet:Connect(function(name)
		if self._wolfData then
			self._wolfData.Name = name
		end
	end)
end

--[=[
	Spawn the wolf model at the current spawn position.
]=]
function WolfController:_spawnWolf(stage: string, coatColor: string)
	-- Clean up existing
	if self._animator then
		self._animator:Destroy()
		self._animator = nil
	end
	if self._model then
		self._model:Destroy()
		self._model = nil
	end

	local model = WolfModelBuilder.Build(stage, coatColor)
	model:SetAttribute("Stage", stage)
	model:PivotTo(self._spawnPosition)
	model.Parent = workspace

	self._model = model
	self._animator = WolfAnimator.new(model)
	self._animator:PlayIdle()
end

--[=[
	Handle stage advancement with visual feedback.
]=]
function WolfController:_onStageAdvanced(prevStage: string, newStage: string, factText: string)
	if self._wolfData then
		self._wolfData.Stage = newStage
	end

	-- Rebuild wolf at new size
	local coatColor = if self._wolfData then self._wolfData.CoatColor else "Gray"
	self:_spawnWolf(newStage, coatColor)

	-- Update eye color
	if self._model then
		WolfModelBuilder.UpdateEyeColor(self._model, newStage)
	end

	self.StageAdvanced:Fire(prevStage, newStage, factText)
end

--[=[
	Returns the cached current stage.
]=]
function WolfController:GetCurrentStage(): string
	return if self._wolfData then self._wolfData.Stage else "Newborn"
end

--[=[
	Returns the cached current stats.
]=]
function WolfController:GetCurrentStats(): { Hunger: number, Energy: number, Happiness: number }?
	return if self._wolfData then self._wolfData.Stats else nil
end

--[=[
	Returns the cached wolf name.
]=]
function WolfController:GetWolfName(): string
	return if self._wolfData then self._wolfData.Name else ""
end

--[=[
	Returns the stage definition for the current stage.
]=]
function WolfController:GetCurrentStageDef()
	local stage = self:GetCurrentStage()
	return WolfData.Stages[stage]
end

--[=[
	Get the current wolf model.
]=]
function WolfController:GetModel(): Model?
	return self._model
end

--[=[
	Get the current animator.
]=]
function WolfController:GetAnimator(): WolfAnimator.WolfAnimator?
	return self._animator
end

--[=[
	Get current wolf data (cached).
]=]
function WolfController:GetWolfData(): any
	return self._wolfData
end

--[=[
	Set the spawn position for the wolf.
]=]
function WolfController:SetSpawnPosition(cf: CFrame)
	self._spawnPosition = cf
	if self._model then
		self._model:PivotTo(cf)
	end
end

--[=[
	Play a care animation on the wolf.
]=]
function WolfController:PlayCareAnimation(actionName: string)
	if not self._animator then
		return
	end
	if actionName == "Feed" then
		self._animator:PlayEat()
	else
		self._animator:PlayCareReaction(actionName)
	end
end

--[=[
	Play the howl animation.
]=]
function WolfController:PlayHowlAnimation(duration: number?)
	if self._animator then
		self._animator:PlayHowl(duration)
	end
end

return WolfController
