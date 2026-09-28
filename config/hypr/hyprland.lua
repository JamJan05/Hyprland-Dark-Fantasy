-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- HYPRLAND DARK FANTASY - main Hyprland config (Lua).    --
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
--
-- Monitors, autostart, look, input, keybindings and rules. Floors live in
-- floors.lua (require("floors")); the Cogwheel's overrides are loaded from
-- ~/.config/hypr/ustawienia.lua at the very end of this file.
-- Option reference: https://wiki.hypr.land/Configuring/Start/


-- Interface language (Cogwheel -> Language): "en" (default) or "pl". The
-- Quickshell shell keeps it in $XDG_STATE_HOME/dark-fantasy/powloka.json
-- and runs "hyprctl reload" after a change, so reading it once per config
-- load is enough. Missing or unreadable file = English. T(en, pl) is global,
-- so floors.lua and the generated ustawienia.lua can use it as well.
local function readLanguage()
    local state = os.getenv("XDG_STATE_HOME")
    if not state or state == "" then
        state = (os.getenv("HOME") or "") .. "/.local/state"
    end
    local f = io.open(state .. "/dark-fantasy/powloka.json", "r")
    if not f then return "en" end
    local text = f:read("a") or ""
    f:close()
    return text:match('"jezyk"%s*:%s*"pl"') and "pl" or "en"
end

local language = readLanguage()

function _G.T(en, pl)
    if language == "pl" and pl ~= nil then return pl end
    return en
end


------------------
---- MONITORS ----
------------------

-- Defines the monitors: resolution/refresh rate, position relative to each
-- other and interface scaling.
-- Change this when you connect a second screen, want to force a specific
-- resolution or arrange the monitors in a different order.
-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
    output   = "",          -- empty string = catch-all rule, applies to every monitor
    mode     = "preferred", -- the monitor's preferred mode (its native resolution and refresh rate)
    position = "auto",      -- Hyprland places the screens next to each other by itself
    -- WARNING: the resolution divided by the scale must be an integer,
    -- otherwise Hyprland silently replaces the scale with the nearest "clean" one
    -- (e.g. 0.9 on a 1920x1200 screen turns into 0.8333).
    -- Valid scales for 1920x1200: 0.6, 0.64, 0.75, 0.8, 0.96, 1, 1.2, 1.25, 1.5
    scale    = "1",       -- no scaling, logical desktop = native resolution
})


---------------------
---- MY PROGRAMS ----
---------------------

-- Helper variables with program names. These are not Hyprland options,
-- just shorthands used below in keybindings and in autostart.
-- Change them if you use a different terminal, file manager or launcher:
-- replacing the value in one place is enough.
local terminal    = "kitty"
-- File manager: yazi, launched in a terminal through the wrapper
-- ~/.local/bin/menedzer-plikow. Yazi is a terminal program, so
-- plain "yazi" would not open a window. Shortcut: SUPER+W (see below).
local fileManager = "menedzer-plikow"

-- App menu and dock: the Quickshell tile row, see config/quickshell/dark-fantasy/kafle/RzadKafli.qml.

-------------------
---- AUTOSTART ----
-------------------

-- Programs launched together with Hyprland (bars, notification daemons,
-- wallpapers, applets etc.).
-- Add here everything that should start automatically after login.
-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Commands MUST be wrapped in the "hyprland.start" event.
-- hl.exec_cmd called outside that block fires while the config is still
-- being read - i.e. BEFORE Hyprland creates the backend and the Wayland socket.
-- A graphical client (waybar, kitty) then has nothing to connect to
-- and dies immediately. That is why the bar did not come up after logging in from SDDM.
-- The "hyprland.start" event fires only after the compositor is initialized,
-- once at startup - not on every config reload.

-- The autostart body is pulled out into a named function instead of an anonymous one.
-- Two reasons:
--   1. It can be called by hand to check that everything comes up, WITHOUT
--      logging out of the session (see __autostart below).
--   2. The "hyprland.start" event fires only once, so without this the only
--      autostart test is logging out and back in.
-- Launches a program only if it is NOT running yet.
--
-- On a normal login this is unnecessary, because the session starts empty. It
-- matters when you call autostart by hand through __autostart() to
-- check the config without logging out - without this guard you get
-- a second bar, a second hypridle and duplicate clipboard watchers.
--
-- Checked empirically which programs protect themselves:
--   swaync                  - holds a D-Bus name, a second instance exits
--   waybar, hyprpaper,      - do NOT protect themselves, they start a second time
--   hypridle, hyprpolkitagent, wl-paste
--
-- The second argument lets you pass your own check command when the process
-- name is not enough to tell instances apart (see wl-paste below).
-- Redirecting the launched program's output to /dev/null is
-- deliberate, not cosmetic: without it the process inherits Hyprland's
-- descriptors and in some setups can die right after starting.
-- Actually hit with the clipboard watchers - see the comment below.
local function run_once(cmd, check)
    hl.exec_cmd((check or ("pgrep -x " .. cmd)) ..
                " >/dev/null 2>&1 || { " .. cmd .. " >/dev/null 2>&1; }")
end

