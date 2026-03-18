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

function Dash.CanDash(char: Model): boolean
    if StateManager.HasState(char, "Ragdoll") and not CooldownService:IsOnCooldown(char, "RagdollCancel") then
        return true
    else
        return MoveUtils:CanPerformAction(char, "Dash", { statesToSkip = { "Ragdoll" } })
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

function Dash:_FireHitFX(hitChar)
    ClientFXService:Start({ Name = "Hit", Type = "Combat" }, { target = hitChar })
    ClientFXService:Start({ Name = "EmitParticles", Type = "Combat" }, {
        parent = hitChar.HumanoidRootPart,
        particleContainer = self.Effects.Hit
    })
end

function Dash:Dash(char: Model, dir: string)
    print("Attemping to dash")
    if not self.CanDash(char) then return end
    print("DASHING")

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local session = ActionSession.new({
        attacker = char,
        actionName = "Dash",
        actionType = "Misc",
        cooldown = {
            cooldown = 1
        },
        states = {
            attackerStates = {"CantUse"}
        }
    })

    if not session then return end
    print(StateManager.HasState(char, "Ragdoll"))
    if StateManager.HasState(char, "Ragdoll") then
        
        CooldownService:SetCooldown(char, "RagdollCancel", 10)
        MoveUtils:UnragdollCharacter(char)
    end

    local track = session:PlayAndAddAnimation(char, Dash.Anims[dir], { Priority = 3 })
    if dir == "Forward" then
        track:AdjustSpeed(.7) 

        local trackLength = track.Length 
        if trackLength <= 0 then
            trackLength = .5
        else
            trackLength -= .1
        end

        task.delay(trackLength, function()
            track:Stop()
            local newTrack: AnimationTrack = session:PlayAndAddAnimation(char, Dash.Anims.ForwardHit, { Priority = 3 })
            newTrack.Ended:Connect(function()
                session:Stop()
            end)

            self:_CreateHitbox(char, session, function(hitChar, ehrp)
                AnimationService:Play(hitChar, self.Anims.OnHit)

                local hum = hitChar:FindFirstChild("Humanoid")
                if not hum then return end

                hum:TakeDamage(10)

                self:_FireHitFX(hitChar)

                MoveUtils:FacePlayer(ehrp, hrp)
            end)
        end)
    end

    local plr = Players:GetPlayerFromCharacter(char)
    if not plr then return end

    DashEvent:FireClient(plr, dir)
end

return Dash