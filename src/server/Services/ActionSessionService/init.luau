local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local Types = require(script.Types)

local ActionSessionService = Knit.CreateService {
    Name = "ActionSessionService",
    Client = {},
}

function ActionSessionService:KnitStart()
    self.ActionSession = require(script.ActionSession)
end

type AttackSessionParams = Types.AttackSessionParams

function ActionSessionService:NewSession(params: AttackSessionParams)
    return self.ActionSession.new(params)
end