---@diagnostic disable: undefined-global, undefined-field, need-check-nil
local AceGUI = LibStub("AceGUI-3.0")

local class
local spec
local phase
local class_index
local spec_index
local phase_index

local class_options = {}
local class_options_to_class = {}

local spec_options = {}
local spec_options_to_spec = {}
local spec_frame
local items = {}
local spells = {}
local main_frame

local classDropdown
local specDropdown
local phaseDropDown

local checkmarks = {}
local Yellowcheckmarks = {}
local boemarks = {}

local isHorde = UnitFactionGroup("player") == "Horde"

local BoECache = {}
local talentsFrame
local talentsTexture
local talentsEscapeButton

local function IsItemBoE(itemID)
    if BoECache[itemID] ~= nil then
        return BoECache[itemID]
    end

    if not BoECheckTooltip then
        CreateFrame("GameTooltip", "BoECheckTooltip", UIParent, "GameTooltipTemplate")
    end

    local tooltip = BoECheckTooltip
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:ClearLines()
    tooltip:SetHyperlink("item:" .. itemID)

    for i = 2, tooltip:NumLines() do
        local line = _G["BoECheckTooltipTextLeft" .. i]
        if line then
            local text = line:GetText()
            if text == ITEM_BIND_ON_EQUIP then
                BoECache[itemID] = true
                return true
            elseif text == ITEM_BIND_ON_PICKUP then
                BoECache[itemID] = false
                return false
            end
        end
    end

    BoECache[itemID] = false
    return false
end

local function createItemFrame(item_id, size, ItemEquipped, ItemInInventory, BoEItem)
    if item_id < 0 then
        return AceGUI:Create("Label")
    end

    local item_frame = AceGUI:Create("Icon")
    item_frame:SetImageSize(size, size)

    local aliItemID
    if Bistooltip_horde_to_ali then
        aliItemID = Bistooltip_horde_to_ali[item_id]
    end

    if aliItemID then
        item_id = aliItemID
    end

    GameTooltip:SetHyperlink("item:" .. item_id .. ":0:0:0:0:0:0:0")
    local itemName, itemLink, _, _, _, _, _, _, _, itemIcon, _, _, _, _ = GetItemInfo(item_id)

    if not itemName then
        item_frame:SetImage("Interface\\Icons\\INV_Misc_QuestionMark")
        return item_frame
    end

    item_frame:SetImage(itemIcon)

    if ItemEquipped then
        local checkMark = item_frame.frame:CreateTexture(nil, "OVERLAY")
        checkMark:SetWidth(32)
        checkMark:SetHeight(32)
        checkMark:SetPoint("CENTER", 6, -8)
        checkMark:SetTexture("Interface\\AddOns\\Bistooltip\\Media\\checkmark-16.tga")
        table.insert(checkmarks, checkMark)
    end

    if ItemInInventory then
        local YellowcheckMark = item_frame.frame:CreateTexture(nil, "OVERLAY")
        YellowcheckMark:SetWidth(32)
        YellowcheckMark:SetHeight(32)
        YellowcheckMark:SetPoint("CENTER", 6, -8)
        YellowcheckMark:SetTexture("Interface\\AddOns\\Bistooltip\\Media\\checkmark-17.tga")
        table.insert(Yellowcheckmarks, YellowcheckMark)
    end

    if BoEItem then
        local boeMark = item_frame.frame:CreateTexture(nil, "OVERLAY")
        boeMark:SetWidth(15)
        boeMark:SetHeight(15)
        boeMark:SetPoint("TOPLEFT", 2, -2)
        boeMark:SetTexture("Interface\\Icons\\inv_misc_coin_02")
        table.insert(boemarks, boeMark)
    end

    item_frame:SetCallback("OnClick", function(_)
        SetItemRef(itemLink, itemLink, "LeftButton")
    end)
    item_frame:SetCallback("OnEnter", function(_)
        GameTooltip:SetOwner(item_frame.frame)
        GameTooltip:SetPoint("TOPRIGHT", item_frame.frame, "TOPRIGHT", 220, -13)
        GameTooltip:SetHyperlink(itemLink)
    end)
    item_frame:SetCallback("OnLeave", function(_)
        GameTooltip:Hide()
    end)

    return item_frame
