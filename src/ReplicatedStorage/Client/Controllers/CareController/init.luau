local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

-- Client-side cooldown tracking for UI display
local COOLDOWN_DURATION = 30

local CareController = Knit.CreateController({
	Name = "CareController",
	CareActionCompleted = Signal.new(), -- (actionName)
})

CareController._cooldowns = {} :: { [string]: number }

function CareController:KnitInit() end

function CareController:KnitStart()
	local CareService = Knit.GetService("CareService")

	CareService.CareActionCompleted:Connect(function(actionName)
		self._cooldowns[actionName] = os.clock()
		self.CareActionCompleted:Fire(actionName)
	end)
end

--[=[
	Check if an action is on cooldown (client-side estimate for UI).
	@param actionName string
	@return boolean
]=]
function CareController:IsOnCooldown(actionName: string): boolean
	local lastUsed = self._cooldowns[actionName]
	if not lastUsed then
		return false
	end
	return (os.clock() - lastUsed) < COOLDOWN_DURATION
end

--[=[
	Get remaining cooldown time in seconds.
	@param actionName string
	@return number
]=]
function CareController:GetCooldownRemaining(actionName: string): number
	local lastUsed = self._cooldowns[actionName]
	if not lastUsed then
		return 0
	end
	local remaining = COOLDOWN_DURATION - (os.clock() - lastUsed)
	return math.max(0, remaining)
end

--[=[
	Request a Feed action from the server.
	@return boolean success
	@return string? errorMessage
]=]
function CareController:Feed(): (boolean, string?)
	if self:IsOnCooldown("Feed") then
		return false, "Feed is on cooldown"
	end
	local CareService = Knit.GetService("CareService")
	local ok, result = CareService:Feed():await()
	if not ok then
		return false, "Request failed"
	end
	return result
end

--[=[
	Request a Groom action from the server.
	@return boolean success
	@return string? errorMessage
]=]
function CareController:Groom(): (boolean, string?)
	if self:IsOnCooldown("Groom") then
		return false, "Groom is on cooldown"
	end
	local CareService = Knit.GetService("CareService")
	local ok, result = CareService:Groom():await()
	if not ok then
		return false, "Request failed"
	end
	return result
end

--[=[
	Request a Play action from the server.
	@return boolean success
	@return string? errorMessage
]=]
function CareController:Play(): (boolean, string?)
	if self:IsOnCooldown("Play") then
		return false, "Play is on cooldown"
	end
	local CareService = Knit.GetService("CareService")
	local ok, result = CareService:Play():await()
	if not ok then
		return false, "Request failed"
	end
	return result
end

return CareController
