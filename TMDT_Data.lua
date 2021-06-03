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
        alts = {
            "addonbabe",
            "airah",
            "manitvex",
            "ninriel",
            "mythricia",
            "hederine",
            "lorasha",
        },
    }
}
-- sanitize the characters table to make EVERYTHING lowercase, just in *case* I make a mistake during data entry.
do
    local new = {}
    for main, data in pairs(characters) do
        new[main:lower()] = {
            alts = {}
        }

        for _, alt in pairs(data.alts) do
            tinsert(new[main:lower()].alts, alt:lower())
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
    elseif id == "saelspecial" then
        return pre_special .. saelspecial[math.random(1, #saelspecial)] .. post
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

-- determines if <query> belongs to a known main TM member
local function isTMCharacter(queryName)
    queryName = queryName:lower()

    -- try to match a character name
    for main, data in pairs(characters) do
        if queryName == main then
            return main
        else
            for i, alt in ipairs(data.alts) do
                if queryName == alt then
                    return main
                end
            end
        end
    end

    return false
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