end

local function createSpellFrame(spell_id, size)
    if spell_id < 0 then
        local f = AceGUI:Create("Label")
        return f
    end

    local spell_frame = AceGUI:Create("Icon")
    spell_frame:SetImageSize(size, size)

    local name, _, icon, _, _, _ = GetSpellInfo(spell_id)
    if not name then
        print("Failed to find spell ID:", spell_id)
        return spell_frame
    end

    spell_frame:SetImage(icon)
    local link = GetSpellLink(spell_id)
    if not link then
        link = "\124cffffd000\124Hspell:" .. spell_id .. "\124h[" .. name .. "]\124h\124r"
    end

    spell_frame:SetCallback("OnClick", function(_)
        SetItemRef(link, link, "LeftButton")
    end)
    spell_frame:SetCallback("OnEnter", function(_)
        GameTooltip:SetOwner(spell_frame.frame)
        GameTooltip:SetPoint("TOPRIGHT", spell_frame.frame, "TOPRIGHT", 220, -13)
        GameTooltip:SetHyperlink(link)
    end)
    spell_frame:SetCallback("OnLeave", function(_)
        GameTooltip:Hide()
    end)

    return spell_frame
end

local function createEnhancementsFrame(enhancements)
    local frame = AceGUI:Create("SimpleGroup")
    frame:SetLayout("Table")
    frame:SetWidth(40)
    frame:SetHeight(40)
    frame:SetUserData("table", {
        columns = {
            {
                weight = 20
            },
            {
                width = 20
            },
        },
        spaceV = -10,
        spaceH = 10,
        align = "BOTTOMRIGHT"
    })
    frame:SetFullWidth(true)
    frame:SetFullHeight(true)
    frame:SetHeight(0)
    frame:SetAutoAdjustHeight(false)
    for _, enhancement in ipairs(enhancements) do
        local size = 15

        if enhancement.type == "none" then
            frame:AddChild(createItemFrame(-1, size))
        end
        if enhancement.type == "item" then
            frame:AddChild(createItemFrame(enhancement.id, size))
        end
        if enhancement.type == "spell" then
            frame:AddChild(createSpellFrame(enhancement.id, size))
        end
    end
    return frame
end

local function drawItemSlot(slot)
    local f = AceGUI:Create("Label")
    f:SetText(slot.slot_name)
    f:SetFont("Fonts\\SFUIDisplayCondensed-Semibold", 14, " ")
    spec_frame:AddChild(f)
    spec_frame:AddChild(createEnhancementsFrame(slot.enhs))

    for _, original_item_id in ipairs(slot) do
        local item_id = original_item_id

        if isHorde and Bistooltip_horde_to_ali then
            local translated_item_id = Bistooltip_horde_to_ali[original_item_id]
            if translated_item_id then
                item_id = translated_item_id
            end
        end

        local isBoE = IsItemBoE(item_id)
        if item_id and Bistooltip_char_equipment and Bistooltip_char_equipment[item_id] == 2 then
            spec_frame:AddChild(createItemFrame(item_id, 40, true, false, isBoE))
        elseif item_id and Bistooltip_char_equipment and Bistooltip_char_equipment[item_id] == 1 then
            spec_frame:AddChild(createItemFrame(item_id, 40, false, true, isBoE))
        else
            spec_frame:AddChild(createItemFrame(item_id, 40, false, false, isBoE))
        end
    end
end

local function drawTableHeader(frame)
    local f = AceGUI:Create("Label")
    f:SetText("Slot")
    f:SetFont("Fonts\\SFUIDisplayCondensed-Semibold", 14, " ")
    local color = 0.6
    f:SetColor(color, color, color)
    frame:AddChild(f)
    frame:AddChild(AceGUI:Create("Label"))
    for i = 1, 5 do
        f = AceGUI:Create("Label")
        f:SetText("Top " .. i)
        f:SetColor(color, color, color)
        frame:AddChild(f)
    end
