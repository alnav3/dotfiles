#!/usr/bin/env bash

status=$(cat /sys/class/power_supply/ACAD/online)
if [ "$status" -eq 1 ]; then
else
    systemctl suspend
fi

