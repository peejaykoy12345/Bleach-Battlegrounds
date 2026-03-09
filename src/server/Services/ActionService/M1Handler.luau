local ServerStorage = game:GetService("ServerStorage")

local CharacterFolder = ServerStorage.ServerStorage.Characters

local module = {}
module.__index = module

module.M1Instances = {}

function module:HandleAction(plr: Player, params)
    local module = require(CharacterFolder.Default.Melee)
    
    if self.M1Instances[plr] then
        self.M1Instances[plr]:M1()
    else
        self.M1Instances[plr] = module.new({
            char = plr.Character
        }) 
        self.M1Instances[plr]:M1()
    end
end

return module