end

local function saveData()
    BistooltipAddon.db.char.class_index = class_index
    BistooltipAddon.db.char.spec_index = spec_index
    BistooltipAddon.db.char.phase_index = phase_index
end

local function clearCheckMarks()
    for _, value in ipairs(checkmarks) do
        value:SetTexture(nil)
    end
    checkmarks = {}
end

local function clearYellowCheckMarks()
    for _, value in ipairs(Yellowcheckmarks) do
        value:SetTexture(nil)
    end
    Yellowcheckmarks = {}
end

local function clearBoeMarks()
    for _, value in ipairs(boemarks) do
        value:SetTexture(nil)
    end
    boemarks = {}
end

local drawQueue = {}
local drawWorker = CreateFrame("Frame")
drawWorker:Hide()

drawWorker:SetScript("OnUpdate", function(self)
    local maxPerFrame = 2
    local count = 0

    while count < maxPerFrame do
        local slot = table.remove(drawQueue, 1)
        if not slot then
            self:Hide()
            return
        end
        drawItemSlot(slot)
        count = count + 1
    end
end)

local function drawSpecData()
    clearCheckMarks()
    clearYellowCheckMarks()
    clearBoeMarks()
    saveData()

    items = {}
    spells = {}

    spec_frame:ReleaseChildren()
    drawTableHeader(spec_frame)

    if not spec or not phase then
        return
    end

    local slots = Bistooltip_bislists[class][spec][phase]

    wipe(drawQueue)
    for _, slot in ipairs(slots) do
        table.insert(drawQueue, slot)
    end

    drawWorker:Show()
end

local function buildClassDict()
    if not Bistooltip_classes or type(Bistooltip_classes) ~= "table" then
        return
    end

    class_options = {}
    for ci, classes in ipairs(Bistooltip_classes) do
        local option_name = "|T" .. Bistooltip_spec_icons[classes.name]["classIcon"] .. ":18|t " .. classes.name
        table.insert(class_options, option_name)
        class_options_to_class[option_name] = {
            name = classes.name,
            i = ci
        }
    end
end

local function buildSpecsDict(class_i)
    if not Bistooltip_classes or type(Bistooltip_classes) ~= "table" then
        return
    end

    spec_options = {}
    spec_options_to_spec = {}
    local classes = Bistooltip_classes[class_i]
    for _, specs in ipairs(classes.specs) do
        local option_name = "|T" .. Bistooltip_spec_icons[classes.name][specs] .. ":18|t " .. specs
        table.insert(spec_options, option_name)
        spec_options_to_spec[option_name] = specs
    end
end

local function loadData()
    class_index = BistooltipAddon.db.char.class_index
    spec_index = BistooltipAddon.db.char.spec_index
    phase_index = BistooltipAddon.db.char.phase_index
    if class_index then
        class = class_options_to_class[class_options[class_index]].name
        buildSpecsDict(class_index)
    end
    if spec_index then
        spec = spec_options_to_spec[spec_options[spec_index]]
    end
    if phase_index then
        phase = Bistooltip_phases[phase_index]
    end
end

