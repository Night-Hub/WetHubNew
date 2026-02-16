--// ========================
--// WetHub UI Library (Fixed + ValueButton + CONFIG SYSTEM) - FIXED BUILD
--// - Config registry + Save/Load via writefile/readfile (JSON)
--// - Missing keys auto-add (toggles -> false, others -> __Default)
--// - Handles returned for Toggle/Slider/Dropdown/ColourPicker/ValueButton
--// - IMPORTANT: This file RETURNS UILibrary and contains ONLY ONE Notify() implementation.
--// ========================

--// services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGuiService = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")

--// locals
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local TweenTime = 0.1
local Level = 1
local GlobalTweenInfo = TweenInfo.new(TweenTime)

local DropShadowID = "rbxassetid://297774371"
local DropShadowTransparency = 0.3

local IconLibraryID = "rbxassetid://3926305904"
local IconLibraryID2 = "rbxassetid://3926307971"
local MainFont = Enum.Font.Gotham

--// ========================
--// UILibrary + CONFIG REGISTRY
--// ========================
local UILibrary = {}
UILibrary.__Registry = {}
UILibrary.__ConfigFolder = "WetHubConfigs"
UILibrary.__ConfigExt = ".json"
UILibrary.__ConfigVersion = 1

--// ---------- config helpers ----------
local function _sanitizeKey(s)
	s = tostring(s or "")
	s = s:gsub("[%c\r\n\t]", " ")
	s = s:gsub("%s+", " ")
	s = s:gsub("[^%w%s%-%_%.%[%]%(%)%#%&:]", "")
	s = s:sub(1, 140)
	if s == "" then s = "Unnamed" end
	return s
end

local function _makeKey(pageTitle, kind, text)
	return _sanitizeKey(pageTitle) .. " :: " .. _sanitizeKey(kind) .. " :: " .. _sanitizeKey(text)
end

local function _register(key, handle)
	UILibrary.__Registry[key] = handle
end

local function _ensureFolder()
	if typeof(makefolder) == "function" then
		if typeof(isfolder) == "function" then
			if not isfolder(UILibrary.__ConfigFolder) then
				makefolder(UILibrary.__ConfigFolder)
			end
		else
			pcall(function()
				makefolder(UILibrary.__ConfigFolder)
			end)
		end
	end
end

local function _cfgPath(name)
	name = _sanitizeKey(name)
	if name == "" then name = "default" end
	return UILibrary.__ConfigFolder .. "/" .. name .. UILibrary.__ConfigExt
end

function UILibrary.GetConfigTable()
	local out = {
		Version = UILibrary.__ConfigVersion,
		SavedAt = os.time(),
		Values = {}
	}

	for key, handle in pairs(UILibrary.__Registry) do
		if handle and typeof(handle.Get) == "function" then
			local ok, val = pcall(function()
				return handle:Get()
			end)
			if ok then
				out.Values[key] = val
			end
		end
	end

	return out
end

function UILibrary.ApplyConfigTable(cfg, fireCallbacks)
	fireCallbacks = (fireCallbacks == nil) and true or (fireCallbacks == true)

	if typeof(cfg) ~= "table" or typeof(cfg.Values) ~= "table" then
		return false
	end

	for key, val in pairs(cfg.Values) do
		local handle = UILibrary.__Registry[key]
		if handle and typeof(handle.Set) == "function" then
			pcall(function()
				handle:Set(val, fireCallbacks)
			end)
		end
	end

	return true
end

function UILibrary.WriteConfig(name)
	if typeof(writefile) ~= "function" then
		warn("UILibrary.WriteConfig: writefile() not available in this executor.")
		return false
	end

	_ensureFolder()

	local cfg = UILibrary.GetConfigTable()
	local json = HttpService:JSONEncode(cfg)
	writefile(_cfgPath(name), json)
	return true
end

-- opts:
--  fireCallbacks (default true)
--  autofillMissing (default true)
--  saveIfPatched (default true)
function UILibrary.ReadAndApplyConfig(name, opts)
	opts = opts or {}

	local fireCallbacks = (opts.fireCallbacks == nil) and true or (opts.fireCallbacks == true)
	local autofillMissing = (opts.autofillMissing == nil) and true or (opts.autofillMissing == true)
	local saveIfPatched = (opts.saveIfPatched == nil) and true or (opts.saveIfPatched == true)

	if typeof(readfile) ~= "function" then
		warn("UILibrary.ReadAndApplyConfig: readfile() not available in this executor.")
		return false
	end

	local path = _cfgPath(name)

	if typeof(isfile) == "function" and not isfile(path) then
		warn("UILibrary.ReadAndApplyConfig: config not found: " .. path)
		return false
	end

	local raw = readfile(path)

	local ok, cfg = pcall(function()
		return HttpService:JSONDecode(raw)
	end)

	if not ok or typeof(cfg) ~= "table" then
		warn("UILibrary.ReadAndApplyConfig: invalid config JSON.")
		return false
	end

	cfg.Values = cfg.Values or {}

	-- Patch missing keys for new UI elements (rule: toggles -> false)
	local patched = false
	if autofillMissing then
		for key, handle in pairs(UILibrary.__Registry) do
			if cfg.Values[key] == nil then
				local defaultValue
				if handle and handle.__Type == "Toggle" then
					defaultValue = false
				elseif handle and handle.__Default ~= nil then
					defaultValue = handle.__Default
				else
					defaultValue = false
				end
				cfg.Values[key] = defaultValue
				patched = true
			end
		end
	end

	UILibrary.ApplyConfigTable(cfg, fireCallbacks)

	if patched and saveIfPatched and typeof(writefile) == "function" then
		_ensureFolder()
		writefile(path, HttpService:JSONEncode(cfg))
	end

	return true
