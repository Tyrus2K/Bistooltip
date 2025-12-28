local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LDB and LibStub("LibDBIcon-1.0", true)
local icon_loaded = false
local icon_name = "BisTooltipIcon"

local sources = {
    wowtbc = "wowtbc"
}

Bistooltip_source_to_url = {
    ["wowtbc"] = "V I N T A G E - Guild class BIS - Feito por Tyrus "
}

local db_defaults = {
    char = {
        class_index = 1,
        spec_index = 1,
        phase_index = 1,
        data_source = nil,
        minimap_icon = true,
        tooltip_with_ctrl = false
    }
}

local configTable = {
    type = "group",
    args = {
        minimap_icon = {
            name = "Botão no Minimapa",
            order = 0,
            desc = "Mostra/Esconde o botão no minimapa",
            type = "toggle",
            set = function(_, val)
                BistooltipAddon.db.char.minimap_icon = val
                if val == true then
                    if icon_loaded == true then
                        LDBIcon:Show(icon_name)
                    else
                        BistooltipAddon:addMapIcon()
                    end
                else
                    LDBIcon:Hide(icon_name)
                end
            end,
            get = function(_)
                return BistooltipAddon.db.char.minimap_icon
            end
        },
        tooltip_with_ctrl = {
            name = "Mostrar tooltips com o CTRL",
            order = 2,
            desc = "Mostra as tooltips ao pressionar o CTRL",
            type = "toggle",
            width = "double",
            set = function(_, val)
                BistooltipAddon.db.char.tooltip_with_ctrl = val
            end,
            get = function(_)
                return BistooltipAddon.db.char.tooltip_with_ctrl
            end
        },
        data_source = {
            name = "Fonte de informação",
            order = 3,
            desc = "BIS usado pela guild V I N T A G E",
            type = "select",
            style = "dropdown",
            width = "double",
            values = Bistooltip_source_to_url,
            set = function(_, key, _)
                BistooltipAddon.db.char.data_source = key
                BistooltipAddon:changeSpec(key)
            end,
            get = function(_, _)
                return BistooltipAddon.db.char.data_source
            end
        },
    }
}

local function openSourceSelectDialog()
    local frame = AceGUI:Create("Window")
    frame:SetWidth(300)
    frame:SetHeight(150)
    frame:EnableResize(false)
    frame:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
        frame = nil
    end)
    frame:SetLayout("List")
    frame:SetTitle(BistooltipAddon.AddonNameAndVersion)

    local labelEmpty = AceGUI:Create("Label")
    labelEmpty:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    labelEmpty:SetText(" ")
    frame:AddChild(labelEmpty)

    local label = AceGUI:Create("Label")
    label:SetText("Seleciona a fonte de informação para aparecer a lista de BIS:")
    label:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    label:SetRelativeWidth(1)
    frame:AddChild(label)

    local labelEmpty2 = AceGUI:Create("Label")
    labelEmpty2:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    labelEmpty2:SetText(" ")
    frame:AddChild(labelEmpty2)

    local sourceDropdown = AceGUI:Create("Dropdown")
    sourceDropdown:SetCallback("OnValueChanged", function(_, _, key)
        BistooltipAddon.db.char.data_source = key
        BistooltipAddon:changeSpec(key)
    end)
    sourceDropdown:SetRelativeWidth(1)
    sourceDropdown:SetList(Bistooltip_source_to_url)
    sourceDropdown:SetValue(BistooltipAddon.db.char["data_source"])
    frame:AddChild(sourceDropdown)
end

local function migrateAddonDB()
    if not BistooltipAddon.db.char.version then
        BistooltipAddon.db.char.version = 6.1
        BistooltipAddon.db.char.class_index = 1
        BistooltipAddon.db.char.spec_index = 1
        BistooltipAddon.db.char.phase_index = 1
    end

    if BistooltipAddon.db.char.data_source == nil then
        BistooltipAddon.db.char.data_source = "wowtbc"
    end

    if BistooltipAddon.db.char.version == 6.1 then
        BistooltipAddon.db.char.version = 6.2
    end
end

local config_shown = false
function BistooltipAddon:openConfigDialog()
    if config_shown then
        InterfaceOptionsFrame_Show()
    else
        InterfaceOptionsFrame_OpenToCategory(BistooltipAddon.AceAddonName)
    end
    config_shown = not config_shown
end

local function enableSpec(spec_name)
    if spec_name == sources.wowtbc then
        Bistooltip_bislists = Bistooltip_wowtbc_bislists
        Bistooltip_items = Bistooltip_wowtbc_items
        Bistooltip_classes = Bistooltip_wowtbc_classes
        Bistooltip_phases = Bistooltip_wowtbc_phases
    else
        return
    end

    if type(Bistooltip_phases) ~= "table" then
        return
    end

    Bistooltip_phases_string = ""
    for i, phase in ipairs(Bistooltip_phases) do
        if i ~= 1 then
            Bistooltip_phases_string = Bistooltip_phases_string .. "/"
        end
        Bistooltip_phases_string = Bistooltip_phases_string .. phase
    end
end

function BistooltipAddon:addMapIcon()
    if BistooltipAddon.db.char.minimap_icon then
        icon_loaded = true
        local LDataBroker = LibStub("LibDataBroker-1.1", true)
        local LDataBrokerIcon = LDataBroker and LibStub("LibDBIcon-1.0", true)
        if LDataBroker then
            local PC_MinimapBtn = LDataBroker:NewDataObject(icon_name, {
                type = "launcher",
                text = icon_name,
                icon = "interface/icons/inv_weapon_glave_01.blp",
                OnClick = function(_, button)
                    if button == "LeftButton" then
                        BistooltipAddon:createMainFrame()
                    end
                    if button == "RightButton" then
                        BistooltipAddon:openConfigDialog()
                    end
                end,
                OnTooltipShow = function(tt)
                    tt:AddLine(BistooltipAddon.AddonNameAndVersion)
                    tt:AddLine("|cffffff00Botão Esquerdo|r para abrir a lista de items BIS")
                    tt:AddLine("|cffffff00Botão Direito|r para abrir as configurações")
                end
            })
            if LDataBrokerIcon then
                LDataBrokerIcon:Register(icon_name, PC_MinimapBtn, BistooltipAddon.db.char)
            end
        end
    end
end

function BistooltipAddon:changeSpec(spec_name)
    BistooltipAddon.db.char.class_index = 1
    BistooltipAddon.db.char.spec_index = 1
    BistooltipAddon.db.char.phase_index = 1
    enableSpec(spec_name)

    BistooltipAddon:initBislists()
    BistooltipAddon:reloadData()
end

function BistooltipAddon:initConfig()
    BistooltipAddon.db = LibStub("AceDB-3.0"):New("BisTooltipDB", db_defaults, "Default")

    migrateAddonDB()

    enableSpec(BistooltipAddon.db.char.data_source)

    LibStub("AceConfig-3.0"):RegisterOptionsTable(BistooltipAddon.AceAddonName, configTable)
    AceConfigDialog:AddToBlizOptions(BistooltipAddon.AceAddonName, BistooltipAddon.AceAddonName)
end