local function drawDropdowns()
    local dropDownGroup = AceGUI:Create("SimpleGroup")

    dropDownGroup.frame:SetBackdrop(nil)

    dropDownGroup:SetLayout("Table")
    dropDownGroup:SetUserData("table", {
        columns = { 138, 138, 138 },
        align = "BOTTOMRIGHT"
    })

    main_frame:AddChild(dropDownGroup)

    classDropdown = AceGUI:Create("Dropdown")
    specDropdown = AceGUI:Create("Dropdown")
    phaseDropDown = AceGUI:Create("Dropdown")
    specDropdown:SetDisabled(false)

    phaseDropDown:SetCallback("OnValueChanged", function(_, _, key)
        phase_index = key
        phase = Bistooltip_phases[key]
        drawSpecData()
    end)

    specDropdown:SetCallback("OnValueChanged", function(_, _, key)
        spec_index = key
        spec = spec_options_to_spec[spec_options[key]]
        drawSpecData()
    end)

    classDropdown:SetCallback("OnValueChanged", function(_, _, key)
        class_index = key
        class = class_options_to_class[class_options[key]].name

        specDropdown:SetDisabled(false)
        buildSpecsDict(key)
        specDropdown:SetList(spec_options)
        specDropdown:SetValue(1)
        spec_index = 1
        spec = spec_options_to_spec[spec_options[1]]
        drawSpecData()

    end)

    classDropdown:SetList(class_options)
    phaseDropDown:SetList(Bistooltip_phases)

    dropDownGroup:AddChild(classDropdown)
    dropDownGroup:AddChild(specDropdown)
    dropDownGroup:AddChild(phaseDropDown)

    local fillerFrame = AceGUI:Create("Label")
    fillerFrame:SetText(" ")
    main_frame:AddChild(fillerFrame)

    classDropdown:SetValue(class_index)
    if (class_index) then
        buildSpecsDict(class_index)
        specDropdown:SetList(spec_options)
        specDropdown:SetDisabled(false)
    end
    specDropdown:SetValue(spec_index)
    phaseDropDown:SetValue(phase_index)
end

local function createSpecFrame()
    local frame = AceGUI:Create("ScrollFrame")
    frame:SetLayout("Table")
    frame:SetUserData("table", {
        columns = { {
                        weight = 40
                    }, {
                        width = 55
                    }, {
                        width = 55
                    }, {
                        width = 55
                    }, {
                        width = 55
                    }, {
                        width = 55
                    }, {
                        width = 55
                    } },
        space = 2,
        align = "middle"
    })
    frame:SetFullWidth(true)
    frame:SetHeight(370)
    frame:SetAutoAdjustHeight(false)
    main_frame:AddChild(frame)
    spec_frame = frame
end

function BistooltipAddon:reloadData()
    buildClassDict()
    class_index = BistooltipAddon.db.char.class_index
    spec_index = BistooltipAddon.db.char.spec_index
    phase_index = BistooltipAddon.db.char.phase_index

    class = class_options_to_class[class_options[class_index]].name
    buildSpecsDict(class_index)
    spec = spec_options_to_spec[spec_options[spec_index]]
    phase = Bistooltip_phases[phase_index]

    if main_frame then
        phaseDropDown:SetList(Bistooltip_phases)
        classDropdown:SetList(class_options)
        specDropdown:SetList(spec_options)

        classDropdown:SetValue(class_index)
        specDropdown:SetValue(spec_index)
        phaseDropDown:SetValue(phase_index)

        drawSpecData()
        main_frame:SetStatusText(Bistooltip_source_to_url[BistooltipAddon.db.char["data_source"]])
    end
end

function BistooltipAddon:OpenGithubLink()
    BistooltipAddon:closeMainFrame()
    StaticPopup_Show("Github_LINK_DIALOG")
    StaticPopupDialogs["Github_LINK_DIALOG"].preferredIndex = 4
end

StaticPopupDialogs["Github_LINK_DIALOG"] = {
    text = "---Github link for the Addon---                              (press CTRL+C and paste into Google)",
    button2 = "Close",
    OnShow = function(self)
        self.editBox:SetText("https://github.com/Tyrus2K/Bistooltip")
        self.editBox:SetFocus()
        self.editBox:HighlightText()
        self.editBox:SetWidth(200)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 4,
    hasEditBox = true,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
        BistooltipAddon:createMainFrame()
    end,
    OnHide = function(self)
        self.data = nil
    end,
    EditBoxOnTextChanged = function(self, userInput)
        if userInput then
            self:SetText(self.data)
            self:HighlightText()
        end
    end,
    OnCancel = function(self)
        self:Hide()
        BistooltipAddon:createMainFrame()
    end
}

