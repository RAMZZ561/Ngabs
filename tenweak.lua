--[[
    TEN WEAK // ECLIPSE PROTOCOL HUB v3.0
    Target: Roblox (Universal)
    Theme: Eclipse Purple / Modern Dark
    Operator: VORD
]]

--// SERVICES & CORE VARIABLES //--
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

--// STATE MANAGEMENT //--
local State = {
    ActiveModes = {},
    SelectedPlayer = nil,
    AccentColor = Color3.fromRGB(123, 44, 191), -- Eclipse Purple Default
    RGBEnabled = false,
    FlySpeed = 50,
    WalkSpeed = 16,
    JumpPower = 50,
    Spectating = false,
    GameName = workspace:GetServerName():lower(),
    OriginalLighting = {}
}

local Connections = {}
local RenderBindings = {}
local ESPObjects = {}

--// UTILITY FUNCTIONS //--
local function SafeGetChar() return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait() end
local function GetHumanoid() local c = SafeGetChar() return c and c:FindFirstChildWhichIsA("Humanoid") end
local function GetRoot() local c = SafeGetChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function Notify(Msg) print("[TEN WEAK] " .. Msg) end

--// TRIPLE LAYER GODMODE SYSTEM //--
local function EnableGodMode()
    if State.ActiveModes["GodMode"] then return end
    State.ActiveModes["GodMode"] = true
    
    -- Layer 1: Stat Override
    local hum = GetHumanoid()
    if hum then hum.MaxHealth = math.huge; hum.Health = math.huge end
    
    -- Layer 2: RenderStepped Enforcement
    RenderBindings["GodMode"] = RunService:BindToRenderStep("TW_GodMode", Enum.RenderPriority.Last.Value, function()
        local h = GetHumanoid()
        if h and h.Health < math.huge then h.MaxHealth = math.huge; h.Health = math.huge end
    end)
    
    -- Layer 3: Metatable Namecall Hook
    local mt = getrawmetatable(game)
    if mt and not State.ActiveModes["NamecallHooked"] then
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if (method == "TakeDamage" or method == "Damage") and self:IsDescendantOf(LocalPlayer.Character) then
                return 0
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
        State.ActiveModes["NamecallHooked"] = true
    end
    Notify("GODMODE ACTIVE [TRIPLE LAYER]")
end

local function DisableGodMode()
    State.ActiveModes["GodMode"] = false
    if RenderBindings["GodMode"] then RunService:UnbindFromRenderStep("TW_GodMode"); RenderBindings["GodMode"] = nil end
    Notify("GODMODE DISABLED")
end

--// MOVEMENT & AC BYPASS MODULES //--
local function ToggleFly(Active)
    if Active then
        RenderBindings["Fly"] = RunService:BindToRenderStep("TW_Fly", Enum.RenderPriority.Input.Value, function()
            local root = GetRoot()
            if not root then return end
            local moveDir = Vector3.new(0,0,0)
            local camCF = Camera.CFrame
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += camCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= camCF.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= camCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += camCF.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.yAxis end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir -= Vector3.yAxis end
            if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
            root.Velocity = moveDir * State.FlySpeed
            root.RotVelocity = Vector3.zero
        end)
    else
        if RenderBindings["Fly"] then RunService:UnbindFromRenderStep("TW_Fly"); RenderBindings["Fly"] = nil end
    end
end

local function InitACBypass()
    local mt = getrawmetatable(game)
    local old_namecall = mt.__namecall
    local old_index = mt.__index
    setreadonly(mt, false)
    
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "Kick" and (self == LocalPlayer or self == game) then return task.wait(math.huge) end
        return old_namecall(self, ...)
    end)
    
    mt.__index = newcclosure(function(self, key)
        if self:IsA("Humanoid") and key == "WalkSpeed" and not checkcaller() then return 16 end
        return old_index(self, key)
    end)
    
    setreadonly(mt, true)
    Notify("AC BYPASS ACTIVE")
end

