local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Melee = {}
Melee.__index = Melee
Melee.M1anims = {
    [1] = 83339276849762,
    [2] = 76706163460362,
}

local UtilitiesFolder = ServerScriptService.Server.Utilities
local AnimationService = require(ServerScriptService.Server.Services.AnimationService)
local MoveUtils = require(UtilitiesFolder.Combat.MoveUtils)
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

function Melee:CreateHitbox()
    --log(self.char, "Hitbox", "Creating hitbox (destroying existing if present)")
    self:DestroyHitbox()
    self.hitbox = MoveUtils:CreateStandardHitbox()
    --log(self.char, "Hitbox", "Hitbox created: %s", tostring(self.hitbox))
end

function Melee:DestroyHitbox()
    if self.hitbox then
        --log(self.char, "Hitbox", "Destroying hitbox: %s", tostring(self.hitbox))
        self.hitbox:Stop()
        self.hitbox = nil
    else
        --log(self.char, "Hitbox", "DestroyHitbox called but no hitbox present")
    end
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Melee = {}
Melee.__index = Melee
Melee.M1anims = {
    [1] = 83339276849762,
    [2] = 76706163460362,
}

local UtilitiesFolder = ServerScriptService.Server.Utilities
local AnimationService = require(ServerScriptService.Server.Services.AnimationService)
local MoveUtils = require(UtilitiesFolder.Combat.MoveUtils)
local AsyncTimer = require(UtilitiesFolder.AsyncTimer)

export type Meleeparams = {
    char: Model,
}

function Melee.new(params: Meleeparams)
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

function Melee:CreateHitbox()
    self:DestroyHitbox()
    self.hitbox = MoveUtils:CreateStandardHitbox()
end

function Melee:DestroyHitbox()
    if self.hitbox then
        self.hitbox:Stop()
        self.hitbox = nil
    else
    end
end

function Melee:M1()
    if self.comboCooldown then return end

    local animToPlay = self.animIdToPlay

    if animToPlay > #self.M1anims then
        self.comboCooldown = true
        task.delay(2, function()
            self.animToPlay = 1
            self.comboCooldown = false
        end)
        return
    end
    
    print(animToPlay)

    AnimationService:Play(self.char, self.M1anims[animToPlay])
    self.animIdToPlay += 1
    self.timer:Reset()
end

return Melee