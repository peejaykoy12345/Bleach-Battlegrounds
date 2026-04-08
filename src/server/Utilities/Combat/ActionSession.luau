local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")  

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Services
local AnimationPlayer = require(ReplicatedStorage.Shared.Modules.Utilities.AnimationPlayer)
local CooldownService = require(ServerScriptService.Server.Services.CooldownService)

-- Utils
local TableUtils = require(ReplicatedStorage.Shared.Utils.TableUtils)
local BufferInput = require(ServerScriptService.Server.Utilities.BufferInput)
local StateManager = require(ServerScriptService.Server.Utilities.Combat.StateManager)
local MoveUtils = require(ServerScriptService.Server.Utilities.Combat.MoveUtils)

local ActionSession = {}
ActionSession.__index = ActionSession

type cooldownParams = {
    cooldown: number
}

type statesParams = {
    sharedStates: {string},
    attackerStates: {string},
    targetStates: {string},
}

export type ActionSessionParams = {
    attacker: Model,
    actionName: string,
    actionType: "Default" | "Overrideable" | "Cooldown" | "Misc",
    cooldown: cooldownParams?,
    states: statesParams?,
    properties: {
        attackerProperties: {
            ["AutoRotate"]: boolean?,
            ["Anchored"]: boolean?
        },
        sharedProperties: {
            ["AutoRotate"]: boolean?,
            ["Anchored"]: boolean?
        },
        targetProperties: {
            ["AutoRotate"]: boolean?,
            ["Anchored"]: boolean?
        },
    }?
}

local CharacterAttackSessions = {}

function ActionSession.StopSession(char)
    local sessions = CharacterAttackSessions[char]
    if not sessions then return end
    for _, session in ipairs(sessions) do
        session:Stop(true)
    end
    CharacterAttackSessions[char] = nil
end

function ActionSession.new(params: ActionSessionParams)
    assert(params.attacker, "Attacker is required")
    assert(params.actionName, "actionName is required")
    assert(params.actionType, "ActionType is required")

    if not CharacterAttackSessions[params.attacker] then
        CharacterAttackSessions[params.attacker] = {}
    end

    local sessions = CharacterAttackSessions[params.attacker]
    for _, pastSession in ipairs(sessions) do
        if pastSession.actionType == "Overrideable" then
            pastSession:Stop(true)
        end
    end

    local self = setmetatable({}, ActionSession)

    self.attacker = params.attacker
    self.actionName = params.actionName
    self.actionType = params.actionType
    self.cooldown = params.cooldown
    self.states = params.states
    self.properties = params.properties
    self.animations = {}
    self.targets = {}
    self.options = params

    self.connections = {}
    self.hitboxes = {}
    self.welds = {}

    self.stopped = false

    table.insert(CharacterAttackSessions[self.attacker], self)

    local conn

    conn = self.attacker.Humanoid.Died:Connect(function()
        self:Stop(true)
        conn:Disconnect()
    end)

    return self
end

function ActionSession:InitTarget(target: Model)
    ActionSession.StopSession(target)

    self:SetStatesTo(target, self.states.sharedStates)
    self:SetStatesTo(target, self.states.targetStates)

    if self.properties then
        self:_ApplyPropertiesTo(target, self.properties.sharedProperties)
        self:_ApplyPropertiesTo(target, self.properties.targetProperties)
    end

    MoveUtils:RegisterHit(self.attacker, target)

    table.insert(self.targets, target)
end

function ActionSession:WeldParts(primary: BasePart, part: BasePart, weldName: "Weld" | "WeldConstraint" | "Motor6D"): Weld | WeldConstraint | Motor6D
	local weld = MoveUtils:WeldParts(primary, part, weldName)
    
    table.insert(self.welds, weld)

    return weld
end

-------------------
--- ANIMATIONS ----
-------------------

type playOptionsParams = {
    Priority: number
}

function ActionSession:PlayAndAddAnimation(char: Model, animationId: number, playOptions: playOptionsParams?): Animation
    local anim = AnimationPlayer:Play(char, animationId, playOptions)
    self:AddAnimation(anim)

    return anim
end

function ActionSession:AddAnimation(animation: Animation)
    table.insert(self.animations, animation)
end

