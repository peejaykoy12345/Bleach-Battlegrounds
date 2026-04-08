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
local Velocity = require(CombatUtils.Velocity)
local Hover = require(ReplicatedStorage.Shared.Modules.Utilities.Hover)
local Pooling = require(ReplicatedStorage.Shared.Modules.Utilities.Pooling)

local Stomp = {}

local CONFIG = {
    STOMP_DAMAGE = 5,
    KICK_DAMAGE = 10,
    KNOCKBACK = {
        ZAxis = 25,
        YAxis = 15,
    },
    HITBOX = {
        LAUNCH = Vector3.new(10, 10, 10),
        HIT = Vector3.new(4, 4, 4),
    },
    IS_BLOCKABLE = false,
    COOLDOWN = 10,
}

local ASSETS = {
    ANIMATIONS = {
        ATTACKER = 79992048107494,
    },
    VFX = {
        STOMP = ReplicatedStorage["Assets (New)"].Gabi.Slam,
    },
}

function Stomp.CreateHitbox(session, hrp, offset, size, onTouched)
    local hitbox = MoveUtils:CreateHitbox({
        CFrame = hrp.CFrame * offset,
        SizeOrPart = size,
        WeldedPart = hrp,
        WeldOffsetCFrame = offset,
    })

    table.insert(session.hitboxes, hitbox)
    hitbox.HitSomeone:Connect(function(hitChars)
        for _, hitChar in ipairs(hitChars) do
            if not MoveUtils:ValidateHit(session.attacker, hitChar, {BLOCK = {IS_BLOCKABLE = CONFIG.IS_BLOCKABLE}}) then continue end

            local ehrp = hitChar:FindFirstChild("HumanoidRootPart")
            if not ehrp then return end

            session:InitTarget(hitChar)

            onTouched(hitChar, ehrp)
        end
    end)

    hitbox:Start()

    return hitbox
end

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

    local track = session:PlayAndAddAnimation(char, ASSETS.ANIMATIONS.ATTACKER)

    local stopDebuff = StunService:SpeedDebuff(char, {speed = 0, duration = 999, priority = 3})

    local hrp = char:WaitForChild("HumanoidRootPart")

    local alreadyLaunched = false

    local launchHitbox

    local stomp = Pooling.GetPooledObject(ASSETS.VFX.STOMP)
    stomp.Parent = char["Right Leg"]
    MoveUtils:EmitEveryParticleEmitter(stomp)

    local markers = {
        ["Launch"] = function()
            local function onTouchLaunchHitbox(hitChar)
                Hover:AsyncToggle(hitChar, true, 1)

                DamageUtils:ValidateAndDamage(char, hitChar, CONFIG.STOMP_DAMAGE)
                StunService:Stun(hitChar, {stunPriority = 4, stunSpeed = 0, stunDuration = 1})

                if not alreadyLaunched then
                    alreadyLaunched = true
                    Hover:AsyncToggle(char, true, 1)
                end
            end

            CharacterService:AddUltimateValue(char, 5)

            launchHitbox = Stomp.CreateHitbox(session, hrp, CFrame.new(0, 0, 0), CONFIG.HITBOX.LAUNCH, onTouchLaunchHitbox)
        end,
        ["EarlyEnd"] = function()
            launchHitbox:Stop()
            if alreadyLaunched then return end

            Pooling.Return(stomp, ASSETS.VFX.STOMP)
            session:Stop()
        end,
        ["Hit"] = function()
            local function onTouched(hitChar, ehrp)
                MoveUtils:RagdollCharacter(hitChar, 2)
                local bv = Velocity.CreateBV(ehrp, Vector3.new(math.huge, math.huge, math.huge))
                bv.Velocity = (hrp.CFrame.LookVector * CONFIG.KNOCKBACK.ZAxis) + (hrp.CFrame.UpVector * CONFIG.KNOCKBACK.YAxis)
                Debris:AddItem(bv, 0.2)

                DamageUtils:ValidateAndDamage(char, hitChar, CONFIG.KICK_DAMAGE)
                Hover:AsyncToggle(hitChar, false)
                
                CharacterService:AddUltimateValue(char, 5)
            end

            task.delay(0.2, function()
                Hover:AsyncToggle(char, false)
            end)

            Stomp.CreateHitbox(session, hrp, CFrame.new(0, 0, -3), CONFIG.HITBOX.HIT, onTouched)
        end,
    }

    local conn = track.Stopped:Connect(function()
        session:Stop()
    end)

    session:AddConnection(conn)

    session.extraStopFunction = function()
        CooldownService:SetCooldown(char, script.Name, CONFIG.COOLDOWN)
        stopDebuff()
    end

    local connections = MoveUtils:ConnectAnimationMarkers(track, markers)
    session:BulkAddConnections(connections)
end

return Stomp