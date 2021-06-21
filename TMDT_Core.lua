-- core TMDT code
local addonName, tmdt = ...
local module = {}
tmdt.modules.core = module

-- tmdt module
local options, db, frame
function module.init(opt, database, addonframe)
    options, db, frame = opt, database, addonframe

    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:RegisterEvent("PLAYER_DEAD")
    frame:RegisterEvent("PLAYER_UNGHOST")
    frame:RegisterEvent("PLAYER_ALIVE")
end

-- lua locals
local format = string.format

-- module locals
local addonMsgPrefix = tmdt.addonMsgPrefix
local eventHandlers = tmdt.eventHandlers
local addonPrint = tmdt.addonPrint
local debugPrint = tmdt.debugPrint
local player = tmdt.player
local TMDTEventHandlers = {}
local deathEventBlocked = false

-- helpers
local function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end
tmdt.firstToUpper = firstToUpper

-- play a sound by "id" (usually character name)
local function play(id)
    local soundFile, errmsg = tmdt.getCharacterSound(id)

    if soundFile then
        PlaySoundFile(soundFile, options.channel)
    else
        debugPrint("getCharacterSound(%s) error: %s", id, errmsg)
    end
end
tmdt.play = play

-- makes every value in the table equal to its key
local function enumify(t)
    for k in pairs(t) do
        t[k] = k
    end

    return t
end

-- table data
local allowedInstanceTypes = {
    none = true,
    pvp = false,
    party = true,
    raid = true,
    scenario = false,
}
enumify(allowedInstanceTypes)

local addonMessageChannels = {
    PARTY = true,
    RAID = true,
    INSTANCE_CHAT = true,
    GUILD = true,
    OFFICER = true,
    WHISPER = true,
    CHANNEL = true,
    SAY = true,
    YELL = true,
}
enumify(addonMessageChannels)

-- TMDT addonMessage types
local TMDTEvent = {
    SAEL_DIED = true,
    MEMBER_DIED = true,
    OTHER_DIED = true,
}
enumify(TMDTEvent)

-- addon msg stuff
-- broadcasts a message
local function broadcast(data)
    local event, msg, channel, target = data.event, data.message, data.channel, data.target

    if not (msg and channel) then
        debugPrint("TMDT_ERROR: Missing argument to broadcast()")
        if not msg then
            debugPrint("Missing: msg")
        end
        if not channel then
            debugPrint("Missing: channel")
        end

        return
    end

    local payload = format("%s#%s", event, data.message)

    debugPrint("AddonMsg Echo <%s> %s: %s", channel, target and ("["..target.."]") or "", payload)

    if addonMessageChannels[channel] then
        C_ChatInfo.SendAddonMessage(addonMsgPrefix, payload, channel, target)
    else
        addonPrint("|cffff0000Error:|r Tried to use invalid AddonCommsChannel '%s'", channel)
    end
end

-- handle TMDT events, these are for INCOMING events.
function TMDTEventHandlers.MEMBER_DIED(name)
    if not options.muteall then
        if not db.mutedCharacters[name] then
            tmdt.play(name)
        else
            debugPrint("Skipped muted character effect: %s", name)
        end
    end
end

function TMDTEventHandlers.SAEL_DIED(character, count)
    local playerRoot = tmdt.isTMCharacter(player)

    if (playerRoot == "saelaris") or UnitInRaid(character) or UnitInParty(character) then
        -- don't do anything if we are in party with or identify as saelaris
        return
    elseif not (options.mutespecial or options.muteall) then
        print(format("|cff8f8f8fSomewhere, somehow, |cffC79C6ESaelaris|r died. Again."))
        play("saelspecial")
    end
end

-- handle WoW events
function eventHandlers.CHAT_MSG_ADDON(self, prefix, message, channel, sender, target, _, localId, channelName, _)
    if prefix == addonMsgPrefix then
        -- print(table.concat({message, channel, sender, target, channelName}, ", "))
        local eventData = {}

        for piece in string.gmatch(message, "[^#]+") do
            tinsert(eventData, piece)
        end

        -- verify that it's a valid TMDT event
        local event = eventData[1]
        if TMDTEventHandlers[event] then
            -- call event with all payload packets as arguments
            TMDTEventHandlers[event](unpack(eventData, 2))
            debugPrint("Received %s event. Payload: %s", event, table.concat(eventData, ", ", 2))
        else
            debugPrint("|cffff0000TMDTError: Received unhandled event: %s", tostring(event))
        end
    end
end

-- either of these events happening will unblock PLAYER_DEAD events
function eventHandlers.PLAYER_UNGHOST()
    debugPrint("PLAYER_DEAD unblocked!")
    deathEventBlocked = false
end
function eventHandlers.PLAYER_ALIVE()
    debugPrint("PLAYER_DEAD unblocked!")
    deathEventBlocked = false
end

function eventHandlers.PLAYER_DEAD()
    if deathEventBlocked then
        -- bail immediately, we already triggered this event very recently (bug, or player dying again REALLY FAST!)
        debugPrint("DIED TOO FAST!")
        return
    else
        -- delay the blocking for a second to prevent weird issues such as spirit of redemption "ressing" you on the same frame that you "died", thus disabling blocking...
        C_Timer.After(1, function()
            db.deathcount = db.deathcount + 1
            debugPrint("PLAYER_DEAD blocked!")
            deathEventBlocked = true
        end)
    end

    local member = tmdt.isTMCharacter(player)
    local guilded = IsInGuild() and GetGuildInfo("player") == tmdt.guildName
    local isParty = IsInGroup()
    local isRaid = IsInRaid()
    local instanced, instanceType = IsInInstance()

    if member then
        if member == "saelaris" then
            if guilded and allowedInstanceTypes[instanceType] then
                broadcast{
                    event = TMDTEvent.SAEL_DIED,
                    message = string.lower(player),
                    channel = addonMessageChannels.GUILD,
                }
            else
                -- do nothing
            end
        end

        if allowedInstanceTypes[instanceType] then
            local msgChannel

            if isParty and not isRaid then
                msgChannel = addonMessageChannels.PARTY
            elseif isParty and isRaid then
                msgChannel = addonMessageChannels.RAID
            else
                -- bail, we're in an instance, but not in a party or raid, i.e. solo
                return
            end

            broadcast{
                event = TMDTEvent.MEMBER_DIED,
                message = member,
                channel = msgChannel,
            }
        else
            -- do nothing?
        end
    end
end