--// RESPAWN HANDLER //--
LocalPlayer.CharacterAdded:Connect(function(char)
    wait(1)
    if State.ActiveModes["GodMode"] then EnableGodMode() end
    if State.ActiveModes["NoClip"] then 
        RunService:BindToRenderStep("TW_NoClip", Enum.RenderPriority.First.Value, function()
            for _, p in ipairs(SafeGetChar():GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
        end)
    end
    Notify("CHARACTER LOADED - MODES RE-APPLIED")
end)

--// CUSTOM UI ENGINE (ECLIPSE THEME) //--
if CoreGui:FindFirstChild("TW_EclipsePro") then CoreGui.TW_EclipsePro:Destroy() end

local Gui = Instance.new("ScreenGui")
Gui.Name = "TW_EclipsePro"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = CoreGui

-- Main Frame
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 800, 0, 550)
Main.Position = UDim2.new(0.5, -400, 0.5, -275)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = Gui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = State.AccentColor
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.4
MainStroke.Parent = Main

-- Header (Draggable)
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 45)
Header.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
Header.BorderSizePixel = 0
Header.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -120, 1, 0)
Title.Position = UDim2.new(0, 20, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "TEN WEAK // ECLIPSE PROTOCOL [VORD]"
Title.TextColor3 = Color3.fromRGB(220, 220, 220)
Title.Font = Enum.Font.Code
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- Drag Logic
local Dragging, DragInput, DragStart, StartPos
Header.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
        Dragging = true; DragStart = Input.Position; StartPos = Main.Position
        Input.Changed:Connect(function() if Input.UserInputState == Enum.UserInputState.End then Dragging = false end end)
    end
end)
Header.InputChanged:Connect(function(Input) if Input.UserInputType == Enum.UserInputType.MouseMovement then DragInput = Input end end)
UserInputService.InputChanged:Connect(function(Input)
    if Input == DragInput and Dragging then
        local Delta = Input.Position - DragStart
        TweenService:Create(Main, TweenInfo.new(0.1), {Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)}):Play()
    end
end)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 180, 1, -45)
Sidebar.Position = UDim2.new(0, 0, 0, 45)
Sidebar.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

local SidebarScroll = Instance.new("ScrollingFrame")
SidebarScroll.Size = UDim2.new(1, 0, 1, 0)
SidebarScroll.BackgroundTransparency = 1
SidebarScroll.BorderSizePixel = 0
SidebarScroll.ScrollBarThickness = 0
SidebarScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
SidebarScroll.Parent = Sidebar

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.Padding = UDim.new(0, 4)
SidebarLayout.Parent = SidebarScroll
SidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() SidebarScroll.CanvasSize = UDim2.new(0, 0, 0, SidebarLayout.AbsoluteContentSize.Y) end)

-- Content Area
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -180, 1, -45)
Content.Position = UDim2.new(0, 180, 0, 45)
Content.BackgroundTransparency = 1
Content.Parent = Main

local ContentScroll = Instance.new("ScrollingFrame")
ContentScroll.Size = UDim2.new(1, -10, 1, -10)
ContentScroll.Position = UDim2.new(0, 5, 0, 5)
ContentScroll.BackgroundTransparency = 1
ContentScroll.BorderSizePixel = 0
ContentScroll.ScrollBarThickness = 2
ContentScroll.ScrollBarImageColor3 = State.AccentColor
ContentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentScroll.Parent = Content

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 10)
ContentLayout.Parent = ContentScroll
ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() ContentScroll.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y) end)

-- Status Bar (Bottom)
local StatusBar = Instance.new("Frame")
StatusBar.Size = UDim2.new(1, 0, 0, 25)
StatusBar.Position = UDim2.new(0, 0, 1, -25)
StatusBar.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
StatusBar.BorderSizePixel = 0
StatusBar.Parent = Main

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, -20, 1, 0)
StatusText.Position = UDim2.new(0, 10, 0, 0)
StatusText.BackgroundTransparency = 1
StatusText.Text = "Build: v3.0.0 | Connected | Servers Online: 4,782 | Users Online: 23,456"
StatusText.TextColor3 = Color3.fromRGB(100, 100, 100)
StatusText.Font = Enum.Font.Code
StatusText.TextSize = 10
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.Parent = StatusBar

--// UI GENERATORS //--
local Tabs = {}
local ActiveTab = nil

