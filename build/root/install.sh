#!/bin/bash

# exit script if return code != 0
set -e

# app name from buildx arg, used in healthcheck to identify app and monitor correct process
APPNAME="${1}"
shift

# release tag name from buildx arg, stripped of build ver using string manipulation
RELEASETAG="${1}"
shift

# target arch from buildx arg
TARGETARCH="${1}"
shift

if [[ -z "${APPNAME}" ]]; then
	echo "[warn] App name from build arg is empty, exiting script..."
	exit 1
fi

if [[ -z "${RELEASETAG}" ]]; then
	echo "[warn] Release tag name from build arg is empty, exiting script..."
	exit 1
fi

if [[ -z "${TARGETARCH}" ]]; then
	echo "[warn] Target architecture name from build arg is empty, exiting script..."
	exit 1
fi

# note do NOT write APPNAME and RELEASETAG to file, as this is an intermediate image

# ensure we have the latest builds scripts
refresh.sh

# pacman packages
####

# define pacman packages
pacman_packages="ttf-dejavu xorg-fonts-misc terminus-font ttf-dejavu xfce4-terminal tint2 xorg-server-xvfb openbox obconf-qt lxappearance xcompmgr cantarell-fonts firefox openssl"

# install compiled packages using pacman
if [[ -n "${pacman_packages}" ]]; then
	# arm64 currently targetting aor not archive, so we need to update the system first
	if [[ "${TARGETARCH}" == "arm64" ]]; then
		pacman -Syu --noconfirm
	fi
	pacman -S --needed $pacman_packages --noconfirm
fi

# aur packages
####

# define aur packages
aur_packages="obmenu2-git ttf-font-awesome novnc hsetroot"

# call aur install script (arch user repo)
source aur.sh

# python
####

python.sh --create-virtualenv 'yes' --create-pyenv 'yes' --pyenv-version '3.12' --pip-packages 'pyxdg numpy cffi websockify'

# # custom
# ####

# tigervnc 1.14.0 is causing corruption of images and general x-windows issues, revert to older version until this is resolved
curl -o /tmp/tiger.zst -L https://archive.archlinux.org/packages/t/tigervnc/tigervnc-1.13.1-5-x86_64.pkg.tar.zst
pacman -U /tmp/tiger.zst --noconfirm

# llvm-libs v19.1.7-2 is causing connectivity issues with tigervnc/novnc, this is a revert to older version until this is resolved
curl -o /tmp/llvm-libs.tar.zst -L https://archive.archlinux.org/packages/l/llvm-libs/llvm-libs-19.1.7-1-x86_64.pkg.tar.zst
pacman -U /tmp/llvm-libs.tar.zst --noconfirm

# add additional excludes to prevent accidental updates
sed -i -e 's~IgnorePkg.*~IgnorePkg = filesystem tigervnc llvm-libs~g' '/etc/pacman.conf'

# config - look and feel
####

# download gtk icon theme (dark)
rcurl.sh -o "/tmp/gtk-icon.zip" "https://github.com/binhex/themes/raw/master/gtk/icon-themes/BLACK-Ice-Numix-FLAT_1.4.1.zip"

# unpack gtk icon theme to home dir
unzip -d "/home/nobody/.icons/" "/tmp/gtk-icon.zip"

# download gtk widget theme (light)
rcurl.sh -o "/tmp/gtk-widget-light.zip" "https://github.com/binhex/themes/raw/master/gtk/widget-theme/Ultimate-Maia-Blue-light-v3.34.zip"

# download gtk widget theme (dark)
rcurl.sh -o "/tmp/gtk-widget-dark.zip" "https://github.com/binhex/themes/raw/master/gtk/widget-theme/Ultimate-Maia-Blue-dark-v3.34.zip"

# unpack gtk widget theme to home dir
unzip -d "/home/nobody/.themes/" "/tmp/gtk-widget-light.zip"
unzip -d "/home/nobody/.themes/" "/tmp/gtk-widget-dark.zip"

# download openbox theme (dark and light)
rcurl.sh -o "/tmp/openbox-theme.tar.gz" "https://github.com/binhex/themes/raw/master/openbox/Adwaita-Revisited-for-Openbox.tar.gz"

# unpack openbox theme to home dir
tar -xvf "/tmp/openbox-theme.tar.gz" -C "/home/nobody/.themes/"

