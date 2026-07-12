#!/bin/bash

fail_counter=0 #Set the number of attempts

# Dynamically identifies interface in column 5
TARGET_INTERFACE=$(ip route show | grep default | awk '{print $5}')
echo "Targeting active interface: $TARGET_INTERFACE"
echo "Press [CTRL] to exit the monitoring process"
echo "-----------------------------------------------------"

# ================================
# MONITORING LAYER 3 CONNECTION
# ================================

# continually checks a response from an intended 100% reliable server
while true; do
	
	# 2 & 4. Ping the server quietly, count to 3, and redirect text away
	ping -q -c 3 -W 2 -I $TARGET_INTERFACE 8.8.8.8 > /dev/null

	# 3. Check the exit status condition
	if [ $? -eq 0 ]; then
		echo "[$(date +%T)]: HEALTHY. Packets are flowing through $TARGET_INTERFACE."
		fail_counter=0
	else
    		echo "[$(date +%T)]: Layer 3 CRITICAL! 'Black Hole' detected on $TARGET_INTERFACE!"
		((fail_counter++))
	fi

	# Check if threshold has been broken
	if [ $fail_counter -ge 4 ]; then
		echo "[$(date +%T)]: Threshhold breached ($fail_counter errors). Initialize phase 1 recovery.."

# =========================
# ERROR MANAGEMENT STEPS
# =========================
	
		# =================================
		#  PHASE 1: DHCP RELEASE / RENEW
		# =================================

		echo "Phase 1: Releasing and renewing IP lease via DHCP.."
		sudo dhclient -r $TARGET_INTERFACE
		sleep 3
		sudo dhclient $TARGET_INTERFACE
		echo "[$(date +%T)]: DHCP lease renewed. Retrying connection test.."

		ping -q -c 2 -W 2 -I $TARGET_INTERFACE 8.8.8.8 > /dev/null
		if [ $? -eq 0 ]; then
			echo "[$(date +%T)]: Phase 1 Successful! Interface restored to HEALTHY."
			fail_counter=0
		else
			# ===================================
                	#  PHASE 2: RESTART INTERFACE PORT
                	# ===================================

			echo "Phase 2: Restart network interface port"
			sudo ip link set $TARGET_INTERFACE down
			echo "$TARGET_INTERFACE shut down, wait 10 seconds"

			sleep 10

			sudo ip link set $TARGET_INTERFACE up
			echo "$TARGET_INTERFACE is up again"
			echo "[$(date +%T)]: Network interface port restarted. Retrying connection test.."
		
			# Confirm if problem is solved
			ping -q -c 2 -W 2 -I $TARGET_INTERFACE 8.8.8.8 > /dev/null
			if [ $? -eq 0 ]; then
				echo "[$(date +%T)]: Phase 2 Successful! Interface restored to HEALTHY."
				fail_counter=0
		
			else
				# ==========================
				# PHASE 3: ROUTE FAILOVER
				# ==========================
				echo "[$(date +%T)]: Phase 2 failed. Initiating phase 3"
				echo "Phase 3: Change Route Failover to Backup interface"
				sudo ip route del default dev $TARGET_INTERFACE
				echo "Removed current route"
				sudo ip route add default via 192.168.1.1 dev enp3s0
				echo "[$(date +%T)]: FAILOVER COMPLETE. System shifted to enp3s0"

				# Break out or pause monitoring to prevent infinite loops
				fail_counter=0
			fi
		fi
	fi	
	
	# Pause for 5 seconds
	sleep 5
done
