local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GoodSignal = require(ReplicatedStorage.Packages.GoodSignal)
local Knit = require(ReplicatedStorage.Packages.Knit)

local AsyncTimerService = Knit.CreateService{
    Name = "AsyncTimerService",
    Client = {}
}
AsyncTimerService.__index = AsyncTimerService

function AsyncTimerService.new(duration)
    local self = setmetatable({}, AsyncTimerService)
    self.duration = duration or 10
    self.running = false
    self.endTime = 0
    self.handle = nil
    self.timeout = GoodSignal.new()

    return self
end

function AsyncTimerService:OnTimeout()
    print("OnTimeout")
    if self.running and tick() >= self.endTime then
        self.timeout:Fire()
        self:Stop()
        self.running = false
    end
end

function AsyncTimerService:Start()
    self.running = true
    self.endTime = tick() + self.duration
    if self.handle then task.cancel(self.handle) end
    self.handle = task.delay(self.duration, function()
        self:OnTimeout()
    end)
end

function AsyncTimerService:TryStart()
    if not self.running then
        self:Start()
    end
end

function AsyncTimerService:Extend(extra)
    if not self.running then return end
    self.endTime = self.endTime + extra
    if self.handle then task.cancel(self.handle) end
    local remaining = self.endTime - tick()
    self.handle = task.delay(remaining, function()
        self:OnTimeout()
    end)
end

function AsyncTimerService:Stop()
    self.running = false
    if self.handle then
        pcall(task.cancel, self.handle)
        self.handle = nil
    end
end


function AsyncTimerService:Reset()
    if not self.running then
        self:Start() 
    else
        local duration = self.duration
        self:Stop()        
        self.endTime = tick() + duration
        self.running = true
        self.handle = task.delay(duration, function()
            self:OnTimeout()
        end)
    end
end

return AsyncTimerService