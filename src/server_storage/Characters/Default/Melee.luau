local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local ActionSessionService = Knit.GetService("ActionSessionService")
local AnimationService = Knit.GetService("AnimationService")
local AsyncTimerService = Knit.GetService("AsyncTimerService")

local Melee = {}
Melee.__index = Melee

Melee.M1anims = {
    [1] = 132158895417218,
}

export type params = {
    char: Model,
}

function Melee.new(params: params)
    local self = setmetatable({}, Melee)

    self.char = params.char

    return self
end

function Melee:M1()
    
end

return Melee