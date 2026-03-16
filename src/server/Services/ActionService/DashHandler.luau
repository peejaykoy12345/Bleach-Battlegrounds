local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local module = {}

function module:HandleAction(plr: Player, params)
    local Default = require(ServerStorage.ServerStorage.Characters.Default.Dash)

    local char = plr.Character
    if not char then return end

    if not Default.CanDash(char) then return end

    Default:Dash(char, params.dir)
end

return module