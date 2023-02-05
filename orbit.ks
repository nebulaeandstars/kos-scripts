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
        return min(90 - vang(ship:up:forevector, prograde_vector), 80).
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

function circ_score {
    parameter burn.
    local mnv is node(burn[0], burn[1], burn[2], burn[3]).
    add mnv.
    local score is 0 - mnv:orbit:eccentricity.
    remove mnv.
    return score.
}

function circularize {
    logmsg("waiting to exit atmosphere").
    lock steering to prograde.
    wait until ship:altitude > 70000.
    kuniverse:timewarp:cancelwarp().

    logmsg("creating circularisation node").
    local mnv is maneuver_find(circ_score@, list(true, false, false, true)).
    add mnv.
    maneuver_execute(mnv).
}

main().
