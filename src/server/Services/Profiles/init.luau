local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ProfileStore = require(ServerScriptService.ServerPackages.ProfileStore)
local Knit = require(ReplicatedStorage.Packages.Knit)

export type DataTemplateType = {
    Character: string,
}

local PROFILE_TEMPLATE: DataTemplateType = {
    Character = "The Hollow"
}

local Profiles = Knit.CreateService{
    Name = "Profiles",
    Client = {},
}

local PlayerStore = ProfileStore.New("PlayerStore", PROFILE_TEMPLATE)
local PlayerProfiles = {}

function Profiles:GetOrLoadProfile(plr: Player)
    if PlayerProfiles[plr] then
        return PlayerProfiles[plr]
    end

    local profile = PlayerStore:StartSessionAsync(`{plr.UserId}`, {
        Cancel = function()
            return plr.Parent ~= Players
        end,
    })

    if profile ~= nil then
        profile:AddUserId(plr.UserId)
        profile:Reconcile()

        profile.OnSessionEnd:Connect(function()
            PlayerProfiles[plr] = nil  -- was Profiles[plr]
            plr:Kick("Profile session end - Please rejoin")
        end)

        if plr.Parent == Players then
            PlayerProfiles[plr] = profile  -- was Profiles[plr]
        else
            profile:EndSession()
        end
    else
        plr:Kick("Profile load fail - Please rejoin")
    end

    return PlayerProfiles[plr] 
end

function Profiles:KnitStart()
    
end

return Profiles