local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Replica = require(ReplicatedStorage.Packages.Replica)

local plr = Players.LocalPlayer

local ScreenGUI = plr:WaitForChild("PlayerGui"):WaitForChild("HUD")
local CooldownFrame = ScreenGUI:WaitForChild("Cooldowns")
local Template = CooldownFrame.Template

local CharacterHUDController = Knit.CreateController{
    Name = "CharacterHUDController"
}

function CharacterHUDController:_HandleMoveChanges(data)
    for _, button in ipairs(CooldownFrame:GetChildren()) do
        if not button:IsA("ImageButton") or button.Name == "Template" then continue end

        button:Destroy()
    end

    print(data)

    for input, moveName in pairs(data) do
        if input == "Awakening" then continue end

        local button = Template:Clone()
        button.Name = moveName
        button.Frame.SkillName.Text = moveName
        button.Frame.Order.Text = input
        button.Visible = true
        button.Parent = CooldownFrame
    end
end

function CharacterHUDController:KnitStart()
    Replica.OnNew("CharacterData", function(replica)
        self.replica = replica

        CharacterHUDController:_HandleMoveChanges(replica.Data.Moves)
    end)
end

return CharacterHUDController