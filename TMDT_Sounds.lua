-- handles sound effect stuff
local addonName, tmdt = ...
local module = {}
tmdt.modules.sounds = module

-- tmdt module
local options, db
function module.init(opt, database)
    options, db = opt, database
end

-- lua locals

-- paths
local pre = "Interface\\AddOns\\TMDeathTracker\\Sounds\\"
local pre_special = "Interface\\AddOns\\TMDeathTracker\\Sounds\\wilhelm_distant\\"
local post = ".mp3"
local testsound = "wilhelm"

local sounds = {
    characters = {
        saelaris = "wilhelm",
    },
    saelspecial = {
        "wilhelm_echo_left",
        "wilhelm_echo_right",
        "wilhelm_faded_left",
        "wilhelm_faded_right",
        "wilhelm_left",
        "wilhelm_right",
    }
}

function tmdt.getSound(id)
    if id == "test" then
        return pre .. testsound .. post
    elseif id == "saelspecial" then
        local pick = sounds.saelspecial[math.random(1, #sounds.saelspecial)]
        return pre_special .. pick .. post
    end

    local main = tmdt.isTMCharacter(id)
    if main then
        if sounds.characters[main] then
            return pre .. sounds.characters[main] .. post
        else
            return false, string.format("no sound effect: %s", main)
        end
    else
        return false, string.format("not a TM character: %s", id)
    end
end

function tmdt.play(id)
    local sound, errmsg = tmdt.getSound(id)

    if sound then
        PlaySoundFile(sound, options.channel)
    elseif options.debug then
        print(string.format("|cffaf0000debug:|r %s", errmsg))
    end
end