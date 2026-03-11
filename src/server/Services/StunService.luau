local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local StateManager = require(ServerScriptService.Server.Utilities.Combat.StateManager)

local StunService = Knit.CreateService{
    Name = "StunService",
    Client = {}
}

type stunParams = {
    stunPriority: number,
    stunDuration: number,
    stunSpeed: number
}

local stunStates = {}

function StunService:Stun(char: Model, params: stunParams): () -> ()
	if not char then return function() end end
	local humanoid: Humanoid = char:FindFirstChild("Humanoid")
	if not humanoid then return function() end end

    local speed = params.stunSpeed
    local priority = params.stunPriority
    local time = params.stunDuration

	if not stunStates[char] then
		stunStates[char] = {
			originalSpeed = humanoid.WalkSpeed,
			originalJump = humanoid.JumpHeight,
			currentPriority = -1,
			stopCurrentStun = nil
		}
	end

	if stunStates[char].currentPriority > priority then
		return function() end
	end

	if stunStates[char].stopCurrentStun then
		stunStates[char].stopCurrentStun = nil
	end

	stunStates[char].currentPriority = priority

	humanoid.WalkSpeed = speed
	humanoid.JumpHeight = 0
	StateManager.SetState(char, "Stunned", true)

	local diedConn
	diedConn = humanoid.Died:Connect(function()
		stunStates[char] = nil
		diedConn:Disconnect()
	end)

	local function stopStun()
		if not stunStates[char] then return end

		if stunStates[char].stopCurrentStun == stopStun then
			StateManager.RemoveState(char, "Stunned")
			humanoid.JumpHeight = stunStates[char].originalJump
			humanoid.WalkSpeed = stunStates[char].originalSpeed
			stunStates[char].currentPriority = -1
			stunStates[char].stopCurrentStun = nil
		end
	end

	stunStates[char].stopCurrentStun = stopStun

	task.delay(time, stopStun)
	return stopStun
end

return StunService