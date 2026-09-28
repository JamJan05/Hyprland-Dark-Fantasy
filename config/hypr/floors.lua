-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- FLOORS - desktops grouped into floors.                 --
-- Included from hyprland.lua via require("floors").      --
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
--
-- A desktop's address is the pair (floor, desktop), not a global number.
-- Each floor has its own desktops 1..9 and 0, and the 0 key means
-- "tenth" - both for a desktop and for a floor (F0).
--
--     SUPER + 1..0             desktop on the CURRENT floor
--     SUPER + SHIFT + 1..0     move window to a desktop on the current floor
--     SUPER + CTRL + 1..0      floor - returns to its last desktop
--     SUPER + CTRL + up/down   floor up / down
--     3 fingers left / right   next / previous desktop of the floor
--     3 fingers up / down      floor up / down
--
-- The shortcuts and gestures themselves are in hyprland.lua, with everything
-- else. The logic is here.
--
-- ---------------------------------------------------------------
-- MAPPING ONTO HYPRLAND WORKSPACES
--
--     id = (floor - 1) * 10 + desktop          (desktop 0 = 10)
--
--     F1 -> 1..10     F2 -> 11..20     ...     F0 -> 91..100
--
-- Plain numbered workspaces, not named ones. Hyprland gives a named one
-- a NEGATIVE id in creation order, so the same desktop would get
-- a different number in every session. Numbered ones are stable, appear on
-- their own on first entry and vanish once empty - nothing has to be
-- set up in advance.
--
-- F1 is desktops 1..10, so without changing floors everything behaves like
-- plain numbered workspaces.
--
-- ---------------------------------------------------------------
-- WHICH FLOOR AM I ON
--
-- Computed every time from the id of the active workspace. The current floor
-- is DELIBERATELY not a variable: a variable can drift apart from what is
-- on screen - a touchpad gesture, a click in the HUD or "hyprctl dispatch"
-- from a terminal is enough. The active workspace id always tells the truth,
-- so the HUD will not show floor II while you are on I.
--
-- Only the last desktop of each floor is remembered - and it cannot
-- live in Lua alone. On a config reload Hyprland starts the interpreter
-- from scratch, and autoreload catches every save of hyprland.lua.
-- That is why it lives in a file in the Hyprland instance directory,
-- $XDG_RUNTIME_DIR/hypr/<instance signature>/. The directory is separate
-- for each session, so a new session starts from zero: F1 / desktop 1.
--
-- ---------------------------------------------------------------
-- QUICKSHELL SHELL HUD
--
-- The floor and desktops are shown in the left corner of the shell (hud/Godlo.qml
-- and hud/PulpityPietra.qml). The HUD reads ONE file, floors-stan.json,
-- written after every change in refresh() - so nothing is computed a second
-- time and the corner cannot show a different floor than the one you are on.
--
-- The shell needs no signal: FileView with watchChanges also watches the
-- directory, so it catches the file being replaced via rename (src/io/fileview.cpp,
-- onWatchedDirectoryChanged in Quickshell 0.3.1).
--
-- Waybar's built-in hyprland/workspaces is no good for this: it shows the
-- workspaces of all floors at once, and its click sends a dispatcher in the
-- old syntax, which Hyprland with a Lua config does not accept.

local M = {}

-- The grid is ALWAYS 10 x 10, regardless of the settings. The number of floors
-- from Cogwheel (below: liczbaPieter) only limits which floors can be
-- entered - workspace numbers do not shift, so changing the setting
-- does not move windows between floors.
local FLOORS   = 10
local DESKTOPS = 10

-- ---------------------------------------------------------------
--  SETTINGS FROM COGWHEEL
--
--  Number of floors, their names and the gesture switch. Set by M.ustaw() -
--  called from ~/.config/hypr/ustawienia.lua, which the shell's Cogwheel
--  generates (services/UstawieniaHyprlanda.qml), and on a live change via
--  "hyprctl eval". Default: ten unnamed floors, gestures enabled.
-- ---------------------------------------------------------------
local liczbaPieter  = FLOORS
local nazwy         = {}
local gestyWlaczone = true

local function ws_id(floor, desktop)
    return (floor - 1) * DESKTOPS + desktop
end

-- Inverse of ws_id. For workspaces outside the floor grid (the scratchpad
-- has a negative id) it returns nil.
local function split(id)
    if type(id) ~= "number" or id < 1 or id > FLOORS * DESKTOPS then
        return nil
    end
    return (id - 1) // DESKTOPS + 1, (id - 1) % DESKTOPS + 1
end


-- ---------------------------------------------------------------
--  FILES
-- ---------------------------------------------------------------

