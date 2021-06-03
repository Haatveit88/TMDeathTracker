-- core TMDT code
local addonName, tmdt = ...
local module = {}
tmdt.modules.core = module

-- module locals
local enableTMDT
local disableTMDT

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
local eventType = {
    SAEL_DIED = true,
    MEMBER_DIED = true,
    OTHER_DIED = true,
}
-- enum-i-fy eventTypes
for k, v in pairs(eventType) do
    eventType[k] = k
end

local colors = {
    tmg = "|cff00af00",
    tmr = "|cffff0000",
    tmp = "|cffff00ff",
}

local player = UnitName("player")

-- helpers
function tmdt.firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

function tmdt.addonPrint(msg, ...)
    if ... then
        msg = format(msg, ...)
    end

    print(format("%sTM|r%sDT|r:: %s", colors.tmg, colors.tmp, msg))
end

local function compoundMatch(str, matches)
    for i, m in ipairs(matches) do
        if str:match(m) then
            return true
        end
    end

    return false
end

-- addon msg stuff
-- broadcasts a message
local function broadcast(data)
    local event, msg, channel, target = data.event, data.message, data.channel, data.target

    if not (msg and channel) then
        print("TMDT_ERROR: Missing argument to broadcast()")
        if not msg then
            print("Missing: msg")
        end
        if not channel then
            print("Missing: channel")
        end

        return
    end

    local payload = format("%s#%s", event, data.message)

    if options.debug then
        print(format("TMDT_MsgEcho<%s>%s: %s", channel, target and ("["..target.."]") or "", payload))
    end

    if addonMessageChannels[channel] then
        C_ChatInfo.SendAddonMessage(addonMsgPrefix, payload, channel, target)
    else
        tmdt.addonPrint(format("|cffff0000Error:|r Tried to use invalid AddonCommsChannel '%s'", channel))
    end
end

-- handle WoW events
function eventHandlers.CHAT_MSG_ADDON(self, prefix, message, channel, sender, target, _, localId, channelName, _)
    if prefix == addonMsgPrefix then
        -- print(table.concat({message, channel, sender, target, channelName}, ", "))
        local pieces = {}
        --for word in string.gmatch(msg, "[^ ]+") do
        for piece in string.gmatch(message, "[^#]+") do
            tinsert(pieces, piece)
        end

        for k, v in ipairs(pieces) do
            print(k, v)
        end
    end
end

function eventHandlers.PLAYER_DEAD()
    local member = tmdt.isTMCharacter(player)
    if member then
        if member == "avael" then
            broadcast{
                event = eventType.SAEL_DIED,
                message = "again",
                channel = addonMessageChannels.WHISPER,
                target = "Addonbabe"
            }
        else
            broadcast{
                event = eventType.MEMBER_DIED,
                message = member,
                channel = addonMessageChannels.WHISPER,
                target = "Addonbabe"
            }
        end
    else
        broadcast{
            event = eventType.OTHER_DIED,
            message = UnitName("player"),
            channel = addonMessageChannels.WHISPER,
            target = "Addonbabe"
        }
    end
end