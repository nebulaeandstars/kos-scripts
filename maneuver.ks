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

    // wait until vang(original_vector, mnv:burnvector) > 45.
    // wait maneuver_burn_time(mnv).

    lock twr to max((ship:availablethrust / ship:mass), 0.0000001).
    lock limited_thrust to min(mnv:burnvector:mag / twr, 1).
    lock throttle to max(limited_thrust, 0.005).
    wait until vang(original_vector, mnv:burnvector) > 90.

    lock throttle to 0.
}

function maneuver_improve {
    parameter burn, score_function, step_size is 1.
    parameter mask is list(true, true, true, true).

    local candidates is list().

    local i is 0.
    until i = burn:length {
        if mask[i] {
            local c1 is burn:copy().
            local c2 is burn:copy().
            set c1[i] to c1[i] + step_size.
            set c2[i] to c2[i] - step_size.
            candidates:add(c1).
            candidates:add(c2).
        }
        set i to i + 1.
    }

    local best_burn is burn.
    local best_score is score_function(burn).

    for candidate in candidates {
        local score is score_function(candidate).
        if score > best_score {
            set best_burn to candidate.
            set best_score to score.
        }
    }

    return list(best_burn, best_score).
}

function _maneuver_improve_multi {
    parameter burn, score_function, step_size.
    parameter mask is list(true, true, true, true).

    local old_score is score_function(burn).
    until false {
        local improvement is maneuver_improve(
            burn, score_function, step_size, mask
        ).
        local new_burn is improvement[0].
        local score is improvement[1].

        if score > old_score {
            set burn to new_burn.
            set old_score to score.
        } else {
            break.
        }
    }

    return burn.
}

function maneuver_find {
    parameter score_function.
    parameter mask is list(true, true, true, true).

    local burn is list(time:seconds + 30, 0, 0, 0).

    for step_size in list(300, 100, 10, 1, 0.1) {
        set burn to _maneuver_improve_multi(
            burn, score_function@, step_size, mask
        ).
    }

    local mnv is node(burn[0], burn[1], burn[2], burn[3]).
    return mnv.
}
