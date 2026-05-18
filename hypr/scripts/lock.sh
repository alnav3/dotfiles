#!/usr/bin/env bash
# Universal lock screen script that uses machine-specific lockers
# For surface: gtklock
# For all others: noctalia-shell

HOSTNAME=$(hostname)

if [ "$HOSTNAME" = "surface" ]; then
    exec gtklock
else
    exec noctalia-shell ipc call lockScreen lock
fi
