-- contains known characters and their related data
local addonName, tmdt = ...
local module = {}
tmdt.modules.data = module

-- tmdt module
local options, db
function module.init(opt, database)
    options, db = opt, database
end

-- module locals
local characters = {
    saelaris = {
        alts = {
            "athall",
            "eleonar",
            "snikkels",
        },
        soundFile = "wilhelm"
    },
    avael = {
        "addonbabe",
        "airah",
        "manitvex",
        "ninriel",
        "mythricia",
        "hederine",
        "lorasha",
    }
}
-- sanitize the characters table to make EVERYTHING lowercase, just in *case* I make a mistake during data entry.
do
    local new = {}
    for main, alts in pairs(characters) do
        local mainLower = main:lower()
        new[mainLower] = {}

        for i, alt in pairs(alts) do
            tinsert(new[mainLower], alt:lower())
        end
    end

    characters = new
end

-- paths
local pre = "Interface\\AddOns\\TMDeathTracker\\Sounds\\"
local pre_special = "Interface\\AddOns\\TMDeathTracker\\Sounds\\wilhelm_distant\\"
local post = ".mp3"
local testsound = "wilhelm"

-- sekrit speshul
local saelspecial = {
    "wilhelm_echo_left",
    "wilhelm_echo_right",
    "wilhelm_faded_left",
    "wilhelm_faded_right",
    "wilhelm_left",
    "wilhelm_right",
}

-- retrieves a sound by mian character name
function tmdt.getCharacterSound(id)
    if id == "test" then
        return pre .. testsound .. post
    else
        local main = tmdt.isTMCharacter(id)
        if main then
            if characters[main].soundFile then
                return pre .. characters[main].soundFile .. post
            else
                return false, string.format("no soundFile: %s", main)
            end
        else
            return false, string.format("not a TM character: %s. This is a strange error, and you should screenshot this message and tell Avael.", id)
        end
    end
end

function tmdt.play(id)
    local soundFile, errmsg = tmdt.getCharacterSound(id)

    if soundFile then
        PlaySoundFile(soundFile, options.channel)
    elseif options.debug then
        print(string.format("|cffaf0000debug:|r %s", errmsg))
    end
end

-- determines if <query> belongs to a known main TM member
local function isTMCharacter(queryName)
    local name = queryName:lower()
    local mainCharacter = false

    -- try to match a character name
    for main, alts in pairs(characters) do
        if main:lower() == name then
            mainCharacter = main
        else
            for i, alt in ipairs(alts) do
                if name == alt:lower() then
                    mainCharacter = main
                    break
                end
            end
        end
    end

    return mainCharacter
end

-- patch character list if required
local function patchCharacterList(extraCharacters)
    local counter = 0
    local patched = {}

    for main, newChars in pairs(extraCharacters) do
        if characters[main] then
            for i, char in ipairs(newChars) do
                if not tContains(characters[main], char) then
                    tinsert(characters[main], char)
                    if options.debug then
                        tinsert(patched, char)
                        counter = counter + 1
                    end
                end
            end
        end
    end

    if options.debug then
        print("patched " .. counter .. " extra characters")
        table.concat(patched, ", ")
    end
end

-- make chars public for other uses
tmdt.characters = characters
tmdt.patchCharacterList = patchCharacterList
tmdt.isTMCharacter = isTMCharacter