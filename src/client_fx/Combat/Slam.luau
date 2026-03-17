local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SlamVFX = ReplicatedStorage.Assets.Effects.Combat.Downslam

local RaycastHelper = require(ReplicatedStorage.Packages.RaycastHelper)

local RocksModule = require(script.Parent.RocksModule)
local VFXUtils = require(ReplicatedStorage.Shared.Utils.VFXUtils)

local module = {}

function module:Start(args)
    local target = args.target
    local fxDelay = args.fxDelay or 0

    local hrp = target:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local CanContinue = true
    local connection: RBXScriptConnection?

    task.wait(fxDelay)
    if not CanContinue then
        if connection then connection:Disconnect(); connection = nil end
        return
    end

    connection = RunService.Heartbeat:Connect(function()
        if not CanContinue then
            if connection then connection:Disconnect(); connection = nil end
            return
        end

        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = {target}

        local result = RaycastHelper.raycast({
            origin = hrp.Position,
            direction = Vector3.new(0, -4, 0),
            rayParams = rayParams
        })

        if result then
            local pos = result.Position + Vector3.new(0, SlamVFX.Size.Y / 2, 0)

            local vfx = SlamVFX:Clone()
            vfx.CFrame = CFrame.new(pos)
            vfx.Parent = workspace

            Debris:AddItem(vfx, 3)

            VFXUtils.emitEveryParticleEmitter(vfx)

            RocksModule.Ground(pos, 7, Vector3.new(0.7, .5, 0.7) * 2, nil, 8, false, 1.4)
            CanContinue = false
        end
    end)
end

return module