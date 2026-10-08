form = nil

WIDTH = 400
HEIGHT = 200
LINESIZE = 13
TEXTBOXSIZE = 22

------ Static addresses ------
ADDR_gItemManager = 0x027e0fb4
ADDR_gPlayerManager = 0x027e0fbc
ADDR_gAdventureFlags = 0x027e0f74
ADDR_gPlayer = 0x027e0fec
ADDR_gOverlayManager_mLoadedOverlays_4 = 0x027e0910
ADDR_gMapManager = 0x027e0e60

function main()
    form = forms.newform(WIDTH, HEIGHT, "AP rando")
    local form_y = 0

    -- label(formhandle, caption, x, y, width, height, fixedwidth)
    -- textbox(formhandle, caption, width, height, boxtype, x, y, multiline, fixedwidth, scrollbars)
    -- button(formhandle, caption, clickevent, x, y, width, height)
    -- dropdown(formhandle, items, x, y, width, height)
    -- checkbox(formhandle, caption, x, y)
    -- ischecked(handle)

    ------ Give items ------
    BUTTON_WIDTH = 50
    BUTTON_HEIGHT = 20
    INPUT_X = BUTTON_WIDTH * 2 + 10
    INPUT_WIDTH = WIDTH - INPUT_X
    local dropdown_Item = forms.dropdown(form, keys(ITEM_TYPES), INPUT_X, form_y, INPUT_WIDTH, BUTTON_HEIGHT)
    local callback = function()
        local item_name = forms.gettext(dropdown_Item)
        local item = ITEM_TYPES[item_name]
        give_item(item)
    end
    forms.button(form, "Give:", callback, 0, form_y, BUTTON_WIDTH, BUTTON_HEIGHT)
    local callback = function()
        local item_name = forms.gettext(dropdown_Item)
        local item = ITEM_TYPES[item_name]
        take_item(item)
    end
    forms.button(form, "Take:", callback, BUTTON_WIDTH, form_y, BUTTON_WIDTH, BUTTON_HEIGHT)
    form_y = form_y + BUTTON_HEIGHT + 10

    ------ Give rupees ------
    forms.label(form, "Rupees:", 0, form_y, WIDTH, LINESIZE)
    form_y = form_y + LINESIZE + 5
    forms.button(form, "+1", give_rupees_cb(1), 0, form_y, BUTTON_WIDTH, BUTTON_HEIGHT)
    forms.button(form, "+5", give_rupees_cb(5), BUTTON_WIDTH, form_y, BUTTON_WIDTH, BUTTON_HEIGHT)
    forms.button(form, "+10", give_rupees_cb(10), BUTTON_WIDTH * 2, form_y, BUTTON_WIDTH, BUTTON_HEIGHT)
    forms.button(form, "+20", give_rupees_cb(20), BUTTON_WIDTH * 3, form_y, BUTTON_WIDTH, BUTTON_HEIGHT)
    forms.button(form, "+100", give_rupees_cb(100), BUTTON_WIDTH * 4, form_y, BUTTON_WIDTH, BUTTON_HEIGHT)
    forms.button(form, "+200", give_rupees_cb(200), BUTTON_WIDTH * 5, form_y, BUTTON_WIDTH, BUTTON_HEIGHT)
    forms.button(form, "+300", give_rupees_cb(300), BUTTON_WIDTH * 6, form_y, BUTTON_WIDTH, BUTTON_HEIGHT)
    form_y = form_y + BUTTON_HEIGHT
    forms.button(form, "-10", give_rupees_cb(-10), 0, form_y, BUTTON_WIDTH, BUTTON_HEIGHT)
    forms.button(form, "-50", give_rupees_cb(-50), BUTTON_WIDTH, form_y, BUTTON_WIDTH, BUTTON_HEIGHT)
    form_y = form_y + BUTTON_HEIGHT + 10

    ------ Give keys ------
    forms.label(form, "Small keys:", 0, form_y, WIDTH, LINESIZE)
    form_y = form_y + LINESIZE + 5
    local callback = function()
        give_item(ITEM_TYPES["Small Key"])
    end
    forms.button(form, "Give", callback, 0, form_y, BUTTON_WIDTH, BUTTON_HEIGHT)
    local callback = function()
        take_item(ITEM_TYPES["Small Key"])
    end
    forms.button(form, "Take", callback, BUTTON_WIDTH, form_y, BUTTON_WIDTH, BUTTON_HEIGHT)
    form_y = form_y + BUTTON_HEIGHT + 10

    ------ Speed up boat ------
    BUTTON_WIDTH = 150
    local checkbox_SpeedUpShip forms.checkbox(form, "Speed up ship", 0, form_y)
    form_y = form_y + BUTTON_HEIGHT + 10

    ------ Button to set initial adventure flags ------
    local callback = set_initial_adventure_flags
    forms.button(form, "Set initial adventure flags", callback, 0, form_y, BUTTON_WIDTH, TEXTBOXSIZE)

    ------ Game loop ------
    while true do
        if forms.ischecked(checkbox_SpeedUpShip) then
            speedup_boat()
        end

        emu.frameadvance()
    end
