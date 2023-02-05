run common.

function maneuver_execute {
    parameter mnv.

    logmsg("warping to node (" + maneuver_turn_eta(mnv) + "s)").
    kuniverse:timewarp:cancelwarp().
    set kuniverse:timewarp:mode to "RAILS".
    kuniverse:timewarp:warpto(time:seconds + maneuver_turn_eta(mnv)).

    set SAS to false.
    lock steering to mnv:burnvector.
    wait maneuver_start_eta(mnv).
    logmsg("starting burn (burn time: " + maneuver_burn_time(mnv) + "s)").
    maneuver_perform_burn(mnv).
    logmsg("maneuver complete!").

    unlock steering.
    remove mnv.
}

function maneuver_is_complete {
    parameter original_vector, current_vector.
    return vang(originalVector, currentVector) > 90.
}

function maneuver_burn_time {
    parameter mnv.

    local dV is mnv:deltaV:mag.
    local g0 is 9.80665.
    local isp is current_isp().

    local mf is ship:mass / constant():e^(dV / (isp * g0)).
    local fuelFlow is ship:maxThrust / (isp * g0).
    local t is (ship:mass - mf) / fuelFlow.

    return t.
}

function maneuver_start_eta {
    parameter mnv.
    return mnv:eta - (maneuver_burn_time(mnv) / 2).
}

function maneuver_turn_eta {
    parameter mnv.
    return maneuver_start_eta(mnv) - 10.
}

function maneuver_perform_burn {
    parameter mnv.
    local original_vector is mnv:burnvector.
    lock throttle to 1.
    wait maneuver_burn_time(mnv).
    lock throttle to 0.
}
