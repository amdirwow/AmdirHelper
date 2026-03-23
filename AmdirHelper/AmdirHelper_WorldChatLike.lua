-- AmdirHelper_WorldChatLike.lua
-- World Chat Likes

local HEART_ICON = "|TInterface\\Icons\\INV_Misc_Gift_01:14:14:0:0|t"

-- ============= ФІЛЬТР =============

local function MessageFilter(self, event, msg, ...)
    if not msg then return false end
    
    -- Замінюємо [likes] на іконку
    if msg:find("%[likes%]") then
        local newMsg = msg:gsub("|cffFF69B4%[likes%]|r", HEART_ICON)
        return false, newMsg, ...
    end
    
    return false
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", MessageFilter)

-- ============= КОНТЕКСТНЕ МЕНЮ =============

UnitPopupButtons["WC_LIKE"] = {
    text = HEART_ICON .. " Like",
    dist = 0,
}

-- Додаємо кнопку в UnitPopup ТІЛЬКИ на момент right-click по ніку в чаті
local WC_LIKE_MENUS = {"FRIEND", "PLAYER", "PARTY", "RAID_PLAYER"}

local function WCLike_AddToMenus()
    for _, menu in ipairs(WC_LIKE_MENUS) do
        local t = UnitPopupMenus[menu]
        if t then
            local found = false
            for i = 1, #t do
                if t[i] == "WC_LIKE" then found = true break end
            end
            if not found then
                table.insert(t, "WC_LIKE")
            end
        end
    end
end

local function WCLike_RemoveFromMenus()
    for _, menu in ipairs(WC_LIKE_MENUS) do
        local t = UnitPopupMenus[menu]
        if t then
            for i = #t, 1, -1 do
                if t[i] == "WC_LIKE" then
                    table.remove(t, i)
                end
            end
        end
    end
end

do
    local _orig = ChatFrame_OnHyperlinkShow
    ChatFrame_OnHyperlinkShow = function(frame, link, text, button)
        if button == "RightButton" and type(link) == "string" then
            local linkType = strsplit(":", link)
            if linkType == "player" then
                WCLike_AddToMenus()
                local a,b,c,d,e,f = _orig(frame, link, text, button)
                WCLike_RemoveFromMenus()
                return a,b,c,d,e,f
            end
        end
        return _orig(frame, link, text, button)
    end
end

hooksecurefunc("UnitPopup_OnClick", function(self)
    if self.value == "WC_LIKE" then
        local dropdown = UIDROPDOWNMENU_INIT_MENU
        local name = dropdown.name
        if name then
            name = strsplit("-", name)
            local editBox = ChatFrame1EditBox
            if editBox then
                local wasShown = editBox:IsShown()
                if not wasShown then editBox:Show() end
                editBox:SetText(".like " .. name)
                ChatEdit_SendText(editBox)
                if not wasShown then editBox:Hide() end
            end
        end
    end
end)

-- ============= SLASH КОМАНДА =============

SLASH_WCLIKE1 = "/wclike"
SLASH_WCLIKE2 = "/like"
SlashCmdList["WCLIKE"] = function(name)
    if name and name ~= "" then
        local editBox = ChatFrame1EditBox
        if editBox then
            local wasShown = editBox:IsShown()
            if not wasShown then editBox:Show() end
            editBox:SetText(".like " .. name)
            ChatEdit_SendText(editBox)
            if not wasShown then editBox:Hide() end
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffFF69B4[WC Like]|r Usage: /like <name>")
    end
end

DEFAULT_CHAT_FRAME:AddMessage("|cffFF69B4[WC Like]|r " .. HEART_ICON .. " Loaded!")