function ActionSession:StopAnimation(animation: AnimationTrack)
    TableUtils:ArrayRemove(self.animations, animation)
    AnimationPlayer:StopAnimation(animation)
end

function ActionSession:StopAllAnimations()
    for _, anim in ipairs(self.animations) do
        AnimationPlayer:StopAnimation(anim)
    end
    self.animations = {}
end

function ActionSession:SetStatesTo(target: Model, states)
    if not states then return end

    for _, state in ipairs(states) do 
        StateManager.SetState(target, state, true)
    end
end

function ActionSession:RemoveStatesTo(target: Model, states)
    if not states then return end

    for _, state in ipairs(states) do 
        StateManager.RemoveState(target, state)
    end
end

function ActionSession:_ApplyPropertiesTo(target: Model, props: {[string]: any}?)
    if not props then return end

    local humanoid = target:FindFirstChildOfClass("Humanoid")
    local hrp = target:FindFirstChild("HumanoidRootPart")

    if props.AutoRotate == false and humanoid then
        humanoid.AutoRotate = false
    end

    if props.Anchored == true and hrp then
        hrp.Anchored = true
    end
end

function ActionSession:_RemovePropertiesFrom(target: Model, props: {[string]: any}?)
    if not props then return end

    local humanoid = target:FindFirstChildOfClass("Humanoid")
    local hrp = target:FindFirstChild("HumanoidRootPart")

    if props.AutoRotate == false and humanoid then
        humanoid.AutoRotate = true
    end

    if props.Anchored == true and hrp then
        hrp.Anchored = false
    end
end

function ActionSession:BulkAddConnections(connections: {RBXScriptConnection})
    for _, connection in connections do
        table.insert(self.connections, connection)
    end
end

function ActionSession:AddConnection(connection: RBXScriptConnection)
    table.insert(self.connections, connection)
end

function ActionSession:Start()
    local states = self.states
    if states then
        if states.sharedStates then
            self:SetStatesTo(self.attacker, states.sharedStates)
        end
        
        if states.attackerStates then
            self:SetStatesTo(self.attacker, states.attackerStates)
        end
    end

    if self.properties then
        self:_ApplyPropertiesTo(self.attacker, self.properties.attackerProperties)
        self:_ApplyPropertiesTo(self.attacker, self.properties.sharedProperties)
    end
end

function ActionSession:Stop(forcestop: boolean?)
    local sessions = CharacterAttackSessions[self.attacker]
    if sessions then
        TableUtils:ArrayRemove(sessions, self)
    end

    self.stopped = true

    if forcestop then
        self:StopAllAnimations()
    end

    if self.hitbox then
        self.hitbox:Stop()
        self.hitbox = nil
    end

    if self.hitboxes then
        for _, hitbox in ipairs(self.hitboxes) do
            hitbox:Stop()
        end
        self.hitboxes = nil
    end

    if self.cooldown then
        CooldownService:SetCooldown(self.attacker, self.actionName, self.cooldown.cooldown)
    end

    if self.states then
        self:RemoveStatesTo(self.attacker, self.states.attackerStates)
        self:RemoveStatesTo(self.attacker, self.states.sharedStates)

        for _, target in ipairs(self.targets) do
            self:RemoveStatesTo(target, self.states.sharedStates)
            self:RemoveStatesTo(target, self.states.targetStates)
        end
    end

    if self.properties then
        self:_RemovePropertiesFrom(self.attacker, self.properties.attackerProperties)
        self:_RemovePropertiesFrom(self.attacker, self.properties.sharedProperties)

        for _, target in ipairs(self.targets) do
            self:_RemovePropertiesFrom(target, self.properties.sharedProperties)
            self:_RemovePropertiesFrom(target, self.properties.targetProperties)
        end
    end

    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end

    for _, weld in ipairs(self.welds) do
        weld:Destroy()
    end

    if self.extraStopFunction then
        self.extraStopFunction(self) 
    end

    local plr = Players:GetPlayerFromCharacter(self.attacker) -- When buffering input and done with a session try to consume it
    if plr then
        BufferInput.TryConsumeBuffer(plr)
    end

    self = nil
end

export type ActionSessionType = typeof(ActionSession)

return ActionSession :: ActionSessionType