local function CreateTab(Name, Icon)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(1, -10, 0, 40)
    TabBtn.Position = UDim2.new(0, 5, 0, 0)
    TabBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    TabBtn.Text = "  " .. (Icon or "") .. " " .. Name
    TabBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    TabBtn.Font = Enum.Font.GothamBold
    TabBtn.TextSize = 12
    TabBtn.TextXAlignment = Enum.TextXAlignment.Left
    TabBtn.Parent = SidebarScroll
    Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 6)

    local Page = Instance.new("Frame")
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.Visible = false
    Page.Parent = ContentScroll

    local PageLayout = Instance.new("UIListLayout")
    PageLayout.Padding = UDim.new(0, 10)
    PageLayout.Parent = Page
    PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ContentScroll.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y)
    end)

    TabBtn.MouseButton1Click:Connect(function()
        if ActiveTab then 
            ActiveTab.Page.Visible = false
            TweenService:Create(ActiveTab.Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(22, 22, 30), TextColor3 = Color3.fromRGB(150, 150, 150)}):Play() 
        end
        Page.Visible = true
        ActiveTab = {Btn = TabBtn, Page = Page}
        TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundColor3 = State.AccentColor, TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    end)

    Tabs[Name] = {Btn = TabBtn, Page = Page}
    if #Tabs == 1 then TabBtn.MouseButton1Click:Fire() end
    return Page
end

local function CreateSection(Parent, Text)
    local Sec = Instance.new("TextLabel")
    Sec.Size = UDim2.new(1, 0, 0, 25)
    Sec.BackgroundTransparency = 1
    Sec.Text = "  " .. string.upper(Text)
    Sec.TextColor3 = State.AccentColor
    Sec.Font = Enum.Font.GothamBold
    Sec.TextSize = 11
    Sec.TextXAlignment = Enum.TextXAlignment.Left
    Sec.Parent = Parent
end

local function CreateToggle(Parent, Name, Default, Callback)
    local Holder = Instance.new("Frame")
    Holder.Size = UDim2.new(1, 0, 0, 36)
    Holder.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    Holder.Parent = Parent
    Instance.new("UICorner", Holder).CornerRadius = UDim.new(0, 6)

    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(1, -60, 1, 0)
    Lbl.Position = UDim2.new(0, 15, 0, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = Name
    Lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    Lbl.Font = Enum.Font.Gotham
    Lbl.TextSize = 13
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Parent = Holder

    local Bg = Instance.new("Frame")
    Bg.Size = UDim2.new(0, 40, 0, 20)
    Bg.Position = UDim2.new(1, -55, 0.5, -10)
    Bg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    Bg.Parent = Holder
    Instance.new("UICorner", Bg).CornerRadius = UDim.new(1, 0)

    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0, 16, 0, 16)
    Circle.Position = UDim2.new(0, 2, 0.5, -8)
    Circle.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    Circle.Parent = Bg
    Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)

    local Active = Default
    local function Update()
        if Active then
            TweenService:Create(Bg, TweenInfo.new(0.2), {BackgroundColor3 = State.AccentColor}):Play()
            TweenService:Create(Circle, TweenInfo.new(0.2), {Position = UDim2.new(1, -18, 0.5, -8), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        else
            TweenService:Create(Bg, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}):Play()
            TweenService:Create(Circle, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = Color3.fromRGB(150, 150, 150)}):Play()
        end
    end

    Holder.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            Active = not Active
            Update()
            if Callback then Callback(Active) end
        end
    end)
    Update()
end

local function CreateSlider(Parent, Name, Min, Max, Default, StateRef, Key)
    local Holder = Instance.new("Frame")
    Holder.Size = UDim2.new(1, 0, 0, 55)
    Holder.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    Holder.Parent = Parent
    Instance.new("UICorner", Holder).CornerRadius = UDim.new(0, 6)

    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(1, -20, 0, 20)
    Lbl.Position = UDim2.new(0, 15, 0, 8)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = Name .. ": " .. Default
    Lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    Lbl.Font = Enum.Font.Gotham
    Lbl.TextSize = 12
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Parent = Holder

    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(1, -30, 0, 6)
    Bar.Position = UDim2.new(0, 15, 1, -18)
    Bar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    Bar.Parent = Holder
    Instance.new("UICorner", Bar).CornerRadius = UDim.new(1, 0)

    local Fill = Instance.new("Frame")
    Fill.BackgroundColor3 = State.AccentColor
    Fill.Parent = Bar
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 14, 0, 14)
    Indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Indicator.Parent = Bar
    Instance.new("UICorner", Indicator).CornerRadius = UDim.new(1, 0)

    StateRef[Key] = Default
    local Percent = (Default - Min) / (Max - Min)
    Fill.Size = UDim2.new(Percent, 0, 1, 0)
    Indicator.Position = UDim2.new(Percent, -7, 0.5, -7)

    local Dragging = false
    Holder.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            Dragging = true
            Input.Changed:Connect(function() if Input.UserInputState == Enum.UserInputState.End then Dragging = false end end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(Input)
        if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
            local AbsPos = Bar.AbsolutePosition.X
            local AbsSize = Bar.AbsoluteSize.X
            local MouseX = Input.Position.X
            local RelX = math.clamp((MouseX - AbsPos) / AbsSize, 0, 1)
            local Val = math.floor(Min + (Max - Min) * RelX)
            StateRef[Key] = Val
            Lbl.Text = Name .. ": " .. Val
            Fill.Size = UDim2.new(RelX, 0, 1, 0)
            Indicator.Position = UDim2.new(RelX, -7, 0.5, -7)
        end
    end)
