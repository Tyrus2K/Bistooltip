local eventFrame = CreateFrame("Frame", nil, UIParent)
Bistooltip_phases_string = ""

function searchIDInBislistsClassSpec(structure, id, class, spec)
    local paths = {}
    local seen = {}

    local sortedPhases = {}
    for _, phase in ipairs(Bistooltip_wowtbc_phases) do
        if structure[class] and structure[class][spec] and structure[class][spec][phase] then
            table.insert(sortedPhases, phase)
        end
    end

    for _, phase in ipairs(sortedPhases) do
        local items = structure[class][spec][phase]

        for _, itemData in pairs(items) do
            if type(itemData) == "table" and itemData[1] then
                for i, itemId in ipairs(itemData) do
                    if i ~= "slot_name" and i ~= "enhs" and itemId == id then
                        local phaseLabel
                        if i == 1 then
                            phaseLabel = phase .. " BIS"
                        elseif i == 2 then
                            phaseLabel = phase .. " Pre-BIS"
                        else
                            phaseLabel = phase .. " Top " .. i
                        end

                        if not seen[phaseLabel] then
                            table.insert(paths, phaseLabel)
                            seen[phaseLabel] = true
                        end
                    end
                end
            end
        end
    end

    if #paths > 0 then
        return table.concat(paths, " / ")
    else
        return nil
    end
end

local function caseInsensitivePairs(t)
    local keys = {}
    for k in pairs(t) do
        table.insert(keys, k)
    end
    table.sort(keys, function(a, b)
        return a:lower() < b:lower()
    end)
    local i = 0
    return function()
        i = i + 1
        local k = keys[i]
        if k then
            return k, t[k]
        end
    end
end

function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

local function GetItemSource(itemId)
    local source

    local function formatInstanceName(instance)
        local tmpInstance = string.lower(instance)
        if tmpInstance == "the obsidian sanctum (heroic)" then
            instance = "The Obsidian Sanctum(25)"
        elseif tmpInstance == "the eye of eternity (heroic)" then
            instance = "The Eye Of Eternity (25)"
        elseif tmpInstance == "naxxramas (heroic)" then
            instance = "Naxxramas (25)"
        elseif tmpInstance == "ulduar (heroic)" then
            instance = "Ulduar (25)"
        end
        return instance
    end

    for zone, bosses in pairs(lootTable) do
        for boss, items in pairs(bosses) do
            if table.contains(items, itemId) then
                local formattedZone = formatInstanceName(zone)
                source = "|cFFFFFFFFDrop:|r |cFF00FF00" .. formattedZone .. " - " .. boss .. "|r"
                break
            end
        end
        if source then
            break
        end
    end

    return source
end

local function OnGameTooltipSetItem(tooltip)
    if BistooltipAddon.db.char.tooltip_with_ctrl and not IsControlKeyDown() then
        return
    end

    local _, link = tooltip:GetItem()
    if not link then
        return
    end

    local _, itemId, _, _, _, _, _, _, _, _, _, _, _, _ = strsplit(":", link)
    itemId = tonumber(itemId)

    if not itemId then
        return
    end

    for class, specs in caseInsensitivePairs(Bistooltip_spec_icons) do
        for spec, icon in pairs(specs) do
            if spec ~= "classIcon" then
                local foundPhases = searchIDInBislistsClassSpec(Bistooltip_bislists, itemId, class, spec)

                if foundPhases then
                    local iconString = string.format("|T%s:18|t", icon)
                    local lineText = string.format("%s %s - %s", iconString, class, spec)
                    tooltip:AddDoubleLine(lineText, foundPhases, 1, 1, 0, 1, 1, 0)
                end
            end
        end
    end

    if Bistooltip_char_equipment and Bistooltip_char_equipment[itemId] ~= nil then
        tooltip:AddLine(" ", 1, 1, 0)
        if Bistooltip_char_equipment[itemId] == 2 then
            tooltip:AddLine("You have this item equipped", 1.000, 0.000, 0.000)
            tooltip:AddLine(" ", 1, 1, 0)
        else
            tooltip:AddLine("You have this item in inventory / bank", 1.000, 0.000, 0.000)
            tooltip:AddLine(" ", 1, 1, 0)
        end
    end

    local itemSource = GetItemSource(itemId)

    if itemSource then
        tooltip:AddLine(" ", 1, 1, 0)
        tooltip:AddLine(itemSource, 1, 1, 1)
        tooltip:AddLine(" ", 1, 1, 0)
    end
end

function BistooltipAddon:initBisTooltip()
    eventFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
    eventFrame:SetScript("OnEvent", function(_, _, e_key, _, _)
        if GameTooltip:GetOwner() then
            if GameTooltip:GetOwner().hasItem then
                return
            end

            if e_key == "RALT" or e_key == "LALT" then
                local _, link = GameTooltip:GetItem()
                if link then
                    GameTooltip:SetHyperlink("|cff9d9d9d|Hitem:3299::::::::20:257::::::|h[Fractured Canine]|h|r")
                    GameTooltip:SetHyperlink(link)
                end
            end
        end
    end)

    GameTooltip:HookScript("OnTooltipSetItem", OnGameTooltipSetItem)
    ItemRefTooltip:HookScript("OnTooltipSetItem", OnGameTooltipSetItem)
end
