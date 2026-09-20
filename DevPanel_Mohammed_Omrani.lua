--========================================================--
--                    DEV PANEL                           --
--                 CLEAN UI VERSION                       --
--========================================================--

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera

--========================================================--
-- CONFIG
--========================================================--

local DEFAULT_SPEED = 16
local DEFAULT_FLY_SPEED = 65

local AIM_SMOOTHNESS = 0.22
local AIM_MAX_DISTANCE = 1000
local AIM_BIND_NAME = "DevPanel_AimAssist"

local LOGO_IMAGE_ID = ""

--========================================================--
-- STATE
--========================================================--

local SpeedEnabled = false
local InfiniteJump = false
local FlyEnabled = false
local NoClipEnabled = false
local ESPEnabled = false
local AimEnabled = false

local CurrentSpeed = DEFAULT_SPEED
local FlySpeed = DEFAULT_FLY_SPEED

local SelectedPlayer = nil
local SavedPoint = nil

local ESPObjects = {}

local CurrentPage = "PLAYER"
local IsMinimized = false

local Dragging = false
local DragStart = nil
local StartPosition = nil

--========================================================--
-- CHARACTER HELPERS
--========================================================--

local function getCharacter(player)
    if not player then return nil end
    return player.Character
end

local function getHumanoid(player)
    local character = getCharacter(player)
    if not character then return nil end
    return character:FindFirstChildOfClass("Humanoid")
end

local function getRoot(player)
    local character = getCharacter(player)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
end

local function getAimPart(player)
    local character = getCharacter(player)
    if not character then return nil end

    local head = character:FindFirstChild("Head")
    if head and head:IsA("BasePart") then return head end

    local root = character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then return root end

    return nil
end

--========================================================--
-- GUI
--========================================================--

local Gui = Instance.new("ScreenGui")
Gui.Name = "DevPanel"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(400, 500)
Main.Position = UDim2.new(0.5, -200, 0.5, -250)
Main.BackgroundColor3 = Color3.fromRGB(17, 17, 20)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Active = true
Main.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 7)
MainCorner.Parent = Main

--========================================================--
-- TOP BAR
--========================================================--

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(18, 18, 21)
TopBar.BorderSizePixel = 0
TopBar.Active = true
TopBar.ZIndex = 20
TopBar.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -100, 1, 0)
Title.Position = UDim2.fromOffset(12, 0)
Title.BackgroundTransparency = 1
Title.Text = "محمد عمراني"
Title.TextColor3 = Color3.fromRGB(245, 245, 245)
Title.TextSize = 15
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextYAlignment = Enum.TextYAlignment.Center
Title.ZIndex = 21
Title.Parent = TopBar

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(32, 32)
Minimize.Position = UDim2.new(1, -70, 0, 4)
Minimize.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
Minimize.BorderSizePixel = 0
Minimize.Text = "—"
Minimize.TextColor3 = Color3.fromRGB(235, 235, 235)
Minimize.TextSize = 15
Minimize.Font = Enum.Font.GothamBold
Minimize.ZIndex = 30
Minimize.Parent = Main

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 5)
MinCorner.Parent = Minimize

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(32, 32)
Close.Position = UDim2.new(1, -35, 0, 4)
Close.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
Close.BorderSizePixel = 0
Close.Text = "×"
Close.TextColor3 = Color3.fromRGB(235, 235, 235)
Close.TextSize = 16
Close.Font = Enum.Font.GothamBold
Close.ZIndex = 30
Close.Parent = Main

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 5)
CloseCorner.Parent = Close

Close.MouseButton1Click:Connect(function()
    RunService:UnbindFromRenderStep(AIM_BIND_NAME)
    Gui:Destroy()
end)

--========================================================--
-- TABS
--========================================================--

local Tabs = Instance.new("Frame")
Tabs.Size = UDim2.new(1, -12, 0, 35)
Tabs.Position = UDim2.fromOffset(6, 46)
Tabs.BackgroundColor3 = Color3.fromRGB(25, 25, 29)
Tabs.BorderSizePixel = 0
Tabs.Parent = Main

