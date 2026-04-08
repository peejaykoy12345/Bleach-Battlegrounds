local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
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

local Kick = {}

local CONFIG = {
    DAMAGE = 2,
    SPEED = 60,
    HITBOX_SIZE = Vector3.new(6, 6, 6),
    HITBOX_OFFSET = CFrame.new(0, 0, -3),
}

local ASSETS = {
    ANIMATIONS = {
        ATTACKER = 97991718036713,
    }
}

function Kick.CreateHitbox(session, hrp, onTouched)
    local plr = Players:GetPlayerFromCharacter(session.attacker)
    if not plr then return end

    local hitboxOffset = CONFIG.HITBOX_OFFSET
    local hb = MoveUtils:CreateHitbox({
        CFrame = hrp.CFrame * hitboxOffset,
        SizeOrPart = Vector3.new(6, 6, 6),
        WeldedPart = hrp,
        WeldOffsetCFrame = hitboxOffset,
        DebounceTime = 0.1,
        UseClient = plr,
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

function Kick.Run(char, params)
    if not MoveUtils:CanPerformAction(char, script.Name) then return end -- Checks for cooldowns and states

    print(script.Name, " is in dev!")

    --[[local session = ActionSession.new({
        attacker = char,
        actionName = script.Name,
        actionType = "Default",
        states = {
            attackerStates = {"CantUse"}
        },
        properties = {
            sharedProperties = {
                
            }
        }
    })

    if not session then return end

    session:Start()
    
    CooldownService:SetCooldown(char, script.Name, 1)]]

    CharacterService:AddUltimateValue(char, 20)
end

return Kick