local ServerScriptService = game:GetService("ServerScriptService")

local ActionSession = require(ServerScriptService.Server.Utilities.Combat.ActionSession)
local MoveUtils = require(ServerScriptService.Server.Utilities.Combat.MoveUtils)

local StunService = require(ServerScriptService.Server.Services.StunService)

local Run = {}
Run.RunSessions = {}
Run.RunAnimation = 132923954253285

function Run.CanRun(char: Model): boolean
    local CanRun = MoveUtils:CanPerformAction(char, "Run")
    return CanRun
end

function Run:Run(char: Model)
    if not self.CanRun(char) then return end

    local session = ActionSession.new({
        attacker = char,
        actionName = "Run",
        actionType = "Misc",
        states = {
            attackerStates = {"Running"}
        }
    })

    if not session then return end

    self.RunSessions[char] = session

    local stopSpeedBuff = StunService:SpeedDebuff(char, {
        speed = 20,
        duration = 999,
        priority = 2
    })

    session.extraStopFunction = function()
        stopSpeedBuff()
        self.RunSessions[char] = nil
    end

    session:Start()

    local track = session:PlayAndAddAnimation(char, self.RunAnimation)
end

function Run:StopRun(char: Model)
    local session = self.RunSessions[char]
    if not session then return end

    session:Stop(true)
end

return Run