local PlayerTab = Instance.new("TextButton")
PlayerTab.Size = UDim2.new(0.5, 0, 1, 0)
PlayerTab.BackgroundColor3 = Color3.fromRGB(40, 40, 47)
PlayerTab.BorderSizePixel = 0
PlayerTab.Text = "PLAYER"
PlayerTab.TextColor3 = Color3.fromRGB(240, 240, 240)
PlayerTab.TextSize = 10
PlayerTab.Font = Enum.Font.GothamBold
PlayerTab.Parent = Tabs

local PlacesTab = Instance.new("TextButton")
PlacesTab.Size = UDim2.new(0.5, 0, 1, 0)
PlacesTab.Position = UDim2.new(0.5, 0, 0, 0)
PlacesTab.BackgroundColor3 = Color3.fromRGB(25, 25, 29)
PlacesTab.BorderSizePixel = 0
PlacesTab.Text = "PLACES"
PlacesTab.TextColor3 = Color3.fromRGB(170, 170, 175)
PlacesTab.TextSize = 10
PlacesTab.Font = Enum.Font.GothamBold
PlacesTab.Parent = Tabs

local PlayerPage = Instance.new("Frame")
PlayerPage.Size = UDim2.new(1, -12, 1, -91)
PlayerPage.Position = UDim2.fromOffset(6, 87)
PlayerPage.BackgroundTransparency = 1
PlayerPage.ClipsDescendants = true
PlayerPage.Parent = Main

local PlacesPage = Instance.new("Frame")
PlacesPage.Size = UDim2.new(1, -12, 1, -91)
PlacesPage.Position = UDim2.fromOffset(6, 87)
PlacesPage.BackgroundTransparency = 1
PlacesPage.ClipsDescendants = true
PlacesPage.Visible = false
PlacesPage.Parent = Main

local function createCorner(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 5)
    corner.Parent = object
    return corner
end

local function createButton(parent, text, width, height)
    local button = Instance.new("TextButton")
    button.Size = UDim2.fromOffset(width, height)
    button.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.fromRGB(225, 225, 230)
    button.TextSize = 9
    button.Font = Enum.Font.Gotham
    button.AutoButtonColor = true
    button.Parent = parent
    createCorner(button, 5)
    return button
end

local function createSection(parent, title, y, height)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, height)
    section.Position = UDim2.fromOffset(0, y)
    section.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    section.BorderSizePixel = 0
    section.Parent = parent
    createCorner(section, 6)

    local sectionTitle = Instance.new("TextLabel")
    sectionTitle.Size = UDim2.new(1, -20, 0, 22)
    sectionTitle.Position = UDim2.fromOffset(10, 5)
    sectionTitle.BackgroundTransparency = 1
    sectionTitle.Text = title
    sectionTitle.TextColor3 = Color3.fromRGB(145, 145, 152)
    sectionTitle.TextSize = 8
    sectionTitle.Font = Enum.Font.GothamBold
    sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    sectionTitle.Parent = section

    return section
end

--========================================================--
-- MOVEMENT
--========================================================--

local Movement = createSection(PlayerPage, "MOVEMENT", 0, 126)

local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.fromOffset(55, 28)
SpeedLabel.Position = UDim2.fromOffset(10, 32)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "SPEED"
SpeedLabel.TextColor3 = Color3.fromRGB(195, 195, 200)
SpeedLabel.TextSize = 9
SpeedLabel.Font = Enum.Font.GothamBold
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
SpeedLabel.Parent = Movement

local SpeedBox = Instance.new("TextBox")
SpeedBox.Size = UDim2.fromOffset(60, 28)
SpeedBox.Position = UDim2.fromOffset(62, 32)
SpeedBox.BackgroundColor3 = Color3.fromRGB(29, 29, 34)
SpeedBox.BorderSizePixel = 0
SpeedBox.Text = "16"
SpeedBox.TextColor3 = Color3.fromRGB(240, 240, 240)
SpeedBox.TextSize = 9
SpeedBox.Font = Enum.Font.Gotham
SpeedBox.ClearTextOnFocus = false
SpeedBox.Parent = Movement
createCorner(SpeedBox, 5)

local SpeedButton = createButton(Movement, "OFF", 55, 28)
SpeedButton.Position = UDim2.fromOffset(128, 32)

