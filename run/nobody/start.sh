#!/bin/bash

# create env var for display (note display number must match for tigervnc)
export DISPLAY=:0

# start tigervnc (vnc server) - note the port that it runs on is 5900 + display number (i.e. 5900 + 0 in the case below).
rm -rf /tmp/.X*; vncserver :0 -depth 24 -SecurityTypes=None

# starts novnc (web vnc client) - note the launch.sh also starts websockify to connect novnc to tigervnc server
nohup /usr/share/novnc/utils/launch.sh --listen 6080 --vnc localhost:5900 &

# run tint2 (creates task bar) with custom theme
nohup tint2 -c /home/nobody/tint2/tint2rc &

# start openbox (window manager)
nohup openbox-session &

# run application (specified via env var)
"${APP_COMMAND}"
