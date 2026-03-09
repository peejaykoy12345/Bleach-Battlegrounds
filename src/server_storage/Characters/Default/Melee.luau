local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

    local session = ActionSession.new({
        attacker = self.char,
        actionName = "DefaultM1",
        actionType = "Cooldown",
        cooldown = {cooldown = CONFIG.M1Cooldown}
    })

    if not session then return end

    local animToPlay = self.animIdToPlay

    if animToPlay > #self.M1anims then
        self.comboCooldown = true
        task.delay(CONFIG.ComboCooldown, function()
            self.animIdToPlay = 1
            self.comboCooldown = false
        end)
        return
    end

    CooldownService:SetCooldown(self.char, "DefaultM1", CONFIG.M1Cooldown)

    local track: AnimationTrack = session:PlayAndAddAnimation(self.char, self.M1anims[animToPlay], {Priority = 4})
    
    track:GetMarkerReachedSignal("Hit"):Connect(function()
        local hitbox = MoveUtils:CreateStandardHitbox({
            CFrame = self.hrp.CFrame * CFrame.new(0, 0, -3)
        })
        hitbox:Start()
        hitbox.Touched:Connect(function(hitChar)
            if hitChar == self.char then return end
            hitChar.Humanoid:TakeDamage(10)
        end)
        session.hitbox = hitbox
    end)

    track.Ended:Connect(function()
        session:Stop()
    end)

    self.animIdToPlay += 1
    self.timer:Reset()
end

return Melee