# copy gtk-2.0 settings to home directory (sets gtk widget and icons)
cp /home/nobody/.build/gtk/config/.gtkrc-2.0 /home/nobody/.gtkrc-2.0

# copy gtk-3.0 settings to home directory (sets gtk widget and icons)
mkdir -p /home/nobody/.config/gtk-3.0
cp /home/nobody/.build/gtk/config/settings.ini /home/nobody/.config/gtk-3.0/settings.ini

# copy settings to home directory (sets openbox theme and fonts)
mkdir -p /home/nobody/.config/openbox
cp /home/nobody/.build/openbox/config/rc.xml /home/nobody/.config/openbox/rc.xml

# copy settings to home directory (sets tint2 theme)
mkdir -p /home/nobody/.config/tint2/theme
cp /home/nobody/.build/tint2/theme/tint2rc /home/nobody/.config/tint2/theme/tint2rc

# config - novnc
####

# replace all novnc normal (used for bookmarks and favorites) icon sizes with fixed 16x16 icon
sed -i -E 's~\s+<link rel="icon".*~    <link rel="icon" href="app/images/icons/novnc-16x16.png">~g' "/usr/share/webapps/novnc/vnc.html"

# replace all novnc home screen (used for tablets etc) icon sizes with fixed 16x16 icon
sed -i -E 's~\s+<link rel="apple-touch-icon".*~    <link rel="apple-touch-icon" sizes="16x16" type="image/png" href="app/images/icons/novnc-16x16.png">~g' "/usr/share/webapps/novnc/vnc.html"

# create openbox menu items to add in application
cat <<'EOF' > /home/nobody/.config/openbox/menu.xml
<?xml version="1.0" encoding="UTF-8"?>

<openbox_menu xmlns="http://openbox.org/3.4/menu">

<menu id="root-menu" label="Openbox 3">
  <separator label="Applications" />
    <item label="Xfce Terminal">
    <action name="Execute">
      <command>xfce4-terminal</command>
      <startupnotify>
        <enabled>yes</enabled>
      </startupnotify>
    </action>
    </item>
    <item label="Firefox">
    <action name="Execute">
      <command>firefox</command>
      <startupnotify>
        <enabled>yes</enabled>
      </startupnotify>
    </action>
    </item>
    <!-- APPLICATIONS_PLACEHOLDER -->
  <separator label="Utils" />
    <item label="Openbox config">
    <action name="Execute">
      <command>obconf-qt</command>
      <startupnotify>
        <enabled>yes</enabled>
      </startupnotify>
    </action>
    </item>
    <item label="Openbox menu">
    <action name="Execute">
      <command>obmenu</command>
      <startupnotify>
        <enabled>yes</enabled>
      </startupnotify>
    </action>
    </item>
    <item label="GTK theme">
    <action name="Execute">
      <command>lxappearance</command>
      <startupnotify>
        <enabled>yes</enabled>
      </startupnotify>
    </action>
    </item>
    <item label="tint2 GUI Editor">
    <action name="Execute">
      <command>tint2conf</command>
      <startupnotify>
        <enabled>yes</enabled>
      </startupnotify>
    </action>
    </item>
    <!-- UTILS_PLACEHOLDER -->
</menu>

</openbox_menu>
EOF

# set a background color for openbox (slightly lighter than default to contrast taskbar)
cat <<'EOF' > /home/nobody/.config/openbox/autostart
BG=""
if which hsetroot >/dev/null 2>/dev/null; then
  BG=hsetroot
elif which esetroot >/dev/null 2>/dev/null; then
  BG=esetroot
elif which xsetroot >/dev/null 2>/dev/null; then
  BG=xsetroot
fi
test -z $BG || $BG -solid "#4d4d4d"
EOF

# env vars
####

cat <<'EOF' > /tmp/envvars_heredoc
export WEBPAGE_TITLE=$(echo "${WEBPAGE_TITLE}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${WEBPAGE_TITLE}" ]]; then
	echo "[info] WEBPAGE_TITLE defined as '${WEBPAGE_TITLE}'" | ts '%Y-%m-%d %H:%M:%.S'
fi

export VNC_PASSWORD=$(echo "${VNC_PASSWORD}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${VNC_PASSWORD}" ]]; then
	echo "[info] VNC_PASSWORD defined as '${VNC_PASSWORD}'" | ts '%Y-%m-%d %H:%M:%.S'
