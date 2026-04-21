-- AmdirHelper_ChatMod.lua
-- World chat polish: class-colored player links and badge placement.

local PREFIX = "AMDIR"

if RegisterAddonMessagePrefix then
    RegisterAddonMessagePrefix(PREFIX)
end

AmdirHelperChatDB = AmdirHelperChatDB or {}
AmdirHelperChatDB.classes = AmdirHelperChatDB.classes or {}

local CLASS_BY_ID = {
    [1] = "WARRIOR",
    [2] = "PALADIN",
    [3] = "HUNTER",
    [4] = "ROGUE",
    [5] = "PRIEST",
    [6] = "DEATHKNIGHT",
    [7] = "SHAMAN",
    [8] = "MAGE",
    [9] = "WARLOCK",
    [11] = "DRUID",
}

local function StripRealm(name)
    if not name then return nil end
    return (name:gsub("%-.*$", ""))
end

local function StoreClass(name, classId)
    name = StripRealm(name)
    classId = tonumber(classId)
    local classToken = classId and CLASS_BY_ID[classId]
    if name and name ~= "" and classToken then
        AmdirHelperChatDB.classes[name] = classToken
    end
end

local function GetClassColor(name)
    name = StripRealm(name)
    local classToken = name and AmdirHelperChatDB.classes[name]
    if not classToken then return nil end

    local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[classToken] or RAID_CLASS_COLORS[classToken]
    if not color then return nil end

    return color
end

local function ColorPlayerLinks(text)
    return text:gsub("(|Hplayer:([^|:]+)([:%d]*)([^|]*)|h)%[([^%]]+)%](|h)", function(prefix, name, msgId, extra, displayName, suffix)
        local color = GetClassColor(name)
        if not color then
            if displayName:find("|cff", 1, true) then
                return prefix .. "[" .. displayName .. "]" .. suffix
            end

            return prefix .. "[" .. displayName .. "]" .. suffix
        end

        displayName = displayName:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        local coloredName = ("|cff%02x%02x%02x%s|r"):format(
            math.floor(color.r * 255 + 0.5),
            math.floor(color.g * 255 + 0.5),
            math.floor(color.b * 255 + 0.5),
            displayName)
        return prefix .. "[" .. coloredName .. "]" .. suffix
    end)
end

local function MoveWorldChatBadge(text)
    local before, link, after = text:match("^(.-)(|Hplayer:[^|]+|h%[[^%]]+%]|h):(.*)$")
    if not before or not link or not after then
        return text
    end

    local colorPrefix, tail = after:match("^%s*(|c%x%x%x%x%x%x%x%x)(.*)$")
    if not colorPrefix then
        tail = after
    end

    local badge, rest = tail:match("^%[(.-|T.-|t.-)%]%s*(.*)$")
    if not badge or not rest then
        return text
    end

    return before .. (colorPrefix or "") .. badge .. link .. ": " .. rest
end

local function ProcessChatLine(text)
    if type(text) ~= "string" or text == "" then
        return text
    end

    text = ColorPlayerLinks(text)
    text = MoveWorldChatBadge(text)
    return text
end

local function HookChatFrame(frame)
    if not frame or frame.AmdirHelperChatModWrapper == frame.AddMessage then return end

    local originalAddMessage = frame.AddMessage
    local wrapper = function(self, text, ...)
        return originalAddMessage(self, ProcessChatLine(text), ...)
    end

    frame.AmdirHelperChatModOriginal = originalAddMessage
    frame.AmdirHelperChatModWrapper = wrapper
    frame.AddMessage = wrapper
end

local function HookAllChatFrames()
    for i = 1, NUM_CHAT_WINDOWS do
        HookChatFrame(_G["ChatFrame" .. i])
    end
end

local hookTimer = CreateFrame("Frame")
local hookDelay = 0
local hookRepeats = 0

local function RequestHookRefresh(delay, repeats)
    hookDelay = delay or 0
    hookRepeats = repeats or 1
    hookTimer:SetScript("OnUpdate", function(_, elapsed)
        hookDelay = hookDelay - elapsed
        if hookDelay > 0 then return end

        HookAllChatFrames()
        hookRepeats = hookRepeats - 1

        if hookRepeats <= 0 then
            hookTimer:SetScript("OnUpdate", nil)
        else
            hookDelay = 1
        end
    end)
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("CHAT_MSG_ADDON")

events:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "ADDON_LOADED" and arg1 == "Chatter" then
        RequestHookRefresh(0.1, 5)
        return
    end

    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        HookAllChatFrames()
        RequestHookRefresh(0.5, 5)
        return
    end

    if event == "CHAT_MSG_ADDON" and arg1 == PREFIX and type(arg2) == "string" then
        local cmd, name, classId = arg2:match("^([^|]+)|([^|]+)|([^|]+)")
        if cmd == "WCC" then
            StoreClass(name, classId)
        end
    end
end)

HookAllChatFrames()