end

ItemType = {
    item_flag = nil,         -- Sets mItemFlags on gItemManager
    adventure_flag = nil,    -- Sets mFlags on gAdventureFlags
    heart_container = false, -- Sets mMaxHealth on gPlayerManager
    sand_of_hours = false,   -- Sets mHourglassSandFrames on gItemManager
    bomb_bag = nil,          -- Sets mBombBagSize on gItemManager
    bombchu_bag = nil,       -- Sets mBombchuBagSize on gItemManager
    quiver = nil,            -- Sets mQuiverSize on gItemManager
    power_gem = nil,         -- Sets mNumGems[Gem_Power] on gItemManager
    wisdom_gem = nil,        -- Sets mNumGems[Gem_Wisdom] on gItemManager
    courage_gem = nil,       -- Sets mNumGems[Gem_Courage] on gItemManager
}
function ItemType:new(i)
    i.parent = self
    return i
end

function give_item(item)
    if item.item_flag ~= nil then
        local gItemManager = read("u32", ADDR_gItemManager)
        if gItemManager ~= 0 then
            -- gItemManager->mItemFlags
            set_flag(gItemManager + 0x128, item.item_flag, true)
        end
    elseif item.adventure_flag ~= nil then
        local gAdventureFlags = read("u32", ADDR_gAdventureFlags)
        if gAdventureFlags ~= 0 then
            -- gAdventureFlags->mFlags
            set_flag(gAdventureFlags, item.adventure_flag, true)
        end
    elseif item.heart_container then
        local gPlayerManager = read("u32", ADDR_gPlayerManager)
        if gPlayerManager ~= 0 then
            -- gPlayerManager->mMaxHealth
            local max_health = read("u16", gPlayerManager)
            local new_max_health = max_health + 4 -- +1 heart
            if new_max_health > 64 then -- Cap at 16 hearts
                new_max_health = 64
            end
            write("u16", gPlayerManager, new_max_health)
        end
    elseif item.sand_of_hours then
        local gItemManager = read("u32", ADDR_gItemManager)
        if gItemManager ~= 0 then
            -- gItemManager->mHourglassSandFrames
            local sand_frames = read("u32", gItemManager + 0xc)
            local new_sand_frames = sand_frames + 3600 -- +1 minute
            if new_sand_frames > 3600 * 99 then -- Cap at 99 minutes
                new_sand_frames = 3600 * 99
            end
            write("u32", gItemManager + 0xc, new_sand_frames)
        end
    elseif item.bomb_bag ~= nil then
        local gItemManager = read("u32", ADDR_gItemManager)
        if gItemManager ~= 0 then
            -- gItemManager->mBombBagSize
            write("u16", gItemManager + 0xb6, item.bomb_bag)
        end
    elseif item.bombchu_bag ~= nil then
        local gItemManager = read("u32", ADDR_gItemManager)
        if gItemManager ~= 0 then
            -- gItemManager->mBombchuBagSize
            write("u16", gItemManager + 0xb8, item.bombchu_bag)
        end
    elseif item.quiver ~= nil then
        local gItemManager = read("u32", ADDR_gItemManager)
        if gItemManager ~= 0 then
            -- gItemManager->mQuiverSize
            write("u16", gItemManager + 0xb4, item.quiver)
        end
    elseif item.power_gem then
        local gItemManager = read("u32", ADDR_gItemManager)
        if gItemManager ~= 0 then
            -- gItemManager->mNumGems[Gem_Power]
            local power_gems = read("u8", gItemManager + 0x25)
            local new_power_gems = power_gems + 1
            if new_power_gems > 99 then -- Cap at 99
                new_power_gems = 99
            end
            write("u8", gItemManager + 0x25, new_power_gems)
        end
    elseif item.wisdom_gem then
        local gItemManager = read("u32", ADDR_gItemManager)
        if gItemManager ~= 0 then
            -- gItemManager->mNumGems[Gem_Wisdom]
            local wisdom_gems = read("u8", gItemManager + 0x26)
            local new_wisdom_gems = wisdom_gems + 1
            if new_wisdom_gems > 99 then -- Cap at 99
                new_wisdom_gems = 99
            end
            write("u8", gItemManager + 0x26, new_wisdom_gems)
        end
    elseif item.courage_gem then
        local gItemManager = read("u32", ADDR_gItemManager)
        if gItemManager ~= 0 then
            -- gItemManager->mNumGems[Gem_Courage]
            local courage_gems = read("u8", gItemManager + 0x24)
            local new_courage_gems = courage_gems + 1
            if new_courage_gems > 99 then -- Cap at 99
                new_courage_gems = 99
            end
            write("u8", gItemManager + 0x24, new_courage_gems)
        end
    elseif item.small_key then
        local gMapManager = read("u32", ADDR_gMapManager)
        if gMapManager ~= 0 then
            -- gMapManager->mCourse
            local mCourse = read("u32", gMapManager)
            if mCourse ~= 0 then
                -- gMapManager->mCourse->mSmallKeys
                local mNumKeys = read("u32", mCourse + 0x260)
                mNumKeys = mNumKeys + 1
                if mNumKeys > 8 then -- Cap at 8 keys
                    mNumKeys = 8
                end
                write("u32", mCourse + 0x260, mNumKeys)
            end
        end
    end
