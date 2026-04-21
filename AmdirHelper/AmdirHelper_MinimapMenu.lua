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

local function AskConfirm(prompt, callback)
    StaticPopupDialogs["AMDIRHELPER_CONFIRM"] = {
        text = prompt,
        button1 = "Підтвердити",
        button2 = "Скасувати",
        OnAccept = function()
            if callback then callback() end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("AMDIRHELPER_CONFIRM")
end

-----------------------------------------------------------------------
-- ВИКОНАННЯ КОМАНД
-----------------------------------------------------------------------
local function Exec(cmd)
    SendChatMessage(cmd, "WHISPER", nil, UnitName("player"))
end

local raidBuffConfirmFrame = CreateFrame("Frame")
local raidBuffConfirmPrompt = "Підтвердіть встановлення рейдової скрині"

local function StopRaidBuffConfirmWait()
    raidBuffConfirmFrame.waiting = false
    raidBuffConfirmFrame:UnregisterEvent("CHAT_MSG_SYSTEM")
    raidBuffConfirmFrame:SetScript("OnUpdate", nil)
end

raidBuffConfirmFrame:SetScript("OnEvent", function(self, event, msg)
    if not self.waiting or event ~= "CHAT_MSG_SYSTEM" or not msg then return end
    if not string.find(msg, raidBuffConfirmPrompt, 1, true) then return end

    StopRaidBuffConfirmWait()
    Exec(".raidbuff confirm")
end)

local function ExecRaidBuffWithServerConfirm()
    StopRaidBuffConfirmWait()
    raidBuffConfirmFrame.waiting = true
    raidBuffConfirmFrame.timeout = 3
    raidBuffConfirmFrame:RegisterEvent("CHAT_MSG_SYSTEM")
    raidBuffConfirmFrame:SetScript("OnUpdate", function(self, elapsed)
        self.timeout = self.timeout - elapsed
        if self.timeout > 0 then return end
        StopRaidBuffConfirmWait()
    end)

    Exec(".raidbuff")
end

local function IsCurrentPlayerHardcore()
    local name = UnitName("player")
    return name and type(AmdirHardcoreWhoDB) == "table" and AmdirHardcoreWhoDB[name]
end

local function ShouldShowHardcoreMenu()
    return UnitLevel("player") == 1 or IsCurrentPlayerHardcore()
end

local function BuildHardcoreMenuList()
    local menuList = {}

    if UnitLevel("player") == 1 then
        menuList[#menuList + 1] = {
            text = "Увімкнути хардкор режим",
            func = function() Exec(".hardcore enable") end
        }
    end

    menuList[#menuList + 1] = {
        text = "Увімкнути героічну форма",
        func = function() Exec(".hardcore form on") end
    }
    menuList[#menuList + 1] = {
        text = "Вимкнути героічну форма",
        func = function() Exec(".hardcore form off") end
    }
    menuList[#menuList + 1] = {
        text = "Хардкор статус",
        func = function() Exec(".hardcore status") end
    }

    return menuList
end

local hardcoreMenu = {
    text = "Хардкор режим",
    hasArrow = true,
    menuList = {},
}

local function RefreshHardcoreMenu()
    hardcoreMenu.menuList = BuildHardcoreMenuList()
end

RefreshHardcoreMenu()

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
        {
            text = "АОЕ лут",
            hasArrow = true,
            menuList = {
                {
                    text = "Увімкнути",
                    func = function() Exec(".aoeloot on") end
                },
                {
                    text = "Вимкнути",
                    func = function() Exec(".aoeloot off") end
                },
            },
        },
        {
            text = "Рейдова скриня бафів",
            func = function()
                AskConfirm("Поставити рейдову скриню бафів? З балансу буде списано 1 токен.", function()
                    ExecRaidBuffWithServerConfirm()
                end)
            end
        },
        
    },
},
    hardcoreMenu,

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

local function BuildMenu()
    RefreshHardcoreMenu()

    local visibleMenu = {}
    for _, item in ipairs(menu) do
        if item ~= hardcoreMenu or ShouldShowHardcoreMenu() then
            visibleMenu[#visibleMenu + 1] = item
        end
    end
    return visibleMenu
end

-----------------------------------------------------------------------
-- ПІДКЛЮЧЕННЯ МЕНЮ ДО КНОПКИ
-----------------------------------------------------------------------
btn:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        EasyMenu(BuildMenu(), menuFrame, "cursor", 0 , 0, "MENU")
    end
end)
