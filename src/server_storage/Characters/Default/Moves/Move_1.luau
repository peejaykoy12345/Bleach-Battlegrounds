local ServerScriptService = game:GetService("ServerScriptService")

local ServicesFolder = ServerScriptService.Server.Services
local CharacterService = require(ServicesFolder.CharacterService)
local CooldownService = require(ServicesFolder.CooldownService)

local MoveUtils = require(ServerScriptService.Server.Utilities.Combat.MoveUtils)

local Move_1 = {}

function Move_1.Run(char, params)
    if not MoveUtils:CanPerformAction(char, script.Name) then return end

    print("USED MOVE! Adding ultimate value", char.Name)
    CharacterService:AddUltimateValue(char, 20)
    print("SETTING COOLDOWN! ", char.Name)
    CooldownService:SetCooldown(char, script.Name, 5)
    
end

return Move_1