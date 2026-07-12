#!/bin/bash

# ====================
# GLOBAL VARIABLES
# ====================

fail_counter=0 #Set the number of attempts
TARGET_INTERFACE=""


# =====================
# Monitoring Methods
# =====================

# Dynamically identifies interface in column 5
get_active_interface()
{
	ip route show | grep default | awk '{print $5}'
}


ping_target()
{
	local interface=$1
	local target_ip=$2
	local count=$3

	ping -q -c "$count" -W 2 -I "$interface" "$target_ip" > /dev/null 2>&1
	return $?
}


# ==============
# MAIN SCRIPT
# ==============

main()
{
	TARGET_INTERFACE=$(get_active_interface)

	if [ -z "$TARGET_INTERFACE" ]; then
		echo "[CRITICAL] No default route interface detected! Exiting.."
		exit 1
	fi

	echo "Targeting active interface: $TARGET_INTERFACE"
	echo "Press [CTRL+C] to exit the monitoring process"
	echo "--------------------------------------------------"

	#continually checks a response from an intended 100% reliable server
	while true; do
		if ping_target "$TARGET_INTERFACE" "8.8.8.8" 3; then
			echo "[$(date +%T)]: HEALTHY. Packets are flowing through $TARGET_INTERFACE."
			fail_counter=0
		else
			echo "[$(date +%T)]: Layer 3 CRITICAL! 'Back Hole' detected on $TARGET_INTERFACE!"
			((fail_counter++))
		fi

		if ((fail_counter == 4)); then
			echo "Connection is lost"
		fi
		sleep 5
	done
}


# ==============
# THE TRIGGER
# ==============
main
