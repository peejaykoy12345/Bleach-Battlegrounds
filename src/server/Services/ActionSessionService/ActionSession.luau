local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Services
local AnimationService = Knit.GetService("AnimationService")

-- Utils
local TableUtils = require(ReplicatedStorage.Shared.Utils.TableUtils)

local Types = require(script.Parent.Types)

type AttackSessionParams = Types.AttackSessionParams

local AttackSession = {}
AttackSession.__index = AttackSession

function AttackSession.new(params: AttackSessionParams)
    assert(params.attacker, "Attacker is required")
    assert(params.moveName, "MoveName is required")
    assert(params.actionType, "ActionType is required")

    local self = setmetatable({}, AttackSession)

    self.attacker = params.attacker
    self.moveName = params.moveName
    self.actionType = params.actionType

    self.animations = {}

    self.options = params
    return self
end

function AttackSession:PlayAndAddAnimation(char: Model, animationId: number): Animation
    local anim = AnimationService:PlayAnimation(char, animationId)
    self:AddAnimation(anim)

    return anim
end

function AttackSession:AddAnimation(animation: Animation)
    table.insert(self.animations, animation)
end

function AttackSession:StopAnimation(animation: Animation)
    TableUtils:ArrayRemove(self.animations, animation)
    AnimationService:StopAnimation(animation)
end

return AttackSession