local function autostart()
   -- WELCOME LAYOUT
   --
   --     +------------------+------------------+
   --     |     terminal     |                  |
   --     +------------------+       yazi       |
   --     |    tty-clock     |                  |
   --     +------------------+------------------+
   --
   -- It is built by ~/.local/bin/uklad-startowy, not by three separate calls.
   -- Reason: dwindle picks the split side from the force_split option,
   -- whose default value means "wherever the mouse is" - the layout
   -- would come out differently every time. force_split = 2 is set in the
   -- dwindle section below; the script waits for each window instead of
   -- launching three at once and letting them race.
   --
   -- DELIBERATELY WITHOUT run_once - and this is not an oversight.
   --
   -- run_once glues the command together in the form:
   --     <check> || { <command> ...; }
   -- i.e. the program name ends up on THE SAME shell command line
   -- as "pgrep -f". The shell then finds itself, the check
   -- succeeds and the program never starts. That is exactly what
   -- happened here: after a restart everything came up except the layout.
   --
   -- This can be worked around with a "^name" anchor in the pattern, because the
   -- shell's command line starts with /bin/sh - but for a script launched
   -- through a shebang the anchor won't work, because the command line
   -- starts with the interpreter.
   --
   -- THE TILE ROW IS HIDDEN AFTER LOGIN - and that is intended. The welcome
   -- layout opens three windows, and the tile row (kafle/RzadKafli.qml) hides
   -- when there are windows on the desktop. It slides out when the cursor reaches the
   -- bottom edge or on SUPER+R.
   --
   -- There is a safeguard anyway, just in the script itself: it exits
   -- immediately when there is at least one window on the current desktop. At
   -- login the desktop is empty, and a manual __autostart() won't add
   -- a second set.
   hl.exec_cmd("uklad-startowy")

   run_once("hyprpaper")   -- wallpaper; reads ~/.config/hypr/hyprpaper.conf

   -- Notifications are now handled by the QUICKSHELL SHELL, not SwayNC.
   -- The D-Bus name org.freedesktop.Notifications is held by exactly one
   -- process, so swaync MUST NOT start here - if it got there first,
   -- our server would not receive a single notification.
   --
   -- The swaync package stays installed as a fallback. To go back:
   -- restore this line and point to swaync in the file
   -- ~/.local/share/dbus-1/services/org.freedesktop.Notifications.service
   -- (or simply switch to the main branch).


   run_once("waybar")

   -- Quickshell shell: HUD, tile row, panels, OSD and notifications.
   -- It must run in the background, because Waybar calls it through "qs ipc call", and the
   -- SUPER+R/U/O shortcuts through global-shortcuts - both require
   -- a running instance.
   --
   -- The -n (--no-duplicate) flag matters here. Without it you can launch
   -- a second instance of THE SAME config; the symptom is sneaky, because the
   -- panel looks normal, but "hyprctl layers" shows two
   -- "quickshell-kafle" layers on top of each other, and "qs ipc call" hits
   -- one of them at random - the panel starts responding to every other click.
   --
   -- Custom check command, because the process is called "qs", not
   -- "quickshell" - the default "pgrep -x <cmd>" would take the whole command line
   -- and never match.
   run_once("qs -n -c dark-fantasy", "pgrep -x qs")

   -- Screen blanking and locking after idle (~/.config/hypr/hypridle.conf).
   run_once("hypridle")

   -- Polkit agent, i.e. the dialog asking for the root password during system
   -- operations. WARNING: the binary is NOT in PATH, but in /usr/libexec,
   -- so plain "hyprpolkitagent" won't launch anything.
   run_once("/usr/libexec/hyprpolkitagent", "pgrep -x hyprpolkitagent")

   -- Clipboard history. wl-paste in --watch mode sits in the background and on every
   -- change of the clipboard contents appends an entry to the cliphist database.
   -- Two separate instances, because the MIME types of text and images are disjoint.
   --
   -- Both instances have the same process name, so run_once() is not
   -- enough here - instead we check whether EXACTLY TWO are running.
   --
   -- Why not "pgrep -f" on the full command line: the shell running
   -- the condition also has the fallback part in its own command line,
   -- i.e. the literal "wl-paste --type text --watch cliphist store". pgrep -f
   -- would therefore match itself, the condition would always be true and the watcher
   -- would never start. Checked - that is exactly what happened.
   -- The character-class trick ("te[x]t") protects only the pattern, not
   -- the command standing next to it on the same line.
   --
   -- "pgrep -cx" compares the process NAME (comm), not the command line, so
   -- a shell named "sh" never matches. This is robust.
   --
   -- When the count is wrong (0, or 1 after a crash), we kill the leftovers
   -- and start both from scratch - otherwise you can end up with a text watcher
   -- without an image watcher.
   -- Three things to watch out for here (all verified
   -- empirically, each cost a separate investigation):
   --
   -- 1. The command MUST NOT start with a square bracket.
   --    Hyprland treats a leading "[...]" as a window rule - a leftover of the
   --    "exec-once = [workspace 2] firefox" syntax. Written directly as
   --    "[ \"$(pgrep -cx wl-paste)\" = 2 ] || ...", the whole condition
   --    gets eaten as a rule, only the remainder starting with "||" reaches
   --    the shell and NOTHING runs, without a single
   --    word in the log. That is why this uses "test", not "[ ]".
   --
   -- 2. "setsid --fork", NOT "&". A program backgrounded with the "&" operator
   --    dies together with the shell, which Hyprland closes immediately.
   --    setsid detaches the process into its own session and returns at once.
   --
   -- 3. Redirection to /dev/null. Without it the watcher inherits the
   --    compositor's descriptors and can die right after starting.
   hl.exec_cmd(
      'test "$(pgrep -cx wl-paste)" = 2 || { pkill -x wl-paste; ' ..
      'setsid --fork wl-paste --type text  --watch cliphist store; ' ..
      'setsid --fork wl-paste --type image --watch cliphist store; ' ..
      '} >/dev/null 2>&1'
   )


   -- Sound server. On OpenRC PipeWire does not start by itself - it is launched by this
   -- script from the media-video/pipewire package (it starts pipewire,
   -- pipewire-pulse and wireplumber). Without it neither the volume keys
   -- nor the volume indicator in the bar work.
   hl.exec_cmd("gentoo-pipewire-launcher restart")

   -- Hardware settings from before the shutdown: screen and keyboard
   -- backlight, volume and mute. Restores them, then saves every few seconds
   -- (OpenRC has nothing that would remember the backlight). It waits for
   -- the PipeWire started just above by itself. Num Lock is handled in the
   -- INPUT DEVICES section. Details in ~/.local/bin/pamiec-ustawien.
   --
   -- run_once works here because the script has a "#!/bin/bash" shebang, so
   -- the process name (comm) is "pamiec-ustawien". The script also holds a
   -- flock, so a second instance exits anyway.
   run_once("pamiec-ustawien")