SpeedButton.MouseButton1Click:Connect(function()
    SpeedEnabled = not SpeedEnabled

    local value = tonumber(SpeedBox.Text)
    if value then
        CurrentSpeed = math.clamp(value, 1, 500)
    end

    SpeedButton.Text = SpeedEnabled and "ON" or "OFF"

    local humanoid = getHumanoid(LocalPlayer)
    if humanoid then
        humanoid.WalkSpeed = SpeedEnabled and CurrentSpeed or DEFAULT_SPEED
    end
end)

SpeedBox.FocusLost:Connect(function()
    local value = tonumber(SpeedBox.Text)

    if value then
        CurrentSpeed = math.clamp(value, 1, 500)
        SpeedBox.Text = tostring(CurrentSpeed)

        if SpeedEnabled then
            local humanoid = getHumanoid(LocalPlayer)
            if humanoid then
                humanoid.WalkSpeed = CurrentSpeed
            end
        end
    else
        SpeedBox.Text = tostring(CurrentSpeed)
    end
end)

local FlyButton = createButton(Movement, "FLY: OFF", 95, 28)
FlyButton.Position = UDim2.fromOffset(194, 32)

local FlySpeedBox = Instance.new("TextBox")
FlySpeedBox.Size = UDim2.fromOffset(55, 28)
FlySpeedBox.Position = UDim2.fromOffset(298, 32)
FlySpeedBox.BackgroundColor3 = Color3.fromRGB(29, 29, 34)
FlySpeedBox.BorderSizePixel = 0
FlySpeedBox.Text = tostring(DEFAULT_FLY_SPEED)
FlySpeedBox.TextColor3 = Color3.fromRGB(240, 240, 240)
FlySpeedBox.TextSize = 9
FlySpeedBox.Font = Enum.Font.Gotham
FlySpeedBox.ClearTextOnFocus = false
FlySpeedBox.Parent = Movement
createCorner(FlySpeedBox, 5)

local FlySpeedText = Instance.new("TextLabel")
FlySpeedText.Size = UDim2.fromOffset(55, 20)
FlySpeedText.Position = UDim2.fromOffset(298, 63)
FlySpeedText.BackgroundTransparency = 1
FlySpeedText.Text = "FLY SPEED"
FlySpeedText.TextColor3 = Color3.fromRGB(125, 125, 132)
FlySpeedText.TextSize = 7
FlySpeedText.Font = Enum.Font.GothamBold
FlySpeedText.Parent = Movement

FlySpeedBox.FocusLost:Connect(function()
    local value = tonumber(FlySpeedBox.Text)

    if value then
        FlySpeed = math.clamp(value, 1, 500)
        FlySpeedBox.Text = tostring(FlySpeed)
    else
        FlySpeedBox.Text = tostring(FlySpeed)
    end
end)

local JumpButton = createButton(Movement, "INFINITE JUMP: OFF", 150, 28)
JumpButton.Position = UDim2.fromOffset(10, 78)

local NoClipButton = createButton(Movement, "NOCLIP: OFF", 115, 28)
NoClipButton.Position = UDim2.fromOffset(170, 78)

local ESPButton = createButton(Movement, "ESP: OFF", 100, 28)
ESPButton.Position = UDim2.fromOffset(292, 78)

JumpButton.MouseButton1Click:Connect(function()
    InfiniteJump = not InfiniteJump
    JumpButton.Text = InfiniteJump and "INFINITE JUMP: ON" or "INFINITE JUMP: OFF"
end)

