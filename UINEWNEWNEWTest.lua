function PageLibrary.AddToggle(Text, Default, Callback)
	local ThisToggle = (Default == true)

	local ToggleContainer = Frame()
	ToggleContainer.Name = Text .. "TOGGLE"
	ToggleContainer.Size = UDim2.new(1, 0, 0, 20)
	ToggleContainer.BackgroundTransparency = 1
	ToggleContainer.Parent = DisplayPage

	local ToggleLeftSide, ToggleRightSide, EffectFrame, RightTick = RoundBox(5), RoundBox(5), Frame(), TickIcon()
	local FlatLeft, FlatRight = Frame(), Frame()

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

	local function apply(newValue, fire)
		ThisToggle = (newValue == true)
		Tween(EffectFrame, { BackgroundColor3 = ThisToggle and Color3.fromRGB(0, 255, 109) or Color3.fromRGB(255, 160, 