end

function take_item(item)
    if item.item_flag ~= nil then
        local gItemManager = read("u32", ADDR_gItemManager)
        if gItemManager ~= 0 then
            -- gItemManager->mItemFlags
            set_flag(gItemManager + 0x128, item.item_flag, false)
        end
    elseif item.adventure_flag ~= nil then
        local gAdventureFlags = read("u32", ADDR_gAdventureFlags)
        if gAdventureFlags ~= 0 then
            -- gAdventureFlags->mFlags
            set_flag(gAdventureFlags, item.adventure_flag, false)
        end
    elseif item.heart_container then
        local gPlayerManager = read("u32", ADDR_gPlayerManager)
        if gPlayerManager ~= 0 then
            -- gPlayerManager->mMaxHealth
            local max_health = read("u16", gPlayerManager)
            local new_max_health = max_health - 4 -- -1 heart
            if new_max_health < 4 then -- Cap at 1 hearts
                new_max_health = 4
            end
            write("u16", gPlayerManager, new_max_health)
        end
    elseif item.sand_of_hours then
        local gItemManager = read("u32", ADDR_gItemManager)
        if gItemManager ~= 0 then
            -- gItemManager->mHourglassSandFrames
            local sand_frames = read("u32", gItemManager + 0xc)
            local new_sand_frames = sand_frames - 3600 -- -1 minute
            if new_sand_frames < 3600 then -- Cap at 1 minute
                new_sand_frames = 3600
            end
            write("u32", gItemManager + 0xc, new_sand_frames)
        end
    elseif item.bomb_bag ~= nil then
        local gItemManager = read("u32", ADDR_gItemManager)
        if gItemManager ~= 0 then
            -- gItemManager->mBombBagSize
            write("u16", gItemManager + 0xb6, item.bomb_bag - 1)
        end
    elseif item.bombchu_bag ~= nil then
        local gItemManager = read("u32", ADDR_gItemManager)
        if gItemManager ~= 0 then
            -- gItemManager->mBombchuBagSize
            write("u16", gItemManager + 0xb8, item.bombchu_bag - 1)
        end
    elseif item.quiver ~= nil then
        local gItemManager = read("u32", ADDR_gItemManager)
        if gItemManager ~= 0 then
            -- gItemManager->mQuiverSize
            write("u16", gItemManager + 0xb4, item.quiver - 1)
        end
    elseif item.power_gem then
        local gItemManager = read("u32", ADDR_gItemManager)
        if gItemManager ~= 0 then
            -- gItemManager->mNumGems[Gem_Power]
            local power_gems = read("u8", gItemManager + 0x25)
            local new_power_gems = power_gems - 1
            if new_power_gems < 0 then -- Cap at 0
                new_power_gems = 0
            end
            write("u8", gItemManager + 0x25, new_power_gems)
        end
    elseif item.wisdom_gem then
        local gItemManager = read("u32", ADDR_gItemManager)
        if gItemManager ~= 0 then
            -- gItemManager->mNumGems[Gem_Wisdom]
            local wisdom_gems = read("u8", gItemManager + 0x26)
            local new_wisdom_gems = wisdom_gems - 1
            if new_wisdom_gems < 0 then -- Cap at 0
                new_wisdom_gems = 0
            end
            write("u8", gItemManager + 0x26, new_wisdom_gems)
        end
    elseif item.courage_gem then
        local gItemManager = read("u32", ADDR_gItemManager)
        if gItemManager ~= 0 then
            -- gItemManager->mNumGems[Gem_Courage]
            local courage_gems = read("u8", gItemManager + 0x24)
            local new_courage_gems = courage_gems - 1
            if new_courage_gems < 0 then -- Cap at 0
                new_courage_gems = 0
            end
            write("u8", gItemManager + 0x24, new_courage_gems)
        end
    elseif item.small_key then
        local gMapManager = read("u32", ADDR_gMapManager)
        if gMapManager ~= 0 then
            -- gMapManager->mCourse
            local mCourse = read("u32", gMapManager)
            if mCourse ~= 0 then
                -- gMapManager->mCourse->mSmallKeys
                local mNumKeys = read("u32", mCourse + 0x260)
                mNumKeys = mNumKeys - 1
                if mNumKeys < 0 then
                    mNumKeys = 0
                end
                write("u32", mCourse + 0x260, mNumKeys)
            end
        end
    end
