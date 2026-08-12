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

-----------------------------------------------------------------------
-- ОФОРМЛЕННЯ МЕНЮ (шрифт, іконки, розміри рядків)
-----------------------------------------------------------------------
-- Беремо шрифт з ігрового GameFontNormal (FRIZQT__.TTF) — він гарантовано
-- містить кирилицю на будь-якій збірці клієнта, просто робимо його більшим.
local FONT_PATH, _, FONT_FLAGS = GameFontNormal:GetFont()
FONT_PATH = FONT_PATH or "Fonts\\FRIZQT__.TTF"
FONT_FLAGS = FONT_FLAGS or ""

local ROW_HEIGHT = 20      -- висота рядка меню
local ICON_SIZE = 16       -- розмір іконки в рядку
local TEXT_PADDING = 48    -- запас під стрілку підменю та відступи

local titleFont = CreateFont(addonName .. "MenuTitleFont")
titleFont:SetFont(FONT_PATH, 15, FONT_FLAGS)
titleFont:SetShadowOffset(1, -1)
titleFont:SetShadowColor(0, 0, 0, 1)
titleFont:SetJustifyH("LEFT")
titleFont:SetTextColor(1, 0.86, 0.3)

local headerFont = CreateFont(addonName .. "MenuHeaderFont")
headerFont:SetFont(FONT_PATH, 14, FONT_FLAGS)
headerFont:SetShadowOffset(1, -1)
headerFont:SetShadowColor(0, 0, 0, 1)
headerFont:SetJustifyH("LEFT")
headerFont:SetTextColor(1, 0.82, 0)

local itemFont = CreateFont(addonName .. "MenuItemFont")
itemFont:SetFont(FONT_PATH, 13, FONT_FLAGS)
itemFont:SetShadowOffset(1, -1)
itemFont:SetShadowColor(0, 0, 0, 1)
itemFont:SetJustifyH("LEFT")
itemFont:SetTextColor(0.95, 0.95, 0.95)

-- Іконка перед текстом пункту (обрізаємо стандартну рамку іконок)
local function Icon(path)
    if not path then return "" end
    return "|T" .. path .. ":" .. ICON_SIZE .. ":" .. ICON_SIZE .. ":0:0:64:64:5:59:5:59|t  "
end

-- Іконка без обрізки (для логотипа аддона)
local function RawIcon(path)
    return "|T" .. path .. ":" .. ICON_SIZE .. ":" .. ICON_SIZE .. "|t  "
end

-- Чи належить відкрите зараз випадаюче меню саме нам
-- (у 3.3.5 ці глобалки можуть тримати як фрейм, так і його ім'я)
local function IsOurMenu()
    local name = menuFrame:GetName()
    local open = UIDROPDOWNMENU_OPEN_MENU
    local init = UIDROPDOWNMENU_INIT_MENU
    return open == menuFrame or open == name or init == menuFrame or init == name
end

-- Шрифт застосовуємо одразу після створення кнопки, щоб текст не «стрибав»
hooksecurefunc("UIDropDownMenu_AddButton", function(info, level)
    if not IsOurMenu() then return end

    level = level or 1
    local listFrame = _G["DropDownList" .. level]
    if not listFrame or not listFrame.numButtons then return end

    local button = _G["DropDownList" .. level .. "Button" .. listFrame.numButtons]
    if not button then return end

    local font = itemFont
    if info.amdirTitle then
        font = titleFont
    elseif info.hasArrow then
        font = headerFont
    end

    button:SetNormalFontObject(font)
    button:SetHighlightFontObject(font)
    button:SetDisabledFontObject(font)
end)

-- Після того як список побудовано — вирівнюємо ширину/висоту під новий шрифт
hooksecurefunc("ToggleDropDownMenu", function(level)
    if not IsOurMenu() then return end

    level = level or 1
    local listFrame = _G["DropDownList" .. level]
    if not listFrame or not listFrame:IsShown() then return end

    local count = listFrame.numButtons or 0
    if count == 0 then return end

    local maxText = 0
    for i = 1, count do
        local text = _G["DropDownList" .. level .. "Button" .. i .. "NormalText"]
        if text then
            local width = text:GetStringWidth() or 0
            if width > maxText then maxText = width end
        end
    end

    local buttonWidth = maxText + TEXT_PADDING
    listFrame.maxWidth = buttonWidth
    listFrame:SetWidth(buttonWidth + 30)
    listFrame:SetHeight(count * ROW_HEIGHT + 30)

    local previous
    for i = 1, count do
        local button = _G["DropDownList" .. level .. "Button" .. i]
        if button then
            button:SetHeight(ROW_HEIGHT)
            button:SetWidth(buttonWidth)
            button:ClearAllPoints()
            if previous then
                button:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, 0)
            else
                button:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 15, -15)
            end
            previous = button
        end
    end
end)

-----------------------------------------------------------------------
-- ХЕЛПЕРИ ДЛЯ ОПИСУ ПУНКТІВ
-----------------------------------------------------------------------
-- Звичайний пункт: виконує дію і закриває меню
local function Item(text, icon, func)
    return {
        text = Icon(icon) .. text,
        notCheckable = true,
        func = func,
    }
end

-- Категорія: тільки розкриває підменю, сама нічого не робить
-- (без func + keepShownOnClick => клік нічого не виконує і меню не закривається)
local function Category(text, icon, menuList)
    return {
        text = Icon(icon) .. text,
        hasArrow = true,
        notCheckable = true,
        keepShownOnClick = true,
        menuList = menuList,
    }
end

-----------------------------------------------------------------------
-- ЗАПИТИ ДО ГРАВЦЯ
-----------------------------------------------------------------------
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

