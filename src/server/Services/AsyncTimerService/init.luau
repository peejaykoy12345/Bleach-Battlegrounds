local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local AsyncTimerService = Knit.CreateService{
    Name = "AsyncTimerService",
    Client = {}
}
AsyncTimerService.__index = AsyncTimerService

function AsyncTimerService:KnitStart()
    self.AsyncTimer = require(script.AsyncTimer)  
end

function AsyncTimerService:CreateNewAsyncTimer(duration: number)
    
end

return AsyncTimerService