end

function give_rupees(rupees)
    local gItemManager = read("u32", ADDR_gItemManager)
    if gItemManager ~= 0 then
        -- gItemManager->mNumRupees
        local current_rupees = read("u16", gItemManager + 0x22)
        local new_rupees = current_rupees + rupees
        if new_rupees > 9999 then
            new_rupees = 9999
        end
        if new_rupees < 0 then
            new_rupees = 0
        end
        write("u16", gItemManager + 0x22, new_rupees)
    end
end

function give_rupees_cb(rupees)
    return function()
        give_rupees(rupees)
    end
end

function speedup_boat()
    local gPlayer = read("u32", ADDR_gPlayer)
    local overlaySlot4 = read("u32", ADDR_gOverlayManager_mLoadedOverlays_4)
    -- Overlay 15 is the sea overlay
    if gPlayer ~= 0 and overlaySlot4 == 15 then
        -- gPlayer->mBoatSpeed
        write("u16", gPlayer + 0x78, 512) -- Set boat speed to 512
    end
end

function set_initial_adventure_flags()
    local gAdventureFlags = read("u32", ADDR_gAdventureFlags)
    local gItemManager = read("u32", ADDR_gItemManager)
    if gAdventureFlags == 0 or gItemManager == 0 then
        show_error("Open a save file first!")
        return
    end

    -- gAdventureFlags->mFlags[0]
    write("u32", gAdventureFlags, 0x033e3cef)
    -- gAdventureFlags->mFlags[1]
    write("u32", gAdventureFlags + 0x4, 0xab4090e7)
    -- gAdventureFlags->mFlags[2]
    write("u32", gAdventureFlags + 0x8, 0xfc27ffff)
    -- gAdventureFlags->mFlags[3]
    write("u32", gAdventureFlags + 0xc, 0x0204003b)
    -- gAdventureFlags->mFlags[4]
    write("u32", gAdventureFlags + 0x10, 0x04124fd9)
    -- gAdventureFlags->mFlags[5]
    write("u32", gAdventureFlags + 0x14, 0xea45fe02)
    -- gAdventureFlags->mFlags[6]
    write("u32", gAdventureFlags + 0x18, 0x03080047)
    -- gAdventureFlags->mFlags[7]
    write("u32", gAdventureFlags + 0x1c, 0xe010e034)
    -- gAdventureFlags->mFlags[8]
    write("u32", gAdventureFlags + 0x20, 0x050fd94e)
    -- gAdventureFlags->mFlags[9]
    write("u32", gAdventureFlags + 0x24, 0x1fa00031)
    -- gAdventureFlags->mFlags[10]
    write("u32", gAdventureFlags + 0x28, 0x4800cc26)
    -- gAdventureFlags->mFlags[11]
    write("u32", gAdventureFlags + 0x2c, 0x4018001f)
    -- gAdventureFlags->mFlags[12]
    write("u32", gAdventureFlags + 0x30, 0x00000070)

    -- Must have boomerang to access the item menu
    give_item(ITEM_TYPES["Boomerang"])
    -- gItemManager->mAmmo
    local mAmmo = read("u32", gItemManager + 0xb0)
    -- gItemManager->mAmmo[ItemFlag_Boomerang]
    write("u16", mAmmo + 0x4, 1)
    -- gItemManager->mAmmo[ItemFlag_Shovel]
    write("u16", mAmmo + 0x6, 1)
    -- gItemManager->mAmmo[ItemFlag_BombBag]
    write("u16", mAmmo + 0x8, 10)
    -- gItemManager->mAmmo[ItemFlag_Bow]
    write("u16", mAmmo + 0xa, 20)
    -- gItemManager->mAmmo[ItemFlag_GrapplingHook]
    write("u16", mAmmo + 0xc, 1)
    -- gItemManager->mAmmo[ItemFlag_BombchuBag]
    write("u16", mAmmo + 0xe, 10)
    -- gItemManager->mAmmo[ItemFlag_Hammer]
    write("u16", mAmmo + 0x10, 1)
