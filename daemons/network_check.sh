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


# Method sends packages towards the designated ip address
ping_target()
{
	local interface=$1
	local target_ip=$2
	local count=$3

	ping -q -c "$count" -W 2 -I "$interface" "$target_ip" > /dev/null 2>&1
	return $?
}


# Checks that it is actually a functioning interface
check_interface()
{
        if [ -z "$TARGET_INTERFACE" ]; then
                echo "[CRITICAL] No default route interface detected! Exiting.."
                exit 1
        fi

}


# ===================
# RECOVERY METHODS
# ===================


# Refresh a potentially broken IP address
recover_dhcp()
{
	local interface=$1
	echo "[$(date +%T)]: Phase 1 -> Releasing and renewing IP lease via DHCP on $interface.."
	sudo dhclient -r "$interface"
	sleep 3
	sudo dhclient "$interface"
	echo "[$(date +%T)]: DHCP lease renewed. Retrying connectoin test.."
}


# Restarts the network interface port
recover_interface_flap()
{
	local interface=$1
	echo "[$(date +%T)]: Phase 2-> Toggling interface port state (shutdown / no shutdown): $interface"
	sudo /usr/sbin/ip link set "$interface" down
	echo "$interface is SHUTDOWN. Waiting 10 seconds..."
	sleep 10
	sudo /usr/sbin/ip link set "$interface" up
	echo "$interface is UP (no shutdown). Retrying connection test..."
}


# Changes the network interface port to the backup/default interface (must be manually configured)
recover_route_failover()
{
	local primary_if=$1
	local backup_if="enp3s0" # ("ip link show" to find available network interface ports on your device)
	local backup_gw="192.168.1.1" # default gateway
	
	echo "[$(date +%T)]: Phase 3 -> Changing Route Failover to Backup interface..."
	sudo /usr/sbin/ip link set "$primary_if" down
	sudo /usr/sbin/ip route del default dev "$primary_if" > /dev/null 2>&1
	sudo /usr/sbin/ip route add default via "$backup_gw" dev "$backup_if"
	echo "[$(date +%T)]: FAILOVER COMPLETE. System shifted routing engine to $backup_if"
}

# ==============
# MAIN SCRIPT
# ==============

main()
{
	# Begins by setting the interface to ping a reliable server, this case it is set to googles.
	TARGET_INTERFACE=$(get_active_interface)

	# Checks that there is a valid interface
	check_interface

	# If yes then we begin the monitoring process
	echo "Targeting active interface: $TARGET_INTERFACE"
	echo "Press [CTRL+C] to exit the monitoring process"
	echo "--------------------------------------------------"

	#continually checks a response from an intended 100% reliable server
	while true; do

		# Sends a ping
		if ping_target "$TARGET_INTERFACE" "8.8.8.8" 3; then
			echo "[$(date +%T)]: HEALTHY. Packets are flowing through $TARGET_INTERFACE."
			fail_counter=0
		else
			# Ping failed
			echo "[$(date +%T)]: Layer 3 CRITICAL! 'Back Hole' detected on $TARGET_INTERFACE!"
			((fail_counter++))
		fi

		# Escalation Engine triggers when error threshold is breached
		if ((fail_counter >= 4)); then
			echo "[$(date +%T)]: Connection is lost! Threshold reached ($fail_counter errors). Initializing recovery sequence..."
	    
			# -----------------------------   phase 1: Flush IP   ------------------------
			recover_dhcp "$TARGET_INTERFACE"
			if ping_target "$TARGET_INTERFACE" "8.8.8.8" 2; then
				echo "[$(date +%T)]: Phase 1 Successful! Interface restored to HEALTHY."

				# Resets counter
				fail_counter=0
			else
				# -----------------------------   phase 2: Restart Interface   ------------------------
				echo "[$(date +%T)]: Phase 1 failed. Escalating to Phase 2..."
				recover_interface_flap "$TARGET_INTERFACE"
				
				if ping_target "$TARGET_INTERFACE" "8.8.8.8" 2; then
					echo "[$(date +%T)]: Phase 2 Successful! Interface restored to HEALTHY."
					
					fail_counter=0
				else
					# -----------------------------   phase 3: Change Interface   ------------------------
					echo "[$(date +%T)]: Phase 2 failed. Escalating to structural Phase 3 failover..."
					recover_route_failover "$TARGET_INTERFACE"
					TARGET_INTERFACE="enp3s0"
					
					fail_counter=0
				fi
			fi
		fi
	
	sleep 5
	done
}


# ==============
# THE TRIGGER
# ==============
main
