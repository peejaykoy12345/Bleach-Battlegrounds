local ServerScriptService = game:GetService("ServerScriptService")

local AsyncTimer = require(ServerScriptService.Server.Utilities.AsyncTimer)

local HoverService = {}

local CharData = {}

local DEFAULT_HEIGHT = 1
local DEFAULT_DURATION = 10

function HoverService:Enable(char: Model, duration: number?, height: number?)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	if CharData[char] then
		HoverService:Extend(char, duration or DEFAULT_DURATION)
		return
	end

	local bodyPos = Instance.new("BodyPosition")
	bodyPos.Position = Vector3.new(hrp.Position.X, hrp.Position.Y + (height or DEFAULT_HEIGHT), hrp.Position.Z)
	bodyPos.MaxForce = Vector3.new(0, 200000, 0)
	bodyPos.P = 50000 
	bodyPos.D = 500 
	bodyPos.Parent = hrp

	local timer = AsyncTimer.new(duration or DEFAULT_DURATION)
	timer.timeout:Connect(function()
		self:Disable(char)
	end)

	timer:Start()

	CharData[char] = {
		bodyPos = bodyPos,
		height = height or DEFAULT_HEIGHT,
		timer = timer,
	}
end

function HoverService:Disable(char: Model)
	local data = CharData[char]
	if not data then return end

	if data.bodyPos then
		data.bodyPos:Destroy()
	end

	if data.timer then
		data.timer:Stop()
	end

	CharData[char] = nil
end

function HoverService:Toggle(char: Model, state: boolean, duration: number?)
	if state then
		HoverService:Enable(char, duration)
	else
		HoverService:Disable(char)
	end
end

function HoverService:AsyncToggle(char: Model, state: boolean, duration: number?)
	task.spawn(function()
		self:Toggle(char, state, duration)
	end)
end

function HoverService:Extend(char: Model, extraTime: number)
	local data = CharData[char]
	if not data then return end

	data.timer:Extend(extraTime)
end

function HoverService:ResetHoverTimer(char: Model)
	local data = CharData[char]
	if not data then return end

	data.timer:Reset()
end

function HoverService:Cleanup(char: Model)
	HoverService:Disable(char)
end

return HoverService