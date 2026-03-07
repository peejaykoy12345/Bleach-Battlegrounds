local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local HitboxService = Knit.CreateService{
    Name = "HitboxService",
    Client = {}
}

local Hitbox = require(script.Hitbox)

function HitboxService:CreateHitbox(): typeof(Hitbox)
    return Hitbox.new()
end