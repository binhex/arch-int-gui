#!/bin/bash

# exit script if return code != 0
set -e

# set user "nobody" home directory (issue with pycharm) - hack please remove once new base built.
usermod -d /home/nobody nobody

# build scripts
####

# download build scripts from github
curl --connect-timeout 5 --max-time 600 --retry 5 --retry-delay 0 --retry-max-time 60 -o /tmp/scripts-master.zip -L https://github.com/binhex/scripts/archive/master.zip

# unzip build scripts
unzip /tmp/scripts-master.zip -d /tmp

# move shell scripts to /root
mv /tmp/scripts-master/shell/arch/docker/*.sh /usr/local/bin/

# pacman packages
####

# define pacman packages
pacman_packages="ttf-dejavu xorg-fonts-misc terminus-font ttf-dejavu xfce4-terminal tint2 xorg-server-xvfb tigervnc openbox obconf python2-xdg coreutils lxappearance xcompmgr cantarell-fonts python-pip python-numpy"

# install compiled packages using pacman
if [[ ! -z "${pacman_packages}" ]]; then
	pacman -S --needed $pacman_packages --noconfirm
fi

# aur packages
####

# define aur packages
aur_packages="obmenu ttf-font-awesome novnc hsetroot"

# call aur install script (arch user repo)
source aur.sh

# config - novnc
####

# replace all novnc normal (used for bookmarks and favorites) icon sizes with fixed 16x16 icon
sed -i -E 's~\s+<link rel="icon" sizes.*~    <link rel="icon" sizes="16x16" type="image/png" href="app/images/icons/novnc-16x16.png">~g' "/usr/share/webapps/novnc/vnc.html"

# replace all novnc home screen (used for tablets etc) icon sizes with fixed 16x16 icon
sed -i -E 's~\s+<link rel="apple-touch-icon" sizes.*~    <link rel="apple-touch-icon" sizes="16x16" type="image/png" href="app/images/icons/novnc-16x16.png">~g' "/usr/share/webapps/novnc/vnc.html"

# config - openbox
####

# copy custom openbox theme
cp -r /home/nobody/openbox/theme/Shiki-Brave /usr/share/themes/

# copy custom openbox main config file to home directory (required to set theme and menu font)
mkdir -p /home/nobody/.config/openbox
cp /home/nobody/openbox/config/rc.xml /home/nobody/.config/openbox/rc.xml

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
    <!-- APPLICATIONS_PLACEHOLDER -->
  <separator label="Utils" />
    <item label="Openbox config">
    <action name="Execute">
      <command>obconf</command>
      <startupnotify><enabled>yes</enabled></startupnotify>
    </action>
    </item>
    <item label="Openbox menu">
    <action name="Execute">
      <command>obmenu</command>
      <startupnotify><enabled>yes</enabled></startupnotify>
    </action>
    </item>
    <item label="GTK theme">
    <action name="Execute">
      <command>lxappearance</command>
      <startupnotify><enabled>yes</enabled></startupnotify>
    </action>
    </item>
</menu>

</openbox_menu>
EOF

# set default system font (contents below generated via lxappearance util)
cat <<'EOF' > /home/nobody/.gtkrc-2.0
# DO NOT EDIT! This file will be overwritten by LXAppearance.
# Any customization should be done in ~/.gtkrc-2.0.mine instead.

include "/home/nobody/.gtkrc-2.0.mine"
gtk-theme-name="Adwaita"
gtk-icon-theme-name="Adwaita"
gtk-font-name="Cantarell 8"
gtk-cursor-theme-name="Adwaita"
gtk-cursor-theme-size=0
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle="hintfull"
EOF

mkdir -p /home/nobody/.config/gtk-3.0
cat <<'EOF' > /home/nobody/.config/gtk-3.0/settings.ini
[Settings]
gtk-theme-name=Adwaita
gtk-icon-theme-name=Adwaita
gtk-font-name=Cantarell 8
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=0
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
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

# ENVVARS_PLACEHOLDER
EOF

# replace env vars placeholder string with contents of file (here doc)
# note we need to -reinsert the placeholder as other gui docker images
# may require additonal env vars i.e. krusader
sed -i '/# ENVVARS_PLACEHOLDER/{
	s/# ENVVARS_PLACEHOLDER//g
	r /tmp/envvars_heredoc
}' /usr/local/bin/init.sh
rm /tmp/envvars_heredoc

# cleanup
cleanup.sh
