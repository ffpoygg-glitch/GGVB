-- =====================================================
-- HONKUKI DEEP VALIDATOR SCANNER (ALL-IN-ONE)
-- แก้ไขระบบแยก Real/Fake ให้แม่นยำขึ้น
-- ตรวจสอบ AssetTypeId และ Duration จาก Roblox API
-- =====================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

local CurrentSelectedPlayer = nil
local WebhookURL = "https://discord.com/api/webhooks/1520312240782442536/ZQ5nuEq80B9ZcrH7nDpjvFYIcXVRbhAqjRkF7Szsj2aHDF9Tm1TIJ9VVOVu6Nu91BE9a"
local WhitelistPlayers = {}

-- ==================== บล็อค ID ปลอมทั้งหมด ====================
local BlockedIDs = {
    ["00106800577264015"] = true, ["00109462618039650"] = true,
    ["00112583972042063"] = true, ["00113841533670628"] = true,
    ["00116872955970254"] = true, ["00117424747387525"] = true,
    ["00117628371363749"] = true, ["00121320825772761"] = true,
    ["00125329595131078"] = true, ["00129043827992035"] = true,
    ["00134076916421685"] = true, ["00134523838494464"] = true,
    ["00137058099826867"] = true, ["00138763959207625"] = true,
    ["0070567654933546"] = true, ["0079688020178596"] = true,
    ["0083260119948695"] = true, ["0083681471562121"] = true,
    ["0083848201981900"] = true, ["0090308298517537"] = true,
    ["0093338918256962"] = true, ["0093932829347443"] = true,
    ["00"] = true, ["4"] = true, ["62"] = true, ["7"] = true,
    ["78899"] = true, ["83260119948695"] = true, ["9"] = true,
    ["00120104871360327"] = true, ["00129060362076134"] = true,
    ["101631982347841"] = true, ["112210298860778"] = true,
    ["115819698454027"] = true, ["116331922770563"] = true,
    ["117391349741339"] = true, ["117871196330268"] = true,
    ["120313493879944"] = true, ["134216333534795"] = true,
    ["137555839480738"] = true, ["140497415402103"] = true,
    ["54410081542"] = true, ["70999314371231"] = true,
    ["71352236"] = true, ["76500780055460"] = true,
    ["78515442941510"] = true, ["90533928572341"] = true,
    ["99721399503975"] = true,
    ["00101020203030404"] = true, ["00112233445566778"] = true,
    ["00123456789012345"] = true, ["00135791357913579"] = true,
    ["00159260374815926"] = true, ["00246802468024680"] = true,
    ["00405060708090001"] = true, ["00543210987654321"] = true,
    ["00731959731959731"] = true, ["00864208642086420"] = true,
    ["00887766554433221"] = true, ["00975319753197531"] = true,
    ["00987654321098765"] = true, ["00998877665544332"] = true,
    ["129569049476734"] = true, ["81067084464165"] = true
}

-- ==================== ฟังก์ชัน Helper ====================
local function getHttpRequest()
    if request then return request end
    if http_request then return http_request end
    if syn and type(syn) == "table" and syn.request then return syn.request end
    if http and type(http) == "table" and http.request then return http.request end
    return nil
end

