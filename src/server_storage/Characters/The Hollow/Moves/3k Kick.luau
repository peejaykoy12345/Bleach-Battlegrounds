local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ServicesFolder = ServerScriptService.Server.Services
local Velocity = require(ServerScriptService.Server.Utilities.Combat.Velocity)
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
        ATTACKER = 104295996856823,
    },
    VFX = {
        HIT = ReplicatedStorage["Assets (New)"].Gabi["Triple Kick"]
    }
}

function Kick.CreateHitbox(session, hrp, onTouched, debounce)
    local plr = Players:GetPlayerFromCharacter(session.attacker)
    if not plr then return end

    local hitboxOffset = CONFIG.HITBOX_OFFSET
    local hb = MoveUtils:CreateHitbox({
        CFrame = hrp.CFrame * hitboxOffset,
        SizeOrPart = Vector3.new(6, 6, 6),
        WeldedPart = hrp,
        WeldOffsetCFrame = hitboxOffset,
        DebounceTime = debounce,
        --UseClient = plr,
    })

    table.insert(session.hitboxes, hb)

    hb.HitSomeone:Connect(function(hitChars)
        for _, hitChar in ipairs(hitChars) do
            if not MoveUtils:ValidateHit(session.attacker, hitChar, {Block = {Blockable = true}}) then continue end
            local ehrp = hitChar:FindFirstChild("HumanoidRootPart")
            if not ehrp then return end

            session:InitTarget(hitChar)
            onTouched(hitChar, ehrp)
        end
    end)

    hb:Start()
end

function Kick.Run(char, params)
    if not MoveUtils:CanPerformAction(char, script.Name) then return end -- Checks for cooldowns and states
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local session = ActionSession.new({
        attacker = char,
        actionName = script.Name,
        actionType = "Default",
        states = {
            sharedStates = {"CantUse"}
        },
        properties = {
            targetProperties = {
                AutoRotate = false,
            }
        }
    })

    if not session then return end

    session:Start()

    local track: AnimationTrack = session:PlayAndAddAnimation(char, ASSETS.ANIMATIONS.ATTACKER)

    local lv = Velocity.CreateLV(hrp, {RelativeTo = "Attachment", Velocity = Vector3.new(0, 0, -1) * 50})
    lv.ForceLimitMode = Enum.ForceLimitMode.PerAxis
    lv.MaxAxesForce = Vector3.new(math.huge, 0, math.huge)

    local conn = track.Stopped:Connect(function()
        session:Stop()
    end)

    local function onWeldTouched(hitChar, ehrp)
        local weld = session:WeldParts(hrp, ehrp, "Weld")
        weld.C1 = CFrame.new(0, 0, -3) * CFrame.Angles(0, math.rad(180), 0)

        if lv then
            local mass = MoveUtils:GetModelMass(hitChar)
            lv.VectorVelocity = lv.VectorVelocity + Vector3.new(0, 0, -1) * mass
        end
    end

    local function onTouched(hitChar, ehrp)
        DamageUtils:ValidateAndDamage(char, hitChar, CONFIG.DAMAGE)
        CharacterService:AddUltimateValue(char, 2)

        ClientFXService:Start(
            {
            Name = "EmitParticles",
            Type = "Combat",
            },
            {
                parent = ehrp,
                particleContainer = ASSETS.VFX.HIT,
            }
        )
    end

    local markers = {
        ["KickStart"] = function()
            Kick.CreateHitbox(session, hrp, onWeldTouched)
            Kick.CreateHitbox(session, hrp, onTouched, 0.1)
        end
    }

    local connections = MoveUtils:ConnectAnimationMarkers(track, markers)

    session:AddConnection(conn)
    session:BulkAddConnections(connections)
    
    session.extraStopFunction = function()
        CooldownService:SetCooldown(char, script.Name, 1)
       lv:Destroy()
       lv = nil
    end
end

return Kick