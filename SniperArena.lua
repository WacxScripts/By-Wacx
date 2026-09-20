local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")

--==================================================
-- WACX AUTO RELOAD / REJOIN
-- Put your hosted RAW GitHub script URL below.
-- Example: https://raw.githubusercontent.com/USER/REPO/main/sniperarena.lua
--==================================================
local WACX_RELOAD_URL = ""

local function QueueWacxReload()
    if WACX_RELOAD_URL == "loadstring(game:HttpGet("https://raw.githubusercontent.com/WacxScripts/By-Wacx/main/SniperArena.lua"))()
" then
        return
    end

    local QueueOnTeleport =
        rawget(_G, "queue_on_teleport")
        or rawget(_G, "queueonteleport")
        or (syn and syn.queue_on_teleport)
        or (fluxus and fluxus.queue_on_teleport)

    if type(QueueOnTeleport) ~= "function" then
        return
    end

    local Loader = string.format([[
        pcall(function()
            loadstring(game:HttpGet(%q))()
        end)
    ]], WACX_RELOAD_URL)

    pcall(QueueOnTeleport, Loader)
end

QueueWacxReload()

--==================================================

local ENV = getgenv and getgenv() or _G
if ENV.WacxSniperArena then
    pcall(function()
        ENV.WacxSniperArena:Unload()
    end)
end

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
local ThemeManager = nil
local SaveManager = nil

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({
    Title            = "Wacx/Sniper Arena",
    Footer           = "Wacx • Sniper Arena",
    Icon             = "crosshair",
    ToggleKeybind    = Enum.KeyCode.RightControl,
    Center           = true,
    AutoShow         = true,
    Resizable        = true,
    Size             = UDim2.fromOffset(720, 560),
    MinSize          = UDim2.fromOffset(500, 380),
    MobileButtonsSide = "Left",
    ShowCustomCursor = false,
    AlwaysOnTop      = true,
    NotifySide       = "Right",
})

-- Compatibility adapter: keeps the original feature callbacks/settings intact
-- while rendering every control through the Obsidian UI library.
local UIId = 0
local function NextUIId(prefix)
    UIId = UIId + 1
    return (prefix or "Control") .. "_" .. tostring(UIId)
end

local function RoundingFromIncrement(increment)
    increment = tonumber(increment) or 1
    if increment >= 1 then return 0 end
    local n = 0
    while n < 6 and math.abs(increment - math.floor(increment + 0.5)) > 1e-9 do
        increment = increment * 10
        n = n + 1
    end
    return n
end

-- Native Obsidian bridge. Every original feature callback is kept intact.
local function CompatTab(actualTab)
    local self = { Tab = actualTab, Group = nil, LeftCount = 0, RightCount = 0 }

    function self:CreateSection(name, side)
        side = side or "auto"
        local ok, group
        if side == "right" then
            ok, group = pcall(function() return self.Tab:AddRightGroupbox(tostring(name)) end)
            self.RightCount = self.RightCount + 1
        elseif side == "left" then
            ok, group = pcall(function() return self.Tab:AddLeftGroupbox(tostring(name)) end)
            self.LeftCount = self.LeftCount + 1
        elseif self.LeftCount <= self.RightCount then
            ok, group = pcall(function() return self.Tab:AddLeftGroupbox(tostring(name)) end)
            self.LeftCount = self.LeftCount + 1
        else
            ok, group = pcall(function() return self.Tab:AddRightGroupbox(tostring(name)) end)
            self.RightCount = self.RightCount + 1
        end
        if not ok or not group then
            error("Obsidian failed to create groupbox '" .. tostring(name) .. "': " .. tostring(group))
        end
        self.Group = group
        return group
    end

    function self:EnsureGroup()
        if not self.Group then self:CreateSection("General") end
        return self.Group
    end

    function self:CreateLabel(data)
        local group = self:EnsureGroup()
        local text = type(data) == "table" and data.Text or tostring(data)
        return group:AddLabel(tostring(text), true)
    end

    function self:CreateToggle(data)
        local group = self:EnsureGroup()
        local id = NextUIId("Toggle")
        return group:AddToggle(id, {
            Text = tostring(data.Name or id),
            Default = data.CurrentValue == true,
            Callback = type(data.Callback) == "function" and data.Callback or function() end,
        })
    end

    function self:CreateDropdown(data)
        local group = self:EnsureGroup()
        local id = NextUIId("Dropdown")
        local options = data.Options or {}
        local default = data.CurrentOption
        if default == nil and #options > 0 then default = options[1] end
        return group:AddDropdown(id, {
            Values = options,
            Default = default,
            Multi = false,
            Text = tostring(data.Name or id),
            Callback = type(data.Callback) == "function" and data.Callback or function() end,
        })
    end

    function self:CreateSlider(data)
        local group = self:EnsureGroup()
        local id = NextUIId("Slider")
        local range = data.Range or {0, 100}
        local min = tonumber(range[1]) or 0
        local max = tonumber(range[2]) or 100
        local default = tonumber(data.CurrentValue)
        if default == nil then default = min end
        default = math.clamp(default, min, max)
        return group:AddSlider(id, {
            Text = tostring(data.Name or id),
            Default = default,
            Min = min,
            Max = max,
            Rounding = RoundingFromIncrement(data.Increment),
            Suffix = tostring(data.Suffix or ""),
            Callback = type(data.Callback) == "function" and data.Callback or function() end,
        })
    end

    function self:CreateInput(data)
        local group = self:EnsureGroup()
        local id = NextUIId("Input")
        local ok, input = pcall(function()
            return group:AddInput(id, {
                Text = tostring(data.Name or id),
                Default = tostring(data.CurrentValue or data.Default or ""),
                Placeholder = tostring(data.Placeholder or ""),
                Numeric = data.Numeric == true,
                Finished = data.Finished == true,
                Callback = type(data.Callback) == "function" and data.Callback or function() end,
            })
        end)
        if not ok then
            warn("[Wacx/Sniper Arena] Input error:", input)
        end
        return input
    end

    function self:CreateColorPicker(data)
        local group = self:EnsureGroup()
        local id = NextUIId("Color")
        local label = group:AddLabel(tostring(data.Name or id), true)
        local ok, picker = pcall(function()
            return label:AddColorPicker(id, {
                Default = data.Color or Color3.new(1, 1, 1),
                Title = tostring(data.Name or id),
                Callback = type(data.Callback) == "function" and data.Callback or function() end,
            })
        end)
        if not ok then
            warn("[Wacx/Sniper Arena] ColorPicker error:", picker)
        end
        return label
    end

    function self:CreateDivider()
        return self:EnsureGroup():AddDivider()
    end

    function self:CreateButton(data)
        return self:EnsureGroup():AddButton({
            Text = tostring(data.Name or "Button"),
            Func = type(data.Callback) == "function" and data.Callback or function() end,
        })
    end

    function self:CreateConfigManager(_)
        return self.Group
    end

    return self
end

local function Notify(data)
    data = data or {}
    local ok, err = pcall(function()
        Library:Notify({
            Title   = tostring(data.Title or "Wacx/Sniper Arena"),
            Description = tostring(data.Description or ""),
            Icon    = tostring(data.Icon or "bell"),
            Time = tonumber(data.Duration) or 5,
        })
    end)
    if not ok then
        warn("[Wacx/Sniper Arena] Notification error:", err)
    end
    return ok
end

local Settings = {
    Enabled             = true,
    Targets             = "Enemies",
    MaxDistance         = 3000,
    ColorMode           = "Feature",
    EnemyColor          = Color3.fromRGB(255, 70, 85),
    FriendlyColor       = Color3.fromRGB(80, 170, 255),
    BoxColor            = Color3.fromRGB(255, 255, 255),
    NameColor           = Color3.fromRGB(255, 255, 255),
    DistanceColor       = Color3.fromRGB(210, 210, 210),
    TracerColor         = Color3.fromRGB(255, 255, 255),
    ArrowColor          = Color3.fromRGB(255, 90, 90),
    Box                 = true,
    BoxStyle            = "Corner",
    BoxOutline          = true,
    BoxThickness        = 1,
    BoxWidth            = 100,
    BoxHeight           = 100,
    BoxYOffset          = 0,
    CornerLength        = 28,
    Name                = true,
    NameSize            = 13,
    Distance            = true,
    DistanceSize        = 12,
    HealthBar           = true,
    HealthText          = false,
    HealthThickness     = 3,
    HealthColorMode     = "Gradient",
    HealthCustomColor   = Color3.fromRGB(90, 255, 120),
    Tracers             = false,
    TracerOrigin        = "Bottom",
    TracerTarget        = "Feet",
    TracerOutline       = true,
    TracerThickness     = 1,
    Arrows              = true,
    ArrowRadius         = 230,
    ArrowSize           = 18,
    ArrowThickness      = 2,
    ArrowOutline        = true,
    ArrowOnlyOutsideFOV = true,
    Skeleton            = false,
    SkeletonThickness   = 1,
    SkeletonOutline     = false,
    Chams               = false,
    ChamsThroughWalls   = true,
    ChamsFillOpacity    = 35,
    ChamsOutlineOpacity = 100,
    ChamsUseESPColor    = false,
    ChamsFillColor      = Color3.fromRGB(255, 70, 85),
    ChamsOutlineColor   = Color3.fromRGB(255, 255, 255),
    DrawingOpacity      = 100,
    HideDead            = true,
    HideSelf            = true,
    DiscoveryInterval   = 0.08,
    EntityGracePeriod   = 1.25,
    CombatEnabled           = false,
    CombatTeamCheck         = true,
    CombatWallCheck         = true,
    CombatOnScreenOnly      = true,
    CombatMaxDistance       = 3000,
    CombatPriority          = "Crosshair",
    CombatTargetLock        = true,
    CombatSwitchDelay       = 0.1,
    CombatLockFOVScale      = 135,
    CombatHitbox            = "Head/Torso Weighted",
    CombatHeadChance        = 70,
    CombatPrediction        = false,
    CombatPredictionMs      = 45,
    CombatFOVVisible        = true,
    CombatFOVRadius         = 200,
    CombatFOVCenter         = "Screen Center",
    CombatFOVColor          = Color3.fromRGB(255, 255, 255),
    CombatFOVOpacity        = 70,
    CombatFOVThickness      = 1,
    CombatFOVSides          = 64,
    CombatFOVFilled         = false,
    CombatTargetIndicator   = true,
    CombatIndicatorColor    = Color3.fromRGB(255, 80, 90),
    CombatIndicatorSize     = 6,
    CombatImpactLine        = true,
    CombatImpactLineColor   = Color3.fromRGB(255, 80, 90),
    CombatImpactLineThickness = 1,
    CombatImpactLineOpacity = 100,
    CombatHybridCrosshairWeight = 60,
    CombatHybridDistanceWeight  = 25,
    CombatHybridHealthWeight    = 15,
}

local Controller = {
    Library  = Library,
    Window   = Window,
    Settings = Settings,
    Entries  = {},
    Connections = {},
    Unloaded = false,
}
ENV.WacxSniperArena = Controller

local DRAWING_AVAILABLE = typeof(Drawing) == "table" and typeof(Drawing.new) == "function"

local function newDrawing(kind, zIndex)
    if not DRAWING_AVAILABLE then return nil end
    local obj = Drawing.new(kind)
    obj.Visible = false
    pcall(function() obj.ZIndex = zIndex or 3 end)
    return obj
end

local function safeRemove(obj)
    if not obj then return end
    pcall(function()
        obj.Visible = false
        obj:Remove()
    end)
end

local function setLine(line, from, to, color, thickness, opacity)
    if not line then return end
    line.From        = from
    line.To          = to
    line.Color       = color
    line.Thickness   = thickness
    line.Transparency = opacity
    line.Visible     = true
end

local function hideDrawing(obj)
    if obj then obj.Visible = false end
end

local function makeLineArray(count, zIndex)
    local out = table.create(count)
    for i = 1, count do
        local line = newDrawing("Line", zIndex)
        if line then
            line.Thickness    = 1
            line.Transparency = 1
            line.Color        = Color3.new(1, 1, 1)
        end
        out[i] = line
    end
    return out
end

local function hideLines(lines)
    for _, line in ipairs(lines) do
        hideDrawing(line)
    end
end

local BODY_PARTS = {
    HumanoidRootPart = true, Head = true,
    UpperTorso = true, LowerTorso = true,
    LeftUpperArm = true, LeftLowerArm = true, LeftHand = true,
    RightUpperArm = true, RightLowerArm = true, RightHand = true,
    LeftUpperLeg = true, LeftLowerLeg = true, LeftFoot = true,
    RightUpperLeg = true, RightLowerLeg = true, RightFoot = true,
    Torso = true,
    ["Left Arm"] = true, ["Right Arm"] = true,
    ["Left Leg"] = true, ["Right Leg"] = true,
}

local R15_SKELETON = {
    { "Head", "UpperTorso" },
    { "UpperTorso", "LowerTorso" },
    { "UpperTorso", "LeftUpperArm" },
    { "LeftUpperArm", "LeftLowerArm" },
    { "LeftLowerArm", "LeftHand" },
    { "UpperTorso", "RightUpperArm" },
    { "RightUpperArm", "RightLowerArm" },
    { "RightLowerArm", "RightHand" },
    { "LowerTorso", "LeftUpperLeg" },
    { "LeftUpperLeg", "LeftLowerLeg" },
    { "LeftLowerLeg", "LeftFoot" },
    { "LowerTorso", "RightUpperLeg" },
    { "RightUpperLeg", "RightLowerLeg" },
    { "RightLowerLeg", "RightFoot" },
}