-- Hyprland creates the instance directory BEFORE reading the config,
-- so it is already available at login.
local function state_path(name)
    local runtime = os.getenv("XDG_RUNTIME_DIR")
    local sig     = os.getenv("HYPRLAND_INSTANCE_SIGNATURE")
    if not runtime or not sig then return nil end
    return runtime .. "/hypr/" .. sig .. "/" .. name
end

-- Write via a temporary file and rename. The shell may read the file
-- at any moment, and rename replaces it as a whole - the HUD will never
-- see half a JSON.
local function write_file(name, content)
    local path = state_path(name)
    if not path then return false end

    local f = io.open(path .. ".tmp", "w")
    if not f then return false end
    f:write(content)
    f:close()

    return os.rename(path .. ".tmp", path) == true
end

-- Last desktop of each floor. No entry = desktop 1.
local last = {}

local function load_last()
    local path = state_path("floors-last")
    local f = path and io.open(path, "r")
    if not f then return end

    local floor = 1
    for n in f:read("a"):gmatch("%d+") do
        n = tonumber(n)
        if floor <= FLOORS and n >= 1 and n <= DESKTOPS then
            last[floor] = n
        end
        floor = floor + 1
    end
    f:close()
end

local function save_last()
    local t = {}
    for floor = 1, FLOORS do
        t[floor] = tostring(last[floor] or 1)
    end
    write_file("floors-last", table.concat(t, " ") .. "\n")
end


-- ---------------------------------------------------------------
--  CURRENT FLOOR
-- ---------------------------------------------------------------

-- Floor of the last active workspace from the grid. Fallback only:
-- when the active workspace is outside the floors (e.g. a manually entered
-- number 150), the digits still refer to the floor you came from.
local fallback_floor = 1

-- Returns the floor and desktop. The desktop may be nil - see above.
local function current()
    local ws = hl.get_active_workspace()
    local floor, desktop = split(ws and ws.id)
    if floor then
        fallback_floor = floor
        return floor, desktop
    end
    return fallback_floor, nil
end


-- ---------------------------------------------------------------
--  STATE FOR THE HUD
-- ---------------------------------------------------------------

local function json_string(s)
    s = s:gsub('[\\"]', "\\%0")
    s = s:gsub("\n", "\\n")
    return '"' .. s .. '"'
end

-- What was last sent to each file. No change - no write. After a config
-- reload the table is empty, so the first refresh writes everything
-- anew.
local written = {}

-- Whether the HUD is currently showing an urgent desktop - see window.active.
local urgent_shown = false

local function put(name, content)
    if written[name] == content then return false end
    if not write_file(name, content) then return false end
    written[name] = content
    return true
end

local function refresh()
    local floor, desktop = current()

    -- The current desktop is by definition the last desktop of its floor.
    -- Saved here as well, not only in workspace.active: when the active
    -- desktop changes because a monitor is disconnected, Hyprland does not
    -- report that event and the memory drifted apart from the screen -
    -- caught on the test stand.
    if desktop and last[floor] ~= desktop then
        last[floor] = desktop
        save_last()
    end

    local existing = {}
    for _, ws in ipairs(hl.get_workspaces()) do
        local f, d = split(ws.id)
        if f == floor then existing[d] = ws end
    end

    urgent_shown = false

    -- The floor's desktops for the HUD, in the order 1..9, 0: existing ones and
    -- the current one. The current one in case the event about its creation
    -- arrives after the activation event.
    local pulpity = {}

    for d = 1, DESKTOPS do
        if existing[d] or d == desktop then
            local pilny = d ~= desktop and existing[d].has_urgent == true
            if pilny then urgent_shown = true end
            pulpity[#pulpity + 1] = string.format('{"n":%d,"aktywny":%s,"pilny":%s}',
                d, tostring(d == desktop), tostring(pilny))
        end
    end

    -- "pulpit" 0 means: the active workspace is outside the floor grid
    -- (e.g. a manually entered number 150) - the HUD then marks none.
    put("floors-stan.json", string.format('{"pietro":%d,"pulpit":%d,"pietra":%d,"nazwa":%s,"pulpity":[%s]}\n',
        floor, desktop or 0, liczbaPieter, json_string(nazwy[floor] or ""), table.concat(pulpity, ",")))
end

-- One desktop change is several events at once: a new workspace is created,
-- becomes active, the old empty one vanishes. Instead of three HUD
-- refreshes - one, a moment after the last event.
--
-- The timer does not need to be stored anywhere: Hyprland holds it itself
-- until it runs.
local pending = false

local function schedule()
    if pending then return end
    pending = true
    hl.timer(function()
        pending = false
        refresh()
    end, { timeout = 15, type = "oneshot" })
end


