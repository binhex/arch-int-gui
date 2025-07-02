#!/usr/bin/dumb-init /bin/bash

# activate virtualenv
source "/usr/local/lib/venv/bin/activate"

# CONFIG_PLACEHOLDER

# create env var for display (note display number must match for tigervnc)
export DISPLAY=:0

# vnc start command
vnc_start="rm -rf /tmp/.X*; Xvnc :0 -depth 24"

# if a password is specified then generate password file using vncpasswd
# else append insecure flag to command line
if [[ -n "${VNC_PASSWORD}" ]]; then

	password_length="${#VNC_PASSWORD}"
	vnc_password_path="${HOME}/.config/tigervnc"
	vnc_password_filepath="${vnc_password_path}/passwd"

	if [[ "${password_length}" -gt 5 ]]; then
		echo "[info] Password length OK, proceeding to set password..."
		mkdir -p "${vnc_password_path}"
		echo -e "${VNC_PASSWORD}\n${VNC_PASSWORD}\nn" | vncpasswd "${vnc_password_filepath}" 1>&- 2>&-
		vnc_start="${vnc_start} -PasswordFile=${vnc_password_filepath}"
	else
		echo "[warn] Password specified is less than 6 characters and thus will be ignored."
		vnc_start="${vnc_start} -SecurityTypes=None"
	fi

else
	vnc_start="${vnc_start} -SecurityTypes=None"
fi

# if defined then set title for the web ui tab
if [[ -n "${WEBPAGE_TITLE}" ]]; then
	vnc_start="${vnc_start} -Desktop='${WEBPAGE_TITLE}'"
fi

# start tigervnc (vnc server) - note the port that it runs on is 5900 + display number (i.e. 5900 + 0 in the case below).
eval "${vnc_start}" &

websockify_start="websockify --web /usr/share/webapps/novnc/ ${WEBUI_PORT} localhost:5900"

if [[ ! -d '/config/certs' ]]; then
	echo "[info] Creating '/config/certs' directory for self-signed certificate..."
	mkdir -p '/config/certs'
fi

if [[ ! -f '/config/certs/self-signed.key' ]] || [[ ! -f '/config/certs/self-signed.crt' ]]; then
	echo "[info] Generating self-signed certificate for websockify..."
	# generate self signed certificate for websockify (required for novnc)
	openssl req \
		-x509 \
		-newkey 'rsa:4096' \
		-sha256 \
		-days '3650' \
		-nodes \
		-keyout '/config/certs/self-signed.key' \
		-out '/config/certs/self-signed.crt' \
		-subj '/CN=localhost'
else
	echo "[info] Self-signed certificate already exists, skipping generation..."
fi

if [[ -n "${HTTPS_CERT_PATH}" ]] && [[ -n "${HTTPS_KEY_PATH}" ]]; then
	echo "[info] Using custom certificate and key for websockify..."
	websockify_start="${websockify_start} --cert=${HTTPS_CERT_PATH} --key=${HTTPS_KEY_PATH}"
else
	echo "[info] Using self-signed certificate for websockify..."
	websockify_start="${websockify_start} --cert=/config/certs/self-signed.crt --key=/config/certs/self-signed.key"
fi

# starts novnc (web vnc client) - note also starts websockify to connect novnc to tigervnc server
# websockify is installed via pip in pyenv and is on the path, thus no path specified
eval "${websockify_start}" &

# start dbus (required for libreoffice menus to be viewable when started via openbox right click menu) and launch openbox (window manager)
dbus-launch openbox-session &

# run xcomppmgr (required for transparency support for tint2)
sleep 2s; xcompmgr &

# run tint2 (creates task bar) with custom theme (in while loop to restart on process end)
sleep 2s; source /usr/local/bin/tint2.sh &

# STARTCMD_PLACEHOLDER

# foreground blocking process to keep container running
sleep infinity