fi

export HTTPS_CERT_PATH=$(echo "${HTTPS_CERT_PATH}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${HTTPS_CERT_PATH}" ]]; then
	echo "[info] HTTPS_CERT_PATH defined as '${HTTPS_CERT_PATH}'" | ts '%Y-%m-%d %H:%M:%.S'
fi

export HTTPS_KEY_PATH=$(echo "${HTTPS_KEY_PATH}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${HTTPS_KEY_PATH}" ]]; then
	echo "[info] HTTPS_KEY_PATH defined as '${HTTPS_KEY_PATH}'" | ts '%Y-%m-%d %H:%M:%.S'
fi

export ENABLE_STARTUP_SCRIPTS=$(echo "${ENABLE_STARTUP_SCRIPTS}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${ENABLE_STARTUP_SCRIPTS}" ]]; then
	echo "[info] ENABLE_STARTUP_SCRIPTS defined as '${ENABLE_STARTUP_SCRIPTS}'" | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[info] ENABLE_STARTUP_SCRIPTS not defined,(via -e ENABLE_STARTUP_SCRIPTS), defaulting to 'no'" | ts '%Y-%m-%d %H:%M:%.S'
	export ENABLE_STARTUP_SCRIPTS="no"
fi

# ENVVARS_PLACEHOLDER
EOF

# replace env vars placeholder string with contents of file (here doc)
# note we need to -reinsert the placeholder as other gui docker images
# may require additonal env vars i.e. krusader
sed -i '/# ENVVARS_PLACEHOLDER/{
	s/# ENVVARS_PLACEHOLDER//g
	r /tmp/envvars_heredoc
}' /usr/bin/init.sh
rm /tmp/envvars_heredoc

# config
####

cat <<'EOF' > /tmp/config_heredoc

if [[ "${ENABLE_STARTUP_SCRIPTS}" == "yes" ]]; then

	# define path to scripts
	base_path="/config/home"
  user_script_src_path="/home/nobody/.build/scripts/example-startup-script.sh"
	user_script_dst_path="${base_path}/scripts"

	mkdir -p "${user_script_dst_path}"

	# copy example startup script
	# note slence stdout/stderr and ensure exit code 0 due to src file may not exist (symlink)
	if [[ ! -f "${user_script_dst_path}/example-startup-script.sh" ]]; then
		cp "${user_script_src_path}" "${user_script_dst_path}/example-startup-script.sh" 2> /dev/null || true
	fi

	# find any scripts located in "${user_script_dst_path}"
	user_scripts=$(find "${user_script_dst_path}" -maxdepth 1 -name '*sh' 2> '/dev/null' | xargs)

	# loop over scripts, make executable and source
	for i in ${user_scripts}; do
		chmod +x "${i}"
		echo "[info] Executing user script '${i}' in the background" | ts '%Y-%m-%d %H:%M:%.S'
		source "${i}" &
	done

	# change ownership as we are running as root
	chown -R nobody:users "${base_path}"

fi

# call symlink function from utils.sh
symlink --src-path '/config/home' --dst-path '/home/nobody' --link-type 'softlink'

EOF

# replace config placeholder string with contents of file (here doc)
sed -i '/# CONFIG_PLACEHOLDER/{
    s/# CONFIG_PLACEHOLDER//g
    r /tmp/config_heredoc
}' /usr/bin/init.sh
rm /tmp/config_heredoc

# container perms
####

# define comma separated list of paths
install_paths="/home/nobody"

# split comma separated string into list for install paths
IFS=',' read -ra install_paths_list <<< "${install_paths}"

# process install paths in the list
for i in "${install_paths_list[@]}"; do

	# confirm path(s) exist, if not then exit
	if [[ ! -d "${i}" ]]; then
		echo "[crit] Path '${i}' does not exist, exiting build process..." ; exit 1
	fi

done

# convert comma separated string of install paths to space separated, required for chmod/chown processing
install_paths=$(echo "${install_paths}" | tr ',' ' ')

# set permissions for container during build - Do NOT double quote variable for install_paths otherwise this will wrap space separated paths as a single string
chmod -R 775 "${install_paths}"

# set ownership back to user 'nobody', required after copying of configs and themes
chown -R nobody:users "${install_paths}"

# cleanup
cleanup.sh
