--// ========================
--// WetHub UI Library (FIXED + CONFIG-READY HANDLES)
--// - NO FILE FUNCTIONS (safe on executors with no writefile/readfile)
--// - Adds handles: Toggle/Slider/Dropdown/ColourPicker -> Get/Set/Destroy
--// - Adds ProfileBar (avatar + welcome) under tabs
--// - Fixes: ColourPicker order, Search empty restore, Tab matching, collapse hiding ProfileBar
--// - Includes Notify() (UIListLayout-safe slide)
--// ========================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGuiService = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local TweenTime = 0.1
local GlobalTweenInfo = TweenInfo.new(TweenTime)

local DropShadowID = "rbxassetid://297774371"
local DropShadowTransparency = 0.3

local IconLibraryID  = "rbxassetid://3926305904"
local IconLibraryID2 = "rbxassetid://3926307971"

local MainFont = Enum.Font.Gotham

--// ===== helpers =====
local function clamp(n, a, b)
	n = tonumber(n) or 0
	if n < a then return a end
	if n > b then return b end
	return n
end

local function GetXY(GuiObject)
	local X = Mouse.X - GuiObject.AbsolutePosition.X
	local Y = Mouse.Y - GuiObject.AbsolutePosition.Y
	local MaxX = GuiObject.AbsoluteSize.X
	local MaxY = GuiObject.AbsoluteSize.Y
	X, Y = math.clamp(X, 0, MaxX), math.clamp(Y, 0, MaxY)
	return X, Y, (MaxX == 0 and 0 or (X / MaxX)), (MaxY == 0 and 0 or (Y / MaxY))
end

local function Tween(obj, props)
	local tw = TweenService:Create(obj, GlobalTweenInfo, props)
	tw:Play()
	return tw
end

--// ===== UI factories =====
local function TitleIcon(isButton)
	local ico = Instance.new(isButton and "ImageButton" or "ImageLabel")
	ico.Name = "TitleIcon"
	ico.BackgroundTransparency = 1
	ico.Image = IconLibraryID
	ico.ImageRectOffset = Vector2.new(524, 764)
	ico.ImageRectSize = Vector2.new(36, 36)
	ico.Size = UDim2.new(0, 14, 0, 14)
	ico.Position = UDim2.new(1, -17, 0, 3)
	ico.Rotation = 180
	return ico
end

local function TickIcon(isButton)
	local ico = Instance.new(isButton and "ImageButton" or "ImageLabel")
	ico.Name = "TickIcon"
	ico.BackgroundTransparency = 1
	ico.Image = "rbxassetid://3926305904"
	ico.ImageRectOffset = Vector2.new(312, 4)
	ico.ImageRectSize = Vector2.new(24, 24)
	ico.Size = UDim2.new(1, -6, 1, -6)
	ico.Position = UDim2.new(0, 3, 0, 3)
	return ico
end

local function DropdownIcon(isButton)
	local ico = Instance.new(isButton and "ImageButton" or "ImageLabel")
	ico.Name = "DropdownIcon"
	ico.BackgroundTransparency = 1
	ico.Image = IconLibraryID2
	ico.ImageRectOffset = Vector2.new(324, 364)
	ico.ImageRectSize = Vector2.new(36, 36)
	ico.Size = UDim2.new(0, 16, 0, 16)
	ico.Position = UDim2.new(1, -18, 0, 2)
	return ico
end

local function SearchIcon(isButton)
	local ico = Instance.new(isButton and "ImageButton" or "ImageLabel")
	ico.Name = "SearchIcon"
	ico.BackgroundTransparency = 1
	ico.Image = IconLibraryID
	ico.ImageRectOffset = Vector2.new(964, 324)
	ico.ImageRectSize = Vector2.new(36, 36)
	ico.Size = UDim2.new(0, 16, 0, 16)
	ico.Position = UDim2.new(0, 2, 0, 2)
	return ico
end

local function RoundBox(cornerRadius, isButton)
	local img = Instance.new(isButton and "ImageButton" or "ImageLabel")
	img.BackgroundTransparency = 1
	img.Image = "rbxassetid://3570695787"
	img.SliceCenter = Rect.new(100, 100, 100, 100)
	img.SliceScale = math.clamp((cornerRadius or 5) * 0.01, 0.01, 1)
	img.ScaleType = Enum.ScaleType.Slice
	return img
end

local function DropShadow()
	local sh = Instance.new("ImageLabel")
	sh.Name = "DropShadow"
	sh.BackgroundTransparency = 1
	sh.Image = DropShadowID
	sh.ImageTransparency = DropShadowTransparency
	sh.Size = UDim2.new(1, 0, 1, 0)
	return sh
end

local function Frame()
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	return f
end

local function ScrollingFrame()
	local sf = Instance.new("ScrollingFrame")
	sf.BackgroundTransparency = 1
	sf.BorderSizePixel = 0
	sf.ScrollBarThickness = 0
	return sf
end

local function TextButton(text, size)
	local b = Instance.new("TextButton")
	b.Text = tostring(text or "")
	b.AutoButtonColor = false
	b.Font = MainFont
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.BackgroundTransparency = 1
	b.TextSize = size or 12
	b.Size = UDim2.new(1, 0, 1, 0)
	return b
end

local function TextBox(text, size)
	local t = Instance.new("TextBox")
	t.Text = tostring(text or "")
	t.Font = MainFont
	t.TextColor3 = Color3.fromRGB(255, 255, 255)
	t.BackgroundTransparency = 1
	t.TextSize = size or 12
	t.Size = UDim2.new(1, 0, 1, 0)
	return t
end

local function TextLabel(text, size)
	local l = Instance.new("TextLabel")
	l.Text = tostring(text or "")
	l.Font = MainFont
	l.TextColor3 = Color3.fromRGB(255, 255, 255)
	l.BackgroundTransparency = 1
	l.TextSize = size or 12
	l.Size = UDim2.new(1, 0, 1, 0)
	return l
