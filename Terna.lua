local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

local CurrentSelectedPlayer = nil

-- ลิงก์ Webhook ของมึง
local WebhookURL = "https://discord.com/api/webhooks/1514562602208854159/mq9nAgQ_zpnb1czvwSfJRJq1zDAvXz9vpsF2CCzL7aphQS-BN7YTN0NM5eaYM1WYJw29"

-- ตารางจัดเก็บรายชื่อ Whitelist (ไวริส)
local WhitelistPlayers = {}

-- ==================== [ ฟังก์ชันสุ่มแถบสีรุ้งข้างกรอบ Embed ] ====================
local function getRandomRainbowColor()
    local colors = {16711680, 16744192, 16776960, 65280, 65535, 255, 16711935}
    return colors[math.random(1, #colors)]
end

-- ==================== [ ฟังก์ชันส่งข้อมูลเข้า Discord Webhook ] ====================
local function sendToDiscordEmbed(embedData)
    local httpRequest = (syn and syn.request) or http_request or (http and http.request) or request
    if httpRequest then
        pcall(function()
            httpRequest({
                Url = WebhookURL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({["embeds"] = {embedData}})
            })
        end)
    end
end

-- ==================== [ ระบบดึงไอดีจริงจากเอนจินเสียง (Anti-Junk Bypass) ] ====================

local function getAbsoluteSoundID(soundIdStr)
    if type(soundIdStr) ~= "string" or soundIdStr == "" then return "" end
    
    -- ทำการค้นหากลุ่มตัวเลขทั้งหมดที่อยู่ในโครงสร้าง SoundId ของออบเจกต์
    local detectedIDs = {}
    for num in string.gmatch(soundIdStr, "%d+") do
        -- คัดกรองเอาเฉพาะตัวเลขที่มีความยาว 7 ถึง 12 หลัก (ซึ่งเป็นช่วงความยาวของ Asset ID เพลงใน Roblox)
        -- ลบเลข 0 ด้านหน้าออกเพื่อป้องกันทริคถม 0 ข้างหน้าไอดีจริง
        local cleanNum = string.gsub(num, "^0+", "")
        if #cleanNum >= 7 and #cleanNum <= 12 and not string.match(cleanNum, "^1340") then
            table.insert(detectedIDs, cleanNum)
        end
    end
    
    -- ถ้าเจอตัวเลขไอดีที่เข้าเกณฑ์ ให้เลือกตัวล่าสุดหรือตัวที่สมบูรณ์ที่สุด
    if #detectedIDs > 0 then
        -- ปกติแล้ว ตัวเอนจินจะมองหาเลขชุดที่ระบบสามารถแปลงเป็นสินทรัพย์เพลงได้จริง
        return detectedIDs[#detectedIDs] 
    end
    
    -- กรณีดึงไม่สำเร็จจริงๆ ให้คืนค่าตัวเลขชุดแรกที่เจอ
    return string.match(soundIdStr, "%d+") or ""
end

local function copyToClipboard(text)
    local setclip = setclipboard or toclipboard or (Clipboard and Clipboard.set)
    if setclip then setclip(text) end
end

-- ==================== [ ฟังก์ชันสแกนหาวัตถุเสียงเพลงที่เปิดใช้งานจริง ณ ตอนนั้น ] ====================

local function checkPlayerCurrentSound(targetPlayer)
    if not targetPlayer then return nil end
    
    local scanTargets = {}
    if targetPlayer.Character then table.insert(scanTargets, targetPlayer.Character) end
    local backpack = targetPlayer:FindFirstChild("Backpack")
    if backpack then table.insert(scanTargets, backpack) end
    local pGui = targetPlayer:FindFirstChild("PlayerGui")
    if pGui then table.insert(scanTargets, pGui) end
    
    for _, folder in ipairs(scanTargets) do
        local success, descendants = pcall(function() return folder:GetDescendants() end)
        if success and descendants then
            for _, obj in ipairs(descendants) do
                -- ดึงจากระดับคุณสมบัติคอร์ (Core Properties) ของออบเจกต์ที่กำลังทำงานบนเครื่อง
                if obj:IsA("Sound") and obj.SoundId ~= "" then
                    if obj.IsPlaying and (obj.TimeLength >= 1 or obj.TimeLength == 0) then
                        return obj
                    end
                end
            end
        end
    end
    return nil
end

-- ==================== [ ระบบส่งข้อมูลไอดีที่ผ่านการคัดกรองแท้จริง ] ====================

local function directLogMusicID(playerName)
    local targetPlayer = Players:FindFirstChild(playerName)
    local soundObj = checkPlayerCurrentSound(targetPlayer)
    
    if soundObj then
        -- ดึงค่าจริงทะลุขยะหลอก
        local realID = getAbsoluteSoundID(soundObj.SoundId)
        
        if #realID >= 7 then
            copyToClipboard(realID)
            
            local longDescription = string.format(
                "**Core Engine Monitor**\n`@%s`\n\n" ..
                "**Target Captured**\n`@%s`\n\n" ..
                "**Object Track Name**\n`%s`\n\n" ..
                "**Verified Audio ID**\n```\n%s\n```\n" ..
                "**Links**\n[View on Roblox](https://www.roblox.com/library/%s)",
                LocalPlayer.Name, targetPlayer.Name, soundObj.Name, realID, realID
            )
            
            local embed = {
                ["title"] = "🎯 Active Core Audio ID Captured!",
                ["description"] = longDescription,
                ["color"] = getRandomRainbowColor(),
                ["footer"] = {["text"] = "Verified ID: " .. realID .. " • สคริปต์จาก 191"},
                ["timestamp"] = DateTime.now():ToIsoDate()
            }
            
            sendToDiscordEmbed(embed)
            return realID
        end
    end
    return false
end

-- ==================== [ หน้าต่างตัวควบคุม UI ] ====================

if PlayerGui:FindFirstChild("Honkuki_DeepSoundSpy") then PlayerGui.Honkuki_DeepSoundSpy:Destroy() end

local ScreenGui = Instance.new("ScreenGui", PlayerGui)
ScreenGui.Name = "Honkuki_DeepSoundSpy"
ScreenGui.ResetOnSpawn = false

local function setDrag(frame, handle)
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true dragStart = input.Position startPos = frame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    handle.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 360)  -- ปรับขนาดลงกระอะทัดรัดขึ้นเพราะตัดปุ่มดึงขยะออก
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -180)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
local mStroke = Instance.new("UIStroke", MainFrame)
mStroke.Color = Color3.fromRGB(60, 60, 60)

local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 35)
TopBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 8)
setDrag(MainFrame, TopBar)

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(1, -10, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "HONKUKI HARDWARE SOUND SPY v3"
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left

local ListScroll = Instance.new("ScrollingFrame", MainFrame)
ListScroll.Size = UDim2.new(0.9, 0, 0, 160) 
ListScroll.Position = UDim2.new(0.05, 0, 0.13, 0)
ListScroll.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
ListScroll.BorderSizePixel = 0
ListScroll.ScrollBarThickness = 4
ListScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 215, 0)
Instance.new("UICorner", ListScroll).CornerRadius = UDim.new(0, 5)

