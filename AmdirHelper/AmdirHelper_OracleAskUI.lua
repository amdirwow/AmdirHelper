-- OracleAskUI: WotLK 3.3.5a - Stable UI (links + ESC behavior)
local ADDON_NAME = "AmdirHelper_OracleAskUI"
local PLAYER_NAME = UnitName("player")

print("|cff00ff00[Oracle]|r Loading addon...")

-- ===== MAIN FRAME =====
local f = CreateFrame("Frame", "OracleAskUIFrame", UIParent)
f:SetSize(500, 400)
f:SetPoint("CENTER")
f:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = {left = 3, right = 3, top = 3, bottom = 3}
})
f:SetBackdropColor(0, 0, 0, 0.9)
f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", function(self) self:StartMoving() end)
f:SetScript("OnDragStop",  function(self) self:StopMovingOrSizing() end)
f:SetToplevel(true)
f:SetFrameStrata("DIALOG")
f:Hide()

-- ===== ESC registration helpers =====
UISpecialFrames = UISpecialFrames or {}

local function _in_UISF(name)
    for i, n in ipairs(UISpecialFrames) do if n == name then return i end end
    return nil
end
local function _add_UISF(name)
    if not _in_UISF(name) then table.insert(UISpecialFrames, name) end
end
local function _remove_UISF(name)
    local idx = _in_UISF(name)
    if idx then table.remove(UISpecialFrames, idx) end
end

-- Title
local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
title:SetPoint("TOP", 0, -8)
title:SetText("Оракул - ігровий помічник сервера Amdir")

-- Close button
local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", 2, 2)

-- ===== CHAT AREA =====
local chatBox = CreateFrame("ScrollingMessageFrame", "OracleChatBox", f)
chatBox:SetPoint("TOPLEFT", 12, -36)
chatBox:SetPoint("BOTTOMRIGHT", -32, 52)
chatBox:SetFontObject(ChatFontNormal)
chatBox:SetFading(false)
chatBox:SetMaxLines(1000)
chatBox:SetJustifyH("LEFT")
chatBox:SetHyperlinksEnabled(true)
chatBox:EnableMouse(true)

chatBox:EnableMouseWheel(true)
chatBox:SetScript("OnMouseWheel", function(self, delta)
    if delta > 0 then self:ScrollUp() else self:ScrollDown() end
end)

chatBox:SetScript("OnHyperlinkEnter", function(self, link)
    GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
    GameTooltip:SetHyperlink(link)
    GameTooltip:Show()
end)
chatBox:SetScript("OnHyperlinkLeave", function() GameTooltip:Hide() end)

-- ===== LOCALE INDEX =====
local function Oracle_LocaleIndex()
  local map = { enUS=0, koKR=1, frFR=2, deDE=3, zhCN=4, zhTW=5, esES=6, esMX=7, ruRU=8 }
  return map[GetLocale()] or 0
end

-- ===== INPUT =====
local input = CreateFrame("EditBox", "OracleInput", f, "InputBoxTemplate")
input:SetSize(400, 22)
input:SetPoint("BOTTOMLEFT", 12, 18)
input:SetAutoFocus(false)
input:SetMaxLetters(255)

local function UpdateEscRegistration() end -- forward declaration

-- Завжди вставляємо текст у поле Оракула з фокусом
local function Oracle_InsertToInput(text)
    if not text or text == "" then return end
    if OracleAskUIFrame and OracleAskUIFrame:IsShown() and OracleInput then
        OracleInput:Insert(text)
        OracleInput:SetFocus()
        if UpdateEscRegistration then UpdateEscRegistration() end
    end
end

local sendBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
sendBtn:SetSize(60, 22)
sendBtn:SetPoint("LEFT", input, "RIGHT", 6, 0)
sendBtn:SetText("Ask")

-- ESC behavior
function UpdateEscRegistration()
    if f:IsShown() then
        if input:HasFocus() then
            _remove_UISF("OracleAskUIFrame")
        else
            _add_UISF("OracleAskUIFrame")
        end
    else
        _remove_UISF("OracleAskUIFrame")
    end