local function getRandomRainbowColor()
    local colors = {16711680, 16744192, 16776960, 65280, 65535, 255, 16711935}
    return colors[math.random(1, #colors)]
end

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

local function deepDecode(str)
    if type(str) ~= "string" then return str end
    local prev
    repeat
        prev = str
        str = urlDecode(str)
        str = hexDecode(str)
    until str == prev
    return str
end

local function extractIDsFromPattern(text)
    local ids = {}
    local patterns = {
        "69%%64=([^&]*)", "&id=([^&]*)", "id=([^&]*)",
        "audio=([^&]*)", "song=([^&]*)", "music=([^&]*)",
        "%%69%%64=([^&]*)", "&%%69%%64=([^&]*)"
    }
    for _, pat in ipairs(patterns) do
        for capture in string.gmatch(text, pat) do
            for num in string.gmatch(capture, "%d+") do
                table.insert(ids, num)
            end
        end
    end
    return ids
end

local function isSoundFromPlayer(sound, player)
    if not sound or not player then return false end
    local character = player.Character
    local backpack = player:FindFirstChild("Backpack")
    local playerGui = player:FindFirstChild("PlayerGui")
    if character and sound:IsDescendantOf(character) then return true end
    if backpack and sound:IsDescendantOf(backpack) then return true end
    if playerGui and sound:IsDescendantOf(playerGui) then return true end
    return false
end

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
                    if not NameBlacklist[soundNameLower] and isSoundFromPlayer(obj, targetPlayer) then
                        table.insert(validSounds, obj)
                    end
                end
            end
        end
    end
    return validSounds
end

local function copyToClipboard(text)
    local setclip = setclipboard or toclipboard or (Clipboard and Clipboard.set)
    if setclip then setclip(text) end
end

-- ==================== ฟังก์ชันตรวจสอบ Asset (แบบ Async) ====================
local function getAssetInfoAsync(assetId, callback)
    local httpRequest = getHttpRequest()
    if not httpRequest then
        callback(nil)
        return
    end
    local url = "https://api.roblox.com/marketplace/productinfo?assetId=" .. tostring(assetId)
    task.spawn(function()
        local success, response = pcall(function()
            return httpRequest({
                Url = url,
                Method = "GET",
                Headers = {["Content-Type"] = "application/json"}
            })
        end)
        if success and response and response.StatusCode == 200 and response.Body then
            local data = HttpService:JSONDecode(response.Body)
            if data then
                -- ตรวจสอบว่าเป็น Audio หรือไม่ (AssetTypeId == 3)
                local assetTypeId = data.AssetTypeId
                local duration = data.Duration or 0
                local name = data.Name or ""
                callback({assetTypeId = assetTypeId, duration = duration, name = name})
                return
            end
        end
        callback(nil)
    end)
end

-- ==================== ฟังก์ชันหลักปุ่มเจาะ (แบบขนาน + เช็ค AssetTypeId) ====================
local function directLogMusicID(playerName)
    local targetPlayer = Players:FindFirstChild(playerName)
    local soundObjects = checkPlayerAllSounds(targetPlayer)
    if #soundObjects == 0 then return false end

    local rawIds = {}
    local totalFound = 0
    local totalBlocked = 0

    for _, soundObj in ipairs(soundObjects) do
        local rawId = soundObj.SoundId or ""
        local decoded = deepDecode(rawId)
        local searchText = (decoded ~= "" and decoded) or rawId

        local extractedIds = extractIDsFromPattern(searchText)
        if #extractedIds == 0 then
            for num in string.gmatch(searchText, "%d+") do
                table.insert(extractedIds, num)
            end
        end

        if #extractedIds > 0 then
            for _, id in ipairs(extractedIds) do
                totalFound = totalFound + 1
                if BlockedIDs[id] then
                    totalBlocked = totalBlocked + 1
                else
                    table.insert(rawIds, id)
                end
            end
        end
    end

    if #rawIds == 0 then
        local msg = "ไม่พบ ID ที่ไม่ถูกบล็อค (ถูกบล็อคทั้งหมด " .. totalBlocked .. " ตัว)"
        StatusLabel.Text = msg
        return false
    end

    -- เรียก API แบบขนานเพื่อดึงข้อมูล Asset
    local idData = {}
    local pendingCount = 0
    local completedCount = 0
    local maxAttempts = 15

    for _, id in ipairs(rawIds) do
        if not idData[id] then
            idData[id] = { checked = false, duration = 0, assetTypeId = nil, name = "" }
            pendingCount = pendingCount + 1
            getAssetInfoAsync(id, function(info)
                if info then
                    idData[id].duration = info.duration
                    idData[id].assetTypeId = info.assetTypeId
                    idData[id].name = info.name
                else
                    -- ถ้า API ไม่ตอบ ให้ถือว่าไม่ใช่ Audio
                    idData[id].duration = 0
                    idData[id].assetTypeId = 0
                end
                idData[id].checked = true
                completedCount = completedCount + 1
            end)
        end
    end

    -- รอให้ทุกตัวเสร็จ (หรือ timeout)
    local waitCount = 0
    while completedCount < pendingCount and waitCount < maxAttempts do
        task.wait(0.1)
        waitCount = waitCount + 1
    end

    -- ถ้ายังค้างอยู่ ให้ถือว่าไม่ใช่ Audio
    for id, info in pairs(idData) do
        if not info.checked then
            info.duration = 0
            info.assetTypeId = 0
            info.name = ""
        end
    end

    -- แยก Real / Fake โดยใช้ AssetTypeId และ Duration
    local realIDs = {}
    local fakeIDs = {}
    for id, info in pairs(idData) do
        -- เงื่อนไข Real: เป็น Audio (AssetTypeId == 3) และ Duration >= 60
        if info.assetTypeId == 3 and info.duration >= 60 then
            table.insert(realIDs, {id = id, len = info.duration, name = info.name})
        else
            table.insert(fakeIDs, {id = id, len = info.duration, typeId = info.assetTypeId})
        end
    end

    table.sort(realIDs, function(a,b) return a.id < b.id end)
    table.sort(fakeIDs, function(a,b) return a.id < b.id end)

    local listStr = ""
    if #realIDs > 0 then
        listStr = listStr .. "**✅ REAL IDs (Audio ≥60s):**\n"
        for i, item in ipairs(realIDs) do
            listStr = listStr .. string.format("%02d. `%s` (%.1f sec) – **%s**\n", i, item.id, item.len, item.name)
        end
    end
    if #fakeIDs > 0 then
        if #realIDs > 0 then listStr = listStr .. "\n" end
        listStr = listStr .. "**❌ FAKE IDs (ไม่ใช่ Audio หรือ <60s):**\n"
        for i, item in ipairs(fakeIDs) do
            local typeStr = (item.typeId == 3) and "Audio" or "ประเภท " .. tostring(item.typeId)
            listStr = listStr .. string.format("%02d. `%s` (%.1f sec) – %s\n", i, item.id, item.len, typeStr)
        end
    end

    -- คัดลอก Real IDs ทั้งหมด (ถ้ามี) หรือ Fake ตัวแรก
    local copyText = ""
    if #realIDs > 0 then
        for i, item in ipairs(realIDs) do
            if i > 1 then copyText = copyText .. " " end
            copyText = copyText .. item.id
        end
    elseif #fakeIDs > 0 then
        copyText = fakeIDs[1].id
    else
        copyText = next(idData)
    end
    copyToClipboard(copyText)

    local summary = string.format(
        "**พบทั้งหมด:** %d ID | **ถูกบล็อค:** %d | **Real:** %d | **Fake:** %d",
        totalFound, totalBlocked, #realIDs, #fakeIDs
    )

    local longDescription = string.format(
        "**Spy Executor:** `@%s`\n" ..
        "**Target Player:** `@%s`\n\n" ..
        "**📊 สรุป:** %s\n\n" ..
        "%s\n" ..
        "*คัดลอก ID จริงทั้งหมด (Audio ≥60s) ไปคลิปบอร์ดแล้ว*",
        LocalPlayer.Name, targetPlayer.Name, summary, listStr
    )

    local embed = {
        ["title"] = "🎵 Audio ID Validator (AssetTypeId + Duration)",
        ["description"] = longDescription,
        ["color"] = getRandomRainbowColor(),
        ["footer"] = {["text"] = "Real/Fake • ตรวจสอบ AssetTypeId • สคริปต์จาก 191"},
        ["timestamp"] = DateTime.now():ToIsoDate()
    }

    sendToDiscordEmbed(embed)
    return true
end

-- ==================== ปุ่มดึงขยะ ====================
local function directLogRawJunk(playerName)
    local targetPlayer = Players:FindFirstChild(playerName)
    local soundObjects = checkPlayerAllSounds(targetPlayer)
    if #soundObjects == 0 then return false end

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

-- =====================================================
-- ส่วน UI (ล็อกอิน + หน้าหลัก)
-- =====================================================
if PlayerGui:FindFirstChild("Honkuki_DeepSoundSpy") then PlayerGui.Honkuki_DeepSoundSpy:Destroy() end

local ScreenGui = Instance.new("ScreenGui", PlayerGui)
ScreenGui.Name = "Honkuki_DeepSoundSpy"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local function setDrag(frame, handle)
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ==================== หน้าต่างล็อกอิน ====================
local LoginFrame = Instance.new("Frame", ScreenGui)
LoginFrame.Size = UDim2.new(0, 320, 0, 180)
LoginFrame.Position = UDim2.new(0.5, -160, 0.5, -90)
LoginFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
LoginFrame.BorderSizePixel = 0
LoginFrame.ZIndex = 10
Instance.new("UICorner", LoginFrame).CornerRadius = UDim.new(0, 12)

local lStroke = Instance.new("UIStroke", LoginFrame)
lStroke.Color = Color3.fromRGB(255, 215, 0)
lStroke.Thickness = 2
lStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local LoginTitle = Instance.new("TextLabel", LoginFrame)
LoginTitle.Size = UDim2.new(1, 0, 0, 40)
LoginTitle.Position = UDim2.new(0, 0, 0, 5)
LoginTitle.BackgroundTransparency = 1
LoginTitle.Text = "🔐 HONKUKI DEEP SCANNER"
LoginTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
LoginTitle.Font = Enum.Font.GothamBold
LoginTitle.TextSize = 16
LoginTitle.TextXAlignment = Enum.TextXAlignment.Center
LoginTitle.ZIndex = 11

local LoginSub = Instance.new("TextLabel", LoginFrame)
LoginSub.Size = UDim2.new(1, 0, 0, 20)
LoginSub.Position = UDim2.new(0, 0, 0, 45)
LoginSub.BackgroundTransparency = 1
LoginSub.Text = "กรุณาป้อนรหัสผ่านเพื่อเข้าใช้งาน"
LoginSub.TextColor3 = Color3.fromRGB(180, 180, 180)
LoginSub.Font = Enum.Font.Gotham
LoginSub.TextSize = 12
LoginSub.TextXAlignment = Enum.TextXAlignment.Center
LoginSub.ZIndex = 11

local PasswordBox = Instance.new("TextBox", LoginFrame)
PasswordBox.Size = UDim2.new(0.8, 0, 0, 35)
PasswordBox.Position = UDim2.new(0.1, 0, 0.4, 0)
PasswordBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
PasswordBox.Text = ""
PasswordBox.PlaceholderText = "ป้อนรหัส..."
PasswordBox.TextColor3 = Color3.fromRGB(255, 255, 255)
PasswordBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
PasswordBox.Font = Enum.Font.Gotham
PasswordBox.TextSize = 14
PasswordBox.ClearTextOnFocus = false
PasswordBox.ZIndex = 11
Instance.new("UICorner", PasswordBox).CornerRadius = UDim.new(0, 6)

local LoginButton = Instance.new("TextButton", LoginFrame)
LoginButton.Size = UDim2.new(0.5, 0, 0, 35)
LoginButton.Position = UDim2.new(0.25, 0, 0.65, 0)
LoginButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
LoginButton.Text = "เข้าสู่ระบบ"
LoginButton.TextColor3 = Color3.fromRGB(15, 15, 15)
LoginButton.Font = Enum.Font.GothamBold
LoginButton.TextSize = 14
LoginButton.ZIndex = 11
Instance.new("UICorner", LoginButton).CornerRadius = UDim.new(0, 6)

local LoginError = Instance.new("TextLabel", LoginFrame)
LoginError.Size = UDim2.new(1, 0, 0, 20)
LoginError.Position = UDim2.new(0, 0, 0.85, 0)
LoginError.BackgroundTransparency = 1
LoginError.Text = ""
LoginError.TextColor3 = Color3.fromRGB(255, 80, 80)
LoginError.Font = Enum.Font.Gotham
LoginError.TextSize = 12
LoginError.TextXAlignment = Enum.TextXAlignment.Center
LoginError.ZIndex = 11

-- ==================== UI หลัก ====================
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 435)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -217)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.Visible = false
MainFrame.ZIndex = 1
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local mStroke = Instance.new("UIStroke", MainFrame)
mStroke.Color = Color3.fromRGB(60, 60, 60)
mStroke.Thickness = 1

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
StatusLabel.Text = "ระบบดึงส่งตรงทำงานปกติ (ตรวจสอบ AssetTypeId + Duration)"
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
ToggleBtn.Visible = false
ToggleBtn.ZIndex = 2
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 22)
local tStroke = Instance.new("UIStroke", ToggleBtn)
tStroke.Color = Color3.fromRGB(255, 215, 0)
tStroke.Thickness = 1.5
setDrag(ToggleBtn, ToggleBtn)