local R6_SKELETON = {
    { "Head", "Torso" },
    { "Torso", "Left Arm" },
    { "Torso", "Right Arm" },
    { "Torso", "Left Leg" },
    { "Torso", "Right Leg" },
}

local function getHighlightHolder(kind)
    local highlight = Workspace:FindFirstChild("Highlight")
    if not highlight then return nil end
    local group = highlight:FindFirstChild(kind)
    if not group then return nil end
    return group:FindFirstChild("HighlightHolder")
end

local function isExcludedVisualCandidate(model, entity)
    local node = model
    while node and node ~= entity do
        if node.Name == "Collider" or node.Name == "FreePart" then return true end
        node = node.Parent
    end
    return false
end

local function scoreVisualCandidate(model, entity)
    if not model or not model:IsA("Model") then return nil end
    if isExcludedVisualCandidate(model, entity) then return nil end
    local root = model:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then return nil end
    local hasTorso = model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")
    local score = 0
    if model == entity then
        score += 10
    elseif model.Parent == entity then
        score += 30
    end
    if model:GetAttribute("DisplayName") ~= nil then score += 40 end
    if model:GetAttribute("UserId") ~= nil then score += 40 end
    if model:GetAttribute("Controller") ~= nil then score += 15 end
    if model:GetAttribute("Setuped") == true then score += 10 end
    if model:FindFirstChildOfClass("Humanoid") then score += 20 end
    if model:FindFirstChild("Head") then score += 15 end
    if hasTorso then score += 20 end
    if model:FindFirstChild("LowerTorso") then score += 5 end
    return score
end

local function getVisualModel(entity)
    if not entity or not entity.Parent then return nil end
    local bestModel = nil
    local bestScore = -math.huge
    local ownScore = scoreVisualCandidate(entity, entity)
    if ownScore and ownScore > bestScore then
        bestModel = entity
        bestScore = ownScore
    end
    for _, descendant in ipairs(entity:GetDescendants()) do
        if descendant:IsA("Model") then
            local score = scoreVisualCandidate(descendant, entity)
            if score and score > bestScore then
                bestModel = descendant
                bestScore = score
            end
        end
    end
    return bestModel
end

local function getRoot(entity, visual)
    if visual then
        local root = visual:FindFirstChild("HumanoidRootPart")
        if root and root:IsA("BasePart") then return root end
    end
    if entity then
        local root = entity:FindFirstChild("HumanoidRootPart")
        if root and root:IsA("BasePart") then return root end
    end
    return nil
end

local function getDisplayName(entity, visual)
    if visual then
        local displayName = visual:GetAttribute("DisplayName")
        if displayName ~= nil and tostring(displayName) ~= "" then
            return tostring(displayName)
        end
    end
    return entity and entity.Name or "Unknown"
end

local function getUserId(visual)
    if not visual then return nil end
    local id = visual:GetAttribute("UserId")
    return tonumber(id)
end

local function getEntityIdentity(entity, visual)
    local userId = getUserId(visual)
    if userId and userId > 0 then
        return "uid:" .. tostring(math.floor(userId))
    end
    if entity then
        local fakeUserId = tonumber(entity:GetAttribute("FakeUserId"))
        if fakeUserId and fakeUserId > 0 then
            return "fake:" .. tostring(math.floor(fakeUserId))
        end
        return "name:" .. string.lower(entity.Name)
    end
    return nil
end

local function getHealth(entity, visual)
    local health    = entity and entity:GetAttribute("Health")
    local maxHealth = entity and entity:GetAttribute("MaxHealth")
    if typeof(health) ~= "number" or typeof(maxHealth) ~= "number" then
        local humanoid = visual and visual:FindFirstChildOfClass("Humanoid")
        if humanoid then
            if typeof(health) ~= "number" then health = humanoid.Health end
            if typeof(maxHealth) ~= "number" then maxHealth = humanoid.MaxHealth end
        end
    end
    health    = tonumber(health) or 0
    maxHealth = tonumber(maxHealth) or 100
    if health ~= health then health = 0 end
    if maxHealth ~= maxHealth or maxHealth <= 0 then maxHealth = 100 end
    return health, maxHealth
end

local function isDead(entity, health)
    if health <= 0 then return true end
    if not entity then return false end
    local state = entity:GetAttribute("State")
    if typeof(state) == "string" then
        state = string.lower(state)
        if state == "dead" or state == "died" then return true end
    end
    return false
end

local function getLocalRoot()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("Torso")
        or char:FindFirstChild("UpperTorso")
end

local function getDistance(root)
    local localRoot = getLocalRoot()
    if localRoot then return (localRoot.Position - root.Position).Magnitude end
    local camera = Workspace.CurrentCamera
    if camera then return (camera.CFrame.Position - root.Position).Magnitude end
    return math.huge
end

local function normalizeColor(value, fallback)
    if typeof(value) == "Color3" then return value end
    if type(value) == "table" then
        if typeof(value.Color) == "Color3" then return value.Color end
        local r = tonumber(value.R or value.r or value[1])
        local g = tonumber(value.G or value.g or value[2])
        local b = tonumber(value.B or value.b or value[3])
        if r and g and b then
            if r <= 1 and g <= 1 and b <= 1 then return Color3.new(r, g, b) end
            return Color3.fromRGB(r, g, b)
        end
    end
    return fallback or Color3.new(1, 1, 1)
end

local function getTargetColor(kind)
    if kind == "Friendly" then
        return normalizeColor(Settings.FriendlyColor, Color3.fromRGB(80, 170, 255))
    end
    return normalizeColor(Settings.EnemyColor, Color3.fromRGB(255, 70, 85))
end

local function getFeatureColor(feature, kind)
    if Settings.ColorMode == "Target" then return getTargetColor(kind) end
    if feature == "Box" then
        return normalizeColor(Settings.BoxColor, Color3.new(1, 1, 1))
    elseif feature == "Name" then
        return normalizeColor(Settings.NameColor, Color3.new(1, 1, 1))
    elseif feature == "Distance" then
        return normalizeColor(Settings.DistanceColor, Color3.fromRGB(210, 210, 210))
    elseif feature == "Tracer" then
        return normalizeColor(Settings.TracerColor, Color3.new(1, 1, 1))
    elseif feature == "Arrow" then
        return normalizeColor(Settings.ArrowColor, Color3.fromRGB(255, 90, 90))
    end
    return getTargetColor(kind)
end

local function getHealthColor(ratio, espColor)
    if Settings.HealthColorMode == "ESP Color" then return espColor end
    if Settings.HealthColorMode == "Custom" then
        return normalizeColor(Settings.HealthCustomColor, Color3.fromRGB(90, 255, 120))
    end
    return Color3.fromHSV(math.clamp(ratio, 0, 1) * 0.33, 1, 1)
end

local function shouldScanKind(kind)
    if Settings.Targets == "Both" then return true end
    if Settings.Targets == "Friendlies" then return kind == "Friendly" end
    return kind == "Enemy"
end

local function projectBoxCorners(camera, cf, size)
    local half = size * 0.5
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local count = 0
    for x = -1, 1, 2 do
        for y = -1, 1, 2 do
            for z = -1, 1, 2 do
                local world = cf * Vector3.new(half.X * x, half.Y * y, half.Z * z)
                local point = camera:WorldToViewportPoint(world)
                if point.Z > 0.1 then
                    minX = math.min(minX, point.X)
                    minY = math.min(minY, point.Y)
                    maxX = math.max(maxX, point.X)
                    maxY = math.max(maxY, point.Y)
                    count += 1
                end
            end
        end
    end
    if count == 0 then return nil end
    return minX, minY, maxX, maxY
end

local function getSyntheticBounds(camera, visual, root)
    local head   = visual:FindFirstChild("Head")
    local torso  = visual:FindFirstChild("UpperTorso") or visual:FindFirstChild("Torso")
    local height = 6
    local width  = 4
    local depth  = 2.5
    local centerY = root.Position.Y
    if head and head:IsA("BasePart") then
        local bottomY = root.Position.Y - 3
        local topY    = head.Position.Y + head.Size.Y * 0.5
        height  = math.clamp(topY - bottomY, 4.5, 9)
        centerY = (topY + bottomY) * 0.5
    elseif torso and torso:IsA("BasePart") then
        centerY = torso.Position.Y
    end
    local flatLook = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
    local cf
    if flatLook.Magnitude > 0.001 then
        flatLook = flatLook.Unit
        cf = CFrame.lookAt(
            Vector3.new(root.Position.X, centerY, root.Position.Z),
            Vector3.new(root.Position.X, centerY, root.Position.Z) + flatLook
        )
    else
        cf = CFrame.new(root.Position.X, centerY, root.Position.Z)
    end
    return projectBoxCorners(camera, cf, Vector3.new(width, height, depth))
end

local function getScreenBounds(visual)
    local camera = Workspace.CurrentCamera
    if not camera or not visual then return nil end
    local root = visual:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then return nil end
    local rootPoint = camera:WorldToViewportPoint(root.Position)
    if rootPoint.Z <= 0.1 then return nil end
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local projectedCorners = 0
    local bodyPartCount    = 0
    for _, part in ipairs(visual:GetChildren()) do
        if part:IsA("BasePart") and BODY_PARTS[part.Name] then
            bodyPartCount += 1
            local half = part.Size * 0.5
            local cf   = part.CFrame
            for x = -1, 1, 2 do
                for y = -1, 1, 2 do
                    for z = -1, 1, 2 do
                        local world = cf * Vector3.new(half.X * x, half.Y * y, half.Z * z)
                        local point = camera:WorldToViewportPoint(world)
                        if point.Z > 0.1 then
                            minX = math.min(minX, point.X)
                            minY = math.min(minY, point.Y)
                            maxX = math.max(maxX, point.X)
                            maxY = math.max(maxY, point.Y)
                            projectedCorners += 1
                        end
                    end
                end
            end
        end
    end
    if projectedCorners == 0 or bodyPartCount < 3 then
        local sx1, sy1, sx2, sy2 = getSyntheticBounds(camera, visual, root)
        if not sx1 then return nil end
        minX, minY, maxX, maxY = sx1, sy1, sx2, sy2
    end
    local width  = maxX - minX
    local height = maxY - minY
    if width <= 1 or height <= 1 then
        local sx1, sy1, sx2, sy2 = getSyntheticBounds(camera, visual, root)
        if not sx1 then return nil end
        minX, minY, maxX, maxY = sx1, sy1, sx2, sy2
        width  = maxX - minX
        height = maxY - minY
    end
    local cx = (minX + maxX) * 0.5
    local cy = (minY + maxY) * 0.5 + Settings.BoxYOffset
    width  = width  * (Settings.BoxWidth  / 100)
    height = height * (Settings.BoxHeight / 100)
    minX = cx - width  * 0.5
    maxX = cx + width  * 0.5
    minY = cy - height * 0.5
    maxY = cy + height * 0.5
    return {
        X      = minX, Y      = minY,
        Right  = maxX, Bottom = maxY,
        Width  = width, Height = height,
        Center = Vector2.new(cx, cy),
    }
end