end

input:SetScript("OnEditFocusGained", function() UpdateEscRegistration() end)
input:SetScript("OnEditFocusLost",   function() UpdateEscRegistration() end)

-- ===== MESSAGE BUFFER + RENDER =====
local messages = {}
local function RenderMessages()
    chatBox:Clear()
    for i = 1, #messages do chatBox:AddMessage(messages[i]) end
    chatBox:ScrollToBottom()
end

local function AppendLine(text)
    table.insert(messages, text or "")
    RenderMessages()
end

-- ===== LINK-SAFE TOKENIZATION =====
local function Oracle_TokenizeWithLinks(s)
    local tokens, i = {}, 1
    while i <= #s do
        local a, b = s:find("|c%x%x%x%x%x%x%x%x|H.-|h%[.-%]|h|r", i)
        if a then
            if a > i then table.insert(tokens, {kind="text", val=s:sub(i, a-1)}) end
            table.insert(tokens, {kind="link", val=s:sub(a, b)})
            i = b + 1
        else
            table.insert(tokens, {kind="text", val=s:sub(i)})
            break
        end
    end
    return tokens
end

-- ===== TYPEWRITER =====
local typeQueue, active, speed, acc = {}, nil, 0.015, 0
local function EnqueueOracle(fullText)
    local prefix = "|cff33ff99Оракул|r: "
    local tokens = Oracle_TokenizeWithLinks(prefix .. (fullText or ""))
    table.insert(typeQueue, {tokens=tokens})
end

local function PumpType(elapsed)
    if not active then
        if #typeQueue == 0 then return end
        active = table.remove(typeQueue, 1)
        active.ti, active.ci, active.built = 1, 0, ""
        table.insert(messages, "")
    end
    acc = acc + elapsed
    local steps = floor(acc / speed); if steps <= 0 then return end
    acc = acc - steps * speed

    while steps > 0 and active.ti <= #active.tokens do
        local tok = active.tokens[active.ti]
        if tok.kind == "link" then
            active.built = active.built .. tok.val
            active.ti = active.ti + 1
            active.ci = 0
            steps = steps - 1
        else
            if active.ci >= #tok.val then
                active.ti = active.ti + 1; active.ci = 0
            else
                local take = min(steps, #tok.val - active.ci)
                local from, to = active.ci + 1, active.ci + take
                active.built = active.built .. tok.val:sub(from, to)
                active.ci = to
                steps = steps - take
            end
        end
    end

    messages[#messages] = active.built
    RenderMessages()
    if active.ti > #active.tokens then active = nil end
end

local driver = CreateFrame("Frame")
driver:SetScript("OnUpdate", function(_, e) PumpType(e) end)

-- ===== ORACLE DETECTION/FILTERS =====
local lastHash
local function IsOracle(msg)
    return msg and (msg:find("Оракул:", 1, true) or msg:find("|cff33ff99Оракул|r:", 1, true))
end
local function StripPrefix(msg)
    local clean = msg:gsub("^|cff%x%x%x%x%x%xОракул|r:%s*", "")
    clean = clean:gsub("^Оракул:%s*", "")
    return clean
end
local function HandleOracleMsg(msg)
    local clean = StripPrefix(msg)
    local h = tostring(#clean):sub(1, 16) .. ":" .. clean:sub(1, 32)
    if lastHash ~= h then
        lastHash = h
        if f:IsShown() then EnqueueOracle(clean) else AppendLine("|cff33ff99Оракул|r: " .. clean) end
    end
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(_, _, msg)
    if IsOracle(msg) then HandleOracleMsg(msg); return f:IsShown() end
    return false
end)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", function(_, _, msg, author)
    if author == PLAYER_NAME and IsOracle(msg) then HandleOracleMsg(msg); return f:IsShown() end
    return false
end)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", function(_, _, msg, target)
    if target == PLAYER_NAME and IsOracle(msg) then return f:IsShown() end
    return false
end)
ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", function(_, _, msg, author)
    if author == PLAYER_NAME and msg and msg:find("^%.ask") then return true end
    return false