local function GetTalentTextureForCurrentSpec()
    if not class or not spec then
        return "Interface\\Icons\\INV_Misc_QuestionMark"
    end

    local c = string.lower(class)
    local s = string.lower(spec)

    if c == "warrior" then
        if s == "fury" then
            return "Interface\\AddOns\\Bistooltip\\Media\\Talents\\WarriorFury.tga"
        elseif s == "protection" or s == "prot" then
            return "Interface\\AddOns\\Bistooltip\\Media\\Talents\\WarriorProtection.tga"
        end
    elseif c == "paladin" then
        if s == "holy" then
            return "Interface\\AddOns\\Bistooltip\\Media\\Talents\\PaladinHoly.tga"
        elseif s == "protection" or s == "prot" then
            return "Interface\\AddOns\\Bistooltip\\Media\\Talents\\PaladinProtection.tga"
        elseif s == "retribution" or s == "ret" then
            return "Interface\\AddOns\\Bistooltip\\Media\\Talents\\PaladinRetribution.tga"
        end
    elseif c == "hunter" then
        if s == "beast mastery" or s == "bm" then
            return "Interface\\AddOns\\Bistooltip\\Media\\Talents\\HunterBeast.tga"
        elseif s == "marksmanship" or s == "mm" then
            return "Interface\\AddOns\\Bistooltip\\Media\\Talents\\HunterMarksman.tga"
        elseif s == "survival" then
            return "Interface\\AddOns\\Bistooltip\\Media\\Talents\\HunterSurvival.tga"
        end
    elseif c == "rogue" then
        if s == "assassination" then
            return "Interface\\AddOns\\Bistooltip\\Media\\Talents\\RogueAssassin.tga"
        elseif s == "combat" then
            return "Interface\\AddOns\\Bistooltip\\Media\\Talents\\RogueCombat.tga"
        end
    elseif c == "priest" then
        if s == "discipline" or s == "disc" then
            return "Interface\\AddOns\\Bistooltip\\Media\\Talents\\PriestDiscipline.tga"
        elseif s == "holy" then
            return "Interface\\AddOns\\Bistooltip\\Media\\Talents\\PriestHoly.tga"
        elseif s == "shadow" then
            return "Interface\\AddOns\\Bistooltip\\Media\\Talents\\PriestShadow.tga"
        end
    elseif c == "death knight" or c == "deathknight" or c == "dk" then
        if s == "blood tank" then
            return "Interface\\AddOns\\Bistooltip\\Media\\Talents\\DKBloodTank.tga"
        elseif s == "frost" then
            return "Interface\\AddOns\\Bistooltip\\Media\\Talents\\DKFrost.tga"
        elseif s == "unholy" then
            return "Interface\\AddOns\\Bistooltip\\Media\\Talents\\DKUnholy.tga"
        end
    elseif c == "shaman" then
        if s == "elemental" then
            return "Interface\\AddOns\\Bistooltip\\Media\\Talents\\ShamanElemental.tga"
        elseif s == "enhancement" or s == "enh" then
            return "Interface\\AddOns\\Bistooltip\\Media\\Talents\\ShamanEnhancement.tga"
        elseif s == "restoration" or s == "resto" then
            return "Interface\\AddOns\\Bistooltip\\Media\\Talents\\ShamanRestoration.tga"
        end
    elseif c == "mage" then
        if s == "arcane" then
            return "Interface\\AddOns\\Bistooltip\\Media\\Talents\\MageArcane.tga"
        elseif s == "fire" then
            return "Interface\\AddOns\\Bistooltip\\Media\\Talents\\MageFire.tga"
        elseif s == "frost" then
            return "Interface\\AddOns\\Bistooltip\\Media\\Talents\\MageFrost.tga"
        end
    elseif c == "warlock" then
        if s == "affliction" then
            return "Interface\\AddOns\\Bistooltip\\Media\\Talents\\WarlockAffliction.tga"
        elseif s == "demonology" then
            return "Interface\\AddOns\\Bistooltip\\Media\\Talents\\WarlockDemo.tga"
        elseif s == "destruction" then
            return "Interface\\AddOns\\Bistooltip\\Media\\Talents\\WarlockDestruction.tga"
        end
    elseif c == "druid" then
        if s == "balance" then
            return "Interface\\AddOns\\Bistooltip\\Media\\Talents\\DruidBalance.tga"
        elseif s == "feral dps" then
            return "Interface\\AddOns\\Bistooltip\\Media\\Talents\\DruidFeralDPS.tga"
        elseif s == "feral tank" then
            return "Interface\\AddOns\\Bistooltip\\Media\\Talents\\DruidFeralTank.tga"
        elseif s == "restoration" or s == "resto" then
            return "Interface\\AddOns\\Bistooltip\\Media\\Talents\\DruidRestoration.tga"
        end
    end

    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function ResizeTalentsFrameToTexture()
    if not talentsFrame or not talentsTexture then
        return
    end

    local w, h = talentsTexture:GetSize()
    if not w or w <= 0 or not h or h <= 0 then
        w = talentsTexture:GetTextureWidth()
        h = talentsTexture:GetTextureHeight()
    end

    if w and h and w > 0 and h > 0 then
        talentsFrame:SetSize(w, h)
    end