end

ITEM_TYPES = {
    ["Oshus's Sword"]         = ItemType:new{ item_flag = 0 },
    ["Wooden Shield"]         = ItemType:new{ item_flag = 1 },
    ["Boomerang"]             = ItemType:new{ item_flag = 2 },
    ["Shovel"]                = ItemType:new{ item_flag = 3 },
    ["Bomb Bag"]              = ItemType:new{ item_flag = 4 },
    ["Bomb Bag Upgrade 1"]    = ItemType:new{ bomb_bag = 1 },
    ["Bomb Bag Upgrade 2"]    = ItemType:new{ bomb_bag = 2 },
    ["Bow"]                   = ItemType:new{ item_flag = 5 },
    ["Bow Upgrade 1"]         = ItemType:new{ quiver = 2 },
    ["Bow Upgrade 2"]         = ItemType:new{ quiver = 3 },
    ["Grappling Hook"]        = ItemType:new{ item_flag = 6 },
    ["Bombchu Bag"]           = ItemType:new{ item_flag = 7 },
    ["Bombchu Bag Upgrade 1"] = ItemType:new{ bombchu_bag = 1 },
    ["Bombchu Bag Upgrade 2"] = ItemType:new{ bombchu_bag = 2 },
    ["Hammer"]                = ItemType:new{ item_flag = 8 },
    ["Spirit of Courage"]     = ItemType:new{ item_flag = 20 },
    ["Spirit of Power"]       = ItemType:new{ item_flag = 21 },
    ["Spirit of Wisdom"]      = ItemType:new{ item_flag = 22 },
    ["Spirit of Courage Lv1"] = ItemType:new{ item_flag = 23 },
    ["Spirit of Power Lv1"]   = ItemType:new{ item_flag = 24 },
    ["Spirit of Wisdom Lv1"]  = ItemType:new{ item_flag = 25 },
    ["Spirit of Courage Lv2"] = ItemType:new{ item_flag = 26 },
    ["Spirit of Power Lv2"]   = ItemType:new{ item_flag = 27 },
    ["Spirit of Wisdom Lv2"]  = ItemType:new{ item_flag = 28 },
    ["Phantom Hourglass"]     = ItemType:new{ item_flag = 32 },
    ["Sea Chart (Southwest)"] = ItemType:new{ item_flag = 33 },
    ["Sea Chart (Northwest)"] = ItemType:new{ item_flag = 34 },
    ["Sea Chart (Southeast)"] = ItemType:new{ item_flag = 35 },
    ["Sea Chart (Northeast)"] = ItemType:new{ item_flag = 36 },
    ["Phantom Sword"]         = ItemType:new{ item_flag = 37 },
    ["Sun Key"]               = ItemType:new{ item_flag = 38 },
    ["Fishing Rod"]           = ItemType:new{ item_flag = 40 },
    ["Cannon"]                = ItemType:new{ item_flag = 41 },
    ["King's Key"]            = ItemType:new{ item_flag = 42 },
    ["Ghost Key"]             = ItemType:new{ item_flag = 43 },
    ["Salvage Arm"]           = ItemType:new{ item_flag = 44 },
    ["Swordsman's Scroll"]    = ItemType:new{ item_flag = 45 },
    ["Cyclone Slate"]         = ItemType:new{ item_flag = 46 },
    ["Big Catch Lure"]        = ItemType:new{ item_flag = 47 },
    ["Regal Necklace"]        = ItemType:new{ adventure_flag = 51 },
    ["Courage Crest"]         = ItemType:new{ adventure_flag = 122 },
    ["Hero's New Clothes"]    = ItemType:new{ adventure_flag = 162 },
    ["Kaleidoscope"]          = ItemType:new{ adventure_flag = 163 },
    ["Guard Notebook"]        = ItemType:new{ adventure_flag = 164 },
    ["Wood Heart"]            = ItemType:new{ adventure_flag = 167 },
    ["Spawn Phantoms B12"]    = ItemType:new{ adventure_flag = 182 },
    ["Frog Glyph X"]          = ItemType:new{ adventure_flag = 311 },
    ["Frog Glyph Phi"]        = ItemType:new{ adventure_flag = 312 },
    ["Frog Glyph N"]          = ItemType:new{ adventure_flag = 313 },
    ["Frog Glyph Omega"]      = ItemType:new{ adventure_flag = 314 },
    ["Frog Glyph W"]          = ItemType:new{ adventure_flag = 315 },
    ["Frog Glyph Box"]        = ItemType:new{ adventure_flag = 316 },
    ["Heart Container"]       = ItemType:new{ heart_container = true },
    ["Sand of Hours"]         = ItemType:new{ sand_of_hours = true },
    ["Power Gem"]             = ItemType:new{ power_gem = true },
    ["Wisdom Gem"]            = ItemType:new{ wisdom_gem = true },
    ["Courage Gem"]           = ItemType:new{ courage_gem = true },
    ["Small Key"]             = ItemType:new{ small_key = true },
}

