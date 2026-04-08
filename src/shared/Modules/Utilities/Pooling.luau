local ServerStorage = game:GetService("ServerStorage")

local pooledFolder = Instance.new("Folder", ServerStorage)
pooledFolder.Name = "PooledFolder"
local pool = {} 

local Pooling = {}

function Pooling.GetPooledObject(vfxTemplate: Instance): Instance
	if vfxTemplate == nil then 
		warn("VFX TEMPLATE IS NIL")
		return
	end
	
	pool[vfxTemplate] = pool[vfxTemplate] or {}
	local typePool = pool[vfxTemplate]
	pool[vfxTemplate] = typePool

	local vfx: Instance
	if #typePool > 0 then
		vfx = table.remove(typePool)
	else
		vfx = vfxTemplate:Clone()
	end

	return vfx
end

function Pooling.Return(vfx: Instance, template: Instance)
    vfx.Parent = pooledFolder
    pool[template] = pool[template] or {}
    table.insert(pool[template], vfx)
end

return Pooling