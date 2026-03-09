local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local CONFIG = {
    M1Cooldown = 0.3,
    ComboCooldown = 1.2,
}

local Melee = {}
Melee.__index = Melee
Melee.M1anims = {
    [1] = 109332345017518,
    [2] = 116598628098678,
    [3] = 88790772873415,
    [4] = 137132189634903,
}

Melee.hitAnims = {
    [1] = 107787809160749,
    [2] = 84083069819396,
    [3] = 135412824644606,
    [4] = 81715699171439,
}

print(ServerScriptService.Server:GetChildren())

local UtilitiesFolder = ServerScriptService.Server.Utilities
local AnimationService = require(ServerScriptService.Server.Services.AnimationService)
local CooldownService = require(ServerScriptService.Server.Services.CooldownService)
local MoveUtils = require(UtilitiesFolder.Combat.MoveUtils)
local ActionSession = require(UtilitiesFolder.Combat.ActionSession)
local AsyncTimer = require(UtilitiesFolder.AsyncTimer)

export type params = {
    char: Model,
}

function Melee.new(params: params)
    local self = setmetatable({}, Melee)

    self.char = params.char
    self.hrp = self.char.HumanoidRootPart
    self.animIdToPlay = 1
    self.timer = AsyncTimer.new(3)
    self.timer.timeout:Connect(function()
        self.animIdToPlay = 1
        self.timer:Reset()
    end)

    self.comboCooldown = false

    return self
end

function Melee:M1()
    if not MoveUtils:CanPerformAction(self.char, "DefaultM1") then return end
    if self.comboCooldown then return end

    local animToPlay = self.animIdToPlay

    if animToPlay > #self.M1anims then return end

    local session = ActionSession.new({
        attacker = self.char,
        actionName = "DefaultM1",
        actionType = "Cooldown",
    })

    if not session then return end

    CooldownService:SetCooldown(self.char, "DefaultM1", CONFIG.M1Cooldown)

    self.animIdToPlay += 1
    self.timer:Reset()

    if self.animIdToPlay > #self.M1anims then
        self.comboCooldown = true
        task.delay(CONFIG.ComboCooldown, function()
            self.animIdToPlay = 1
            self.comboCooldown = false
        end)
    end

    local track: AnimationTrack = session:PlayAndAddAnimation(self.char, self.M1anims[animToPlay], {Priority = 4})

    local hitboxFired = false

    local function fireHitbox()
        if hitboxFired then return end
        hitboxFired = true

        local hb = MoveUtils:CreateStandardHitbox({
            CFrame = self.hrp.CFrame * CFrame.new(0, 0, -3)
        })
        hb:Start()

        local updateConn = RunService.Heartbeat:Connect(function()
            hb.CFrame = self.hrp.CFrame * CFrame.new(0, 0, -3)
        end)

        hb.Touched:Connect(function(hitChar)
            if hitChar == self.char then return end
            hitChar.Humanoid:TakeDamage(10)
            AnimationService:Play(hitChar, self.hitAnims[animToPlay])
        end)

        session.hitbox = hb

        -- disconnect when hitbox stops
        task.delay(0.2, function()
            updateConn:Disconnect()
        end)
    end

    track:GetMarkerReachedSignal("Hit"):Connect(fireHitbox)
    task.delay(.275, fireHitbox)

    track.Ended:Connect(function()
        session:Stop()
    end)
end

return Melee