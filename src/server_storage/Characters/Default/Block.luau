local ServerScriptService = game:GetService("ServerScriptService")

local ActionSession = require(ServerScriptService.Server.Utilities.Combat.ActionSession)
local StunService = require(ServerScriptService.Server.Services.StunService)

local MoveUtils = require(ServerScriptService.Server.Utilities.Combat.MoveUtils)

local Block = {}
Block.__index = Block

Block.Anims = 94528668053133

local BlockSessions = {}

function Block.CanBlock(char)
    return MoveUtils:CanPerformAction(char, "Block")
end

function Block:Start(char)
    if not Block.CanBlock(char) then return end
    local session = ActionSession.new({
        attacker = char,
        actionName = "Block",
        actionType = "Misc",
        states = {
            attackerStates = {"Blocking"},
        }
    })

    session:Start()

    session:PlayAndAddAnimation(char, self.Anims, {Priority = 2})
    local stopDebuff = StunService:SpeedDebuff(char, {speed = 5, duration = 999, priority = 1})

    BlockSessions[char] = {
        session = session,
        stopDebuff = stopDebuff
    }
end

function Block:Stop(char)
    if BlockSessions[char] then
        local session = BlockSessions[char].session
        local stopDebuff = BlockSessions[char].stopDebuff
        
        if session then
            session:Stop(true)
            BlockSessions[char].session = nil
        end

        if stopDebuff then
            stopDebuff()
        end
    end
end

return Block