-- AmdirHelper_TransmogPreview.lua
-- Ловимо системні повідомлення виду "TMOG_PREVIEW <itemId>"
-- і відкриваємо стандартну примерочну з цим предметом.

local PREFIX = "TMOG_PREVIEW"

local function HandlePreviewMessage(msg)
    if type(msg) ~= "string" then
        return false
    end

    -- знаходимо "TMOG_PREVIEW <itemId>" як підрядок
    local itemId = msg:match(PREFIX .. "%s+(%d+)")
    if not itemId then
        return false
    end

    itemId = tonumber(itemId)
    if not itemId or itemId == 0 then
        return true -- фільтруємо повідомлення, але без дії
    end

    local link = string.format("item:%d:0:0:0:0:0:0:0", itemId)

    if not (DressUpFrame and DressUpModel and DressUpModel.TryOn) then
        return true
    end

    local wasShown = DressUpFrame:IsShown()

    ShowUIPanel(DressUpFrame)

    if not wasShown and DressUpFrame:IsShown() then
        DressUpModel:SetUnit("player")
    end

    DressUpModel:TryOn(link)

    return true    -- не показувати це повідомлення у чаті
end

local function SystemMessageFilter(self, event, msg, ...)
    if HandlePreviewMessage(msg) then
        return true
    end
    return false
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", SystemMessageFilter)
end)
