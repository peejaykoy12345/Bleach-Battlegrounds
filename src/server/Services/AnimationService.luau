local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local AnimationService = Knit.CreateService{
    Name = "AnimationService",
    Client = {},
}

local cachedAnimations = {}

local function getAnimator(character: Model)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        warn("No humanoid found")
        return nil
    end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end

    return animator
end

function AnimationService:KnitInit()
    local animationLoader = workspace.AnimationLoader
    local humanoid = animationLoader:FindFirstChildOfClass("Humanoid")
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")

    if not animator then
        warn("[AnimationService] No Animator found on AnimationLoader rig")
        return
    end

    local animationAssets = ReplicatedStorage.Animations

    task.spawn(function()
        for _, animationAsset in pairs(animationAssets:GetChildren()) do
            if not animationAsset:IsA("Animation") then continue end

            local track = animator:LoadAnimation(animationAsset)
            track:Play()
            track.Stopped:Wait()
        end

        print("Finished preplaying animations")
    end)
end

function AnimationService:Play(character: Model, animationId: string)
    local animator = getAnimator(character)
    if not animator then return nil end

    if not cachedAnimations[animationId] then
        local animation = ReplicatedStorage.Animations:FindFirstChild(tostring(animationId))
        if animation then
            cachedAnimations[animationId] = animation
        else
            animation = Instance.new("Animation")
            animation.AnimationId = "rbxassetid://" .. animationId
            animation.Name = animationId
            animation.Parent = ReplicatedStorage.Animations
            cachedAnimations[animationId] = animation
        end
    end

    local track = animator:LoadAnimation(cachedAnimations[animationId])
    track:Play()

    return track
end

return AnimationService