end)

-- ===== QUEST LINK HELPERS =====
local function Oracle_BuildQuestLink(qid, fallbackText)
    qid = tonumber(qid); if not qid then return fallbackText end
    local okLink = (GetQuestLink and type(GetQuestLink)=="function") and GetQuestLink(qid)
    if type(okLink)=="string" and okLink:find("|Hquest:") then return okLink end
    local shown = fallbackText and fallbackText:match("%[(.+)%]") or ("Квест #%d"):format(qid)
    return ("|cffffff00|Hquest:%d:0|h[%s]|h|r"):format(qid, shown)
end

local function Oracle_FindQuestLinkByTitle(title)
    if not title or title=="" then return nil end
    local plain = title:gsub("^%[(.+)%]$","%1")
    if not GetNumQuestLogEntries or not GetQuestLink or not GetQuestLogTitle then return nil end
    local n = GetNumQuestLogEntries()
    if not n or n <= 0 then return nil end
    for i = 1, n do
        local qTitle = GetQuestLogTitle(i)
        if qTitle and qTitle == plain then
            local link = GetQuestLink(i)
            if link and link:find("|Hquest:") then return link end
        end
    end
    return nil
end

-- ===== LINK NORMALIZATION =====
local function Oracle_NormalizeLink(textOrLink)
    if not textOrLink or textOrLink=="" then return textOrLink end

    if textOrLink:find("^|c%x%x%x%x%x%x%x%x|H.+|h%[.+%]|h|r$") then
        return textOrLink
    end

    local qid = textOrLink:match("^quest:(%d+)")
    if qid then return Oracle_BuildQuestLink(qid, textOrLink) end

    local iid = textOrLink:match("^item:(%d+)")
    if iid then local _, link = GetItemInfo(tonumber(iid)); return link or textOrLink end

    local sid = textOrLink:match("^spell:(%d+)")
    if sid then local link = GetSpellLink(tonumber(sid)); return link or textOrLink end

    local aid = textOrLink:match("^achievement:(%d+)")
    if aid then local link = GetAchievementLink(tonumber(aid)); return link or textOrLink end

    local qLink = Oracle_FindQuestLinkByTitle(textOrLink)
    if qLink then return qLink end

    return textOrLink
end

-- Хук на кліки по заголовках квестів у журналі
if type(hooksecurefunc) == "function" then
    hooksecurefunc("QuestLogTitleButton_OnClick", function(self, button)
        if not IsModifiedClick("CHATLINK") then return end
        if not (OracleAskUIFrame and OracleAskUIFrame:IsShown() and OracleInput) then return end

        local idx = (self and (self.questLogIndex or (self.GetID and self:GetID()))) or nil
        if not idx then return end

        local link
        if GetQuestLink and type(GetQuestLink) == "function" then
            link = GetQuestLink(idx)
        end
        if not link or not link:find("|Hquest:") then
            local title = GetQuestLogTitle and select(1, GetQuestLogTitle(idx)) or nil
            if title and title ~= "" then
                link = ("|cffffff00|Hquest:0:0|h[%s]|h|r"):format(title)
            end
        end

        Oracle_InsertToInput(link or "")
    end)
end

if type(hooksecurefunc) == "function" and _G.WatchFrameLinkButton_OnClick then
    hooksecurefunc("WatchFrameLinkButton_OnClick", function(self, button, ...)
        if not IsModifiedClick("CHATLINK") then return end
        if not (OracleAskUIFrame and OracleAskUIFrame:IsShown() and OracleInput) then return end

        local link
        if self and self.index and GetQuestLink then
            link = GetQuestLink(self.index)
        end
        Oracle_InsertToInput(link or "")
    end)
end

