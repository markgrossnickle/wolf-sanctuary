local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local HowlData = require(ReplicatedStorage.Shared.Data.HowlData)

local HowlController = Knit.CreateController({
	Name = "HowlController",
	HowlTriggered = Signal.new(), -- (playerName, howlType, position)
})

HowlController._cooldowns = {} :: { [string]: number }

function HowlController:KnitInit() end

function HowlController:KnitStart()
	local HowlService = Knit.GetService("HowlService")

	HowlService.HowlTriggered:Connect(function(playerName, howlType, position)
		self.HowlTriggered:Fire(playerName, howlType, position)
	end)
end

--[=[
	Get all howl type definitions for the howl wheel UI.
	@return { [string]: HowlData.HowlDefinition }
]=]
function HowlController:GetHowlTypes()
	return HowlData
end

--[=[
	Check if a howl type is on cooldown (client-side estimate).
	@param howlType string
	@return boolean
]=]
function HowlController:IsOnCooldown(howlType: string): boolean
	local lastUsed = self._cooldowns[howlType]
	if not lastUsed then
		return false
	end
	local howlDef = HowlData[howlType]
	if not howlDef then
		return true
	end
	return (os.clock() - lastUsed) < howlDef.cooldown
end

--[=[
	Get remaining cooldown time in seconds.
	@param howlType string
	@return number
]=]
function HowlController:GetCooldownRemaining(howlType: string): number
	local lastUsed = self._cooldowns[howlType]
	if not lastUsed then
		return 0
	end
	local howlDef = HowlData[howlType]
	if not howlDef then
		return 0
	end
	local remaining = howlDef.cooldown - (os.clock() - lastUsed)
	return math.max(0, remaining)
end

--[=[
	Trigger a howl on the server.
	@param howlType string
	@return boolean success
	@return string? errorMessage
]=]
function HowlController:PerformHowl(howlType: string): (boolean, string?)
	if self:IsOnCooldown(howlType) then
		return false, "Howl is on cooldown"
	end

	local HowlService = Knit.GetService("HowlService")
	local ok, result = HowlService:PerformHowl(howlType):await()
	if not ok then
		return false, "Request failed"
	end

	-- Set client-side cooldown on success
	if result then
		self._cooldowns[howlType] = os.clock()
	end

	return result
end

return HowlController
