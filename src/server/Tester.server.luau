local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Default = require(ServerStorage.ServerStorage.Characters.Default.Melee)

local Melee

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        local char = player.Character

        Melee = Default.new({
            char = char
        })

        while task.wait(2) do
            Melee:M1()
        end
    end)
end)