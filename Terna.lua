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

-- 🛡️ ระบบจัดเก็บคัดกรองไอดีขยะครบถ้วนทั้งหมด (ล็อกไว้แก้ไขแค่ตรงนี้ตามสั่งมึง)
local JunkBlacklist = {
    ["300000000000000"] = true,
    ["129569049476734"] = true,
    ["106800577264015"] = true,
    ["1068005772640150093932829347443"] = true,
    ["102154442982549"] = true,
    ["82791323516669"] = true,
    ["83260119948695"] = true,
    ["81813976130913"] = true,
    ["130372250847248"] = true,
    ["137017155308361"] = true,
    ["83370097021520"] = true,
    ["126659616504291"] = true,
    ["19006509949"] = true,
    ["96774521681190"] = true,
    ["135159509633580"] = true,
    ["114870502995953"] = true,
    ["112304110902021"] = true,
    ["99721399503975"] = true,
    ["116331922770563"] = true,
    ["137434811238124"] = true,
    ["117391349741339"] = true,
    ["120313493879944"] = true,
    ["112210298860778"] = true,
    ["137555839480738"] = true,
    ["115819698454027"] = true,
    ["101631982347841"] = true,
    ["97254689160075"] = true,
    ["90634248855281"] = true,
    ["139822448198319"] = true,
    ["13370097021520"] = true,
    ["138058631419886"] = true,
    ["140497415402103"] = true,
    ["137632553110798"] = true,
    ["132565074561820"] = true,
    ["135717653489469"] = true,
    ["117978901016225"] = true,
    ["131120650233515"] = true,
    ["136038459746844"] = true,
    ["122209668269742"] = true,
    ["120104871360327"] = true,
    ["119215996902118"] = true,
    ["0079081439699719"] = true,
    ["79081439699719"] = true,
    ["0075803753062002"] = true,
    ["75803753062002"] = true,
    ["00104007943345258"] = true, 
    ["104007943345258"] = true,
    ["00109462618039650"] = true,
    ["109462618039650"] = true,
    ["0093932829347443"] = true,
    ["93932829347443"] = true,
    ["000000000000000000000000000000000000000000000000"] = true,
    ["0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"] = true,
    ["123728962822472"] = true,
    ["122929786531506"] = true,
    ["90308298517537"] = true,
    ["00"] = true,
}

