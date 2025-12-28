BistooltipAddon = LibStub("AceAddon-3.0"):NewAddon("Bis-Tooltip")

Bistooltip_char_equipment = {}

local function collectItemIDs(bislists)
    local itemIDs = {}

    for _, classData in pairs(bislists) do
        for _, specData in pairs(classData) do
            for _, phaseData in pairs(specData) do
                for _, itemData in ipairs(phaseData) do
                    for key, value in pairs(itemData) do
                        if type(key) == "number" then
                            table.insert(itemIDs, value)
                        elseif key == "enhs" then
                            for _, enhData in pairs(value) do
                                if enhData.type == "item" and enhData.id then
                                    table.insert(itemIDs, enhData.id)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return itemIDs
end

local function createEquipmentWatcher()
    local frame = CreateFrame("Frame")
    frame:Hide()

    frame:RegisterEvent("BAG_UPDATE")
    frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
    frame:RegisterEvent("BANKFRAME_OPENED")
    frame:RegisterEvent("BANKFRAME_CLOSED")

    local pending = false

    frame:SetScript("OnEvent", function()
        pending = true
        frame:Show()
    end)

    frame:SetScript("OnUpdate", function(self)
        if not pending then
            self:Hide()
            return
        end
        pending = false
        self:Hide()

        local listIDs = collectItemIDs(Bistooltip_bislists)
        local collection = {}

        for slot = 1, 19 do
            local itemID = GetInventoryItemID("player", slot)
            if itemID then
                for _, bisID in ipairs(listIDs) do
                    if bisID == itemID then
                        collection[itemID] = 2
                    end
                end
            end
        end

        for _, bisID in ipairs(listIDs) do
            local count = GetItemCount(bisID, true)
            if count > 0 then
                if not collection[bisID] then
                    collection[bisID] = 1
                end
            end
        end
        Bistooltip_char_equipment = collection
    end)
end


function BistooltipAddon:OnInitialize()
    createEquipmentWatcher()
    BistooltipAddon.AceAddonName = "Bis-Tooltip WoTLK"
    BistooltipAddon.AddonNameAndVersion = "Bis-Tooltip - WoTLK"
    BistooltipAddon:initConfig()
    BistooltipAddon:addMapIcon()
    BistooltipAddon:initBislists()
    BistooltipAddon:initBisTooltip()
end