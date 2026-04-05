local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Replica = require(ReplicatedStorage.Packages.Replica)

local Profiles = require(script.Parent.Profiles)

local ReplicaInstances = {}
local UltimateCoroutines: {[Player]: thread} = {}
local HumDiedConnections: {[Player]: RBXScriptConnection} = {}

local CharacterService = Knit.CreateService{
    Name = "CharacterService",
    Client = {},
}

function CharacterService:KnitStart()
    self.ActionService = Knit.GetService("ActionService")

    Players.PlayerAdded:Connect(function(player)
        
        local triggered = false

        player.CharacterAdded:Connect(function(char)
            local currentCharacter = self:GetCurrentCharacter(player)
            self.ActionService:CreateMeleeInstance(player, currentCharacter)

            local moves = self:GetMoveNames(currentCharacter, false)

            char:SetAttribute("IsUltimate", false)

            if triggered and ReplicaInstances[player] then
                ReplicaInstances[player]:Set({"Character"}, currentCharacter)
                ReplicaInstances[player]:Set({"Moves"}, moves)
            else
                local hum = char:WaitForChild("Humanoid")
                hum.Running:Wait()
                ReplicaInstances[player] = Replica.New({
                    Token = Replica.Token("CharacterData"),
                    Data = {
                        Character = currentCharacter,
                        Moves = moves,
                        Ultimate = 0,
                    },
                })
                ReplicaInstances[player]:Subscribe(player)
            end

            char:SetAttribute("Character", currentCharacter)

            if not HumDiedConnections[player] then
                local hum = char:WaitForChild("Humanoid")
                if not hum then return end

                HumDiedConnections[player] = hum.Died:Connect(function()
                    self:StopUltimate(player)
                end)
            end
        end)
    end)

    Players.PlayerRemoving:Connect(function(player)
        HumDiedConnections[player] = nil
        self:StopUltimate(player)
        UltimateCoroutines[player] = nil
        ReplicaInstances[player]:Destroy()
        ReplicaInstances[player] = nil
    end)
end

function CharacterService:GetMoveNames(characterName: string, isUltimate: boolean)
    local moves = self.ActionService:GetCharacterMoves(characterName, isUltimate)

    local moveNames = {}

    for slot, module_script in pairs(moves) do
        moveNames[slot] = module_script.Name
    end

    return moveNames
end

function CharacterService:GetCurrentCharacter(plr: Player)
    local profile = Profiles:GetOrLoadProfile(plr)
    if not profile then return end

    return profile.Data.Character
end

function CharacterService:GetReplicaInstance(plr: Player)
    return ReplicaInstances[plr]
end

function CharacterService:AddOrSubtractUltimate(plr: Player, value: number, operation: "Add" | "Subtract")
    assert(operation == "Add" or operation == "Subtract", 'Operation is nil or not correct. "Add | Subtract"')
    
    if operation == "Add" then
        local currentValue = math.min(ReplicaInstances[plr].Data.Ultimate + value, 100)
        ReplicaInstances[plr]:Set({"Ultimate"}, currentValue)
    else
        local currentValue = math.max(0, ReplicaInstances[plr].Data.Ultimate - value)
        ReplicaInstances[plr]:Set({"Ultimate"}, currentValue)
    end
end

function CharacterService:CanStartUltimate(plr: Player)
    local replica = ReplicaInstances[plr]
    if not replica then return end

    return replica.Data.Ultimate >= 100
end

function CharacterService:StartUltimate(plr: Player)
    local char = plr.Character
    if char then return end

    if not self:CanStartUltimate(plr) then return end

    char:SetAttribute("IsUltimate", true)

    UltimateCoroutines[plr] = coroutine.create(function()
        while task.wait(1) do
            if not ReplicaInstances[plr] then return end

            ReplicaInstances[plr].Data.Ultimate -= 1
            if ReplicaInstances[plr].Data.Ultimate  <= 0 then
                self:StopUltimate(plr)
                return
            end
        end
    end)

    coroutine.resume(UltimateCoroutines[plr])
end

function CharacterService:StopUltimate(plr: Player)
    if UltimateCoroutines[plr] and coroutine.status(UltimateCoroutines[plr]) ~= "dead" then
        coroutine.close(UltimateCoroutines[plr])
        UltimateCoroutines[plr] = nil
    end

    local char = plr.Character
    if not char then return end

    char:SetAttribute("IsUltimate", false)
end

return CharacterService