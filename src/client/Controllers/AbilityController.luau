local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local AbilityController = Knit.CreateController{
    Name = "AbilityController"
}

local KeycodeToString = {
    [Enum.KeyCode.One] = "1",
    [Enum.KeyCode.Two] = "2",
    [Enum.KeyCode.Three] = "3",
    [Enum.KeyCode.Four] = "4",
    [Enum.KeyCode.G] = "G"
}

function AbilityController:KnitStart()
    self.ActionService = Knit.GetService("ActionService")

    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end

        local inputString = KeycodeToString[input.KeyCode]
        if inputString then
            self.ActionService:PerformAction("Ability", {input = inputString})
        end
    end)
end

return AbilityController