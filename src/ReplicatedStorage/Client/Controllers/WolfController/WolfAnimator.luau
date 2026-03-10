--!strict
--[=[
	@class WolfAnimator
	Procedural wolf animations using TweenService.
	Idle breathing, tail wag, walking, howling, and care reactions.
]=]

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local WolfAnimator = {}
WolfAnimator.__index = WolfAnimator

export type WolfAnimator = typeof(setmetatable(
	{} :: {
		_model: Model,
		_running: boolean,
		_currentAnim: string,
		_connections: { RBXScriptConnection },
		_originalCFrames: { [string]: CFrame },
	},
	WolfAnimator
))

--[=[
	Create a new WolfAnimator for a model.
]=]
function WolfAnimator.new(model: Model): WolfAnimator
	local self = setmetatable({}, WolfAnimator)
	self._model = model
	self._running = false
	self._currentAnim = "none"
	self._connections = {}
	self._originalCFrames = {}

	-- Store original local CFrames for resetting
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			self._originalCFrames[part.Name] = part.CFrame
		end
	end

	return self
end

--[=[
	Stop all running animations.
]=]
function WolfAnimator:Stop()
	self._running = false
	self._currentAnim = "none"
	for _, conn in self._connections do
		conn:Disconnect()
	end
	table.clear(self._connections)
end

--[=[
	Destroy the animator and clean up.
]=]
function WolfAnimator:Destroy()
	self:Stop()
	table.clear(self._originalCFrames)
end

-- ============================================================================
-- Idle Animation (breathing + subtle tail wag)
-- ============================================================================

function WolfAnimator:PlayIdle()
	if self._currentAnim == "idle" then
		return
	end
	self:Stop()
	self._currentAnim = "idle"
	self._running = true

	local model = self._model
	local body = model:FindFirstChild("Body") :: BasePart?
	local tailBase = model:FindFirstChild("TailBase") :: BasePart?

	if not body then
		return
	end

	-- Breathing cycle
	local breathTime = 0
	local conn = RunService.Heartbeat:Connect(function(dt)
		if not self._running then
			return
		end
		breathTime += dt

		-- Subtle body rise/fall (breathing)
		if body and body.Parent then
			local breathOffset = math.sin(breathTime * 1.5) * 0.05
			body.CFrame = body.CFrame * CFrame.new(0, breathOffset * dt * 2, 0)
		end

		-- Tail wag (gentle sway)
		if tailBase and tailBase.Parent then
			local wagAngle = math.sin(breathTime * 3) * math.rad(8)
			local currentCF = tailBase.CFrame
			tailBase.CFrame = currentCF * CFrame.Angles(0, wagAngle * dt * 2, 0)
		end
	end)
	table.insert(self._connections, conn)
end

-- ============================================================================
-- Walk Animation (leg cycling)
-- ============================================================================

function WolfAnimator:PlayWalk()
	if self._currentAnim == "walk" then
		return
	end
	self:Stop()
	self._currentAnim = "walk"
	self._running = true

	local model = self._model
	local walkTime = 0

	local frontLeftLeg = model:FindFirstChild("FrontLeftLeg") :: BasePart?
	local frontRightLeg = model:FindFirstChild("FrontRightLeg") :: BasePart?
	local backLeftLeg = model:FindFirstChild("BackLeftLeg") :: BasePart?
	local backRightLeg = model:FindFirstChild("BackRightLeg") :: BasePart?
	local body = model:FindFirstChild("Body") :: BasePart?

	local conn = RunService.Heartbeat:Connect(function(dt)
		if not self._running then
			return
		end
		walkTime += dt

		local speed = 6
		local amplitude = math.rad(20)

		-- Diagonal gait: front-left with back-right, front-right with back-left
		local phase1 = math.sin(walkTime * speed) * amplitude
		local phase2 = math.sin(walkTime * speed + math.pi) * amplitude

		if frontLeftLeg and frontLeftLeg.Parent then
			local cf = frontLeftLeg.CFrame
			frontLeftLeg.CFrame = cf * CFrame.Angles(0, 0, phase1 * dt * 4)
		end
		if backRightLeg and backRightLeg.Parent then
			local cf = backRightLeg.CFrame
			backRightLeg.CFrame = cf * CFrame.Angles(0, 0, phase1 * dt * 4)
		end
		if frontRightLeg and frontRightLeg.Parent then
			local cf = frontRightLeg.CFrame
			frontRightLeg.CFrame = cf * CFrame.Angles(0, 0, phase2 * dt * 4)
		end
		if backLeftLeg and backLeftLeg.Parent then
			local cf = backLeftLeg.CFrame
			backLeftLeg.CFrame = cf * CFrame.Angles(0, 0, phase2 * dt * 4)
		end

		-- Subtle body bob
		if body and body.Parent then
			local bob = math.sin(walkTime * speed * 2) * 0.03
			body.CFrame = body.CFrame * CFrame.new(0, bob * dt * 3, 0)
		end
	end)
	table.insert(self._connections, conn)