-- ===== CLICK/HYPERLINK HANDLERS =====
chatBox:SetScript("OnHyperlinkClick", function(self, link, text, button)
    if IsModifiedClick("CHATLINK") then
        local payload = text or link
        local normalized = Oracle_NormalizeLink(payload)
        input:Insert(normalized or payload or "")
        input:SetFocus()
        UpdateEscRegistration()
    else
        SetItemRef(link, text, button, self)
    end
end)

local _orig_ChatEdit_InsertLink = ChatEdit_InsertLink
function ChatEdit_InsertLink(text)
    if OracleAskUIFrame and OracleAskUIFrame:IsShown() and OracleInput then
        local normalized = Oracle_NormalizeLink(text)
        OracleInput:Insert(normalized or text or "")
        OracleInput:SetFocus()
        UpdateEscRegistration()
        return true
    end
    if _orig_ChatEdit_InsertLink then
        return _orig_ChatEdit_InsertLink(text)
    end
end

-- ===== SENDING =====
local lastAskTime = 0
local function SendAsk(text)
  if not text then return end
  text = text:match("^%s*(.-)%s*$"); if text=="" then return end
  local now = GetTime()
  if now - lastAskTime < 1.0 then AppendLine("|cffff0000Зачекайте секунду.|r"); return end
  lastAskTime = now
  local loc = Oracle_LocaleIndex()
  AppendLine("|cff4da6ffВи|r: " .. text)
  SendChatMessage(".ask @loc=" .. loc .. " " .. text, "SAY")
end

input:SetScript("OnEnterPressed", function(self)
    SendAsk(self:GetText())
    self:SetText("")
    self:SetFocus()
    UpdateEscRegistration()
end)

input:SetScript("OnEscapePressed", function(self)
    if self:HasFocus() then
        self:ClearFocus()
        UpdateEscRegistration()
    end
end)

sendBtn:SetScript("OnClick", function()
    SendAsk(input:GetText())
    input:SetText("")
    input:SetFocus()
    UpdateEscRegistration()
end)

-- ===== SLASH + WELCOME =====
local welcomeShownThisSession = false
local function ShowWelcomeOnce()
    if welcomeShownThisSession then return end
    welcomeShownThisSession = true
    local namePart = PLAYER_NAME and (", " .. PLAYER_NAME) or ""
    local exampleLink = "|cffff8000|Hitem:49623:0:0:0:0:0:0:0:80|h[Темная скорбь]|h|r"
    local greet = ("Вітаю тебе%s! Чим я можу допомогти? Питай про ігрові предмети, квести, зони, фракції та неігрових персонажів! За можливості використовуй внутрішньоігрові посилання (приклад посилання на %s)!"):format(namePart, exampleLink)
    EnqueueOracle(greet)
end

local function OracleAskUI_Toggle()
    if f:IsShown() then
        f:Hide()
        UpdateEscRegistration()
    else
        f:Show()
        input:SetFocus()
        UpdateEscRegistration()
        ShowWelcomeOnce()
    end
end

SLASH_ORACLE1 = "/oracle"
SLASH_ORACLE2 = "/askui"
SlashCmdList["ORACLE"] = function(msg)
    local q = (msg or ""):match("^%s*(.-)%s*$")
    OracleAskUI_Toggle()
    if q and q ~= "" then
        local delay = CreateFrame("Frame"); local elapsed = 0
        delay:SetScript("OnUpdate", function(self, delta)
            elapsed = elapsed + delta
            if elapsed >= 0.2 then
                SendAsk(q); input:SetText(""); self:SetScript("OnUpdate", nil)
                input:SetFocus(); UpdateEscRegistration()
            end
        end)
    end
end

SLASH_ORACLECLEAR1 = "/oracleclear"
SlashCmdList["ORACLECLEAR"] = function()
    wipe(messages); RenderMessages()
    print("|cff33ff99[Oracle]|r Chat cleared.")
end

local init = CreateFrame("Frame")
init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent", function()
    print("|cff33ff99[Oracle]|r Loaded! Type |cffffcc00/oracle|r to open.")
end)

print("|cff00ff00[Oracle]|r Addon loaded successfully!")
