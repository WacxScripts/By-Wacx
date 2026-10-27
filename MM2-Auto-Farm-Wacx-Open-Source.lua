local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local VirtualUser        = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local VERSION = "v3.3.2"

local cfg = {
	autoFarm   = false,
	antiAFK    = true,
	farmSpeed  = 25,
	loopDelay  = 0.18,
}

local stats = {
	coins   = 0,
	started = os.clock(),
}

local C = {
	bgTop    = Color3.fromRGB(17, 22, 31),
	bgBot    = Color3.fromRGB(8, 11, 17),
	card     = Color3.fromRGB(12, 16, 23),
	glass    = Color3.fromRGB(22, 29, 39),
	glassTop = Color3.fromRGB(30, 40, 52),
	accent   = Color3.fromRGB(0, 220, 190),
	accent2  = Color3.fromRGB(122, 255, 231),
	trackOff = Color3.fromRGB(52, 66, 78),
	ink      = Color3.fromRGB(241, 247, 250),
	inkSoft  = Color3.fromRGB(151, 169, 181),
}

local function corner(inst, r)
	local u = Instance.new("UICorner")
	u.CornerRadius = UDim.new(0, r or 8)
	u.Parent = inst
	return u
end

local function pad(inst, p)
	local u = Instance.new("UIPadding")
	u.PaddingLeft   = UDim.new(0, p)
	u.PaddingRight  = UDim.new(0, p)
	u.PaddingTop    = UDim.new(0, p)
	u.PaddingBottom = UDim.new(0, p)
	u.Parent = inst
	return u
end

local function gradient(inst, c1, c2, rot)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(c1, c2)
	g.Rotation = rot or 90
	g.Parent = inst
	return g
end

local function stroke(inst, col, thick, trans)
	local s = Instance.new("UIStroke")
	s.Color = col
	s.Thickness = thick or 1
	s.Transparency = trans or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = inst
	return s
end

local function addPop(btn, down)
	local sc = Instance.new("UIScale")
	sc.Parent = btn
	local target = down or 0.9
	local function to(v)
		TweenService:Create(sc, TweenInfo.new(0.1, Enum.EasingStyle.Quad), { Scale = v }):Play()
	end
	btn.MouseButton1Down:Connect(function() to(target) end)
	btn.MouseButton1Up:Connect(function() to(1) end)
	btn.MouseLeave:Connect(function() to(1) end)
end

local guiParent = PlayerGui
do
	local ok, hui = pcall(function() return gethui and gethui() end)
	if ok and hui then
		guiParent = hui
	else
		local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
		if ok2 and cg then guiParent = cg end
	end
end

for _, where in ipairs({ guiParent, PlayerGui, game:GetService("CoreGui") }) do
	pcall(function()
		for _, name in ipairs({ "WacxMM2Autofarm", "HalloweenAutofarm", "SummerAutofarm", "Heatwave", "XHub" }) do
			local old = where:FindFirstChild(name)
			if old then old:Destroy() end
		end
	end)
end

local gui = Instance.new("ScreenGui")
gui.Name = "WacxMM2Autofarm"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999999
if not pcall(function() gui.Parent = guiParent end) then
	gui.Parent = PlayerGui
end
local toastLayer = Instance.new("Frame")
toastLayer.Name = "ToastLayer"
toastLayer.BackgroundTransparency = 1
toastLayer.AnchorPoint = Vector2.new(1, 0)
toastLayer.Position = UDim2.new(1, -14, 0, 14)
toastLayer.Size = UDim2.new(0, math.clamp((workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 360) * 0.88, 240, 320), 0, 180)
toastLayer.ZIndex = 100
toastLayer.Parent = gui
local toastLayout = Instance.new("UIListLayout")
toastLayout.Padding = UDim.new(0, 8)
toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
toastLayout.Parent = toastLayer
local toastCount = 0
local function notify(message, kind, duration)
	toastCount += 1
	local toast = Instance.new("Frame")
	toast.Name = "Toast"
	toast.LayoutOrder = -toastCount
	toast.Size = UDim2.new(1, 0, 0, 48)
	toast.BackgroundColor3 = C.glass
	toast.BackgroundTransparency = 0.04
	toast.BorderSizePixel = 0
	toast.ZIndex = 101
	toast.Parent = toastLayer
	corner(toast, 10)
	local edge = stroke(toast, kind == "error" and Color3.fromRGB(255, 100, 110) or C.accent, 1.2, 0.25)
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0, 3, 1, -14)
	bar.Position = UDim2.new(0, 7, 0, 7)
	bar.BackgroundColor3 = kind == "error" and Color3.fromRGB(255, 100, 110) or C.accent
	bar.BorderSizePixel = 0
	bar.ZIndex = 102
	bar.Parent = toast
	corner(bar, 2)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0, 18, 0, 0)
	label.Size = UDim2.new(1, -28, 1, 0)
	label.Font = Enum.Font.GothamMedium
	label.Text = tostring(message)
	label.TextColor3 = C.ink
	label.TextSize = 12
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 102
	label.Parent = toast
	task.delay(duration or 2.8, function()
		if toast and toast.Parent then
			local tw = TweenService:Create(toast, TweenInfo.new(0.2), {BackgroundTransparency = 1})
			tw:Play()
			task.wait(0.22)
			if toast then toast:Destroy() end
		end
	end)
end

