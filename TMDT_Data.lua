-- contains known characters and their related data
local addonName, tmdt = ...
local module = {}
tmdt.modules.data = module

-- tmdt module
local options, db
function module.init(opt, database)
    options, db = opt, database
end

-- tmdt locals
local debugPrint = tmdt.debugPrint

--------------------
-- Character Data --
--------------------
local characterData = {
    saelaris = {
        alts = {
            "athall",
            "eleonar",
            "snikkels",
        },
        sound = "wilhelm"
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
        sound = "winxp_error"
    },
    horricee = {
        alts = {
            "ireni"
        },
        messages = {
            "This is my first totally original and very funny message, it can include my current death <n>.",
            "Avenge me for I am slain!",
            "This is my first death ever! Wait what no shut up I haven't died <n> times!",
            "Your god has fallen, fear not however for I shall arise again, this is the <ordinal> time after all!",
        },
        sound = "Horrice_death"
    }
}


-- check the characters table to make sure ALL NAMES are lowercase, and scream in your face if some aren't.
do
    local bad = {}
    for _, data in pairs(characterData) do
        for _, alt in pairs(data.alts) do
            if alt:match("[A-Z]") then
                tinsert(bad, alt)
            end
        end
    end

    if next(bad) then
        C_Timer.After(1, function()
            debugPrint("BAD! VERY BAD! There are characters with Capital Letters in the TMDT character database:")
            debugPrint(table.concat(bad, ", "))
        end)
    end
end


-- ship it
tmdt.characterData = characterData