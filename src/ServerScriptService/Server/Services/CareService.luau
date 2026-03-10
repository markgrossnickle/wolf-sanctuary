local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local PlayerDataService
local JournalService

-- Cooldown tracking (server-side, per player per action)
local Cooldowns: { [Player]: { [string]: number } } = {}

-- Care action config
local CARE_ACTIONS = {
	Feed = {
		cooldown = 30,
		statChanges = { Hunger = 30, Energy = 0, Happiness = 10 },
		countPath = "FeedCount",
		firstFlag = "FirstFed",
		journalEntry = "diet_daily_needs",
	},
	Groom = {
		cooldown = 30,
		statChanges = { Hunger = 0, Energy = 20, Happiness = 25 },
		countPath = "GroomCount",
		firstFlag = "FirstGroomed",
		journalEntry = "senses_smell", -- "Winter Survival: Two-Layer Fur" mapped to closest available entry
	},
	Play = {
		cooldown = 30,
		statChanges = { Hunger = -10, Energy = -5, Happiness = 25 },
		countPath = "PlayCount",
		firstFlag = "FirstPlayed",
		journalEntry = "pack_alloparenting", -- "Wolf Pups: Learning Through Play" mapped to closest available entry
	},
}

local CareService = Knit.CreateService({
	Name = "CareService",
	CareActionCompleted = Signal.new(),
	Client = {
		CareActionCompleted = Knit.CreateSignal(),
	},
})

function CareService:KnitInit()
	PlayerDataService = Knit.GetService("PlayerDataService")
	JournalService = Knit.GetService("JournalService")

	local Players = game:GetService("Players")
	Players.PlayerRemoving:Connect(function(player)
		Cooldowns[player] = nil
	end)
end

function CareService:KnitStart() end

--[=[
	Internal: check if an action is on cooldown for a player.
]=]
function CareService:_isOnCooldown(player: Player, action: string): boolean
	local playerCooldowns = Cooldowns[player]
	if not playerCooldowns or not playerCooldowns[action] then
		return false
	end
	return (os.clock() - playerCooldowns[action]) < CARE_ACTIONS[action].cooldown
end

--[=[
	Internal: set cooldown for an action.
]=]
function CareService:_setCooldown(player: Player, action: string)
	if not Cooldowns[player] then
		Cooldowns[player] = {}
	end
	Cooldowns[player][action] = os.clock()
end

--[=[
	Internal: perform a care action.
]=]
function CareService:_performAction(player: Player, actionName: string): (boolean, string?)
	local config = CARE_ACTIONS[actionName]
	if not config then
		return false, "Unknown care action"
	end

	if self:_isOnCooldown(player, actionName) then
		return false, "Action is on cooldown"
	end

	-- Apply stat changes
	local stats = PlayerDataService:Read(player, { "Wolf", "Stats" })
	if not stats then
		return false, "Could not read wolf stats"
	end

	for stat, change in config.statChanges do
		if change ~= 0 then
			local current = stats[stat] or 0
			local newValue = math.clamp(current + change, 0, 100)
			PlayerDataService:Write(player, { "Wolf", "Stats", stat }, newValue)
		end
	end

	-- Update care count
	local currentCount = PlayerDataService:Read(player, { "Care", config.countPath }) or 0
	PlayerDataService:Write(player, { "Care", config.countPath }, currentCount + 1)

	-- Set cooldown
	self:_setCooldown(player, actionName)

	-- Check first-time unlock for journal entry
	local isFirst = PlayerDataService:Read(player, { "Care", config.firstFlag })
	if not isFirst then
		PlayerDataService:Write(player, { "Care", config.firstFlag }, true)
		JournalService:UnlockEntry(player, config.journalEntry)
	end

	-- Fire signals
	self.CareActionCompleted:Fire(player, actionName)
	self.Client.CareActionCompleted:Fire(player, actionName)

	return true, nil
end

function CareService.Client:Feed(player: Player)
	return self.Server:_performAction(player, "Feed")
end

function CareService.Client:Groom(player: Player)
	return self.Server:_performAction(player, "Groom")
end

function CareService.Client:Play(player: Player)
	return self.Server:_performAction(player, "Play")
end

return CareService
