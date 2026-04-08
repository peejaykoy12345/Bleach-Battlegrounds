local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationPlayer = {}

local cachedTracks: {[Model]: {[string]: AnimationTrack}} = {}

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

local function setupCleanup(character: Model)
    if cachedTracks[character] then return end

    cachedTracks[character] = {}

    character.Destroying:Connect(function()
        local tracks = cachedTracks[character]
        if not tracks then return end

        for _, track in pairs(tracks) do
            track:Stop()
            track:Destroy()
        end

        cachedTracks[character] = nil
    end)
end

function AnimationPlayer:Play(character: Model, animationId: number, playOptionsParams: {Priority: number}? )
    playOptionsParams = playOptionsParams or {}

    local animator = getAnimator(character)
    if not animator then return nil end

    setupCleanup(character)

    local characterCache = cachedTracks[character]

    if not characterCache[animationId] then
        local animation = ReplicatedStorage.Animations:FindFirstChild(tostring(animationId))

        if not animation then
            animation = Instance.new("Animation")
            animation.AnimationId = "rbxassetid://" .. animationId
            animation.Name = animationId
            animation.Parent = ReplicatedStorage.Animations
        end

        local track = animator:LoadAnimation(animation)

        if playOptionsParams.Priority then
            track.Priority = Enum.AnimationPriority["Action" .. tostring(playOptionsParams.Priority)]
        end

        characterCache[animationId] = track
    end

    local track = characterCache[animationId]
    track:Play()

    return track
end

function AnimationPlayer:Stop(character: Model, animationId: string)
    local characterCache = cachedTracks[character]
    if not characterCache then return end

    local track = characterCache[animationId]
    if not track then return end

    track:Stop()
end

function AnimationPlayer:StopAnimation(track: AnimationTrack)
    track:Stop()
end

return AnimationPlayer