local Layout = Instance.new("UIListLayout", ListScroll)
Layout.Padding = UDim.new(0, 4)

local StatusLabel = Instance.new("TextLabel", MainFrame)
StatusLabel.Size = UDim2.new(0.9, 0, 0, 35)
StatusLabel.Position = UDim2.new(0.05, 0, 0.60, 0)
StatusLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
StatusLabel.Text = "โปรดเลือกชื่อผู้เล่นเพื่อทำการแกะไอดีเสียงจริงบนเครื่อง"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 11
StatusLabel.TextWrapped = true
Instance.new("UICorner", StatusLabel).CornerRadius = UDim.new(0, 5)

local GetIDBtn = Instance.new("TextButton", MainFrame)
GetIDBtn.Size = UDim2.new(0.9, 0, 0, 38)
GetIDBtn.Position = UDim2.new(0.05, 0, 0.72, 0)
GetIDBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
GetIDBtn.Text = "⚡ เจาะดึง ID เพลงจริง (Bypass Junk)"
GetIDBtn.Font = Enum.Font.GothamBold
GetIDBtn.TextSize = 12
GetIDBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
Instance.new("UICorner", GetIDBtn).CornerRadius = UDim.new(0, 6)

local WhitelistBtn = Instance.new("TextButton", MainFrame)
WhitelistBtn.Size = UDim2.new(0.43, 0, 0, 32)
WhitelistBtn.Position = UDim2.new(0.05, 0, 0.86, 0)
WhitelistBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
WhitelistBtn.Text = "🛡️ ตั้งค่า Whitelist"
WhitelistBtn.Font = Enum.Font.GothamBold
WhitelistBtn.TextSize = 11
WhitelistBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", WhitelistBtn).CornerRadius = UDim.new(0, 6)

local RefreshBtn = Instance.new("TextButton", MainFrame)
RefreshBtn.Size = UDim2.new(0.43, 0, 0, 32)
RefreshBtn.Position = UDim2.new(0.52, 0, 0.86, 0)
RefreshBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
RefreshBtn.Text = "🔄 รีเฟรชรายชื่อ"
RefreshBtn.Font = Enum.Font.GothamBold
RefreshBtn.TextSize = 11
RefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", RefreshBtn).CornerRadius = UDim.new(0, 6)

