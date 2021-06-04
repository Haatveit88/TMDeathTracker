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
-- enum-i-fy addonMessageChannels
for k, v in pairs(addonMessageChannels) do
    addonMessageChannels[k] = k
end

-- TMDT addonMessage types
local TMDTEvent = {
    SAEL_DIED = true,
    MEMBER_DIED = true,
    OTHER_DIED = true,
}
-- enum-i-fy eventTypes
for k, v in pairs(TMDTEvent) do
    TMDTEvent[k] = k
end

local player = UnitName("player")

-- helpers
function tmdt.firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

local function compoundMatch(str, matches)
    for i, m in ipairs(matches) do
        if str:match(m) then
            return true
        end
    end

    return false
end

function tmdt.play(id)
    local soundFile, errmsg = tmdt.getCharacterSound(id)

    if soundFile then
        PlaySoundFile(soundFile, options.channel)
    else
        debugPrint("|cffaf0000debug:|r %s", errmsg)
    end
end

-- addon msg stuff
-- TMDT event handlers, these handle INCOMING events.
local TMDTEventHandler = {}
function TMDTEventHandler.MEMBER_DIED(name)
    tmdt.play(name)
    debugPrint("recieved MEMBER_DIED event for: %s", name)
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
        if TMDTEventHandler[event] then
            -- call event with all payload packets as arguments
            TMDTEventHandler[event](unpack(eventData, 2))
        else
            debugPrint("|cffff0000TMDTError: Unhandled event: %s", tostring(event))
        end
    end
end

function eventHandlers.PLAYER_DEAD()
    local member = tmdt.isTMCharacter(player)

    if member then
        if member == "saelaris" then
            broadcast{
                event = TMDTEvent.SAEL_DIED,
                message = "again",
                channel = addonMessageChannels.GUILD,
            }
        end

        if options.debug then
            broadcast{
                event = TMDTEvent.MEMBER_DIED,
                message = member,
                channel = addonMessageChannels.WHISPER,
                target = player
            }
        else
            broadcast{
                event = TMDTEvent.MEMBER_DIED,
                message = member,
                channel = addonMessageChannels.RAID,
            }
        end
    end
end