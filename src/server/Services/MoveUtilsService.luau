local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local MoveUtilsService = Knit.CreateService{
    Name = "MoveUtilsService",
    Client = {}
}

function MoveUtilsService:KnitInit()
	
end

return MoveUtilsService