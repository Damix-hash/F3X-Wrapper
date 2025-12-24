local Player = game.Players.LocalPlayer

-- Dynamically find the remote every time to prevent "nil" errors if the tool is moved
local function getRemote()
    local tool = Player.Character:FindFirstChild("F3X") or Player.Backpack:FindFirstChild("F3X")
    if tool then
        local bf = tool:FindFirstChildOfClass("BindableFunction")
        if bf then return bf:FindFirstChildOfClass("RemoteFunction") end
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
        local edited = {}
        edited[k] = v
        F3X.Edit(object, edited)
    end
    
    proxy.Object = object
    
    -- Creation Methods (Wraps new objects back into F3X.Object)
    function proxy:AddMesh() 
        local res = getRemote():InvokeServer("CreateMeshes", {{Part = object}})
        return F3X.Object(res[1]) 
    end
    function proxy:AddDecal() 
        local res = getRemote():InvokeServer("CreateTextures", {{Part = object, Face = Enum.NormalId.Front, TextureType = "Decal"}})
        return F3X.Object(res[1]) 
    end
    function proxy:AddTexture() 
        local res = getRemote():InvokeServer("CreateTextures", {{Part = object, Face = Enum.NormalId.Front, TextureType = "Texture"}})
        return F3X.Object(res[1]) 
    end
    function proxy:AddLight(lType) 
        local res = getRemote():InvokeServer("CreateLights", {{Part = object, LightType = lType or "PointLight"}})
        return F3X.Object(res[1]) 
    end
    function proxy:AddDecoration(dType) 
        local res = getRemote():InvokeServer("CreateDecorations", {{Part = object, DecorationType = dType or "Smoke"}})
        return F3X.Object(res[1]) 
    end
    
    function proxy:Destroy() getRemote():InvokeServer("Remove", {object}) end
    return proxy
end

function F3X.Edit(objects, properties)
    local remote = getRemote()
    if not remote then return end
    
    local objList = type(objects) == "table" and objects or {objects}
    for _, obj in pairs(objList) do
        -- Physical & Transform
        if properties.CFrame then remote:InvokeServer("SyncMove", {{Part = obj, CFrame = properties.CFrame}}) end
        if properties.Size then remote:InvokeServer("SyncResize", {{Part = obj, Size = properties.Size}}) end
        if properties.Anchored ~= nil then remote:InvokeServer("SyncAnchor", {{Part = obj, Anchored = properties.Anchored}}) end
        if properties.CanCollide ~= nil then remote:InvokeServer("SyncCollision", {{Part = obj, CanCollide = properties.CanCollide}}) end
        
        -- Appearance
        if properties.Color then remote:InvokeServer("SyncColor", {{Part = obj, Color = properties.Color}}) end
        if properties.Material or properties.Transparency or properties.Reflectance then
            remote:InvokeServer("SyncMaterial", {{
                Part = obj, 
                Material = properties.Material or obj.Material, 
                Transparency = properties.Transparency or obj.Transparency, 
                Reflectance = properties.Reflectance or obj.Reflectance
            }}) 
        end
        
        -- Shapes (Sphere/Cylinder)
        if properties.Shape then remote:InvokeServer("SyncShape", {{Part = obj, Shape = properties.Shape}}) end

        -- Sub-Object Sync
        if obj:IsA("SpecialMesh") then
            properties.Part = obj.Parent
            remote:InvokeServer("SyncMesh", {properties})
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            properties.Part = obj.Parent
            properties.TextureType = obj.ClassName
            remote:InvokeServer("SyncTexture", {properties})
        elseif obj:IsA("Light") then
            properties.Part = obj.Parent
            properties.LightType = obj.ClassName
            remote:InvokeServer("SyncLighting", {properties})
        end
    end
end

function F3X.new(className, parent)
    local remote = getRemote()
    if not remote then warn("No F3X Tool Found") return nil end
    local f3xName = classNames[className] or "Normal"
    local obj = remote:InvokeServer("CreatePart", f3xName, CFrame.new(), parent or workspace)
    return F3X.Object(obj)
end

return F3X