local camera = workspace.CurrentCamera
local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local WIN_W = math.floor(math.clamp(viewport.X * (IS_MOBILE and 0.92 or 0.36), IS_MOBILE and 290 or 340, IS_MOBILE and 430 or 470))
local WIN_H = math.floor(math.clamp(viewport.Y * (IS_MOBILE and 0.78 or 0.72), IS_MOBILE and 320 or 390, 610))

local win = Instance.new("Frame")
win.Name = "Window"
win.AnchorPoint = Vector2.new(0, 0)
win.Position = UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2)
win.Size = UDim2.new(0, WIN_W, 0, WIN_H)
win.BackgroundColor3 = C.card
win.BorderSizePixel = 0
win.ZIndex = 2
win.Active = true
win.ClipsDescendants = true
win.Parent = gui
corner(win, 16)

local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://6014261993"
shadow.ImageColor3 = Color3.fromRGB(120, 82, 190)
shadow.ImageTransparency = 0.5
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(49, 49, 450, 450)
shadow.ZIndex = 1
shadow.Parent = gui
local function syncShadow()
	local p, s = win.Position, win.Size
	shadow.Position = UDim2.new(p.X.Scale, p.X.Offset - 22, p.Y.Scale, p.Y.Offset - 18)
	shadow.Size = UDim2.new(s.X.Scale, s.X.Offset + 44, s.Y.Scale, s.Y.Offset + 46)
end
win:GetPropertyChangedSignal("Position"):Connect(syncShadow)
win:GetPropertyChangedSignal("Size"):Connect(syncShadow)
syncShadow()

gradient(win, C.bgTop, C.bgBot, 90)
stroke(win, C.accent, 1.5, 0.45)

local miniIcon = Instance.new("TextButton")
miniIcon.Name = "WacxMiniIcon"
miniIcon.Size = UDim2.new(0, 54, 0, 54)
miniIcon.Position = UDim2.new(1, -72, 0.5, -27)
miniIcon.BackgroundColor3 = C.accent
miniIcon.Text = "W"
miniIcon.TextColor3 = Color3.fromRGB(8, 15, 20)
miniIcon.TextSize = 22
miniIcon.Font = Enum.Font.GothamBlack
miniIcon.Visible = false
miniIcon.Active = true
miniIcon.AutoButtonColor = false
miniIcon.ZIndex = 20
miniIcon.Parent = gui
corner(miniIcon, 18)
stroke(miniIcon, C.accent2, 2, 0.12)
gradient(miniIcon, C.accent2, C.accent, 35)

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 62)
header.BackgroundTransparency = 1
header.BorderSizePixel = 0
header.Parent = win

local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -24, 0, 1)
divider.Position = UDim2.new(0, 12, 1, -1)
divider.BackgroundColor3 = C.ink
divider.BackgroundTransparency = 0.9
divider.BorderSizePixel = 0
divider.Parent = header

local accentBar = Instance.new("Frame")
accentBar.Name = "AccentBar"
accentBar.Position = UDim2.new(0, 12, 1, -2)
accentBar.Size = UDim2.new(0, 66, 0, 3)
accentBar.BackgroundColor3 = C.accent
accentBar.BorderSizePixel = 0
accentBar.Parent = header
corner(accentBar, 2)
gradient(accentBar, C.accent2, C.accent, 0)

local badge = Instance.new("Frame")
badge.Size = UDim2.new(0, 36, 0, 36)
badge.AnchorPoint = Vector2.new(0, 0.5)
badge.Position = UDim2.new(0, 14, 0.5, 0)
badge.BackgroundColor3 = C.accent
badge.BorderSizePixel = 0
badge.Parent = header
corner(badge, 9)
gradient(badge, C.accent2, C.accent, 115)
stroke(badge, C.accent2, 1, 0.4)

local sun = Instance.new("TextLabel")
sun.Size = UDim2.new(1, 0, 1, 0)
sun.BackgroundTransparency = 1
sun.Text = "W"
sun.TextColor3 = Color3.fromRGB(255, 255, 255)
sun.TextSize = 19
sun.Font = Enum.Font.GothamBold
sun.Parent = badge

local titleWrap = Instance.new("Frame")
titleWrap.Size = UDim2.new(1, -150, 1, 0)
titleWrap.Position = UDim2.new(0, 60, 0, 0)
titleWrap.BackgroundTransparency = 1
titleWrap.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 22)
title.Position = UDim2.new(0, 0, 0, 8)
title.BackgroundTransparency = 1
title.Text = "WACX  /  MM2"
title.TextColor3 = C.ink
title.TextSize = 17
title.Font = Enum.Font.GothamBlack
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleWrap
gradient(title, C.ink, C.accent2, 0)

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 7, 0, 7)
statusDot.AnchorPoint = Vector2.new(0, 0.5)
statusDot.Position = UDim2.new(0, 1, 0, 37)
statusDot.BackgroundColor3 = C.inkSoft
statusDot.BorderSizePixel = 0
statusDot.Parent = titleWrap
corner(statusDot, 4)

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -14, 0, 14)
subtitle.Position = UDim2.new(0, 14, 0, 30)
subtitle.BackgroundTransparency = 1
subtitle.Text = "OPEN SOURCE  •  PC + MOBILE"
subtitle.TextColor3 = C.inkSoft
subtitle.TextTransparency = 0
subtitle.TextSize = 11
subtitle.Font = Enum.Font.GothamMedium
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = titleWrap

