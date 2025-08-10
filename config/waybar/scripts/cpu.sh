#!/bin/bash
TEMP=$(sensors | grep "Tctl" | awk '{print $2}' | sed 's/+//;s/°C//')
echo "${TEMP}°C"

