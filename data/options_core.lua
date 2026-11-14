--=====================================================================================
-- RGX | Simple Quest Plates! - options_core.lua

-- Author: DonnieDice
-- Description: Options panel — built on RGXUI:CreateOptionsPanel
--=====================================================================================

local addonName, SQP = ...

SQP.SECTION_COLOR = {0.345, 0.745, 0.506}

function SQP:CreateOptionsPanel()
    if self.optionsPanel then
        return self.optionsPanel
    end

    local RGX = _G.RGXFramework
    local UI = RGX and RGX:GetUI() or _G.RGXUI
    if not UI then
        print("|cFFFF4444[SQP] RGXUI not available — options panel cannot be created.|r")
        return
    end

    -- Brand colours: the main colour chosen on the RGX-Framework settings page (Theme tab) while "Apply the
    -- framework theme to addons" is on, otherwise SQP's own green. Read when the panel is built; a change
    -- applies after a reload like the rest of the theme.
    local function ChosenFrameworkTheme()
        local db = _G.RGXFrameworkDB
        local preset = type(db) == "table" and db.themeOverride ~= false and db.themePreset
        local D = _G.RGXDesign
        local chosen = preset and D and D.THEME_PRESETS and D.THEME_PRESETS[preset]
        if type(chosen) ~= "table" or type(chosen.primary) ~= "table" then return nil end
        return chosen
    end
    local chosen = ChosenFrameworkTheme()
    local function Pair(c) return { c[1], c[2], c[3] } end
    local theme = {
        primary = chosen and Pair(chosen.primary) or { 0.345, 0.745, 0.506 },
        accent  = chosen and chosen.accent and Pair(chosen.accent) or { 0.737, 0.435, 0.659 },
    }

    self.optionsPanel = UI:CreateOptionsPanel({
        addonName    = "SimpleQuestPlates",
        theme        = theme,
        title        = "|cff58be81S|cffffffffimple |cff58be81Q|cffffffffuest |cff58be81P|cfffffffflates|cff58be81!|r",
        subtitle     = "Quest tracking overlay for enemy nameplates",
        author       = SQP.AUTHOR or "DonnieDice",
        website      = "|cff7289daDiscord:|r |cffffd700discord.gg/N7kdKAHVVF|r",
        brand        = "|cff8b4b5cRGX|r |cffffd700Mods|r",
        icon         = "Interface\\AddOns\\SimpleQuestPlates\\media\\logo.tga",
        openInSettings = true,
        registerInSettings = true,
        bannerHeight = 88,
        banner       = function(frame)
            SQP.previewFrame = SQP:CreatePreviewSection(frame)
        end,
        tabs = {
            { text = "General", content = function(f) SQP:CreateGlobalOptions(f) end },
            { text = "Kill",    content = function(f) SQP:CreateKillOptions(f) end,
              onSelect = function() if SQP.previewFrame then SQP.previewFrame.activateKillMode() end end },
            { text = "Loot",   content = function(f) SQP:CreateLootOptions(f) end,
              onSelect = function() if SQP.previewFrame then SQP.previewFrame.activateLootMode() end end },
            { text = "Percent", content = function(f) SQP:CreatePercentOptions(f) end,
              onSelect = function() if SQP.previewFrame then SQP.previewFrame.activatePercentMode() end end },
            { text = "About",  content = function(f) SQP:CreateAboutSection(f) end },
        },
    })

    return self.optionsPanel
end

function SQP:OpenOptions()
    if InCombatLockdown() then
        self:PrintMessage(self.L["ERROR_COMBAT_LOCKDOWN"] or "Cannot open options during combat.")
        return
    end
    if not self.optionsPanel then
        self:CreateOptionsPanel()
    end
    if self.optionsPanel then self.optionsPanel:Open() end
end

StaticPopupDialogs["SQP_RESET_CONFIRM"] = {
    text = "|cff58be81Simple Quest Plates!|r\n\nAre you sure you want to reset all settings to defaults?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        SQP:ResetSettings()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}