end

function UILibrary.ListConfigs()
	if typeof(listfiles) ~= "function" then
		return {}
	end

	_ensureFolder()

	local files = listfiles(UILibrary.__ConfigFolder)
	local out = {}

	for _, f in ipairs(files) do
		local name = tostring(f):match("([^/\\]+)%" .. UILibrary.__ConfigExt .. "$")
		if name then
			table.insert(out, name)
		end
	end

	table.sort(out)
	return out
end

--// ========================
--// UI HELPERS
--// ========================
local function GetXY(GuiObject)
	local X, Y = Mouse.X - GuiObject.AbsolutePosition.X, Mouse.Y - GuiObject.AbsolutePosition.Y
	local MaxX, MaxY = GuiObject.AbsoluteSize.X, GuiObject.AbsoluteSize.Y
	X, Y = math.clamp(X, 0, MaxX), math.clamp(Y, 0, MaxY)
	return X, Y, X / MaxX, Y / MaxY
end

local function TitleIcon(ButtonOrNot)
	local NewTitleIcon = Instance.new(ButtonOrNot and "ImageButton" or "ImageLabel")
	NewTitleIcon.Name = "TitleIcon"
	NewTitleIcon.BackgroundTransparency = 1
	NewTitleIcon.Image = IconLibraryID
	NewTitleIcon.ImageRectOffset = Vector2.new(524, 764)
	NewTitleIcon.ImageRectSize = Vector2.new(36, 36)
	NewTitleIcon.Size = UDim2.new(0, 14, 0, 14)
	NewTitleIcon.Position = UDim2.new(1, -17, 0, 3)
	NewTitleIcon.Rotation = 180
	NewTitleIcon.ZIndex = Level
	return NewTitleIcon
end

local function TickIcon(ButtonOrNot)
	local NewTickIcon = Instance.new(ButtonOrNot and "ImageButton" or "ImageLabel")
	NewTickIcon.Name = "TickIcon"
	NewTickIcon.BackgroundTransparency = 1
	NewTickIcon.Image = "rbxassetid://3926305904"
	NewTickIcon.ImageRectOffset = Vector2.new(312, 4)
	NewTickIcon.ImageRectSize = Vector2.new(24, 24)
	NewTickIcon.Size = UDim2.new(1, -6, 1, -6)
	NewTickIcon.Position = UDim2.new(0, 3, 0, 3)
	NewTickIcon.ZIndex = Level
	return NewTickIcon
end

local function DropdownIcon(ButtonOrNot)
	local NewDropdownIcon = Instance.new(ButtonOrNot and "ImageButton" or "ImageLabel")
	NewDropdownIcon.Name = "DropdownIcon"
	NewDropdownIcon.BackgroundTransparency = 1
	NewDropdownIcon.Image = IconLibraryID2
	NewDropdownIcon.ImageRectOffset = Vector2.new(324, 364)
	NewDropdownIcon.ImageRectSize = Vector2.new(36, 36)
	NewDropdownIcon.Size = UDim2.new(0, 16, 0, 16)
	NewDropdownIcon.Position = UDim2.new(1, -18, 0, 2)
	NewDropdownIcon.ZIndex = Level
	return NewDropdownIcon
end

local function SearchIcon(ButtonOrNot)
	local NewSearchIcon = Instance.new(ButtonOrNot and "ImageButton" or "ImageLabel")
	NewSearchIcon.Name = "SearchIcon"
	NewSearchIcon.BackgroundTransparency = 1
	NewSearchIcon.Image = IconLibraryID
	NewSearchIcon.ImageRectOffset = Vector2.new(964, 324)
	NewSearchIcon.ImageRectSize = Vector2.new(36, 36)
	NewSearchIcon.Size = UDim2.new(0, 16, 0, 16)
	NewSearchIcon.Position = UDim2.new(0, 2, 0, 2)
	NewSearchIcon.ZIndex = Level
	return NewSearchIcon
end