local minBtn = Instance.new("TextButton")
minBtn.Name = "Min"
minBtn.AnchorPoint = Vector2.new(1, 0.5)
minBtn.Position = UDim2.new(1, -16, 0.5, 0)
minBtn.Size = UDim2.new(0, 32, 0, 32)
minBtn.BackgroundColor3 = C.glass
minBtn.BackgroundTransparency = 0.2
minBtn.Text = "–"
minBtn.TextColor3 = C.ink
minBtn.TextSize = 22
minBtn.Font = Enum.Font.GothamBold
minBtn.AutoButtonColor = false
minBtn.Parent = header
corner(minBtn, 8)
stroke(minBtn, C.accent, 1, 0.75)
addPop(minBtn)

local miniBtn = Instance.new("TextButton")
miniBtn.Name = "MiniMode"
miniBtn.AnchorPoint = Vector2.new(1, 0.5)
miniBtn.Position = UDim2.new(1, -54, 0.5, 0)
miniBtn.Size = UDim2.new(0, 30, 0, 30)
miniBtn.BackgroundColor3 = C.glass
miniBtn.Text = "◈"
miniBtn.TextColor3 = C.accent
miniBtn.TextSize = 16
miniBtn.Font = Enum.Font.GothamBold
miniBtn.AutoButtonColor = false
miniBtn.Parent = header
corner(miniBtn, 8)
stroke(miniBtn, C.accent, 1, 0.75)
addPop(miniBtn)

local nav = Instance.new("Frame")
nav.Name = "Navigation"
nav.Position = UDim2.new(0, 12, 0, 69)
nav.Size = UDim2.new(1, -24, 0, 36)
nav.BackgroundColor3 = C.card
nav.BorderSizePixel = 0
nav.Parent = win
corner(nav, 10)
stroke(nav, C.inkSoft, 1, 0.88)

local navLayout = Instance.new("UIListLayout")
navLayout.FillDirection = Enum.FillDirection.Horizontal
navLayout.SortOrder = Enum.SortOrder.LayoutOrder
navLayout.Padding = UDim.new(0, 4)
navLayout.Parent = nav
pad(nav, 4)

local pages = {}
local pageButtons = {}
local body
local pageNames = {"Home", "Farm", "Settings", "About"}
for _, pageName in ipairs(pageNames) do
	local page = Instance.new("ScrollingFrame")
	page.Name = pageName .. "Page"
	page.Active = true
	page.Position = UDim2.new(0, 0, 0, 112)
	page.Size = UDim2.new(1, 0, 1, -112)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 3
	page.ScrollBarImageColor3 = C.accent
	page.ScrollBarImageTransparency = 0.45
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.Visible = pageName == "Home"
	page.Parent = win
	pad(page, 12)

	local pageList = Instance.new("UIListLayout")
	pageList.Padding = UDim.new(0, 10)
	pageList.SortOrder = Enum.SortOrder.LayoutOrder
	pageList.Parent = page
	pageList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		page.CanvasSize = UDim2.new(0, 0, 0, pageList.AbsoluteContentSize.Y + 24)
	end)
	pages[pageName] = page

	local button = Instance.new("TextButton")
	button.Name = pageName .. "Tab"
	button.LayoutOrder = table.find(pageNames, pageName)
	button.Size = UDim2.new(0.25, -5, 1, 0)
	button.BackgroundColor3 = pageName == "Home" and C.accent or C.glass
	button.BorderSizePixel = 0
	button.Text = string.upper(pageName)
	button.TextColor3 = pageName == "Home" and C.bgBot or C.inkSoft
	button.TextSize = IS_MOBILE and 10 or 11
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = false
	button.Parent = nav
	corner(button, 7)
	pageButtons[pageName] = button
end

local function switchPage(name)
	for pageName, page in pairs(pages) do
		page.Visible = pageName == name
		local button = pageButtons[pageName]
		local selected = pageName == name
		button.BackgroundColor3 = selected and C.accent or C.glass
		button.TextColor3 = selected and C.bgBot or C.inkSoft
	end
end
for pageName, button in pairs(pageButtons) do
	button.Activated:Connect(function() switchPage(pageName) end)
end
body = pages.Home

local order = 0
local function nextOrder()
	order = order + 1
	return order
end

local function sectionLabel(text)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, 0, 0, 16)
	l.BackgroundTransparency = 1
	l.Text = string.upper(text)
	l.TextColor3 = C.inkSoft
	l.TextSize = 10
	l.Font = Enum.Font.GothamBlack
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.LayoutOrder = nextOrder()
	l.Parent = body
	return l
end

local function card(height)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, height)
	f.BackgroundColor3 = C.glass
	f.BackgroundTransparency = 0.12
	f.BorderSizePixel = 0
	f.LayoutOrder = nextOrder()
	f.Parent = body
	corner(f, 14)

	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new(C.glassTop, C.glass)
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.0),
		NumberSequenceKeypoint.new(1, 0.28),
	})
	g.Parent = f

	stroke(f, C.accent, 1, 0.72)
	return f
end

