local Utils = require(script.Parent.Utils)

local AbilityHandler = {}

function AbilityHandler:HandleAction(plr: Player, params)
    local char = plr.Character
    if not char then return end

    local characterName = char:GetAttribute("Character")
    local isUltimate = char:GetAttribute("IsUltimate")

    local moves = Utils.GetCharacterMoves(characterName, isUltimate)
    if moves[params.input] then
        local module = require(moves[params.input])
        if module.Run then
            module.Run(char, params)
        else
            warn(`{moves[params.input].Name} does not have a .Run function`)
        end
    else
        warn(`{characterName} does not support {params.input} module`)
    end
end

return AbilityHandler