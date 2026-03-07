local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local AnimationService = Knit.GetService("AnimationService")

local Melee = {}
Melee.__index = Melee

type params = {
    char: Model,
}

function Melee.new(params)
    local self = setmetatable({}, Melee)

    self.char = params.char

    return self
end

return Melee