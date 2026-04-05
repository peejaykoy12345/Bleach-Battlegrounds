local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local MeleeInstances = require(script.MeleeInstances)
local Utils = require(script.Utils)

local Characters = ServerStorage.ServerStorage.Characters

local Knit = require(ReplicatedStorage.Packages.Knit)

local ActionService = Knit.CreateService({
    Name = "ActionService",
    Client = {}
})

local DiedConnections: {[Player]: RBXScriptConnection} = {}

function ActionService.Client:PerformAction(plr: Player, actionName: string, params)
    local moduleName = actionName .. "Handler"
    local module = script:FindFirstChild(moduleName)
    if module then
        require(module):HandleAction(plr, params)
    end

    DiedConnections[plr] = plr.Character.Humanoid.Died:Connect(function()
        MeleeInstances[plr] = nil
    end)
end

function ActionService:_CreateMeleeInstance(char: Model, characterName: string, folder: Folder)
    local MeleeModule = folder:FindFirstChild("Melee")
    if not MeleeModule then
        warn(`{characterName} does not have a melee module`)
        return
    end

    local module = require(MeleeModule)
    return module.new({char = char})
end

function ActionService:CreateMeleeInstance(plr: Player, characterName: string)
    local char = plr.Character
    if not char then return end

    local CharacterFolder = Characters:FindFirstChild(characterName)
    if not CharacterFolder then
        warn(`{characterName} does not have a character folder set! Resorting to default`)
        MeleeInstances[plr] = self:_CreateMeleeInstance(char, characterName, Characters.Default)
        return
    end

    MeleeInstances[plr] = self:_CreateMeleeInstance(char, characterName, CharacterFolder)
end

function ActionService:GetCharacterMoves(characterName: string, isUltimate: boolean)
    local moves = Utils.GetCharacterMoves(characterName, isUltimate)
    return moves
end

Players.PlayerRemoving:Connect(function(plr)
    if DiedConnections[plr] then
        DiedConnections[plr]:Disconnect()
        DiedConnections[plr] = nil
    end
end)

return ActionService