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

-- ==================== [ ฟังก์ชันหาฟังก์ชัน Request ที่ปลอดภัยที่สุด ] ====================
local function getHttpRequest()
    if request then return request end
    if http_request then return http_request end
    if syn and type(syn) == "table" and syn.request then return syn.request end
    if http and type(http) == "table" and http.request then return http.request end
    return nil
end

-- ==================== [ ฟังก์ชันสุ่มแถบสีรุ้งข้างกรอบ Embed ] ====================
local function getRandomRainbowColor()
    local colors = {16711680, 16744192, 16776960, 65280, 65535, 255, 16711935}
    return colors[math.random(1, #colors)]
end

-- ==================== [ ฟังก์ชันส่งข้อมูลเข้า Discord Webhook ] ====================
local function sendToDiscordEmbed(embedData)
    local httpRequest = getHttpRequest()
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
    local httpRequest = getHttpRequest()
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

-- ==================== [ ระบบถอดรหัสและดึง ID เดิมของมึง (ห้ามแตะ) ] ====================

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

local function getAllIDsFromSound(soundIdStr)
    if type(soundIdStr) ~= "string" then return {} end
    local decoded = urlDecode(soundIdStr)
    decoded = hexDecode(decoded)
    decoded = string.gsub(decoded, "%%3", "")
    decoded = string.lower(decoded)
    
    local foundIDs = {}
    local duplicates = {}
    
    local IDBlacklist = {
        ["300000000000000"] = true,
        ["82791323516669"] = true
    }
    
    local function validateAndInsert(num)
        if #num >= 7 and #num <= 12 and not duplicates[num] and not IDBlacklist[num] then
            local checkNum = string.gsub(num, "^0+", "")
            if not string.match(checkNum, "^1340") and #checkNum >= 7 then
                duplicates[num] = true
                table.insert(foundIDs, num)
            end
        end
    end
    
    for num in string.gmatch(decoded, "%d+") do
        validateAndInsert(num)
    end
    
    if #foundIDs == 0 then
        for num in string.gmatch(soundIdStr, "%d+") do
            validateAndInsert(num)
        end
    end
    
    return foundIDs
end

local function copyToClipboard(text)
    local setclip = setclipboard or toclipboard or (Clipboard and Clipboard.set)
    if setclip then setclip(text) end
end

-- ==================== [ ฟังก์ชันเช็ควัตถุเสียงเพลงบนตัวผู้เล่น ] ====================

local function checkPlayerAllSounds(targetPlayer)
    if not targetPlayer then return {} end
    
    local scanTargets = {}
    if targetPlayer.Character then table.insert(scanTargets, targetPlayer.Character) end
    local backpack = targetPlayer:FindFirstChild("Backpack")
    if backpack then table.insert(scanTargets, backpack) end
    local pGui = targetPlayer:FindFirstChild("PlayerGui")
    if pGui then table.insert(scanTargets, pGui) end
    
    local validSounds = {}
    
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

-- ================ [ ฟังก์ชันกรองเฉพาะ ID 15 หลัก ] =================
local function filter15DigitIDs(ids)
    local result = {}
    for _, id in ipairs(ids) do
        if type(id) == "string" and #id == 15 and tonumber(id) then
            table.insert(result, id)
        end
    end
    return result
end

-- ==================== [ ปุ่มดึงแบบเจาะ (เฉพาะ 15 หลัก + ตรวจสอบความยาว) ] ====================
local function directLogMusicID(playerName)
    local targetPlayer = Players:FindFirstChild(playerName)
    local soundObjects = checkPlayerAllSounds(targetPlayer)
    
    if #soundObjects == 0 then return false end
    
    -- ตารางเก็บข้อมูล ID แต่ละตัว: id -> { timeLength, soundName }
    local idData = {}
    
    for _, soundObj in ipairs(soundObjects) do
        local ids = getAllIDsFromSound(soundObj.SoundId)
        local filtered = filter15DigitIDs(ids)
        if #filtered > 0 then
            -- อ่านความยาวของไฟล์เสียง (TimeLength)
            local timeLen = soundObj.TimeLength or 0
            -- ถ้ายังเป็น 0 ให้รอสักครู่แล้วลองใหม่ (บางครั้งโหลดช้า)
            if timeLen == 0 then
                task.wait(0.2)
                timeLen = soundObj.TimeLength or 0
            end
            
            for _, id in ipairs(filtered) do
                -- ถ้ายังไม่มี id นี้ในตาราง หรือมีแล้วแต่ timeLen มากกว่า ให้เก็บค่าสูงสุด
                if not idData[id] then
                    idData[id] = { timeLength = timeLen, soundName = soundObj.Name }
                else
                    if timeLen > idData[id].timeLength then
                        idData[id].timeLength = timeLen
                        idData[id].soundName = soundObj.Name
                    end
                end
            end
        end
    end
    
    if next(idData) == nil then return false end
    
    -- แยก ID จริง (>=60s) และ ID หลอก (<60s)
    local realIDs = {}
    local fakeIDs = {}
    for id, info in pairs(idData) do
        if info.timeLength >= 60 then
            table.insert(realIDs, {id = id, len = info.timeLength})
        else
            table.insert(fakeIDs, {id = id, len = info.timeLength})
        end
    end
    
    -- เรียงลำดับตาม ID
    table.sort(realIDs, function(a,b) return a.id < b.id end)
    table.sort(fakeIDs, function(a,b) return a.id < b.id end)
    
    -- สร้างข้อความแสดงรายการ
    local listStr = ""
    if #realIDs > 0 then
        listStr = listStr .. "**✅ REAL IDs (≥60s):**\n"
        for i, item in ipairs(realIDs) do
            listStr = listStr .. string.format("%02d. `%s` (%.1f sec)\n", i, item.id, item.len)
        end
    end
    if #fakeIDs > 0 then
        if #realIDs > 0 then listStr = listStr .. "\n" end
        listStr = listStr .. "**❌ FAKE IDs (<60s):**\n"
        for i, item in ipairs(fakeIDs) do
            listStr = listStr .. string.format("%02d. `%s` (%.1f sec)\n", i, item.id, item.len)
        end
    end
    
    -- คัดลอก ID ตัวแรก (ถ้ามี Real ให้ใช้ Real ตัวแรก ไม่เช่นนั้นใช้ Fake ตัวแรก)
    local copyId
    if #realIDs > 0 then
        copyId = realIDs[1].id
    elseif #fakeIDs > 0 then
        copyId = fakeIDs[1].id
    else
        -- fallback (ไม่น่าจะเกิด)
        copyId = next(idData)
    end
    copyToClipboard(copyId)
    
    local longDescription = string.format(
        "**Spy Executor:** `@%s`\n" ..
        "**Target Player:** `@%s`\n\n" ..
        "**📊 สรุป:** `%d Real IDs` , `%d Fake IDs`\n\n" ..
        "%s\n" ..
        "*คัดลอก ID แรก (จัดลำดับ Real ก่อน) ไปคลิปบอร์ดแล้ว*",
        LocalPlayer.Name, targetPlayer.Name, #realIDs, #fakeIDs, listStr
    )
    
    local embed = {
        ["title"] = "🎵 Audio ID Validator (15‑digit + Duration Check)",
        ["description"] = longDescription,
        ["color"] = getRandomRainbowColor(),
        ["footer"] = {["text"] = "Real/Fake Classifier • สคริปต์จาก 191"},
        ["timestamp"] = DateTime.now():ToIsoDate()
    }
    
    sendToDiscordEmbed(embed)
    return true
end

-- ==================== [ ปุ่มดึงขยะ Raw ดิบ (ทุกเสียง) ] ====================
local function directLogRawJunk(playerName)
    local targetPlayer = Players:FindFirstChild(playerName)
    local soundObjects = checkPlayerAllSounds(targetPlayer)
    
    if #soundObjects == 0 then return false end
    
    -- รวบรวม SoundId ดิบของทุกเสียง
    local rawDump = {}
    for i, soundObj in ipairs(soundObjects) do
        table.insert(rawDump, string.format(
            "Sound #%02d | Name: %s | SoundId: %s",
            i, soundObj.Name, soundObj.SoundId
        ))
    end
    
    local rawJunkAll = table.concat(rawDump, "\n")
    local fullDump = string.format(
        "=== RAW JUNK DUMP (ALL SOUNDS) ===\nRun By: @%s\nTarget: @%s\nTotal Sounds: %d\n=======================================\n\n%s",
        LocalPlayer.Name, targetPlayer.Name, #soundObjects, rawJunkAll
    )
    
    -- คัดลอก SoundId ตัวแรก (ดิบ) เข้าคลิปบอร์ด (ตามเดิม)
    if #soundObjects > 0 then
        copyToClipboard(soundObjects[1].SoundId)
    end
    
    local txtFileName = "raw_junk_all_" .. targetPlayer.Name .. ".txt"
    local longDescription = string.format(
        "**Junk Collector:** `@%s`\n" ..
        "**Target Block:** `@%s`\n" ..
        "**Dump Status:** `สกัด SoundId ดิบทั้งหมด (%d เสียง) สำเร็จ!`",
        LocalPlayer.Name, targetPlayer.Name, #soundObjects
    )
    
    local embed = {
        ["title"] = "Strict Raw Text Dumped Log (All Sounds)",
        ["description"] = longDescription,
        ["color"] = getRandomRainbowColor(),
        ["footer"] = {["text"] = "Raw All Sounds • สคริปต์จาก 191"},
        ["timestamp"] = DateTime.now():ToIsoDate()
    }
    
    sendToDiscordFile(txtFileName, fullDump, embed)
    return true
end

-- ==================== [ หน้าต่างควบคุม UI (เหมือนเดิม) ] ====================

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
StatusLabel.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
StatusLabel.BackgroundTransparency = 0.9
StatusLabel.Text = "ระบบดึงส่งตรงทำงานปกติ (คัดกรองอัตโนมัติที่หลังบ้าน)"
StatusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 11
StatusLabel.TextWrapped = true
Instance.new("UICorner", StatusLabel).CornerRadius = UDim.new(0, 5)

local GetIDBtn = Instance.new("TextButton", MainFrame)
GetIDBtn.Size = UDim2.new(0.9, 0, 0, 36)
GetIDBtn.Position = UDim2.new(0.05, 0, 0.60, 0)
GetIDBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
GetIDBtn.Text = "เจาะและดึงไอดีตามจริงทั้งหมด (Direct Log)"
GetIDBtn.Font = Enum.Font.GothamBold
GetIDBtn.TextSize = 12
GetIDBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
Instance.new("UICorner", GetIDBtn).CornerRadius = UDim.new(0, 6)

local GetJunkBtn = Instance.new("TextButton", MainFrame)
GetJunkBtn.Size = UDim2.new(0.9, 0, 0, 36)
GetJunkBtn.Position = UDim2.new(0.05, 0, 0.70, 0)
GetJunkBtn.BackgroundColor3 = Color3.fromRGB(230, 90, 40) 
GetJunkBtn.Text = "ดึงข้อความ Junk (สร้างเป็นไฟล์ข้อความ)"
GetJunkBtn.Font = Enum.Font.GothamBold
GetJunkBtn.TextSize = 12
GetJunkBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", GetJunkBtn).CornerRadius = UDim.new(0, 6)

local WhitelistBtn = Instance.new("TextButton", MainFrame)
WhitelistBtn.Size = UDim2.new(0.9, 0, 0, 34)
WhitelistBtn.Position = UDim2.new(0.05, 0, 0.80, 0)
WhitelistBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
WhitelistBtn.Text = "เพิ่ม / ลบ รายชื่อไวริส (Whitelist)"
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
                    StatusLabel.Text = "เลือก: " .. p.DisplayName .. " (@" .. p.Name .. ") (สถานะ: ไวริสอยู่)"
                else
                    StatusLabel.Text = "เลือก: " .. p.DisplayName .. " (@" .. p.Name .. ")"
                end
            end)
        end
    end
    ListScroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y)
