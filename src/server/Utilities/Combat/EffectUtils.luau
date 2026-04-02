--[[
    TEST ONLY (NOT FINAL)
]]

local EffectUtils = {}
EffectUtils.EffectVFX = {}
EffectUtils.EffectFunctions = {
    Fire = function(target: Model, entry: { task: thread, vfx: Instance, effectTask: thread? })
        local humanoid = target:FindFirstChild("Humanoid")
        if not humanoid then return end

        local loopTask = task.spawn(function()
            while true do
                task.wait(0.5)
                humanoid:TakeDamage(5)
            end
        end)

        entry.effectTask = loopTask
    end,
}

export type effects = "Fire"

type EffectEntry = {
    task: thread,
    vfx: Instance,
    effectTask: thread?,
}

-- {[target] = {[effectName] = EffectEntry}}
local activeEffects: { [Model]: { [string]: EffectEntry } } = {}

function EffectUtils:ApplyEffect(target: Model, effectName: effects, duration: number)
    local vfx = self.EffectVFX[effectName]
    if not vfx then
        warn(`{effectName} does not have a vfx set`)
        return
    end

    if activeEffects[target] and activeEffects[target][effectName] then
        EffectUtils:RemoveEffect(target, effectName)
    end

    if not activeEffects[target] then
        activeEffects[target] = {}
    end

    vfx = vfx:Clone()

    local entry: EffectEntry = { task = nil :: any, vfx = vfx, effectTask = nil }
    activeEffects[target][effectName] = entry

    local effectFn = self.EffectFunctions[effectName]
    if effectFn then
        effectFn(target, entry)
    end

    entry.task = task.spawn(function()
        task.wait(duration)
        EffectUtils:RemoveEffect(target, effectName)
    end)
end

function EffectUtils:RemoveEffect(target: Model, effectName: effects)
    if not activeEffects[target] or not activeEffects[target][effectName] then return end

    local existing = activeEffects[target][effectName]
    if existing.effectTask then
        task.cancel(existing.effectTask)
    end
    existing.vfx:Destroy()
    activeEffects[target][effectName] = nil

    if next(activeEffects[target]) == nil then
        activeEffects[target] = nil
    end
end

function EffectUtils:RemoveAllEffects(target: Model)
    if not activeEffects[target] then return end

    for effectName in activeEffects[target] do
        EffectUtils:RemoveEffect(target, effectName)
    end
end

return EffectUtils