function keys(table)
    local keys = {}
    for key, _ in pairs(table) do
        keys[#keys + 1] = key
    end
    return keys
end

READ_FNS = {
    ["u8"] = memory.read_u8,
    ["s8"] = memory.read_s8,
    ["u16"] = memory.read_u16_le,
    ["s16"] = memory.read_s16_le,
    ["u32"] = memory.read_u32_le,
    ["s32"] = memory.read_s32_le,
}

WRITE_FNS = {
    ["u8"] = memory.write_u8,
    ["s8"] = memory.write_s8,
    ["u16"] = memory.write_u16_le,
    ["s16"] = memory.write_s16_le,
    ["u32"] = memory.write_u32_le,
    ["s32"] = memory.write_s32_le,
}

function set_value_cb(datatype, object_addr, offset, handle)
    return function()
        local object = read("u32", object_addr)
        if object ~= 0 then
            write("u8", object + offset, forms.gettext(handle))
        end
    end
end

function domain(addr)
    if addr >= 0x2000000 and addr < 0x2400000 then
        return "Main RAM", addr - 0x2000000
    elseif addr >= 0x27e0000 and addr < 0x27e4000 then
        return "Data TCM", addr - 0x27e0000
    end
    return nil
end

function read(datatype, addr)
    local domain, offset = domain(addr)
    -- print(string.format("Reading %s from offset %08x in %s", datatype, offset, domain))
    return READ_FNS[datatype](offset, domain)
end

function write(datatype, addr, value)
    local domain, offset = domain(addr)
    value = tonumber(value)
    -- print(string.format("Writing %x to %s at offset %08x in %s", value, datatype, offset, domain))
    WRITE_FNS[datatype](offset, value, domain)
end

function set_flag(array_addr, index, value)
    local flag_addr = array_addr + math.floor(index / 32) * 4
    local bit_index = index % 32
    local current_flags = read("u32", flag_addr)
    local flag = 1 << bit_index
    if value then
        current_flags = current_flags | flag
    else
        current_flags = current_flags & ~flag
    end
    write("u32", flag_addr, current_flags)
end

function show_error(message)
    forms.newform(200, 100, "Error")
    local error_label = forms.label(form, message, 10, 10, 180, 80)
    forms.button(form, "OK", function() forms.destroy(form) end, 10, 60, 180, 30)
end

main()
