local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ServicesFolder = ServerScriptService.Server.Services
local StunService = require(ServicesFolder.StunService)
local CooldownService = require(ServicesFolder.CooldownService)

local UtilitiesFolder = ServerScriptService.Server.Utilities
local CombatUtils = UtilitiesFolder.Combat
local MoveUtils = require(CombatUtils.MoveUtils)
local ActionSession = require(CombatUtils.ActionSession)
local DamageUtils = require(CombatUtils.DamageUtils)
local Pooling = require(ReplicatedStorage.Shared.Modules.Utilities.Pooling)

local Stomp = {}

local CONFIG = {
    MULTIPLIER = 1.3,
    DURATION = 10,
    COOLDOWN = 30, -- DURATION + ACTUAL COOLDOWN
}

local ASSETS = {
    ANIMATIONS = {
        ATTACKER = 95770090832566,
    },
    VFX = {
       FIRE =  ReplicatedStorage["Assets (New)"].Gabi.FireVFX
    },
}


function Stomp.Run(char, params)
    if not MoveUtils:CanPerformAction(char, script.Name) then return end -- Checks for cooldowns and states

    local session = ActionSession.new({
        attacker = char,
        actionName = script.Name,
        actionType = "Default",
        states = {
            attackerStates = {"CantUse"}
        },
    })

    if not session then return end

    session:Start()

    local track: AnimationTrack = session:PlayAndAddAnimation(char, ASSETS.ANIMATIONS.ATTACKER)

    local stopDebuff = StunService:SpeedDebuff(char, {speed = 0, duration = 999, priority = 3})

    session.extraStopFunction = function()
        stopDebuff()
    end

    local conn = track.Stopped:Connect(function()
        session:Stop()

        DamageUtils:AddDamageMultiplier(char, CONFIG.MULTIPLIER, CONFIG.DURATION)
        CooldownService:SetCooldown(char, script.Name, CONFIG.COOLDOWN)

        local fireFX = Pooling.GetPooledObject(ASSETS.VFX.FIRE)
        fireFX.Parent = char.HumanoidRootPart
        task.delay(CONFIG.DURATION, function()
            Pooling.Return(fireFX, ASSETS.VFX.FIRE)
        end)
    end)

    session:AddConnection(conn)
end

return Stomp