end

-- Registers the actual autostart at session start.
hl.on("hyprland.start", autostart)

-- The same function exposed globally, so it can be fired from outside
-- to verify autostart without logging out:
--
--   hyprctl dispatch '(function() __autostart(); return hl.dsp.no_op() end)()'
--
-- Calling it again is safe: every program starts through
-- run_once(), which first checks whether it is already running.
_G.__autostart = autostart




-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- Environment variables passed to launched programs.
-- This is most often where the cursor look, graphics backends (GDK/QT)
-- and variables required by drivers are set.
-- Change them when the cursor is too small or too large, or when some application
-- needs a specific variable.
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "24")    -- cursor size in pixels (XCursor themes)
hl.env("HYPRCURSOR_SIZE", "24") -- the same for Hyprland's native cursor format

-- Cursor theme. Without this variable Hyprland draws its own built-in cursor
-- (that "water drop"). The given name must match a directory in /usr/share/icons
-- or ~/.local/share/icons.
--
-- Bibata-Original-Classic from x11-themes/bibata-xcursors (GURU overlay):
-- a black cursor with a sharp edge, without Adwaita's rounding. The same name
-- is set in gtk-cursor-theme-name in config/gtk-3.0 and gtk-4.0/settings.ini -
-- otherwise GTK applications would draw a different cursor over their windows than the desktop.
--
-- Until the package is installed, XCursor silently falls back to the default theme.
hl.env("XCURSOR_THEME", "Bibata-Original-Classic")

-- Tells Electron applications (Obsidian, VS Code, Discord...) to start natively
-- on Wayland instead of through XWayland. XWayland does not support fractional
-- scaling, so at a scale other than 1 such windows are blurry.
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Disables Hyprland's native cursor format (hyprcursor). This way
-- the compositor is sure to use the regular XCursor theme set above,
-- and not its own default cursor.
hl.config({
    cursor = {
        enable_hyprcursor = false,
    },
})


---------------------------------
---- APPEARANCE AND BEHAVIOR ----
---------------------------------

-- The main aesthetic section: gaps, borders, rounding, shadows,
-- background blur and animations.
-- Change it when you want to rework the desktop's look or lighten the load on weaker
-- hardware (disabling blur and shadows noticeably improves smoothness).
-- See https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in  = 5,  -- gap between neighbouring windows (in pixels)
        gaps_out = 10, -- gap between windows and the screen edge

        -- 1 px, like every frame in this theme - in Waybar, in the Quickshell
        -- shell, in hyprlock. The frame should suggest the edge of forged
        -- metal, not outline the window with a marker pen.
        border_size = 1, -- window border thickness in pixels (0 = no frame)

        col = {
            -- Colors in rgba(RRGGBBAA) format, where the last two digits are
            -- the transparency.
            --
            -- Active window: full old gold. Inactive: the same gold
            -- at 20 % opacity (33 in hex) - exactly the "obwodka" border from
            -- waybar/style.css and Theme.border in the shell.
            --
            -- No gradient to ember: in this theme ember means ONLY alarm and
            -- charging, and on the frame of every active window it would fake
            -- an alarm all day long.
            --   gold  #b19a67   ember #8f4935   iron  #55504a
            active_border   = "rgba(b19a67ff)",
            inactive_border = "rgba(b19a6733)",
        },

        -- Set to true to resize windows by grabbing their
        -- borders and gaps with the mouse
        resize_on_border = false,

        -- Allows tearing, used mainly in games for
        -- lower latency. Read
        -- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before enabling it
        allow_tearing = false,

        layout = "dwindle", -- default tiling layout (alternatives: "master", "scrolling")
    },

    decoration = {
        -- Sharp rectangles - like the bar, the shell, hyprlock and SDDM.
        -- rounding_power is not set: it has no effect at a zero radius.
        rounding = 0, -- window corner rounding radius in pixels (0 = sharp corners)

        -- Opacity of the active window and of inactive windows
        -- (1.0 = fully opaque, e.g. 0.9 = slightly see-through).
        -- The active window stays at 1.0, because transparency is meant only for the terminal,
        -- not for all windows. Kitty handles it itself - see
        -- ~/.config/kitty/kitty.conf, option background_opacity.
        active_opacity   = 1.0,
        inactive_opacity = 0.92,

        -- Dimming of inactive windows. Together with inactive_opacity it gives
        -- the "world in fog, the active window in the bonfire light" effect. 0.15 is
        -- little - at 0.5 (the default) an inactive terminal becomes
        -- unreadable, and sometimes you need to read something next to the active one.
        dim_inactive = true,
        dim_strength = 0.15,

        -- Strength of the dimming around a window with the dim_around rule (the panel window
        -- "df-panel" - btop from the Status tile). 0.6, not the default 0.4: the tile row
        -- pause dims by the same amount (Theme.pauzaPrzyciemnienie), and the panel
        -- window opens precisely from the pause - the dimming must stay
        -- the same, not suddenly brighten.
        dim_around = 0.6,

        shadow = {
            enabled      = true,       -- shadow cast by windows
            -- 22 px: a wide, soft shadow lifts the window off the wallpaper like
            -- a stone slab off a wall. 4 px gave an outline, not a shadow.
            range        = 22,         -- shadow reach (blur) in pixels
            render_power = 3,          -- how fast the shadow fades at the edge, higher = sharper falloff
            color        = 0xcc060607, -- shadow color 0xAARRGGBB; almost black, to match the #0b0b0c background
        },

        blur = {
            enabled   = true,   -- background blur under transparent windows and panels
            size      = 6,      -- blur strength (radius)
            passes    = 3,      -- number of blur passes, more = nicer, but more expensive for the GPU
            vibrancy  = 0.1696, -- color saturation boost in the blurred background (range 0.0 - 1.0)

            -- "Ash, not smooth black." Noise laid over the blurred background
            -- under the bar, panels and terminal. The default 0.0117 gets lost
            -- on a dark wallpaper; 0.03 is visible, yet does not hiss like
            -- an old TV. The Quickshell shell adds the same itself
            -- (components/Szum.qml), because it draws its own background.
            noise      = 0.03,

            -- Darkening of the blurred background (1.0 = unchanged). The blurred
            -- wallpaper under the bar stops bleeding through the semi-transparent
            -- background as bright blotches - text stays readable.
            brightness = 0.8,
        },
    },

    animations = {
        enabled = true, -- master switch for all animations (false = instant switching)
    },
})

