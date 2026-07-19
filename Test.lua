--[[
    FAKE LAG / DESYNC SCRIPT
    Draggable GUI + Toggle Button
    Clientside movement while appearing frozen to other players
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ===== CONFIG =====
local THEME = {
    Background = Color3.fromRGB(18, 18, 24),
    Header     = Color3.fromRGB(28, 28, 38),
    Accent     = Color3.fromRGB(120, 80, 220),
    AccentHover = Color3.fromRGB(140, 100, 240),
    Text       = Color3.fromRGB(230, 230, 240),
    SubText    = Color3.fromRGB(150, 150, 165),
    ToggleOff  = Color3.fromRGB(60, 60, 75),
    ToggleOn   = Color3.fromRGB(100, 60, 200),
    Corner     = 10,
}

-- ===== STATE =====
local fakeLagEnabled = false
local ghostCFrame = nil
local heartbeatConnection = nil
local renderConnection = nil
local steppedConnection = nil

-- ===== SCREEN GUI =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DesyncHub_" .. tostring(math.random(1000, 9999))
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true

-- Try CoreGui, fall back to PlayerGui
local parentTarget = CoreGui
pcall(function()
    if CoreGui:GetChildren() then parentTarget = CoreGui end
end)
if syn and syn.protect_gui then
    syn.protect_gui(screenGui)
    screenGui.Parent = parentTarget
else
    screenGui.Parent = playerGui
end

-- ===== MAIN FRAME =====
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 260, 0, 180)
mainFrame.Position = UDim2.new(0.5, -130, 0.5, -90)
mainFrame.BackgroundColor3 = THEME.Background
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, THEME.Corner)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = THEME.Accent
mainStroke.Thickness = 1.2
mainStroke.Transparency = 0.4
mainStroke.Parent = mainFrame

-- ===== HEADER =====
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 42)
header.BackgroundColor3 = THEME.Header
header.BorderSizePixel = 0
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, THEME.Corner)
headerCorner.Parent = header

-- Cover bottom corners of header
local headerCover = Instance.new("Frame")
headerCover.Size = UDim2.new(1, 0, 0, THEME.Corner)
headerCover.Position = UDim2.new(0, 0, 1, -THEME.Corner)
headerCover.BackgroundColor3 = THEME.Header
headerCover.BorderSizePixel = 0
headerCover.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 14, 0, 0)
title.BackgroundTransparency = 1
title.Text = "DESYNC HUB"
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = THEME.Text
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

-- Status indicator dot
local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 8, 0, 8)
statusDot.Position = UDim2.new(1, -22, 0.5, -4)
statusDot.BackgroundColor3 = THEME.ToggleOff
statusDot.BorderSizePixel = 0
statusDot.Parent = header

local statusDotCorner = Instance.new("UICorner")
statusDotCorner.CornerRadius = UDim.new(1, 0)
statusDotCorner.Parent = statusDot

-- ===== DRAGGING =====
local dragging = false
local dragStart, startPos

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        if dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end
end)

-- ===== TOGGLE BUTTON =====
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, -28, 0, 44)
toggleBtn.Position = UDim2.new(0, 14, 0, 62)
toggleBtn.BackgroundColor3 = THEME.ToggleOff
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = "FAKE LAG: OFF"
toggleBtn.Font = Enum.Font.GothamSemibold
toggleBtn.TextSize = 13
toggleBtn.TextColor3 = THEME.Text
toggleBtn.AutoButtonColor = false
toggleBtn.Parent = mainFrame

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleBtn

-- Info text
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -28, 0, 40)
infoLabel.Position = UDim2.new(0, 14, 0, 116)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Appears frozen to others.\nYou move freely on your screen."
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 11
infoLabel.TextColor3 = THEME.SubText
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.Parent = mainFrame

-- Button hover effect
toggleBtn.MouseEnter:Connect(function()
    if not fakeLagEnabled then
        TweenService:Create(toggleBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(80, 80, 100)
        }):Play()
    end
end)

toggleBtn.MouseLeave:Connect(function()
    if not fakeLagEnabled then
        TweenService:Create(toggleBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = THEME.ToggleOff
        }):Play()
    end
end)

-- ===== FAKE LAG / DESYNC LOGIC =====

local function enableFakeLag()
    local character = LocalPlayer.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not hrp then return end
    
    -- Store the ghost position (where others see you)
    ghostCFrame = hrp.CFrame
    
    -- Method: Use Stepped to freeze server position, RenderStepped to restore client position
    -- On Stepped (before physics): teleport HRP to ghost position for server replication
    -- On Heartbeat (after physics): save the "real" client position
    -- On RenderStepped: restore HRP to real position so YOU see yourself moving
    
    local realCFrame = hrp.CFrame
    
    steppedConnection = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        -- Save where we actually are (client moved here)
        realCFrame = root.CFrame
        
        -- Teleport to ghost position (server will replicate THIS to others)
        if ghostCFrame then
            root.CFrame = ghostCFrame
        end
    end)
    
    heartbeatConnection = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        -- After physics step, restore our real position so we see ourselves move
        root.CFrame = realCFrame
    end)
end

local function disableFakeLag()
    if steppedConnection then
        steppedConnection:Disconnect()
        steppedConnection = nil
    end
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end
    ghostCFrame = nil
end

-- Toggle handler
toggleBtn.MouseButton1Click:Connect(function()
    fakeLagEnabled = not fakeLagEnabled
    
    if fakeLagEnabled then
        enableFakeLag()
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = THEME.ToggleOn,
            Text = "FAKE LAG: ON"
        }):Play()
        TweenService:Create(statusDot, TweenInfo.new(0.2), {
            BackgroundColor3 = THEME.Accent
        }):Play()
        TweenService:Create(mainStroke, TweenInfo.new(0.3), {
            Transparency = 0.1
        }):Play()
    else
        disableFakeLag()
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = THEME.ToggleOff,
            Text = "FAKE LAG: OFF"
        }):Play()
        TweenService:Create(statusDot, TweenInfo.new(0.2), {
            BackgroundColor3 = THEME.ToggleOff
        }):Play()
        TweenService:Create(mainStroke, TweenInfo.new(0.3), {
            Transparency = 0.4
        }):Play()
    end
end)

-- Re-apply on respawn
LocalPlayer.CharacterAdded:Connect(function()
    if fakeLagEnabled then
        disableFakeLag()
        task.wait(1)
        enableFakeLag()
    end
end)
