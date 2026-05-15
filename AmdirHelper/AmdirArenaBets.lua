local ADDON = ...
local AAB = CreateFrame("Frame", "AmdirArenaBetsFrame", UIParent)
AAB:SetFrameStrata("HIGH")
AAB:SetWidth(680)
AAB:SetHeight(80)
AAB:SetPoint("TOP", UIParent, "TOP", 0, -26)
AAB:Hide()

local state = {
    active = false,
    hasBet = false,
    inHyjal = false,
    aName = "",
    bName = "",
    betName = "",
    winnerName = nil,
    loserName = nil,
    aValue = 1,
    aMax = 1,
    bValue = 1,
    bMax = 1,
    aShown = 1,
    bShown = 1,
    aOdds = 0,
    bOdds = 0,
    hideAfter = nil,
}

local function Clamp(v, mn, mx)
    if v < mn then return mn end
    if v > mx then return mx end
    return v
end

local function ToNumber(v, fallback)
    v = tonumber(v)
    if not v then return fallback or 0 end
    return v
end

local function SplitPipe(msg)
    local out = {}
    local start = 1
    while true do
        local pos = string.find(msg, "|", start, true)
        if not pos then
            table.insert(out, string.sub(msg, start))
            break
        end
        table.insert(out, string.sub(msg, start, pos - 1))
        start = pos + 1
    end
    return out
end

local function ContainsAny(text, ...)
    if not text then return false end
    for i = 1, select("#", ...) do
        local needle = select(i, ...)
        if needle and string.find(text, needle, 1, true) then
            return true
        end
    end
    return false
end

local function IsInHyjal()
    -- Працюємо тільки у відкритій локації Хіджал.
    -- Інстовий Hyjal Summit / Battle for Mount Hyjal має inInstance=true, тому UI там не показуємо.
    if IsInInstance then
        local inInstance = IsInInstance()
        if inInstance then
            return false
        end
    end

    local z1 = GetZoneText and GetZoneText() or ""
    local z2 = GetRealZoneText and GetRealZoneText() or ""
    local z3 = GetSubZoneText and GetSubZoneText() or ""

    return ContainsAny(z1, "Хиджал", "Хіджал", "Hyjal", "Mount Hyjal")
        or ContainsAny(z2, "Хиджал", "Хіджал", "Hyjal", "Mount Hyjal")
        or ContainsAny(z3, "Хиджал", "Хіджал", "Hyjal", "Mount Hyjal")
end

local function FormatOdds(x100)
    x100 = ToNumber(x100, 0)
    if x100 <= 0 then return "" end
    if math.fmod(x100, 100) == 0 then
        return string.format("%d до 1", x100 / 100)
    elseif math.fmod(x100, 10) == 0 then
        return string.format("%.1f до 1", x100 / 100)
    end
    return string.format("%.2f до 1", x100 / 100)
end

local function CreateStatusBar(parent, name, point, x)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetWidth(290)
    holder:SetHeight(34)
    holder:SetPoint(point, parent, point, x, 0)

    holder.bg = holder:CreateTexture(nil, "BACKGROUND")
    holder.bg:SetAllPoints(holder)
    holder.bg:SetTexture(0, 0, 0, 0.72)

    holder.border = CreateFrame("Frame", nil, holder)
    holder.border:SetAllPoints(holder)
    holder.border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    holder.border:SetBackdropBorderColor(0.85, 0.12, 0.08, 1)

    local bar = CreateFrame("StatusBar", nil, holder)
    bar:SetPoint("TOPLEFT", holder, "TOPLEFT", 5, -5)
    bar:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", -5, 5)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)
    bar:SetStatusBarColor(0.72, 0.04, 0.03, 0.95)
    holder.bar = bar

    holder.nameText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    holder.nameText:SetPoint("LEFT", bar, "LEFT", 8, 0)
    holder.nameText:SetJustifyH("LEFT")
    holder.nameText:SetTextColor(1.0, 0.86, 0.25, 1)

    holder.valueText = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    holder.valueText:SetPoint("RIGHT", bar, "RIGHT", -8, 0)
    holder.valueText:SetJustifyH("RIGHT")
    holder.valueText:SetTextColor(1, 1, 1, 1)

    holder.betMark = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    holder.betMark:SetPoint("TOP", holder, "BOTTOM", 0, -2)
    holder.betMark:SetTextColor(0.35, 1.0, 0.35, 1)
    holder.betMark:SetText("")

    return holder
end

AAB.left = CreateStatusBar(AAB, "left", "LEFT", 0)
AAB.right = CreateStatusBar(AAB, "right", "RIGHT", 0)

AAB.vs = AAB:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
AAB.vs:SetPoint("CENTER", AAB, "CENTER", 0, 0)
AAB.vs:SetTextColor(1, 0.15, 0.12, 1)
AAB.vs:SetText("ПРОТИ")

