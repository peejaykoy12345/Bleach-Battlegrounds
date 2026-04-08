local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ServicesFolder = ServerScriptService.Server.Services
local CharacterService = require(ServicesFolder.CharacterService)
local CooldownService = require(ServicesFolder.CooldownService)
local ClientFXService = require(ServicesFolder.ClientFXService)
local AnimationPlayer = require(ReplicatedStorage.Shared.Modules.Utilities.AnimationPlayer)
local StunService = require(ServicesFolder.StunService)
local SoundPlayer = require(ReplicatedStorage.Shared.Modules.Utilities.SoundPlayer)

local UtilitiesFolder = ServerScriptService.Server.Utilities
local CombatUtils = UtilitiesFolder.Combat
local MoveUtils = require(CombatUtils.MoveUtils)
local ActionSession = require(CombatUtils.ActionSession)
local DamageUtils = require(CombatUtils.DamageUtils)
local VelocityUtils = require(CombatUtils.Velocity)
local EffectUtils = require(CombatUtils.EffectUtils)
local Pooling = require(ReplicatedStorage.Shared.Modules.Utilities.Pooling)

local Fireball = {}

local CONFIG = {
    DAMAGE = 20,
    FIREBALL_DURATION = 10,
    EFFECT_DURATION = 5,
    COOLDOWN = 10,
    ULTIMATE_ADDED = 5,
}

local ASSETS = {
    ANIMATIONS = {
        ATTACKER = 98157898468817,
    },
    VFX = {
        Fireball = script.Fireball,
        Activation = ReplicatedStorage["Assets (New)"].Gabi.FireActivationVFX,
    },
}

function Fireball.CreateHitbox(session, fireball, onTouched)
    local hb = MoveUtils:CreateHitbox({
        CFrame = fireball.CFrame,
        SizeOrPart = Vector3.new(6, 6, 6),
        WeldedPart = fireball,
        DebounceTime = 0.1,
        VelocityPredictionFactor = -5,
    })

    hb.HitSomeone:Connect(function(hitChars)
        for _, hitChar in ipairs(hitChars) do
            if not MoveUtils:ValidateHit(session.attacker, hitChar, {Block = {IS_BLOCKABLE = true}}) then continue end

            session:InitTarget(hitChar)
            onTouched(hitChar)
        end
    end)

    hb:Start()

    return hb
end

function Fireball.ApplyLinearVelocity(fireball, direction)
    local lv, att = VelocityUtils.CreateLV(fireball, {
        Velocity = direction * 100,
        Lifetime = CONFIG.FIREBALL_DURATION,
    })

    return lv, att
end

function Fireball.Run(char, params)
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

    ClientFXService:Start({ Name = "EmitParticles", Type = "Combat" }, {
        parent = char.HumanoidRootPart,
        particleContainer = ASSETS.VFX.Activation,
    })

    local fireball: BasePart
    local hb
    local lv
    local att

    local function onTouched(hitChar)
        DamageUtils:ValidateAndDamage(char, hitChar, CONFIG.DAMAGE)
        EffectUtils:ApplyEffect(hitChar, "Fire", CONFIG.EFFECT_DURATION)

        CharacterService:AddUltimateValue(char, CONFIG.ULTIMATE_ADDED)

        if fireball then
            Pooling.Return(fireball, ASSETS.VFX.Fireball)
        end

        if att then
            att:Destroy()
        end

        if lv then
            lv:Destroy()
        end

        if hb then
            hb:Stop()
        end
    end

    local hrp = char.HumanoidRootPart

    local markers = {
        ["Fireball"] = function()
            fireball = Pooling.GetPooledObject(ASSETS.VFX.Fireball)
            fireball.Massless = true
            fireball.CFrame = char.Head.CFrame * CFrame.new(0, 0, -2)
            
            lv, att = Fireball.ApplyLinearVelocity(fireball, hrp.CFrame.LookVector)
            hb = Fireball.CreateHitbox(session, fireball, onTouched)

            fireball.Parent = workspace.Assets.VFX

            task.delay(CONFIG.FIREBALL_DURATION, function()
                Pooling.Return(fireball, ASSETS.VFX.Fireball)
            end)
        end,
    }

    local connections = MoveUtils:ConnectAnimationMarkers(track, markers)
    session:BulkAddConnections(connections)

    local stopDebuff = StunService:SpeedDebuff(char, {
        speed = 0,
        priority = 3,
        duration = 999,
    })

    session.extraStopFunction = function()
        stopDebuff()
        CooldownService:SetCooldown(char, script.Name, CONFIG.COOLDOWN)
    end

    local conn = track.Stopped:Connect(function()
        session:Stop()
    end)

    session:AddConnection(conn)
end

return Fireball