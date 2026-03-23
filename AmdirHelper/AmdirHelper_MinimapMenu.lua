local addonName = ...
local frame = CreateFrame("Frame", addonName .. "Frame")

-----------------------------------------------------------------------
-- MINIMAP BUTTON
-----------------------------------------------------------------------
local btn = CreateFrame("Button", addonName .. "MiniMapButton", Minimap)
btn:SetFrameStrata("MEDIUM")
btn:SetSize(32, 32)

-- ВАЖЛИВО: логотип у папці AmdirHelper
btn:SetNormalTexture("Interface\\AddOns\\AmdirHelper\\logo.tga")

btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
btn:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
btn:SetMovable(true)
btn:EnableMouse(true)
btn:RegisterForDrag("LeftButton")
btn:SetScript("OnDragStart", btn.StartMoving)
btn:SetScript("OnDragStop", btn.StopMovingOrSizing)

-----------------------------------------------------------------------
-- MENU POPUP
-----------------------------------------------------------------------
local menuFrame = CreateFrame("Frame", addonName .. "MenuFrame", UIParent, "UIDropDownMenuTemplate")

-- запит тексту у гравця
local function AskInput(prompt, callback)
    StaticPopupDialogs["AMDIRHELPER_INPUT"] = {
        text = prompt,
        button1 = "OK",
        button2 = "Cancel",
        hasEditBox = true,
        maxLetters = 250,
        OnAccept = function(self)
            local text = self.editBox:GetText()
            if callback then callback(text) end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("AMDIRHELPER_INPUT")
end

-----------------------------------------------------------------------
-- ВИКОНАННЯ КОМАНД
-----------------------------------------------------------------------
local function Exec(cmd)
    SendChatMessage(cmd, "WHISPER", nil, UnitName("player"))
end

-----------------------------------------------------------------------
-- МЕНЮ
-----------------------------------------------------------------------
local menu = {
    {
        text = "PVP",
        hasArrow = true,
        menuList = {
            {
                text = "1v1 Rated",
                func = function() Exec(".q1v1 rated") end
            },
            {
                text = "1v1 Unrated",
                func = function() Exec(".q1v1 unrated") end
            },
            {
                text = "Low-Level 2v2",
                func = function() Exec(".lla queue") end
            },
            {
                text = "Дуель з баном",
                func = function()
                    AskInput("Введіть нік противника:", function(name)
                        if name ~= "" then Exec(".duelban 1 " .. name) end
                    end)
                end
            },
        },
    },

    {
    text = "PVE",
    hasArrow = true,
    menuList = {
        {
            text = "Спостереження за рейдом",
            hasArrow = true,
            menuList = {
                {
                    text = "Приєднатись до рейду",
                    func = function()
                        AskInput("Ім'я гравця:", function(name)
                            if name ~= "" then Exec(".ps player " .. name) end
                        end)
                    end
                },
                {
                    text = "Телепорт до РЛа",
                    func = function() Exec(".ps gorl") end
                },
                {
                    text = "Покинути спостереження",
                    func = function() Exec(".ps leave") end
                },
                {
                    text = "Спостерігачі",
                    func = function() Exec(".ps list") end
                },
                {
                    text = "Кікнути спостерігача",
                    func = function()
                        AskInput("Ім'я спостерігача:", function(name)
                            if name ~= "" then Exec(".ps kick " .. name) end
                        end)
                    end
                },
            },
        },
        {
            text = "Solo LFG: On",
            func = function() Exec(".sololfg on") end
        },
        {
            text = "Solo LFG: Off",
            func = function() Exec(".sololfg off") end
        },
        {
            text = "Solo LFG: Status",
            func = function() Exec(".sololfg status") end
        },
        
    },
},
    {
        text = "Хардкор режим",
        hasArrow = true,
        menuList = {
            
            {
                text = "Увімкнути хардкор режим",
                func = function() Exec(".hardcore enable") end
            },
            {
                text = "Увімкнути героічну форма",
                func = function() Exec(".hardcore form on") end
            },
             {
                text = "Вимкнути героічну форма",
                func = function() Exec(".hardcore form off") end
            },
            {
                text = "Хардкор статус",
                func = function() Exec(".hardcore status") end
            },
        },
    },

    {
        text = "Оракул",
        func = function()
            AskInput("Введіть питання (до 250 символів):", function(msg)
                if msg ~= "" then
                    Exec(".ask " .. msg)
                end
            end)
        end
    },
}

-----------------------------------------------------------------------
-- ПІДКЛЮЧЕННЯ МЕНЮ ДО КНОПКИ
-----------------------------------------------------------------------
btn:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        EasyMenu(menu, menuFrame, "cursor", 0 , 0, "MENU")
    end
end)
