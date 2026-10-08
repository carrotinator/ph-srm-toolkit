form = nil

WIDTH = 450
HEIGHT = 900
LINESIZE = 13
TEXTBOXSIZE = 22

WIDTH_TOOLKIT = 300
HEIGHT_TOOLKIT = 100

TEXTSIZE = 12
Y_MARGIN = 2
ELEMENT_HEIGHT = TEXTSIZE + Y_MARGIN

COLUMN_WIDTHS = {40, 70, 70, 50, 150}
COLUMN_OFFSETS = {2}
for i, w in ipairs(COLUMN_WIDTHS) do
    table.insert(COLUMN_OFFSETS, w+COLUMN_OFFSETS[i])
end

-- Actor identification lookup
local IDENT_TABLE = {
    [0x20E6560] = "Ciela",

    -- Stuff
    [0x2155DF8] = "Grapple",
    [0x21559E8] = "Arrow",
    [0x2155BF0] = "Bomb",
    [0x2155CFC] = "Boomerang",
    [0x2155EF4] = "Bombchu",
    [0x2155AC8] = "Explosion",
    [0x2158448] = "Blue Pot",
    [0x2158510] = "Red Pot",
    [0x21582B8] = "Barrel",
    [0x2158380] = "Rock",
    [0x2157DD8] = "Push Block",
    [0x2157A78] = "Arrow Drop",
    [0x21579B8] = "Time Drop",
    [0x2157BF8] = "Bomb Drop",
    [0x21589E4] = "Rupee",
    [0x2158750] = "Heart",
    [0x215880C] = "Map",
    [0x216C8F8] = "Platform",
    [0x216BCC4] = "Boss Key",
    [0x216BEE4] = "Sq Crystal",
    [0x216BDCC] = "Force Gem",
    [0x216C00C] = "Small Key",

    -- Enemies
    [0x21855AC] = "ChuChu",
    [0x2198B80] = "Crow",
    [0x2180330] = "Cucco",
    [0x21804A0] = "Angry Cucco",
    [0x218FAE0] = "Keese",
    [0x2195184] = "Moldorm",
    [0x2194FB8] = "Moldorm",
    [0x2198720] = "Winder",
    [0x2194DD8] = "Beamos",
    [0x21860D0] = "Rock Chu h",
    [0x21857C0] = "Rock Chu b",
    [0x2198568] = "Like-Like",
    [0x218D9AC] = "Eye Slug",
    [0x2189054] = "Phantom",
    [0x2188F44] = "Red Phantom",
    [0x2188D24] = "Warp Phantom",
    [0x2198978] = "Spike Log",
    [0x218F778] = "Octorock",
    [0x218F964] = "Octo-projectile",
    [0x219885C] = "Spike Trap",
    [0x217AB0C] = "Bone Projectile",
    [0x217A414] = "Stalfos_Body",
    [0x217A990] = "Stalfos_Head",

    -- Static Actors
    [0x2158134] = "Dig Spot",
    [0x216C2C4] = "Boat",

    -- Technical
    [0x20E8460] = "Splash",
    [0x20E8FC0] = "Dialogue",
    [0x20E29EC] = "Kill Detector",
    [0x20E8CB4] = "Spawner",
    [0x20E2930] = "Trigger",
    [0x20E2AA8] = "Camera Thing?",
    [0x215A478] = "Cutscene Trigger",

    -- NPCs
    [0x21947C8] = "Linebeck",
    [0x218E4D4] = "Freedle",
    [0x218E768] = "Lapelli",
    [0x217A668] = "Gongoron",
    [0x218E47C] = "Fallen Adventurer",
    [0x218E754] = "Trade Barrel"
}

------ Static addresses ------
ADDR_gItemManager = 0x027e0fb4
ADDR_gPlayerManager = 0x027e0fbc
ADDR_gAdventureFlags = 0x027e0f74
ADDR_gPlayer = 0x027e0fec
ADDR_gPlayerStuffs = 0x027e0f90
ADDR_gOverlayManager_mLoadedOverlays_4 = 0x027e0910
ADDR_gMapManager = 0x027e0e60
ADDR_gActorManager = 0x027e0FE4


BLACK = {0, 0, 0}
WHITE = {1, 1, 1}

BUTTON_MARGIN = 5
BUTTON_HEIGHT = 20
BUTTON_WIDTH = 60
BUTTON_V_OFFSET = BUTTON_HEIGHT + BUTTON_MARGIN

