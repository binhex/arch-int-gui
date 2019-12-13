#!/bin/bash

# run in infinite loop to restart process if it ends
while true; do

	tint2_running="false"

	# check if tint2 is running
	if ! pgrep -x "/usr/bin/tint2" > /dev/null; then

			echo "[info] tint2 not running"

	else

			tint2_running="true"

	fi

	if [[ "${tint2_running}" == "false" ]];then

			# run tint2 (creates task bar) with custom theme
			/usr/bin/tint2 -c /home/nobody/.config/tint2/theme/tint2rc

	fi

	sleep 10s

done
