-- AmdirHardcoreWho.lua (WoW 3.3.5)
-- Skull mark for hardcore players in /who (WhoFrame) using server addon messages (prefix AMDIR).
--
-- Payloads:
--   HCL|name1,name2,...   (snapshot chunk; may be empty "HCL|")
--   HCON|Name             (delta add)
--   HCOFF|Name            (delta remove)

AmdirHardcoreWhoDB = AmdirHardcoreWhoDB or {}

local function HCtbl()
  if type(AmdirHardcoreWhoDB) ~= "table" then AmdirHardcoreWhoDB = {} end
  return AmdirHardcoreWhoDB
end

local PREFIX     = "AMDIR"
if RegisterAddonMessagePrefix then
  RegisterAddonMessagePrefix(PREFIX)
end
local SKULL_TEX  = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull"
local SKULL_SIZE = 12
local function SendHCQuery()
  -- Only works if server handles HCQ| and replies with HCL|
  if SendAddonMessage then
    SendAddonMessage(PREFIX, "HCQ|", "WHISPER", UnitName("player"))
  end
end
-- ================= helpers =================

local function trim(s)
  return (s and s:gsub("^%s+", ""):gsub("%s+$", "")) or s
end

local function split_csv(s)
  local t = {}
  if not s or s == "" then return t end
  for name in string.gmatch(s, "([^,]+)") do
    name = trim(name)
    if name and name ~= "" then t[#t+1] = name end
  end
  return t
end

-- ================= WhoFrame row helpers =================

local function EnsureSkullIcon(btn)
  if btn.hcIcon then return btn.hcIcon end
  local icon = btn:CreateTexture(nil, "ARTWORK")
  icon:SetTexture(SKULL_TEX)
  icon:SetWidth(SKULL_SIZE)
  icon:SetHeight(SKULL_SIZE)
  icon:Hide()
  btn.hcIcon = icon
  return icon
end

local function UpdateSkullIcon(btn, i, name)
  local fs = _G["WhoFrameButton"..i.."Name"]
  if not fs then return end

  local icon = EnsureSkullIcon(btn)
  icon:ClearAllPoints()
  icon:SetPoint("RIGHT", fs, "RIGHT", -2, 0)

  if HCtbl()[name] then icon:Show() else icon:Hide() end
end

-- ================= Deferred updating =================

local hooksDone      = false
local updatePending  = false
local updateRunning  = false
local updateFrame    = CreateFrame("Frame")

local function UpdateWhoIcons()
  if updateRunning then return end
  if not WhoFrame or not WhoFrame:IsShown() then return end
  if not WhoListScrollFrame then return end
  if not GetWhoInfo(1) then return end

  updateRunning = true

  local offset  = FauxScrollFrame_GetOffset(WhoListScrollFrame) or 0
  local maxRows = WHOS_TO_DISPLAY or 17

  for i = 1, maxRows do
    local btn = _G["WhoFrameButton"..i]
    if btn and btn:IsShown() then
      local name = GetWhoInfo(offset + i)
      if name then
        UpdateSkullIcon(btn, i, name)
      elseif btn.hcIcon then
        btn.hcIcon:Hide()
      end
    end
  end

  updateRunning = false
end

local function RequestUpdate(delaySec)
  if updatePending then return end
  updatePending = true

  local t    = 0
  local wait = delaySec or 0

  updateFrame:SetScript("OnUpdate", function(_, elapsed)
    t = t + elapsed
    if t >= wait then
      updateFrame:SetScript("OnUpdate", nil)
      updatePending = false
      UpdateWhoIcons()
    end
  end)
end

local function SetupWhoHooks()
  if hooksDone then return end
  if not WhoFrame then UIParentLoadAddOn("Blizzard_FriendsUI") end
  if not WhoFrame then return end

  hooksDone = true

  WhoFrame:HookScript("OnShow", function()
  SendHCQuery()
  RequestUpdate(0.10)
end)

  if WhoListScrollFrame then
    WhoListScrollFrame:HookScript("OnVerticalScroll", function() RequestUpdate(0) end)
  end

  if     type(WhoFrame_Update)              == "function" then hooksecurefunc("WhoFrame_Update",              function() RequestUpdate(0) end)
  elseif type(FriendsFrameWhoFrame_Update)  == "function" then hooksecurefunc("FriendsFrameWhoFrame_Update",  function() RequestUpdate(0) end)
  elseif type(WhoList_Update)               == "function" then hooksecurefunc("WhoList_Update",               function() RequestUpdate(0) end)
  end
end

-- ================= addon payload handling =================

local function HandlePayload(payload)
  if not payload or payload == "" then return end

  local cmd, rest = payload:match("^([^|]+)|?(.*)$")
  if not cmd then return end

if cmd == "HCL" then
    -- Перший чанк: очищаємо і заповнюємо
    local HC = HCtbl()
    for k in pairs(HC) do HC[k] = nil end
    for _, name in ipairs(split_csv(rest)) do HC[name] = true end
    RequestUpdate(0.15)  -- чекаємо решту чанків

  elseif cmd == "HCLA" then
    -- Наступні чанки: тільки додаємо, не витираємо
    for _, name in ipairs(split_csv(rest)) do HCtbl()[name] = true end
    RequestUpdate(0.15)

  elseif cmd == "HCON" then
    local name = trim(rest)
    if name and name ~= "" then HCtbl()[name] = true; RequestUpdate(0) end

  elseif cmd == "HCOFF" then
    local name = trim(rest)
    if name and name ~= "" then HCtbl()[name] = nil; RequestUpdate(0) end
  end
end

-- ================= events =================

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("CHAT_MSG_ADDON")
f:RegisterEvent("WHO_LIST_UPDATE")

f:SetScript("OnEvent", function(_, event, a1, a2)
  if event == "CHAT_MSG_ADDON" then
    if a1 == PREFIX and type(a2) == "string" then HandlePayload(a2) end

  elseif event == "WHO_LIST_UPDATE" then
    if WhoFrame and WhoFrame:IsShown() then
      SetupWhoHooks()
      -- SendHCQuery()
      RequestUpdate(0.05)
    end

  elseif event == "PLAYER_ENTERING_WORLD" then
    SetupWhoHooks(); RequestUpdate(0.20)

  elseif event == "ADDON_LOADED" and a1 == "Blizzard_FriendsUI" then
    SetupWhoHooks(); RequestUpdate(0.05)
  end
end)

-- ================= debug =================

SLASH_AMDIRHCDBG1 = "/amhcdbg"
SlashCmdList["AMDIRHCDBG"] = function()
  local HC = HCtbl()
  local n = 0
  for _ in pairs(HC) do n = n + 1 end
  print("AMDIR HC DBG: saved HC count =", n)

  local off = WhoListScrollFrame and (FauxScrollFrame_GetOffset(WhoListScrollFrame) or 0) or 0
  print("AMDIR HC DBG: offset =", off)

  local name1 = GetWhoInfo(off + 1)
  print("AMDIR HC DBG: GetWhoInfo(1) =", tostring(name1), "HC? =", (name1 and HC[name1]) and "yes" or "no")
end

SLASH_AMDIRHCWHO1 = "/amhcwho"
SlashCmdList["AMDIRHCWHO"] = function(msg)
  local name, v = (msg or ""):match("^%s*(.-)%s+(%S+)%s*$")
  if not name or name == "" then
    print("Usage: /amhcwho <Name> <on|off|1|0>")
    return
  end

  if v == "1" or v == "on" then
    HCtbl()[name] = true
    print("AMDIR HC: added", name)
  elseif v == "0" or v == "off" then
    HCtbl()[name] = nil
    print("AMDIR HC: removed", name)
  else
    print("Usage: /amhcwho <Name> <on|off|1|0>")
  end

  RequestUpdate(0)
end
