local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local VirtualUser        = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

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
	bgTop    = Color3.fromRGB(18, 22, 42),
	bgBot    = Color3.fromRGB(8, 10, 20),
	card     = Color3.fromRGB(12, 16, 30),
	glass    = Color3.fromRGB(23, 29, 49),
	glassTop = Color3.fromRGB(36, 46, 72),
	accent   = Color3.fromRGB(89, 210, 255),
	accent2  = Color3.fromRGB(172, 245, 255),
	trackOff = Color3.fromRGB(47, 63, 86),
	ink      = Color3.fromRGB(241, 249, 255),
	inkSoft  = Color3.fromRGB(151, 173, 198),
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

local WIN_W, WIN_H = 360, 470

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
titleWrap.Size = UDim2.new(1, -118, 1, 0)
titleWrap.Position = UDim2.new(0, 60, 0, 0)
titleWrap.BackgroundTransparency = 1
titleWrap.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 22)
title.Position = UDim2.new(0, 0, 0, 8)
title.BackgroundTransparency = 1
title.Text = "Wacx MM2 Autofarm"
title.TextColor3 = C.ink
title.TextSize = 18
title.Font = Enum.Font.GothamBlack
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleWrap
gradient(title, Color3.fromRGB(235, 220, 255), Color3.fromRGB(168, 112, 255), 90)

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
subtitle.Text = "MM2  /  AUTOFARM  /  OPEN SOURCE"
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

local body = Instance.new("ScrollingFrame")
body.Name = "Body"
body.Active = true
body.Position = UDim2.new(0, 0, 0, 62)
body.Size = UDim2.new(1, 0, 1, -62)
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.ScrollBarThickness = 3
body.ScrollBarImageColor3 = C.accent
body.ScrollBarImageTransparency = 0.55
body.CanvasSize = UDim2.new(0, 0, 0, 0)
body.Parent = win
pad(body, 12)

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 11)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = body

list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	body.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 24)
end)

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
	track.MouseButton1Click:Connect(function()
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

sectionLabel("Harvest")
toggle("Auto Farm", "harvest every coin on the map", cfg.autoFarm, function(s)
	cfg.autoFarm = s
	overviewStatus.Text = s and "Status: Enabled" or "Status: Idle"
	overviewStatus.TextColor3 = s and Color3.fromRGB(142, 255, 178) or C.inkSoft
	TweenService:Create(statusDot, TweenInfo.new(0.2), {
		BackgroundColor3 = s and Color3.fromRGB(120, 255, 90) or C.inkSoft,
	}):Play()
end)
slider("Farm Speed", 5, 120, cfg.farmSpeed, "", function(v)
	cfg.farmSpeed = v
end)

sectionLabel("Utility")
toggle("Anti AFK", "no ghosting out of the server", cfg.antiAFK, function(s)
	cfg.antiAFK = s
end)

sectionLabel("Session")
local coinStat = statRow("Coins collected", 0)
local timeStat = statRow("Time active", "0m 0s")

sectionLabel("Credits")
local creditsCard = card(150)

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
creditLine("OPEN SOURCE PROJECT", 75, Color3.fromRGB(116, 238, 190), 11, Enum.Font.GothamBold)

local githubButton = Instance.new("TextButton")
githubButton.Name = "GitHubLink"
githubButton.Position = UDim2.new(0, 12, 0, 101)
githubButton.Size = UDim2.new(1, -24, 0, 32)
githubButton.BackgroundColor3 = C.bgTop
githubButton.BorderSizePixel = 0
githubButton.Text = "GitHub  /  Click to copy link"
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
    else
        githubButton.Text = "Copy not supported in this executor"
        task.delay(2.5, function()
            if githubButton and githubButton.Parent then
                githubButton.Text = "GitHub  /  Click to copy link"
            end
        end)
    end
end)

local function makeDraggable(frame, handle)
	local dragging, startPos, startInput
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startPos = frame.Position
			startInput = input.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - startInput
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end
makeDraggable(win, header)

local collapsed = false
local expandedH = WIN_H

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

local MIN_W, MIN_H = 250, 210
local MAX_W, MAX_H = 480, 560
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
		local newW = math.clamp(input.Position.X - win.AbsolutePosition.X, MIN_W, MAX_W)
		local newH = math.clamp(input.Position.Y - win.AbsolutePosition.Y, MIN_H, MAX_H)
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

minBtn.MouseButton1Click:Connect(function()
	collapsed = not collapsed
	grip.Visible = not collapsed
	minBtn.Text = collapsed and "+" or "–"
	local targetH = collapsed and HEADER_H or expandedH
	TweenService:Create(win, barTween, {
		Size = UDim2.new(0, win.Size.X.Offset, 0, targetH),
	}):Play()
end)

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
			startEv.OnClientEvent:Connect(function() roundActive = true end)
		end
		if endEv then
			endEv.OnClientEvent:Connect(function() roundActive = false end)
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

task.spawn(function()
	while true do
		if cfg.autoFarm and roundActive then
			local coin, dist = nearestCoin()
			if coin then
				local hrp = root()
				local t = TweenService:Create(
					hrp,
					TweenInfo.new(dist / math.max(cfg.farmSpeed, 1), Enum.EasingStyle.Linear),
					{ CFrame = coin.CFrame }
				)
				t:Play()
				repeat task.wait()
				until not coin:FindFirstChild("TouchInterest")
					or not roundActive
					or not cfg.autoFarm
				t:Cancel()
			end
		end
		task.wait(cfg.loopDelay)
	end
end)

task.spawn(function()
	while true do
		local secs = math.floor(os.clock() - stats.started)
		timeStat.Text = string.format("%dm %ds", math.floor(secs / 60), secs % 60)
		task.wait(1)
	end
end)
