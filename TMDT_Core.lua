-- core TMDT code
local addonName, tmdt = ...
local module = {}
tmdt.modules.core = module

-- tmdt module
local options, db
function module.init(opt, database)
    options, db = opt, database
end

-- lua locals
local format = string.format

-- tmdt locals
local addonMsgPrefix = tmdt.addonMsgPrefix
local eventHandlers = tmdt.eventHandlers

local colors = {
    tmg = "|cff00af00",
    tmr = "|cffff0000",
    tmp = "|cffff00ff",
}

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

-- helpers
function tmdt.firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

function tmdt.addonPrint(msg)
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
local function broadcast(msg, channel, target)
    if options.debug then
        print(format("TMDT_MsgEcho<%s>%s: %s", channel, target and ("["..target.."]") or "", msg))
    end

    if addonMessageChannels[channel] then
        C_ChatInfo.SendAddonMessage(addonMsgPrefix, msg, addonMessageChannels[channel], target)
    else
        tmdt.addonPrint(format("|cffff0000Error:|r Tried to use invalid AddonCommsChannel '%s'", channel))
    end
end

function eventHandlers.PLAYER_DEAD()
    local player = UnitName("player")
    if tmdt.isTMCharacter(player) then
        --print(format("%s died", player))
        local msg = player .. " died."

        broadcast(msg, addonMessageChannels.GUILD)
    end
end

function eventHandlers.CHAT_MSG_ADDON(prefix, message, channel, sender, target, _, localId, channelName, _)
    if prefix == addonMsgPrefix then
        print(table.concat({message, channel, sender, target, channelName}, ", "))
    end
end