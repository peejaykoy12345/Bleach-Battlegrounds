local ServerScriptService = game:GetService("ServerScriptService")

local Asynctimer = require(ServerScriptService.Server.Utilities.AsyncTimer)

local EffectUtils = {}
EffectUtils.EffectVFX = {
    Fire = script.FireVFX,
}
EffectUtils.EffectFunctions = {
    Fire = function(target: Model)
        local humanoid = target:FindFirstChild("Humanoid")
        if not humanoid then return end

        while true do
            task.wait(0.5)
            humanoid:TakeDamage(5)
        end
    end,
}

export type effects = "Fire"

type EffectEntry = {
    VFX: Attachment,
    Timer: Asynctimer.AsyncTimerType,
    EffectCoroutine: thread,
}

-- {[target] = {[effectName] = EffectEntry}}
local activeEffects: { [Model]: { [string]: EffectEntry } } = {}

function EffectUtils:ApplyEffect(target: Model, effectName: effects, duration: number)
    local vfx = self.EffectVFX[effectName]
    if not vfx then
        warn(`{effectName} does not have a vfx set`)
        return
    end

    local effectFn = self.EffectFunctions[effectName]
    if not effectFn then
        warn(`No effect function found for {effectName}`)
        return
    end

    activeEffects[target] = activeEffects[target] or {}
    

    local existing = activeEffects[target][effectName]

    if existing then
        existing.Timer:Reset()
        return
    end

    activeEffects[target][effectName] = activeEffects[target][effectName] or {}

    activeEffects[target][effectName].VFX = vfx:Clone()
    activeEffects[target][effectName].VFX.Parent = target.HumanoidRootPart
    
    activeEffects[target][effectName].EffectCoroutine = coroutine.create(function()
        effectFn(target)
    end)
    coroutine.resume(activeEffects[target][effectName].EffectCoroutine)

    activeEffects[target][effectName].Timer = Asynctimer.new(duration)
    activeEffects[target][effectName].Timer.timeout:Connect(function()
        EffectUtils:RemoveEffect(target, effectName)
    end)

    activeEffects[target][effectName].Timer:Start()
end

function EffectUtils:RemoveEffect(target: Model, effectName: effects)
    if not activeEffects[target] or not activeEffects[target][effectName] then return end

    local existing = activeEffects[target][effectName]
    if existing.Timer then
        existing.Timer:Stop()
    end
    if existing.VFX then
        existing.VFX:Destroy()
    end
    if existing.EffectCoroutine and coroutine.status(existing.EffectCoroutine) ~= "dead"  then
        coroutine.close(existing.EffectCoroutine)
    end

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