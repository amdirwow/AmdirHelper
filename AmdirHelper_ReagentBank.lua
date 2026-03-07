-- ReagentBank Addon for WoW 3.3.5
-- Кнопка для швидкого депозиту реагентів через drag & drop

local NPC_NAME = "VIP банкір"  -- Назва NPC

-- Створюємо головний фрейм для подій
local eventFrame = CreateFrame("Frame", "ReagentBankEventFrame", UIParent)

-- Створюємо кнопку
local button = CreateFrame("Button", "ReagentBankButton", UIParent)
button:SetSize(64, 64)
button:SetFrameStrata("DIALOG")
button:SetFrameLevel(100)
button:SetClampedToScreen(true)
button:Hide()

-- Фон кнопки
button:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

-- Іконка на кнопці
local icon = button:CreateTexture(nil, "ARTWORK")
icon:SetSize(48, 48)
icon:SetPoint("CENTER", 0, 0)
icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_10_Blue")

-- Текст під кнопкою
local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
text:SetPoint("TOP", button, "BOTTOM", 0, -2)
text:SetText("|cff00ff00Перетягни сюди|r")

-- Підсвітка
local highlightTex = button:CreateTexture(nil, "OVERLAY")
highlightTex:SetAllPoints()
highlightTex:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
highlightTex:SetBlendMode("ADD")
highlightTex:SetVertexColor(0, 1, 0, 0.5)
highlightTex:Hide()

-- Таймер фрейм для анімації
local flashFrame = CreateFrame("Frame")
flashFrame:Hide()
flashFrame.elapsed = 0
flashFrame:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = self.elapsed + elapsed
    if self.elapsed >= 0.3 then
        highlightTex:Hide()
        self:Hide()
    end
end)

-- Анімація при успішному депозиті
local function FlashSuccess()
    highlightTex:SetVertexColor(0, 1, 0, 0.8)
    highlightTex:Show()
    flashFrame.elapsed = 0
    flashFrame:Show()
end

-- Функція для позиціонування
local function PositionButton()
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", GossipFrame, "TOPRIGHT", 5, -30)
end

-- Функція для отримання item link з курсора
local function GetCursorItemLink()
    local infoType, itemID, itemLink = GetCursorInfo()
    if infoType == "item" then
        return itemLink
    end
    return nil
end

-- Функція для відправки команди
local function SendReagentBankCommand(itemLink)
    if itemLink then
        local cmd = ".rb " .. itemLink
        local editBox = ChatFrame1EditBox or DEFAULT_CHAT_FRAME.editBox
        if editBox then
            editBox:SetText(cmd)
            ChatEdit_SendText(editBox)
        end
    end
end

-- Перетягування кнопки
button:SetMovable(true)
button:EnableMouse(true)
button:RegisterForDrag("RightButton")

button:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

button:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)

-- Обробка drop на кнопку
button:SetScript("OnReceiveDrag", function(self)
    local itemLink = GetCursorItemLink()
    if itemLink then
        ClearCursor()
        SendReagentBankCommand(itemLink)
        FlashSuccess()
    end
end)

-- Обробка кліку з айтемом на курсорі
button:SetScript("OnClick", function(self, mouseButton)
    if mouseButton == "LeftButton" then
        local itemLink = GetCursorItemLink()
        if itemLink then
            ClearCursor()
            SendReagentBankCommand(itemLink)
            FlashSuccess()
        end
    end
end)

-- Підсвітка коли наводимо
button:SetScript("OnEnter", function(self)
    local itemLink = GetCursorItemLink()
    if itemLink then
        highlightTex:SetVertexColor(0, 1, 0, 0.5)
        highlightTex:Show()
        text:SetText("|cff00ff00Відпусти тут!|r")
    else
        text:SetText("|cff00ff00Перетягни сюди|r")
    end
    
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Банк Реагентів", 1, 1, 1)
    GameTooltip:AddLine("Перетягніть реагент на цю кнопку", 0, 1, 0)
    GameTooltip:AddLine("щоб покласти його в банк.", 0, 1, 0)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("ПКМ - перемістити кнопку", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end)

button:SetScript("OnLeave", function(self)
    highlightTex:Hide()
    text:SetText("|cff00ff00Перетягни сюди|r")
    GameTooltip:Hide()
end)

-- Слухаємо події gossip
eventFrame:RegisterEvent("GOSSIP_SHOW")
eventFrame:RegisterEvent("GOSSIP_CLOSED")

local positioned = false

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "GOSSIP_SHOW" then
        local npcName = UnitName("npc")
        if npcName and npcName == NPC_NAME then
            if not positioned then
                PositionButton()
                positioned = true
            end
            button:Show()
        end
    elseif event == "GOSSIP_CLOSED" then
        button:Hide()
    end
end)