-- Default curves and animations.
-- Curves (hl.curve) define the character of the motion, and hl.animation assigns them
-- to specific interface elements. Change them when the animations are
-- too slow or too fast for you, or you want to tone them down.
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
-- Bezier curves: two pairs of control points, just like CSS cubic-bezier().
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

-- THERE ARE NO SPRINGS.
--
-- A spring by definition arrives with a bounce - and in the Dark Souls style
-- nothing bounces or pops out, things only slowly emerge. Windows fade in
-- along the easeOutQuint curve, like the shell's panels.

-- Assigning animations to interface elements:
-- leaf   - which element the animation applies to,
-- speed  - duration in deciseconds (1 = 100 ms), so a larger value = slower,
-- bezier - the curve used, defined above,
-- style  - effect variant.
--
-- WINDOWS ONLY FADE, but not with the "fade" style - windows do not have
-- such a style. Hyprland 0.56.2 accepts for "window*" leaves only
-- slide, gnome(d) and "popin N%" (CHyprAnimationManager::styleValidInConfigVar
-- in src/animation/AnimationManager.cpp); "fade" gives an "unknown style" error.
-- "popin 100%" means growing from 100 % of the size, i.e. no size
-- change - only the opacity remains, which the fadeIn/fadeOut leaves animate.
-- Both got the same curve and duration as the windows, so the whole thing is one
-- slow emergence.
--
-- The layer durations (layersIn 500 ms, layersOut 200 ms) mirror
-- animPanelIn / animPanelOut from config/quickshell/dark-fantasy/Theme.qml -
-- the shell animates panel opening itself, so both paces must match.
-- A table instead of seventeen hl.animation calls. The same durations are recomputed by
-- the shell's Cogwheel (Hyprland -> Motion section) with a single pace slider: Hyprland
-- has no global speed multiplier, so every leaf has to be declared
-- again with the recomputed duration.
local ANIMACJE = {
    { leaf = "global",        speed = 10,    bezier = "default" },
    { leaf = "border",        speed = 5.39,  bezier = "easeOutQuint" },
    { leaf = "windows",       speed = 3,     bezier = "easeOutQuint" },
    { leaf = "windowsIn",     speed = 3,     bezier = "easeOutQuint",  style = "popin 100%" },
    { leaf = "windowsOut",    speed = 3,     bezier = "easeOutQuint",  style = "popin 100%" },
    { leaf = "fadeIn",        speed = 3,     bezier = "easeOutQuint" },
    { leaf = "fadeOut",       speed = 3,     bezier = "easeOutQuint" },
    { leaf = "fade",          speed = 3.03,  bezier = "quick" },
    { leaf = "layers",        speed = 5,     bezier = "easeOutQuint" },
    { leaf = "layersIn",      speed = 5,     bezier = "easeOutQuint",  style = "fade" },
    { leaf = "layersOut",     speed = 2,     bezier = "linear",        style = "fade" },
    { leaf = "fadeLayersIn",  speed = 1.79,  bezier = "almostLinear" },
    { leaf = "fadeLayersOut", speed = 1.39,  bezier = "almostLinear" },
    { leaf = "workspaces",    speed = 1.94,  bezier = "almostLinear",  style = "fade" },
    { leaf = "workspacesIn",  speed = 1.21,  bezier = "almostLinear",  style = "fade" },
    { leaf = "workspacesOut", speed = 1.94,  bezier = "almostLinear",  style = "fade" },
    { leaf = "zoomFactor",    speed = 7,     bezier = "quick" },
}

-- Declares all animations from the table. "tempo" 1 = durations from the table,
-- 2 = twice as fast, 0.5 = twice as slow (speed is a duration, so it gets
-- DIVIDED by tempo). Global, because it is also called by ~/.config/hypr/ustawienia.lua
-- generated by the Cogwheel, and by "hyprctl eval" while the slider moves.
function _G.ustawAnimacje(tempo)
    tempo = tonumber(tempo) or 1
    if tempo <= 0 then tempo = 1 end
    for _, anim in ipairs(ANIMACJE) do
        hl.animation({
            leaf    = anim.leaf,
            enabled = true,
            speed   = anim.speed / tempo,
            bezier  = anim.bezier,
            style   = anim.style,
        })
    end
end

ustawAnimacje(1)

-- Settings of the "dwindle" layout, in which a new window splits the area of the previous one
-- in half. This is the layout selected above in general.layout.
-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/
hl.config({
    dwindle = {
        preserve_split = true, -- keeps the split direction when windows are resized; you usually want this

        -- Which side the NEW window lands on.
        --   0 - wherever the mouse happens to be (default)
        --   1 / 2 - always on the same side
        --
        -- Zero means the window layout depends on the cursor position, so
        -- the same set of programs launched twice gives two different
        -- layouts. For building the welcome layout
        -- (~/.local/bin/uklad-startowy) that is disqualifying.
        --
        -- This option CANNOT be changed on the fly: "hyprctl
        -- keyword" does not work with a Lua config - checked,
        -- reading it back after writing shows the old value. So it must stay here.
        --
        -- Measured after setting it in this file and reloading:
        --     1  ->  new window to the LEFT / UP
        --     2  ->  new window to the RIGHT / DOWN   <- this is what we want
        force_split = 2,
    },
})