UserInputService.JumpRequest:Connect(function()
    if not InfiniteJump then return end

    local humanoid = getHumanoid(LocalPlayer)
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

NoClipButton.MouseButton1Click:Connect(function()
    NoClipEnabled = not NoClipEnabled
    NoClipButton.Text = NoClipEnabled and "NOCLIP: ON" or "NOCLIP: OFF"
end)

RunService.Stepped:Connect(function()
    if not NoClipEnabled then return end

    local character = LocalPlayer.Character
    if not character then return end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end)

local FlyConnection = nil

local function stopFly()
    FlyEnabled = false

    if FlyConnection then
        FlyConnection:Disconnect()
        FlyConnection = nil
    end

    local root = getRoot(LocalPlayer)
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
    end

    FlyButton.Text = "FLY: OFF"
end

local function startFly()
    FlyEnabled = true
    FlyButton.Text = "FLY: ON"

    if FlyConnection then
        FlyConnection:Disconnect()
    end

    FlyConnection = RunService.RenderStepped:Connect(function()
        if not FlyEnabled then return end

        local root = getRoot(LocalPlayer)
        if not root then return end

        local direction = Vector3.zero

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            direction += Camera.CFrame.LookVector
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            direction -= Camera.CFrame.LookVector
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            direction -= Camera.CFrame.RightVector
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            direction += Camera.CFrame.RightVector
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            direction += Vector3.new(0, 1, 0)
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            direction -= Vector3.new(0, 1, 0)
        end

        if direction.Magnitude > 0 then
            direction = direction.Unit
        end

        root.AssemblyLinearVelocity = direction * FlySpeed
    end)
end

FlyButton.MouseButton1Click:Connect(function()
    if FlyEnabled then
        stopFly()
    else
        startFly()
    end
end)

--========================================================--
-- TELEPORT
--========================================================--

local Teleport = createSection(PlayerPage, "TELEPORT", 134, 76)

local SavePoint = createButton(Teleport, "SAVE POINT", 120, 30)
SavePoint.Position = UDim2.fromOffset(10, 34)

local TPPoint = createButton(Teleport, "TP TO POINT", 120, 30)
TPPoint.Position = UDim2.fromOffset(140, 34)

local PointStatus = Instance.new("TextLabel")
PointStatus.Size = UDim2.fromOffset(115, 30)
PointStatus.Position = UDim2.fromOffset(270, 34)
PointStatus.BackgroundTransparency = 1
PointStatus.Text = "POINT: NONE"
PointStatus.TextColor3 = Color3.fromRGB(130, 130, 138)
PointStatus.TextSize = 8
PointStatus.Font = Enum.Font.Gotham
PointStatus.TextXAlignment = Enum.TextXAlignment.Left
PointStatus.Parent = Teleport

SavePoint.MouseButton1Click:Connect(function()
    local root = getRoot(LocalPlayer)
    if not root then return end

    SavedPoint = root.CFrame
    PointStatus.Text = "POINT: SAVED"
    PointStatus.TextColor3 = Color3.fromRGB(130, 220, 150)
end)

TPPoint.MouseButton1Click:Connect(function()
    if not SavedPoint then
        PointStatus.Text = "POINT: NONE"
        return
    end

    local root = getRoot(LocalPlayer)
    if not root then return end

    root.CFrame = SavedPoint
    PointStatus.Text = "POINT: ACTIVE"
end)

--========================================================--
-- AIM ASSIST
--========================================================--

local AimSection = createSection(PlayerPage, "AIM ASSIST", 218, 68)

local AimButton = createButton(AimSection, "AIM ASSIST: OFF", 145, 30)
AimButton.Position = UDim2.fromOffset(10, 32)

local SelectedLabel = Instance.new("TextLabel")
SelectedLabel.Size = UDim2.fromOffset(210, 30)
SelectedLabel.Position = UDim2.fromOffset(165, 32)
SelectedLabel.BackgroundTransparency = 1
SelectedLabel.Text = "SELECTED: NONE"
SelectedLabel.TextColor3 = Color3.fromRGB(165, 165, 172)
SelectedLabel.TextSize = 8
SelectedLabel.Font = Enum.Font.Gotham
SelectedLabel.TextXAlignment = Enum.TextXAlignment.Left
SelectedLabel.Parent = AimSection

--========================================================--
-- PLAYERS
--========================================================--

local PlayersSection = createSection(PlayerPage, "PLAYERS", 292, 190)

local PlayerList = Instance.new("ScrollingFrame")
PlayerList.Size = UDim2.new(1, -20, 1, -34)
PlayerList.Position = UDim2.fromOffset(10, 29)
PlayerList.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
PlayerList.BorderSizePixel = 0
PlayerList.ScrollBarThickness = 3
PlayerList.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 88)
PlayerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
PlayerList.ScrollingEnabled = true
PlayerList.ClipsDescendants = true
PlayerList.Parent = PlayersSection
createCorner(PlayerList, 5)

local PlayerLayout = Instance.new("UIListLayout")
PlayerLayout.Padding = UDim.new(0, 4)
PlayerLayout.SortOrder = Enum.SortOrder.Name
PlayerLayout.Parent = PlayerList

