**Application**

[Arch Linux](https://www.archlinux.org/)

**Description**

Arch Linux is an independently developed, i686/x86-64 general purpose GNU/Linux distribution versatile enough to suit any role. Development focuses on simplicity, minimalism, and code elegance.

**Build notes**

This is an intermediate Docker image which is used as a base image for other Docker images which require a GUI's.

**Access via web interface (noVNC)**

`http://<host ip>:<host port>/vnc.html?resize=remote&host=<host ip>&port=<host port>&&autoconnect=1`

e.g.:-

`http://192.168.1.10:6080/vnc.html?resize=remote&host=192.168.1.10&port=6080&&autoconnect=1`

**Access via VNC client**

`<host ip>::<host port>`

e.g.:-

`192.168.1.10::5900`

**Notes**

This image includes dumb-init (https://github.com/Yelp/dumb-init) to ensure a clean shutdown and to correctly reap processes, Supervisor (http://supervisord.org/) is also installed to help monitor and run child processes.

If you appreciate my work, then please consider buying me a beer  :D

[![PayPal donation](https://www.paypal.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=MM5E27UX6AUU4)

[Documentation](https://github.com/binhex/documentation) | [Support Forum](http://forums.unraid.net/index.php?topic=45811.0)