function main()
    
    -- initialize table window
    form = forms.newform(WIDTH, HEIGHT, "Actor Viewer")
    canvas = forms.pictureBox(form, 0, 0, WIDTH, HEIGHT)
    current_table = {}
    selected_row = -1
    -- table events
    forms.addclick(canvas, clickevent_select_row)

    -- initialize control window
    control_form = forms.newform(WIDTH_TOOLKIT, HEIGHT_TOOLKIT, "SRM Toolkit")
    canvas_toolkit = forms.pictureBox(control_form, BUTTON_WIDTH + 2*BUTTON_MARGIN, 0, WIDTH_TOOLKIT-BUTTON_WIDTH-BUTTON_MARGIN , HEIGHT_TOOLKIT)
    -- control events
    forms.button(control_form, "Delete", button_event_delete, BUTTON_MARGIN, BUTTON_MARGIN, BUTTON_WIDTH, BUTTON_HEIGHT)
    forms.button(control_form, "Hold", button_event_hold, BUTTON_MARGIN, BUTTON_MARGIN+BUTTON_V_OFFSET, BUTTON_WIDTH, BUTTON_HEIGHT)
    forms.button(control_form, "Overflow", button_event_overflow, BUTTON_MARGIN, BUTTON_MARGIN+BUTTON_V_OFFSET*2, BUTTON_WIDTH, BUTTON_HEIGHT)

    -- label(formhandle, caption, x, y, width, height, fixedwidth)
    -- textbox(formhandle, caption, width, height, boxtype, x, y, multiline, fixedwidth, scrollbars)
    -- button(formhandle, caption, clickevent, x, y, width, height)
    -- dropdown(formhandle, items, x, y, width, height)
    -- checkbox(formhandle, caption, x, y)
    -- ischecked(handle)

    
    local test_table = {
        {name="Ciela", address=0x137b25, coords={25, 34, 24}},
        {name="Next Object", address=0x2453, coords={88, -3, 0}}
    }
    

    ------ Game loop ------
    while true do
        forms.clear(canvas, "white")
        forms.clear(canvas_toolkit, "white")
        
        get_addresses()
        draw_header()
        highlight_held_slot()
        highlight_selected_row()
        highlight_mouse()

        current_table = get_data(current_table)
        draw_table(current_table)
        draw_toolkit_data()

        forms.refresh(canvas)
        forms.refresh(canvas_toolkit)
        emu.frameadvance()
    end
end

-- Helper Functions --
READ_FNS = { -- AetiasHax
    ["u8"] = memory.read_u8,
    ["s8"] = memory.read_s8,
    ["u16"] = memory.read_u16_le,
    ["s16"] = memory.read_s16_le,
    ["u32"] = memory.read_u32_le,
    ["s32"] = memory.read_s32_le,
}

WRITE_FNS = { -- AetiasHax
    ["u8"] = memory.write_u8,
    ["s8"] = memory.write_s8,
    ["u16"] = memory.write_u16_le,
    ["s16"] = memory.write_s16_le,
    ["u32"] = memory.write_u32_le,
    ["s32"] = memory.write_s32_le,
}

function domain(addr) -- AetiasHax
    if addr >= 0x2000000 and addr < 0x2400000 then
        return "Main RAM", addr - 0x2000000
    elseif addr >= 0x27e0000 and addr < 0x27e4000 then
        return "Data TCM", addr - 0x27e0000
    end
    return nil
end

function read(datatype, addr) -- AetiasHax
    local domain, offset = domain(addr)
    -- print(string.format("Reading %s from offset %08x in %s", datatype, offset, domain))
    return READ_FNS[datatype](offset, domain)
end

function write(datatype, addr, value) -- AetiasHax
    local domain, offset = domain(addr)
    value = tonumber(value)
    -- print(string.format("Writing %x to %s at offset %08x in %s", value, datatype, offset, domain))
    WRITE_FNS[datatype](offset, value, domain)
end

