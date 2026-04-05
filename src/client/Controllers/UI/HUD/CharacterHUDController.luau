local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Replica = require(ReplicatedStorage.Packages.Replica)

local Network = require(ReplicatedStorage.Shared.Modules.Network)

local plr = Players.LocalPlayer

local ScreenGUI = plr:WaitForChild("PlayerGui"):WaitForChild("HUD")
local CooldownFrame = ScreenGUI:WaitForChild("Cooldowns")
local Template = CooldownFrame.Template

local UltimateFrame = ScreenGUI:WaitForChild("Ultimate")
local Fill = UltimateFrame.Fill
local Title = UltimateFrame.Title

local CharacterHUDController = Knit.CreateController{
    Name = "CharacterHUDController"
}

local CONFIG = {
    ULTIMATE_MAX_X_VALUE = 0.857
}

function CharacterHUDController:_HandleMoveChanges(data)
    for _, button in ipairs(CooldownFrame:GetChildren()) do
        if not button:IsA("ImageButton") or button.Name == "Template" then continue end

        button:Destroy()
    end

    for input, moveName in pairs(data) do
        if input == "Awakening" then continue end

        local button = Template:Clone()
        button.Name = moveName
        button.Frame.SkillName.Text = moveName
        button.Frame.Order.Text = input
        button.Visible = true
        button.Parent = CooldownFrame
    end
end

function CharacterHUDController:_HandleUltimateChange(ultimateTitle: string, ultimateValue: number)
    Title.Text = ultimateTitle
    
    local x_size = math.lerp(0, CONFIG.ULTIMATE_MAX_X_VALUE, ultimateValue / 100)
    Fill.Size = UDim2.fromScale(x_size, Fill.Size.Y.Scale)
end

function CharacterHUDController:_ModifyFrameSize(frame: Frame, size: number)
    frame.Size = UDim2.fromScale(frame.Size.X.Scale, size)
    frame.Position = UDim2.fromScale(frame.Position.X.Scale, 1 - size)
end

function CharacterHUDController:KnitStart()
    Network.Character.packets.InitializeReplica.send()
    Replica.OnNew("CharacterData", function(replica)
        self.replica = replica

        local awakeningName = replica.Data.Moves["Awakening"]

        CharacterHUDController:_HandleMoveChanges(replica.Data.Moves)
        CharacterHUDController:_HandleUltimateChange(awakeningName, replica.Data.Ultimate)

        replica:OnSet({"Moves"}, function(newMoves)
            awakeningName = newMoves.Awakening
            CharacterHUDController:_HandleUltimateChange(awakeningName, replica.Data.Ultimate)
            CharacterHUDController:_HandleMoveChanges(newMoves)
        end)

        replica:OnSet({"Ultimate"}, function(newUltimate)
            local awakeningTitle = replica.Data.Moves["Awakening"]
            CharacterHUDController:_HandleUltimateChange(awakeningTitle, newUltimate)
        end)
    end)

    Network.Character.packets.OnMoveCooldown.listen(function(data)
        local CooldownTime = data.CooldownTime
        local MoveName = data.MoveName
        local TimeOfSent = data.TimeOfSent

        local moveButton = CooldownFrame:FindFirstChild(MoveName)
        if not moveButton then
            warn(`{MoveName} is not found in cooldown frames`)
            return
        end

        local moveFrame = moveButton.Frame
        local fillFrame = moveFrame.Fill

        -- Account for time already elapsed since server sent the packet
        local elapsed = os.time() - TimeOfSent
        local remaining = math.max(0, CooldownTime - elapsed)
        local remainingRatio = remaining / CooldownTime

        fillFrame.Trans.Transparency = NumberSequence.new(0.5)
        self:_ModifyFrameSize(fillFrame, remainingRatio)

        local tween = TweenService:Create(fillFrame, TweenInfo.new(remaining, Enum.EasingStyle.Linear), {
            Size = UDim2.fromScale(fillFrame.Size.X.Scale, 0),
            Position = UDim2.fromScale(fillFrame.Position.X.Scale, 1)
        })
        tween:Play()
        tween.Completed:Connect(function()
            fillFrame.Trans.Transparency = NumberSequence.new(0)
        end)
    end)
end

return CharacterHUDController