local function toggle(label, sub, initial, onChange)
	local f = card(sub and 54 or 44)

	local name = Instance.new("TextLabel")
	name.Position = UDim2.new(0, 12, 0, sub and 8 or 0)
	name.Size = UDim2.new(1, -80, 0, sub and 20 or 44)
	name.BackgroundTransparency = 1
	name.Text = label
	name.TextColor3 = C.ink
	name.TextSize = 14
	name.Font = Enum.Font.GothamSemibold
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextYAlignment = sub and Enum.TextYAlignment.Bottom or Enum.TextYAlignment.Center
	name.Parent = f

	if sub then
		local d = Instance.new("TextLabel")
		d.Position = UDim2.new(0, 12, 0, 28)
		d.Size = UDim2.new(1, -80, 0, 16)
		d.BackgroundTransparency = 1
		d.Text = sub
		d.TextColor3 = C.inkSoft
		d.TextSize = 11
		d.Font = Enum.Font.Gotham
		d.TextXAlignment = Enum.TextXAlignment.Left
		d.Parent = f
	end

	local track = Instance.new("TextButton")
	track.AnchorPoint = Vector2.new(1, 0.5)
	track.Position = UDim2.new(1, -12, 0.5, 0)
	track.Size = UDim2.new(0, 50, 0, 26)
	track.AutoButtonColor = false
	track.Text = ""
	track.BackgroundColor3 = initial and C.accent or C.trackOff
	track.Parent = f
	corner(track, 13)
	addPop(track, 0.94)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 20, 0, 20)
	knob.Position = initial and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
	knob.BackgroundColor3 = Color3.fromRGB(255, 240, 222)
	knob.BorderSizePixel = 0
	knob.Parent = track
	corner(knob, 10)
	stroke(knob, Color3.fromRGB(20, 10, 30), 1, 0.6)

	local state = initial
	local ti = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	track.Activated:Connect(function()
		state = not state
		TweenService:Create(track, ti, { BackgroundColor3 = state and C.accent or C.trackOff }):Play()
		TweenService:Create(knob, ti, {
			Position = state and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10),
		}):Play()
		onChange(state)
	end)

	return f
end