local PlayerPadding = Instance.new("UIPadding")
PlayerPadding.PaddingTop = UDim.new(0, 5)
PlayerPadding.PaddingBottom = UDim.new(0, 5)
PlayerPadding.PaddingLeft = UDim.new(0, 5)
PlayerPadding.PaddingRight = UDim.new(0, 5)
PlayerPadding.Parent = PlayerList

local function refreshPlayerList()
    for _, child in ipairs(PlayerList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local playerArray = Players:GetPlayers()

    table.sort(playerArray, function(a, b)
        return a.Name:lower() < b.Name:lower()
    end)

    for _, player in ipairs(playerArray) do
        if player ~= LocalPlayer then

            local button = Instance.new("TextButton")
            button.Size = UDim2.new(1, -10, 0, 30)

            button.BackgroundColor3 =
                player == SelectedPlayer
                and Color3.fromRGB(50, 50, 58)
                or Color3.fromRGB(28, 28, 33)

            button.BorderSizePixel = 0
            button.Text = "@" .. player.Name
            button.TextColor3 = Color3.fromRGB(225, 225, 230)
            button.TextSize = 9
            button.Font = Enum.Font.Gotham
            button.TextXAlignment = Enum.TextXAlignment.Left
            button.Parent = PlayerList

            local padding = Instance.new("UIPadding")
            padding.PaddingLeft = UDim.new(0, 9)
            padding.Parent = button

            createCorner(button, 4)

            button.MouseButton1Click:Connect(function()
                SelectedPlayer = player
                SelectedLabel.Text = "SELECTED: @" .. player.Name
                refreshPlayerList()
            end)
        end
    end
end

task.spawn(function()
    while Gui.Parent do
        refreshPlayerList()
        task.wait(1)
    end
end)

--========================================================--
-- AIM
--========================================================--

local function stopAim()
    RunService:UnbindFromRenderStep(AIM_BIND_NAME)
end

local function startAim()
    stopAim()

    RunService:BindToRenderStep(
        AIM_BIND_NAME,
        Enum.RenderPriority.Camera.Value + 1,
        function()

            if not AimEnabled then return end
            if not SelectedPlayer then return end

            local humanoid = getHumanoid(SelectedPlayer)
            if not humanoid then return end
            if humanoid.Health <= 0 then return end

            local target = getAimPart(SelectedPlayer)
            if not target then return end

            local distance =
                (target.Position - Camera.CFrame.Position).Magnitude

            if distance > AIM_MAX_DISTANCE then return end

            local desired =
                CFrame.lookAt(
                    Camera.CFrame.Position,
                    target.Position
                )

            Camera.CFrame =
                Camera.CFrame:Lerp(
                    desired,
                    AIM_SMOOTHNESS
                )
        end
    )
end

AimButton.MouseButton1Click:Connect(function()
    if not SelectedPlayer then
        SelectedLabel.Text = "SELECTED: NONE"
        return
    end

    AimEnabled = not AimEnabled

    if AimEnabled then
        AimButton.Text = "AIM ASSIST: ON"
        startAim()
    else
        AimButton.Text = "AIM ASSIST: OFF"
        stopAim()
    end
end)

--========================================================--
-- ESP
--========================================================--

local function removeESP(player)
    local object = ESPObjects[player]

    if object then
        object:Destroy()
        ESPObjects[player] = nil
    end
end

local function addESP(player)
    if player == LocalPlayer then return end

    local character = player.Character
    if not character then return end

    removeESP(player)

    local highlight = Instance.new("Highlight")
    highlight.Name = "DevESP"
    highlight.Adornee = character
    highlight.FillColor = Color3.fromRGB(255, 70, 70)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.65
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character

    ESPObjects[player] = highlight
end

local function updateESP()
    if not ESPEnabled then

        for player, object in pairs(ESPObjects) do
            object:Destroy()
            ESPObjects[player] = nil
        end

        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            addESP(player)
        end
    end
end

ESPButton.MouseButton1Click:Connect(function()
    ESPEnabled = not ESPEnabled
    ESPButton.Text = ESPEnabled and "ESP: ON" or "ESP: OFF"
    updateESP()
end)

--========================================================--
-- PLACES
--========================================================--

local ScanButton = createButton(PlacesPage, "SCAN", 175, 34)
ScanButton.Position = UDim2.fromOffset(5, 0)

local ClearButton = createButton(PlacesPage, "CLEAR", 175, 34)
ClearButton.Position = UDim2.fromOffset(185, 0)

local Results = Instance.new("TextLabel")
Results.Size = UDim2.new(1, -10, 0, 20)
Results.Position = UDim2.fromOffset(5, 42)
Results.BackgroundTransparency = 1
Results.Text = "RESULTS: 0"
Results.TextColor3 = Color3.fromRGB(130, 130, 138)
Results.TextSize = 8
Results.Font = Enum.Font.GothamBold
Results.TextXAlignment = Enum.TextXAlignment.Left
Results.Parent = PlacesPage

local PlacesList = Instance.new("ScrollingFrame")
PlacesList.Size = UDim2.new(1, -10, 1, -70)
PlacesList.Position = UDim2.fromOffset(5, 66)
PlacesList.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
PlacesList.BorderSizePixel = 0
PlacesList.ScrollBarThickness = 4
PlacesList.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 88)
PlacesList.AutomaticCanvasSize = Enum.AutomaticSize.Y
PlacesList.ClipsDescendants = true
PlacesList.Parent = PlacesPage
createCorner(PlacesList, 5)