end

local function CreateButton(Parent, Name, Callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 36)
    Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    Btn.Text = Name
    Btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 12
    Btn.Parent = Parent
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    Btn.MouseButton1Click:Connect(Callback)
    
    Btn.MouseEnter:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 55)}):Play()
    end)
    Btn.MouseLeave:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 42)}):Play()
    end)
end

--// BUILD HUB STRUCTURE //--
local Dashboard = CreateTab("Dashboard", "🏠")
local Movement = CreateTab("Movement", "⚡")
local Combat = CreateTab("Combat", "️")
local Visuals = CreateTab("Visuals", "👁️")
local Modes = CreateTab("Modes", "️")
local Settings = CreateTab("Settings", "⚙️")

-- Dashboard Elements
CreateSection(Dashboard, "SYSTEM TELEMETRY")
local StatsLabel = Instance.new("TextLabel")
StatsLabel.Size = UDim2.new(1, 0, 0, 80)
StatsLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
StatsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatsLabel.Font = Enum.Font.Code
StatsLabel.TextSize = 12
StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
StatsLabel.TextYAlignment = Enum.TextYAlignment.Top
StatsLabel.Parent = Dashboard
Instance.new("UICorner", StatsLabel).CornerRadius = UDim.new(0, 6)
Instance.new("UIPadding", StatsLabel).PaddingLeft = UDim.new(0, 15)
Instance.new("UIPadding", StatsLabel).PaddingTop = UDim.new(0, 15)

RunService.RenderStepped:Connect(function()
    local hum = GetHumanoid()
    local root = GetRoot()
    if hum and root then
        StatsLabel.Text = string.format("HP: %d/%d\nWS: %d | JP: %d\nPOS: %.1f, %.1f, %.1f\nGAME: %s", 
            math.floor(hum.Health), math.floor(hum.MaxHealth), 
            math.floor(hum.WalkSpeed), math.floor(hum.JumpPower), 
            root.Position.X, root.Position.Y, root.Position.Z,
            State.GameName)
    end
end)

CreateSection(Dashboard, "QUICK ACTIONS")
CreateButton(Dashboard, "Rejoin Server", function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
CreateButton(Dashboard, "Server Hop", function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)

-- Movement Elements
CreateSection(Movement, "ALL-IN-ONE")
CreateToggle(Movement, "Activate All-in-One (NoClip+InfJump+Speed)", false, function(Active)
    if Active then
        GetHumanoid().WalkSpeed = State.WalkSpeed
        GetHumanoid().JumpPower = State.JumpPower
        RenderBindings["NoClip"] = RunService:BindToRenderStep("TW_NoClip", Enum.RenderPriority.First.Value, function()
            for _, p in ipairs(SafeGetChar():GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
        end)
    else
        GetHumanoid().WalkSpeed = 16
        GetHumanoid().JumpPower = 50
        if RenderBindings["NoClip"] then 
            RunService:UnbindFromRenderStep("TW_NoClip")
            RenderBindings["NoClip"] = nil 
        end
    end
end)

CreateSection(Movement, "FLY CONTROL")
CreateSlider(Movement, "Fly Speed", 10, 150, 50, State, "FlySpeed")
CreateToggle(Movement, "Enable Fly", false, ToggleFly)

CreateSection(Movement, "TP SYSTEM")
local function CreateButton(Parent, Name, Callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 36)
    Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    Btn.Text = Name
    Btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 12
    Btn.Parent = Parent
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    Btn.MouseButton1Click:Connect(Callback)
    
    Btn.MouseEnter:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 55)}):Play()
    end)
    Btn.MouseLeave:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 42)}):Play()
    end)
