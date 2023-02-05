stage.

// Throttle up when below target altitude, throttle down when above
// target altitude, trying to hover:

until false {
    wait until RCS.

    local target_alt is ship:altitude.

    set HOVERPID to PIDLOOP(
        1,  // adjust throttle 0.1 per 5m in error from desired altitude.
        0, // adjust throttle 0.1 per second spent at 1m error in altitude.
        1,  // adjust throttle 0.1 per 3 m/s speed toward desired altitude.
        0,   // min possible throttle is zero.
        1    // max possible throttle is one.
      ).
    set HOVERPID:SETPOINT to target_alt.
    set mythrot to 0.
    lock throttle to mythrot.

    until not RCS {
      set mythrot to HOVERPID:UPDATE(TIME:SECONDS, alt:radar).
      wait 0.
    }

    unlock throttle.
}