-- Settings of the "master" layout: one main window plus a stack of the others.
-- They matter only when you set general.layout to "master".
-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/
hl.config({
    master = {
        new_status = "master", -- a newly opened window becomes the main (master) window
    },
})


----------------
----  MISC  ----
----------------

-- Minor compositor behavior settings, including the default wallpaper and logo.
-- Change them when you want to get rid of Hyprland's default background.
hl.config({
    misc = {
        force_default_wallpaper = 0,     -- 0 = no built-in wallpaper; hyprpaper draws the background
        disable_hyprland_logo   = true,  -- no random background with the Hyprland logo / anime
        -- WARNING: this option does NOT remove the splash text ("Read the wiki.") that
        -- sits at the bottom of the wallpaper. Hyprland only picks the random string -
        -- the text is DRAWN BY HYPRPAPER, which fetches it from the compositor and paints
        -- it over the wallpaper. Measured on Hyprland 0.56.2: "hyprctl getoption
        -- misc:disable_splash_rendering" reports true while the text still renders, and
        -- neither disable_hyprland_logo, nor force_default_wallpaper, nor a transparent
        -- misc:col.splash changes anything. The switch that does work is "splash = 0"
        -- in hyprpaper.conf (see hyprwm/Hyprland discussions #13176 and #14704).
        --
        -- What stays below only concerns the splash on Hyprland's OWN background, the one
        -- hyprpaper covers anyway.
        disable_splash_rendering = true,
    },
})


-----------------------
---- INPUT DEVICES ----
-----------------------

-- Keyboard, mouse and touchpad: keyboard layout, how focus follows
-- the cursor, mouse sensitivity and gestures.
-- Change it when you want a different keyboard layout, a different mouse sensitivity or
-- natural scrolling on the touchpad.

-- Num Lock from before the shutdown. ~/.local/bin/pamiec-ustawien keeps
-- "numlock=0/1" in $XDG_STATE_HOME/dark-fantasy/ustawienia-sprzetu up to date.
-- Hyprland has no dispatcher that flips Num Lock at runtime, so the saved
-- state goes into numlock_by_default, which applies when a keyboard is
-- created - at login. No file (first boot) = off, Hyprland's default.
local function readNumlock()
    local state = os.getenv("XDG_STATE_HOME")
    if not state or state == "" then
        state = (os.getenv("HOME") or "") .. "/.local/state"
    end
    local f = io.open(state .. "/dark-fantasy/ustawienia-sprzetu", "r")
    if not f then return false end
    local text = f:read("a") or ""
    f:close()
    return ("\n" .. text):find("\nnumlock=1", 1, true) ~= nil
end

hl.config({
    input = {
        numlock_by_default = readNumlock(), -- Num Lock state from the previous session (see above)

        kb_layout  = "pl", -- keyboard layout (XKB code), e.g. "pl", "us", or "pl,us" for two layouts
        kb_variant = "",   -- layout variant, e.g. "dvorak" (empty = default)
        kb_model   = "",   -- keyboard model per XKB (empty = default)
        kb_options = "",   -- extra XKB options, e.g. a layout switch shortcut (empty = none)
        kb_rules   = "",   -- XKB rule set (empty = default)

        follow_mouse = 1, -- 1 = focus follows the mouse cursor (0 disables this behavior)

        sensitivity = 0, -- mouse sensitivity in the range -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = false, -- true = "phone-like" scrolling, i.e. reversed direction
        },
    },
})

-- TOUCHPAD GESTURES: three fingers sideways switch desktops, vertically floors.
--
-- Both gestures are further down, in the FLOORS AND DESKTOPS section, because they need
-- the floors module to be loaded already. Not the native action = "workspace":
-- it knows nothing about floors and goes from the last desktop of a floor
-- to the next one. Rationale next to the gestures in floors.lua.


---------------------
---- KEYBINDINGS ----
---------------------

-- All keybindings. This is where you add your own combinations
-- and change the assignments of existing ones.
-- See https://wiki.hypr.land/Configuring/Basics/Binds/

local mainMod = "SUPER" -- sets the "Windows" key as the main modifier

-- Basic shortcuts (examples, feel free to change them)
--
-- Every shortcut has a "description". They are visible in "hyprctl binds" - and from that
-- command the shell's Cogwheel builds the shortcut overview (Hyprland ->
-- Shortcuts section). A shortcut without a description would show up there as "__lua" with a number.
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal), { description = T("Terminal", "Terminal") }) -- launch the terminal
hl.bind(mainMod .. " + C", hl.dsp.window.close(), { description = T("Close window", "Zamknij okno") }) -- close the active window
-- Ending the session: runs hyprshutdown if it is available on the system,
-- otherwise calls the fallback command through hyprctl.
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"), { description = T("Log out", "Wyloguj") })
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }), { description = T("Floating / tiled window", "Okno pływające / kafelkowane") }) -- toggle the window: floating / tiled
hl.bind(mainMod .. " + R", hl.dsp.global("quickshell:menuToggle"), { description = T("Tile menu - Arsenal", "Menu kafli - Uzbrojenie") }) -- pause: tile menu at the bottom of the screen
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(fileManager), { description = T("File manager (yazi)", "Menedżer plików (yazi)") }) -- launch the file manager (yazi)
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo(), { description = T("Pseudotile", "Pseudokafelkowanie") }) -- pseudotiling: the window keeps its own size, but still takes up its place in the layout
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"), { description = T("Toggle split direction", "Zmień kierunek podziału") }) -- change the split direction (vertical/horizontal); dwindle only