end

local function EnableTalentsEsc()
    if not talentsEscapeButton then
        talentsEscapeButton = CreateFrame("Button", "BisTooltipTalentsEscapeButton", UIParent, "SecureActionButtonTemplate")
        talentsEscapeButton:SetAttribute("type", "click")
        talentsEscapeButton:SetScript("OnClick", function()
            if talentsFrame and talentsFrame:IsShown() then
                talentsFrame:Hide()
            end
        end)
    end
    SetOverrideBindingClick(talentsEscapeButton, false, "ESCAPE", "BisTooltipTalentsEscapeButton")
end

local function DisableTalentsEsc()
    if talentsEscapeButton then
        ClearOverrideBindings(talentsEscapeButton)
    end
end

function BistooltipAddon:ShowTalentsImage()
    local texPath = GetTalentTextureForCurrentSpec()

    if talentsFrame then
        if talentsTexture then
            talentsTexture:SetTexture(texPath)
            ResizeTalentsFrameToTexture()
        end

        if talentsFrame:IsShown() then
            talentsFrame:Hide()
            DisableTalentsEsc()
        else
            talentsFrame:Show()
            EnableTalentsEsc()
        end
        return
    end

    talentsFrame = CreateFrame("Frame", "BisTooltipTalentsFrame", UIParent)
    talentsFrame:SetPoint("CENTER")
    talentsFrame:SetFrameStrata("DIALOG")
    talentsFrame:EnableMouse(true)
    talentsFrame:SetMovable(true)
    talentsFrame:RegisterForDrag("LeftButton")
    talentsFrame:SetScript("OnDragStart", talentsFrame.StartMoving)
    talentsFrame:SetScript("OnDragStop", talentsFrame.StopMovingOrSizing)
    talentsFrame:SetClampedToScreen(true)
    talentsFrame:SetScript("OnHide", DisableTalentsEsc)

    talentsTexture = talentsFrame:CreateTexture(nil, "ARTWORK")
    talentsTexture:SetPoint("TOPLEFT", talentsFrame, "TOPLEFT", 0, 0)
    talentsTexture:SetPoint("BOTTOMRIGHT", talentsFrame, "BOTTOMRIGHT", 0, 0)
    talentsTexture:SetTexture(texPath)

    ResizeTalentsFrameToTexture()

    talentsFrame:Show()
    EnableTalentsEsc()
end

