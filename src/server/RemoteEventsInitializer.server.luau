-- Initializes remote events so that the they can be accessed through the client
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotes = require(ReplicatedStorage.Packages.remotes)

local DashEvent: RemoteEvent = remotes:getEventAsync("Dash")
local UndashEvent: RemoteEvent = remotes:getEventAsync("UnDash")
local StopDashAndPunchInstead: RemoteEvent = remotes:getEventAsync("StopDashAndPunchInstead")

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
Players.PlayerAdded:Connect(function(player: Player)
    player.CharacterAppearanceLoaded:Wait()

    task.wait(5)
    require(ServerScriptService.Server.Utilities.Combat.EffectUtils):ApplyEffect(player.Character, "Fire", 5)
    task.wait(5)
    print("Turned it to 7")
    require(ServerScriptService.Server.Utilities.Combat.EffectUtils):ApplyEffect(player.Character, "Fire", 7)
end)