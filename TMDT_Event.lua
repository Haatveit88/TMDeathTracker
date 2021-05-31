-- custom event msg generation for TMDT
local addonName, tmdt = ...
local module = {}
tmdt.modules.event = module

-- tmdt module
local options, db
function module.init(opt, database)
    options, db = opt, database
end

-- lua locals
local format = string.format