local function RoundBox(CornerRadius, ButtonOrNot)
	local NewRoundBox = Instance.new(ButtonOrNot and "ImageButton" or "ImageLabel")
	NewRoundBox.BackgroundTransparency = 1
	NewRoundBox.Image = "rbxassetid://3570695787"
	NewRoundBox.SliceCenter = Rect.new(100, 100, 100, 100)
	NewRoundBox.SliceScale = math.clamp((CornerRadius or 5) * 0.01, 0.01, 1)
	NewRoundBox.ScaleType = Enum.ScaleType.Slice
	NewRoundBox.ZIndex = Level
	return NewRoundBox
end

local function DropShadow()
	local NewDropShadow = Instance.new("ImageLabel")
	NewDropShadow.Name = "DropShadow"
	NewDropShadow.BackgroundTransparency = 1
	NewDropShadow.Image = DropShadowID
	NewDropShadow.ImageTransparency = DropShadowTransparency
	NewDropShadow.Size = UDim2.new(1, 0, 1, 0)
	NewDropShadow.ZIndex = Level
	return NewDropShadow
end

local function Frame()
	local NewFrame = Instance.new("Frame")
	NewFrame.BorderSizePixel = 0
	NewFrame.ZIndex = Level
	return NewFrame
end

local function ScrollingFrame()
	local NewScrollingFrame = Instance.new("ScrollingFrame")
	NewScrollingFrame.BackgroundTransparency = 1
	NewScrollingFrame.BorderSizePixel = 0
	NewScrollingFrame.ScrollBarThickness = 0
	NewScrollingFrame.ZIndex = Level
	return NewScrollingFrame
end

local function TextButton(Text, Size)
	local NewTextButton = Instance.new("TextButton")
	NewTextButton.Text = Text
	NewTextButton.AutoButtonColor = false
	NewTextButton.Font = MainFont
	NewTextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	NewTextButton.BackgroundTransparency = 1
	NewTextButton.TextSize = Size or 12
	NewTextButton.Size = UDim2.new(1, 0, 1, 0)
	NewTextButton.ZIndex = Level
	return NewTextButton
end

local function TextBox(Text, Size)
	local NewTextBox = Instance.new("TextBox")
	NewTextBox.Text = Text
	NewTextBox.Font = MainFont
	NewTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	NewTextBox.BackgroundTransparency = 1
	NewTextBox.TextSize = Size or 12
	NewTextBox.Size = UDim2.new(1, 0, 1, 0)
	NewTextBox.ZIndex = Level
	return NewTextBox
end

local function TextLabel(Text, Size)
	local NewTextLabel = Instance.new("TextLabel")
	NewTextLabel.Text = Text
	NewTextLabel.Font = MainFont
	NewTextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	NewTextLabel.BackgroundTransparency = 1
	NewTextLabel.TextSize = Size or 12
	NewTextLabel.Size = UDim2.new(1, 0, 1, 0)
	NewTextLabel.ZIndex = Level
	return NewTextLabel
end

local function Tween(GuiObject, Dictionary)
	local TweenBase = TweenService:Create(GuiObject, GlobalTweenInfo, Dictionary)
	TweenBase:Play()
	return TweenBase
end

