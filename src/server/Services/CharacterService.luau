local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local Profiles = require(script.Parent.Profiles)

local CharacterService = Knit.CreateService{
    Name = "CharacterService",
    Client = {},
}

function CharacterService:KnitStart()
    self.ActionService = Knit.GetService("ActionService")

    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(char)
            local currentCharacter = self:GetCurrentCharacter(player)
            self.ActionService:CreateMeleeInstance(player, currentCharacter)

            char:SetAttribute("Character", currentCharacter)
        end)
    end)
end

function CharacterService:GetCurrentCharacter(plr: Player)
    local profile = Profiles:GetOrLoadProfile(plr)
    if not profile then return end

    return profile.Data.Character
end

return CharacterService