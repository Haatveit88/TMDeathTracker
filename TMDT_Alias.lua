-- contains known characters and their aliases (alts)
local addonName, tmdt = ...
local module = {}
tmdt.modules.alias = module

-- tmdt module
local options, db
function module.init(opt, database)
    options, db = opt, database
end

-- tmdt locals
local characters = {
    saelaris = {
        "athall",
        "eleonar",
        "snikkels",
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

do -- sanitize the characters table to make EVERYTHING lowercase, just in *case* I make a mistake during data entry.
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