local function getCleanID(soundIdStr)
    if type(soundIdStr) ~= "string" then return "" end
    local decoded = urlDecode(soundIdStr)
    decoded = hexDecode(decoded)
    decoded = string.gsub(decoded, "%%3", "")
    decoded = string.lower(decoded)
    
    local cleanStr = decoded
    local junkPatterns = {"69d=00", "=00", "id=", "song=", "assetid=", "music=", "&="}
    for _, pattern in ipairs(junkPatterns) do
        if string.find(cleanStr, pattern) then
            local segments = string.split(cleanStr, pattern)
            for i = #segments, 1, -1 do
                if string.match(segments[i], "%d+") then cleanStr = segments[i] break end
            end
        end
    end
    
    local numberBlocks = {}
    for num in string.gmatch(cleanStr, "%d+") do
        if #num >= 7 then
            local checkNum = string.gsub(num, "^0+", "")
            if not string.match(checkNum, "^1340") and not JunkBlacklist[checkNum] and not JunkBlacklist[num] then
                table.insert(numberBlocks, num)
            end
        end
    end
    
    if #numberBlocks == 0 then
        for num in string.gmatch(decoded, "%d+") do
            if #num >= 7 then 
                local checkNum = string.gsub(num, "^0+", "")
                if not string.match(checkNum, "^1340") and not JunkBlacklist[checkNum] and not JunkBlacklist[num] then
                    table.insert(numberBlocks, num)
                end
            end
        end
    end
    
    if #numberBlocks > 0 then
        local firstID = numberBlocks[1]
        local lastID = numberBlocks[#numberBlocks]
        if #lastID >= #firstID then return lastID else return firstID end
    end
    
    for num in string.gmatch(soundIdStr, "%d+") do
        local checkNum = string.gsub(num, "^0+", "")
        if #num >= 7 and not string.match(checkNum, "^1340") and not JunkBlacklist[checkNum] and not JunkBlacklist[num] then 
            return num 
        end
    end
    return string.match(soundIdStr, "%d+") or ""
end

local function copyToClipboard(text)
    local setclip = setclipboard or toclipboard or (Clipboard and Clipboard.set)
    if setclip then setclip(text) end
end

-- ==================== [ ฟังก์ชันเช็ควัตถุเสียงเพลงจริง (เวอร์ชันแก้โค้ดค้าง + บล็อกเสียงพร้อพชัวร์ๆ) ] ====================

local function checkPlayerCurrentSound(targetPlayer)
    if not targetPlayer then return nil end
    
    local scanTargets = {}
    if targetPlayer.Character then table.insert(scanTargets, targetPlayer.Character) end
    local backpack = targetPlayer:FindFirstChild("Backpack")
    if backpack then table.insert(scanTargets, backpack) end
    local pGui = targetPlayer:FindFirstChild("PlayerGui")
    if pGui then table.insert(scanTargets, pGui) end
    
    -- บัญชีดำชื่อเสียงขยะจากพวกบอร์ดและรถ (เอาคำว่า sound ออกเพราะไปทับชื่อวิทยุบางตัว)
    local NameBlacklist = {
        ["roll"] = true, ["clips"] = true, ["engine"] = true, 
        ["pitch"] = true, ["drive"] = true, ["skateboardsound"] = true, ["hoverdrive"] = true,
        ["idle"] = true, ["move"] = true, ["spark"] = true, ["spin"] = true, ["thrust"] = true
    }
    
    for _, folder in ipairs(scanTargets) do
        local success, descendants = pcall(function() return folder:GetDescendants() end)
        if success and descendants then
            for _, obj in ipairs(descendants) do
                if obj:IsA("Sound") and obj.SoundId ~= "" then
                    if obj.IsPlaying and (obj.Looped or obj.TimeLength > 10 or obj.TimeLength == 0) then
                        
                        local soundNameLower = string.lower(obj.Name)
                        
                        if not NameBlacklist[soundNameLower] then
                            -- ตัดเสียงเดินมาตรฐานออก
                            if obj.Name ~= "GettingUp" and obj.Name ~= "Died" and obj.Name ~= "FreeFalling" and obj.Name ~= "Jumping" and obj.Name ~= "Landing" and obj.Name ~= "Running" and obj.Name ~= "Splash" and obj.Name ~= "Swimming" and obj.Name ~= "Climbing" then
                                
                                -- ล้อม pcall ป้องกันกรณีออบเจกต์ถูกทำลายกระทันหันในแมพ ไม่ให้โค้ดค้าง
                                local isVehicleSound = false
                                pcall(function()
                                    local currentParent = obj.Parent
                                    for i = 1, 4 do
                                        if currentParent and currentParent ~= game then
                                            local parentName = string.lower(currentParent.Name)
                                            if string.find(parentName, "wheel") or string.find(parentName, "skate") or string.find(parentName, "hover") or string.find(parentName, "vehicle") or string.find(parentName, "motor") or string.find(parentName, "car") then
                                                isVehicleSound = true
                                                break
                                            end
                                            currentParent = currentParent.Parent
                                        else
                                            break
                                        end
                                    end
                                end)
                                
                                if not isVehicleSound then
                                    return obj
                                end
                                
                            end
                        end
                        
                    end
                end
            end
        end
    end
    return nil
end

-- ==================== [ ระบบส่งแบบกรอบข้อความแนวตั้ง ] ====================

local function directLogMusicID(playerName)
    local targetPlayer = Players:FindFirstChild(playerName)
    local soundObj = checkPlayerCurrentSound(targetPlayer)
    
    if soundObj then
        local cleanID = getCleanID(soundObj.SoundId)
        
        if #cleanID >= 7 then
            copyToClipboard(cleanID)
            
            local longDescription = string.format(
                "**Spy Executor**\n`@%s`\n\n" ..
                "**Target Player**\n`@%s`\n\n" ..
                "**Audio Object Name**\n`%s`\n\n" ..
                "**Audio ID**\n```\n%s\n```\n" ..
                "**Links**\n[View on Roblox](https://www.roblox.com/library/%s)",
                LocalPlayer.Name, targetPlayer.Name, soundObj.Name, cleanID, cleanID
            )
            
            local embed = {
                ["title"] = "🎵 New Deep Sound Decoded Audio!",
                ["description"] = longDescription,
                ["color"] = getRandomRainbowColor(),
                ["footer"] = {["text"] = "Audio ID: " .. cleanID .. " • สคริปต์จาก 191"},
                ["timestamp"] = DateTime.now():ToIsoDate()
            }
            
            sendToDiscordEmbed(embed)
            return cleanID
        end
    end
    return false
end

local function directLogRawJunk(playerName)
    local targetPlayer = Players:FindFirstChild(playerName)
    local soundObj = checkPlayerCurrentSound(targetPlayer)
    
    if soundObj then
        local cleanCheck = getCleanID(soundObj.SoundId)
        if #cleanCheck >= 7 then
            local rawJunk = soundObj.SoundId
            copyToClipboard(rawJunk)
            
            local fileData = string.format(
                "=== HONKUKI RAW JUNK LOG ===\nRun By: @%s\nTarget: @%s\nSound Name: %s\n============================\n\n[RAW DATA]:\n%s",
                LocalPlayer.Name, targetPlayer.Name, soundObj.Name, rawJunk
            )
            
            local txtFileName = "raw_junk_" .. targetPlayer.Name .. ".txt"
            
            local longDescription = string.format(
                "**Junk Collector**\n`@%s`\n\n" ..
                "**Target Block**\n`@%s`\n\n" ..
                "**Attachment File Status**\n`ระบบได้ทำการสร้าง %s อัปโหลดแนบไว้ด้านล่างกล่องนี้เรียบร้อยแล้วมึง!`",
                LocalPlayer.Name, targetPlayer.Name, soundObj.Name, txtFileName
            )
            
            local embed = {
                ["title"] = "📦 New Raw Junk Dumped Log!",
                ["description"] = longDescription,
                ["color"] = getRandomRainbowColor(),
                ["footer"] = {["text"] = "Raw Text Captured • สคริปต์จาก 191"},
                ["timestamp"] = DateTime.now():ToIsoDate()
            }
            
            sendToDiscordFile(txtFileName, fileData, embed)
            return true
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
Title.Text = "HONKUKI DEEP SOUND SCANNER v2"
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
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
StatusLabel.Text = "โปรดเลือกชื่อผู้เล่นเพื่อทำการสแกนดีโค้ดเพลงจริง"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 11
StatusLabel.TextWrapped = true
Instance.new("UICorner", StatusLabel).CornerRadius = UDim.new(0, 5)

local GetIDBtn = Instance.new("TextButton", MainFrame)
GetIDBtn.Size = UDim2.new(0.9, 0, 0, 36)
GetIDBtn.Position = UDim2.new(0.05, 0, 0.60, 0)
GetIDBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
GetIDBtn.Text = "🔍 ดึง ID เพลง (แกะ DECODE เลขจริง)"
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
            
            local hasMusic = checkPlayerCurrentSound(p)
            if WhitelistPlayers[p.Name] then
                PBtn.Text = "  🛡️ " .. p.DisplayName .. " (@" .. p.Name .. ") [ไวริส]"
                PBtn.TextColor3 = Color3.fromRGB(0, 255, 128)
            elseif hasMusic then
                PBtn.Text = "  " .. p.DisplayName .. " (@" .. p.Name .. ") [กำลังเปิดเพลง 🎵]"
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
        StatusLabel.Text = "กำลังถอดรหัสบัสและยิงเข้ากล่อง Embed..."
        task.wait(0.05)
        local result = directLogMusicID(CurrentSelectedPlayer.Name)
        if result then
            StatusLabel.Text = "💥 สำเร็จ! ยิงข้อมูลแบบเรียงดิ่งสุ่มสีเข้าดิสคอร์ดแล้ว"
        else
            StatusLabel.Text = "ไม่พบเพลงจริง (หรือไอดีต่ำกว่า 7 หลัก/ติด Blacklist/เสียงแมพ)"
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