-- Cogwheel - settings (Quickshell). "U" as in Ustawienia (settings). It opens
-- the tile row pause with the Cogwheel selected; the settings show above the row.
--
-- hl.dsp.global sends the shortcut through the global-shortcuts protocol straight to
-- the already running shell. This is NOT the same as exec_cmd - there every
-- press would launch a new "qs ipc" process, here none is created.
--
-- The name "quickshell:systemToggle" comes from the GlobalShortcut in shell.qml
-- (appid "quickshell", name "systemToggle"). You can check the registered shortcuts
-- with the command: hyprctl globalshortcuts
--
-- If the shell is not running, the shortcut simply does nothing - Hyprland has
-- no one to deliver it to and does not report it as an error.
hl.bind(mainMod .. " + U", hl.dsp.global("quickshell:systemToggle"), { description = T("Cogwheel - settings", "Zębatka - ustawienia") })

-- Media player panel. "O" as in Odtwarzacz (player) - just as "U" above stands for
-- Ustawienia (settings).
--
-- The shortcut is NOT only for convenience: the media modules on the bar
-- (track title and cover) disappear when nothing is playing, so without it, on a
-- silent desktop, there would be nothing to open the panel with.
hl.bind(mainMod .. " + O", hl.dsp.global("quickshell:mediaToggle"), { description = T("Media player panel", "Panel odtwarzacza") })

-- Power profile: power saver -> balanced -> performance. The switching is done by
-- the shell (GlobalShortcut "profilZasilania" in shell.qml) through
-- power-profiles-daemon over D-Bus, and it shows the OSD right away. The bind does not call
-- powerprofilesctl, so that the switch and its confirmation live in one place.
hl.bind(mainMod .. " + B", hl.dsp.global("quickshell:profilZasilania"), { description = T("Power profile: next", "Profil zasilania: następny") })

-- Changing the active window with mainMod + arrows
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }), { description = T("Focus left", "Fokus w lewo") })
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }), { description = T("Focus right", "Fokus w prawo") })
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }), { description = T("Focus up", "Fokus w górę") })
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }), { description = T("Focus down", "Fokus w dół") })

-- FLOORS AND DESKTOPS
--
-- A desktop is a (floor, desktop) pair, not a global number. The logic
-- and the mapping to Hyprland workspaces live in ~/.config/hypr/floors.lua.
--
--   mainMod + [0-9]            desktop on the CURRENT floor
--   mainMod + SHIFT + [0-9]    move the window to a desktop of the current floor
--   mainMod + CTRL + [0-9]     floor - returns to its last desktop
--   mainMod + CTRL + up/down   floor up / down
--   3 fingers left / right     next / previous desktop of the floor
--   3 fingers up / down        floor up / down
--
-- The shortcuts are FUNCTIONS, not ready-made dispatchers.
-- hl.dsp.focus({ workspace = 3 }) computes the number once, when the
-- config is read, and the same key has to mean something different on each floor -
-- so the number must be computed at the moment of the key press.
local floors = require("floors")
floors.setup()

for i = 1, 10 do
    local key = i % 10 -- desktop and floor 10 map to the 0 key
    hl.bind(mainMod .. " + " .. key,         function() return hl.dispatch(floors.desktop(i)) end, { description = T("Desktop " .. key .. " on the current floor", "Pulpit " .. key .. " na bieżącym piętrze") })
    hl.bind(mainMod .. " + SHIFT + " .. key, function() return hl.dispatch(floors.move(i)) end,    { description = T("Move window to desktop " .. key, "Przenieś okno na pulpit " .. key) })
    hl.bind(mainMod .. " + CTRL + " .. key,  function() return hl.dispatch(floors.floor(i)) end,   { description = T("Floor " .. key, "Piętro " .. key) })
end

hl.bind(mainMod .. " + CTRL + up",   function() return hl.dispatch(floors.floor_step(1)) end, { description = T("Floor up", "Piętro wyżej") })
hl.bind(mainMod .. " + CTRL + down", function() return hl.dispatch(floors.floor_step(-1)) end, { description = T("Floor down", "Piętro niżej") })

-- Three-finger gestures, from anywhere on the screen:
--   left / right      -> next / previous desktop of the floor; past the last one
--                        it creates a new one, but never leaves the floor
--   up / down         -> floor up / down
-- Hyprland decides the axis from the first pixels of movement, so both gestures
-- live side by side. Why in Lua and not the native "workspace" - see
-- the gestures in floors.lua.
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = floors.desktop_swipe,
})
hl.gesture({
    fingers   = 3,
    direction = "vertical",
    action    = floors.floor_swipe,
})

-- Special desktop (scratchpad), i.e. a hidden desktop overlaid on the current one
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"), { description = T("Show / hide scratchpad", "Pokaż / ukryj scratchpad") }) -- show/hide the scratchpad
-- Moving a window to the scratchpad is on SUPER+SHIFT+X, not the usual
-- SUPER+SHIFT+S - that one takes a screenshot of a selected area (see the
-- SCREENSHOTS section below).
hl.bind(mainMod .. " + SHIFT + X", hl.dsp.window.move({ workspace = "special:magic" }), { description = T("Move window to scratchpad", "Przenieś okno do scratchpada") }) -- move the window to the scratchpad

-- Cycling through existing desktops with the mouse wheel: mainMod + scroll,
-- wrapping around, but only within the CURRENT floor.
--
-- Not "e+1" / "e-1", i.e. the next / previous existing workspace overall:
-- with floors that would jump from the last desktop of F1 straight to F2.
hl.bind(mainMod .. " + mouse_down", function() return hl.dispatch(floors.desktop_step(1)) end, { description = T("Next desktop on this floor", "Następny pulpit piętra") })
hl.bind(mainMod .. " + mouse_up",   function() return hl.dispatch(floors.desktop_step(-1)) end, { description = T("Previous desktop on this floor", "Poprzedni pulpit piętra") })

-- Moving and resizing windows: mainMod + LMB/RMB and dragging
-- (mouse:272 = left mouse button, mouse:273 = right)
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true, description = T("Move window with mouse", "Przesuń okno myszą") })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = T("Resize window with mouse", "Zmień rozmiar okna myszą") })

