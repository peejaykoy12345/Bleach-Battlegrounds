local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local ActionSession = require(ServerScriptService.Server.Utilities.Combat.ActionSession)
local MoveUtils = require(ServerScriptService.Server.Utilities.Combat.MoveUtils)
local StateManager = require(ServerScriptService.Server.Utilities.Combat.StateManager)

local ClientFXService = require(ServerScriptService.Server.Services.ClientFXService)
local AnimationService = require(ServerScriptService.Server.Services.AnimationService)
local CooldownService = require(ServerScriptService.Server.Services.CooldownService)

local RunHandler = require(ServerScriptService.Server.Services.ActionService.RunHandler)

local remotes = require(ReplicatedStorage.Packages.remotes)

local DashEvent: RemoteEvent = remotes:getEventAsync("Dash")
local UnDashEvent: RemoteEvent = remotes:getEventAsync("UnDash")
local StopDashAndPunchInstead: RemoteEvent = remotes:getEventAsync("StopDashAndPunchInstead")

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
        print("CanPerformAction:", CanPerformAction, "states:", StateManager.GetStates and StateManager.GetStates(char))
        return CanPerformAction
    end
end

function Dash:_CreateHitbox(char: Model, session, onTouched, validateHitParams)
    local hrp: BasePart = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    validateHitParams = validateHitParams or self.ValidateHitParams

    local plr = Players:GetPlayerFromCharacter(char)

    local hb = MoveUtils:CreateHitbox({
        CFrame = hrp.CFrame * CFrame.new(0, 0, -3),
        UseClient = plr,
        SizeOrPart = Vector3.new(4, 4, 4),
        Debug = true,
        WeldedPart = hrp,
        WeldOffsetCFrame = CFrame.new(0, 0, -3),
    })
    session.hitbox = hb
    hb:Start()
    hb.HitSomeone:Connect(function(hitChars)
        for _, hitChar in ipairs(hitChars) do
            if not MoveUtils:ValidateHit(char, hitChar, validateHitParams) then continue end
            local ehrp = hitChar:FindFirstChild("HumanoidRootPart")
            if not ehrp then continue end

            session:InitTarget(hitChar)
            onTouched(hitChar)
        end
    end)
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

    local wasRunning = RunHandler:WasRunning(char)

    local session = ActionSession.new({
        attacker = char,
        actionName = dashType,
        actionType = "Cooldown",
        states = {
            attackerStates = {"CantUse"}
        }
    })

    if not session then return end

    local plr = Players:GetPlayerFromCharacter(char)

    session:Start()

    if StateManager.HasState(char, "Ragdoll") then
        CooldownService:SetCooldown(char, "RagdollCancel", 10)
        MoveUtils:UnragdollCharacter(char)
    end

    local track = session:PlayAndAddAnimation(char, Dash.Anims[dir], { Priority = 3 })

    local conn

    session.extraStopFunction = function()
        if plr then
            UnDashEvent:FireClient(plr)
        end

        if wasRunning then
            RunHandler:StartRunning(char, true)
        end

        if conn then
            conn:Disconnect()
        end 

        CooldownService:SetCooldown(char, dashType, 1)
    end

    local trackLength = track.Length
    if trackLength <= 0 then
        trackLength = .5
    else
        trackLength -= .2
    end

    print("Passed")

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
                newTrackLength -= .2
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
                print("Session stoppwed")
                session:Stop()
            end)
        end

        task.delay(trackLength, function()
            punch()
        end)

        StopDashAndPunchInstead.OnServerEvent:Connect(function(plr)
        if plr.Character and plr.Character == char then
            punch()
        end
    end)
    else
        task.delay(trackLength, function()
            session:Stop()
        end)
    end

    if plr then
        DashEvent:FireClient(plr, dir)
    end
end

return Dash