function round(num, decimalPlaces)
    local mult = 10^(decimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function to_hex(s)
    return "0x" .. string.format("%x", s)
end

function format_coords(c)
    local coords = "("
    for i, value in ipairs(c) do
        coords = coords .. tostring(value)
        if i < 3 then
            coords = coords .. ", "
        end
    end
    coords = coords .. ")"
    return coords
end

-- Process functions

function get_addresses()
    actor_manager = read("u32", ADDR_gActorManager)
    actor_table = read("u32", actor_manager +16)
    actor_table_size = read("u8", actor_manager)
    last_actor = read("u8", actor_manager+4)
    next_actor_index = read("u32", actor_manager + 12)

    player_data = read("u32", ADDR_gPlayerStuffs)
    held_item_offset = read("u8", player_data+16*4)
    held_item_index = read("u32", player_data+15*4)

    mouse_x = forms.getMouseX(canvas)
    mouse_y = forms.getMouseY(canvas)

end

function read_coords(actor_data)
    local actor_coords = {}
    for i=1, 3 do
        local new_coord = read("s32", actor_data+(17+i)*4)
        table.insert(actor_coords, round(new_coord / 100, 1))
    end
    return actor_coords
end

function get_data(last_table)
    local res = {}
    local count_actors = 1
    local index = 1
    for actor_pointer=actor_table, actor_table+actor_table_size*4, 4 do
        local actor_data = read("u32", actor_pointer)
        -- print("Actor data: "..to_hex(actor_pointer).. " -> " .. to_hex(actor_data))
        if actor_data == 0 then
            table.insert(res, {name="-"})
            if index > last_actor+2 then
                return res
            end
        else
            -- use cached data if the pointer didn't change. coords want to be updated though
            if last_table[index] and actor_pointer == last_table[index].pointer then
                table.insert(res, last_table[index])
                res[index].coords = read_coords(actor_data)
            else
                -- identify actor from lookup table
                local name = "unk"
                local actor_ident = read("u32", actor_data)
                if IDENT_TABLE[actor_ident] then
                    name = IDENT_TABLE[actor_ident]
                end
                table.insert(res, {
                    name=name, 
                    address=actor_data, 
                    coords = read_coords(actor_data), 
                    counter = read("u32", actor_data+8),
                    pointer = actor_pointer
                })
            end
            count_actors = count_actors + 1
        end
        index = index + 1
    end
    return res
end

-- Drawing functions

function draw_simple(text, x, y, mod)
    forms.drawText(canvas, x, y*ELEMENT_HEIGHT, text, "black", "white", TEXTSIZE, "Consolas", mod, "left", "top")
end

function draw_simple_toolkit(text, x, y, bg_color)
    if bg_color == nil then bg_color = "white" end
    forms.drawText(canvas_toolkit, x, y*ELEMENT_HEIGHT, text, "black", bg_color, TEXTSIZE, "Consolas", mod, "left", "top")
end

function draw_header()
    local header = {"Offset", "Name", "Address", "Index", "Coords (kilo-units)"}
    for i, x in ipairs(COLUMN_OFFSETS) do
        draw_simple(header[i], x, 0, "bold")
    end
end

function draw_table(data)
    for y, row in ipairs(data) do
        -- print(to_hex(y))
        draw_simple(to_hex(y-1), COLUMN_OFFSETS[1], y)
        draw_simple(row.name, COLUMN_OFFSETS[2], y)
        if row.name ~= "-" then
            draw_simple(to_hex(row.address), COLUMN_OFFSETS[3], y)
            draw_simple(to_hex(row.counter), COLUMN_OFFSETS[4], y)
            draw_simple(format_coords(row.coords), COLUMN_OFFSETS[5], y)
        end
    end
end

function draw_toolkit_data()
    local srm_color = "white"
    draw_simple_toolkit("Next Actor Index: "..to_hex(next_actor_index), 5, 0)
    if held_item_index ~= 0xffffffff and current_table[held_item_offset+1] and current_table[held_item_offset+1].counter and current_table[held_item_offset+1].counter == held_item_index then
        draw_simple_toolkit("Holding: "..current_table[held_item_offset+1].name, 5, 3, "lightgreen")
    elseif held_item_index ~= 0xffffffff then
        srm_color = "lightgreen"
        draw_simple_toolkit("Got Stale Reference!", 5, 3, "lightgreen")
    end
    draw_simple_toolkit("Held Item Offset: "..to_hex(held_item_offset), 5, 1, srm_color)
    draw_simple_toolkit("Held Item Index: "..to_hex(held_item_index), 5, 2, srm_color)

    if selected_row > 0 and current_table[selected_row] then
        draw_simple_toolkit("Selected: "..current_table[selected_row].name, 5, 4, "lightblue")
    end
end

-- Code for highlighting rows
function highlight_mouse()
    if 0 <= mouse_x and mouse_x <= WIDTH and 0 <= mouse_y and mouse_y <= HEIGHT then
        forms.drawRectangle(canvas, 0, math.floor(mouse_y / ELEMENT_HEIGHT)*ELEMENT_HEIGHT, WIDTH, ELEMENT_HEIGHT, "lightskyblue", "lightskyblue")
    end
end

function highlight_held_slot()
    if 0xff > held_item_offset and held_item_offset > 0 and held_item_offset*ELEMENT_HEIGHT < HEIGHT then
        forms.drawRectangle(canvas, 0, (held_item_offset+1)*ELEMENT_HEIGHT, WIDTH, ELEMENT_HEIGHT, "lightgreen", "lightgreen")
    end
end

function highlight_selected_row()
    if selected_row > 0 then
        forms.drawRectangle(canvas, 0, (selected_row)*ELEMENT_HEIGHT, WIDTH, ELEMENT_HEIGHT, "blue", "blue")
    end
end



-- Event functions

function clickevent_select_row()
    if 0 <= mouse_x and mouse_x <= WIDTH and 0 <= mouse_y and mouse_y <= HEIGHT then
        selected_row = math.floor(mouse_y / ELEMENT_HEIGHT)
    end
end

function button_event_delete()
    local selected_data = current_table[selected_row]
    if selected_data and selected_data.address then
        write("u32", selected_data.pointer, 0)
    end
    selected_row = 0
end

function button_event_hold()
    local selected_data = current_table[selected_row]
    if selected_data and selected_data.address then
        local player_data = read("u32", ADDR_gPlayerStuffs)
        write("u32", player_data+16*4, selected_row-1)
        write("u32", player_data+15*4, selected_data.counter)

    end
    selected_row = 0
end

function button_event_overflow()
    --print(to_hex(next_actor_index))
    write("u32", actor_manager + 12, 0xffffffff)
end

main()