-- Виклик клієнтської слеш-команди (напр. /wbid, /wbuy з аддона WorldBid)
local function RunSlash(handlerName, args, slashText)
    local handler = SlashCmdList and SlashCmdList[handlerName]
    if handler then
        handler(args or "")
        return
    end

    local editBox = (ChatEdit_ChooseBoxForSend and ChatEdit_ChooseBoxForSend()) or ChatFrame1EditBox
    if editBox and ChatEdit_SendText then
        editBox:SetText(slashText)
        ChatEdit_SendText(editBox, 0)
        editBox:SetText("")
        return
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cffff5555AmdirHelper:|r команда " .. slashText .. " недоступна (аддон не завантажено).")
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
        menuList[#menuList + 1] = Item("Увімкнути хардкор режим", "Interface\\Icons\\Spell_ChargePositive",
            function() Exec(".hardcore enable") end)
    end

    menuList[#menuList + 1] = Item("Увімкнути героїчну форму", "Interface\\Icons\\Ability_Warrior_InnerRage",
        function() Exec(".hardcore form on") end)
    menuList[#menuList + 1] = Item("Вимкнути героїчну форму", "Interface\\Icons\\Spell_ChargeNegative",
        function() Exec(".hardcore form off") end)
    menuList[#menuList + 1] = Item("Хардкор статус", "Interface\\Icons\\INV_Misc_Note_01",
        function() Exec(".hardcore status") end)

    return menuList
end

local hardcoreMenu = Category("Хардкор режим", "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01", {})

local function RefreshHardcoreMenu()
    hardcoreMenu.menuList = BuildHardcoreMenuList()
end

RefreshHardcoreMenu()

-----------------------------------------------------------------------
-- МЕНЮ
-----------------------------------------------------------------------
local menu = {
    {
        text = RawIcon("Interface\\AddOns\\AmdirHelper\\logo.tga") .. "Amdir Helper",
        notCheckable = true,
        keepShownOnClick = true,
        amdirTitle = true,
    },

    Category("PVP", "Interface\\Icons\\INV_BannerPVP_02", {
        Item("1v1 Rated", "Interface\\Icons\\Ability_Warrior_Challange",
            function() Exec(".q1v1 rated") end),
        Item("1v1 Unrated", "Interface\\Icons\\Ability_DualWield",
            function() Exec(".q1v1 unrated") end),
        Item("Low-Level 2v2", "Interface\\Icons\\Ability_Warrior_BattleShout",
            function() Exec(".lla queue") end),
        Item("Дуель з баном", "Interface\\Icons\\Ability_Warrior_Disarm", function()
            AskInput("Введіть нік противника:", function(name)
                if name ~= "" then Exec(".duelban 1 " .. name) end
            end)
        end),
    }),

    Category("PVE", "Interface\\Icons\\INV_Misc_Head_Dragon_01", {
        Category("Спостереження за рейдом", "Interface\\Icons\\INV_Misc_Spyglass_02", {
            Item("Приєднатись до рейду", "Interface\\Icons\\INV_Misc_GroupLooking", function()
                AskInput("Ім'я гравця:", function(name)
                    if name ~= "" then Exec(".ps player " .. name) end
                end)
            end),
            Item("Телепорт до РЛа", "Interface\\Icons\\Spell_Arcane_Blink",
                function() Exec(".ps gorl") end),
            Item("Покинути спостереження", "Interface\\Icons\\Ability_Vanish",
                function() Exec(".ps leave") end),
            Item("Спостерігачі", "Interface\\Icons\\INV_Scroll_03",
                function() Exec(".ps list") end),
            Item("Кікнути спостерігача", "Interface\\Icons\\Ability_Kick", function()
                AskInput("Ім'я спостерігача:", function(name)
                    if name ~= "" then Exec(".ps kick " .. name) end
                end)
            end),
        }),

        Category("Solo LFG", "Interface\\Icons\\INV_Misc_GroupNeedMore", {
            Item("Увімкнути", "Interface\\Icons\\Spell_ChargePositive",
                function() Exec(".sololfg on") end),
            Item("Вимкнути", "Interface\\Icons\\Spell_ChargeNegative",
                function() Exec(".sololfg off") end),
            Item("Статус", "Interface\\Icons\\INV_Misc_Note_01",
                function() Exec(".sololfg status") end),
        }),

        Category("АОЕ лут", "Interface\\Icons\\INV_Misc_Bag_10", {
            Item("Увімкнути", "Interface\\Icons\\Spell_ChargePositive",
                function() Exec(".aoeloot on") end),
            Item("Вимкнути", "Interface\\Icons\\Spell_ChargeNegative",
                function() Exec(".aoeloot off") end),
        }),

        Item("Рейдова скриня бафів", "Interface\\Icons\\Spell_Holy_GreaterBlessingofKings", function()
            AskConfirm("Поставити рейдову скриню бафів? З балансу буде списано 1 токен.", function()
                ExecRaidBuffWithServerConfirm()
            end)
        end),

        Item("Рейд меню", "Interface\\Icons\\INV_Misc_Book_09",
            function() Exec(".raidmenu") end),
    }),

    Category("Швидкі аукціони", "Interface\\Icons\\INV_Misc_Coin_01", {
        Item("Продаж", "Interface\\Icons\\INV_Misc_Coin_02",
            function() RunSlash("WORLDBID", "", "/wbid") end),
        Item("Купівля", "Interface\\Icons\\INV_Misc_Bag_08",
            function() RunSlash("WORLDBUY", "", "/wbuy") end),
    }),

    hardcoreMenu,

    Item("Оракул", "Interface\\Icons\\INV_Misc_Orb_04", function()
        AskInput("Введіть питання (до 250 символів):", function(msg)
            if msg ~= "" then
                Exec(".ask " .. msg)
            end
        end)
    end),
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