-- ---------------------------------------------------------------
--  ACTIONS
--
--  Each one RETURNS a dispatcher instead of executing it. That way the same
--  function is used by the shortcuts (hl.dispatch in hyprland.lua) and the HUD
--  (services/Pietra.qml):
--
--      hyprctl dispatch 'floors.desktop(3)'
--
--  because with a Lua config "hyprctl dispatch X" is shorthand for hl.dispatch(X).
-- ---------------------------------------------------------------

function M.desktop(desktop)
    local floor = current()
    return hl.dsp.focus({ workspace = ws_id(floor, desktop) })
end

-- The window goes along with the focus.
function M.move(desktop)
    local floor = current()
    return hl.dsp.window.move({ workspace = ws_id(floor, desktop) })
end

-- A floor beyond the configured number of floors (e.g. SUPER+CTRL+7 with five
-- floors) does nothing - instead of opening a floor that "does not exist".
function M.floor(floor)
    if floor < 1 or floor > liczbaPieter then return hl.dsp.no_op() end
    return hl.dsp.focus({ workspace = ws_id(floor, last[floor] or 1) })
end

-- One floor up (+1) or down (-1). Stops at the first and last floor
-- instead of wrapping around.
function M.floor_step(delta)
    return M.floor(current() + delta)
end

