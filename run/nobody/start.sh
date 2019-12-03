#!/bin/bash

# config nemo
####

function symlink_home_dir {

	folder="${1}"

	# if container folder exists then rename and use as default restore
	if [[ -d "/home/nobody/${folder}" && ! -L "/home/nobody/${folder}" ]]; then
		echo "[info] /home/nobody/${folder} folder storing user general settings already exists, renaming..."
		mv "/home/nobody/${folder}" "/home/nobody/${folder}-backup"
	fi

	# if /config/home/${folder} doesnt exist then restore from backup (see note above)
	if [[ ! -d "/config/home/${folder}" ]]; then
		if [[ -d "/home/nobody/${folder}-backup" ]]; then
			echo "[info] /config/home/${folder} folder storing user general settings does not exist, copying defaults..."
			mkdir -p "/config/home" ; cp -R "/home/nobody/${folder}-backup" "/config/home/${folder}"
		fi
	else
		echo "[info] /config/home/${folder} folder storing user general settings already exists, skipping copy"
	fi

	# create soft link to /home/nobody/${folder} storing nemo general settings
	echo "[info] Creating soft link from /config/home/${folder} to /home/nobody/${folder}..."
	mkdir -p "/config/home/${folder}" ; rm -rf "/home/nobody/${folder}" ; ln -s "/config/home/${folder}/" "/home/nobody/"

}

# call function to create symlinks
symlink_home_dir ".config"
symlink_home_dir ".local"
symlink_home_dir ".themes"
symlink_home_dir ".icons"
symlink_home_dir "openbox"

# CONFIG_PLACEHOLDER

# create env var for display (note display number must match for tigervnc)
export DISPLAY=:0

# vnc start command
vnc_start="rm -rf /tmp/.X*; vncserver :0 -depth 24"

# if a password is specified then generate password file
# else append insecure flag to command line
if [[ -n "${VNC_PASSWORD}" ]]; then
	password_length="${#VNC_PASSWORD}"
	if [[ "${password_length}" -gt 5 ]]; then
		echo "[info] Password length OK, proceeding to set password..."
		echo -e "${VNC_PASSWORD}\n${VNC_PASSWORD}\nn" | vncpasswd 1>&- 2>&-
	else
		echo "[warn] Password specified is less than 6 characters and thus will be ignored."
		vnc_start="${vnc_start} -SecurityTypes=None"
	fi
else
	vnc_start="${vnc_start} -SecurityTypes=None"
fi

# start tigervnc (vnc server) - note the port that it runs on is 5900 + display number (i.e. 5900 + 0 in the case below).
eval "${vnc_start}"

# if defined then set title for the web ui tab
if [[ -n "${WEBPAGE_TITLE}" ]]; then
	vncconfig -set desktop="${WEBPAGE_TITLE}"
fi

# starts novnc (web vnc client) - note also starts websockify to connect novnc to tigervnc server
/usr/sbin/websockify --web /usr/share/webapps/novnc/ 6080 localhost:5900 &

# start dbus (required for libreoffice menus to be viewable when started via openbox right click menu) and launch openbox (window manager)
dbus-launch openbox-session &

# run xcomppmgr (required for transparency support for tint2)
sleep 2s; xcompmgr &

# run tint2 (creates task bar) with custom theme (in while loop to restart on process end)
sleep 2s; source /home/nobody/tint2.sh &

# STARTCMD_PLACEHOLDER

# run cat in foreground, this prevents start.sh script from exiting and ending all background processes
cat
