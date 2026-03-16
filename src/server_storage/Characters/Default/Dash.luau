local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ActionSession = require(ServerScriptService.Server.Utilities.Combat.ActionSession)
local MoveUtils = require(ServerScriptService.Server.Utilities.Combat.MoveUtils)

local remotes = require(ReplicatedStorage.Packages.remotes)

local DashEvent: RemoteEvent = remotes:getEventAsync("Dash")

local Dash = {}
Dash.__index = Dash

Dash.Anims = {
    Forward = 119388231419633,
    Backward = 112379928777464,
    Left = 131268823739939,
    Right = 86975962496064,
}

function Dash.CanDash(char: Model): boolean
    return MoveUtils:CanPerformAction(char, "Dash")
end

function Dash:Dash(char: Model, dir: string)
    if not self.CanDash(char) then return end

    print(dir)

    local session = ActionSession.new({
        attacker = char,
        actionName = "Dash",
        actionType = "Misc",
        cooldown = {
            cooldown = 1
        },
        states = {
            attackerStates = {"CantUse"}
        }
    })

    if not session then return end

    local track = session:PlayAndAddAnimation(char, Dash.Anims[dir])
    track.Ended:Connect(function()
        session:Stop()
    end)

    local plr = Players:GetPlayerFromCharacter(char)
    if not plr then return end

    DashEvent:FireClient(plr, dir)
end

return Dash