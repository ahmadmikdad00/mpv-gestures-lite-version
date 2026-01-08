-- touchscreen and mouse gestures for mpv.

local OPTS = {
    autostart = 1,

    deadzone = 30,
    sample_rate_ms = 16,
    input_delay = 0,

    seek_volume_button = "MOUSE_BTN0",

    pixels_per_second = 6,
    volume_modifier = 60,

    speed_enabled = 1,
    speed_button = "MBTN_MID",
    pps = 1200,
}

(require "mp.options").read_options(OPTS)

local mp = require "mp"

-- =========================
-- DRAG HANDLER (FINAL)
-- =========================
local function drag_handler(onDrag, onStart, onEnd, options)
    options = options or {}
    local deadzone = options.deadzone or 30
    local button = options.button or "MOUSE_BTN0"
    local tick = options.tick_ms or 16

    local state = "idle" -- idle | tracking | dragging
    local sx, sy = 0, 0
    local lastx, lasty = 0, 0
    local click_time = 0

    local ticker
    ticker = mp.add_periodic_timer(tick / 1000, function()
        if state == "tracking" or state == "dragging" then
            local x, y = mp.get_mouse_pos()
            local dx = x - sx
            local dy = y - sy

            if state == "tracking" then
                if math.abs(dx) > deadzone or math.abs(dy) > deadzone then
                    state = "dragging"
                    onStart()
                else
                    return
                end
            end

            onDrag(dx, dy)
            lastx, lasty = x, y
        end
    end)
    ticker:kill()

    local function binding(e)
        if e.event == "down" then
            sx, sy = mp.get_mouse_pos()
            lastx, lasty = sx, sy
            click_time = mp.get_time()
            state = "tracking"
            ticker:resume()

        elseif e.event == "up" then
            ticker:kill()
            local was_drag = (state == "dragging")
            state = "idle"

            if was_drag then
                onEnd()
            else
                if options.on_click and mp.get_time() - click_time < 0.3 then
                    options.on_click()
                end
            end
        end
    end

        local bind_name = "gesture-" .. button

        return {
            start = function()
                mp.add_forced_key_binding(button, bind_name, binding, {complex = true})
            end,
            stop = function()
                mp.remove_key_binding(bind_name)
            ticker:kill()
            state = "idle"
        end
    }
end

-- =========================
-- SEEK + VOLUME
-- =========================
local function seek_n_volume()
    local init_pos, init_vol, max_vol, osd_h
    local mode = nil -- "seek" | "volume"

    local drag = drag_handler(
        function(dx, dy)
            if not mode then
                if math.abs(dx) > math.abs(dy) then
                    mode = "seek"
                else
                    mode = "volume"
                end
            end

            if mode == "seek" then
                mp.commandv(
                    "seek",
                    init_pos + dx / OPTS.pixels_per_second,
                    "absolute",
                    "exact"
                )
            else
                local vol = init_vol - (dy / osd_h) * OPTS.volume_modifier
                vol = math.max(0, math.min(max_vol, vol))
                mp.commandv("set", "volume", vol)
                mp.osd_message(("Volume: %d%%"):format(vol), 0.3)
            end
        end,
        function()
            init_pos = mp.get_property_number("time-pos", 0)
            init_vol = mp.get_property_number("volume", 50)
            max_vol = mp.get_property_number("volume-max", 100)
            local _, h = mp.get_osd_size()
            osd_h = h
            mode = nil
        end,
        function() end,
        {
            deadzone = OPTS.deadzone,
            button = OPTS.seek_volume_button,
            tick_ms = OPTS.sample_rate_ms,
            on_click = function()
                mp.command("cycle pause")
            end
        }
    )

    return drag
end

local function speed_control()
    if OPTS.speed_enabled ~= 1 then
        return { start = function() end, stop = function() end }
    end

    local init_speed

    return drag_handler(
        function(dx, dy)
            local spd = math.max(0.01, init_speed + dx / OPTS.pps)
            mp.commandv("set", "speed", spd)
            mp.osd_message(("Speed: %.2fx"):format(spd), 0.3)
        end,
        function()
            init_speed = mp.get_property_number("speed", 1.0)
        end,
        function() end,
        {
            deadzone = OPTS.deadzone,
            button = OPTS.speed_button,
            tick_ms = OPTS.sample_rate_ms,
        }
    )
end

-- =========================
-- INIT
-- =========================
local ctl = seek_n_volume()
local ctl_speed = speed_control()


if OPTS.autostart == 1 then
    ctl.start()
    ctl_speed.start()
end

mp.add_key_binding(nil, "toggle-gestures", function()
    ctl.stop()
    ctl_speed.stop()
    ctl.start()
    ctl_speed.start()
end)
