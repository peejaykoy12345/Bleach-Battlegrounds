local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local Network = require(ReplicatedStorage.Shared.Modules.Network)

local CharactersFolder = ServerStorage.ServerStorage.Characters

local CooldownService = Knit.CreateService {
    Name = "CooldownService";
    Client = {};
}

function CooldownService:InitializeCharacter(char: Model)
    self.Cooldowns[char] = {}

    char.Humanoid.Died:Connect(function()
        self.Cooldowns[char] = nil
    end)
end

function CooldownService:SetCooldown(char: Model, action: string, cooldown: number)
    if not self.Cooldowns[char] then
        self:InitializeCharacter(char)
    end
    
    self.Cooldowns[char][action] = true

    task.delay(cooldown, function()
        if not self.Cooldowns[char] then return end
        self.Cooldowns[char][action] = nil
    end)

    if not self.moves[action] then return end

    local plr = Players:GetPlayerFromCharacter(char)
    if plr then
        Network.Character.packets.OnMoveCooldown.sendTo({
            MoveName = action,
            CooldownTime = cooldown,
            TimeOfSent = os.time(),
        }, plr)
    end
end

function CooldownService:IsOnCooldown(char: Model, action: string): boolean
    if not self.Cooldowns[char] then
        return false
    end

    return self.Cooldowns[char][action] ~= nil
end

function CooldownService:KnitInit()
    self.Cooldowns = {}
    self.moves = {}

    for _, folder in ipairs(CharactersFolder:GetChildren()) do
        if not folder:IsA("Folder") then continue end

        local MovesModule = folder:FindFirstChild("Moves")
        if not MovesModule then continue end

        local module = require(MovesModule)

        if module.Base then
            for input, module_script in pairs(module.Base) do
                if input == "Awakening" then continue end
                self.moves[module_script.Name] = true
            end
        end

        if module.Ultimate then
            for _, module_script in pairs(module.Ultimate) do
                self.moves[module_script.Name] = true
            end
        end
    end
end

return CooldownService