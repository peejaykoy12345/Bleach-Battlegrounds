local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local Types = require(script.Types)

local ActionSessionService = Knit.CreateService {
    Name = "ActionSessionService",
    Client = {},
}

function ActionSessionService:KnitStart()
    
end

type AttackSessionParams = Types.AttackSessionParams

function ActionSessionService:NewSession(params: AttackSessionParams)
    
end