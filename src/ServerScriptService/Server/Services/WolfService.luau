--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local WolfData = require(ReplicatedStorage.Shared.Data.WolfData)

-- How often stats decay (seconds)
local DECAY_INTERVAL = 60

local PlayerDataService

local WolfService = Knit.CreateService({
	Name = "WolfService",
	StageAdvanced = Signal.new(),
	Client = {
		StageAdvanced = Knit.CreateSignal(),
		StatsUpdated = Knit.CreateSignal(),
		WolfNameSet = Knit.CreateSignal(),
	},
})

-- Track last decay time per player
local lastDecayTime: { [Player]: number } = {}

--[=[
	Returns the full wolf data table for a player.
]=]
function WolfService:GetWolfData(player: Player)
	return PlayerDataService:Read(player, { "Wolf" })
end

--[=[
	Sets the wolf's name. Names must be 1-20 characters, letters and spaces only.
]=]
function WolfService:SetWolfName(player: Player, name: string)
	if type(name) ~= "string" then
		return false, "Name must be a string"
	end

	-- Trim whitespace
	name = name:match("^%s*(.-)%s*$") or ""

	if #name < 1 or #name > 20 then
		return false, "Name must be 1-20 characters"
	end

	if not name:match("^[%a%s]+$") then
		return false, "Name can only contain letters and spaces"
	end

	PlayerDataService:Write(player, { "Wolf", "Name" }, name)
	self.Client.WolfNameSet:Fire(player, name)
	return true, "Name set"
end

--[=[
	Feed the wolf — restores hunger.
]=]
function WolfService:FeedWolf(player: Player)
	local stats = PlayerDataService:Read(player, { "Wolf", "Stats" })
	if not stats then
		return
	end

	local careValues = WolfData.CareValues.Feed
	local newHunger = math.min(100, stats.Hunger + careValues.Hunger)
	PlayerDataService:Write(player, { "Wolf", "Stats", "Hunger" }, newHunger)
	self:_fireStatsUpdated(player)
end

--[=[
	Groom the wolf — restores happiness.
]=]
function WolfService:GroomWolf(player: Player)
	local stats = PlayerDataService:Read(player, { "Wolf", "Stats" })
	if not stats then
		return
	end

	local careValues = WolfData.CareValues.Groom
	local newHappiness = math.min(100, stats.Happiness + careValues.Happiness)
	PlayerDataService:Write(player, { "Wolf", "Stats", "Happiness" }, newHappiness)
	self:_fireStatsUpdated(player)
end

--[=[
	Play with the wolf — restores happiness, costs some energy.
]=]
function WolfService:PlayWithWolf(player: Player)
	local stats = PlayerDataService:Read(player, { "Wolf", "Stats" })
	if not stats then
		return
	end

	local careValues = WolfData.CareValues.Play
	local newHappiness = math.min(100, stats.Happiness + careValues.Happiness)
	local newEnergy = math.max(WolfData.MinStatValue, stats.Energy + careValues.Energy)
	PlayerDataService:Write(player, { "Wolf", "Stats", "Happiness" }, newHappiness)
	PlayerDataService:Write(player, { "Wolf", "Stats", "Energy" }, newEnergy)
	self:_fireStatsUpdated(player)
end

--[=[
	Increments the player's play day count. Called once per session.
	Checks if the wolf should advance to the next stage.
]=]
function WolfService:IncrementPlayDay(player: Player)
	local wolf = PlayerDataService:Read(player, { "Wolf" })
	if not wolf then
		return
	end

	local newPlayDays = wolf.PlayDays + 1
	PlayerDataService:Write(player, { "Wolf", "PlayDays" }, newPlayDays)

	-- Check if we should advance stage
	local nextStage = WolfData.GetNextStage(wolf.Stage)
	if nextStage then
		local nextStageDef = WolfData.Stages[nextStage]
		if nextStageDef and newPlayDays >= nextStageDef.PlayDaysRequired then
			self:AdvanceStage(player)
		end
	end
end