local function slider(label, minV, maxV, initial, suffix, onChange)
	local f = card(58)

	local name = Instance.new("TextLabel")
	name.Position = UDim2.new(0, 12, 0, 8)
	name.Size = UDim2.new(1, -80, 0, 18)
	name.BackgroundTransparency = 1
	name.Text = label
	name.TextColor3 = C.ink
	name.TextSize = 14
	name.Font = Enum.Font.GothamSemibold
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Parent = f

	local val = Instance.new("TextLabel")
	val.AnchorPoint = Vector2.new(1, 0)
	val.Position = UDim2.new(1, -12, 0, 8)
	val.Size = UDim2.new(0, 70, 0, 18)
	val.BackgroundTransparency = 1
	val.Text = tostring(initial) .. (suffix or "")
	val.TextColor3 = C.accent
	val.TextSize = 14
	val.Font = Enum.Font.GothamBold
	val.TextXAlignment = Enum.TextXAlignment.Right
	val.Parent = f

	local track = Instance.new("Frame")
	track.Position = UDim2.new(0, 12, 0, 38)
	track.Size = UDim2.new(1, -24, 0, 8)
	track.BackgroundColor3 = C.trackOff
	track.BorderSizePixel = 0
	track.Parent = f
	corner(track, 4)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new((initial - minV) / (maxV - minV), 0, 1, 0)
	fill.BackgroundColor3 = C.accent
	fill.BorderSizePixel = 0
	fill.Parent = track
	corner(fill, 4)
	gradient(fill, C.accent2, C.accent, 0)

	local knob = Instance.new("Frame")
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new((initial - minV) / (maxV - minV), 0, 0.5, 0)
	knob.Size = UDim2.new(0, 16, 0, 16)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.ZIndex = 2
	knob.Parent = track
	corner(knob, 8)
	stroke(knob, C.accent, 1.4, 0.15)

	local hit = Instance.new("TextButton")
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.Position = UDim2.new(0, 0, 0, -12)
	hit.Size = UDim2.new(1, 0, 0, 32)
	hit.ZIndex = 3
	hit.Parent = track

	local dragging = false

	local function setFromX(px)
		local a = math.clamp((px - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		local v = math.floor(minV + a * (maxV - minV) + 0.5)
		fill.Size = UDim2.new(a, 0, 1, 0)
		knob.Position = UDim2.new(a, 0, 0.5, 0)
		val.Text = tostring(v) .. (suffix or "")
		onChange(v)
	end

	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromX(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			setFromX(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	return f
end

local function statRow(label, initial)
	local f = card(38)
	local n = Instance.new("TextLabel")
	n.Position = UDim2.new(0, 12, 0, 0)
	n.Size = UDim2.new(0.6, 0, 1, 0)
	n.BackgroundTransparency = 1
	n.Text = label
	n.TextColor3 = C.inkSoft
	n.TextSize = 13
	n.Font = Enum.Font.GothamMedium
	n.TextXAlignment = Enum.TextXAlignment.Left
	n.Parent = f

	local v = Instance.new("TextLabel")
	v.AnchorPoint = Vector2.new(1, 0)
	v.Position = UDim2.new(1, -12, 0, 0)
	v.Size = UDim2.new(0.4, 0, 1, 0)
	v.BackgroundTransparency = 1
	v.Text = tostring(initial)
	v.TextColor3 = C.accent
	v.TextSize = 15
	v.Font = Enum.Font.GothamBold
	v.TextXAlignment = Enum.TextXAlignment.Right
	v.Parent = f
	return v
end

body = pages.Home
sectionLabel("Overview")
local overview = card(48)

local overviewTitle = Instance.new("TextLabel")
overviewTitle.Position = UDim2.new(0, 12, 0, 6)
overviewTitle.Size = UDim2.new(1, -24, 0, 17)
overviewTitle.BackgroundTransparency = 1
overviewTitle.Text = "MM2 AUTOFARM"
overviewTitle.TextColor3 = C.ink
overviewTitle.TextSize = 12
overviewTitle.Font = Enum.Font.GothamBold
overviewTitle.TextXAlignment = Enum.TextXAlignment.Left
overviewTitle.Parent = overview

local overviewStatus = Instance.new("TextLabel")
overviewStatus.Position = UDim2.new(0, 12, 0, 24)
overviewStatus.Size = UDim2.new(1, -24, 0, 15)
overviewStatus.BackgroundTransparency = 1
overviewStatus.Text = "Status: Idle"
overviewStatus.TextColor3 = C.inkSoft
overviewStatus.TextSize = 11
overviewStatus.Font = Enum.Font.Gotham
overviewStatus.TextXAlignment = Enum.TextXAlignment.Left
overviewStatus.Parent = overview

local liveStatus = Instance.new("TextLabel")
liveStatus.Name = "LiveStatus"
liveStatus.Position = UDim2.new(0, 12, 0, 39)
liveStatus.Size = UDim2.new(1, -24, 0, 13)
liveStatus.BackgroundTransparency = 1
liveStatus.Text = "Round: Waiting for round state"
liveStatus.TextColor3 = C.inkSoft
liveStatus.TextSize = 10
liveStatus.Font = Enum.Font.Gotham
liveStatus.TextXAlignment = Enum.TextXAlignment.Left
liveStatus.Parent = overview
overview.Size = UDim2.new(1, 0, 0, 58)

body = pages.Farm
sectionLabel("Farm Controls")
toggle("Auto Farm", "Collect available map coins during a round", cfg.autoFarm, function(s)
	cfg.autoFarm = s
	overviewStatus.Text = s and "Status: Enabled" or "Status: Idle"
	notify(s and "Auto Farm enabled" or "Auto Farm disabled", "info")
	overviewStatus.TextColor3 = s and Color3.fromRGB(142, 255, 178) or C.inkSoft
	TweenService:Create(statusDot, TweenInfo.new(0.2), {
		BackgroundColor3 = s and Color3.fromRGB(120, 255, 90) or C.inkSoft,
	}):Play()
end)
slider("Farm Speed", 5, 120, cfg.farmSpeed, "", function(v)
	cfg.farmSpeed = v
end)

body = pages.Settings
sectionLabel("Session Utility")
toggle("Anti AFK", "Reduce idle disconnects while enabled", cfg.antiAFK, function(s)
	cfg.antiAFK = s
	notify(s and "Anti AFK enabled" or "Anti AFK disabled", "info")
end)
sectionLabel("Accent Theme")
local themeCard = card(104)
local themeNames = {"Aqua", "Violet", "Crimson", "Amber"}
local themeColors = {
	Aqua = {Color3.fromRGB(0, 220, 190), Color3.fromRGB(122, 255, 231)},
	Violet = {Color3.fromRGB(165, 110, 255), Color3.fromRGB(214, 185, 255)},
	Crimson = {Color3.fromRGB(255, 82, 112), Color3.fromRGB(255, 170, 184)},
	Amber = {Color3.fromRGB(255, 177, 61), Color3.fromRGB(255, 222, 145)},
}
local themeButtons = {}
local function colorEq(a, b)
	return typeof(a) == "Color3" and math.abs(a.R-b.R) < 0.005 and math.abs(a.G-b.G) < 0.005 and math.abs(a.B-b.B) < 0.005
end
local function applyTheme(name)
	local palette = themeColors[name]
	if not palette then return end
	local oldAccent, oldAccent2 = C.accent, C.accent2
	C.accent, C.accent2 = palette[1], palette[2]
	for _, obj in ipairs(gui:GetDescendants()) do
		pcall(function()
			if obj:IsA("GuiObject") and colorEq(obj.BackgroundColor3, oldAccent) then obj.BackgroundColor3 = C.accent end
			if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
				if colorEq(obj.TextColor3, oldAccent) then obj.TextColor3 = C.accent end
				if colorEq(obj.TextColor3, oldAccent2) then obj.TextColor3 = C.accent2 end
			end
			if obj:IsA("UIStroke") and colorEq(obj.Color, oldAccent) then obj.Color = C.accent end
			if obj:IsA("UIGradient") then
				local keys = obj.Color.Keypoints
				local changed = false
				local newKeys = {}
				for _, key in ipairs(keys) do
					local col = key.Value
					if colorEq(col, oldAccent) then col = C.accent; changed = true
					elseif colorEq(col, oldAccent2) then col = C.accent2; changed = true end
					table.insert(newKeys, ColorSequenceKeypoint.new(key.Time, col))
				end
				if changed then obj.Color = ColorSequence.new(newKeys) end
			end
		end)
	end
	for themeName, button in pairs(themeButtons) do
		button.TextColor3 = themeName == name and C.bgBot or C.ink
		button.BackgroundColor3 = themeName == name and C.accent or C.glassTop
	end
	notify("Theme changed: " .. name, "info")
end
for i, name in ipairs(themeNames) do
	local b = Instance.new("TextButton")
	b.Name = name .. "Theme"
	b.Position = UDim2.new(((i-1)%2) * 0.5, ((i-1)%2 == 0) and 12 or 6, 0, 12 + math.floor((i-1)/2)*38)
	b.Size = UDim2.new(0.5, -18, 0, 30)
	b.BackgroundColor3 = name == "Aqua" and C.accent or C.glassTop
	b.Text = name
	b.TextColor3 = name == "Aqua" and C.bgBot or C.ink
	b.TextSize = 12
	b.Font = Enum.Font.GothamBold
	b.AutoButtonColor = false
	b.Parent = themeCard
	corner(b, 8)
	stroke(b, themeColors[name][1], 1, 0.4)
	themeButtons[name] = b
	b.Activated:Connect(function() applyTheme(name) end)
end

local resetCard = card(44)
local resetPositionButton = Instance.new("TextButton")
resetPositionButton.Name = "ResetWindowPosition"
resetPositionButton.Position = UDim2.new(0, 10, 0, 6)
resetPositionButton.Size = UDim2.new(1, -20, 0, 32)
resetPositionButton.BackgroundColor3 = C.bgTop
resetPositionButton.BorderSizePixel = 0
resetPositionButton.Text = "RESET WINDOW POSITION"
resetPositionButton.TextColor3 = C.ink
resetPositionButton.TextSize = 11
resetPositionButton.Font = Enum.Font.GothamBold
resetPositionButton.AutoButtonColor = false
resetPositionButton.Parent = resetCard
corner(resetPositionButton, 8)
stroke(resetPositionButton, C.accent, 1, 0.65)
resetPositionButton.Activated:Connect(function()
    win.Position = UDim2.new(0.5, -win.AbsoluteSize.X / 2, 0.5, -win.AbsoluteSize.Y / 2)
    if miniIcon.Visible then
        miniIcon.Position = UDim2.new(1, -72, 0.5, -27)
    end
    notify("Window position reset", "info")
end)

body = pages.Home
sectionLabel("Session Stats")
local coinStat = statRow("Coins collected", 0)
local timeStat = statRow("Time active", "0m 0s")
local sessionResetCard = card(44)
local sessionResetButton = Instance.new("TextButton")
sessionResetButton.Name = "ResetSessionStats"
sessionResetButton.Position = UDim2.new(0, 10, 0, 6)
sessionResetButton.Size = UDim2.new(1, -20, 0, 32)
sessionResetButton.BackgroundColor3 = C.bgTop
sessionResetButton.BorderSizePixel = 0
sessionResetButton.Text = "RESET SESSION STATS"
sessionResetButton.TextColor3 = C.ink
sessionResetButton.TextSize = 11
sessionResetButton.Font = Enum.Font.GothamBold
sessionResetButton.AutoButtonColor = false
sessionResetButton.Parent = sessionResetCard
corner(sessionResetButton, 8)
stroke(sessionResetButton, C.accent, 1, 0.65)
sessionResetButton.Activated:Connect(function()
	stats.coins = 0
	stats.started = os.clock()
	coinStat.Text = "0"
	timeStat.Text = "0m 0s"
	notify("Session statistics reset", "info")
end)

body = pages.About
sectionLabel("Project & Credits")
local creditsCard = card(190)

local function creditLine(text, y, color, size, font)
	local label = Instance.new("TextLabel")
	label.Position = UDim2.new(0, 12, 0, y)
	label.Size = UDim2.new(1, -24, 0, 18)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or C.ink
	label.TextSize = size or 12
	label.Font = font or Enum.Font.GothamMedium
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = creditsCard
	return label
end

creditLine("DEVELOPER  /  Wacx", 8, C.ink, 13, Enum.Font.GothamBold)
creditLine("Discord  /  W1acx", 31, C.inkSoft, 12, Enum.Font.GothamMedium)
creditLine("Community  /  discord.gg/7y3JUQ7kYP", 52, C.inkSoft, 11, Enum.Font.Gotham)
creditLine("OPEN SOURCE PROJECT  /  " .. VERSION, 75, Color3.fromRGB(116, 238, 190), 11, Enum.Font.GothamBold)
creditLine("Source review recommended before running", 94, C.inkSoft, 10, Enum.Font.Gotham)

local githubButton = Instance.new("TextButton")
githubButton.Name = "GitHubLink"
githubButton.Position = UDim2.new(0, 12, 0, 118)
githubButton.Size = UDim2.new(1, -24, 0, 30)
githubButton.BackgroundColor3 = C.bgTop
githubButton.BorderSizePixel = 0
githubButton.Text = "OPEN GITHUB SOURCE  /  COPY LINK"
githubButton.TextColor3 = C.accent
githubButton.TextSize = 11
githubButton.Font = Enum.Font.GothamSemibold
githubButton.AutoButtonColor = true
githubButton.Parent = creditsCard
corner(githubButton, 8)
stroke(githubButton, C.accent, 1, 0.65)

githubButton.Activated:Connect(function()
    local url = "https://github.com/WacxScripts/By-Wacx/blob/main/MM2-Auto-Farm-Wacx-Open-Source.lua"
    local copied = false
    if typeof(setclipboard) == "function" then
        copied = pcall(setclipboard, url)
    end
    if copied then
        githubButton.Text = "GitHub link copied!"
        notify("GitHub source link copied", "info")
    else
        githubButton.Text = url
        notify("Clipboard unavailable — GitHub URL shown on the button", "error", 3.5)
        task.delay(4, function()
            if githubButton and githubButton.Parent then
                githubButton.Text = "OPEN GITHUB SOURCE  /  COPY LINK"
            end
        end)
    end
end)

local discordButton = Instance.new("TextButton")
discordButton.Name = "DiscordCommunity"
discordButton.Position = UDim2.new(0, 12, 0, 154)
discordButton.Size = UDim2.new(1, -24, 0, 28)
discordButton.BackgroundColor3 = C.bgTop
discordButton.BorderSizePixel = 0
discordButton.Text = "DISCORD COMMUNITY  /  COPY INVITE"
discordButton.TextColor3 = C.ink
discordButton.TextSize = 11
discordButton.Font = Enum.Font.GothamSemibold
discordButton.AutoButtonColor = true
discordButton.Parent = creditsCard
corner(discordButton, 8)
stroke(discordButton, C.inkSoft, 1, 0.75)
discordButton.Activated:Connect(function()
	local invite = "https://discord.gg/7y3JUQ7kYP"
	local copied = false
	if typeof(setclipboard) == "function" then copied = pcall(setclipboard, invite) end
	if copied then
		discordButton.Text = "Discord invite copied!"
	else
		discordButton.Text = invite
	end
	notify(copied and "Discord invite copied" or "Clipboard unsupported; invite shown in button", "info")
	task.delay(2.5, function()
		if discordButton and discordButton.Parent then discordButton.Text = "DISCORD COMMUNITY  /  COPY INVITE" end
	end)
end)

local function makeDraggable(frame, handle)
	local dragging = false
	local activeInput = nil
	local dragInputType = nil
	local startPointer = nil
	local startFrame = nil

	local function stopDragging(input)
		if not dragging then return end
		if input == nil
			or input == activeInput
			or (dragInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1) then
			dragging = false
			activeInput = nil
			dragInputType = nil
			startPointer = nil
			startFrame = nil
		end
	end

	handle.InputBegan:Connect(function(input)
		local inputType = input.UserInputType
		if inputType ~= Enum.UserInputType.MouseButton1 and inputType ~= Enum.UserInputType.Touch then
			return
		end
		if dragging then return end

		dragging = true
		activeInput = input
		dragInputType = inputType
		startPointer = Vector2.new(input.Position.X, input.Position.Y)
		startFrame = frame.AbsolutePosition

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				stopDragging(input)
			end
		end)
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging or not startPointer or not startFrame then return end

		local isMouseMove = dragInputType == Enum.UserInputType.MouseButton1
			and input.UserInputType == Enum.UserInputType.MouseMovement
		local isActiveTouch = dragInputType == Enum.UserInputType.Touch
			and input.UserInputType == Enum.UserInputType.Touch
			and input == activeInput
		if not isMouseMove and not isActiveTouch then return end

		local pointer = Vector2.new(input.Position.X, input.Position.Y)
		local delta = pointer - startPointer
		local view = camera and camera.ViewportSize or Vector2.new(1280, 720)
		local maxX = math.max(0, view.X - frame.AbsoluteSize.X)
		local maxY = math.max(0, view.Y - frame.AbsoluteSize.Y)
		local targetX = math.clamp(startFrame.X + delta.X, 0, maxX)
		local targetY = math.clamp(startFrame.Y + delta.Y, 0, maxY)
		frame.Position = UDim2.fromOffset(targetX, targetY)
	end)

	UserInputService.InputEnded:Connect(function(input)
		if dragging then
			if input == activeInput
				or (dragInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1) then
				stopDragging(input)
			end
		end
	end)
end
makeDraggable(win, header)

local collapsed = false
local expandedH = WIN_H
if camera then
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		local v = camera.ViewportSize
        toastLayer.Size = UDim2.new(0, math.clamp(v.X * 0.88, 240, 320), 0, 180)
		local mobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
		local minW = math.min(mobile and 290 or 340, math.max(220, v.X - 20))
		local maxW = math.max(minW, math.min(mobile and 430 or 470, v.X - 20))
		local minH = math.min(mobile and 300 or 360, math.max(240, v.Y - 20))
		local maxH = math.max(minH, math.min(610, v.Y - 20))
		local w = math.floor(math.clamp(v.X * (mobile and 0.92 or 0.36), minW, maxW))
		local h = math.floor(math.clamp(v.Y * (mobile and 0.78 or 0.72), minH, maxH))
		win.Size = UDim2.new(0, w, 0, h)
		win.Position = UDim2.new(0, math.max(10, (v.X - w) / 2), 0, math.max(10, (v.Y - h) / 2))
		expandedH = h
		miniIcon.Position = UDim2.new(0, math.max(8, v.X - 68), 0, math.max(8, (v.Y - 54) / 2))
	end)
end


local grip = Instance.new("TextButton")
grip.Name = "Grip"
grip.AnchorPoint = Vector2.new(1, 1)
grip.Position = UDim2.new(1, -4, 1, -4)
grip.Size = UDim2.new(0, 16, 0, 16)
grip.BackgroundColor3 = C.card
grip.BackgroundTransparency = 0.25
grip.Text = "⟋"
grip.TextColor3 = C.accent
grip.TextSize = 12
grip.Font = Enum.Font.GothamBold
grip.AutoButtonColor = false
grip.ZIndex = 5
grip.Parent = win
corner(grip, 5)
stroke(grip, C.accent, 1, 0.6)
addPop(grip, 0.85)

local MIN_W, MIN_H = IS_MOBILE and 270 or 280, IS_MOBILE and 300 or 360
local MAX_W, MAX_H = 520, 650
local resizing = false

grip.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		resizing = true
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if not resizing or collapsed then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
		local view = camera and camera.ViewportSize or Vector2.new(1280, 720)
		local maxW = math.max(math.min(MIN_W, view.X - 16), math.min(MAX_W, view.X - win.AbsolutePosition.X - 8))
		local maxH = math.max(math.min(MIN_H, view.Y - 16), math.min(MAX_H, view.Y - win.AbsolutePosition.Y - 8))
		local newW = math.clamp(input.Position.X - win.AbsolutePosition.X, math.min(MIN_W, maxW), maxW)
		local newH = math.clamp(input.Position.Y - win.AbsolutePosition.Y, math.min(MIN_H, maxH), maxH)
		expandedH = newH
		win.Size = UDim2.new(0, newW, 0, newH)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		resizing = false
	end
end)

local HEADER_H = 62
local barTween = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

minBtn.Activated:Connect(function()
	collapsed = not collapsed
	grip.Visible = not collapsed
	minBtn.Text = collapsed and "+" or "–"
	local targetH = collapsed and HEADER_H or expandedH
	TweenService:Create(win, barTween, {
		Size = UDim2.new(0, win.Size.X.Offset, 0, targetH),
	}):Play()
end)

local miniMode = false
miniBtn.Activated:Connect(function()
	miniMode = true
	win.Visible = false
	shadow.Visible = false
	miniIcon.Visible = true
	notify("Mini Mode enabled — tap W to reopen", "info")
end)
miniIcon.Activated:Connect(function()
	miniMode = false
	miniIcon.Visible = false
	win.Visible = true
	shadow.Visible = true
	notify("Wacx menu restored", "info")
end)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed or UserInputService.TouchEnabled then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if win.Visible then
            win.Visible = false
            shadow.Visible = false
            miniIcon.Visible = true
            miniMode = true
        else
            win.Visible = true
            shadow.Visible = true
            miniIcon.Visible = false
            miniMode = false
        end
    end
end)
makeDraggable(miniIcon, miniIcon)

