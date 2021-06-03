-- handles initial setup, savedvariables, and initial event registration
local addonName, tmdt = ...
tmdt.modules = {}

-- event frame setup --
-----------------------
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

-- lua locals
local format = string.format

-- TMDT locals
local addonMsgPrefix = "TMDTMsg"
local eventHandlers = {}
local options = {}
local db = {}

-- option handling
local function verifyOptions()
    local opts = {
        channel = "Master",
        muted = false,
        self = false,
        debug = false,
    }

    for k, v in pairs(opts) do
        if not TMDT_Options[k] then
            TMDT_Options[k] = v
        end
    end
end

-- init or patch db
local function verifyDB()
    local dbstruct = {
        extraCharacters = {},
        deathcount = {},
    }

    for k, v in pairs(dbstruct) do
        if not db[k] then
            db[k] = v
        end
    end
end

-- handle addon load complete
function eventHandlers.ADDON_LOADED(self, ...)
    if ... == addonName then
        frame:UnregisterEvent("ADDON_LOADED")

        -- Hook up SavedVariables: TMDT_Options, TMDT_DB
        TMDT_Options = TMDT_Options or {}
        options = TMDT_Options
        verifyOptions()

        TMDT_DB = TMDT_DB or {}
        db = TMDT_DB
        verifyDB()

        -- initialize all other addon files now that we have the SavedVariables figured out
        for name, mod in pairs(tmdt.modules) do
            mod.init(options, db, frame)

            if options.debug then
                print(format("tmdt initialized module [%s]", name))
            end
        end

        if db.extraCharacters then
            tmdt.patchCharacterList(db.extraCharacters)
        end

        local identity = tmdt.isTMCharacter(UnitName("player"))
        tmdt.addonPrint("Loaded. You are %s%s|r.", identity and "|cff00aa00" or "|cffaa0000", identity and tmdt.firstToUpper(identity) or "not a recognized TM member")
    end
end

function eventHandlers.PLAYER_ENTERING_WORLD(self, ...)
    if not C_ChatInfo.IsAddonMessagePrefixRegistered(addonMsgPrefix) then
        C_ChatInfo.RegisterAddonMessagePrefix(addonMsgPrefix)
    end
end

-- hook up events to handlers
frame:SetScript("OnEvent", function(self, event, ...)
    if eventHandlers[event] then
        eventHandlers[event](self, ...)
    end
end)

-- gather and export some info
tmdt.player = GetUnitName("player")
tmdt.playerClass  = UnitClassBase("player")

-- export some stuff to addon namespace
tmdt.addonMsgPrefix = addonMsgPrefix
tmdt.eventHandlers = eventHandlers
tmdt.frame = frame
tmdt.options = options
tmdt.db = db
tmdt.verifyOptions = verifyOptions