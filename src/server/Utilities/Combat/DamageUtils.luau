local ServerScriptService = game:GetService("ServerScriptService")

local ClientFXService = require(ServerScriptService.Server.Services.ClientFXService)

local Utils = {}

function Utils:ValidateAndDamage(attacker: Model, target: Model, damage: number)
    if attacker == target then return end
    if not target:FindFirstChild("Humanoid") then return end

    local humanoid = target.Humanoid
    humanoid:TakeDamage(damage)

    ClientFXService:Start({ Name = "Hit", Type = "Combat" }, { target = target })
end

return Utils