local popIn = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
win.Size = UDim2.new(0, WIN_W, 0, 0)
TweenService:Create(win, popIn, { Size = UDim2.new(0, WIN_W, 0, WIN_H) }):Play()

LocalPlayer.Idled:Connect(function()
	if cfg.antiAFK then
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end
end)

local function character()
	return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end
local function root()
	return character():WaitForChild("HumanoidRootPart")
end

local roundActive = false

do
	local gp = ReplicatedStorage:FindFirstChild("Remotes")
	gp = gp and gp:FindFirstChild("Gameplay")
	if gp then
		local coinEv  = gp:FindFirstChild("CoinCollected")
		local startEv = gp:FindFirstChild("RoundStart")
		local endEv   = gp:FindFirstChild("RoundEndFade")

		if coinEv then
			coinEv.OnClientEvent:Connect(function(_, current)
				if typeof(current) == "number" then
					stats.coins = current
					coinStat.Text = tostring(current)
				else
					stats.coins += 1
					coinStat.Text = tostring(stats.coins)
				end
			end)
		end
		if startEv then
			startEv.OnClientEvent:Connect(function()
				roundActive = true
				notify("Round started", "info", 2)
			end)
		end
		if endEv then
			endEv.OnClientEvent:Connect(function()
				roundActive = false
				notify("Round ended", "info", 2)
			end)
		end
	end
