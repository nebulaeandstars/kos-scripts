function launch {
    countdown_s(3).
    lock throttle to 1.
    init_staging().
    stage.
}

function countdown_s {
    parameter seconds.
    logmsg("counting down").

    from {local countdown is 3.} until countdown = 0
    step {set countdown to countdown - 1.}
    do {
        logmsg("- " + countdown).
        wait 1.
    }
}

function init_display {
    parameter refresh_interval is 0.2.

    local height is 5.
    print divider() at (0, height).

    set next_ui_update to time:seconds + refresh_interval.
    when time:seconds > next_ui_update then {
        local pitch is get_ascention_pitch().

        print pad("Apoapsis: " + round(ship:apoapsis, 0) + "m") at (0,0).
        print pad("Periapsis: " + round(ship:periapsis, 0) + "m") at (0,1).
        print pad("Target Pitch: " + round(pitch, 1) + "°") at (0,3).
        print pad("Throttle: " + round(throttle * 100, 0) + "%") at (0,4).

        set next_ui_update to time:seconds + 0.1.
        return true.
    }
}

function refresh_display {
    parameter height.
    until height = -1 {
        print emptyline() at (0, height).
        set height to height - 1.
    }
}

function init_logs {
    parameter height.
    global log_height is height.
    global logs is list().
    print divider() at (0, terminal:height - log_height - 1).
}

function logmsg {
    parameter message.
    parameter level is "INFO".
    logs:add(message).
    print_logs().
}

function print_logs {
    local log_start is terminal:height - min(log_height, logs:length).
    local real_height is terminal:height - log_start.
    local max_entries is min(log_height, logs:length).

    local i is 0.
    local row is 0.
    for entry in logs {
        if logs:length - i <= real_height {
            print pad(logs[i]) at (0, log_start + row).
            set row to row + 1.
        }
        set i to i + 1.
    }
}

function emptyline {
    return "":padright(terminal:width - 1).
}

function pad {
    parameter s.
    return s:padright(terminal:width - 1).
}

function divider {
    return "--------------------".
}

function timestamp {
    parameter ts is time.
    return ts:year + "y" + ts:day + "d " + ts:clock.
}

function init_staging {
    logmsg("initialising staging").
    when engine_flameout and throttle > 0 then {
        logmsg("stage " + ship:stagenum + " is away").
        stage.
        return ship:maxthrust > 0.
    }.
}

function engine_flameout {
    list engines in ship_engines.
    for engine in ship_engines {
        if engine:ignition and engine:flameout {
            return true.
        }
    }
    return false.
}

function init_timewarp {
    when ship:altitude > 200 then {
        logmsg("engaging physical timewarp").
        set kuniverse:timewarp:mode to "PHYSICS".
        set kuniverse:timewarp:warp to 4.
    }.
}

function scale_in_range {
    parameter actual.
    parameter min.
    parameter max.

    if actual >= max {
        return 1.0.
    }
    else if actual <= min {
        return 0.0.
    }
    else {
        return (actual - min) / (max - min).
    }
}

function normal_vector {
    return vcrs(ship:velocity:orbit,-body:position).
}

function current_isp {
    local isp is 0.
    local ship_engines is list().
    list engines in ship_engines.
    for en in ship_engines {
        if en:ignition and not en:flameout {
            set isp to isp + (en:isp * (en:maxthrust / ship:maxthrust)).
        }
    }
    return isp.
}

function point_normal {
    lock steering to normal_vector().
    wait 10.
    set SAS to false.
}

function unimplemented {
    parameter fn_name.
    logmsg("unimplemented: " + fn_name, "ERROR").
}

// TODO: Move this somewhere else
function get_ascention_pitch {
    if speed < 75 {
        return 90.0.
    }
    else if speed < 150 {
        return 80.0.
    }
    else {
        if ship:altitude < 30000 {
            set prograde_vector to ship:srfprograde:forevector.
        } else {
            set prograde_vector to ship:prograde:forevector.
        }
        return 90 - vang(ship:up:forevector, prograde_vector).
    }
}