-- Existing desktops of the current floor (sorted) and the current one's
-- position in that list - nil when the active workspace is outside the floors.
local function floor_desktops()
    local floor, desktop = current()

    local list = {}
    for _, ws in ipairs(hl.get_workspaces()) do
        local f, d = split(ws.id)
        if f == floor then list[#list + 1] = d end
    end
    table.sort(list)

    local index
    for i, d in ipairs(list) do
        if d == desktop then index = i end
    end

    return floor, desktop, list, index
end

-- Next (+1) or previous (-1) EXISTING desktop of the current floor,
-- wrapping around. Unlike "e+1" / "e-1", it never crosses into another floor.
function M.desktop_step(delta)
    local floor, desktop, list, index = floor_desktops()
    if not index then return hl.dsp.no_op() end

    local target = list[(index - 1 + delta) % #list + 1]
    if target == desktop then return hl.dsp.no_op() end
    return hl.dsp.focus({ workspace = ws_id(floor, target) })
end


-- ---------------------------------------------------------------
--  GESTURES: THREE FINGERS
--
--      left / right  -> next / previous desktop of the floor
--      up / down     -> floor up / down
--
--  Both in Lua - including the horizontal one, instead of the native
--  action = "workspace". The native swipe takes the nearest EXISTING
--  workspace on the monitor, so from the last desktop of F1 it went straight
--  to a desktop of F2, and it cannot be stopped at the edge of a floor.
--  Splitting it into separate "left" and "right" gestures does not help
--  either: the desktop gesture is direction-sensitive (isDirectionSensitive),
--  so both halves would go the same way. Verified in the 0.56.2 sources.
--
--  The price, chosen deliberately in exchange for stopping at the floor edge:
--  the desktop does not follow the fingers. It changes when the fingers are
--  lifted, with the "workspaces" animation from hyprland.lua - just like with
--  SUPER+digit.
--
--  The direction follows gestures:workspace_swipe_invert, as in the native
--  swipe: with the default true, fingers to the left give the NEXT desktop, so
--  fingers up give the next floor.
--
--  A change only after a decisive gesture. The thresholds are the same ones
--  Hyprland uses to decide the native swipe (UnifiedWorkspaceSwipeGesture.cpp):
--  a movement of at least workspace_swipe_distance
--  * workspace_swipe_cancel_ratio (default 300 * 0.5 = 150 px) or
--  a fast flick - on average at least
--  workspace_swipe_min_speed_to_force per gesture step. An accidental
--  twitch of three fingers does nothing.
-- ---------------------------------------------------------------

local function config_value(name, default)
    local ok, v = pcall(hl.get_config, name)
    if ok and type(v) == type(default) then return v end
    return default
end

-- A gesture along one axis ("x" or "y"). commit gets +1 (forward)
-- or -1 (back) and returns a dispatcher.
local function axis_swipe(axis, commit)
    local delta, speed, points = 0, 0, 0

    return {
        -- Reset only. Hyprland passes the step that started the gesture
        -- both here and right afterwards to update - counted here, it would
        -- be counted twice.
        start = function()
            delta, speed, points = 0, 0, 0
        end,

        update = function(e)
            local d = e.delta and e.delta[axis]
            if not d then return end
            delta  = delta + d
            speed  = (speed * points + math.abs(d)) / (points + 1)
            points = points + 1
        end,

        finish = function(e)
            -- Disabled in Cogwheel - the gesture does nothing. The gesture itself
            -- stays registered, because hl.gesture has no handle to disable it.
            if not gestyWlaczone then return end
            if e.cancelled or math.abs(delta) < 2 then return end

            local distance = config_value("gestures:workspace_swipe_distance", 300)
            local ratio    = config_value("gestures:workspace_swipe_cancel_ratio", 0.5)
            local force    = config_value("gestures:workspace_swipe_min_speed_to_force", 30)

            local far  = math.abs(delta) >= distance * ratio
            local fast = force > 0 and speed >= force
            if not (far or fast) then return end

            -- Negative means fingers to the left or up.
            local forward = delta < 0
            if not config_value("gestures:workspace_swipe_invert", true) then
                forward = not forward
            end

            hl.dispatch(commit(forward and 1 or -1))
        end,
    }
end

-- A sideways gesture step. It does not wrap and NEVER leaves the floor - that
-- is the whole reason this gesture is not native.
--
-- Past the last desktop of the floor ONE new desktop is created, as in the native
-- swipe with gestures:workspace_swipe_create_new: the next number on the
-- same floor. With two exceptions, both as in the native one:
--   - the current desktop is empty - the gesture stops, so as not to pile up
--     a series of empty desktops,
--   - the current one is desktop 0 - beyond it the next floor already begins.
-- Before the first desktop of the floor the gesture stops.
function M.desktop_swipe_step(delta)
    local floor, desktop, list, index = floor_desktops()
    if not index then return hl.dsp.no_op() end

    local next_index = index + delta
    if next_index >= 1 and next_index <= #list then
        return hl.dsp.focus({ workspace = ws_id(floor, list[next_index]) })
    end

    if delta > 0 and desktop < DESKTOPS
        and config_value("gestures:workspace_swipe_create_new", true) then
        local ws = hl.get_active_workspace()
        if ws and (ws.windows or 0) > 0 then
            return hl.dsp.focus({ workspace = ws_id(floor, desktop + 1) })
        end
    end

    return hl.dsp.no_op()
end

M.desktop_swipe = axis_swipe("x", M.desktop_swipe_step)
M.floor_swipe   = axis_swipe("y", M.floor_step)


-- ---------------------------------------------------------------
--  START
-- ---------------------------------------------------------------

function M.setup()
    load_last()

    -- Memory of the last desktop. Updated here, not in the actions - so it
    -- catches every way the desktop can change: shortcut, HUD, gesture.
    hl.on("workspace.active", function(ws)
        local floor, desktop = split(ws and ws.id)
        if floor and last[floor] ~= desktop then
            last[floor] = desktop
            save_last()
        end
        schedule()
    end)

    hl.on("workspace.created", schedule)
    hl.on("workspace.removed", schedule)
    hl.on("workspace.move_to_monitor", schedule)
    hl.on("window.urgent", schedule)

    -- With two monitors, the "active desktop" is the desktop of the focused monitor.
    -- Moving the cursor to the other screen changes it without a
    -- workspace.active event - without this line the HUD would stay on the old one.
    hl.on("monitor.focused", schedule)

    -- The "pilny" (urgent) marker goes out when the window gets focus. Focus
    -- changes on every mouse pass between windows, so we handle this event
    -- only when something is actually lit up in the HUD.
    hl.on("window.active", function()
        if urgent_shown then schedule() end
    end)

    -- At login the config is read before the monitors exist, so the refresh
    -- below still sees an empty session. Here desktop 1 already exists.
    hl.on("hyprland.start", refresh)

    -- Config reload during the session: the current state right away.
    refresh()
end

-- Settings from Cogwheel - see "SETTINGS FROM COGWHEEL" at the top of the file.
--
--     floors.ustaw({ pietra = 5, nazwy = { "Praca", "Dom" }, gesty = true })
--
-- Missing fields fall back to the defaults. After a change the HUD gets the new
-- state right away - "written" is cleared, so refresh writes the state file
-- even when the floor has not changed.
--
-- refresh() directly, and NOT schedule(). This function is called from the
-- settings file while the configuration is being read, and hl.timer at that
-- point (verified with "Hyprland --verify-config") ends in a segmentation
-- fault - the compositor has no event loop yet. For the same reason setup()
-- also calls refresh() directly.
function M.ustaw(opcje)
    opcje = opcje or {}
    liczbaPieter  = math.max(1, math.min(FLOORS, math.floor(tonumber(opcje.pietra) or FLOORS)))
    nazwy         = type(opcje.nazwy) == "table" and opcje.nazwy or {}
    gestyWlaczone = opcje.gesty ~= false
    written = {}
    refresh()
end

-- Global, for the HUD: hyprctl dispatch 'floors.desktop(3)'.
_G.floors = M

return M
