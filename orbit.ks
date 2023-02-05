run common.
run maneuver.

lock speed to ship:velocity:surface:mag.
lock apoapsis to ship:orbit:apoapsis.
lock periapsis to ship:orbit:periapsis.
lock time_to_apoapsis to ship:orbit:eta:apoapsis.

set negligible_atmosphere to 50000.
set max_ascent_tta to 50.
set min_ascent_tta to 45.

set max_circularisation_tta to 10.
set min_circularisation_tta to 5.
set min_circularisation_burn to 0.1.

function main {
    clearscreen.

    init_logs(10).
    init_display().
    init_timewarp().

    launch().
    do_ascent().
    circularize().
    point_normal().
    set SAS to true.

    logmsg("done!").
}

function get_ascention_throttle {
    if ship:altitude < negligible_atmosphere {
        return 1 - scale_in_range(
            time_to_apoapsis,
            min_ascent_tta,
            max_ascent_tta
        ).
    } else {
        return 1.0.
    }
}

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

function do_ascent {
    logmsg("starting ascent").

    set SAS to false.
    until apoapsis > 80000 {
        set target_throttle to get_ascention_throttle().
        set target_pitch to get_ascention_pitch().

        lock throttle to get_ascention_throttle().
        lock steering to heading(90, target_pitch, 270).
    }.

    lock throttle to 0.0.
    logmsg("ascent complete").
}

function circularize {
    logmsg("waiting to exit atmosphere").
    lock steering to prograde.
    wait until ship:altitude > 70000.

    logmsg("warping to apoapsis").
    local warp_eta is time_to_apoapsis - max_circularisation_tta - 10.
    kuniverse:timewarp:cancelwarp().
    set kuniverse:timewarp:mode to "RAILS".
    kuniverse:timewarp:warpto(time:seconds + warp_eta).
    wait time_to_apoapsis - max_circularisation_tta.

    logmsg("starting circularisation").
    until apoapsis - periapsis < 500 {
        local desired_throttle is 1 - scale_in_range(
            time_to_apoapsis,
            min_circularisation_tta,
            max_circularisation_tta
        ).

        if desired_throttle < min_circularisation_burn {
            set desired_throttle to min_circularisation_burn.
        }

        if time_to_apoapsis > 600 {
            set desired_throttle to 1.
            if periapsis > 70000 {
                break.
            }
        }

        lock throttle to desired_throttle.
    }

    lock throttle to 0.0.
    logmsg("circularisation complete").
}

main().