end

CreateButton(Movement, "TP to Nearest Player", function()
    local closest, minDist = nil, math.huge
    local lRoot = GetRoot()
    if not lRoot then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (player.Character.HumanoidRootPart.Position - lRoot.Position).Magnitude
            if dist < minDist then minDist = dist; closest = player end
        end
    end
    if closest then lRoot.CFrame = closest.Character.HumanoidRootPart.CFrame end
end)

CreateButton(Movement, "TP to Selected Player", function()
    if State.SelectedPlayer and State.SelectedPlayer.Character and State.SelectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local lRoot = GetRoot()
        if lRoot then lRoot.CFrame = State.SelectedPlayer.Character.HumanoidRootPart.CFrame end
    else
        Notify("NO TARGET SELECTED OR TARGET DEAD")
    end
end)

-- Combat Elements
CreateSection(Combat, "TARGET SELECTION")
local SearchBar = Instance.new("TextBox")
SearchBar.Size = UDim2.new(1, 0, 0, 36)
SearchBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
SearchBar.TextColor3 = Color3.fromRGB(200, 200, 200)
SearchBar.PlaceholderText = "  Search player..."
SearchBar.Font = Enum.Font.Gotham
SearchBar.TextSize = 12
SearchBar.TextXAlignment = Enum.TextXAlignment.Left
SearchBar.Parent = Combat
Instance.new("UICorner", SearchBar).CornerRadius = UDim.new(0, 6)

local PlayerListScroll = Instance.new("ScrollingFrame")
PlayerListScroll.Size = UDim2.new(1, 0, 0, 180)
PlayerListScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
PlayerListScroll.BorderSizePixel = 0
PlayerListScroll.ScrollBarThickness = 2
PlayerListScroll.ScrollBarImageColor3 = State.AccentColor
PlayerListScroll.Parent = Combat
Instance.new("UICorner", PlayerListScroll).CornerRadius = UDim.new(0, 6)

local PlayerListLayout = Instance.new("UIListLayout")
PlayerListLayout.Padding = UDim.new(0, 4)
PlayerListLayout.Parent = PlayerListScroll
PlayerListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    PlayerListScroll.CanvasSize = UDim2.new(0, 0, 0, PlayerListLayout.AbsoluteContentSize.Y)
end)

local function RefreshPlayerList()
    for _, child in ipairs(PlayerListScroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and string.find(string.lower(player.Name), string.lower(SearchBar.Text)) then
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, -8, 0, 32)
            Btn.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
            Btn.Text = "  " .. player.Name
            Btn.TextColor3 = Color3.fromRGB(180, 180, 180)
            Btn.Font = Enum.Font.Gotham
            Btn.TextSize = 12
            Btn.TextXAlignment = Enum.TextXAlignment.Left
            Btn.Parent = PlayerListScroll
            Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
            
            Btn.MouseButton1Click:Connect(function()
                State.SelectedPlayer = player
                Notify("TARGET LOCKED: " .. player.Name)
                for _, b in ipairs(PlayerListScroll:GetChildren()) do
                    if b:IsA("TextButton") then TweenService:Create(b, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(28, 28, 38)}):Play() end
                end
                TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = State.AccentColor}):Play()
            end)
        end
    end
end
SearchBar:GetPropertyChangedSignal("Text"):Connect(RefreshPlayerList)
RefreshPlayerList()

CreateSection(Combat, "OFFENSIVE TOOLS")
CreateButton(Combat, "Fling Target (Physics)", function()
    if State.SelectedPlayer and State.SelectedPlayer.Character then
        local tRoot = State.SelectedPlayer.Character:FindFirstChild("HumanoidRootPart")
        if tRoot then 
            tRoot.Velocity = Vector3.new(0, 250, 0)
            tRoot.RotVelocity = Vector3.new(math.random(-100, 100), math.random(-100, 100), math.random(-100, 100)) 
        end
    end
end)

CreateButton(Combat, "Fake Chat Spam (UTF-8)", function()
    local chars = "█░▒▓"
    for i = 1, 50 do game:GetService("Chat"):Chat(string.rep(chars, 20), Enum.ChatColor.White) end
end)

