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
end

-- lua locals
local format = string.format

-- module locals
local addonMsgPrefix = tmdt.addonMsgPrefix
local eventHandlers = tmdt.eventHandlers
local addonMessageChannels = {
    PARTY = "PARTY",
    RAID = "RAID",
    INSTANCE_CHAT = "INSTANCE_CHAT",
    GUILD = "GUILD",
    OFFICER = "OFFICER",
    WHISPER = "WHISPER",
    CHANNEL = "CHANNEL",
    SAY = "SAY",
    YELL = "YELL",
}

local colors = {
    tmg = "|cff00af00",
    tmr = "|cffff0000",
    tmp = "|cffff00ff",
}

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
local function broadcast(msg, channel, target)
    if options.debug then
        print(format("TMDT_MsgEcho<%s>%s: %s", channel, target and ("["..target.."]") or "", msg))
    end

    if addonMessageChannels[channel] then
        C_ChatInfo.SendAddonMessage(addonMsgPrefix, msg, channel, target)
    else
        tmdt.addonPrint(format("|cffff0000Error:|r Tried to use invalid AddonCommsChannel '%s'", channel))
    end
end

function eventHandlers.CHAT_MSG_ADDON(prefix, message, channel, sender, target, _, localId, channelName, _)
    if prefix == addonMsgPrefix then
        print(table.concat({message, channel, sender, target, channelName}, ", "))
    end
end