-- ==================== ฟังก์ชันล็อกอิน ====================
local function tryLogin()
    local input = PasswordBox.Text
    if input == "HONKUKI_191Legendary" then
        LoginFrame.Visible = false
        MainFrame.Visible = true
        ToggleBtn.Visible = true
        LoginError.Text = ""
        PasswordBox.Text = ""
        refreshPlayers()
    else
        LoginError.Text = "❌ รหัสไม่ถูกต้อง กรุณาลองใหม่"
        PasswordBox.Text = ""
        PasswordBox:CaptureFocus()
    end
end

LoginButton.MouseButton1Click:Connect(tryLogin)
PasswordBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        tryLogin()
    end
end)

-- ==================== ฟังก์ชันรีเฟรชผู้เล่น ====================
local function refreshPlayers()
    if not ListScroll or not ListScroll:IsDescendantOf(game) then return end
    for _, item in pairs(ListScroll:GetChildren()) do
        if item:IsA("TextButton") then item:Destroy() end
    end
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
                for _, b in pairs(ListScroll:GetChildren()) do
                    if b:IsA("TextButton") then b.UIStroke.Color = Color3.fromRGB(40, 40, 40) end
                end
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

-- ==================== ปุ่มกดทำงาน ====================
GetIDBtn.MouseButton1Click:Connect(function()
    if CurrentSelectedPlayer then
        StatusLabel.Text = "🔍 กำลังเจาะ ID (ตรวจสอบ AssetTypeId + Duration)..."
        task.wait(0.05)
        local result = directLogMusicID(CurrentSelectedPlayer.Name)
        if result then
            StatusLabel.Text = "✅ สำเร็จ! ส่ง ID แยก Real/Fake ขึ้นดิสแล้ว (คัดลอก ID จริงทั้งหมด)"
        end
    else
        StatusLabel.Text = "⚠️ โปรดเลือกชื่อผู้เล่นก่อนกดดึง!"
    end
end)

GetJunkBtn.MouseButton1Click:Connect(function()
    if CurrentSelectedPlayer then
        StatusLabel.Text = "📦 กำลังดึงข้อมูลขยะดิบ (เฉพาะเสียงของผู้เล่น)..."
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
    if CurrentSelectedPlayer == p then
        CurrentSelectedPlayer = nil
        StatusLabel.Text = "โปรดเลือกผู้เล่น..."
    end
    if WhitelistPlayers[p.Name] then WhitelistPlayers[p.Name] = nil end
    refreshPlayers()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

task.spawn(function()
    while task.wait(5) do
        if MainFrame.Visible then
            refreshPlayers()
        end
    end
end)

task.wait(0.1)
PasswordBox:CaptureFocus()