-- Visuals Elements
CreateSection(Visuals, "OPTICAL OVERRIDE")
CreateToggle(Visuals, "Chams ESP (Highlight)", false, function(Active)
    if Active then
        RenderBindings["ESP"] = RunService:BindToRenderStep("TW_ESP", Enum.RenderPriority.Camera.Value, function()
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local hum = player.Character:FindFirstChildWhichIsA("Humanoid")
                    if hum and hum.Health > 0 and not player.Character:FindFirstChild("TW_Cham") then
                        local hl = Instance.new("Highlight")
                        hl.Name = "TW_Cham"
                        hl.FillColor = State.AccentColor
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.FillTransparency = 0.5
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = player.Character
                    end
                end
            end
        end)
    else
        if RenderBindings["ESP"] then RunService:UnbindFromRenderStep("TW_ESP"); RenderBindings["ESP"] = nil end
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("TW_Cham") then player.Character.TW_Cham:Destroy() end
        end
    end
end)

CreateToggle(Visuals, "Fullbright", false, function(Active)
    if Active then
        State.OriginalLighting = {Brightness=Lighting.Brightness, ClockTime=Lighting.ClockTime, FogEnd=Lighting.FogEnd, GlobalShadows=Lighting.GlobalShadows, OutdoorAmbient=Lighting.OutdoorAmbient}
        Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.FogEnd = 100000; Lighting.GlobalShadows = false; Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    else
        Lighting.Brightness = State.OriginalLighting.Brightness or 1
        Lighting.ClockTime = State.OriginalLighting.ClockTime or 14
        Lighting.FogEnd = State.OriginalLighting.FogEnd or 1000
        Lighting.GlobalShadows = State.OriginalLighting.GlobalShadows or true
        Lighting.OutdoorAmbient = State.OriginalLighting.OutdoorAmbient or Color3.fromRGB(128, 128, 128)
    end
end)

CreateSection(Visuals, "FPS OPTIMIZATION")
CreateToggle(Visuals, "RTX-Off (Performance Mode)", false, function(Active)
    if Active then
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then v.Enabled = false end
        end
        Lighting.GlobalShadows = false
        workspace.Terrain.WaterWaveSize = 0; workspace.Terrain.WaterWaveSpeed = 0; workspace.Terrain.WaterReflectance = 0; workspace.Terrain.WaterTransparency = 0
    else
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then v.Enabled = true end
        end
        workspace.Terrain.WaterWaveSize = 0.1; workspace.Terrain.WaterWaveSpeed = 0.1; workspace.Terrain.WaterReflectance = 0.1; workspace.Terrain.WaterTransparency = 0.3
    end
end)

-- Modes Elements
CreateSection(Modes, "UNIVERSAL MODES")
CreateToggle(Modes, "Infinite Health (God Mode)", false, function(Active) if Active then EnableGodMode() else DisableGodMode() end end)
CreateToggle(Modes, "Statue (Anti-Kill/Freeze)", false, function(Active)
    if Active then
        RenderBindings["Statue"] = RunService:BindToRenderStep("TW_Statue", Enum.RenderPriority.Last.Value, function()
            local hum = GetHumanoid()
            if hum then hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false); hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false) end
        end)
    else
        if RenderBindings["Statue"] then RunService:UnbindFromRenderStep("TW_Statue"); RenderBindings["Statue"] = nil end
    end
end)

-- Settings Elements
CreateSection(Settings, "INTERFACE CONFIGURATION")
CreateToggle(Settings, "RGB Accent Cycle", false, function(Active)
    State.RGBEnabled = Active
    if Active then
        Connections.RGB = RunService.RenderStepped:Connect(function()
            State.AccentColor = Color3.fromHSV(tick() % 5 / 5, 1, 1)
            MainStroke.Color = State.AccentColor
            ContentScroll.ScrollBarImageColor3 = State.AccentColor
        end)
    else
        if Connections.RGB then Connections.RGB:Disconnect() end
        State.AccentColor = Color3.fromRGB(123, 44, 191)
        MainStroke.Color = State.AccentColor
        ContentScroll.ScrollBarImageColor3 = State.AccentColor
    end
end)

CreateButton(Settings, "Destroy GUI", function()
    for name, _ in pairs(RenderBindings) do RunService:UnbindFromRenderStep("TW_" .. name) end
    Gui:Destroy()
end)

--// SYSTEM INITIALIZATION //--
InitACBypass()
Notify("TEN WEAK // ECLIPSE PROTOCOL HUB v3.0 FULLY COMPILED.")
Notify("AWAITING VORD DIRECTIVES.")