local PlacesLayout = Instance.new("UIListLayout")
PlacesLayout.Padding = UDim.new(0, 4)
PlacesLayout.SortOrder = Enum.SortOrder.LayoutOrder
PlacesLayout.Parent = PlacesList

local PlacesPadding = Instance.new("UIPadding")
PlacesPadding.PaddingTop = UDim.new(0, 5)
PlacesPadding.PaddingBottom = UDim.new(0, 5)
PlacesPadding.PaddingLeft = UDim.new(0, 5)
PlacesPadding.PaddingRight = UDim.new(0, 5)
PlacesPadding.Parent = PlacesList

local Keywords = {
    "machine",
    "generator",
    "terminal",
    "lucky",
    "gumball",
    "block",
    "crate",
    "chest",
    "shop",
    "portal",
    "teleport",
    "teleporter"
}

local function containsKeyword(name)
    local lower = name:lower()

    for _, keyword in ipairs(Keywords) do
        if string.find(lower, keyword, 1, true) then
            return true
        end
    end

    return false
end

local function getObjectPosition(object)
    if object:IsA("BasePart") then
        return object.Position
    end

    if object:IsA("Model") then
        return object:GetPivot().Position
    end

    return nil
end

local function getDisplayObject(object)
    if object:IsA("Model") then
        return object
    end

    local model =
        object:FindFirstAncestorOfClass("Model")

    return model or object
end