local function UpdateTexts()
    AAB.left.nameText:SetText(state.aName or "")
    AAB.right.nameText:SetText(state.bName or "")

    local aPct = 0
    local bPct = 0
    if state.aMax and state.aMax > 0 then aPct = Clamp(state.aShown / state.aMax, 0, 1) end
    if state.bMax and state.bMax > 0 then bPct = Clamp(state.bShown / state.bMax, 0, 1) end

    AAB.left.bar:SetValue(aPct)
    AAB.right.bar:SetValue(bPct)

    if state.aMax and state.aMax > 1 then
        AAB.left.valueText:SetText(string.format("%d%%", math.floor(aPct * 100 + 0.5)))
    else
        AAB.left.valueText:SetText(FormatOdds(state.aOdds))
    end

    if state.bMax and state.bMax > 1 then
        AAB.right.valueText:SetText(string.format("%d%%", math.floor(bPct * 100 + 0.5)))
    else
        AAB.right.valueText:SetText(FormatOdds(state.bOdds))
    end

    AAB.left.betMark:SetText(state.betName == state.aName and "Твоя ставка" or "")
    AAB.right.betMark:SetText(state.betName == state.bName and "Твоя ставка" or "")

    if state.winnerName then
        if state.winnerName == state.aName then
            AAB.left.border:SetBackdropBorderColor(0.15, 0.95, 0.15, 1)
            AAB.right.border:SetBackdropBorderColor(0.85, 0.12, 0.08, 1)
        elseif state.winnerName == state.bName then
            AAB.left.border:SetBackdropBorderColor(0.85, 0.12, 0.08, 1)
            AAB.right.border:SetBackdropBorderColor(0.15, 0.95, 0.15, 1)
        end
    else
        AAB.left.border:SetBackdropBorderColor(0.85, 0.12, 0.08, 1)
        AAB.right.border:SetBackdropBorderColor(0.85, 0.12, 0.08, 1)
    end
end

local function RefreshVisibility()
    state.inHyjal = IsInHyjal()
    if state.active and state.hasBet and state.inHyjal then
        AAB:Show()
    else
        AAB:Hide()
    end
end

local function HandlePayload(payload)
    local parts = SplitPipe(payload)
    local cmd = parts[1]

    if cmd == "BET" then
        state.active = true
        state.hasBet = true
        state.winnerName = nil
        state.loserName = nil
        state.hideAfter = nil
        state.aName = parts[2] or "Боєць 1"
        state.bName = parts[3] or "Боєць 2"
        state.betName = parts[4] or ""
        state.aOdds = ToNumber(parts[5], 0)
        state.bOdds = ToNumber(parts[6], 0)
        state.aValue, state.aMax, state.bValue, state.bMax = 1, 1, 1, 1
        state.aShown, state.bShown = 1, 1
        UpdateTexts()
        RefreshVisibility()
        return
    end

    if cmd == "FIGHT" then
        state.active = true
        state.hasBet = true
        state.winnerName = nil
        state.loserName = nil
        state.hideAfter = nil
        state.aName = parts[2] or state.aName
        state.bName = parts[3] or state.bName
        state.aValue = ToNumber(parts[4], state.aValue)
        state.aMax = math.max(1, ToNumber(parts[5], state.aMax))
        state.bValue = ToNumber(parts[6], state.bValue)
        state.bMax = math.max(1, ToNumber(parts[7], state.bMax))
        state.betName = parts[8] or state.betName
        state.aOdds = ToNumber(parts[9], state.aOdds)
        state.bOdds = ToNumber(parts[10], state.bOdds)
        RefreshVisibility()
        return
    end

    if cmd == "END" then
        state.winnerName = parts[2]
        state.loserName = parts[3]
        state.hideAfter = 8
        UpdateTexts()
        RefreshVisibility()
        return
    end

    if cmd == "HIDE" then
        state.active = false
        state.hasBet = false
        state.hideAfter = nil
        AAB:Hide()
        return
    end
end

local function SystemFilter(self, event, msg, ...)
    if type(msg) == "string" and string.sub(msg, 1, 4) == "HBA:" then
        HandlePayload(string.sub(msg, 5))
        return true
    end
    return false
end


-- v1.5: кастомне вікно вводу ставки повністю прибране.
-- Аддон більше не перехоплює gossip-кнопки і не чіпає StaticPopup.
-- Ввід ставки знову обробляє стандартне серверне gossip-code вікно.

AAB:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED_INDOORS" then
        RefreshVisibility()
    end
end)

AAB:SetScript("OnUpdate", function(self, elapsed)
    if state.aMax and state.aMax > 1 then
        state.aShown = state.aShown + (state.aValue - state.aShown) * math.min(1, elapsed * 8)
    end
    if state.bMax and state.bMax > 1 then
        state.bShown = state.bShown + (state.bValue - state.bShown) * math.min(1, elapsed * 8)
    end

    if state.hideAfter then
        state.hideAfter = state.hideAfter - elapsed
        if state.hideAfter <= 0 then
            state.active = false
            state.hasBet = false
            state.hideAfter = nil
            self:Hide()
            return
        end
    end

    if self:IsShown() then
        UpdateTexts()
    end
end)

AAB:RegisterEvent("PLAYER_ENTERING_WORLD")
AAB:RegisterEvent("ZONE_CHANGED")
AAB:RegisterEvent("ZONE_CHANGED_NEW_AREA")
AAB:RegisterEvent("ZONE_CHANGED_INDOORS")
ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", SystemFilter)