end

--// ============================================================
--// UILibrary
--// ============================================================
local UILibrary = {}

function UILibrary.Load(GUITitle)
	GUITitle = tostring(GUITitle or "WetHub")

	local TargetedParent = RunService:IsStudio() and Player:WaitForChild("PlayerGui") or CoreGuiService

	local old = TargetedParent:FindFirstChild(GUITitle)
	if old then old:Destroy() end

	-- Root GUI
	local NewInstance = Instance.new("ScreenGui")
	NewInstance.Name = GUITitle
	NewInstance.ResetOnSpawn = false
	NewInstance.IgnoreGuiInset = false
	NewInstance.Parent = TargetedParent

	-- Container
	local ContainerFrame = Frame()
	ContainerFrame.Name = "ContainerFrame"
	ContainerFrame.Size = UDim2.new(0, 500, 0, 300)
	ContainerFrame.Position = UDim2.new(0.5, -250, 0.5, -150)
	ContainerFrame.BackgroundTransparency = 1
	ContainerFrame.Parent = NewInstance

	local ContainerShadow = DropShadow()
	ContainerShadow.Name = "Shadow"
	ContainerShadow.Parent = ContainerFrame

	-- Main frame
	local MainFrame = RoundBox(5)
	MainFrame.Name = "MainFrame"
	MainFrame.ClipsDescendants = true
	MainFrame.Size = UDim2.new(1, -50, 1, -30)
	MainFrame.Position = UDim2.new(0, 25, 0, 15)
	MainFrame.ImageColor3 = Color3.fromRGB(30, 30, 30)
	MainFrame.Parent = ContainerFrame

	-- Title bar
	local TitleBar = RoundBox(5)
	TitleBar.Name = "TitleBar"
	TitleBar.ImageColor3 = Color3.fromRGB(40, 40, 40)
	TitleBar.Size = UDim2.new(1, -10, 0, 20)
	TitleBar.Position = UDim2.new(0, 5, 0, 5)
	TitleBar.Parent = MainFrame

	-- Menu + Display
	local MenuBar = ScrollingFrame()
	MenuBar.Name = "MenuBar"
	MenuBar.BackgroundTransparency = 0.7
	MenuBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	MenuBar.Position = UDim2.new(0, 5, 0, 30)
	MenuBar.Size = UDim2.new(0, 100, 0, 235)
	MenuBar.CanvasSize = UDim2.new(0, 0, 0, 0)
	MenuBar.Parent = MainFrame

	local DisplayFrame = RoundBox(5)
	DisplayFrame.Name = "Display"
	DisplayFrame.ImageColor3 = Color3.fromRGB(20, 20, 20)
	DisplayFrame.Position = UDim2.new(0, 110, 0, 30)
	DisplayFrame.Size = UDim2.new(1, -115, 0, 235)
	DisplayFrame.Parent = MainFrame

	-- Profile bar under tabs
	local ProfileBarHeight = 40
	local ProfileBarPadding = 5

	MenuBar.Size = UDim2.new(0, 100, 0, 235 - ProfileBarHeight - ProfileBarPadding)

	local ProfileBar = RoundBox(5)
	ProfileBar.Name = "ProfileBar"
	ProfileBar.ImageColor3 = Color3.fromRGB(40, 40, 40)
	ProfileBar.Size = UDim2.new(0, 100, 0, ProfileBarHeight)
	ProfileBar.Position = UDim2.new(0, 5, 1, -(ProfileBarHeight + ProfileBarPadding))
	ProfileBar.Parent = MainFrame
	ProfileBar.ClipsDescendants = true

	local Avatar = Instance.new("ImageLabel")
	Avatar.Name = "Avatar"
	Avatar.BackgroundTransparency = 1
	Avatar.Size = UDim2.new(0, 28, 0, 28)
	Avatar.Position = UDim2.new(0, 6, 0.5, -14)
	Avatar.Parent = ProfileBar

	local AvatarCorner = Instance.new("UICorner")
	AvatarCorner.CornerRadius = UDim.new(1, 0)
	AvatarCorner.Parent = Avatar

	local Welcome = Instance.new("TextLabel")
	Welcome.Name = "Welcome"
	Welcome.BackgroundTransparency = 1
	Welcome.TextXAlignment = Enum.TextXAlignment.Left
	Welcome.TextYAlignment = Enum.TextYAlignment.Center
	Welcome.Font = MainFont
	Welcome.TextSize = 11
	Welcome.TextColor3 = Color3.fromRGB(255, 255, 255)
	Welcome.TextTransparency = 0.15
	Welcome.TextWrapped = true
	Welcome.Size = UDim2.new(1, -40, 1, 0)
	Welcome.Position = UDim2.new(0, 36, 0, 0)
	Welcome.Parent = ProfileBar

	local shownName = (Player.DisplayName and Player.DisplayName ~= "" and Player.DisplayName) or Player.Name
	Welcome.Text = "Welcome,\n" .. shownName .. "!"

	task.spawn(function()
		local ok, content = pcall(function()
			return Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		end)
		if ok and content and content ~= "" then
			Avatar.Image = content
		else
			Avatar.Image = ("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(Player.UserId)
		end
	end)

	-- Title controls
	local MinimiseButton = TitleIcon(true)
	MinimiseButton.Name = "Minimise"
	MinimiseButton.Parent = TitleBar

	local TitleButton = TextButton(GUITitle, 14)
	TitleButton.Name = "TitleButton"
	TitleButton.Position = UDim2.new(0, 24, 0, 0)
	TitleButton.Size = UDim2.new(1, -44, 1, 0)
	TitleButton.Parent = TitleBar

	-- Dragging
	TitleButton.MouseButton1Down:Connect(function()
		local LastMX, LastMY = Mouse.X, Mouse.Y
		local MoveConn, EndConn

		MoveConn = Mouse.Move:Connect(function()
			local NewMX, NewMY = Mouse.X, Mouse.Y
			local DX, DY = NewMX - LastMX, NewMY - LastMY
			ContainerFrame.Position += UDim2.new(0, DX, 0, DY)
			LastMX, LastMY = NewMX, NewMY
		end)

		EndConn = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				if MoveConn then MoveConn:Disconnect() end
				if EndConn then EndConn:Disconnect() end
			end
		end)
	end)

	-- Collapse behavior
	local MinimiseToggle = true
	local function applyCollapsedState()
		if not MinimiseToggle then
			-- collapsed
			Tween(MainFrame, {Size = UDim2.new(1, -50, 0, 30)})
			Tween(MinimiseButton, {Rotation = 0})
			Tween(ContainerShadow, {ImageTransparency = 1})

			-- hard-hide everything that could peek (your avatar issue)
			MenuBar.Visible = false
			DisplayFrame.Visible = false
			ProfileBar.Visible = false
		else
			-- expanded
			Tween(MainFrame, {Size = UDim2.new(1, -50, 1, -30)})
			Tween(MinimiseButton, {Rotation = 180})
			Tween(ContainerShadow, {ImageTransparency = DropShadowTransparency})

			MenuBar.Visible = true
			DisplayFrame.Visible = true
			ProfileBar.Visible = true
		end
	end

	MinimiseButton.MouseButton1Down:Connect(function()
		MinimiseToggle = not MinimiseToggle
		applyCollapsedState()
	end)

	-- Menu layout
	local MenuListLayout = Instance.new("UIListLayout")
	MenuListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	MenuListLayout.Padding = UDim.new(0, 5)
	MenuListLayout.Parent = MenuBar

	-- Tabs
	local TabCount = 0
	local TabLibrary = {}

	local function setActiveTab(tabNameLower)
		-- Menu highlighting
		for _, Button in ipairs(MenuBar:GetChildren()) do
			if Button:IsA("GuiObject") then
				local isThis = (Button.Name:lower() == tabNameLower)
				local inner = Button:FindFirstChild(Button.Name .. "Button")
				Tween(Button, {ImageColor3 = isThis and Color3.fromRGB(50, 50, 50) or Color3.fromRGB(40, 40, 40)})
				if inner and inner:IsA("TextButton") then
					Tween(inner, {TextTransparency = isThis and 0 or 0.5})
				end
			end
		end

		-- Page visibility
		for _, Display in ipairs(DisplayFrame:GetChildren()) do
			if Display:IsA("GuiObject") then
				Display.Visible = (Display.Name:lower() == tabNameLower)
			end
		end
	end

	function TabLibrary.AddPage(PageTitle, SearchBarIncluded)
		PageTitle = tostring(PageTitle or ("Page" .. tostring(TabCount + 1)))
		SearchBarIncluded = (SearchBarIncluded == nil) and true or (SearchBarIncluded == true)

		local PageContainer = RoundBox(5)
		PageContainer.Name = PageTitle
		PageContainer.Size = UDim2.new(1, 0, 0, 20)
		PageContainer.LayoutOrder = TabCount
		PageContainer.ImageColor3 = (TabCount == 0) and Color3.fromRGB(50, 50, 50) or Color3.fromRGB(40, 40, 40)
		PageContainer.Parent = MenuBar

		local PageButton = TextButton(PageTitle, 14)
		PageButton.Name = PageTitle .. "Button"
		PageButton.TextTransparency = (TabCount == 0) and 0 or 0.5
		PageButton.Parent = PageContainer

		PageButton.MouseButton1Down:Connect(function()
			setActiveTab(PageContainer.Name:lower())
		end)

		local DisplayPage = ScrollingFrame()
		DisplayPage.Visible = (TabCount == 0)
		DisplayPage.Name = PageTitle
		DisplayPage.Size = UDim2.new(1, 0, 1, 0)
		DisplayPage.Parent = DisplayFrame

		TabCount += 1

		local DisplayList = Instance.new("UIListLayout")
		DisplayList.SortOrder = Enum.SortOrder.LayoutOrder
		DisplayList.Padding = UDim.new(0, 5)
		DisplayList.Parent = DisplayPage

		DisplayList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			local Y1 = DisplayList.AbsoluteContentSize.Y
			local Y2 = DisplayPage.AbsoluteWindowSize.Y
			if Y2 <= 0 then
				DisplayPage.CanvasSize = UDim2.new(0, 0, 0, 0)
				return
			end
			DisplayPage.CanvasSize = UDim2.new(0, 0, (Y1 / Y2) + 0.05, 0)
		end)

		local DisplayPadding = Instance.new("UIPadding")
		DisplayPadding.PaddingBottom = UDim.new(0, 5)
		DisplayPadding.PaddingTop = UDim.new(0, 5)
		DisplayPadding.PaddingLeft = UDim.new(0, 5)
		DisplayPadding.PaddingRight = UDim.new(0, 5)
		DisplayPadding.Parent = DisplayPage

		-- PageLibrary (controls)
		local PageLibrary = {}

		function PageLibrary.AddButton(Text, Callback, Parent, Underline)
			Text = tostring(Text or "Button")
			local ButtonContainer = Frame()
			ButtonContainer.Name = Text .. "BUTTON"
			ButtonContainer.Size = UDim2.new(1, 0, 0, 20)
			ButtonContainer.BackgroundTransparency = 1
			ButtonContainer.Parent = Parent or DisplayPage

			local ButtonForeground = RoundBox(5)
			ButtonForeground.Name = "ButtonForeground"
			ButtonForeground.Size = UDim2.new(1, 0, 1, 0)
			ButtonForeground.ImageColor3 = Color3.fromRGB(35, 35, 35)
			ButtonForeground.Parent = ButtonContainer

			if Underline then
				local ts = TextService:GetTextSize(Text, 12, Enum.Font.Gotham, Vector2.new(0, 0))
				local BottomEffect = Frame()
				BottomEffect.Size = UDim2.new(0, ts.X, 0, 1)
				BottomEffect.Position = UDim2.new(0.5, (-ts.X / 2) - 1, 1, -1)
				BottomEffect.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				BottomEffect.BackgroundTransparency = 0.5
				BottomEffect.Parent = ButtonForeground
			end

			local HiddenButton = TextButton(Text, 12)
			HiddenButton.Parent = ButtonForeground

			HiddenButton.MouseButton1Down:Connect(function()
				if typeof(Callback) == "function" then
					Callback()
				end
				Tween(ButtonForeground, {ImageColor3 = Color3.fromRGB(45, 45, 45)})
				Tween(HiddenButton, {TextTransparency = 0.5})
				task.wait(TweenTime)
				Tween(ButtonForeground, {ImageColor3 = Color3.fromRGB(35, 35, 35)})
				Tween(HiddenButton, {TextTransparency = 0})
			end)

			local Handle = {}
			function Handle:Destroy()
				if ButtonContainer then ButtonContainer:Destroy() end
			end
			return Handle
		end

		function PageLibrary.AddLabel(Text)
			Text = tostring(Text or "Label")
			local LabelContainer = Frame()
			LabelContainer.Name = Text .. "LABEL"
			LabelContainer.Size = UDim2.new(1, 0, 0, 20)
			LabelContainer.BackgroundTransparency = 1
			LabelContainer.Parent = DisplayPage

			local LabelForeground = RoundBox(5)
			LabelForeground.Name = "LabelForeground"
			LabelForeground.ImageColor3 = Color3.fromRGB(45, 45, 45)
			LabelForeground.Size = UDim2.new(1, 0, 1, 0)
			LabelForeground.Parent = LabelContainer

			local HiddenLabel = TextLabel(Text, 12)
			HiddenLabel.Parent = LabelForeground

			local Handle = {}
			function Handle:Set(newText)
				HiddenLabel.Text = tostring(newText or "")
			end
			function Handle:Get()
				return HiddenLabel.Text
			end
			function Handle:Destroy()
				if LabelContainer then LabelContainer:Destroy() end
			end
			return Handle
		end

		function PageLibrary.AddBlank(Parent)
			local BlankContainer = Frame()
			BlankContainer.Name = "BlankSPACE"
			BlankContainer.Size = UDim2.new(1, 0, 0, 20)
			BlankContainer.BackgroundTransparency = 1
			BlankContainer.Parent = Parent or DisplayPage

			local BlankForeground = RoundBox(5)
			BlankForeground.Name = "BlankForeground"
			BlankForeground.Size = UDim2.new(1, 0, 1, 0)
			BlankForeground.ImageTransparency = 1
			BlankForeground.Parent = BlankContainer

			local Handle = {}
			function Handle:Destroy()
				if BlankContainer then BlankContainer:Destroy() end
			end
			return Handle
		end

		--// SLIDER (returns handle)
		function PageLibrary.AddSlider(Text, ConfigurationDictionary, Callback, Parent)
			Text = tostring(Text or "Slider")
			local cfg = ConfigurationDictionary or {}

			local Minimum = cfg.Min or cfg.min or cfg.Minimum or cfg.minimum or 0
			local Maximum = cfg.Max or cfg.max or cfg.Maximum or cfg.maximum or 100
			local Default = cfg.Def or cfg.def or cfg.Default or cfg.default or Minimum
			local UseDecimal = (cfg.UseDecimal == true)

			if Minimum > Maximum then
				Minimum, Maximum = Maximum, Minimum
			end

			Default = clamp(Default, Minimum, Maximum)
			local DefaultScale = (Maximum == Minimum) and 0 or ((Default - Minimum) / (Maximum - Minimum))
			local CurrentValue = Default

			local SliderContainer = Frame()
			SliderContainer.Name = Text .. "SLIDER"
			SliderContainer.Size = UDim2.new(1, 0, 0, 20)
			SliderContainer.BackgroundTransparency = 1
			SliderContainer.Parent = Parent or DisplayPage

			local SliderForeground = RoundBox(5)
			SliderForeground.Name = "SliderForeground"
			SliderForeground.ImageColor3 = Color3.fromRGB(35, 35, 35)
			SliderForeground.Size = UDim2.new(1, 0, 1, 0)
			SliderForeground.Parent = SliderContainer

			local SliderButton = TextButton(Text .. ": " .. tostring(Default), 12)
			SliderButton.Size = UDim2.new(1, 0, 1, 0)
			SliderButton.ZIndex = 6
			SliderButton.Parent = SliderForeground

			local SliderFill = RoundBox(5)
			SliderFill.Size = UDim2.new(DefaultScale, 0, 1, 0)
			SliderFill.ImageColor3 = Color3.fromRGB(70, 70, 70)
			SliderFill.ZIndex = 5
			SliderFill.ImageTransparency = 0.7
			SliderFill.Parent = SliderButton

			local function setByScale(XScale, fireCallbacks)
				fireCallbacks = (fireCallbacks == nil) and true or (fireCallbacks == true)
				XScale = clamp(XScale, 0, 1)

				local Value = Minimum + ((Maximum - Minimum) * XScale)
				if UseDecimal then
					Value = math.floor(Value * 100) / 100
				else
					Value = math.floor(Value)
				end

				CurrentValue = Value
				SliderButton.Text = Text .. ": " .. tostring(Value)
				SliderFill.Size = UDim2.new(XScale, 0, 1, 0)

				if fireCallbacks and typeof(Callback) == "function" then
					Callback(Value)
				end
			end

			local function setByValue(Value, fireCallbacks)
				fireCallbacks = (fireCallbacks == nil) and true or (fireCallbacks == true)
				Value = tonumber(Value) or Minimum
				Value = clamp(Value, Minimum, Maximum)
				local scale = (Maximum == Minimum) and 0 or ((Value - Minimum) / (Maximum - Minimum))
				setByScale(scale, fireCallbacks)
			end

			SliderButton.MouseButton1Down:Connect(function()
				local _, _, XScale = GetXY(SliderButton)
				setByScale(XScale, true)

				local MoveConn, EndConn
				MoveConn = Mouse.Move:Connect(function()
					local _, _, NewScale = GetXY(SliderButton)
					setByScale(NewScale, true)
				end)

				EndConn = UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						if MoveConn then MoveConn:Disconnect() end
						if EndConn then EndConn:Disconnect() end
					end
				end)
			end)

			if typeof(Callback) == "function" then
				Callback(Default)
			end

			local Handle = {}
			function Handle:Get()
				return CurrentValue
			end
			function Handle:Set(val, fireCallbacks)
				setByValue(val, fireCallbacks)
			end
			function Handle:Destroy()
				if SliderContainer then SliderContainer:Destroy() end
			end
			return Handle
		end

		--// TOGGLE (returns handle)
		function PageLibrary.AddToggle(Text, Default, Callback)
			Text = tostring(Text or "Toggle")
			local ThisToggle = (Default == true)

			local ToggleContainer = Frame()
			ToggleContainer.Name = Text .. "TOGGLE"
			ToggleContainer.Size = UDim2.new(1, 0, 0, 20)
			ToggleContainer.BackgroundTransparency = 1
			ToggleContainer.Parent = DisplayPage

			local ToggleLeftSide = RoundBox(5)
			local ToggleRightSide = RoundBox(5)
			local EffectFrame = Frame()
			local RightTick = TickIcon()

			local FlatLeft = Frame()
			local FlatRight = Frame()

			ToggleLeftSide.Size = UDim2.new(1, -22, 1, 0)
			ToggleLeftSide.ImageColor3 = Color3.fromRGB(35, 35, 35)
			ToggleLeftSide.Parent = ToggleContainer

			ToggleRightSide.Position = UDim2.new(1, -20, 0, 0)
			ToggleRightSide.Size = UDim2.new(0, 20, 1, 0)
			ToggleRightSide.ImageColor3 = Color3.fromRGB(45, 45, 45)
			ToggleRightSide.Parent = ToggleContainer

			FlatLeft.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
			FlatLeft.Size = UDim2.new(0, 5, 1, 0)
			FlatLeft.Position = UDim2.new(1, -5, 0, 0)
			FlatLeft.Parent = ToggleLeftSide

			FlatRight.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
			FlatRight.Size = UDim2.new(0, 5, 1, 0)
			FlatRight.Parent = ToggleRightSide

			EffectFrame.BackgroundColor3 = ThisToggle and Color3.fromRGB(0, 255, 109) or Color3.fromRGB(255, 160, 160)
			EffectFrame.Position = UDim2.new(1, -22, 0.2, 0)
			EffectFrame.Size = UDim2.new(0, 2, 0.6, 0)
			EffectFrame.Parent = ToggleContainer

			RightTick.ImageTransparency = ThisToggle and 0 or 1
			RightTick.Parent = ToggleRightSide

			local ToggleButton = TextButton(Text, 12)
			ToggleButton.Name = "ToggleButton"
			ToggleButton.Size = UDim2.new(1, 0, 1, 0)
			ToggleButton.Parent = ToggleLeftSide

			local function apply(newValue, fireCallbacks)
				fireCallbacks = (fireCallbacks == nil) and true or (fireCallbacks == true)
				ThisToggle = (newValue == true)
				Tween(EffectFrame, {BackgroundColor3 = ThisToggle and Color3.fromRGB(0, 255, 109) or Color3.fromRGB(255, 160, 160)})
				Tween(RightTick, {ImageTransparency = ThisToggle and 0 or 1})

				if fireCallbacks and typeof(Callback) == "function" then
					Callback(ThisToggle)
				end
			end

			ToggleButton.MouseButton1Down:Connect(function()
				apply(not ThisToggle, true)
			end)

			if typeof(Callback) == "function" then
				Callback(ThisToggle)
			end

			local Handle = {}
			function Handle:Get()
				return ThisToggle
			end
			function Handle:Set(val, fireCallbacks)
				apply(val == true, fireCallbacks)
			end
			function Handle:Destroy()
				if ToggleContainer then ToggleContainer:Destroy() end
			end
			return Handle
		end

		--// DROPDOWN (returns handle)
		function PageLibrary.AddDropdown(Text, ConfigurationArray, Callback)
			Text = tostring(Text or "Dropdown")
			local DropdownArray = ConfigurationArray or {}
			local DropdownToggle = false

			local Selected = DropdownArray[1]

			local DropdownContainer = Frame()
			DropdownContainer.Size = UDim2.new(1, 0, 0, 20)
			DropdownContainer.Name = Text .. "DROPDOWN"
			DropdownContainer.BackgroundTransparency = 1
			DropdownContainer.Parent = DisplayPage

			local DropdownForeground = RoundBox(5)
			DropdownForeground.ClipsDescendants = true
			DropdownForeground.ImageColor3 = Color3.fromRGB(35, 35, 35)
			DropdownForeground.Size = UDim2.new(1, 0, 1, 0)
			DropdownForeground.Parent = DropdownContainer

			local DropdownExpander = DropdownIcon(true)
			DropdownExpander.Parent = DropdownForeground

			local DropdownLabel = TextLabel(Text, 12)
			DropdownLabel.Size = UDim2.new(1, 0, 0, 20)
			DropdownLabel.Parent = DropdownForeground

			local function setLabel()
				if Selected ~= nil then
					DropdownLabel.Text = Text .. ": " .. tostring(Selected)
				else
					DropdownLabel.Text = Text
				end
			end
			setLabel()

			local DropdownFrame = Frame()
			DropdownFrame.Position = UDim2.new(0, 0, 0, 20)
			DropdownFrame.BackgroundTransparency = 1
			DropdownFrame.Size = UDim2.new(1, 0, 0, #DropdownArray * 20)
			DropdownFrame.Parent = DropdownForeground

			local DropdownList = Instance.new("UIListLayout")
			DropdownList.Parent = DropdownFrame

			for idx, option in ipairs(DropdownArray) do
				PageLibrary.AddButton(option, function()
					Selected = option
					setLabel()
					if typeof(Callback) == "function" then
						Callback(option)
					end
				end, DropdownFrame, idx < #DropdownArray)
			end

			DropdownExpander.MouseButton1Down:Connect(function()
				DropdownToggle = not DropdownToggle
				Tween(DropdownContainer, {Size = DropdownToggle and UDim2.new(1, 0, 0, 20 + (#DropdownArray * 20)) or UDim2.new(1, 0, 0, 20)})
				Tween(DropdownExpander, {Rotation = DropdownToggle and 135 or 0})
			end)

			local Handle = {}
			function Handle:Get()
				return Selected
			end
			function Handle:Set(val, fireCallbacks)
				fireCallbacks = (fireCallbacks == nil) and true or (fireCallbacks == true)
				Selected = val
				setLabel()
				if fireCallbacks and typeof(Callback) == "function" then
					Callback(Selected)
				end
			end
			function Handle:Destroy()
				if DropdownContainer then DropdownContainer:Destroy() end
			end
			return Handle
		end

		--// COLOUR PICKER (returns handle, Get -> {r,g,b} 0..255)
		function PageLibrary.AddColourPicker(Text, DefaultColour, Callback)
			Text = tostring(Text or "Colour")

			local ColourDictionary = {
				white = Color3.fromRGB(255, 255, 255),
				black = Color3.fromRGB(0, 0, 0),
				red = Color3.fromRGB(255, 0, 0),
				green = Color3.fromRGB(0, 255, 0),
				purple = Color3.fromRGB(180, 0, 255),
				yellow = Color3.fromRGB(255, 255, 0),
				blue = Color3.fromRGB(0, 0, 255),
			}

			if typeof(DefaultColour) == "table" then
				DefaultColour = Color3.fromRGB(DefaultColour[1] or 255, DefaultColour[2] or 255, DefaultColour[3] or 255)
			elseif typeof(DefaultColour) == "string" then
				DefaultColour = ColourDictionary[DefaultColour:lower()] or ColourDictionary.white
			elseif typeof(DefaultColour) ~= "Color3" then
				DefaultColour = ColourDictionary.white
			end

			local r = math.round(DefaultColour.R * 255)
			local g = math.round(DefaultColour.G * 255)
			local b = math.round(DefaultColour.B * 255)

			local PickerContainer = Frame()
			PickerContainer.ClipsDescendants = true
			PickerContainer.Size = UDim2.new(1, 0, 0, 20)
			PickerContainer.Name = Text .. "COLOURPICKER"
			PickerContainer.BackgroundTransparency = 1
			PickerContainer.Parent = DisplayPage

			local ColourTracker = Instance.new("Color3Value")
			ColourTracker.Value = DefaultColour
			ColourTracker.Parent = PickerContainer

			local PickerLeftSide = RoundBox(5)
			local PickerRightSide = RoundBox(5)
			local PickerFrame = RoundBox(5)

			PickerLeftSide.Size = UDim2.new(1, -22, 1, 0)
			PickerLeftSide.ImageColor3 = Color3.fromRGB(35, 35, 35)
			PickerLeftSide.Parent = PickerContainer

			PickerRightSide.Size = UDim2.new(0, 20, 1, 0)
			PickerRightSide.Position = UDim2.new(1, -20, 0, 0)
			PickerRightSide.ImageColor3 = DefaultColour
			PickerRightSide.Parent = PickerContainer

			PickerFrame.ImageColor3 = Color3.fromRGB(35, 35, 35)
			PickerFrame.Size = UDim2.new(1, -22, 0, 60)
			PickerFrame.Position = UDim2.new(0, 0, 0, 20)
			PickerFrame.Parent = PickerContainer

			local PickerList = Instance.new("UIListLayout")
			PickerList.SortOrder = Enum.SortOrder.LayoutOrder
			PickerList.Parent = PickerFrame

			local EffectLeft = Frame()
			local EffectRight = Frame()

			EffectLeft.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
			EffectLeft.Position = UDim2.new(1, -5, 0, 0)
			EffectLeft.Size = UDim2.new(0, 5, 1, 0)
			EffectLeft.Parent = PickerLeftSide

			EffectRight.BackgroundColor3 = DefaultColour
			EffectRight.Size = UDim2.new(0, 5, 1, 0)
			EffectRight.Parent = PickerRightSide

			local PickerLabel = TextLabel(Text, 12)
			PickerLabel.Size = UDim2.new(1, 0, 0, 20)
			PickerLabel.Parent = PickerLeftSide

			local function apply(fireCallbacks)
				fireCallbacks = (fireCallbacks == nil) and true or (fireCallbacks == true)
				local c = Color3.fromRGB(r, g, b)
				ColourTracker.Value = c
				if fireCallbacks and typeof(Callback) == "function" then
					Callback(c)
				end
			end

			PageLibrary.AddSlider("R", {Min = 0, Max = 255, Def = r}, function(v)
				r = v
				apply(true)
			end, PickerFrame)

			PageLibrary.AddSlider("G", {Min = 0, Max = 255, Def = g}, function(v)
				g = v
				apply(true)
			end, PickerFrame)

			PageLibrary.AddSlider("B", {Min = 0, Max = 255, Def = b}, function(v)
				b = v
				apply(true)
			end, PickerFrame)

			ColourTracker:GetPropertyChangedSignal("Value"):Connect(function()
				local c = ColourTracker.Value
				EffectRight.BackgroundColor3 = c
				PickerRightSide.ImageColor3 = c
			end)

			local PickerToggle = false
			local PickerButton = TextButton("", 12)
			PickerButton.Parent = PickerRightSide

			PickerButton.MouseButton1Down:Connect(function()
				PickerToggle = not PickerToggle
				Tween(PickerContainer, {Size = PickerToggle and UDim2.new(1, 0, 0, 80) or UDim2.new(1, 0, 0, 20)})
			end)

			if typeof(Callback) == "function" then
				Callback(DefaultColour)
			end

			local Handle = {}
			function Handle:Get()
				return {r, g, b}
			end
			function Handle:Set(val, fireCallbacks)
				fireCallbacks = (fireCallbacks == nil) and true or (fireCallbacks == true)
				if typeof(val) == "Color3" then
					r = math.round(val.R * 255)
					g = math.round(val.G * 255)
					b = math.round(val.B * 255)
				elseif typeof(val) == "table" then
					r = clamp(val[1] or val.r or r, 0, 255)
					g = clamp(val[2] or val.g or g, 0, 255)
					b = clamp(val[3] or val.b or b, 0, 255)
				end
				apply(fireCallbacks)
			end
			function Handle:Destroy()
				if PickerContainer then PickerContainer:Destroy() end
			end
			return Handle
		end

		-- SearchBar (after controls exist, so it can filter properly)
		if SearchBarIncluded then
			local SearchBarContainer = RoundBox(5)
			SearchBarContainer.Name = "SearchBar"
			SearchBarContainer.ImageColor3 = Color3.fromRGB(35, 35, 35)
			SearchBarContainer.Size = UDim2.new(1, 0, 0, 20)
			SearchBarContainer.Parent = DisplayPage
			SearchBarContainer.LayoutOrder = -999999

			local SearchBox = TextBox("Search...", 12)
			SearchBox.Name = "SearchInput"
			SearchBox.Position = UDim2.new(0, 20, 0, 0)
			SearchBox.Size = UDim2.new(1, -20, 1, 0)
			SearchBox.TextTransparency = 0.5
			SearchBox.TextXAlignment = Enum.TextXAlignment.Left
			SearchBox.ClearTextOnFocus = false
			SearchBox.Parent = SearchBarContainer

			local SearchIconObj = SearchIcon()
			SearchIconObj.Parent = SearchBarContainer

			SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
				local q = tostring(SearchBox.Text or ""):lower()
				for _, Element in ipairs(DisplayPage:GetChildren()) do
					if Element:IsA("Frame") then
						local nm = Element.Name:lower()
						-- Skip label containers
						local isLabel = nm:find("label") ~= nil
						local isSearch = (Element.Name == "SearchBar")
						if not isLabel and not isSearch then
							if q == "" then
								Element.Visible = true
							else
								Element.Visible = (nm:find(q, 1, true) ~= nil)
							end
						end
					end
				end
			end)
		end

		return PageLibrary
	end

	-- force initial active tab
	task.defer(function()
		local first = MenuBar:FindFirstChildWhichIsA("GuiObject")
		if first then
			setActiveTab(first.Name:lower())
		end
	end)

	return TabLibrary
end

--// ============================================================
--// NOTIFY (UIListLayout-safe slide-in toast)
--// ============================================================
function UILibrary.Notify(Title, Text, Duration, LogoImage)
	Title = tostring(Title or "Notification")
	Text = tostring(Text or "")
	Duration = tonumber(Duration) or 3
	LogoImage = LogoImage or "rbxthumb://type=Asset&id=6845502547&w=150&h=150"

	local function findLoadedGui()
		local function scan(parent)
			for _, g in ipairs(parent:GetChildren()) do
				if g:IsA("ScreenGui") then
					local cf = g:FindFirstChild("ContainerFrame")
					if cf and cf:FindFirstChild("MainFrame") then
						local mf = cf.MainFrame
						if mf:FindFirstChild("TitleBar") and mf:FindFirstChild("Display") and mf:FindFirstChild("MenuBar") then
							return g
						end
					end
				end
			end
			return nil
		end

		local pg = Player and (Player:FindFirstChildOfClass("PlayerGui") or Player:WaitForChild("PlayerGui"))
		return scan(CoreGuiService) or (pg and scan(pg)) or nil
	end

	local Gui = findLoadedGui()
	if not Gui then
		warn("UILibrary.Notify: couldn't find loaded UI (call after UILibrary.Load).")
		return
	end

	local Holder = Gui:FindFirstChild("NotificationHolder")
	if not Holder then
		Holder = Instance.new("Frame")
		Holder.Name = "NotificationHolder"
		Holder.BackgroundTransparency = 1
		Holder.Size = UDim2.new(0, 280, 1, 0)
		Holder.Position = UDim2.new(1, -290, 0, 12)
		Holder.ZIndex = 9999
		Holder.Parent = Gui

		local List = Instance.new("UIListLayout")
		List.SortOrder = Enum.SortOrder.LayoutOrder
		List.Padding = UDim.new(0, 8)
		List.HorizontalAlignment = Enum.HorizontalAlignment.Right
		List.VerticalAlignment = Enum.VerticalAlignment.Top
		List.Parent = Holder
	end

	local Toast = Instance.new("Frame")
	Toast.Name = "Toast"
	Toast.BackgroundTransparency = 1
	Toast.Size = UDim2.new(0, 280, 0, 82)
	Toast.ZIndex = 9999
	Toast.Parent = Holder

	-- Slide inner frame (Layout-safe)
	local Slide = Instance.new("Frame")
	Slide.Name = "Slide"
	Slide.BackgroundTransparency = 1
	Slide.Size = UDim2.new(1, 0, 1, 0)
	Slide.Position = UDim2.new(1, 300, 0, 0)
	Slide.ZIndex = 9999
	Slide.Parent = Toast

	local Card = Instance.new("Frame")
	Card.Name = "Card"
	Card.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Card.BorderSizePixel = 0
	Card.Size = UDim2.new(1, 0, 1, 0)
	Card.ZIndex = 10000
	Card.Parent = Slide

	local CardCorner = Instance.new("UICorner")
	CardCorner.CornerRadius = UDim.new(0, 10)
	CardCorner.Parent = Card

	local Stroke = Instance.new("UIStroke")
	Stroke.Thickness = 2
	Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	Stroke.Parent = Card

	local TitleBar = Instance.new("Frame")
	TitleBar.BorderSizePixel = 0
	TitleBar.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	TitleBar.Size = UDim2.new(1, -12, 0, 22)
	TitleBar.Position = UDim2.new(0, 6, 0, 6)
	TitleBar.ZIndex = 10001
	TitleBar.Parent = Card

	local TitleCorner = Instance.new("UICorner")
	TitleCorner.CornerRadius = UDim.new(0, 12)
	TitleCorner.Parent = TitleBar

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Size = UDim2.new(1, -10, 1, 0)
	TitleLabel.Position = UDim2.new(0, 5, 0, 0)
	TitleLabel.Font = MainFont
	TitleLabel.TextSize = 14
	TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	TitleLabel.Text = Title
	TitleLabel.ZIndex = 10002
	TitleLabel.Parent = TitleBar

	local Logo = Instance.new("ImageLabel")
	Logo.BackgroundTransparency = 1
	Logo.Size = UDim2.new(0, 42, 0, 42)
	Logo.Position = UDim2.new(0, 10, 0, 20)
	Logo.Image = LogoImage
	Logo.ZIndex = 10002
	Logo.Parent = Card

	local LogoCorner = Instance.new("UICorner")
	LogoCorner.CornerRadius = UDim.new(0, 8)
	LogoCorner.Parent = Logo

	local Body = Instance.new("TextLabel")
	Body.BackgroundTransparency = 1
	Body.Size = UDim2.new(1, -64, 0, 42)
	Body.Position = UDim2.new(0, 58, 0, 32)
	Body.Font = MainFont
	Body.TextSize = 13
	Body.TextColor3 = Color3.fromRGB(255, 255, 255)
	Body.TextXAlignment = Enum.TextXAlignment.Left
	Body.TextYAlignment = Enum.TextYAlignment.Top
	Body.TextWrapped = true
	Body.Text = Text
	Body.ZIndex = 10002
	Body.Parent = Card

	local BarBack = Instance.new("Frame")
	BarBack.BorderSizePixel = 0
	BarBack.BackgroundColor3 = Color3.fromRGB(35, 0, 0)
	BarBack.Size = UDim2.new(1, -12, 0, 6)
	BarBack.Position = UDim2.new(0, 6, 1, -10)
	BarBack.ZIndex = 10001
	BarBack.Parent = Card

	local BarBackCorner = Instance.new("UICorner")
	BarBackCorner.CornerRadius = UDim.new(0, 6)
	BarBackCorner.Parent = BarBack

	local BarFill = Instance.new("Frame")
	BarFill.BorderSizePixel = 0
	BarFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	BarFill.Size = UDim2.new(1, 0, 1, 0)
	BarFill.ZIndex = 10002
	BarFill.Parent = BarBack

	local BarFillCorner = Instance.new("UICorner")
	BarFillCorner.CornerRadius = UDim.new(0, 6)
	BarFillCorner.Parent = BarFill

	-- Fade in
	Card.BackgroundTransparency = 1
	TitleBar.BackgroundTransparency = 1
	Logo.ImageTransparency = 1
	TitleLabel.TextTransparency = 1
	Body.TextTransparency = 1
	BarBack.BackgroundTransparency = 1
	BarFill.BackgroundTransparency = 1

	TweenService:Create(Slide, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
	TweenService:Create(Card, TweenInfo.new(0.14), {BackgroundTransparency = 0}):Play()
	TweenService:Create(TitleBar, TweenInfo.new(0.14), {BackgroundTransparency = 0}):Play()
	TweenService:Create(Logo, TweenInfo.new(0.14), {ImageTransparency = 0}):Play()
	TweenService:Create(TitleLabel, TweenInfo.new(0.14), {TextTransparency = 0}):Play()
	TweenService:Create(Body, TweenInfo.new(0.14), {TextTransparency = 0}):Play()
	TweenService:Create(BarBack, TweenInfo.new(0.14), {BackgroundTransparency = 0}):Play()
	TweenService:Create(BarFill, TweenInfo.new(0.14), {BackgroundTransparency = 0}):Play()

	-- RGB stroke
	local start = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not Toast or not Toast.Parent then
			if conn then conn:Disconnect() end
			return
		end
		local t = os.clock() - start
		local hue = (t * 0.35) % 1
		Stroke.Color = Color3.fromHSV(hue, 1, 1)
	end)

	-- progress
	TweenService:Create(BarFill, TweenInfo.new(Duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 1, 0)}):Play()

	-- out
	task.delay(Duration, function()
		if not Toast or not Toast.Parent then
			if conn then conn:Disconnect() end
			return
		end

		local tweenOut = TweenService:Create(Slide, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(1, 300, 0, 0)})
		tweenOut:Play()
		tweenOut.Completed:Wait()

		if conn then conn:Disconnect() end
		Toast:Destroy()
	end)
end

return UILibrary
