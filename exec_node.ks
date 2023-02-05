run maneuver.
run common.

function main {
    clearscreen.
    init_logs(20).
    when RCS then {
        set RCS to false.
        if HASNODE {
            maneuver_execute(NEXTNODE).
        } else {
            logmsg("no node exists!", "ERROR").
        }
        return true.
    }
    wait until apoapsis > 1000000.
}

main().
