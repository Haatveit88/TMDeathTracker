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
local characterData = {}
characterData.saelaris = {
    alts = {
        "athall",
        "eleonar",
        "snikkels",
    },
    sound = "wilhelm"
}
characterData.avael = {
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
}
characterData.horricee = {
    alts = {
        "ireni",
    },
    messages = {
        "This is my first totally original and very funny message, it can include my current death <n>.",
        "Avenge me for I am slain!",
        "This is my first death ever! Wait what no shut up I haven't died <n> times!",
        "Your god has fallen, fear not however for I shall arise again, this is the <nth> time after all!",
    },
    sound = "Horrice_death"
}
characterData.becks = {
    alts = {
        "toasty",
        "bex",
        "becka",
    },
    messages = {
        "I guess Becks will be LEAF-ing now, for the <nth> time",
        "Her BARK was worse than her bite. RIP Becks.",
        "Becks has gotten to the ROOT of the problem <n> times! Her health hit zero.",
        "Becks WOOD have lived <n> times if not for the tank.",
    },
    sound = "Becks_nooooo"
}
characterData.illasei = {
    alts = {},
    messages = {},
    sound = "oopsie"
}
characterData.kimora = {
    alts = {
        "effsie",
        "tailynn",
        "zerenity",
        "myseri",
        "lizzi",
        "kinney",
        "elveera",
        "bimini",
    },
    messages = {
        "Kimora was brought to death <n> times",
        "Kimora couldn't wake up <n> times",
        "It's not been a phase, mom, for <n> times",
    },
    sound = "Kimora_Death_Jingle"
}
characterData.shaixira = {
    alts = {
        "evory",
        "rheanwyn",
        "selece",
        "nerida",
        "daranya",
        "isdra",
    },
    messages = {},
    sound = "evory_death1"
}
characterData.makesha = {
    alts = {},
    messages = {},
    sound = "You_serious",
}
characterData.yvai = {
    alts = {},
    messages = {},
    sound = "Yvai_death",
}
characterData.tyfannia = {
    alts = {},
    messages = {},
    sound = "Tyfannia_death_sound"
}
characterData.pingwing = {
    alts = {},
    messages = {},
    sound = "pingwing"
}
characterData.tharri = {
    alts = {
        "peritaph"
    },
    messages = {},
    sound = "cleese_ping"
}
characterData.neshali = {
    alts = {
        "nesharil"
    },
    messages = {},
    sound = "FFXIV_sloppy"
}
characterData.talkui = {
    alts = {
        "kimrog"
    },
    messages = {},
    sound = "FelOrcWoundCritC"
}
characterData.rugnarson = {
    alts = {
        "puna"
    },
    messages = {},
    sound = "nani"
}
characterData.akaani = {
    alts = {
        "delthea",
        "yunara",
        "kallistra"
    },
    messages = {},
    sound = "RamDeath"
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