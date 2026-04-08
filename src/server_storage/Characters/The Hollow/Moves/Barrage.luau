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

local Barrage = {}

local CONFIG = {
    MOVE_DURATION = 2,
    DAMAGE = 2,
    SPEED_DEBUFF = 2,
    COOLDOWN = 5,
    HITBOX_OFFSET = CFrame.new(0, 0, -3),
    IS_BLOCKABLE = true
}

local ASSETS = {
    ANIMATIONS = {
        ATTACKER = 78964918985343,
        TARGET = {
            [1] = 107787809160749,
            [2] = 84083069819396,
            [3] = 135412824644606,
            [4] = 81715699171439,
        }
    },
    SFX = {
        SWING = 686669695,
        HIT = 281156569,
    }
}

function Barrage.CreateHitbox(session, hrp, onTouched)
    local hitboxOffset = CONFIG.HITBOX_OFFSET
    local hb = MoveUtils:CreateHitbox({
        CFrame = hrp.CFrame * hitboxOffset,
        SizeOrPart = Vector3.new(6, 6, 6),
        WeldedPart = hrp,
        WeldOffsetCFrame = hitboxOffset,
        DebounceTime = 0.1,
    })

    session.hitbox = hb

    hb.HitSomeone:Connect(function(hitChars)
        for _, hitChar in ipairs(hitChars) do
            if not MoveUtils:ValidateHit(session.attacker, hitChar, {Block = {Blockable = true}}) then continue end

            session:InitTarget(hitChar)
            onTouched(hitChar)
        end
    end)

    hb:Start()
end

function Barrage.Run(char, params)
    if not MoveUtils:CanPerformAction(char, script.Name) then return end -- Checks for cooldowns and states

    local session = ActionSession.new({
        attacker = char,
        actionName = script.Name,
        actionType = "Default",
        states = {
            attackerStates = {
                "CantUse"
            },
        }
    })

    if not session then return end

    session:Start()

    local hrp = char:WaitForChild("HumanoidRootPart")

    local track = session:PlayAndAddAnimation(char, ASSETS.ANIMATIONS.ATTACKER)
    local stopDebuff = StunService:SpeedDebuff(char, {speed = 4, duration = 999, priority = 3})
    
    session.extraStopFunction = function()
        CooldownService:SetCooldown(char, script.Name, CONFIG.COOLDOWN)
        stopDebuff()

        AnimationPlayer:StopAnimation(track)
    end

    SoundPlayer:Play(ASSETS.SFX.SWING, char)

    local function onTouched(hitChar)
        DamageUtils:ValidateAndDamage(char, hitChar, CONFIG.DAMAGE)

        local sound = SoundPlayer:LoadSound(ASSETS.SFX.HIT, hitChar)

        StunService:Stun(hitChar, {stunSpeed = 0, stunDuration = 0.5, stunPriority = 4})
        local randomHitAnimIndex = math.random(1, #ASSETS.ANIMATIONS.TARGET)
        local randomHitAnim = ASSETS.ANIMATIONS.TARGET[randomHitAnimIndex]

        MoveUtils:FacePlayer(hitChar.HumanoidRootPart, hrp)

        AnimationPlayer:Play(hitChar, randomHitAnim)

        sound:Play()
        Debris:AddItem(sound, .5)
    end

    Barrage.CreateHitbox(session, hrp, onTouched)

    task.delay(CONFIG.MOVE_DURATION, function()
        session:Stop()
    end)
end

return Barrage