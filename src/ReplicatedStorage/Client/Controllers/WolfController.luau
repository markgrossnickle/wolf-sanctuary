--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local WolfData = require(ReplicatedStorage.Shared.Data.WolfData)

local WolfController = Knit.CreateController({
	Name = "WolfController",
})

-- Cached wolf state
local cachedStage: string = "Newborn"
local cachedStats: { Hunger: number, Energy: number, Happiness: number }? = nil
local cachedWolfName: string = ""

--[=[
	Returns the cached current stage.
]=]
function WolfController:GetCurrentStage(): string
	return cachedStage
end

--[=[
	Returns the cached current stats, or nil if not yet loaded.
]=]
function WolfController:GetCurrentStats(): { Hunger: number, Energy: number, Happiness: number }?
	return cachedStats
end

--[=[
	Returns the cached wolf name.
]=]
function WolfController:GetWolfName(): string
	return cachedWolfName
end

--[=[
	Returns the stage definition for the current stage.
]=]
function WolfController:GetCurrentStageDef()
	return WolfData.Stages[cachedStage]
end

function WolfController:KnitInit() end

function WolfController:KnitStart()
	local WolfService = Knit.GetService("WolfService")

	-- Listen for stage advancement
	WolfService.StageAdvanced:Connect(function(previousStage: string, newStage: string, factText: string)
		cachedStage = newStage
		local stageDef = WolfData.Stages[newStage]
		if stageDef then
			print(`[WolfController] Stage advanced: {previousStage} -> {newStage}`)
			print(`[WolfController] Fact: {factText}`)
			print(`[WolfController] Unlocked: {stageDef.UnlocksDescription}`)
			-- TODO: Show celebration UI notification
		end
	end)

	-- Listen for stats updates
	WolfService.StatsUpdated:Connect(function(stats)
		cachedStats = stats
		-- TODO: Update HUD with new stats
	end)

	-- Listen for wolf name changes
	WolfService.WolfNameSet:Connect(function(name: string)
		cachedWolfName = name
	end)

	-- Request initial wolf data from server
	task.spawn(function()
		local ok, wolfData = WolfService:GetWolfData():await()
		if ok and wolfData then
			cachedStage = wolfData.Stage
			cachedStats = wolfData.Stats
			cachedWolfName = wolfData.Name
			print(`[WolfController] Loaded wolf: stage={cachedStage}, name={cachedWolfName}`)
		else
			warn("[WolfController] Failed to load wolf data")
		end

		-- Increment play day for this session
		WolfService:IncrementPlayDay()
	end)
end

return WolfController
