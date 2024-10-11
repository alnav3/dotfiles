#!/run/current-system/sw/bin/zsh

# Obtener el status de la batería
status=$(cat /sys/class/power_supply/BAT1/status)

# Verificar el status y mostrar el mensaje correspondiente
if [ "$status" == "Charging" ]; then
    hyprctl keyword monitor "eDP-1, disable"
else
    hyprlock & hyprctl keyword monitor "eDP-1, disable"
fi

