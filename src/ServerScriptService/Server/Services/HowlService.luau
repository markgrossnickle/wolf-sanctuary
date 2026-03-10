local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local HowlData = require(ReplicatedStorage.Shared.Data.HowlData)

local PlayerDataService

-- Cooldown tracking (server-side, per player per howl type)
local Cooldowns: { [Player]: { [string]: number } } = {}

local HowlService = Knit.CreateService({
	Name = "HowlService",
	HowlPerformed = Signal.new(),
	Client = {
		HowlTriggered = Knit.CreateSignal(),
	},
})

function HowlService:KnitInit()
	PlayerDataService = Knit.GetService("PlayerDataService")

	Players.PlayerRemoving:Connect(function(player)
		Cooldowns[player] = nil
	end)
end

function HowlService:KnitStart() end

--[=[
	Check if a howl type is on cooldown for a player.
]=]
function HowlService:_isOnCooldown(player: Player, howlType: string): boolean
	local playerCooldowns = Cooldowns[player]
	if not playerCooldowns or not playerCooldowns[howlType] then
		return false
	end
	local howlDef = HowlData[howlType]
	if not howlDef then
		return true
	end
	return (os.clock() - playerCooldowns[howlType]) < howlDef.cooldown
end

--[=[
	Set cooldown for a howl type.
]=]
function HowlService:_setCooldown(player: Player, howlType: string)
	if not Cooldowns[player] then
		Cooldowns[player] = {}
	end
	Cooldowns[player][howlType] = os.clock()
end

--[=[
	Check if a player has a howl type unlocked.
]=]
function HowlService:IsHowlUnlocked(player: Player, howlType: string): boolean
	local unlocked = PlayerDataService:Read(player, { "Howls", "Unlocked" })
	if not unlocked then
		return false
	end
	-- Howls.Unlocked is an array of strings
	for _, unlockedType in unlocked do
		if unlockedType == howlType then
			return true
		end
	end
	return false
end

--[=[
	Perform a howl. Validates type is unlocked, enforces cooldown, fires to nearby players.
	@param player Player
	@param howlType string
	@return boolean success
	@return string? errorMessage
]=]
function HowlService:PerformHowl(player: Player, howlType: string): (boolean, string?)
	local howlDef = HowlData[howlType]
	if not howlDef then
		return false, "Unknown howl type"
	end

	if not self:IsHowlUnlocked(player, howlType) then
		return false, "Howl type not unlocked"
	end

	if self:_isOnCooldown(player, howlType) then
		return false, "Howl is on cooldown"
	end

	self:_setCooldown(player, howlType)

	-- Get player position for range check
	local character = player.Character
	if not character then
		return false, "No character"
	end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return false, "No root part"
	end

	local origin = rootPart.Position

	-- Fire to all players within range
	for _, otherPlayer in Players:GetPlayers() do
		local otherCharacter = otherPlayer.Character
		if otherCharacter then
			local otherRoot = otherCharacter:FindFirstChild("HumanoidRootPart")
			if otherRoot then
				local distance = (otherRoot.Position - origin).Magnitude
				if distance <= howlDef.range then
					self.Client.HowlTriggered:Fire(otherPlayer, player.Name, howlType, origin)
				end
			end
		end
	end

	self.HowlPerformed:Fire(player, howlType)

	return true, nil
end

function HowlService.Client:PerformHowl(player: Player, howlType: string)
	return self.Server:PerformHowl(player, howlType)
end

function HowlService.Client:IsHowlUnlocked(player: Player, howlType: string)
	return self.Server:IsHowlUnlocked(player, howlType)
end

return HowlService