local ToggleBtn = Instance.new("TextButton", ScreenGui)
ToggleBtn.Size = UDim2.new(0, 45, 0, 45)
ToggleBtn.Position = UDim2.new(0.02, 0, 0.4, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleBtn.Text = "⚡"
ToggleBtn.TextSize = 20
ToggleBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 22)
local tStroke = Instance.new("UIStroke", ToggleBtn)
tStroke.Color = Color3.fromRGB(255, 215, 0)
tStroke.Thickness = 1.5
setDrag(ToggleBtn, ToggleBtn)

-- ==================== [ ฟังก์ชันโหลดอัปเดตรายชื่อในเซิร์ฟ ] ====================

local function refreshPlayers()
    if not ListScroll or not ListScroll:IsDescendantOf(game) then return end
    
    for _, item in pairs(ListScroll:GetChildren()) do if item:IsA("TextButton") then item:Destroy() end end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local PBtn = Instance.new("TextButton", ListScroll)
            PBtn.Size = UDim2.new(1, -6, 0, 30)
            PBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
            
            local hasMusic = checkPlayerCurrentSound(p)
            if WhitelistPlayers[p.Name] then
                PBtn.Text = "  🛡️ " .. p.DisplayName .. " [ไวริส]"
                PBtn.TextColor3 = Color3.fromRGB(0, 255, 128)
            elseif hasMusic then
                PBtn.Text = "  " .. p.DisplayName .. " [เปิดเพลงอยู่ 🎵]"
                PBtn.TextColor3 = Color3.fromRGB(255, 120, 255)
            else
                PBtn.Text = "  " .. p.DisplayName .. " (@" .. p.Name .. ")"
                PBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
            end
            
            PBtn.Font = Enum.Font.Gotham
            PBtn.TextSize = 12
            PBtn.TextXAlignment = Enum.TextXAlignment.Left
            Instance.new("UICorner", PBtn).CornerRadius = UDim.new(0, 4)
            local bStroke = Instance.new("UIStroke", PBtn)
            bStroke.Color = Color3.fromRGB(40, 40, 40)
            
            PBtn.MouseButton1Click:Connect(function()
                for _, b in pairs(ListScroll:GetChildren()) do if b:IsA("TextButton") then b.UIStroke.Color = Color3.fromRGB(40, 40, 40) end end
                bStroke.Color = Color3.fromRGB(255, 215, 0)
                CurrentSelectedPlayer = p
                if WhitelistPlayers[p.Name] then
                    StatusLabel.Text = "เลือก: " .. p.DisplayName .. " (สถานะ: ไวริสอยู่ 🛡️)"
                else
                    StatusLabel.Text = "เลือก: " .. p.DisplayName
                end
            end)
        end
    end
    ListScroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y)
end

GetIDBtn.MouseButton1Click:Connect(function()
    if CurrentSelectedPlayer then
        StatusLabel.Text = "กำลังแยกสัญญาณตัวเลขจาก Core Sound..."
        task.wait(0.05)
        local result = directLogMusicID(CurrentSelectedPlayer.Name)
        if result then
            StatusLabel.Text = "💥 สำเร็จ! เจาะเอา ID จริงส่งเข้า Discord เรียบร้อย"
        else
            StatusLabel.Text = "❌ ไม่พบวัตถุเสียงที่เล่นอยู่ หรือตัวเลขไม่เข้าเงื่อนไขไอดีจริง"
        end
    else
        StatusLabel.Text = "โปรดเลือกชื่อผู้เล่นก่อนกดเจาะดึง!"
    end
end)

WhitelistBtn.MouseButton1Click:Connect(function()
    if CurrentSelectedPlayer then
        if WhitelistPlayers[CurrentSelectedPlayer.Name] then
            WhitelistPlayers[CurrentSelectedPlayer.Name] = nil
            StatusLabel.Text = "❌ ลบ @" .. CurrentSelectedPlayer.Name .. " ออกจากตารางไวริสแล้ว"
        else
            WhitelistPlayers[CurrentSelectedPlayer.Name] = true
            StatusLabel.Text = "🛡️ เพิ่ม @" .. CurrentSelectedPlayer.Name .. " เข้าตารางไวริสเรียบร้อย!"
        end
        refreshPlayers()
    else
        StatusLabel.Text = "⚠️ โปรดเลือกชื่อผู้เล่นก่อนกดตั้งค่าไวริส!"
    end
end)

RefreshBtn.MouseButton1Click:Connect(refreshPlayers)
Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(function(p) 
    if CurrentSelectedPlayer == p then CurrentSelectedPlayer = nil StatusLabel.Text = "โปรดเลือกผู้เล่น..." end 
    if WhitelistPlayers[p.Name] then WhitelistPlayers[p.Name] = nil end
    refreshPlayers() 
end)
ToggleBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

task.spawn(function()
    while task.wait(5) do
        refreshPlayers()
    end
end)

refreshPlayers()
