local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local Utils = require(script.Parent.Utils)

local BlockHandler = {}
BlockHandler.__index = BlockHandler

function BlockHandler:_HandleBlock(char, params)
    local characterName = char:GetAttribute("Character")
    local module = require(Utils.GetCharacterModule(characterName, "Block"))

    local isHold = params.isHold
    if isHold then
        module:Start(char)
    else
        module:Stop(char)
    end
end

function BlockHandler:HandleAction(plr: Player, params)
    params = params or {}

    local char = plr.Character
    if not char then return end

    self:_HandleBlock(char, params)
end

return BlockHandler