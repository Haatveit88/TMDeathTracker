-- handles slash commands
local addonName, tmdt = ...
local module = {}
tmdt.modules.slash = module

-- tmdt module
local options, db
function module.init(opt, database)
    options, db = opt, database
end

-- tmdt locals
local addonPrint = tmdt.addonPrint
local play = tmdt.play
local firstToUpper = tmdt.firstToUpper

-- localise lua stuff
local format = string.format

-- misc data
local validChannels
do
    local channelList = {
        master = "Master",
        sfx = "SFX",
        music = "Music",
        ambience = "Ambience",
        dialog = "Dialog",
    }
    local channelList_mt = {
        __call = function(t)
            local str = ""
            for k in pairs(t) do
                str = str .. k .. ", "
            end
            str = str:sub(1, #str-2)

            return str
        end
    }
    validChannels = setmetatable(channelList, channelList_mt)
end

-- SLASH_XX setup
SLASH_TMDT1 = "/tmdt"

-- holds all the final command handlers
local handler = {}
handler.testPlay = {
    command = function()
        C_Timer.After(0.1, function()
            play("test")
        end)
        C_Timer.After(0.2, function()
            play("test")
        end)
        C_Timer.After(0.3, function()
            play("test")
        end)
    end,

    debugOnly = true,
}

handler.toggleMute = {
    command = function()
        options.muted = not options.muted
        local newState = options.muted and ("|cffff0000" .. "muted") or ("|cff00ff00" .. "unmuted")
        addonPrint(newState)
    end,
}

handler.toggleSelf = {
    command = function()
        options.self = not options.self
        local newState = options.self and ("|cff00ff00" .. "enabled") or ("|cffff0000" .. "disabled")
        addonPrint("play on self " .. newState)
    end,
}

handler.toggleDebug = {
    command = function()
        options.debug = not options.debug
        local newState = options.debug and ("|cff00ff00" .. "enabled") or ("|cffff0000" .. "disabled")
        addonPrint("debug is " .. newState)
    end,
}

handler.setGetChannel = {
    command = function(args)
        if type(args[2]) == "string" then
            local channel = validChannels[strtrim(args[2])]
            if channel then
                addonPrint("Changed output channel to '" .. channel .. "'")
                options.channel = channel
            else
                addonPrint(format("Invalid output channel '%s'! Must be one of: [%s]", args[2], validChannels()))
            end
        else
            addonPrint("Current output channel is '" .. options.channel .. "'")
        end
    end,
}

handler.getAlts = {
    command = function(args)
        local main = strtrim(args[2])

        if tmdt.isTMCharacter(main) then
            if #tmdt.characters[main] > 0 then
                local alts = table.concat(tmdt.characters[main], ", ")
                addonPrint(format("%s has %i alts: [%s]", firstToUpper(main), #tmdt.characters[main], alts))
            else
                addonPrint(format("%s has no alts", firstToUpper(main)))
            end
        else
            addonPrint(format("No known TM main characters called %s", firstToUpper(main)))
        end
    end,
}

handler.setAlt = {
    command = function(args)
        if args[2] then
            local main = strtrim(args[2])
            if args[3] then -- setting new alt
                local newalt = strtrim(args[3])

                if tmdt.isTMCharacter(main) then
                    db.extraCharacters = db.extraCharacters or {}
                    local dbec = db.extraCharacters
                    if not dbec[main] then dbec[main] = {} end

                    if tContains(dbec[main], newalt) then
                        addonPrint(format("Alt %s already added to %s", firstToUpper(newalt), firstToUpper(main)))
                    else
                        if not dbec[main] then
                            dbec[main] = {}
                        end
                        tinsert(dbec[main], newalt)
                        tmdt.patchCharacterList(db.extraCharacters)

                        addonPrint(format("created a new alt for main %s called %s", firstToUpper(main), firstToUpper(newalt)))
                    end
                else
                    addonPrint(format("No known TM main characters called %s, no alt added", firstToUpper(main)))
                end
            end
        end
    end,
}

handler.removeAlt = {
    command = function(args)
        local main = strtrim(args[2])
        local alt = strtrim(args[3])

        if tmdt.isTMCharacter(main) then
            local dbec = db.extraCharacters
            if dbec[main] then
                local found = false
                for i, name in pairs(dbec[main]) do
                    if name == alt then
                        table.remove(dbec[main], i)
                        found = true
                    end
                end

                if not next(dbec[main]) then
                    dbec[main] = nil
                end

                if found then
                    addonPrint(format("deleted alt %s for main %s", firstToUpper(alt), firstToUpper(main)))
                else
                    addonPrint(format("unknown alt %s for main %s", firstToUpper(alt), firstToUpper(main)))
                end
            else
                addonPrint(format("main %s has no alts to remove", firstToUpper(main)))
            end
        else
            addonPrint(format("No known TM main characters called %s, no alt removed", firstToUpper(main)))
        end
    end,
}

handler.queryName = {
    command = function(args)
        if args[2] then
            local query = firstToUpper(args[2])
            local mainCharacter = firstToUpper(tmdt.isTMCharacter(query))
            print(format("|cffaa0000tmdt debug:|r \"%s\" %s", query, mainCharacter and format("is a known TM character (main: \"%s\")", mainCharacter) or ("is NOT a known TM character")))
        end
    end,
}

handler.fakeDeathEvent = {
    command = function(args)
        play(firstToUpper(args[2]))
        print("|cffaf0000Fake death: " .. args[2])
    end,

    debugOnly = true,
}

handler.fakeSaelEvent = {
    command = function()
        play("saelspecial")
    end,

    debugOnly = true,
}

handler.wipeSettings = {
    command = function()
        addonPrint("Wiped settings & (extra) alt database")
        wipe(db.extraCharacters)
        wipe(TMDT_Options)
        tmdt.verifyOptions()
    end,
}

handler.help = {
    command = function(args)
        addonPrint("Valid commands for TMDT are;")
        for label, cmd in pairs(handler) do
            local str
            local desc = ""

            if cmd.debugOnly then
                if options.debug then
                    str = "|cffaf0000[DEBUG] |cffaaaa00%s    %s"
                end
            else
                str = "|cff00aa00%s    %s"
            end

            if str then
                if cmd.description then
                    desc = "|cff050505"..cmd.description.."|r"
                end

                print(format(str, label, desc))
            end
        end
    end
}

-- picks the appropriate handler based on keywords / aliases
local commandAlias = {
    mute = handler.toggleMute,
    self = handler.toggleSelf,
    channel = handler.setGetChannel,

    -- character db stuff
    setalt = handler.setAlt,
    addalt = handler.setAlt,
    alts = handler.getAlts,
    listalts = handler.getAlts,
    removealt = handler.removeAlt,

    -- misc
    wipe = handler.wipeSettings,
    help = handler.help,

    -- debug-ish stuff
    test = handler.testPlay,
    query = handler.queryName,
    fake = handler.fakeDeathEvent,
    fakespecial = handler.fakeSaelEvent,
    debug = handler.toggleDebug,
}

-- handlers incoming slash cmd and dispatches to handler if valid alias match can be made
local function commandHandler(msg, EditBox)
    msg = strtrim(msg)

    -- split into parts
    local args = {}
    for word in string.gmatch(msg, "[^ ]+") do
        tinsert(args, word:lower()) -- ALL INCOMING WORDS ARE TRIMMED AND LOWERCASED
    end

    local cmd = args[1] or nil
    if not cmd then
        addonPrint("No command.")
        return false
    else
        if commandAlias[cmd] then
            commandAlias[cmd].command(args)
        else
            if msg ~= "" then
                addonPrint("Unknown command \"".. msg .."\".")
                return
            end
        end
    end
end

SlashCmdList["TMDT"] = commandHandler