local Player = game.Players.LocalPlayer

local function getRemote()
    -- Strictly check Character only
    local tool = Player.Character:FindFirstChild("F3X")
    if tool then
        local bf = tool:FindFirstChildOfClass("BindableFunction")
        if bf then 
            local rf = bf:FindFirstChildOfClass("RemoteFunction")
            if rf then return rf end
        end
    end
    return nil
end

local classNames = {Part = "Normal", TrussPart = "Truss", WedgePart = "Wedge", CornerWedgePart = "Corner", SpawnLocation = "Spawn"}
local F3X = {}

function F3X.Object(object)
    if not object then return nil end
    local proxy = newproxy(true)
    local meta = getmetatable(proxy)
    
    meta.__index = function(t, k) return object[k] end
    meta.__newindex = function(t, k, v)
        F3X.Edit(object, {[k] = v})
    end
    
    proxy.Object = object
    
    function proxy:AddMesh() 
        local remote = getRemote()
        if not remote then return nil end
        return F3X.Object(remote:InvokeServer("CreateMeshes", {{Part = object}})[1]) 
    end
    
    -- Optimized AddLight and AddDecoration to be more reliable
    function proxy:AddLight(lType) 
        local remote = getRemote()
        if not remote then return nil end
        return F3X.Object(remote:InvokeServer("CreateLights", {{Part = object, LightType = lType or "PointLight"}})[1]) 
    end

    function proxy:Destroy() 
        local remote = getRemote()
        if remote then remote:InvokeServer("Remove", {object}) end
    end
    
    return proxy
end

function F3X.Edit(objects, properties)
    local remote = getRemote()
    if not remote then return end
    
    local objList = type(objects) == "table" and objects or {objects}
    for _, obj in pairs(objList) do
        -- Grouped standard properties to reduce remote overhead
        if properties.CFrame then remote:InvokeServer("SyncMove", {{Part = obj, CFrame = properties.CFrame}}) end
        if properties.Size then remote:InvokeServer("SyncResize", {{Part = obj, Size = properties.Size}}) end
        if properties.Color then remote:InvokeServer("SyncColor", {{Part = obj, Color = properties.Color}}) end
        
        if properties.Material or properties.Transparency or properties.Reflectance then
            remote:InvokeServer("SyncMaterial", {{
                Part = obj, 
                Material = properties.Material or obj.Material, 
                Transparency = properties.Transparency or obj.Transparency, 
                Reflectance = properties.Reflectance or obj.Reflectance
            }}) 
        end
        
        if properties.Shape then remote:InvokeServer("SyncShape", {{Part = obj, Shape = properties.Shape}}) end
    end
end

function F3X.new(className, parent)
    local remote = getRemote()
    if not remote then 
        warn("F3X Tool must be EQUIPPED to build!") 
        return nil 
    end
    local f3xName = classNames[className] or "Normal"
    local obj = remote:InvokeServer("CreatePart", f3xName, CFrame.new(), parent or workspace)
    return F3X.Object(obj)
end

return F3X
