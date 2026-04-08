local ServerScriptService = game:GetService("ServerScriptService")

local ClientFXService = require(ServerScriptService.Server.Services.ClientFXService)

local Utils = {}
local Multipliers: {[Model]: (number) -> number} = {}

function Utils:ValidateAndDamage(attacker: Model, target: Model, damage: number)
    if attacker == target then return end
    if not target:FindFirstChild("Humanoid") then return end

    if Multipliers[attacker] then
        local oldDamage = damage
        damage = Multipliers[attacker](oldDamage)

        print(`OLD DAMAGE: {oldDamage} AFTER APPLYING 1.3x: {damage}`)
    end

    local humanoid = target:FindFirstChild("Humanoid") :: Humanoid
    humanoid:TakeDamage(damage)

    ClientFXService:Start({ Name = "Hit", Type = "Combat" }, { target = target })
end

function Utils:AddDamageMultiplier(char: Model, multiplier: number, duration: number)
    Multipliers[char] = function(damage)
        return damage * multiplier
    end

    local conn: RBXScriptConnection?

    local humanoid = char:FindFirstChild("Humanoid") :: Humanoid
    if humanoid then
        conn = humanoid.Died:Connect(function()
            Multipliers[char] = nil
            if conn then
                conn:Disconnect()
            end
        end)
    end

    task.delay(duration, function()
        Multipliers[char] = nil
        if conn then
            conn:Disconnect()
        end
    end)
end

return Utils