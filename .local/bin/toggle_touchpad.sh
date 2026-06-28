#!/bin/bash

touchpad="/sys/bus/i2c/devices/i2c-MSNB0001:00/0018:06CB:CEBD.0001/input/input14/inhibited"
state="$(<"$touchpad")"

if [[ "$state" == "0" ]]; then
    echo "1" | sudo tee "$touchpad" > /dev/null
    echo "Touchpad disabled"
else
    echo "0" | sudo tee "$touchpad" > /dev/null
    echo "Touchpad enabled"
fi
