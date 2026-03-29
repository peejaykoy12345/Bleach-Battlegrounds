local Utils = {}

function Utils:ValidateAndDamage(attacker: Model, target: Model, damage: number)
    if attacker == target then return end
    if not target:FindFirstChild("Humanoid") then return end

    local humanoid = target.Humanoid
    humanoid:TakeDamage(damage)
end

return Utils