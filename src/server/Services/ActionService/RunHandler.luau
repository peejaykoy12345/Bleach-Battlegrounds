local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local RunHandler = {}

local DefaultRun = require(ServerStorage.ServerStorage.Characters.Default.Run)

function RunHandler:HandleAction(plr: Player, params)
    params = params or {}

    local run = params.run

    local char = plr.Character
    if not char then return end

    self:StartRunning(char, run)
end

function RunHandler:StartRunning(char: Model, run)
    if run then
        DefaultRun:Run(char)
    else
        DefaultRun:StopRun(char)
    end
end

function RunHandler:StopAction(char: Model, params)
    DefaultRun:StopRun(char)
end

function RunHandler:WasRunning(char: Model)
    return DefaultRun.RunSessions ~= nil
end

return RunHandler