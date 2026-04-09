local Velocity = {}

function Velocity.CreateBV(parent: Instance, MaxForce: Vector3)
    local bv = Instance.new("BodyVelocity")
	bv.MaxForce = MaxForce or bv.MaxForce
	bv.Parent = parent
	return bv
end

type BodyVelocityParams = {
	Velocity: Vector3,
	Attachment: Attachment?,
	MaxForce: Vector3?,
	Lifetime: number?,
}

function Velocity.CreateBodyVelocity(parent: Instance, params: BodyVelocityParams): BodyVelocity
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = params.MaxForce or Vector3.new(9999999, 9999999, 99999999)
	bv.Velocity = params.Velocity or Vector3.new(0, 0, 0)
	bv.Parent = parent

	local lifetime = params.Lifetime
	if lifetime then
		task.delay(lifetime, function()
			bv:Destroy()
		end)
	end

	return bv
end

type LinearVelocityParams = {
	Velocity: Vector3,
	Attachment: Attachment?,
	MaxForce: number?,
	Lifetime: number?,
	Name: string?,
	RelativeTo: "World" | "Attachment"?,
}

function Velocity.ParentAndCreateAttachment(parent: Instance)
	local att = Instance.new("Attachment", parent)
	return att
end

function Velocity.CreateLV(parent: Instance, params: LinearVelocityParams)
	local att = Velocity.ParentAndCreateAttachment(parent)

	local lv = Instance.new("LinearVelocity")
	lv.MaxForce = params.MaxForce or math.huge
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	lv.RelativeTo = if params.RelativeTo == "World" then Enum.ActuatorRelativeTo.World elseif params.RelativeTo == "Attachment" then Enum.ActuatorRelativeTo.Attachment0 else Enum.ActuatorRelativeTo.World
	lv.VectorVelocity = params.Velocity
	lv.Attachment0 = params.Attachment or att
	lv.Name = params.Name or "LinearVelocity"
	lv.Parent = parent

	local lifetime = params.Lifetime
	if lifetime then
		task.delay(lifetime, function()
			lv:Destroy()
			att:Destroy()
		end)
	end

	return lv, att
end

return Velocity