local function createEntry(entity, kind)
    local entry = {
        Entity   = entity,
        Kind     = kind,
        Visual   = nil,
        Identity = nil,
        LastSeen = os.clock(),
        Box            = makeLineArray(8, 4),
        BoxOutline     = makeLineArray(8, 2),
        Name           = newDrawing("Text", 5),
        Distance       = newDrawing("Text", 5),
        HealthText     = newDrawing("Text", 5),
        HealthBackground = newDrawing("Line", 2),
        Health         = newDrawing("Line", 4),
        Tracer         = newDrawing("Line", 4),
        TracerOutline  = newDrawing("Line", 2),
        Arrow          = makeLineArray(3, 4),
        ArrowOutline   = makeLineArray(3, 2),
        Skeleton       = makeLineArray(#R15_SKELETON, 4),
        SkeletonOutline = makeLineArray(#R15_SKELETON, 2),
        Cham           = nil,
    }
    if entry.Name then
        entry.Name.Center  = true
        entry.Name.Outline = true
        entry.Name.Font    = 2
    end
    if entry.Distance then
        entry.Distance.Center  = true
        entry.Distance.Outline = true
        entry.Distance.Font    = 2
    end
    if entry.HealthText then
        entry.HealthText.Center  = false
        entry.HealthText.Outline = true
        entry.HealthText.Font    = 2
    end
    Controller.Entries[entity] = entry
    return entry
end

local function destroyCham(entry)
    if entry.Cham then
        pcall(function() entry.Cham:Destroy() end)
        entry.Cham = nil
    end
end

local function hideEntry(entry, hideChamToo)
    hideLines(entry.Box)
    hideLines(entry.BoxOutline)
    hideLines(entry.Arrow)
    hideLines(entry.ArrowOutline)
    hideLines(entry.Skeleton)
    hideLines(entry.SkeletonOutline)
    hideDrawing(entry.Name)
    hideDrawing(entry.Distance)
    hideDrawing(entry.HealthText)
    hideDrawing(entry.HealthBackground)
    hideDrawing(entry.Health)
    hideDrawing(entry.Tracer)
    hideDrawing(entry.TracerOutline)
    if hideChamToo and entry.Cham then entry.Cham.Enabled = false end
end

local function destroyEntry(entity)
    local entry = Controller.Entries[entity]
    if not entry then return end
    for _, array in ipairs({
        entry.Box, entry.BoxOutline,
        entry.Arrow, entry.ArrowOutline,
        entry.Skeleton, entry.SkeletonOutline,
    }) do
        for _, drawing in ipairs(array) do safeRemove(drawing) end
    end
    safeRemove(entry.Name)
    safeRemove(entry.Distance)
    safeRemove(entry.HealthText)
    safeRemove(entry.HealthBackground)
    safeRemove(entry.Health)
    safeRemove(entry.Tracer)
    safeRemove(entry.TracerOutline)
    destroyCham(entry)
    Controller.Entries[entity] = nil
end

local function renderBox(entry, bounds, color, opacity)
    if not Settings.Box then
        hideLines(entry.Box)
        hideLines(entry.BoxOutline)
        return
    end
    local x1, y1 = bounds.X, bounds.Y
    local x2, y2 = bounds.Right, bounds.Bottom
    local thickness        = Settings.BoxThickness
    local outlineThickness = thickness + 2
    local segments = {}
    if Settings.BoxStyle == "Full" then
        segments = {
            { Vector2.new(x1, y1), Vector2.new(x2, y1) },
            { Vector2.new(x2, y1), Vector2.new(x2, y2) },
            { Vector2.new(x2, y2), Vector2.new(x1, y2) },
            { Vector2.new(x1, y2), Vector2.new(x1, y1) },
        }
    else
        local corner = math.min(bounds.Width, bounds.Height) * (Settings.CornerLength / 100)
        corner = math.max(2, corner)
        segments = {
            { Vector2.new(x1, y1), Vector2.new(x1 + corner, y1) },
            { Vector2.new(x1, y1), Vector2.new(x1, y1 + corner) },
            { Vector2.new(x2, y1), Vector2.new(x2 - corner, y1) },
            { Vector2.new(x2, y1), Vector2.new(x2, y1 + corner) },
            { Vector2.new(x1, y2), Vector2.new(x1 + corner, y2) },
            { Vector2.new(x1, y2), Vector2.new(x1, y2 - corner) },
            { Vector2.new(x2, y2), Vector2.new(x2 - corner, y2) },
            { Vector2.new(x2, y2), Vector2.new(x2, y2 - corner) },
        }
    end
    for i = 1, 8 do
        local segment = segments[i]
        local main    = entry.Box[i]
        local outline = entry.BoxOutline[i]
        if segment then
            if Settings.BoxOutline then
                setLine(outline, segment[1], segment[2], Color3.new(0, 0, 0), outlineThickness, opacity)
            else
                hideDrawing(outline)
            end
            setLine(main, segment[1], segment[2], color, thickness, opacity)
        else
            hideDrawing(main)
            hideDrawing(outline)
        end
    end
end

local function renderTexts(entry, bounds, name, distance, health, maxHealth, nameColor, distanceColor, opacity)
    if entry.Name then
        entry.Name.Visible = Settings.Name
        if Settings.Name then
            entry.Name.Text         = name
            entry.Name.Size         = Settings.NameSize
            entry.Name.Color        = nameColor
            entry.Name.Transparency = opacity
            entry.Name.Position     = Vector2.new(bounds.X + bounds.Width * 0.5, bounds.Y - Settings.NameSize - 4)
        end
    end
    if entry.Distance then
        entry.Distance.Visible = Settings.Distance
        if Settings.Distance then
            entry.Distance.Text         = string.format("%d studs", math.floor(distance + 0.5))
            entry.Distance.Size         = Settings.DistanceSize
            entry.Distance.Color        = distanceColor
            entry.Distance.Transparency = opacity
            entry.Distance.Position     = Vector2.new(bounds.X + bounds.Width * 0.5, bounds.Bottom + 4)
        end
    end
    if entry.HealthText then
        entry.HealthText.Visible = Settings.HealthText
        if Settings.HealthText then
            entry.HealthText.Text         = string.format("%d/%d", math.floor(health + 0.5), math.floor(maxHealth + 0.5))
            entry.HealthText.Size         = 11
            entry.HealthText.Color        = Color3.new(1, 1, 1)
            entry.HealthText.Transparency = opacity
            entry.HealthText.Position     = Vector2.new(bounds.X - 38, bounds.Y - 1)
        end
    end
end

local function renderHealth(entry, bounds, health, maxHealth, espColor, opacity)
    if not Settings.HealthBar then
        hideDrawing(entry.HealthBackground)
        hideDrawing(entry.Health)
        return
    end
    local ratio    = math.clamp(health / math.max(maxHealth, 1), 0, 1)
    local x        = bounds.X - 6
    local top      = Vector2.new(x, bounds.Y)
    local bottom   = Vector2.new(x, bounds.Bottom)
    local healthTop = Vector2.new(x, bounds.Bottom - bounds.Height * ratio)
    setLine(entry.HealthBackground, top, bottom, Color3.new(0, 0, 0), Settings.HealthThickness + 2, opacity)
    setLine(entry.Health, bottom, healthTop, getHealthColor(ratio, espColor), Settings.HealthThickness, opacity)
end

local function getTracerOrigin(camera)
    local viewport = camera.ViewportSize
    if Settings.TracerOrigin == "Center" then
        return Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
    end
    if Settings.TracerOrigin == "Mouse" then
        local mouse = LocalPlayer:GetMouse()
        return Vector2.new(mouse.X, mouse.Y)
    end
    return Vector2.new(viewport.X * 0.5, viewport.Y - 2)
end

local function renderTracer(entry, bounds, rootPoint, color, opacity)
    if not Settings.Tracers then
        hideDrawing(entry.Tracer)
        hideDrawing(entry.TracerOutline)
        return
    end
    local camera = Workspace.CurrentCamera
    if not camera then
        hideDrawing(entry.Tracer)
        hideDrawing(entry.TracerOutline)
        return
    end
    local origin = getTracerOrigin(camera)
    local target
    if Settings.TracerTarget == "Center" then
        target = bounds.Center
    elseif Settings.TracerTarget == "Root" then
        target = Vector2.new(rootPoint.X, rootPoint.Y)
    else
        target = Vector2.new(bounds.X + bounds.Width * 0.5, bounds.Bottom)
    end
    if Settings.TracerOutline then
        setLine(entry.TracerOutline, origin, target, Color3.new(0, 0, 0), Settings.TracerThickness + 2, opacity)
    else
        hideDrawing(entry.TracerOutline)
    end
    setLine(entry.Tracer, origin, target, color, Settings.TracerThickness, opacity)
end

local function renderArrow(entry, root, color, opacity)
    if not Settings.Arrows then
        hideLines(entry.Arrow)
        hideLines(entry.ArrowOutline)
        return
    end
    local camera = Workspace.CurrentCamera
    if not camera then
        hideLines(entry.Arrow)
        hideLines(entry.ArrowOutline)
        return
    end
    local viewport  = camera.ViewportSize
    local center    = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
    local projected, onScreen = camera:WorldToViewportPoint(root.Position)
    local delta = Vector2.new(projected.X, projected.Y) - center
    if projected.Z < 0 then delta = -delta end
    if delta.Magnitude < 0.001 then
        hideLines(entry.Arrow)
        hideLines(entry.ArrowOutline)
        return
    end
    local maxRadius  = math.max(40, math.min(viewport.X, viewport.Y) * 0.5 - 30)
    local radius     = math.clamp(Settings.ArrowRadius, 30, maxRadius)
    local outsideFOV = delta.Magnitude > radius
    local outsideScreen = not onScreen
    if Settings.ArrowOnlyOutsideFOV and not outsideFOV and not outsideScreen then
        hideLines(entry.Arrow)
        hideLines(entry.ArrowOutline)
        return
    end
    local direction    = delta.Unit
    local perpendicular = Vector2.new(-direction.Y, direction.X)
    local arrowCenter  = center + direction * radius
    local halfSize     = Settings.ArrowSize * 0.5
    local tip   = arrowCenter + direction * halfSize
    local base  = arrowCenter - direction * halfSize
    local left  = base + perpendicular * halfSize * 0.75
    local right = base - perpendicular * halfSize * 0.75
    local segments = { { tip, left }, { left, right }, { right, tip } }
    for i = 1, 3 do
        local segment = segments[i]
        if Settings.ArrowOutline then
            setLine(entry.ArrowOutline[i], segment[1], segment[2], Color3.new(0, 0, 0), Settings.ArrowThickness + 2, opacity)
        else
            hideDrawing(entry.ArrowOutline[i])
        end
        setLine(entry.Arrow[i], segment[1], segment[2], color, Settings.ArrowThickness, opacity)
    end
end

local function renderSkeleton(entry, visual, color, opacity)
    if not Settings.Skeleton then
        hideLines(entry.Skeleton)
        hideLines(entry.SkeletonOutline)
        return
    end
    local camera = Workspace.CurrentCamera
    if not camera then
        hideLines(entry.Skeleton)
        hideLines(entry.SkeletonOutline)
        return
    end
    local isR15 = visual:FindFirstChild("UpperTorso") ~= nil
    local map   = isR15 and R15_SKELETON or R6_SKELETON
    for i = 1, #entry.Skeleton do
        local line    = entry.Skeleton[i]
        local outline = entry.SkeletonOutline[i]
        local pair    = map[i]
        if not pair then
            hideDrawing(line)
            hideDrawing(outline)
            continue
        end
        local a = visual:FindFirstChild(pair[1])
        local b = visual:FindFirstChild(pair[2])
        if not (a and b and a:IsA("BasePart") and b:IsA("BasePart")) then
            hideDrawing(line)
            hideDrawing(outline)
            continue
        end
        local pa = camera:WorldToViewportPoint(a.Position)
        local pb = camera:WorldToViewportPoint(b.Position)
        if pa.Z <= 0.1 or pb.Z <= 0.1 then
            hideDrawing(line)
            hideDrawing(outline)
            continue
        end
        local va = Vector2.new(pa.X, pa.Y)
        local vb = Vector2.new(pb.X, pb.Y)
        if Settings.SkeletonOutline then
            setLine(outline, va, vb, Color3.new(0, 0, 0), Settings.SkeletonThickness + 2, opacity)
        else
            hideDrawing(outline)
        end
        setLine(line, va, vb, color, Settings.SkeletonThickness, opacity)
    end
end

local function updateCham(entry, visual, espColor)
    if not Settings.Chams or not visual then
        if entry.Cham then entry.Cham.Enabled = false end
        return
    end
    if not entry.Cham or not entry.Cham.Parent then
        local highlight = Instance.new("Highlight")
        highlight.Name    = "WacxSniperArena_Cham"
        highlight.Enabled = true
        highlight.Adornee = visual
        highlight.Parent  = visual
        entry.Cham = highlight
    end
    local cham = entry.Cham
    cham.Enabled   = true
    cham.Adornee   = visual
    cham.DepthMode = Settings.ChamsThroughWalls
        and Enum.HighlightDepthMode.AlwaysOnTop
        or  Enum.HighlightDepthMode.Occluded
    cham.FillColor    = Settings.ChamsUseESPColor
        and normalizeColor(espColor, Color3.fromRGB(255, 70, 85))
        or  normalizeColor(Settings.ChamsFillColor, Color3.fromRGB(255, 70, 85))
    cham.OutlineColor     = normalizeColor(Settings.ChamsOutlineColor, Color3.new(1, 1, 1))
    cham.FillTransparency    = 1 - math.clamp(Settings.ChamsFillOpacity    / 100, 0, 1)
    cham.OutlineTransparency = 1 - math.clamp(Settings.ChamsOutlineOpacity / 100, 0, 1)
end

local function updateEntry(entry)
    local entity = entry.Entity
    if not Settings.Enabled or not entity or not entity.Parent then
        hideEntry(entry, true)
        return
    end
    local visual = entry.Visual
    if visual then
        local stillValid = visual.Parent and (visual == entity or visual:IsDescendantOf(entity))
        if not stillValid then
            visual       = nil
            entry.Visual = nil
        end
    end
    if not visual then
        visual = getVisualModel(entity)
        if visual then
            entry.Visual   = visual
            entry.Identity = getEntityIdentity(entity, visual)
        end
    end
    if not visual then
        hideEntry(entry, true)
        return
    end
    local userId = getUserId(visual)
    if Settings.HideSelf and userId and userId == LocalPlayer.UserId then
        hideEntry(entry, true)
        return
    end
    local root = getRoot(entity, visual)
    if not root then
        hideEntry(entry, true)
        return
    end
    local health, maxHealth = getHealth(entity, visual)
    if Settings.HideDead and isDead(entity, health) then
        hideEntry(entry, true)
        return
    end
    local distance = getDistance(root)
    if Settings.MaxDistance > 0 and distance > Settings.MaxDistance then
        hideEntry(entry, true)
        return
    end
    local camera = Workspace.CurrentCamera
    if not camera then
        hideEntry(entry, true)
        return
    end
    local rootPoint    = camera:WorldToViewportPoint(root.Position)
    local boxColor     = getFeatureColor("Box",      entry.Kind)
    local nameColor    = getFeatureColor("Name",     entry.Kind)
    local distanceColor = getFeatureColor("Distance", entry.Kind)
    local tracerColor  = getFeatureColor("Tracer",   entry.Kind)
    local arrowColor   = getFeatureColor("Arrow",    entry.Kind)
    local targetColor  = getTargetColor(entry.Kind)
    local opacity      = math.clamp(Settings.DrawingOpacity / 100, 0.05, 1)
    updateCham(entry, visual, targetColor)
    renderArrow(entry, root, arrowColor, opacity)
    if rootPoint.Z <= 0.1 then
        hideLines(entry.Box)
        hideLines(entry.BoxOutline)
        hideLines(entry.Skeleton)
        hideLines(entry.SkeletonOutline)
        hideDrawing(entry.Name)
        hideDrawing(entry.Distance)
        hideDrawing(entry.HealthText)
        hideDrawing(entry.HealthBackground)
        hideDrawing(entry.Health)
        hideDrawing(entry.Tracer)
        hideDrawing(entry.TracerOutline)
        return
    end
    local bounds = getScreenBounds(visual)
    if not bounds then
        hideLines(entry.Box)
        hideLines(entry.BoxOutline)
        hideLines(entry.Skeleton)
        hideLines(entry.SkeletonOutline)
        hideDrawing(entry.Name)
        hideDrawing(entry.Distance)
        hideDrawing(entry.HealthText)
        hideDrawing(entry.HealthBackground)
        hideDrawing(entry.Health)
        hideDrawing(entry.Tracer)
        hideDrawing(entry.TracerOutline)
        return
    end
    local viewport    = camera.ViewportSize
    local nearViewport = bounds.Right >= -100
        and bounds.X <= viewport.X + 100
        and bounds.Bottom >= -100
        and bounds.Y <= viewport.Y + 100
    if not nearViewport then
        hideLines(entry.Box)
        hideLines(entry.BoxOutline)
        hideLines(entry.Skeleton)
        hideLines(entry.SkeletonOutline)
        hideDrawing(entry.Name)
        hideDrawing(entry.Distance)
        hideDrawing(entry.HealthText)
        hideDrawing(entry.HealthBackground)
        hideDrawing(entry.Health)
        hideDrawing(entry.Tracer)
        hideDrawing(entry.TracerOutline)
        return
    end
    renderBox(entry, bounds, boxColor, opacity)
    renderTexts(entry, bounds, getDisplayName(entity, visual), distance, health, maxHealth, nameColor, distanceColor, opacity)
    renderHealth(entry, bounds, health, maxHealth, boxColor, opacity)
    renderTracer(entry, bounds, rootPoint, tracerColor, opacity)
    renderSkeleton(entry, visual, Color3.new(1, 1, 1), opacity)
end

local function collectWorldEntities()
    local result = {}
    local world  = Workspace:FindFirstChild("World")
    if not world then return result end
    for _, worldFolder in ipairs(world:GetChildren()) do
        local entities = worldFolder:FindFirstChild("Entities")
        if entities then
            for _, entity in ipairs(entities:GetChildren()) do
                if entity:IsA("Model") and entity:GetAttribute("_entity") == "HumanoidEntity" then
                    local visual = getVisualModel(entity)
                    result[#result + 1] = {
                        Entity   = entity,
                        Visual   = visual,
                        Identity = getEntityIdentity(entity, visual),
                    }
                end
            end
        end
    end
    return result
end

local function collectHighlightMembership()
    local membership = {
        Enemy    = { Identity = {}, Name = {}, Entries = {} },
        Friendly = { Identity = {}, Name = {}, Entries = {} },
    }
    for _, kind in ipairs({ "Enemy", "Friendly" }) do
        local holder = getHighlightHolder(kind)
        if holder then
            for _, entity in ipairs(holder:GetChildren()) do
                if entity:IsA("Model") then
                    local visual   = getVisualModel(entity)
                    local identity = getEntityIdentity(entity, visual)
                    if identity then membership[kind].Identity[identity] = true end
                    membership[kind].Name[string.lower(entity.Name)] = true
                    membership[kind].Entries[#membership[kind].Entries + 1] =
                        { Entity = entity, Visual = visual, Identity = identity }
                end
            end
        end
    end
    return membership
end

local function findLocalWorldState(worldEntities)
    for _, record in ipairs(worldEntities) do
        local entity = record.Entity
        local visual = record.Visual
        local userId = getUserId(visual)
        if userId and userId == LocalPlayer.UserId then
            return {
                Entity   = entity,
                Team     = entity:GetAttribute("Team"),
                World    = entity:GetAttribute("World"),
                GameRoom = entity:GetAttribute("GameRoom"),
            }
        end
    end
    return nil
end

local function classifyWorldEntity(entity, visual, membership, localState)
    local identity  = getEntityIdentity(entity, visual)
    local lowerName = string.lower(entity.Name)
    if identity and membership.Enemy.Identity[identity]    then return "Enemy"    end
    if identity and membership.Friendly.Identity[identity] then return "Friendly" end
    if membership.Enemy.Name[lowerName]    then return "Enemy"    end
    if membership.Friendly.Name[lowerName] then return "Friendly" end
    if localState then
        local targetRoom = entity:GetAttribute("GameRoom") or entity:GetAttribute("World")
        local localRoom  = localState.GameRoom or localState.World
        if localRoom ~= nil and targetRoom ~= nil and tostring(localRoom) ~= tostring(targetRoom) then
            return nil
        end
        local localTeam  = localState.Team
        local targetTeam = entity:GetAttribute("Team")
        if localTeam ~= nil and targetTeam ~= nil then
            if tostring(localTeam) == tostring(targetTeam) then return "Friendly" end
            return "Enemy"
        end
    end
    return nil
end

local function registerEntity(entity, kind, found, foundIdentities, now, resolvedVisual, resolvedIdentity)
    if not entity or not entity.Parent or not shouldScanKind(kind) then return end
    local visual   = resolvedVisual   or getVisualModel(entity)
    local identity = resolvedIdentity or getEntityIdentity(entity, visual)
    if identity and foundIdentities[identity] then return end
    found[entity] = true
    if identity then foundIdentities[identity] = entity end
    local entry = Controller.Entries[entity]
    if not entry then entry = createEntry(entity, kind) end
    entry.Kind     = kind
    entry.LastSeen = now
    if visual then
        entry.Visual   = visual
        entry.Identity = identity
    end
end

local function refreshEntities()
    if Controller.Unloaded then return end
    local now             = os.clock()
    local found           = {}
    local foundIdentities = {}
    local membership    = collectHighlightMembership()
    local worldEntities = collectWorldEntities()
    local localState    = findLocalWorldState(worldEntities)
    for _, record in ipairs(worldEntities) do
        local entity = record.Entity
        local visual = record.Visual
        local userId = getUserId(visual)
        if not (Settings.HideSelf and userId and userId == LocalPlayer.UserId) then
            local kind = classifyWorldEntity(entity, visual, membership, localState)
            if kind then
                registerEntity(entity, kind, found, foundIdentities, now, visual, record.Identity)
            end
        end
    end
    for _, kind in ipairs({ "Enemy", "Friendly" }) do
        if shouldScanKind(kind) then
            for _, record in ipairs(membership[kind].Entries) do
                registerEntity(record.Entity, kind, found, foundIdentities, now, record.Visual, record.Identity)
            end
        end
    end
    for entity, entry in pairs(Controller.Entries) do
        if not found[entity] then
            local identity = entry.Identity
                or getEntityIdentity(entity, entry.Visual or getVisualModel(entity))
            local canonicalEntity = identity and foundIdentities[identity] or nil
            if canonicalEntity and canonicalEntity ~= entity then
                destroyEntry(entity)
            elseif not entity.Parent then
                destroyEntry(entity)
            elseif now - (entry.LastSeen or now) > Settings.EntityGracePeriod then
                destroyEntry(entity)
            end
        end
    end
end

local CombatRuntime = {
    Available              = false,
    EntityService          = nil,
    ClientShootableComponent = nil,
    LockedEntity           = nil,
    LastSwitch             = 0,
    LastTarget             = nil,
    LastTargetTime         = 0,
    PreviewTarget          = nil,
    LastPreviewUpdate      = 0,
    PreviewInterval        = 0.016666666666666666,
    PreviewGrace           = 0.2,
    LastValidPreview       = nil,
    LastValidPreviewTime   = 0,
    HitboxCache            = setmetatable({}, { __mode = "k" }),
    HookCount              = 0,
    Stats = {
        LocalShootCalls  = 0,
        TargetsSelected  = 0,
        OriginRedirects  = 0,
        HitRedirects     = 0,
        LastHookError    = nil,
    },
}
Controller.Combat = CombatRuntime

local CombatRandom          = Random.new()
local CombatFOVCircle       = newDrawing("Circle", 7)
local CombatImpactLine      = newDrawing("Line", 9)
local CombatTargetIndicator = newDrawing("Circle", 10)
Controller.CombatDrawings   = { CombatFOVCircle, CombatImpactLine, CombatTargetIndicator }
if CombatFOVCircle then
    CombatFOVCircle.Filled   = false
    CombatFOVCircle.NumSides = 64
    CombatFOVCircle.Thickness = 1
end
if CombatTargetIndicator then
    CombatTargetIndicator.Filled   = false
    CombatTargetIndicator.NumSides = 24
    CombatTargetIndicator.Thickness = 1
end

local function getCombatFOVCenter()
    local camera = Workspace.CurrentCamera
    if not camera then return Vector2.zero end
    if Settings.CombatFOVCenter == "Mouse" then
        local mouse = LocalPlayer:GetMouse()
        return Vector2.new(mouse.X, mouse.Y)
    end
    return Vector2.new(camera.ViewportSize.X * 0.5, camera.ViewportSize.Y * 0.5)
end

local function getEntityItems(teamDictionary)
    if type(teamDictionary) ~= "table" then return nil end
    if type(teamDictionary._items) == "table" then return teamDictionary._items end
    return teamDictionary
end

local function entityIsAlive(entity)
    if not entity then return false end
    local ok, alive = pcall(function() return entity:IsAlive() end)
    return ok and alive == true
end

local function resolveEntityCharacter(entity)
    if not entity then return nil end
    local ok, instance = pcall(function() return entity.Instance end)
    if not ok or not instance then return nil end
    local character
    if instance:IsA("Player") then
        character = instance.Character
    elseif instance:IsA("Model") then
        character = instance
    end
    if not character or not character.Parent then return nil end
    if character:FindFirstChild("HumanoidRootPart") then return character end
    return getVisualModel(character) or character
end

local function getCombatHealth(character, entity)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local maxHealth = humanoid.MaxHealth
        if maxHealth <= 0 then maxHealth = 100 end
        return humanoid.Health, maxHealth
    end
    local health    = nil
    local maxHealth = nil
    pcall(function()
        health    = entity.Health
        maxHealth = entity.MaxHealth
    end)
    health    = tonumber(health)    or (character and tonumber(character:GetAttribute("Health")))    or 100
    maxHealth = tonumber(maxHealth) or (character and tonumber(character:GetAttribute("MaxHealth"))) or 100
    if maxHealth <= 0 then maxHealth = 100 end
    return health, maxHealth
end

local function getTorsoPart(character)
    if not character then return nil end
    return character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
        or character:FindFirstChild("LowerTorso")
        or character:FindFirstChild("HumanoidRootPart")
end

local function getLowerTorsoPart(character)
    if not character then return nil end
    return character:FindFirstChild("LowerTorso")
        or character:FindFirstChild("Torso")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("HumanoidRootPart")
end

local function chooseCombatHitbox(character, fovCenter, cacheKey)
    if not character then return nil end
    local head       = character:FindFirstChild("Head")
    local torso      = getTorsoPart(character)
    local lowerTorso = getLowerTorsoPart(character)
    local root       = character:FindFirstChild("HumanoidRootPart")
    local mode       = Settings.CombatHitbox
    if mode == "Head" then
        return head or torso or root
    elseif mode == "Torso" then
        return torso or head or root
    elseif mode == "Lower Torso" then
        return lowerTorso or torso or head or root
    elseif mode == "Head/Torso Random" or mode == "Head/Torso Weighted" then
        local cached = cacheKey and CombatRuntime.HitboxCache[cacheKey]
        if cached and cached.Mode == mode and cached.Part and cached.Part.Parent then
            return cached.Part
        end
        local useHead
        if mode == "Head/Torso Random" then
            useHead = CombatRandom:NextNumber() < 0.5
        else
            local chance = math.clamp(Settings.CombatHeadChance / 100, 0, 1)
            useHead = CombatRandom:NextNumber() <= chance
        end
        local selected = useHead and (head or torso or root) or (torso or head or root)
        if cacheKey and selected then
            CombatRuntime.HitboxCache[cacheKey] = { Mode = mode, Part = selected }
        end
        return selected
    elseif mode == "Closest Part" then
        local camera   = Workspace.CurrentCamera
        local bestPart = nil
        local bestDistance = math.huge
        if camera then
            for _, part in ipairs({ head, torso, lowerTorso }) do
                if part and part:IsA("BasePart") then
                    local point, onScreen = camera:WorldToViewportPoint(part.Position)
                    if point.Z > 0 and onScreen then
                        local dist = (Vector2.new(point.X, point.Y) - fovCenter).Magnitude
                        if dist < bestDistance then
                            bestDistance = dist
                            bestPart     = part
                        end
                    end
                end
            end
        end
        return bestPart or head or torso or root
    end
    return head or torso or root
end

local function combatIsVisible(character, targetPart, targetPosition)
    local camera = Workspace.CurrentCamera
    if not camera or not character or not targetPart then return false end
    local params = RaycastParams.new()
    params.FilterType    = Enum.RaycastFilterType.Exclude
    params.IgnoreWater   = true
    local exclusions     = {}
    local localCharacter = LocalPlayer.Character
    if localCharacter then exclusions[#exclusions + 1] = localCharacter end
    params.FilterDescendantsInstances = exclusions
    local origin = camera.CFrame.Position
    local result = Workspace:Raycast(origin, targetPosition - origin, params)
    if not result then return true end
    return result.Instance == targetPart or result.Instance:IsDescendantOf(character)
end

local function getPredictedPosition(part)
    local position = part.Position
    if not Settings.CombatPrediction then return position end
    local velocity = Vector3.zero
    pcall(function() velocity = part.AssemblyLinearVelocity end)
    local seconds = math.clamp(Settings.CombatPredictionMs / 1000, 0, 0.5)
    return position + velocity * seconds
end

local function findLocalTeamKey(localEntity, entitiesByTeam)
    if not localEntity or type(entitiesByTeam) ~= "table" then return nil end
    for teamKey, teamDictionary in pairs(entitiesByTeam) do
        local items = getEntityItems(teamDictionary)
        if items then
            for _, entity in pairs(items) do
                if entity == localEntity then return teamKey end
                local ok, isLocal = pcall(function()
                    return CombatRuntime.EntityService.IsLocalEntity(entity)
                end)
                if ok and isLocal then return teamKey end
            end
        end
    end
    return nil
end

local function buildTrackedCombatCandidates(fovScale)
    local camera = Workspace.CurrentCamera
    if not camera then return {} end
    local fovCenter = getCombatFOVCenter()
    local fovRadius = math.max(1, Settings.CombatFOVRadius * (fovScale or 1))
    local candidates = {}
    for entity, entry in pairs(Controller.Entries) do
        local allowed = true
        if Settings.CombatTeamCheck then allowed = entry.Kind == "Enemy" end
        if allowed and entity and entity.Parent then
            local visual = entry.Visual or getVisualModel(entity)
            if visual and visual.Parent then
                local userId = getUserId(visual)
                if not userId or userId ~= LocalPlayer.UserId then
                    local health, maxHealth = getHealth(entity, visual)
                    if health > 0 and not isDead(entity, health) then
                        local part = chooseCombatHitbox(visual, fovCenter, entity)
                        if part and part:IsA("BasePart") and part.Parent then
                            local currentPosition       = part.Position
                            local screenPoint, onScreen = camera:WorldToViewportPoint(currentPosition)
                            local validScreen = screenPoint.Z > 0
                                and (not Settings.CombatOnScreenOnly or onScreen)
                            if validScreen then
                                local screenDistance = (Vector2.new(screenPoint.X, screenPoint.Y) - fovCenter).Magnitude
                                if screenDistance <= fovRadius then
                                    local worldDistance = (currentPosition - camera.CFrame.Position).Magnitude
                                    if Settings.CombatMaxDistance <= 0 or worldDistance <= Settings.CombatMaxDistance then
                                        local visible = true
                                        if Settings.CombatWallCheck then
                                            visible = combatIsVisible(visual, part, currentPosition)
                                        end
                                        if visible then
                                            candidates[#candidates + 1] = {
                                                Entity          = entity,
                                                Character       = visual,
                                                Part            = part,
                                                Position        = getPredictedPosition(part),
                                                CurrentPosition = currentPosition,
                                                ScreenPoint     = screenPoint,
                                                ScreenDistance  = screenDistance,
                                                WorldDistance   = worldDistance,
                                                Health          = health,
                                                MaxHealth       = maxHealth,
                                                HealthRatio     = math.clamp(health / math.max(maxHealth, 1), 0, 1),
                                                Source          = "Tracker",
                                            }
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return candidates
end

local function buildCombatCandidates(fovScale)
    local entityService = CombatRuntime.EntityService
    local camera        = Workspace.CurrentCamera
    if not camera then return {} end
    if not entityService then return buildTrackedCombatCandidates(fovScale) end
    local ok, localEntity = pcall(function() return entityService.GetLocalEntity() end)
    if not ok or not localEntity or not localEntity.World or type(localEntity.World.EntitiesByTeam) ~= "table" then
        return buildTrackedCombatCandidates(fovScale)
    end
    local entitiesByTeam = localEntity.World.EntitiesByTeam
    local localTeamKey   = findLocalTeamKey(localEntity, entitiesByTeam)
    local fovCenter      = getCombatFOVCenter()
    local fovRadius      = math.max(1, Settings.CombatFOVRadius * (fovScale or 1))
    local candidates     = {}
    for teamKey, teamDictionary in pairs(entitiesByTeam) do
        if not Settings.CombatTeamCheck or teamKey ~= localTeamKey then
            local items = getEntityItems(teamDictionary)
            if items then
                for _, entity in pairs(items) do
                    local isLocal = false
                    pcall(function() isLocal = entityService.IsLocalEntity(entity) end)
                    if not isLocal and entityIsAlive(entity) then
                        local character = resolveEntityCharacter(entity)
                        if character then
                            local health, maxHealth = getCombatHealth(character, entity)
                            if health > 0 then
                                local part = chooseCombatHitbox(character, fovCenter, entity)
                                if part and part:IsA("BasePart") then
                                    local currentPosition       = part.Position
                                    local screenPoint, onScreen = camera:WorldToViewportPoint(currentPosition)
                                    local validScreen = screenPoint.Z > 0
                                        and (not Settings.CombatOnScreenOnly or onScreen)
                                    if validScreen then
                                        local screenDistance = (Vector2.new(screenPoint.X, screenPoint.Y) - fovCenter).Magnitude
                                        if screenDistance <= fovRadius then
                                            local worldDistance = (currentPosition - camera.CFrame.Position).Magnitude
                                            if Settings.CombatMaxDistance <= 0 or worldDistance <= Settings.CombatMaxDistance then
                                                local visible = true
                                                if Settings.CombatWallCheck then
                                                    visible = combatIsVisible(character, part, currentPosition)
                                                end
                                                if visible then
                                                    candidates[#candidates + 1] = {
                                                        Entity          = entity,
                                                        Character       = character,
                                                        Part            = part,
                                                        Position        = getPredictedPosition(part),
                                                        CurrentPosition = currentPosition,
                                                        ScreenPoint     = screenPoint,
                                                        ScreenDistance  = screenDistance,
                                                        WorldDistance   = worldDistance,
                                                        Health          = health,
                                                        MaxHealth       = maxHealth,
                                                        HealthRatio     = math.clamp(health / math.max(maxHealth, 1), 0, 1),
                                                    }
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    if #candidates == 0 then return buildTrackedCombatCandidates(fovScale) end
    return candidates
end

local function getHybridScore(candidate)
    local fov         = math.max(Settings.CombatFOVRadius, 1)
    local maxDistance = math.max(Settings.CombatMaxDistance, 1)
    local crosshair   = math.clamp(candidate.ScreenDistance / fov, 0, 2)
    local distance    = math.clamp(candidate.WorldDistance / maxDistance, 0, 2)
    local health      = candidate.HealthRatio
    return crosshair * Settings.CombatHybridCrosshairWeight
        + distance   * Settings.CombatHybridDistanceWeight
        + health     * Settings.CombatHybridHealthWeight
end

local function isCandidateBetter(candidate, best)
    if not best then return true end
    local priority = Settings.CombatPriority
    if priority == "Crosshair"       then return candidate.ScreenDistance < best.ScreenDistance end
    if priority == "Distance"        then return candidate.WorldDistance   < best.WorldDistance   end
    if priority == "Lowest Health"   then return candidate.Health          < best.Health          end
    if priority == "Highest Health"  then return candidate.Health          > best.Health          end
    if priority == "Lowest Health %" then return candidate.HealthRatio     < best.HealthRatio     end
    if priority == "Hybrid"          then return getHybridScore(candidate) < getHybridScore(best) end
    if priority == "Random"          then return CombatRandom:NextInteger(0, 1) == 1              end
    return candidate.ScreenDistance < best.ScreenDistance
end

local function findCandidateForLockedEntity(candidates)
    local locked = CombatRuntime.LockedEntity
    if not locked then return nil end
    for _, candidate in ipairs(candidates) do
        if candidate.Entity == locked then return candidate end
    end
    return nil
end

local function selectCombatTarget()
    if not Settings.CombatEnabled then
        CombatRuntime.LockedEntity  = nil
        CombatRuntime.PreviewTarget = nil
        return nil
    end
    local now = os.clock()
    if Settings.CombatTargetLock and CombatRuntime.LockedEntity then
        local lockScale       = math.max(Settings.CombatLockFOVScale / 100, 1)
        local lockedCandidate = findCandidateForLockedEntity(buildCombatCandidates(lockScale))
        if lockedCandidate then
            CombatRuntime.LastTarget     = lockedCandidate
            CombatRuntime.LastTargetTime = now
            return lockedCandidate
        end
        if now - CombatRuntime.LastSwitch < Settings.CombatSwitchDelay then
            local previous = CombatRuntime.LastValidPreview
            if previous and previous.Part and previous.Part.Parent
                and now - CombatRuntime.LastValidPreviewTime <= CombatRuntime.PreviewGrace then
                previous.Position = getPredictedPosition(previous.Part)
                return previous
            end
            return nil
        end
        CombatRuntime.LockedEntity = nil
    end
    local candidates = buildCombatCandidates(1)
    if #candidates == 0 then return nil end
    local best = nil
    if Settings.CombatPriority == "Random" then
        best = candidates[CombatRandom:NextInteger(1, #candidates)]
    else
        for _, candidate in ipairs(candidates) do
            if isCandidateBetter(candidate, best) then best = candidate end
        end
    end
    if best then
        if best.Entity ~= CombatRuntime.LockedEntity then CombatRuntime.LastSwitch = now end
        if Settings.CombatTargetLock then
            CombatRuntime.LockedEntity = best.Entity
        else
            CombatRuntime.LockedEntity = nil
        end
        CombatRuntime.LastTarget     = best
        CombatRuntime.LastTargetTime = now
        CombatRuntime.Stats.TargetsSelected += 1
    end
    return best
end
Controller.GetCombatTarget = selectCombatTarget

local function getFunctionUpvalues(fn)
    local functions = {}
    local seen      = {}
    if type(fn) ~= "function" then return functions end
    if debug and type(debug.getupvalues) == "function" then
        local ok, values = pcall(debug.getupvalues, fn)
        if ok and type(values) == "table" then
            for _, value in pairs(values) do
                if type(value) == "function" and not seen[value] then
                    seen[value] = true
                    functions[#functions + 1] = value
                end
            end
        end
    end
    if #functions == 0 and debug and type(debug.getupvalue) == "function" then
        for index = 1, 40 do
            local ok, first, second = pcall(debug.getupvalue, fn, index)
            if not ok then break end
            local value = second
            if value == nil and type(first) ~= "string" then value = first end
            if type(value) == "function" and not seen[value] then
                seen[value] = true
                functions[#functions + 1] = value
            end
        end
    end
    return functions
end

local COMBAT_HOOK_STATE_KEY = "WacxSniperArenaCombatHookState_V1"
local CombatHookState       = ENV[COMBAT_HOOK_STATE_KEY]
if not CombatHookState then
    CombatHookState = {
        Controller         = nil,
        SilentTarget       = nil,
        InLocalShoot       = false,
        HookedCandidates   = setmetatable({}, { __mode = "k" }),
        HookedLocalShoots  = setmetatable({}, { __mode = "k" }),
        CandidateCount     = 0,
        OriginObserved     = false,
        HitObserved        = false,
    }
    ENV[COMBAT_HOOK_STATE_KEY] = CombatHookState
end
CombatHookState.Controller = Controller

local function installPassiveCandidateHook(candidateFunction)
    if type(hookfunction) ~= "function"
        or type(candidateFunction) ~= "function"
        or CombatHookState.HookedCandidates[candidateFunction] then
        return false
    end
    local original
    local ok = pcall(function()
        original = hookfunction(candidateFunction, function(...)
            local packed           = table.pack(original(...))
            local activeController = CombatHookState.Controller
            local target           = CombatHookState.SilentTarget
            if CombatHookState.InLocalShoot
                and activeController
                and not activeController.Unloaded
                and activeController.Settings.CombatEnabled
                and target
                and target.Part
                and target.Part.Parent then
                target.Position = getPredictedPosition(target.Part)
                if typeof(packed[1]) == "CFrame" and type(packed[3]) == "table" then
                    local origin = packed[1].Position
                    local delta  = target.Position - origin
                    if delta.Magnitude > 0.001 then
                        packed[1] = CFrame.lookAt(origin, target.Position)
                        activeController.Combat.Stats.OriginRedirects += 1
                        if not CombatHookState.OriginObserved then
                            CombatHookState.OriginObserved = true
                            warn("[Combat] origin redirect hook active")
                        end
                    end
                elseif typeof(packed[1]) == "Vector3"
                    and (packed[2] == nil or typeof(packed[2]) == "Instance") then
                    packed[1] = target.Position
                    packed[2] = target.Part
                    activeController.Combat.Stats.HitRedirects += 1
                    if not CombatHookState.HitObserved then
                        CombatHookState.HitObserved = true
                        warn("[Combat] hit-position redirect hook active")
                    end
                end
            end
            return table.unpack(packed, 1, packed.n)
        end)
    end)
    if ok and original then
        CombatHookState.HookedCandidates[candidateFunction] = true
        CombatHookState.CandidateCount += 1
        return true
    end
    return false
end

local function installCombatHooks()
    local entityService
    local shootable
    local entityOk = pcall(function()
        entityService = require(ReplicatedStorage:WaitForChild("Remote"):WaitForChild("EntityService"))
    end)
    local shootableOk = pcall(function()
        shootable = require(
            ReplicatedStorage:WaitForChild("Client")
                :WaitForChild("CombatController")
                :WaitForChild("ClientComponent")
                :WaitForChild("ClientShootableComponent")
        )
    end)
    if not entityOk or not shootableOk
        or type(entityService) ~= "table"
        or type(shootable)     ~= "table"
        or type(shootable.LocalShoot) ~= "function"
        or type(hookfunction)  ~= "function" then
        CombatRuntime.Available = false
        return false
    end
    CombatRuntime.EntityService            = entityService
    CombatRuntime.ClientShootableComponent = shootable
    local localShoot = shootable.LocalShoot
    for _, candidateFunction in ipairs(getFunctionUpvalues(localShoot)) do
        installPassiveCandidateHook(candidateFunction)
    end
    if not CombatHookState.HookedLocalShoots[localShoot] then
        local originalLocalShoot
        local ok = pcall(function()
            originalLocalShoot = hookfunction(localShoot, function(self, ...)
                local activeController = CombatHookState.Controller
                local target           = nil
                if activeController and not activeController.Unloaded
                    and activeController.Settings.CombatEnabled then
                    activeController.Combat.Stats.LocalShootCalls += 1
                    target = activeController.Combat.PreviewTarget
                    if not (target and target.Part and target.Part.Parent)
                        and type(activeController.GetCombatTarget) == "function" then
                        local targetOk, selected = pcall(activeController.GetCombatTarget)
                        if targetOk then
                            target = selected
                        else
                            activeController.Combat.Stats.LastHookError = tostring(selected)
                        end
                    end
                    if target and target.Part and target.Part.Parent then
                        target.Position = getPredictedPosition(target.Part)
                    end
                end
                CombatHookState.SilentTarget  = target
                CombatHookState.InLocalShoot  = target ~= nil
                local results = table.pack(pcall(originalLocalShoot, self, ...))
                CombatHookState.InLocalShoot  = false
                CombatHookState.SilentTarget  = nil
                if activeController and target then
                    if target.Entity then
                        activeController.Combat.HitboxCache[target.Entity] = nil
                    end
                    activeController.Combat.PreviewTarget = nil
                end
                if not results[1] then
                    if activeController then
                        activeController.Combat.Stats.LastHookError = tostring(results[2])
                    end
                    error(results[2], 0)
                end
                return table.unpack(results, 2, results.n)
            end)
        end)
        if ok and originalLocalShoot then
            CombatHookState.HookedLocalShoots[localShoot] = true
        else
            CombatRuntime.Available = false
            return false
        end
    end
    CombatRuntime.HookCount = CombatHookState.CandidateCount
    CombatRuntime.Available = true
    return true
end

local CombatHooksInstalled = false

local function updateCombatDrawings()
    local camera = Workspace.CurrentCamera
    if not camera then
        if CombatFOVCircle then CombatFOVCircle.Visible = false end
        if CombatImpactLine then CombatImpactLine.Visible = false end
        if CombatTargetIndicator then CombatTargetIndicator.Visible = false end
        return
    end
    local now = os.clock()
    if Settings.CombatEnabled then
        if now - CombatRuntime.LastPreviewUpdate >= CombatRuntime.PreviewInterval then
            CombatRuntime.LastPreviewUpdate = now
            local ok, selected = pcall(selectCombatTarget)
            if ok and selected and selected.Part and selected.Part.Parent then
                CombatRuntime.PreviewTarget        = selected
                CombatRuntime.LastValidPreview     = selected
                CombatRuntime.LastValidPreviewTime = now
            elseif ok then
                local previous = CombatRuntime.LastValidPreview
                if previous and previous.Part and previous.Part.Parent
                    and now - CombatRuntime.LastValidPreviewTime <= CombatRuntime.PreviewGrace then
                    previous.Position             = getPredictedPosition(previous.Part)
                    CombatRuntime.PreviewTarget   = previous
                else
                    CombatRuntime.PreviewTarget = nil
                end
            else
                CombatRuntime.PreviewTarget          = nil
                CombatRuntime.Stats.LastHookError    = tostring(selected)
            end
        end
    else
        CombatRuntime.PreviewTarget    = nil
        CombatRuntime.LastValidPreview = nil
        CombatRuntime.LockedEntity     = nil
    end
    local target = CombatRuntime.PreviewTarget
    if target and target.Part and target.Part.Parent then
        target.Position              = getPredictedPosition(target.Part)
        CombatRuntime.LastTarget     = target
        CombatRuntime.LastTargetTime = now
    end
    if CombatFOVCircle then
        CombatFOVCircle.Position    = getCombatFOVCenter()
        CombatFOVCircle.Radius      = Settings.CombatFOVRadius
        CombatFOVCircle.Thickness   = Settings.CombatFOVThickness
        CombatFOVCircle.NumSides    = Settings.CombatFOVSides
        CombatFOVCircle.Filled      = Settings.CombatFOVFilled
        CombatFOVCircle.Color       = normalizeColor(Settings.CombatFOVColor, Color3.new(1, 1, 1))
        CombatFOVCircle.Transparency = math.clamp(Settings.CombatFOVOpacity / 100, 0.05, 1)
        CombatFOVCircle.Visible     = Settings.CombatEnabled and Settings.CombatFOVVisible
    end
    if CombatImpactLine then
        local visible = false
        if Settings.CombatEnabled and Settings.CombatImpactLine
            and target and target.Part and target.Part.Parent then
            target.Position = getPredictedPosition(target.Part)
            local point     = camera:WorldToViewportPoint(target.Position)
            if point.Z > 0 then
                local viewport = camera.ViewportSize
                local endpoint = Vector2.new(
                    math.clamp(point.X, 0, viewport.X),
                    math.clamp(point.Y, 0, viewport.Y)
                )
                setLine(
                    CombatImpactLine,
                    getCombatFOVCenter(),
                    endpoint,
                    normalizeColor(Settings.CombatImpactLineColor, Color3.fromRGB(255, 80, 90)),
                    math.max(1, tonumber(Settings.CombatImpactLineThickness) or 1),
                    math.clamp((tonumber(Settings.CombatImpactLineOpacity) or 100) / 100, 0.05, 1)
                )
                pcall(function() CombatImpactLine.ZIndex = 9 end)
                visible = true
            end
        end
        CombatImpactLine.Visible = visible
    end
    if CombatTargetIndicator then
        local visible = false
        if Settings.CombatEnabled and Settings.CombatTargetIndicator
            and target and target.Part and target.Part.Parent then
            local point, onScreen = camera:WorldToViewportPoint(target.Position)
            if point.Z > 0 and onScreen then
                CombatTargetIndicator.Position    = Vector2.new(point.X, point.Y)
                CombatTargetIndicator.Radius      = Settings.CombatIndicatorSize
                CombatTargetIndicator.Color       = normalizeColor(Settings.CombatIndicatorColor, Color3.fromRGB(255, 80, 90))
                CombatTargetIndicator.Transparency = 1
                CombatTargetIndicator.Thickness   = 1
                visible = true
            end
        end
        CombatTargetIndicator.Visible = visible
    end
end

local CombatTab = CompatTab(Window:AddTab("Combat", "crosshair"))
local ESPTab = CompatTab(Window:AddTab("ESP", "scan"))
local SettingsTab = CompatTab(Window:AddTab("Settings", "settings"))

ESPTab:CreateSection("General", "left")
ESPTab:CreateLabel({
    Text = "Master switch and basic ESP filters.",
})

ESPTab:CreateToggle({
    Name         = "Master ESP",
    Desc         = "Enable or disable all ESP rendering",
    CurrentValue = Settings.Enabled,
    Flag         = "ESP_Master",
    Callback     = function(v)
        Settings.Enabled = v
        if not v then
            for _, entry in pairs(Controller.Entries) do
                hideEntry(entry, true)
            end
        end
    end,
})

ESPTab:CreateDropdown({
    Name          = "Targets",
    Desc          = "Which team to show ESP on",
    Options       = { "Enemies", "Friendlies", "Both" },
    CurrentOption = Settings.Targets,
    Flag          = "ESP_Targets",
    Callback      = function(v)
        Settings.Targets = v
        refreshEntities()
    end,
})

ESPTab:CreateSlider({
    Name         = "Max Distance",
    Desc         = "Furthest range to render ESP (studs)",
    Range        = { 100, 10000 },
    Increment    = 50,
    Suffix       = " studs",
    CurrentValue = Settings.MaxDistance,
    Flag         = "ESP_MaxDistance",
    Callback     = function(v) Settings.MaxDistance = v end,
})

ESPTab:CreateSlider({
    Name         = "Global Opacity",
    Desc         = "Overall transparency of all drawings",
    Range        = { 10, 100 },
    Increment    = 1,
    Suffix       = "%",
    CurrentValue = Settings.DrawingOpacity,
    Flag         = "ESP_Opacity",
    Callback     = function(v) Settings.DrawingOpacity = v end,
})

ESPTab:CreateToggle({
    Name         = "Hide Dead",
    Desc         = "Skip entities with zero health",
    CurrentValue = Settings.HideDead,
    Flag         = "ESP_HideDead",
    Callback     = function(v) Settings.HideDead = v end,
})

ESPTab:CreateDivider()
ESPTab:CreateSection("2D Box", "right")
ESPTab:CreateLabel({
    Text = "Bounding box drawn around players on screen.",
})

ESPTab:CreateToggle({
    Name         = "2D Box",
    Desc         = "Draw a rectangle around each target",
    CurrentValue = Settings.Box,
    Flag         = "ESP_Box",
    Callback     = function(v) Settings.Box = v end,
})

ESPTab:CreateDropdown({
    Name          = "Box Style",
    Desc          = "Full rectangle or corner brackets",
    Options       = { "Corner", "Full" },
    CurrentOption = Settings.BoxStyle,
    Flag          = "ESP_BoxStyle",
    Callback      = function(v) Settings.BoxStyle = v end,
})

ESPTab:CreateToggle({
    Name         = "Box Outline",
    Desc         = "Dark border behind box lines",
    CurrentValue = Settings.BoxOutline,
    Flag         = "ESP_BoxOutline",
    Callback     = function(v) Settings.BoxOutline = v end,
})

ESPTab:CreateSlider({
    Name         = "Box Thickness",
    Range        = { 1, 5 },
    Increment    = 1,
    CurrentValue = Settings.BoxThickness,
    Flag         = "ESP_BoxThickness",
    Callback     = function(v) Settings.BoxThickness = v end,
})

ESPTab:CreateSlider({
    Name         = "Width Scale",
    Range        = { 60, 160 },
    Increment    = 1,
    Suffix       = "%",
    CurrentValue = Settings.BoxWidth,
    Flag         = "ESP_BoxWidth",
    Callback     = function(v) Settings.BoxWidth = v end,
})

ESPTab:CreateSlider({
    Name         = "Height Scale",
    Range        = { 60, 160 },
    Increment    = 1,
    Suffix       = "%",
    CurrentValue = Settings.BoxHeight,
    Flag         = "ESP_BoxHeight",
    Callback     = function(v) Settings.BoxHeight = v end,
})

ESPTab:CreateSlider({
    Name         = "Y Offset",
    Range        = { -30, 30 },
    Increment    = 1,
    Suffix       = " px",
    CurrentValue = Settings.BoxYOffset,
    Flag         = "ESP_BoxYOffset",
    Callback     = function(v) Settings.BoxYOffset = v end,
})

ESPTab:CreateSlider({
    Name         = "Corner Length",
    Range        = { 10, 50 },
    Increment    = 1,
    Suffix       = "%",
    CurrentValue = Settings.CornerLength,
    Flag         = "ESP_CornerLength",
    Callback     = function(v) Settings.CornerLength = v end,
})

ESPTab:CreateDivider()
ESPTab:CreateSection("Text & Health", "left")
ESPTab:CreateLabel({
    Text = "Name, distance and health bar labels.",
})

ESPTab:CreateToggle({
    Name         = "Names",
    Desc         = "Show display name above the box",
    CurrentValue = Settings.Name,
    Flag         = "ESP_Name",
    Callback     = function(v) Settings.Name = v end,
})

ESPTab:CreateSlider({
    Name         = "Name Size",
    Range        = { 10, 22 },
    Increment    = 1,
    CurrentValue = Settings.NameSize,
    Flag         = "ESP_NameSize",
    Callback     = function(v) Settings.NameSize = v end,
})

ESPTab:CreateToggle({
    Name         = "Distance",
    Desc         = "Show stud distance below the box",
    CurrentValue = Settings.Distance,
    Flag         = "ESP_Distance",
    Callback     = function(v) Settings.Distance = v end,
})

ESPTab:CreateSlider({
    Name         = "Distance Size",
    Range        = { 10, 22 },
    Increment    = 1,
    CurrentValue = Settings.DistanceSize,
    Flag         = "ESP_DistanceSize",
    Callback     = function(v) Settings.DistanceSize = v end,
})

ESPTab:CreateToggle({
    Name         = "Health Bar",
    Desc         = "Vertical bar showing current HP",
    CurrentValue = Settings.HealthBar,
    Flag         = "ESP_HealthBar",
    Callback     = function(v) Settings.HealthBar = v end,
})

ESPTab:CreateToggle({
    Name         = "Health Text",
    Desc         = "Show HP numbers next to the bar",
    CurrentValue = Settings.HealthText,
    Flag         = "ESP_HealthText",
    Callback     = function(v) Settings.HealthText = v end,
})

ESPTab:CreateSlider({
    Name         = "Health Bar Thickness",
    Range        = { 1, 6 },
    Increment    = 1,
    CurrentValue = Settings.HealthThickness,
    Flag         = "ESP_HealthThickness",
    Callback     = function(v) Settings.HealthThickness = v end,
})

ESPTab:CreateDropdown({
    Name          = "Health Color Mode",
    Options       = { "Gradient", "ESP Color", "Custom" },
    CurrentOption = Settings.HealthColorMode,
    Flag          = "ESP_HealthColorMode",
    Callback      = function(v) Settings.HealthColorMode = v end,
})

ESPTab:CreateColorPicker({
    Name     = "Custom Health Color",
    Color    = Settings.HealthCustomColor,
    Flag     = "ESP_HealthCustomColor",
    Callback = function(color)
        Settings.HealthCustomColor = normalizeColor(color, Settings.HealthCustomColor)
    end,
})

ESPTab:CreateDivider()
ESPTab:CreateSection("World Visuals", "right")
ESPTab:CreateLabel({
    Text = "Tracers, arrows and skeleton lines.",
})

ESPTab:CreateToggle({
    Name         = "Tracers",
    Desc         = "Lines drawn from screen edge to each target",
    CurrentValue = Settings.Tracers,
    Flag         = "ESP_Tracers",
    Callback     = function(v) Settings.Tracers = v end,
})

ESPTab:CreateDropdown({
    Name          = "Tracer Origin",
    Desc          = "Where the line starts on screen",
    Options       = { "Bottom", "Center", "Mouse" },
    CurrentOption = Settings.TracerOrigin,
    Flag          = "ESP_TracerOrigin",
    Callback      = function(v) Settings.TracerOrigin = v end,
})

ESPTab:CreateDropdown({
    Name          = "Tracer Target",
    Desc          = "Where the line ends on the target",
    Options       = { "Feet", "Center", "Root" },
    CurrentOption = Settings.TracerTarget,
    Flag          = "ESP_TracerTarget",
    Callback      = function(v) Settings.TracerTarget = v end,
})

ESPTab:CreateToggle({
    Name         = "Tracer Outline",
    CurrentValue = Settings.TracerOutline,
    Flag         = "ESP_TracerOutline",
    Callback     = function(v) Settings.TracerOutline = v end,
})

ESPTab:CreateSlider({
    Name         = "Tracer Thickness",
    Range        = { 1, 5 },
    Increment    = 1,
    CurrentValue = Settings.TracerThickness,
    Flag         = "ESP_TracerThickness",
    Callback     = function(v) Settings.TracerThickness = v end,
})

ESPTab:CreateToggle({
    Name         = "FOV Arrows",
    Desc         = "Pointers to off-screen targets",
    CurrentValue = Settings.Arrows,
    Flag         = "ESP_Arrows",
    Callback     = function(v) Settings.Arrows = v end,
})

ESPTab:CreateToggle({
    Name         = "Only Outside Radius",
    Desc         = "Hide arrows when target is inside FOV",
    CurrentValue = Settings.ArrowOnlyOutsideFOV,
    Flag         = "ESP_ArrowOutsideOnly",
    Callback     = function(v) Settings.ArrowOnlyOutsideFOV = v end,
})

ESPTab:CreateToggle({
    Name         = "Arrow Outline",
    CurrentValue = Settings.ArrowOutline,
    Flag         = "ESP_ArrowOutline",
    Callback     = function(v) Settings.ArrowOutline = v end,
})

ESPTab:CreateSlider({
    Name         = "Arrow Radius",
    Range        = { 60, 600 },
    Increment    = 5,
    Suffix       = " px",
    CurrentValue = Settings.ArrowRadius,
    Flag         = "ESP_ArrowRadius",
    Callback     = function(v) Settings.ArrowRadius = v end,
})

ESPTab:CreateSlider({
    Name         = "Arrow Size",
    Range        = { 8, 40 },
    Increment    = 1,
    Suffix       = " px",
    CurrentValue = Settings.ArrowSize,
    Flag         = "ESP_ArrowSize",
    Callback     = function(v) Settings.ArrowSize = v end,
})

ESPTab:CreateSlider({
    Name         = "Arrow Thickness",
    Range        = { 1, 5 },
    Increment    = 1,
    CurrentValue = Settings.ArrowThickness,
    Flag         = "ESP_ArrowThickness",
    Callback     = function(v) Settings.ArrowThickness = v end,
})

ESPTab:CreateToggle({
    Name         = "Skeleton",
    Desc         = "Bone lines connecting body parts",
    CurrentValue = Settings.Skeleton,
    Flag         = "ESP_Skeleton",
    Callback     = function(v) Settings.Skeleton = v end,
})

ESPTab:CreateToggle({
    Name         = "See-Through Chams",
    Desc         = "Highlight model visible through walls.\nMay be detected by anti-cheat",
    CurrentValue = Settings.Chams,
    Flag         = "ESP_Chams",
    Callback     = function(v)
        Settings.Chams = v
        if not v then
            for _, entry in pairs(Controller.Entries) do
                if entry.Cham then entry.Cham.Enabled = false end
            end
        end
    end,
})

ESPTab:CreateToggle({
    Name         = "Chams Through Walls",
    CurrentValue = Settings.ChamsThroughWalls,
    Flag         = "ESP_ChamsWalls",
    Callback     = function(v) Settings.ChamsThroughWalls = v end,
})

ESPTab:CreateToggle({
    Name         = "Chams Use ESP Color",
    CurrentValue = Settings.ChamsUseESPColor,
    Flag         = "ESP_ChamsUseESPColor",
    Callback     = function(v) Settings.ChamsUseESPColor = v end,
})

ESPTab:CreateSlider({
    Name         = "Chams Fill Opacity",
    Range        = { 0, 100 },
    Increment    = 1,
    Suffix       = "%",
    CurrentValue = Settings.ChamsFillOpacity,
    Flag         = "ESP_ChamsFillOpacity",
    Callback     = function(v) Settings.ChamsFillOpacity = v end,
})

ESPTab:CreateSlider({
    Name         = "Chams Outline Opacity",
    Range        = { 0, 100 },
    Increment    = 1,
    Suffix       = "%",
    CurrentValue = Settings.ChamsOutlineOpacity,
    Flag         = "ESP_ChamsOutlineOpacity",
    Callback     = function(v) Settings.ChamsOutlineOpacity = v end,
})

ESPTab:CreateColorPicker({
    Name     = "Chams Fill Color",
    Color    = Settings.ChamsFillColor,
    Flag     = "ESP_ChamsFillColor",
    Callback = function(color) Settings.ChamsFillColor = normalizeColor(color, Settings.ChamsFillColor) end,
})

ESPTab:CreateColorPicker({
    Name     = "Chams Outline Color",
    Color    = Settings.ChamsOutlineColor,
    Flag     = "ESP_ChamsOutlineColor",
    Callback = function(color) Settings.ChamsOutlineColor = normalizeColor(color, Settings.ChamsOutlineColor) end,
})

ESPTab:CreateDivider()
ESPTab:CreateSection("Colors", "left")
ESPTab:CreateLabel({
    Text = "Per-feature color overrides.",
})

ESPTab:CreateDropdown({
    Name          = "Color System",
    Desc          = "Feature = per-element colors, Target = team colors",
    Options       = { "Feature", "Target" },
    CurrentOption = Settings.ColorMode,
    Flag          = "ESP_ColorMode",
    Callback      = function(v) Settings.ColorMode = v end,
})

ESPTab:CreateColorPicker({
    Name     = "Box Color",
    Color    = Settings.BoxColor,
    Flag     = "ESP_BoxColor",
    Callback = function(color) Settings.BoxColor = normalizeColor(color, Settings.BoxColor) end,
})

ESPTab:CreateColorPicker({
    Name     = "Name Color",
    Color    = Settings.NameColor,
    Flag     = "ESP_NameColor",
    Callback = function(color) Settings.NameColor = normalizeColor(color, Settings.NameColor) end,
})

ESPTab:CreateColorPicker({
    Name     = "Distance Color",
    Color    = Settings.DistanceColor,
    Flag     = "ESP_DistanceColor",
    Callback = function(color) Settings.DistanceColor = normalizeColor(color, Settings.DistanceColor) end,
})

ESPTab:CreateColorPicker({
    Name     = "Tracer Color",
    Color    = Settings.TracerColor,
    Flag     = "ESP_TracerColor",
    Callback = function(color) Settings.TracerColor = normalizeColor(color, Settings.TracerColor) end,
})

ESPTab:CreateColorPicker({
    Name     = "FOV Arrow Color",
    Color    = Settings.ArrowColor,
    Flag     = "ESP_ArrowColor",
    Callback = function(color) Settings.ArrowColor = normalizeColor(color, Settings.ArrowColor) end,
})

ESPTab:CreateColorPicker({
    Name     = "Enemy Color",
    Color    = Settings.EnemyColor,
    Flag     = "ESP_EnemyColor",
    Callback = function(color) Settings.EnemyColor = normalizeColor(color, Settings.EnemyColor) end,
})

ESPTab:CreateColorPicker({
    Name     = "Friendly Color",
    Color    = Settings.FriendlyColor,
    Flag     = "ESP_FriendlyColor",
    Callback = function(color) Settings.FriendlyColor = normalizeColor(color, Settings.FriendlyColor) end,
})

ESPTab:CreateDivider()
ESPTab:CreateButton({
    Name     = "Unload ESP",
    Desc     = "Remove all drawings and disconnect",
    Icon     = "power",
    Callback = function() Controller:Unload() end,
})

CombatTab:CreateSection("Silent Aim / Targeting", "left")
CombatTab:CreateLabel({
    Text = "Silent aim hooks shots onto enemies.\nDetectable — use with caution.",
})

CombatTab:CreateToggle({
    Name         = "Silent Aim",
    Desc         = "Redirect shots toward the selected target",
    CurrentValue = Settings.CombatEnabled,
    Flag         = "Combat_Enabled",
    Callback     = function(v)
        Settings.CombatEnabled = v
        if not v then
            CombatRuntime.LockedEntity = nil
            CombatRuntime.LastTarget   = nil
        end
    end,
})

CombatTab:CreateDropdown({
    Name          = "Priority",
    Desc          = "How to rank multiple valid targets",
    Options       = {
        "Crosshair", "Distance", "Lowest Health",
        "Highest Health", "Lowest Health %", "Hybrid", "Random",
    },
    CurrentOption = Settings.CombatPriority,
    Flag          = "Combat_Priority",
    Callback      = function(v) Settings.CombatPriority = v end,
})

CombatTab:CreateSlider({
    Name         = "Max Distance",
    Range        = { 100, 10000 },
    Increment    = 50,
    Suffix       = " studs",
    CurrentValue = Settings.CombatMaxDistance,
    Flag         = "Combat_MaxDistance",
    Callback     = function(v) Settings.CombatMaxDistance = v end,
})

CombatTab:CreateToggle({
    Name         = "Team Check",
    Desc         = "Skip teammates as targets",
    CurrentValue = Settings.CombatTeamCheck,
    Flag         = "Combat_TeamCheck",
    Callback     = function(v) Settings.CombatTeamCheck = v end,
})

CombatTab:CreateToggle({
    Name         = "Wall Check",
    Desc         = "Only lock targets visible through walls",
    CurrentValue = Settings.CombatWallCheck,
    Flag         = "Combat_WallCheck",
    Callback     = function(v) Settings.CombatWallCheck = v end,
})

CombatTab:CreateToggle({
    Name         = "On-Screen Only",
    Desc         = "Ignore targets outside the viewport",
    CurrentValue = Settings.CombatOnScreenOnly,
    Flag         = "Combat_OnScreen",
    Callback     = function(v) Settings.CombatOnScreenOnly = v end,
})

CombatTab:CreateDivider()
CombatTab:CreateSection("Hitbox", "right")
CombatTab:CreateLabel({
    Text = "Which body part to aim at.\nHead-only raises detection risk.",
})

CombatTab:CreateDropdown({
    Name          = "Hitbox",
    Desc          = "Target body part for redirected shots",
    Options       = {
        "Head", "Torso", "Lower Torso",
        "Head/Torso Random", "Head/Torso Weighted", "Closest Part",
    },
    CurrentOption = Settings.CombatHitbox,
    Flag          = "Combat_Hitbox",
    Callback      = function(v) Settings.CombatHitbox = v end,
})

CombatTab:CreateSlider({
    Name         = "Head Chance",
    Desc         = "% chance to aim head in Weighted mode",
    Range        = { 0, 100 },
    Increment    = 1,
    Suffix       = "%",
    CurrentValue = Settings.CombatHeadChance,
    Flag         = "Combat_HeadChance",
    Callback     = function(v) Settings.CombatHeadChance = v end,
})

CombatTab:CreateToggle({
    Name         = "Velocity Prediction",
    Desc         = "Lead moving targets based on velocity",
    CurrentValue = Settings.CombatPrediction,
    Flag         = "Combat_Prediction",
    Callback     = function(v) Settings.CombatPrediction = v end,
})

CombatTab:CreateSlider({
    Name         = "Prediction",
    Range        = { 0, 250 },
    Increment    = 1,
    Suffix       = " ms",
    CurrentValue = Settings.CombatPredictionMs,
    Flag         = "Combat_PredictionMs",
    Callback     = function(v) Settings.CombatPredictionMs = v end,
})

CombatTab:CreateDivider()
CombatTab:CreateSection("FOV Circle", "left")
CombatTab:CreateLabel({
    Text = "Visual indicator of the aim lock radius.",
})

CombatTab:CreateToggle({
    Name         = "Show FOV",
    Desc         = "Draw the targeting radius on screen",
    CurrentValue = Settings.CombatFOVVisible,
    Flag         = "Combat_FOVVisible",
    Callback     = function(v) Settings.CombatFOVVisible = v end,
})

CombatTab:CreateSlider({
    Name         = "Radius",
    Range        = { 20, 800 },
    Increment    = 5,
    Suffix       = " px",
    CurrentValue = Settings.CombatFOVRadius,
    Flag         = "Combat_FOVRadius",
    Callback     = function(v) Settings.CombatFOVRadius = v end,
})

CombatTab:CreateDropdown({
    Name          = "Center",
    Options       = { "Screen Center", "Mouse" },
    CurrentOption = Settings.CombatFOVCenter,
    Flag          = "Combat_FOVCenter",
    Callback      = function(v) Settings.CombatFOVCenter = v end,
})

CombatTab:CreateSlider({
    Name         = "Opacity",
    Range        = { 5, 100 },
    Increment    = 1,
    Suffix       = "%",
    CurrentValue = Settings.CombatFOVOpacity,
    Flag         = "Combat_FOVOpacity",
    Callback     = function(v) Settings.CombatFOVOpacity = v end,
})

CombatTab:CreateSlider({
    Name         = "Thickness",
    Range        = { 1, 4 },
    Increment    = 1,
    CurrentValue = Settings.CombatFOVThickness,
    Flag         = "Combat_FOVThickness",
    Callback     = function(v) Settings.CombatFOVThickness = v end,
})

CombatTab:CreateSlider({
    Name         = "Sides",
    Range        = { 16, 128 },
    Increment    = 4,
    CurrentValue = Settings.CombatFOVSides,
    Flag         = "Combat_FOVSides",
    Callback     = function(v) Settings.CombatFOVSides = v end,
})

CombatTab:CreateToggle({
    Name         = "Filled",
    CurrentValue = Settings.CombatFOVFilled,
    Flag         = "Combat_FOVFilled",
    Callback     = function(v) Settings.CombatFOVFilled = v end,
})

CombatTab:CreateColorPicker({
    Name     = "FOV Color",
    Color    = Settings.CombatFOVColor,
    Flag     = "Combat_FOVColor",
    Callback = function(color) Settings.CombatFOVColor = normalizeColor(color, Settings.CombatFOVColor) end,
})

CombatTab:CreateToggle({
    Name         = "Bullet Impact Guide",
    Desc         = "Line from FOV center to locked target",
    CurrentValue = Settings.CombatImpactLine,
    Flag         = "Combat_ImpactLine",
    Callback     = function(v) Settings.CombatImpactLine = v end,
})

CombatTab:CreateSlider({
    Name         = "Guide Thickness",
    Range        = { 1, 4 },
    Increment    = 1,
    CurrentValue = Settings.CombatImpactLineThickness,
    Flag         = "Combat_ImpactLineThickness",
    Callback     = function(v) Settings.CombatImpactLineThickness = v end,
})

CombatTab:CreateSlider({
    Name         = "Guide Opacity",
    Range        = { 10, 100 },
    Increment    = 1,
    Suffix       = "%",
    CurrentValue = Settings.CombatImpactLineOpacity,
    Flag         = "Combat_ImpactLineOpacity",
    Callback     = function(v) Settings.CombatImpactLineOpacity = v end,
})

CombatTab:CreateColorPicker({
    Name     = "Impact Guide Color",
    Color    = Settings.CombatImpactLineColor,
    Flag     = "Combat_ImpactLineColor",
    Callback = function(color) Settings.CombatImpactLineColor = normalizeColor(color, Settings.CombatImpactLineColor) end,
})

CombatTab:CreateDivider()
CombatTab:CreateSection("Advanced", "right")
CombatTab:CreateLabel({
    Text = "Target lock, switch delay and indicator.\nTuning these wrong may feel choppy.",
})

CombatTab:CreateToggle({
    Name         = "Target Lock",
    Desc         = "Stick to the same target until lost",
    CurrentValue = Settings.CombatTargetLock,
    Flag         = "Combat_TargetLock",
    Callback     = function(v)
        Settings.CombatTargetLock = v
        if not v then CombatRuntime.LockedEntity = nil end
    end,
})

CombatTab:CreateSlider({
    Name         = "Lock FOV Tolerance",
    Desc         = "How far outside FOV to keep a locked target",
    Range        = { 100, 250 },
    Increment    = 5,
    Suffix       = "%",
    CurrentValue = Settings.CombatLockFOVScale,
    Flag         = "Combat_LockFOVScale",
    Callback     = function(v) Settings.CombatLockFOVScale = v end,
})

CombatTab:CreateSlider({
    Name         = "Switch Delay",
    Desc         = "Minimum ms before switching targets",
    Range        = { 0, 1000 },
    Increment    = 10,
    Suffix       = " ms",
    CurrentValue = math.floor(Settings.CombatSwitchDelay * 1000 + 0.5),
    Flag         = "Combat_SwitchDelay",
    Callback     = function(v) Settings.CombatSwitchDelay = v / 1000 end,
})

CombatTab:CreateToggle({
    Name         = "Target Indicator",
    Desc         = "Circle drawn over the locked target",
    CurrentValue = Settings.CombatTargetIndicator,
    Flag         = "Combat_TargetIndicator",
    Callback     = function(v) Settings.CombatTargetIndicator = v end,
})

CombatTab:CreateSlider({
    Name         = "Indicator Size",
    Range        = { 2, 20 },
    Increment    = 1,
    Suffix       = " px",
    CurrentValue = Settings.CombatIndicatorSize,
    Flag         = "Combat_IndicatorSize",
    Callback     = function(v) Settings.CombatIndicatorSize = v end,
})

CombatTab:CreateColorPicker({
    Name     = "Indicator Color",
    Color    = Settings.CombatIndicatorColor,
    Flag     = "Combat_IndicatorColor",
    Callback = function(color) Settings.CombatIndicatorColor = normalizeColor(color, Settings.CombatIndicatorColor) end,
})

CombatTab:CreateDivider()
CombatTab:CreateSection("Hybrid Weights", "left")
CombatTab:CreateLabel({
    Text = "Only used when Priority is set to Hybrid.",
})

CombatTab:CreateSlider({
    Name         = "Crosshair Weight",
    Range        = { 0, 100 },
    Increment    = 1,
    CurrentValue = Settings.CombatHybridCrosshairWeight,
    Flag         = "Combat_HybridCrosshair",
    Callback     = function(v) Settings.CombatHybridCrosshairWeight = v end,
})

CombatTab:CreateSlider({
    Name         = "Distance Weight",
    Range        = { 0, 100 },
    Increment    = 1,
    CurrentValue = Settings.CombatHybridDistanceWeight,
    Flag         = "Combat_HybridDistance",
    Callback     = function(v) Settings.CombatHybridDistanceWeight = v end,
})

CombatTab:CreateSlider({
    Name         = "Low-Health Weight",
    Range        = { 0, 100 },
    Increment    = 1,
    CurrentValue = Settings.CombatHybridHealthWeight,
    Flag         = "Combat_HybridHealth",
    Callback     = function(v) Settings.CombatHybridHealthWeight = v end,
})

CombatTab:CreateLabel({
    Text = CombatHooksInstalled and "Combat hooks: ready" or "Combat hooks: unavailable",
})

SettingsTab:CreateSection("Loads")
SettingsTab:CreateLabel({
    Text = "Paste your RAW GitHub load URL below.\nIt will be queued again automatically after teleport/rejoin.",
})
SettingsTab:CreateInput({
    Name = "Loads",
    Placeholder = "https://raw.githubusercontent.com/...",
    CurrentValue = WACX_RELOAD_URL == "" and "" or WACX_RELOAD_URL,
    Finished = true,
    Callback = function(value)
        WACX_RELOAD_URL = tostring(value or "")
        QueueWacxReload()
    end,
})
SettingsTab:CreateButton({
    Name = "Queue Reload",
    Callback = function()
        QueueWacxReload()
        Notify({
            Title = "Wacx/Sniper Arena",
            Description = "Reload is queued for the next server teleport.",
            Icon = "refresh-cw",
            Duration = 3,
        })
    end,
})
SettingsTab:CreateLabel({
    Text = "Auto reload uses the executor's queue-on-teleport API.\nNo automatic save is used.",
})

-- Install combat hooks AFTER the Obsidian window is fully built.
-- This prevents a missing/delayed game module from blocking the entire GUI.
task.spawn(function()
    local ok, result = pcall(installCombatHooks)
    CombatHooksInstalled = ok and result == true
    CombatRuntime.Available = CombatHooksInstalled
end)

function Controller:Unload()
    if self.Unloaded then return end
    self.Unloaded = true
    for _, connection in ipairs(self.Connections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(self.Connections)
    local entities = {}
    for entity in pairs(self.Entries) do
        table.insert(entities, entity)
    end
    for _, entity in ipairs(entities) do
        destroyEntry(entity)
    end
    if self.CombatDrawings then
        for _, drawing in ipairs(self.CombatDrawings) do
            safeRemove(drawing)
        end
        table.clear(self.CombatDrawings)
    end
    local reviewedHookState = ENV[COMBAT_HOOK_STATE_KEY]
    if reviewedHookState and reviewedHookState.Controller == self then
        reviewedHookState.Controller    = nil
        reviewedHookState.SilentTarget  = nil
        reviewedHookState.InLocalShoot  = false
    end
    pcall(function() self.Library:Unload() end)
    if ENV.WacxSniperArena == self then
        ENV.WacxSniperArena = nil
    end
end

if not DRAWING_AVAILABLE then
    Notify({
        Title       = "Wacx/Sniper Arena",
        Description = "Drawing API not found.\nChams and menu still work, but 2D ESP requires Drawing.new support.",
        Duration    = 8,
    })
end

local renderConnection = RunService.RenderStepped:Connect(function()
    if Controller.Unloaded then return end
    updateCombatDrawings()
    for entity, entry in pairs(Controller.Entries) do
        if entity.Parent then
            local ok = pcall(updateEntry, entry)
            if not ok then hideEntry(entry, true) end
        else
            hideEntry(entry, true)
        end
    end
end)
table.insert(Controller.Connections, renderConnection)

local refreshQueued = false
local function queueEntityRefresh()
    if Controller.Unloaded or refreshQueued then return end
    refreshQueued = true
    task.defer(function()
        refreshQueued = false
        if not Controller.Unloaded then pcall(refreshEntities) end
    end)
end

local world = Workspace:FindFirstChild("World")
if world then
    table.insert(Controller.Connections, world.DescendantAdded:Connect(function(instance)
        local parent = instance.Parent
        if instance.Name == "Entities"
            or (parent and parent.Name == "Entities" and instance:IsA("Model")) then
            queueEntityRefresh()
        end
    end))
    table.insert(Controller.Connections, world.DescendantRemoving:Connect(function(instance)
        local parent = instance.Parent
        if parent and parent.Name == "Entities" and instance:IsA("Model") then
            queueEntityRefresh()
        end
    end))
end

local workspaceHighlight = Workspace:FindFirstChild("Highlight")
if workspaceHighlight then
    table.insert(Controller.Connections, workspaceHighlight.DescendantAdded:Connect(function(instance)
        if instance:IsA("Model") then queueEntityRefresh() end
    end))
    table.insert(Controller.Connections, workspaceHighlight.DescendantRemoving:Connect(function(instance)
        if instance:IsA("Model") then queueEntityRefresh() end
    end))
end

task.spawn(function()
    while not Controller.Unloaded do
        pcall(refreshEntities)
        task.wait(Settings.DiscoveryInterval)
    end
end)

refreshEntities()