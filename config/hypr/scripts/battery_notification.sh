#!/bin/bash

# Define thresholds for battery notifications
LOW_THRESHOLD=20
CRITICAL_THRESHOLD=5
CHARGED_THRESHOLD=95

# Get current battery percentage and charging status
BATTERY_PERCENTAGE=$(cat /sys/class/power_supply/BAT0/capacity)
STATUS=$(cat /sys/class/power_supply/BAT0/status)

# Function to send a notification
send_notification() {
	local title="$1"
	local message="$2"
	local icon="$3"
	dunstify -t 5000 -u critical -i "$icon" "$title" "$message"
}

# Check battery status and send notifications
if ((BATTERY_PERCENTAGE <= LOW_THRESHOLD && STATUS != "Charging")); then
	send_notification "Low Battery" "Your battery is below $LOW_THRESHOLD%. Please connect charger." "battery-caution"
elif ((BATTERY_PERCENTAGE <= CRITICAL_THRESHOLD && STATUS != "Charging")); then
	send_notification "Critical Battery" "Your battery is critically low! Connect charger immediately!" "battery-alert"
elif [[ "$STATUS" == "Full" ]]; then
	send_notification "Battery Fully Charged" "Your battery is fully charged." "battery-full"
fi
