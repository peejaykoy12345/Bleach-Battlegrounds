local ServerScriptService = game:GetService("ServerScriptService")

local ServicesFolder = ServerScriptService.Server.Services
local CooldownService = require(ServicesFolder.CooldownService)

local MoveUtils = require(ServerScriptService.Server.Utilities.Combat.MoveUtils)

local Ultimate_Move_1 = {}

function Ultimate_Move_1.Run(char, params)
    if not MoveUtils:CanPerformAction(char, script.Name) then return end

    print("Used ultimate move!", char.Name)
    print("SETTING COOLDOWN! ", char.Name)
    CooldownService:SetCooldown(char, script.Name, 2)
end

return Ultimate_Move_1