function BistooltipAddon:createMainFrame()
    if main_frame then
        BistooltipAddon:closeMainFrame()
        return
    end

    main_frame = AceGUI:Create("Frame")
    if not BistooltipAddon.EscapeButton then
        local close = CreateFrame("Button", "BistooltipAddon_EscapeButton", UIParent, "SecureActionButtonTemplate")
        close:SetAttribute("type", "click")
        close:SetScript("OnClick", function()
            BistooltipAddon:closeMainFrame()
            if talentsFrame and talentsFrame:IsShown() then
                talentsFrame:Hide()
                DisableTalentsEsc()
            end
        end)
        close:Hide()
        BistooltipAddon.EscapeButton = close
    end

    SetOverrideBindingClick(BistooltipAddon.EscapeButton, true, "ESCAPE", "BistooltipAddon_EscapeButton")

    main_frame:SetWidth(450)
    main_frame:SetHeight(550)
    main_frame.frame:SetMinResize(450, 300)
    main_frame.frame:SetMaxResize(800, 600)

    main_frame:SetCallback("OnClose", function(widget)
        if talentsFrame and talentsFrame:IsShown() then
            talentsFrame:Hide()
            DisableTalentsEsc()
        end
        clearCheckMarks()
        clearYellowCheckMarks()
        clearBoeMarks()
        spec_frame = nil
        items = {}
        spells = {}
        AceGUI:Release(widget)
        main_frame = nil
    end)
    main_frame:SetLayout("List")
    main_frame:SetTitle(BistooltipAddon.AddonNameAndVersion)
    main_frame:SetStatusText(Bistooltip_source_to_url[BistooltipAddon.db.char["data_source"]])

    drawDropdowns()
    createSpecFrame()
    drawSpecData()

    local buttonContainer = AceGUI:Create("SimpleGroup")
    buttonContainer:SetFullWidth(true)
    buttonContainer:SetLayout("Flow")

    local leftSpacer = AceGUI:Create("Label")
    leftSpacer:SetWidth(1)
    buttonContainer:AddChild(leftSpacer)

    local reloadButton = AceGUI:Create("Button")
    reloadButton:SetText("Reload")
    reloadButton:SetWidth(138)
    reloadButton:SetCallback("OnClick", function()
        BistooltipAddon:reloadData()
    end)
    buttonContainer:AddChild(reloadButton)

    local GithubButton = AceGUI:Create("Button")
    GithubButton:SetText("Github")
    GithubButton:SetWidth(138)
    GithubButton:SetCallback("OnClick", function()
        BistooltipAddon:OpenGithubLink()
    end)
    buttonContainer:AddChild(GithubButton)

    local talentsButton = AceGUI:Create("Button")
    talentsButton:SetText("Talents")
    talentsButton:SetWidth(138)
    talentsButton:SetCallback("OnClick", function()
        BistooltipAddon:ShowTalentsImage()
    end)
    buttonContainer:AddChild(talentsButton)

    local noteLabel = AceGUI:Create("Label")
    noteLabel:SetText("If a red question mark appears instead of an item/gem/enchant, click the Reload button")
    noteLabel:SetWidth(425)
    noteLabel:SetFont(GameFontNormal:GetFont(), 10)

    local spacerLabel = AceGUI:Create("Label")
    spacerLabel:SetWidth(5)
    buttonContainer:AddChild(spacerLabel)
    buttonContainer:AddChild(noteLabel)
    noteLabel:SetHeight(reloadButton.frame:GetHeight())
    noteLabel:SetFullWidth(false)
    noteLabel.label:SetPoint("BOTTOM")

    local spacer = AceGUI:Create("Label")
    spacer:SetFullWidth(true)
    spacer:SetText(" ")
    main_frame:AddChild(spacer)
    main_frame:AddChild(buttonContainer)
end

function BistooltipAddon:closeMainFrame()
    if BistooltipAddon.EscapeButton then
        ClearOverrideBindings(BistooltipAddon.EscapeButton)
    end

    if main_frame then
        AceGUI:Release(main_frame)
        classDropdown = nil
        specDropdown = nil
        phaseDropDown = nil
        return
    end
end

function BistooltipAddon:initBislists()
    buildClassDict()
    loadData()
    LibStub("AceConsole-3.0"):RegisterChatCommand("bistooltip", function()
        BistooltipAddon:createMainFrame()
    end, persist)
end