-- Laptop multimedia keys: volume and screen brightness.
-- locked    = the shortcut also works when the screen is locked,
-- repeating = holding the key repeats the action.
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true, description = T("Volume up", "Głośniej") })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true, description = T("Volume down", "Ciszej") })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true, description = T("Mute audio", "Wycisz dźwięk") })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true, description = T("Mute microphone", "Wycisz mikrofon") })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -n2 set 5%+"),                  { locked = true, repeating = true, description = T("Brightness up", "Jaśniej") })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -n2 set 5%-"),                  { locked = true, repeating = true, description = T("Brightness down", "Ciemniej") })

-- Player control, requires playerctl to be installed
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true, description = T("Next track", "Następny utwór") })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = T("Pause", "Pauza") })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = T("Play", "Odtwarzaj") })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true, description = T("Previous track", "Poprzedni utwór") })

-- SCREENSHOTS (hyprshot)
--
-- hyprshot wraps grim and slurp: it takes the shot, copies it to the clipboard
-- AND saves a file, and sends a notification itself. ~/.local/bin/zrzut-ekranu
-- is an alternative without hyprshot - replace the commands below to use it.
--
--   -m region   rectangle selected with the mouse
--   -m window   the pointed-at window
--   -m output   the whole monitor
--   -z          freeze the image while selecting (otherwise menus and animations
--               have time to change between the selection and the shot)
--   -o          target directory; the name can contain a space ("Zrzuty ekranu"), so the quotes are required
-- Folder: <XDG Pictures>/Screenshots ("Zrzuty ekranu" in Polish), created
-- on first use. The command runs through sh, so $(...) is expanded there.
local zrzuty  = '$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")/' .. T("Screenshots", "Zrzuty ekranu")
local hyprshot = 'd="' .. zrzuty .. '"; mkdir -p "$d"; hyprshot -z -o "$d" -m ' 

hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(hyprshot .. "region"), { description = T("Screenshot of selected area", "Zrzut zaznaczonego obszaru") }) -- selected area
hl.bind("Print",                   hl.dsp.exec_cmd(hyprshot .. "output"), { description = T("Screenshot of whole monitor", "Zrzut całego monitora") }) -- whole monitor
hl.bind("SHIFT + Print",           hl.dsp.exec_cmd(hyprshot .. "region"), { description = T("Screenshot of selected area", "Zrzut zaznaczonego obszaru") }) -- selected area
hl.bind(mainMod .. " + Print",     hl.dsp.exec_cmd(hyprshot .. "window"), { description = T("Screenshot of chosen window", "Zrzut wskazanego okna") }) -- pointed-at window


-- SCREEN LOCK AND CLIPBOARD

-- Screen lock on demand. The same hyprlock is also launched by hypridle after
-- 10 minutes of idle (~/.config/hypr/hypridle.conf).
--
-- "pidof hyprlock ||" matters here, it is not decoration. Without it, pressing
-- the shortcut twice launches a SECOND lock instance on top of the
-- first - and each has to be unlocked separately, typing the password twice.
-- hypridle uses the same safeguard in its lock_cmd.
--
-- WARNING: do not kill hyprlock with pkill while the lock is active.
-- It is an ext-session-lock protocol client, and killing it with a signal can
-- bring down the whole session. Details in the hyprlock.conf header.
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("pidof hyprlock || hyprlock"), { description = T("Lock screen", "Zablokuj ekran") })

-- Clipboard history.
--
-- cliphist list prints numbered entries, rofi shows them as a list,
-- and cliphist decode turns the selected number back into the content.
-- "--no-custom" blocks typing your own text, which could not be
-- decoded anyway; "-i" enables case-insensitive search.
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd(
    "cliphist list | rofi -dmenu -i -no-custom -p '" .. T("Clipboard", "Schowek") .. "' " ..
    "-theme $HOME/.config/rofi/dark-fantasy.rasi " ..
    "-theme-str 'entry { placeholder: \"" .. T("search the clipboard...", "szukaj w schowku...") .. "\"; }' " ..
    "| cliphist decode | wl-copy"), { description = T("Clipboard history", "Historia schowka") })


-------------------------------------------
---- WINDOWS AND DESKTOPS (WORKSPACES) ----
-------------------------------------------

-- Rules describing how specific windows should behave: whether they should be
-- floating, where they should appear, whether they may take focus etc.
-- Windows are matched through match (class, title, state), and name only serves
-- to identify the rule itself.
-- Add entries here when some program should open differently from the rest.
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

hl.window_rule({
    -- Ignores maximize requests sent by applications.
    -- This way programs do not break the tiling layout; this is usually desirable.
    name  = "suppress-maximize-events",
    match = { class = ".*" }, -- regular expression matching every window class

    suppress_event = "maximize",
})

hl.window_rule({
    -- Fixes dragging problems in XWayland applications.
    -- Matches the empty, floating helper windows created while
    -- dragging (empty class and empty title) and takes focus away from them.
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",  -- empty window class
        title      = "^$",  -- empty window title
        xwayland   = true,  -- only windows running through XWayland
        float      = true,  -- only floating windows
        fullscreen = false, -- skips fullscreen windows
        pin        = false, -- skips pinned windows
    },

    no_focus = true, -- such a window will never take focus
})

-- LAYER RULES
--
-- Waybar, the shell panels and swaync are layer-shell surfaces, not windows,
-- so decoration.blur does not apply to them - they have to be named separately.
-- You can check the namespace names with the command: hyprctl layers
--
-- ignore_alpha cuts off blurring for pixels below the given opacity.
-- Without it the blur also shows under fully transparent parts of the
-- bar and the segments turn milky instead of sharp.
-- "quickshell-*" are the Quickshell panels (config/quickshell/dark-fantasy).
-- Each panel sets its namespace name itself, through WlrLayershell.namespace.
-- Until the panel is running, the rule is idle - Hyprland simply does not
-- find a layer with that name and nothing happens.
for _, ns in ipairs({ "waybar", "swaync-notification-window", "swaync-control-center",
                      "quickshell-media", "quickshell-osd",
                      "quickshell-quick", "quickshell-popups",
                      -- HUD in the left corner: it should look like the bar frame, so
                      -- it gets the same blur with noise as Waybar.
                      "quickshell-hud" }) do
    hl.layer_rule({
        name         = "blur-" .. ns,
        match        = { namespace = "^" .. ns .. "$" },
        blur         = true,
        ignore_alpha = 0.2,
    })
