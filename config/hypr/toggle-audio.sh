#!/bin/bash

# Noms des périphériques
HEADSET="alsa_output.usb-HP__Inc_HyperX_Cloud_III_000000000000-00.analog-stereo"
SPEAKERS="alsa_output.pci-0000_0b_00.4.analog-stereo"

# Récupère le périphérique actuel
CURRENT=$(pactl get-default-sink)

if [ "$CURRENT" = "$HEADSET" ]; then
	pactl set-default-sink "$SPEAKERS"
else
	pactl set-default-sink "$HEADSET"
fi

# Déplace aussi les flux audio actifs vers le nouveau périphérique
NEW=$(pactl get-default-sink)
for INPUT in $(pactl list short sink-inputs | awk '{print $1}'); do
	pactl move-sink-input $INPUT $NEW
done
