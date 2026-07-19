--[[
    DESYNC HUB v2 — Fixed
    Draggable GUI + Working Fake Lag
    - You move freely on your screen
    - Other players see you frozen
    - Turn OFF → you teleport to your real position for everyone
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ===== STATE =====
local fakeLagEnabled = false
local ghostCFrame = nil
local realCFrame = nil
local steppedConn = nil
local heartbeatConn = nil
local renderConn = nil
local debounce = false

-- ===== HELPER =====
local function getHRP()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

-- ===== GUI =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DesyncHub_" .. tostring(math.random(1000, 9999))
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true

local ok = pcall(function()
    screenGui.Parent = game:GetService("CoreGui")
end)
if not ok then
    screenGui.Parent = playerGui
end

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 260, 0, 160)
mainFrame.Position = UDim2.new(0.5, -130, 0.5, -80)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(120, 80, 220)
mainStroke.Thickness = 1.2
mainStroke.Transparency = 0.4
mainStroke.Parent = mainFrame

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
header.BorderSizePixel = 0
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 10)
headerCorner.Parent = header

local headerCover = Instance.new("Frame")
headerCover.Size = UDim2.new(1, 0, 0, 10)
headerCover.Position = UDim2.new(0, 0, 1, -10)
headerCover.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
headerCover.BorderSizePixel = 0
headerCover.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -30, 1, 0)
title.Position = UDim2.new(0, 14, 0, 0)
title.BackgroundTransparency = 1
title.Text = "DESYNC HUB"
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = Color3.fromRGB(230, 230, 240)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 8, 0, 8)
statusDot.Position = UDim2.new(1, -18, 0.5, -4)
statusDot.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
statusDot.BorderSizePixel = 0
statusDot.Parent = header

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(1, 0)
statusCorner.Parent = statusDot

-- Toggle Button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, -28, 0, 44)
toggleBtn.Position = UDim2.new(0, 14, 0, 56)
toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = "FAKE LAG: OFF"
toggleBtn.Font = Enum.Font.GothamSemibold
toggleBtn.TextSize = 13
toggleBtn.TextColor3 = Color3.fromRGB(230, 230, 240)
toggleBtn.AutoButtonColor = false
toggleBtn.Active = true
toggleBtn.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = toggleBtn

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -28, 0, 40)
infoLabel.Position = UDim2.new(0, 14, 0, 110)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Appears frozen to others.\nYou move freely on your screen."
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 11
infoLabel.TextColor3 = Color3.fromRGB(150, 150, 165)
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.Parent = mainFrame

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

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- ===== HOVER =====
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
            BackgroundColor3 = Color3.fromRGB(60, 60, 75)
        }):Play()
    end
end)

-- ===== DESYNC LOGIC =====
local function enableDesync()
    local hrp = getHRP()
    if not hrp then return end

    -- Capture current position as both ghost and real
    ghostCFrame = hrp.CFrame
    realCFrame = hrp.CFrame

    -- STEPPED: fires BEFORE physics
    -- Restore to real position so physics moves us from real position
    steppedConn = RunService.Stepped:Connect(function()
        local h = getHRP()
        if not h then return end
        if realCFrame then
            h.CFrame = realCFrame
        end
    end)

    -- HEARTBEAT: fires AFTER physics
    -- Save where we moved to (real), then set to ghost for server replication
    heartbeatConn = RunService.Heartbeat:Connect(function()
        local h = getHRP()
        if not h then return end
        -- Save real position (where physics moved us)
        realCFrame = h.CFrame
        -- Set to ghost position so server replicates frozen position
        if ghostCFrame then
            h.CFrame = ghostCFrame
        end
    end)

    -- RENDERSTEPPED: fires before rendering
    -- Restore to real so WE see ourselves moving
    renderConn = RunService.RenderStepped:Connect(function()
        local h = getHRP()
        if not h then return end
        if realCFrame then
            h.CFrame = realCFrame
        end
    end)
end

local function disableDesync()
    -- Disconnect all connections
    if steppedConn then
        steppedConn:Disconnect()
        steppedConn = nil
    end
    if heartbeatConn then
        heartbeatConn:Disconnect()
        heartbeatConn = nil
    end
    if renderConn then
        renderConn:Disconnect()
        renderConn = nil
    end

    -- Teleport to real position (where we actually moved)
    -- Server will replicate this, everyone sees us at our real location
    local h = getHRP()
    if h and realCFrame then
        h.CFrame = realCFrame
    end

    ghostCFrame = nil
    realCFrame = nil
end

-- ===== TOGGLE =====
toggleBtn.MouseButton1Click:Connect(function()
    if debounce then return end
    debounce = true
    task.wait(0.1)
    debounce = false

    fakeLagEnabled = not fakeLagEnabled

    if fakeLagEnabled then
        enableDesync()
        -- Update GUI immediately
        toggleBtn.Text = "FAKE LAG: ON"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(100, 60, 200)
        statusDot.BackgroundColor3 = Color3.fromRGB(120, 80, 220)
        mainStroke.Transparency = 0.1
    else
        disableDesync()
        -- Update GUI immediately
        toggleBtn.Text = "FAKE LAG: OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
        statusDot.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
        mainStroke.Transparency = 0.4
    end
end)

-- ===== RESPAWN HANDLER =====
LocalPlayer.CharacterAdded:Connect(function()
    if fakeLagEnabled then
        -- Re-enable after respawn
        task.wait(1.5)
        local h = getHRP()
        if h then
            ghostCFrame = h.CFrame
            realCFrame = h.CFrame
        end
    end
end)

-- Notification
print("[DESYNC HUB] Loaded successfully. Press the button to toggle fake lag.")
