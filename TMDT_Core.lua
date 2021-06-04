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
end

-- lua locals
local format = string.format

-- module locals
local addonMsgPrefix = tmdt.addonMsgPrefix
local eventHandlers = tmdt.eventHandlers
local addonPrint = tmdt.addonPrint
local debugPrint = tmdt.debugPrint
local player = UnitName("player")

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
    none = false,
    pvp = false,
    party = true,
    raid = true,
    scenario = true,
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
-- TMDT event handlers, these handle INCOMING events.
local TMDTEventHandlers = {}
function TMDTEventHandlers.MEMBER_DIED(name)
    tmdt.play(name)
end
_G["TMDTTEST"] = TMDTEventHandlers -- !!!! FIXME: This should not be here !!!!

function TMDTEventHandlers.SAEL_DIED(character, count)
    if not options.mutespecial then
        if (UnitInRaid(character) or UnitInParty(character)) then
            -- do nothing, we're already grouped with Sael, don't want to double up his sounds
        else
            print(format("|cff8f8f8fSomewhere, somehow, |cffC79C6ESaelaris|r died. Again."))
            play("saelspecial")
        end
    end
end

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
            debugPrint("dispatched %s event. Payload: %s", event, table.concat(eventData, ", ", 2))
        else
            debugPrint("|cffff0000TMDTError: Unhandled event: %s", tostring(event))
        end
    end
end

function eventHandlers.PLAYER_DEAD()
    local member = tmdt.isTMCharacter(player)
    local guilded = IsInGuild() and GetGuildInfo("player") == tmdt.guildName
    local instanced, instanceType = IsInInstance()

    if member then
        if member == "saelaris" then
            if options.debug then
                broadcast{
                    event = TMDTEvent.SAEL_DIED,
                    message = tostring(db.deathcount),
                    channel = addonMessageChannels.WHISPER,
                    target = "Addonbabe"
                }
            elseif guilded then
                broadcast{
                    event = TMDTEvent.SAEL_DIED,
                    message = tostring(db.deathcount),
                    channel = addonMessageChannels.GUILD,
                }
            else
                -- do nothing
            end
        end

        if options.debug then
            broadcast{
                event = TMDTEvent.MEMBER_DIED,
                message = member,
                channel = addonMessageChannels.WHISPER,
                target = player
            }
        elseif allowedInstanceTypes[instanceType] then
            local msgChannel

            if instanceType == allowedInstanceTypes.party then
                msgChannel = addonMessageChannels.PARTY
            elseif instanceType == allowedInstanceTypes.raid then
                msgChannel = addonMessageChannels.RAID
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