end

-- ==================== [ ปุ่มกดทำงาน ] ====================

GetIDBtn.MouseButton1Click:Connect(function()
    if CurrentSelectedPlayer then
        StatusLabel.Text = "🔍 กำลังเจาะ ID 15 หลักและตรวจสอบความยาว..."
        task.wait(0.05)
        local result = directLogMusicID(CurrentSelectedPlayer.Name)
        if result then
            StatusLabel.Text = "✅ สำเร็จ! ส่ง ID แยกจริง/หลอกขึ้นดิสแล้ว (คัดลอก ID จริงตัวแรก)"
        else
            StatusLabel.Text = "❌ ไม่พบ ID 15 หลักใด ๆ บนตัวผู้เล่นคนนี้"
        end
    else
        StatusLabel.Text = "⚠️ โปรดเลือกชื่อผู้เล่นก่อนกดดึง!"
    end
end)

GetJunkBtn.MouseButton1Click:Connect(function()
    if CurrentSelectedPlayer then
        StatusLabel.Text = "📦 กำลังดึงข้อมูลขยะดิบ (ทุกเสียง)..."
        task.wait(0.05)
        local result = directLogRawJunk(CurrentSelectedPlayer.Name)
        if result then
            StatusLabel.Text = "✅ สำเร็จ! ส่งไฟล์ขยะดิบทั้งหมดเรียบร้อย"
        else
            StatusLabel.Text = "❌ ไม่พบเสียงใด ๆ บนตัวผู้เล่นนี้"
        end
    else
        StatusLabel.Text = "⚠️ โปรดเลือกชื่อผู้เล่นก่อนกดดึง!"
    end
end)

WhitelistBtn.MouseButton1Click:Connect(function()
    if CurrentSelectedPlayer then
        if WhitelistPlayers[CurrentSelectedPlayer.Name] then
            WhitelistPlayers[CurrentSelectedPlayer.Name] = nil
            StatusLabel.Text = "🗑️ ลบ @" .. CurrentSelectedPlayer.Name .. " ออกจากตารางไวริสแล้ว"
        else
            WhitelistPlayers[CurrentSelectedPlayer.Name] = true
            StatusLabel.Text = "✅ เพิ่ม @" .. CurrentSelectedPlayer.Name .. " เข้าตารางไวริสเรียบร้อย!"
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
