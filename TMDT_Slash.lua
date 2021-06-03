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
local commandAlias

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
local handlers = {}
handlers.help = {
    command = function()
        addonPrint("Valid commands for TMDT are;")

        for label, cmd in pairs(handlers) do
            local argHint = cmd.hint or ""
            local debug = ""
            local desc = ""
            local skip = false

            -- add debug flag?
            if cmd.debug then
                if options.debug then
                    debug = " |cffaf0000[DEBUG]|r "
                else
                    skip = true
                end
            end

            if not skip then

                -- add command aliases
                local aliases = {}
                for key, handler in pairs(commandAlias) do
                    if handler == cmd then
                        aliases[#aliases+1] = key
                    end
                end
                local slashCmds = ("|cff00f000/tmdt %s|r "):format(table.concat(aliases, ", "))

                -- add argument hint?
                if argHint then
                    argHint = "|cffC0C0C0" .. argHint .. "|r"
                end

                -- add description
                if cmd.description then
                    desc = "\n  > |cffC0FFFF"..cmd.description.."|r"
                end

                print(slashCmds .. argHint .. debug .. desc)
            else
                -- do nothing
            end
        end
    end,

    description = "Shows you this very list, that you are already reading..."
}

handlers.testPlay = {
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

    debug = true,

    description = "Plays a triple wilhelm scream."
}

handlers.toggleMute = {
    command = function()
        options.muted = not options.muted
        local newState = options.muted and ("|cffff0000" .. "muted") or ("|cff00ff00" .. "unmuted")
        addonPrint(newState)
    end,

    description = "Toggles muting TMDT."
}

handlers.toggleSelf = {
    command = function()
        options.self = not options.self
        local newState = options.self and ("|cff00ff00" .. "enabled") or ("|cffff0000" .. "disabled")
        addonPrint("play on self " .. newState)
    end,

    description = "Toggles muting your own death announces / sound effect."
}

handlers.toggleDebug = {
    command = function()
        options.debug = not options.debug
        local newState = options.debug and ("|cff00ff00" .. "enabled") or ("|cffff0000" .. "disabled")
        addonPrint("debug is " .. newState)
    end,

    description = "Toggles debugging mode (don't touch unless Av told you to).",
    debug = true
}

handlers.setGetChannel = {
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
            addonPrint("Current output channel is '" .. options.channel .. "'. Options are: " .. validChannels())
        end
    end,

    description = "Sets which audio channel is used to play TMDT effects. If used with no arguments, shows current setting.",
    hint = "<sound channel>",
}

handlers.getAlts = {
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

    description = "Lists all registered alts for a main character.",
    hint = "<main name>"
}

handlers.setAlt = {
    command = function(args)
        if args[2] then
            local main = strtrim(args[2])
            if args[3] then -- setting new alt
                local newalt = strtrim(args[3])

                if tmdt.isTMCharacter(main) then
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

    description = "Add a new alt to a known TM main character.",
    hint = "<main name> <alt name>",
}

handlers.removeAlt = {
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

    description = "Remove an alt from a known main. Only works for alts you added via /tmdt setalt",
    hint = "<main name> <alt name>",
}

handlers.queryName = {
    command = function(args)
        if args[2] then
            local query = firstToUpper(args[2])
            local tmChar = tmdt.isTMCharacter(query)
            local mainCharacter = tmChar and firstToUpper(tmChar) or false
            tmdt.addonPrint(format("\"%s\" %s", query, mainCharacter and format("is a known TM character (main: \"%s\")", mainCharacter) or ("is NOT a known TM character")))
        end
    end,

    description = "Check whether a character name is recognized in TMDT, searches all mains and alts.",
    hint = "<name to query>",
}

handlers.fakeDeathEvent = {
    command = function(args)
        play(firstToUpper(args[2]))
        print("|cffaf0000Fake death: " .. args[2])
    end,

    debug = true,
    description = "Play sound and show a notification as if <character> died. Does not increase death counter nor show for other people.",
    hint = "<character name>"
}

handlers.fakeSaelEvent = {
    command = function()
        play("saelspecial")
    end,

    description = "Hmm. Mysterious.",
    debug = true,
}

handlers.wipeSettings = {
    command = function()
        addonPrint("Wiped settings & (extra) alt database")
        wipe(db.extraCharacters)
        wipe(TMDT_Options)
        tmdt.verifyOptions()
    end,

    description = "Wipes out your TMDT settings and your custom alt database, if any.",
}

-- picks the appropriate handler based on keywords / aliases
commandAlias = {
    mute = handlers.toggleMute,
    self = handlers.toggleSelf,
    channel = handlers.setGetChannel,

    -- character db stuff
    setalt = handlers.setAlt,
    addalt = handlers.setAlt,
    alts = handlers.getAlts,
    listalts = handlers.getAlts,
    removealt = handlers.removeAlt,

    -- misc
    wipe = handlers.wipeSettings,
    help = handlers.help,

    -- debug-ish stuff
    test = handlers.testPlay,
    query = handlers.queryName,
    fake = handlers.fakeDeathEvent,
    fakespecial = handlers.fakeSaelEvent,
    debug = handlers.toggleDebug,
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