local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local RunHandler = {}

local Utils = require(script.Parent.Utils)

function RunHandler:HandleAction(plr: Player, params)
    params = params or {}

    local run = params.run

    local char = plr.Character
    if not char then return end

    self:StartRunning(char, run)
end

function RunHandler:StartRunning(char: Model, run)
    local characterName = char:GetAttribute("Character")
    local module = require(Utils.GetCharacterModule(characterName, "Run"))
    
    if run then
        module:Run(char)
    else
        module:StopRun(char)
    end
end

function RunHandler:StopAction(char: Model, params)
    local characterName = char:GetAttribute("Character")
    local module = require(Utils.GetCharacterModule(characterName, "Run"))

    module:StopRun(char)
end

function RunHandler:WasRunning(char: Model)
    local characterName = char:GetAttribute("Character")
    local module = require(Utils.GetCharacterModule(characterName, "Run"))

    return module.RunSessions[char] ~= nil
end

return RunHandler