--// ========================
--// MAIN LOAD (UI)
--// ========================
function UILibrary.Load(GUITitle)
	-- choose parent
	local TargetedParent = RunService:IsStudio() and Player:WaitForChild("PlayerGui") or CoreGuiService

	-- cleanup old
	local FindOldInstance = TargetedParent:FindFirstChild(GUITitle)
	if FindOldInstance then
		FindOldInstance:Destroy()
	end

	-- create screen
	local NewInstance = Instance.new("ScreenGui")
	NewInstance.Name = GUITitle
	NewInstance.Parent = TargetedParent

	-- container
	local ContainerFrame = Frame()
	ContainerFrame.Name = "ContainerFrame"
	ContainerFrame.Size = UDim2.new(0, 500, 0, 300)
	ContainerFrame.Position = UDim2.new(0.5, -250, 0.5, -150)
	ContainerFrame.BackgroundTransparency = 1
	ContainerFrame.Parent = NewInstance

	-- shadow
	local ContainerShadow = DropShadow()
	ContainerShadow.Name = "Shadow"
	ContainerShadow.Parent = ContainerFrame

	Level += 1

	-- main card
	local MainFrame = RoundBox(5)
	MainFrame.ClipsDescendants = true
	MainFrame.Name = "MainFrame"
	MainFrame.Size = UDim2.new(1, -50, 1, -30)
	MainFrame.Position = UDim2.new(0, 25, 0, 15)
	MainFrame.ImageColor3 = Color3.fromRGB(30, 30, 30)
	MainFrame.Parent = ContainerFrame

	-- left tabs
	local MenuBar = ScrollingFrame()
	MenuBar.Name = "MenuBar"
	MenuBar.BackgroundTransparency = 0.7
	MenuBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	MenuBar.Size = UDim2.new(0, 100, 0, 235)
	MenuBar.Position = UDim2.new(0, 5, 0, 30)
	MenuBar.CanvasSize = UDim2.new(0, 0, 0, 0)
	MenuBar.Parent = MainFrame

	-- profile bar under tabs
	local ProfileBarHeight = 40
	local ProfileBarPadding = 5
	MenuBar.Size = UDim2.new(0, 100, 0, 235 - ProfileBarHeight - ProfileBarPadding)

	local ProfileBar = RoundBox(5)
	ProfileBar.Name = "ProfileBar"
	ProfileBar.ImageColor3 = Color3.fromRGB(40, 40, 40)
	ProfileBar.Size = UDim2.new(0, 100, 0, ProfileBarHeight)
	ProfileBar.Position = UDim2.new(0, 5, 1, -(ProfileBarHeight + ProfileBarPadding))
	ProfileBar.ZIndex = Level + 1
	ProfileBar.Parent = MainFrame
	ProfileBar.ClipsDescendants = true

	local Avatar = Instance.new("ImageLabel")
	Avatar.BackgroundTransparency = 1
	Avatar.Size = UDim2.new(0, 28, 0, 28)
	Avatar.Position = UDim2.new(0, 6, 0.5, -14)
	Avatar.ZIndex = ProfileBar.ZIndex + 1
	Avatar.Parent = ProfileBar
	Avatar.Image = ("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(Player.UserId)

	local AvatarCorner = Instance.new("UICorner")
	AvatarCorner.CornerRadius = UDim.new(1, 0)
	AvatarCorner.Parent = Avatar

	local Welcome = Instance.new("TextLabel")
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
	Welcome.ZIndex = ProfileBar.ZIndex + 1
	Welcome.Parent = ProfileBar

	local shownName = (Player.DisplayName and Player.DisplayName ~= "" and Player.DisplayName) or Player.Name
	Welcome.Text = "Welcome,\n" .. shownName .. "!"

	-- display panel
	local DisplayFrame = RoundBox(5)
	DisplayFrame.Name = "Display"
	DisplayFrame.ImageColor3 = Color3.fromRGB(20, 20, 20)
	DisplayFrame.Size = UDim2.new(1, -115, 0, 235)
	DisplayFrame.Position = UDim2.new(0, 110, 0, 30)
	DisplayFrame.Parent = MainFrame

	-- top bar
	local TitleBar = RoundBox(5)
	TitleBar.Name = "TitleBar"
	TitleBar.ImageColor3 = Color3.fromRGB(40, 40, 40)
	TitleBar.Size = UDim2.new(1, -10, 0, 20)
	TitleBar.Position = UDim2.new(0, 5, 0, 5)
	TitleBar.Parent = MainFrame
	TitleBar.ClipsDescendants = false

	Level += 1

	local MinimiseButton = TitleIcon(true)
	MinimiseButton.Name = "Minimise"
	MinimiseButton.Parent = TitleBar

	local TitleButton = TextButton(GUITitle, 14)
	TitleButton.Name = "TitleButton"
	TitleButton.Position = UDim2.new(0, 24, 0, 0)
	TitleButton.Size = UDim2.new(1, -44, 1, 0)
	TitleButton.Parent = TitleBar

	-- minimise
	local MinimiseToggle = true
	MinimiseButton.MouseButton1Down:Connect(function()
		MinimiseToggle = not MinimiseToggle
		if not MinimiseToggle then
			Tween(MainFrame, { Size = UDim2.new(1, -50, 0, 30) })
			Tween(MinimiseButton, { Rotation = 0 })
			Tween(ContainerShadow, { ImageTransparency = 1 })
		else
			Tween(MainFrame, { Size = UDim2.new(1, -50, 1, -30) })
			Tween(MinimiseButton, { Rotation = 180 })
			Tween(ContainerShadow, { ImageTransparency = DropShadowTransparency })
		end
	end)

	-- drag
	TitleButton.MouseButton1Down:Connect(function()
		local LastMX, LastMY = Mouse.X, Mouse.Y
		local MoveConn
		local EndConn

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

	Level += 1

	-- menu layout
	local MenuListLayout = Instance.new("UIListLayout")
	MenuListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	MenuListLayout.Padding = UDim.new(0, 5)
	MenuListLayout.Parent = MenuBar

	-- tab system
	local TabCount = 0
	local TabLibrary = {}

	function TabLibrary.AddPage(PageTitle, SearchBarIncluded)
		SearchBarIncluded = (SearchBarIncluded == nil) and true or SearchBarIncluded
		local __PageTitle = PageTitle

		-- tab button
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

		-- page frame
		local DisplayPage = ScrollingFrame()
		DisplayPage.Visible = (TabCount == 0)
		DisplayPage.Name = PageTitle
		DisplayPage.Size = UDim2.new(1, 0, 1, 0)
		DisplayPage.Parent = DisplayFrame

		-- switch
		PageButton.MouseButton1Down:Connect(function()
			task.spawn(function()
				for _, Button in next, MenuBar:GetChildren() do
					if Button:IsA("GuiObject") then
						local isThis = (Button.Name:lower() == PageContainer.Name:lower())
						local inner = Button:FindFirstChild(Button.Name .. "Button")
						Tween(Button, { ImageColor3 = isThis and Color3.fromRGB(50, 50, 50) or Color3.fromRGB(40, 40, 40) })
						if inner then
							Tween(inner, { TextTransparency = isThis and 0 or 0.5 })
						end
					end
				end
			end)

			task.spawn(function()
				for _, Display in next, DisplayFrame:GetChildren() do
					if Display:IsA("GuiObject") then
						Display.Visible = (Display.Name:lower() == PageContainer.Name:lower())
					end
				end
			end)
		end)

		TabCount += 1

		-- page layout
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

		-- optional search
		if SearchBarIncluded then
			local SearchBarContainer = RoundBox(5)
			SearchBarContainer.Name = "SearchBar"
			SearchBarContainer.ImageColor3 = Color3.fromRGB(35, 35, 35)
			SearchBarContainer.Size = UDim2.new(1, 0, 0, 20)
			SearchBarContainer.Parent = DisplayPage

			local SearchBox = TextBox("Search...")
			SearchBox.Name = "SearchInput"
			SearchBox.Position = UDim2.new(0, 20, 0, 0)
			SearchBox.Size = UDim2.new(1, -20, 1, 0)
			SearchBox.TextTransparency = 0.5
			SearchBox.TextXAlignment = Enum.TextXAlignment.Left
			SearchBox.Parent = SearchBarContainer

			local SearchIconObj = SearchIcon()
			SearchIconObj.Parent = SearchBarContainer

			SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
				local NewValue = SearchBox.Text
				for _, Element in next, DisplayPage:GetChildren() do
					if Element:IsA("Frame") then
						if not string.find(Element.Name:lower(), "label") then
							if NewValue == "" or string.find(Element.Name:lower(), NewValue:lower()) then
								Element.Visible = true
							else
								Element.Visible = false
							end
						end
					end
				end
			end)
		end

		--// ========================
		--// PAGE API
		--// ========================
		local PageLibrary = {}

		-- BUTTON
		function PageLibrary.AddButton(Text, Callback, Parent, Underline)
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
				local TextSize = TextService:GetTextSize(Text, 12, Enum.Font.Gotham, Vector2.new(0, 0))
				local BottomEffect = Frame()
				BottomEffect.Size = UDim2.new(0, TextSize.X, 0, 1)
				BottomEffect.Position = UDim2.new(0.5, (-TextSize.X / 2) - 1, 1, -1)
				BottomEffect.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				BottomEffect.BackgroundTransparency = 0.5
				BottomEffect.Parent = ButtonForeground
			end

			local HiddenButton = TextButton(Text, 12)
			HiddenButton.Parent = ButtonForeground

			HiddenButton.MouseButton1Down:Connect(function()
				if Callback then Callback() end
				Tween(ButtonForeground, { ImageColor3 = Color3.fromRGB(45, 45, 45) })
				Tween(HiddenButton, { TextTransparency = 0.5 })
				task.wait(TweenTime)
				Tween(ButtonForeground, { ImageColor3 = Color3.fromRGB(35, 35, 35) })
				Tween(HiddenButton, { TextTransparency = 0 })
			end)
		end

		-- LABEL
		function PageLibrary.AddLabel(Text)
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
		end

		-- DROPDOWN
		function PageLibrary.AddDropdown(Text, ConfigurationArray, Callback)
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

			for OptionIndex, Option in next, DropdownArray do
				PageLibrary.AddButton(Option, function()
					Selected = Option
					setLabel()
					if Callback then Callback(Option) end
				end, DropdownFrame, OptionIndex < #DropdownArray)
			end

			DropdownExpander.MouseButton1Down:Connect(function()
				DropdownToggle = not DropdownToggle
				Tween(DropdownContainer, {
					Size = DropdownToggle and UDim2.new(1, 0, 0, 20 + (#DropdownArray * 20)) or UDim2.new(1, 0, 0, 20),
				})
				Tween(DropdownExpander, { Rotation = DropdownToggle and 135 or 0 })
			end)

			-- handle
			local key = _makeKey(__PageTitle, "Dropdown", Text)
			local Handle = {}
			Handle.__Type = "Dropdown"
			Handle.__Default = Selected

			function Handle:Get()
				return Selected
			end

			function Handle:Set(val, fireCallbacks)
				fireCallbacks = (fireCallbacks == nil) and true or (fireCallbacks == true)
				Selected = val
				setLabel()
				if fireCallbacks and Callback then
					Callback(Selected)
				end
			end

			function Handle:Destroy()
				if DropdownContainer then DropdownContainer:Destroy() end
				UILibrary.__Registry[key] = nil
			end

			_register(key, Handle)
			return Handle
		end

		-- SLIDER
		function PageLibrary.AddSlider(Text, ConfigurationDictionary, Callback, Parent)
			local Configuration = ConfigurationDictionary or {}

			local Minimum = Configuration.Min or Configuration.min or Configuration.Minimum or Configuration.minimum or 0
			local Maximum = Configuration.Max or Configuration.max or Configuration.Maximum or Configuration.maximum or 100
			local Default = Configuration.Def or Configuration.def or Configuration.Default or Configuration.default or Minimum
			local UseDecimal = Configuration.UseDecimal or false

			if Minimum > Maximum then
				Minimum, Maximum = Maximum, Minimum
			end

			Default = math.clamp(Default, Minimum, Maximum)
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

			local SliderButton = TextButton(Text .. ": " .. tostring(Default))
			SliderButton.Size = UDim2.new(1, 0, 1, 0)
			SliderButton.ZIndex = 6
			SliderButton.Parent = SliderForeground

			local SliderFill = RoundBox(5)
			SliderFill.Size = UDim2.new(DefaultScale, 0, 1, 0)
			SliderFill.ImageColor3 = Color3.fromRGB(70, 70, 70)
			SliderFill.ZIndex = 5
			SliderFill.ImageTransparency = 0.7
			SliderFill.Parent = SliderButton

			local function SetByScale(XScale, fireCallbacks)
				fireCallbacks = (fireCallbacks == nil) and true or (fireCallbacks == true)
				XScale = math.clamp(XScale or 0, 0, 1)

				local Value = Minimum + ((Maximum - Minimum) * XScale)
				if UseDecimal then
					Value = math.floor(Value * 100) / 100
				else
					Value = math.floor(Value)
				end

				CurrentValue = Value
				SliderButton.Text = Text .. ": " .. tostring(Value)
				SliderFill.Size = UDim2.new(XScale, 0, 1, 0)

				if fireCallbacks and Callback then
					Callback(Value)
				end
			end

			local function SetByValue(Value, fireCallbacks)
				fireCallbacks = (fireCallbacks == nil) and true or (fireCallbacks == true)
				Value = tonumber(Value) or Minimum
				Value = math.clamp(Value, Minimum, Maximum)
				local scale = (Maximum == Minimum) and 0 or ((Value - Minimum) / (Maximum - Minimum))
				SetByScale(scale, fireCallbacks)
			end

			SliderButton.MouseButton1Down:Connect(function()
				local _, _, XScale = GetXY(SliderButton)
				SetByScale(XScale, true)

				local MoveConn
				local EndConn

				MoveConn = Mouse.Move:Connect(function()
					local _, _, NewScale = GetXY(SliderButton)
					SetByScale(NewScale, true)
				end)

				EndConn = UserInputService.InputEnded:Connect(function(UserInput)
					if UserInput.UserInputType == Enum.UserInputType.MouseButton1 then
						if MoveConn then MoveConn:Disconnect() end
						if EndConn then EndConn:Disconnect() end
					end
				end)
			end)

			if Callback then Callback(Default) end

			local key = _makeKey(__PageTitle, "Slider", Text)
			local Handle = {}
			Handle.__Type = "Slider"
			Handle.__Default = Default

			function Handle:Get()
				return CurrentValue
			end

			function Handle:Set(val, fireCallbacks)
				SetByValue(val, fireCallbacks)
			end

			function Handle:Destroy()
				if SliderContainer then SliderContainer:Destroy() end
				UILibrary.__Registry[key] = nil
			end

			_register(key, Handle)
			return Handle
		end

		-- COLOUR PICKER (stores {r,g,b})
		function PageLibrary.AddColourPicker(Text, DefaultColour, Callback)
			DefaultColour = DefaultColour or Color3.fromRGB(255, 255, 255)

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

			local function apply(fireCallbacks)
				fireCallbacks = (fireCallbacks == nil) and true or (fireCallbacks == true)
				local c = Color3.fromRGB(r, g, b)
				ColourTracker.Value = c
				if fireCallbacks and Callback then
					Callback(c)
				end
			end

			PageLibrary.AddSlider("R", { Min = 0, Max = 255, Def = r }, function(Value)
				r = Value
				apply(true)
			end, PickerFrame)

			PageLibrary.AddSlider("G", { Min = 0, Max = 255, Def = g }, function(Value)
				g = Value
				apply(true)
			end, PickerFrame)

			PageLibrary.AddSlider("B", { Min = 0, Max = 255, Def = b }, function(Value)
				b = Value
				apply(true)
			end, PickerFrame)

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

			ColourTracker:GetPropertyChangedSignal("Value"):Connect(function()
				local NewValue = ColourTracker.Value
				EffectRight.BackgroundColor3 = NewValue
				PickerRightSide.ImageColor3 = NewValue
			end)

			local PickerToggle = false
			local PickerButton = TextButton("")
			PickerButton.Parent = PickerRightSide

			PickerButton.MouseButton1Down:Connect(function()
				PickerToggle = not PickerToggle
				Tween(PickerContainer, { Size = PickerToggle and UDim2.new(1, 0, 0, 80) or UDim2.new(1, 0, 0, 20) })
			end)

			if Callback then Callback(DefaultColour) end

			local key = _makeKey(__PageTitle, "ColourPicker", Text)
			local Handle = {}
			Handle.__Type = "ColourPicker"
			Handle.__Default = { r, g, b }

			function Handle:Get()
				return { r, g, b }
			end

			function Handle:Set(val, fireCallbacks)
				fireCallbacks = (fireCallbacks == nil) and true or (fireCallbacks == true)

				if typeof(val) == "Color3" then
					r = math.round(val.R * 255)
					g = math.round(val.G * 255)
					b = math.round(val.B * 255)
				elseif typeof(val) == "table" then
					r = math.clamp(tonumber(val[1] or val.r) or r, 0, 255)
					g = math.clamp(tonumber(val[2] or val.g) or g, 0, 255)
					b = math.clamp(tonumber(val[3] or val.b) or b, 0, 255)
				end

				apply(fireCallbacks)
			end

			function Handle:Destroy()
				if PickerContainer then PickerContainer:Destroy() end
				UILibrary.__Registry[key] = nil
			end

			_register(key, Handle)
			return Handle
		end

		-- VALUE BUTTON (button with right square indicator)
		function PageLibrary.AddValueButton(Text, Default, Options, OnClick, Getter)
			Options = Options or {}
			local ButtonEnabled = (Options.button == nil) and true or (Options.button == true)
			local RefreshRate = tonumber(Options.refresh) or 0.25

			local ValueBool = (Default == true)

			local ButtonContainer = Frame()
			ButtonContainer.Name = Text .. "VALUEBUTTON"
			ButtonContainer.Size = UDim2.new(1, 0, 0, 20)
			ButtonContainer.BackgroundTransparency = 1
			ButtonContainer.Parent = DisplayPage

			local ButtonForeground = RoundBox(5)
			ButtonForeground.Name = "ButtonForeground"
			ButtonForeground.Size = UDim2.new(1, 0, 1, 0)
			ButtonForeground.ImageColor3 = Color3.fromRGB(35, 35, 35)
			ButtonForeground.Parent = ButtonContainer

			local HiddenButton = TextButton(Text, 12)
			HiddenButton.Name = "ValueButton"
			HiddenButton.Parent = ButtonForeground

			local IndicatorHolder = Frame()
			IndicatorHolder.Name = "IndicatorHolder"
			IndicatorHolder.BackgroundTransparency = 1
			IndicatorHolder.Size = UDim2.new(0, 20, 0, 20)
			IndicatorHolder.Position = UDim2.new(1, -20, 0, 0)
			IndicatorHolder.ZIndex = Level + 2
			IndicatorHolder.Parent = ButtonForeground

			local Indicator = Frame()
			Indicator.Name = "Indicator"
			Indicator.BorderSizePixel = 0
			Indicator.Size = UDim2.new(0, 12, 0, 12)
			Indicator.Position = UDim2.new(0.5, -6, 0.5, -6)
			Indicator.ZIndex = Level + 3
			Indicator.Parent = IndicatorHolder

			local IndicatorCorner = Instance.new("UICorner")
			IndicatorCorner.CornerRadius = UDim.new(0, 3)
			IndicatorCorner.Parent = Indicator

			local GREEN = Color3.fromRGB(0, 255, 109)
			local RED = Color3.fromRGB(255, 160, 160)

			local function Apply(NewBool)
				NewBool = (NewBool == true)
				if NewBool == ValueBool then
					return
				end
				ValueBool = NewBool
				Tween(Indicator, { BackgroundColor3 = ValueBool and GREEN or RED })
			end

			Indicator.BackgroundColor3 = ValueBool and GREEN or RED

			HiddenButton.MouseButton1Down:Connect(function()
				if ButtonEnabled and OnClick then
					OnClick(ValueBool)
				end

				Tween(ButtonForeground, { ImageColor3 = Color3.fromRGB(45, 45, 45) })
				Tween(HiddenButton, { TextTransparency = 0.5 })
				task.wait(TweenTime)
				Tween(ButtonForeground, { ImageColor3 = Color3.fromRGB(35, 35, 35) })
				Tween(HiddenButton, { TextTransparency = 0 })
			end)

			local GetterConn
			if typeof(Getter) == "function" then
				local acc = 0
				GetterConn = RunService.Heartbeat:Connect(function(dt)
					acc += dt
					if acc < RefreshRate then
						return
					end
					acc = 0

					local ok2, res = pcall(Getter)
					if ok2 and res ~= nil then
						Apply(res)
					end
				end)
			end

			local key = _makeKey(__PageTitle, "ValueButton", Text)
			local Handle = {}
			Handle.__Type = "ValueButton"
			Handle.__Default = ValueBool

			function Handle:Set(NewBool)
				Apply(NewBool)
			end

			function Handle:Get()
				return ValueBool
			end

			function Handle:Destroy()
				if GetterConn then
					GetterConn:Disconnect()
					GetterConn = nil
				end
				if ButtonContainer then
					ButtonContainer:Destroy()
				end
				UILibrary.__Registry[key] = nil
			end

			_register(key, Handle)
			return Handle
		end

		-- TOGGLE
		function PageLibrary.AddToggle(Text, Default, Callback)
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

			local function Apply(NewValue, fireCallbacks)
				fireCallbacks = (fireCallbacks == nil) and true or (fireCallbacks == true)
				ThisToggle = (NewValue == true)
				Tween(EffectFrame, { BackgroundColor3 = ThisToggle and Color3.fromRGB(0, 255, 109) or Color3.fromRGB(255, 160, 160) })
				Tween(RightTick, { ImageTransparency = ThisToggle and 0 or 1 })
				if fireCallbacks and Callback then
					Callback(ThisToggle)
				end
			end

			ToggleButton.MouseButton1Down:Connect(function()
				Apply(not ThisToggle, true)
			end)

			if Callback then Callback(ThisToggle) end

			local key = _makeKey(__PageTitle, "Toggle", Text)
			local Handle = {}
			Handle.__Type = "Toggle"
			Handle.__Default = (Default == true)

			function Handle:Get()
				return ThisToggle
			end

			function Handle:Set(val, fireCallbacks)
				Apply(val == true, fireCallbacks)
			end

			function Handle:Destroy()
				if ToggleContainer then ToggleContainer:Destroy() end
				UILibrary.__Registry[key] = nil
			end

			_register(key, Handle)
			return Handle
		end

		return PageLibrary
	end

	return TabLibrary
end

--// ========================
--// NOTIFY (single, clean)
--// ========================
function UILibrary.Notify(Title, Text, Duration, LogoImage)
	Title = tostring(Title or "Notification")
	Text = tostring(Text or "")
	Duration = tonumber(Duration) or 3
	LogoImage = LogoImage or "rbxthumb://type=Asset&id=6845502547&w=150&h=150"

	-- find loaded GUI
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
	Toast.Position = UDim2.new(1, 300, 0, 0)

	local Card = Instance.new("Frame")
	Card.Name = "Card"
	Card.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Card.BorderSizePixel = 0
	Card.Size = UDim2.new(1, 0, 1, 0)
	Card.ZIndex = 10000
	Card.Parent = Toast

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
	Logo.Position = UDim2.new(0, 10, 0, 26)
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
	BarFill.Position = UDim2.new(0, 0, 0, 0)
	BarFill.ZIndex = 10002
	BarFill.Parent = BarBack

	local BarFillCorner = Instance.new("UICorner")
	BarFillCorner.CornerRadius = UDim.new(0, 6)
	BarFillCorner.Parent = BarFill

	-- fade in
	Card.BackgroundTransparency = 1
	TitleBar.BackgroundTransparency = 1
	Logo.ImageTransparency = 1
	TitleLabel.TextTransparency = 1
	Body.TextTransparency = 1
	BarBack.BackgroundTransparency = 1
	BarFill.BackgroundTransparency = 1

	TweenService:Create(Toast, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
	TweenService:Create(Card, TweenInfo.new(0.14), {BackgroundTransparency = 0}):Play()
	TweenService:Create(TitleBar, TweenInfo.new(0.14), {BackgroundTransparency = 0}):Play()
	TweenService:Create(Logo, TweenInfo.new(0.14), {ImageTransparency = 0}):Play()
	TweenService:Create(TitleLabel, TweenInfo.new(0.14), {TextTransparency = 0}):Play()
	TweenService:Create(Body, TweenInfo.new(0.14), {TextTransparency = 0}):Play()
	TweenService:Create(BarBack, TweenInfo.new(0.14), {BackgroundTransparency = 0}):Play()
	TweenService:Create(BarFill, TweenInfo.new(0.14), {BackgroundTransparency = 0}):Play()

	-- rgb stroke
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

		local tweenOut = TweenService:Create(Toast, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(1, 300, 0, 0)})
		tweenOut:Play()
		tweenOut.Completed:Wait()

		if conn then conn:Disconnect() end
		Toast:Destroy()
	end)
end

return UILibrary