end

-- HUD ABOVE WAYBAR.
--
-- The shell's HUD (hud/Hud.qml) sits at the left end of the bar, on the same
-- "top" layer as Waybar. With equal order the surface created later lies
-- on top - so after every Waybar restart the bar would cover the
-- HUD. You would not see it (the left part of the bar is transparent), but
-- clicks on the desktop squares and on the circle on the emblem would go to Waybar.
--
-- "order" sets the order within a layer. Hyprland 0.56.2 sorts
-- layers by order in DESCENDING order (Renderer.cpp, arrangeLayersForMonitor),
-- draws them from the start of the list, and the mouse checks from the end
-- (ViewHitTester.cpp) - i.e. a LOWER value lies higher and gets the cursor
-- first. Default 0; the HUD gets -1.
hl.layer_rule({
    name  = "hud-nad-paskiem",
    match = { namespace = "^quickshell-hud$" },
    order = -1,
})

-- TILE ROW ABOVE THE HUD AND THE BAR.
--
-- The tile row window (kafle/RzadKafli.qml) is fullscreen, and in pause
-- mode it dims the whole screen. The dimming should also cover the bar
-- and the HUD - like in a game, where the menu dims everything beneath it - so the window
-- must lie above them: order -2, lower than the HUD (-1). The sort direction is
-- described at the "hud-nad-paskiem" rule.
--
-- Outside the pause the window mask covers only the strip along the bottom edge and the
-- row itself, so the bar at the top and the HUD receive clicks normally.
--
-- No blur: the world under the menu should stay sharp, only dark - that is why
-- "quickshell-kafle" is not on the list of "blur-*" rules.
hl.layer_rule({
    name  = "kafle-nad-hudem",
    match = { namespace = "^quickshell-kafle$" },
    order = -2,
})

-- PANEL WINDOW - Status (btop).
--
-- The "df-panel" class is set by the wrapper local/bin/monitor-systemu (kitty --class).
-- The rule name is generic, because every further preview opened from a tile
-- can get the same class.
--
-- Yazi from the Satchel does NOT get this class - it opens as a regular tiled
-- window in the layout, like the terminal (described in local/bin/menedzer-plikow). A file manager
-- is a tool for working alongside other windows, not a quick preview.
--
--   float + center + size   floating window in the centre, 70 x 70 % of the screen -
--                           a panel above the desktop, not another tiled window
--   rounding = 0            like every window, but explicit - the panel must stay sharp
--                           even if someone restored rounding globally
--   dim_around              dims the rest of the screen while the window is
--                           open - the tile row pause closes after a tile
--                           is used, but the "world in fog" should remain
--
-- The size is a Hyprland expression (monitor_w, monitor_h), not percentages -
-- rules in Lua take a pair of expressions, just like "move" below.
--
-- Animation: windows only fade anyway ("popin 100%" in the animation section),
-- so there is no separate animation rule here.
hl.window_rule({
    name  = "okno-panelu",
    match = { class = "^df-panel$" },

    float      = true,
    center     = true,
    size       = "monitor_w*0.7 monitor_h*0.7",
    rounding   = 0,
    dim_around = true,
})


----------------------------------------
---- COGWHEEL SETTINGS (LAST) ----------
----------------------------------------

-- The file ~/.config/hypr/ustawienia.lua is generated by the Quickshell shell's Cogwheel
-- (services/UstawieniaHyprlanda.qml): gaps, frame, blur, animation pace,
-- touchpad, keyboard layout, screen scale, number of floors...
--
-- WHY A SEPARATE FILE. The GUI does not edit this file - hyprland.lua is
-- written by hand, with comments, and no generator has the right to
-- rewrite it. The Cogwheel owns one simple file that
-- OVERRIDES selected values; "Restore defaults" simply means deleting it
-- and reloading.
--
-- WHY AT THE VERY END. Every hl.config above sets the default
-- values; the GUI settings must come AFTER them, otherwise they would be
-- overwritten back. The same applies to floors.setup() and ustawAnimacje().
--
-- WHY dofile, NOT require. Hyprland reports a module missing from require
-- as a config error with a red bar (config/lua/ConfigManager.cpp),
-- and a missing file is the normal state here - a fresh install. Besides, files
-- loaded through require are tracked by Hyprland and reloaded on every save
-- (that is how floors.lua works) - and the Cogwheel saves on every slider change.
-- Live changes go through a separate path anyway, via "hyprctl eval".
--
-- The path follows XDG_CONFIG_HOME, just like in the shell - thanks to this
-- the test stand can have its own file and leave the session's one untouched.
--
-- The file is outside the repository (.gitignore) - it is the state of this computer,
-- not the desktop configuration.
local USTAWIENIA = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config"))
    .. "/hypr/ustawienia.lua"

local plikUstawien = io.open(USTAWIENIA, "r")
if plikUstawien then
    plikUstawien:close()
    local ok, blad = pcall(dofile, USTAWIENIA)
    if not ok then
        -- A broken file must not bring down the whole config - the rest has
        -- already loaded. The notification says where to look and how to get out.
        pcall(hl.notification.create, {
            text    = "ustawienia.lua: " .. tostring(blad) .. T(" (Cogwheel -> Restore defaults)", " (Zębatka -> Przywróć domyślne)"),
            timeout = 15000,
        })
    end
end
