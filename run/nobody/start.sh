#!/bin/bash

# create env var for display (note display number must match for tigervnc)
export DISPLAY=:0

# start tigervnc (vnc server) - note the port that it runs on is 5900 + display number (i.e. 5900 + 0 in the case below).
rm -rf /tmp/.X*; vncserver :0 -depth 24 -SecurityTypes=None

# starts novnc (web vnc client) - note the launch.sh also starts websockify to connect novnc to tigervnc server
/usr/share/novnc/utils/launch.sh --listen 6080 --vnc localhost:5900 &

# start dbus (required for libreoffice menus to be viewable when started via openbox right click menu) and launch openbox (window manager)
dbus-launch openbox-session &

# run tint2 (creates task bar) with custom theme
sleep 2s; tint2 -c /home/nobody/tint2/theme/tint2rc &

# run xcomppmgr (required for transparency support for tint2)
sleep 2s; xcompmgr &

# run application (specified via env var)
# STARTCMD_PLACEHOLDER