--[=[
	Advances the wolf to the next growth stage.
	Fires StageAdvanced signal and awards a journal entry.
]=]
function WolfService:AdvanceStage(player: Player)
	local wolf = PlayerDataService:Read(player, { "Wolf" })
	if not wolf then
		return
	end

	local nextStage = WolfData.GetNextStage(wolf.Stage)
	if not nextStage then
		return -- Already at FullGrown
	end

	local previousStage = wolf.Stage
	PlayerDataService:Write(player, { "Wolf", "Stage" }, nextStage)

	-- Award journal entry for this milestone
	local journalEntryId = "stage_" .. nextStage
	PlayerDataService:Write(player, { "Journal", "UnlockedEntries", journalEntryId }, true)

	-- Fire signals
	local stageDef = WolfData.Stages[nextStage]
	self.StageAdvanced:Fire(player, previousStage, nextStage)
	self.Client.StageAdvanced:Fire(player, previousStage, nextStage, stageDef.FactText)

	print(`{player.Name}'s wolf advanced from {previousStage} to {nextStage}!`)
end

--[=[
	Fires the StatsUpdated signal to the client with current stats.
]=]
function WolfService:_fireStatsUpdated(player: Player)
	local stats = PlayerDataService:Read(player, { "Wolf", "Stats" })
	if stats then
		self.Client.StatsUpdated:Fire(player, stats)
	end
end

--[=[
	Applies stat decay for a single player based on their wolf's stage.
]=]
function WolfService:_decayStats(player: Player)
	local wolf = PlayerDataService:Read(player, { "Wolf" })
	if not wolf then
		return
	end

	local stageDef = WolfData.Stages[wolf.Stage]
	if not stageDef then
		return
	end

	local rates = stageDef.StatDecayRates
	local stats = wolf.Stats
	local changed = false

	local newHunger = math.max(WolfData.MinStatValue, stats.Hunger - rates.Hunger)
	if newHunger ~= stats.Hunger then
		PlayerDataService:Write(player, { "Wolf", "Stats", "Hunger" }, newHunger)
		changed = true
	end

	local newEnergy = math.max(WolfData.MinStatValue, stats.Energy - rates.Energy)
	if newEnergy ~= stats.Energy then
		PlayerDataService:Write(player, { "Wolf", "Stats", "Energy" }, newEnergy)
		changed = true
	end

	local newHappiness = math.max(WolfData.MinStatValue, stats.Happiness - rates.Happiness)
	if newHappiness ~= stats.Happiness then
		PlayerDataService:Write(player, { "Wolf", "Stats", "Happiness" }, newHappiness)
		changed = true
	end

	if changed then
		self:_fireStatsUpdated(player)
	end
end

--[=[
	Stat decay loop — runs every DECAY_INTERVAL seconds per player.
]=]
function WolfService:_startDecayLoop()
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		for _, player in Players:GetPlayers() do
			local lastTime = lastDecayTime[player]
			if lastTime and (now - lastTime) >= DECAY_INTERVAL then
				lastDecayTime[player] = now
				task.spawn(function()
					self:_decayStats(player)
				end)
			end
		end
	end)
end

function WolfService:KnitInit()
	Players.PlayerAdded:Connect(function(player: Player)
		lastDecayTime[player] = os.clock()
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		lastDecayTime[player] = nil
	end)
end

function WolfService:KnitStart()
	PlayerDataService = Knit.GetService("PlayerDataService")
	self:_startDecayLoop()
end

-- Client-exposed methods

function WolfService.Client:GetWolfData(player: Player)
	return self.Server:GetWolfData(player)
end

function WolfService.Client:SetWolfName(player: Player, name: string)
	return self.Server:SetWolfName(player, name)
end

function WolfService.Client:FeedWolf(player: Player)
	return self.Server:FeedWolf(player)
end

function WolfService.Client:GroomWolf(player: Player)
	return self.Server:GroomWolf(player)
end

function WolfService.Client:PlayWithWolf(player: Player)
	return self.Server:PlayWithWolf(player)
end

function WolfService.Client:IncrementPlayDay(player: Player)
	return self.Server:IncrementPlayDay(player)
end

return WolfService
