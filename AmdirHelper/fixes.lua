local frame = CreateFrame("Frame", "AmdirHelperFixesFrame")

local pendingRefresh = false
local nextRefreshAt = 0
local refreshUntil = 0
local refreshInterval = 0.2

local function PlayerHasVehicleUI()
    if UnitHasVehicleUI then
        return UnitHasVehicleUI("player")
    end

    if UnitInVehicle then
        return UnitInVehicle("player")
    end

    if CanExitVehicle then
        return CanExitVehicle()
    end

    return false
end

local function PlayerHasDefaultPetBarCandidate()
    return UnitExists("pet") and not UnitIsDead("pet") and not PlayerHasVehicleUI()
end

local function RefreshDefaultPetBar()
    if not PetActionBarFrame or not PlayerHasDefaultPetBarCandidate() then
        return false
    end

    if PetActionBar_Update then
        PetActionBar_Update()
    end

    if PetActionBarFrame_Update then
        PetActionBarFrame_Update()
    end

    if PetActionBar_UpdateCooldowns then
        PetActionBar_UpdateCooldowns()
    end

    PetActionBarFrame:SetAlpha(1)
    PetActionBarFrame:Show()

    return PetActionBarFrame:IsShown()
end

local function StopRefreshLoop()
    pendingRefresh = false
    frame:SetScript("OnUpdate", nil)
end

local function QueuePetBarRefresh(duration, interval)
    refreshInterval = interval or 0.2
    nextRefreshAt = 0
    refreshUntil = GetTime() + (duration or 1.5)
    pendingRefresh = true

    frame:SetScript("OnUpdate", function(self, elapsed)
        if not pendingRefresh then
            self:SetScript("OnUpdate", nil)
            return
        end

        nextRefreshAt = nextRefreshAt - elapsed
        if nextRefreshAt > 0 then
            return
        end

        nextRefreshAt = refreshInterval

        local now = GetTime()
        local shown = RefreshDefaultPetBar()
        if shown and now + refreshInterval >= refreshUntil then
            StopRefreshLoop()
            return
        end

        if now >= refreshUntil then
            StopRefreshLoop()
        end
    end)
end

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_ENTERING_WORLD" then
        QueuePetBarRefresh(2.0, 0.2)
        return
    end

    if event == "UNIT_PET" and arg1 == "player" then
        QueuePetBarRefresh(2.0, 0.2)
        return
    end

    if event == "UNIT_EXITED_VEHICLE" and arg1 == "player" then
        QueuePetBarRefresh(3.0, 0.2)
        return
    end

    if event == "PLAYER_CONTROL_GAINED" or event == "PET_BAR_UPDATE" then
        QueuePetBarRefresh(1.0, 0.2)
    end
end)

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UNIT_PET")
frame:RegisterEvent("UNIT_EXITED_VEHICLE")
frame:RegisterEvent("PLAYER_CONTROL_GAINED")
frame:RegisterEvent("PET_BAR_UPDATE")
