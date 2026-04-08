local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ServicesFolder = ServerScriptService.Server.Services
local CharacterService = require(ServicesFolder.CharacterService)
local CooldownService = require(ServicesFolder.CooldownService)
local ClientFXService = require(ServicesFolder.ClientFXService)
local AnimationPlayer = require(ReplicatedStorage.Shared.Modules.Utilities.AnimationPlayer)
local StunService = require(ServicesFolder.StunService)
local SoundPlayer = require(ReplicatedStorage.Shared.Modules.Utilities.SoundPlayer)

local UtilitiesFolder = ServerScriptService.Server.Utilities
local CombatUtils = UtilitiesFolder.Combat
local MoveUtils = require(CombatUtils.MoveUtils)
local ActionSession = require(CombatUtils.ActionSession)
local DamageUtils = require(CombatUtils.DamageUtils)

local Move_1 = {}

function Move_1.Run(char, params)
    if not MoveUtils:CanPerformAction(char, script.Name) then return end -- Checks for cooldowns and states

    print("USED MOVE! Adding ultimate value", char.Name)
    CharacterService:AddUltimateValue(char, 20)
    
    print("SETTING COOLDOWN! ", char.Name)
    CooldownService:SetCooldown(char, script.Name, 1)
end

return Move_1