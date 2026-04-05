local ServerStorage = game:GetService("ServerStorage")

local CharactersFolder = ServerStorage.ServerStorage.Characters

local DefaultFolder = CharactersFolder.Default

local Utils = {}

export type validModuleNames = "Melee" | "Dash" | "Block" | "Moves" | "Run"

function Utils.GetCharacterModule(characterName: string, moduleName: validModuleNames)
    local folder = CharactersFolder:FindFirstChild(characterName)
    if not folder then
        warn(`{characterName} does not have a character folder`)
        return DefaultFolder[moduleName]
    end

    local module = folder:FindFirstChild(moduleName)
    if not module then
        warn(`{characterName} does not have a module that handles {moduleName}`)
        return DefaultFolder[moduleName]
    end

    return module
end

function Utils.GetCharacterMoves(characterName: string, isUltimate: boolean)
    local module = require(Utils.GetCharacterModule(characterName, "Moves"))

    if isUltimate then
        return module.Ultimate
    else
        return module.Base
    end
end

return Utils