local function clearPlaces()
    for _, child in ipairs(PlacesList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    PlacesList.CanvasPosition = Vector2.zero
    Results.Text = "RESULTS: 0"
end

local function scanPlaces()
    clearPlaces()

    local found = {}
    local seen = {}

    for _, object in ipairs(Workspace:GetDescendants()) do

        if object:IsA("BasePart")
            or object:IsA("Model")
        then

            if containsKeyword(object.Name) then

                local displayObject =
                    getDisplayObject(object)

                if displayObject
                    and displayObject ~= LocalPlayer.Character
                    and not seen[displayObject]
                then

                    local position =
                        getObjectPosition(displayObject)

                    if position then

                        seen[displayObject] = true

                        table.insert(
                            found,
                            {
                                object = displayObject,
                                position = position
                            }
                        )
                    end
                end
            end
        end
    end

    table.sort(found, function(a, b)

        local da =
            (a.position - Camera.CFrame.Position).Magnitude

        local db =
            (b.position - Camera.CFrame.Position).Magnitude

        return da < db
    end)

    for _, data in ipairs(found) do

        local object = data.object
        local position = data.position

        local distance =
            math.floor(
                (position - Camera.CFrame.Position).Magnitude
            )

        local button =
            createButton(
                PlacesList,
                "",
                0,
                32
            )

        button.Size =
            UDim2.new(
                1,
                -10,
                0,
                32
            )

        button.Text =
            object.Name ..
            "   [" ..
            tostring(distance) ..
            " studs]"

        button.TextXAlignment =
            Enum.TextXAlignment.Left

        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 9)
        padding.Parent = button

        button.MouseButton1Click:Connect(function()

            local root =
                getRoot(LocalPlayer)

            if not root then return end

            root.CFrame =
                CFrame.new(
                    position +
                    Vector3.new(0, 4, 0)
                )
        end)
    end

    Results.Text =
        "RESULTS: " ..
        tostring(#found)
end

ScanButton.MouseButton1Click:Connect(scanPlaces)
ClearButton.MouseButton1Click:Connect(clearPlaces)

--========================================================--
-- TABS
--========================================================--

PlayerTab.MouseButton1Click:Connect(function()

    CurrentPage = "PLAYER"

    PlayerPage.Visible = true
    PlacesPage.Visible = false

    PlayerTab.BackgroundColor3 =
        Color3.fromRGB(40, 40, 47)

    PlacesTab.BackgroundColor3 =
        Color3.fromRGB(25, 25, 29)
end)

PlacesTab.MouseButton1Click:Connect(function()

    CurrentPage = "PLACES"

    PlayerPage.Visible = false
    PlacesPage.Visible = true

    PlacesTab.BackgroundColor3 =
        Color3.fromRGB(40, 40, 47)

    PlayerTab.BackgroundColor3 =
        Color3.fromRGB(25, 25, 29)
end)

--========================================================--
-- PLAYER EVENTS
--========================================================--

Players.PlayerAdded:Connect(function(player)

    refreshPlayerList()

    player.CharacterAdded:Connect(function()

        task.wait(0.5)

        if ESPEnabled then
            addESP(player)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)

    removeESP(player)

    if SelectedPlayer == player then

        SelectedPlayer = nil
        AimEnabled = false

        AimButton.Text =
            "AIM ASSIST: OFF"

        SelectedLabel.Text =
            "SELECTED: NONE"

        stopAim()
    end

    refreshPlayerList()
end)

--========================================================--
-- RESPAWN
--========================================================--

LocalPlayer.CharacterAdded:Connect(function(character)

    local humanoid =
        character:WaitForChild(
            "Humanoid",
            10
        )

    if humanoid then

        task.wait(0.2)

        if SpeedEnabled then
            humanoid.WalkSpeed = CurrentSpeed
        else
            humanoid.WalkSpeed = DEFAULT_SPEED
        end
    end
end)

--========================================================--
-- DRAG
--========================================================--

local function updateDrag(input)

    local delta =
        input.Position -
        DragStart

    Main.Position =
        UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + delta.Y
        )
end

local function beginDrag(input)

    if input.UserInputType ~=
        Enum.UserInputType.MouseButton1
    then
        return
    end

    Dragging = true
    DragStart = input.Position
    StartPosition = Main.Position

    local connection

    connection =
        input.Changed:Connect(function()

            if input.UserInputState ==
                Enum.UserInputState.End
            then

                Dragging = false

                if connection then
                    connection:Disconnect()
                end
            end
        end)
end

TopBar.InputBegan:Connect(beginDrag)
Title.InputBegan:Connect(beginDrag)

UserInputService.InputChanged:Connect(function(input)

    if not Dragging then return end

    if input.UserInputType ==
        Enum.UserInputType.MouseMovement
    then
        updateDrag(input)
    end
end)

--========================================================--
-- MINIMIZE
--========================================================--

Minimize.MouseButton1Click:Connect(function()

    IsMinimized = not IsMinimized

    if IsMinimized then

        Tabs.Visible = false
        PlayerPage.Visible = false
        PlacesPage.Visible = false

        Main.Size =
            UDim2.fromOffset(
                400,
                40
            )

        Minimize.Text = "□"

    else

        Tabs.Visible = true

        Main.Size =
            UDim2.fromOffset(
                400,
                500
            )

        if CurrentPage == "PLAYER" then
            PlayerPage.Visible = true
            PlacesPage.Visible = false
        else
            PlayerPage.Visible = false
            PlacesPage.Visible = true
        end

        Minimize.Text = "—"
    end
end)

--========================================================--
-- RIGHT SHIFT
--========================================================--

UserInputService.InputBegan:Connect(function(input, processed)

    if processed then return end

    if input.KeyCode ==
        Enum.KeyCode.RightShift
    then

        Main.Visible =
            not Main.Visible
    end
end)

--========================================================--
-- INITIALIZE
--========================================================--

refreshPlayerList()

print("DEV PANEL - CLEAN VERSION LOADED")
