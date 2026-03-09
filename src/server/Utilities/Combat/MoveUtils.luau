local ServerScriptService = game:GetService("ServerScriptService")

local UtilitiesFolder = ServerScriptService.Server.Utilities
local CombatUtilities = UtilitiesFolder.Combat
local Hitbox = require(CombatUtilities.Hitbox)
local CooldownService = require(ServerScriptService.Server.Services.CooldownService)

local MoveUtils = {}

function MoveUtils:CreateStandardHitbox(config)
	config = config or {}

	local hitbox = Hitbox.CreateHitbox()
	hitbox.Size = config.SIZE or Vector3.new(4, 4, 4)
	hitbox.CFrame = config.CFrame or CFrame.new(0, 0, 0)
	hitbox.Visualizer =  config.VISUALIZER ~= false 
	return hitbox
end

function MoveUtils:CanPerformAction(plr: Player, actionName: string): boolean
	if CooldownService:IsOnCooldown(plr, actionName) then
		return false
	end

	return true
end

return MoveUtils