end

local function nearestCoin()
	local hrp = root()
	local best, bestDist = nil, math.huge
	for _, m in ipairs(workspace:GetChildren()) do
		local container = m:FindFirstChild("CoinContainer")
		if container then
			for _, coin in ipairs(container:GetChildren()) do
				if coin:IsA("BasePart") and coin:FindFirstChild("TouchInterest") then
					local d = (hrp.Position - coin.Position).Magnitude
					if d < bestDist then
						best, bestDist = coin, d
					end
				end
			end
		end
	end
	return best, bestDist
end

local lastFarmError = nil
task.spawn(function()
	while true do
		local ok, err = pcall(function()
			if cfg.autoFarm and roundActive then
				local coin, dist = nearestCoin()
				if coin then
					local hrp = root()
					local t = TweenService:Create(
						hrp,
						TweenInfo.new(dist / math.max(cfg.farmSpeed, 1), Enum.EasingStyle.Linear),
						{ CFrame = coin.CFrame }
					)
					local travelTimeout = math.max(4, dist / math.max(cfg.farmSpeed, 1) + 3)
					local travelStarted = os.clock()
					t:Play()
					repeat task.wait(0.1)
					until not coin.Parent
						or not coin:FindFirstChild("TouchInterest")
						or not roundActive
						or not cfg.autoFarm
						or os.clock() - travelStarted >= travelTimeout
					t:Cancel()
				end
			end
		end)
		if not ok then
			local message = tostring(err)
			if message ~= lastFarmError then
				notify("Auto Farm error: " .. string.sub(message, 1, 90), "error", 4)
				lastFarmError = message
			end
		else
			lastFarmError = nil
		end
		task.wait(cfg.loopDelay)
	end
end)

task.spawn(function()
	while true do
		local secs = math.floor(os.clock() - stats.started)
		timeStat.Text = string.format("%dm %ds", math.floor(secs / 60), secs % 60)
		if not roundActive then
			liveStatus.Text = "Round: Waiting for round state"
            statusDot.BackgroundColor3 = cfg.autoFarm and C.accent or C.inkSoft
		elseif cfg.autoFarm then
			liveStatus.Text = "Round: Active  •  Auto Farm running"
            statusDot.BackgroundColor3 = Color3.fromRGB(120, 255, 90)
		else
			liveStatus.Text = "Round: Active  •  Auto Farm paused"
            statusDot.BackgroundColor3 = Color3.fromRGB(255, 190, 90)
		end
		task.wait(1)
	end
end)

notify("Wacx MM2 Open Source " .. VERSION .. " loaded", "info", 3.5)
