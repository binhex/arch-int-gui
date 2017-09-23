#!/bin/bash

# create env var for display (note display number must match for tigervnc)
export DISPLAY=:0

# start tigervnc (vnc server) - note the port that it runs on is 5900 + display number (i.e. 5900 + 0 in the case below).
rm -rf /tmp/.X*; vncserver :0 -depth 24 -SecurityTypes=None

# starts novnc (web vnc client) - note the launch.sh also starts websockify to connect novnc to tigervnc server
nohup /usr/share/novnc/utils/launch.sh --listen 6080 --vnc localhost:5900 &

# run tint2 (creates task bar) with custom theme
nohup tint2 -c /home/nobody/tint2/tint2rc &

# copy custom openbox theme
if [[ ! -d /usr/share/themes/Shiki-Brave ]]; then
	cp -r /home/nobody/openbox/Shiki-Brave /usr/share/themes/
fi

# copy default openbox menu config file to home directory (required to use obmenu)
if [[ ! -f /home/nobody/.config/openbox/menu.xml ]]; then

	mkdir -p /home/nobody/.config/openbox
	cp /etc/xdg/openbox/menu.xml /home/nobody/.config/openbox/menu.xml

	# edit openbox menu items to add in application
fi

# start openbox (window manager)
nohup openbox-session &

# run application (specified via env var)
xfce4-terminal
"${APP_COMMAND}"
