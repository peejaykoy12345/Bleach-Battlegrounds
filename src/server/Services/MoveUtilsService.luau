local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local MoveUtilsService = Knit.CreateService{
    Name = "MoveUtilsService",
    Client = {}
}

function MoveUtilsService:KnitStart()
	self.HitboxService = Knit.GetService("HitboxService")
end

function MoveUtilsService:CreateStandardHitbox(config)
	config = config or {}

	local hitbox = self.HitboxService:CreateHitbox()
	hitbox.Size = config.SIZE or Vector3.new(4, 4, 4)
	hitbox.CFrame = config.CFrame or CFrame.new(0, 0, 0)
	hitbox.Visualizer =  config.VISUALIZER ~= false 
	return hitbox
end

return MoveUtilsService