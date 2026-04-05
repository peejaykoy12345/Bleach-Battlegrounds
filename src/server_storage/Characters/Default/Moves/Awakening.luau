local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local CharacterService = require(ServerScriptService.Server.Services.CharacterService)

return {
    Run = function(char, params)
        local plr = Players:GetPlayerFromCharacter(char)
        if not plr then return end

        local CanStartUltimate = CharacterService:CanStartUltimate(plr)
        print(`Can start ultimate: {CanStartUltimate}`)
        if not CanStartUltimate then return end
        
        CharacterService:StartUltimate(plr)
    end
}