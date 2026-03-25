local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local ActionSession = require(ServerScriptService.Server.Utilities.Combat.ActionSession)
local MoveUtils = require(ServerScriptService.Server.Utilities.Combat.MoveUtils)
local StateManager = require(ServerScriptService.Server.Utilities.Combat.StateManager)
local Velocity = require(ServerScriptService.Server.Utilities.Combat.Velocity)

local ClientFXService = require(ServerScriptService.Server.Services.ClientFXService)
local AnimationService = require(ServerScriptService.Server.Services.AnimationService)
local CooldownService = require(ServerScriptService.Server.Services.CooldownService)

local remotes = require(ReplicatedStorage.Packages.remotes)

local DashEvent: RemoteEvent = remotes:getEventAsync("Dash")

local Dash = {}
Dash.__index = Dash

Dash.Anims = {
    Forward = 119388231419633,
    ForwardHit = 86003346268818,
    Backward = 112379928777464,
    Left = 131268823739939,
    Right = 86975962496064,
    OnHit = 107787809160749,
}

Dash.Effects = {
    Hit = ReplicatedStorage.Assets.Effects.Combat.FistHit,
}

function Dash.CanDash(char: Model, dir): boolean
    local SideDash = dir == "Left" or dir == "Right"

    local dashType = SideDash and "SideDash" or "Dash"

    if StateManager.HasState(char, "Ragdoll") and not CooldownService:IsOnCooldown(char, "RagdollCancel") then
        return true
    else
        local CanPerformAction = MoveUtils:CanPerformAction(char, dashType, { statesToSkip = { "Ragdoll" } })
        return CanPerformAction
    end
end

function Dash:_CreateHitbox(char: Model, session, onTouched, validateHitParams)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    validateHitParams = validateHitParams or self.ValidateHitParams

    local hb = MoveUtils:CreateStandardHitbox({
        CFrame = hrp.CFrame * CFrame.new(0, 0, -3)
    })
    session.hitbox = hb
    hb:Start()

    local updateConn = RunService.Heartbeat:Connect(function()
        hb.CFrame = hrp.CFrame * CFrame.new(0, 0, -3)
    end)

    hb.Touched:Connect(function(hitChar)
        if not MoveUtils:ValidateHit(char, hitChar, validateHitParams) then return end
        local ehrp = hitChar:FindFirstChild("HumanoidRootPart")
        if not ehrp then return end

        session:InitTarget(hitChar)
        onTouched(hitChar, ehrp)
    end)

    task.delay(0.2, function()
        updateConn:Disconnect()
    end)
end

function Dash:_ApplyVelocity(char: Model, dir: string)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local isForward = dir == "Forward"
    local isBackward = dir == "Backward"
    local isMain = not (dir == "Right" or dir == "Left")

    local multiplier = if isForward then .95 else 0.98
    local Speed = if isForward then 175 * .75 elseif isBackward then 70 else 140
    local int = Speed
    local usedint = int

    local alignDirection = if isForward then 0
        elseif isBackward then 180
        elseif dir == "Right" then -90
        else 90

    for _, v in hrp:GetChildren() do
        if v:IsA("LinearVelocity") or v:IsA("Attachment") then v:Destroy() end
    end

    local att = Instance.new("Attachment")
    att.CFrame = CFrame.new()
    att.Parent = hrp

    local lv = Instance.new("LinearVelocity")
    lv.Attachment0 = att
    lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
    lv.PrimaryTangentAxis = Vector3.new(1, 0, 0)
    lv.SecondaryTangentAxis = Vector3.new(0, 0, 1)
    lv.PlaneVelocity = Vector2.new(0, 0)
    lv.MaxForce = 40000
    lv.Parent = hrp

    lv.RelativeTo = Enum.ActuatorRelativeTo.Attachment0

    local lifetime = if isForward then 1 elseif isMain then 1 else 0.15
    task.delay(lifetime, function()
        if lv and lv.Parent then lv:Destroy() end
        if att and att.Parent then att:Destroy() end
    end)

    if isBackward then
        task.delay(.5, function()
            usedint = 0
            task.wait(.2)
            usedint = 150
        end)
    end

    if isForward then
        task.delay(.365, function()
            multiplier = .625
            int = 30
            usedint = 30
        end)
    end

    task.spawn(function()
        while lv and lv.Parent do
            int *= multiplier
            usedint = int
            local lookVec = (hrp.CFrame * CFrame.Angles(0, math.rad(alignDirection), 0)).LookVector
            lv.PlaneVelocity = Vector2.new(lookVec.X * usedint, lookVec.Z * usedint)
            if int <= 1 then break end
            task.wait(1 / 60)
        end
        if lv and lv.Parent then lv:Destroy() end
        if att and att.Parent then att:Destroy() end
    end)

    return lv
end

function Dash:_FireHitFX(hitChar)
    ClientFXService:Start({ Name = "Hit", Type = "Combat" }, { target = hitChar })
    ClientFXService:Start({ Name = "EmitParticles", Type = "Combat" }, {
        parent = hitChar.HumanoidRootPart,
        particleContainer = self.Effects.Hit
    })
end

function Dash:Dash(char: Model, dir: string)
    if not self.CanDash(char, dir) then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local dashType = (dir == "Left" or dir == "Right") and "SideDash" or "Dash"

    local session = ActionSession.new({
        attacker = char,
        actionName = dashType,
        actionType = "Cooldown",
        cooldown = {
            cooldown = 1
        },
        states = {
            attackerStates = {"CantUse"}
        }
    })

    if not session then return end

    session:Start()

    if StateManager.HasState(char, "Ragdoll") then
        CooldownService:SetCooldown(char, "RagdollCancel", 10)
        MoveUtils:UnragdollCharacter(char)
    end

    local track = session:PlayAndAddAnimation(char, Dash.Anims[dir], { Priority = 3 })

    local bv = self:_ApplyVelocity(char, dir)
    session.extraStopFunction = function()
        if bv then bv:Destroy() end
    end

    local trackLength = track.Length
    if trackLength <= 0 then
        trackLength = .5
    else
        trackLength -= .2
    end

    if dir == "Forward" then
        track:AdjustSpeed(.7)

        local punched = false

        local function punch()
            if punched then return end
            punched = true
            track:Stop()
            local newTrack: AnimationTrack = session:PlayAndAddAnimation(char, Dash.Anims.ForwardHit, { Priority = 3 })

            local newTrackLength = newTrack.Length
            if newTrackLength <= 0 then
                newTrackLength = .5
            else
                newTrackLength -= .1
            end

            self:_CreateHitbox(char, session, function(hitChar, ehrp)
                AnimationService:Play(hitChar, self.Anims.OnHit)

                local hum = hitChar:FindFirstChild("Humanoid")
                if not hum then return end

                hum:TakeDamage(10)

                self:_FireHitFX(hitChar)

                MoveUtils:FacePlayer(ehrp, hrp)
            end)

            task.delay(newTrackLength, function()
                session:Stop()
            end)
        end

        task.delay(trackLength, function()
            punch()
        end)
    else
        task.delay(trackLength, function()
            session:Stop()
        end)
    end

    local plr = Players:GetPlayerFromCharacter(char)
    if not plr then return end

    --DashEvent:FireClient(plr, dir)
end

return Dash