end

-- ============================================================================
-- Howl Animation (head tilt up)
-- ============================================================================

function WolfAnimator:PlayHowl(duration: number?)
	self:Stop()
	self._currentAnim = "howl"
	self._running = true

	local model = self._model
	local head = model:FindFirstChild("Head") :: BasePart?
	local _snout = model:FindFirstChild("Snout") :: BasePart?

	if not head then
		return
	end

	local howlDuration = duration or 3.0
	local tiltUp = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local holdTime = howlDuration - 1.0
	local tiltDown = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	-- Tilt head up
	local headOriginal = head.CFrame
	local headTilted = headOriginal * CFrame.Angles(0, 0, math.rad(35))

	local tween1 = TweenService:Create(head, tiltUp, { CFrame = headTilted })
	tween1:Play()

	task.delay(0.5 + holdTime, function()
		if not self._running or self._currentAnim ~= "howl" then
			return
		end
		-- Tilt back down
		local tween2 = TweenService:Create(head, tiltDown, { CFrame = headOriginal })
		tween2:Play()
		tween2.Completed:Wait()
		if self._currentAnim == "howl" then
			self:PlayIdle()
		end
	end)
end

-- ============================================================================
-- Care Reaction (happy response — tail wag speeds up, body bounce)
-- ============================================================================

function WolfAnimator:PlayCareReaction(_actionName: string)
	self:Stop()
	self._currentAnim = "care"
	self._running = true

	local model = self._model
	local body = model:FindFirstChild("Body") :: BasePart?
	local tailBase = model:FindFirstChild("TailBase") :: BasePart?

	if not body then
		return
	end

	local reactTime = 0
	local reactionDuration = 2.0

	local conn = RunService.Heartbeat:Connect(function(dt)
		if not self._running then
			return
		end
		reactTime += dt

		if reactTime > reactionDuration then
			self:PlayIdle()
			return
		end

		-- Fast excited tail wag
		if tailBase and tailBase.Parent then
			local wagAngle = math.sin(reactTime * 12) * math.rad(25)
			local cf = tailBase.CFrame
			tailBase.CFrame = cf * CFrame.Angles(0, wagAngle * dt * 4, 0)
		end

		-- Happy bounce
		if body and body.Parent then
			local bounce = math.abs(math.sin(reactTime * 8)) * 0.08
			body.CFrame = body.CFrame * CFrame.new(0, bounce * dt * 3, 0)
		end
	end)
	table.insert(self._connections, conn)
end

-- ============================================================================
-- Eat Animation (head down, chewing motion)
-- ============================================================================

function WolfAnimator:PlayEat()
	self:Stop()
	self._currentAnim = "eat"
	self._running = true

	local model = self._model
	local head = model:FindFirstChild("Head") :: BasePart?

	if not head then
		return
	end

	local eatTime = 0
	local eatDuration = 2.5

	-- Dip head down
	local headOriginal = head.CFrame
	local headDown = headOriginal * CFrame.Angles(0, 0, math.rad(-25))
	local tweenDown = TweenService:Create(head, TweenInfo.new(0.4), { CFrame = headDown })
	tweenDown:Play()

	local conn = RunService.Heartbeat:Connect(function(dt)
		if not self._running then
			return
		end
		eatTime += dt

		if eatTime > eatDuration then
			-- Lift head back up
			local tweenUp = TweenService:Create(head, TweenInfo.new(0.3), { CFrame = headOriginal })
			tweenUp:Play()
			tweenUp.Completed:Wait()
			if self._currentAnim == "eat" then
				self:PlayIdle()
			end
			return
		end

		-- Chewing bob (small up/down on head)
		if head and head.Parent then
			local chewBob = math.sin(eatTime * 10) * 0.02
			head.CFrame = head.CFrame * CFrame.new(0, chewBob * dt * 5, 0)
		end
	end)
	table.insert(self._connections, conn)
end

return WolfAnimator
