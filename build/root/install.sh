#!/bin/bash

# exit script if return code != 0
set -e

# build scripts
####

# download build scripts from github
curly.sh -rc 6 -rw 10 -of /tmp/scripts-master.zip -url https://github.com/binhex/scripts/archive/master.zip

# unzip build scripts
unzip /tmp/scripts-master.zip -d /tmp

# move shell scripts to /root
mv /tmp/scripts-master/shell/arch/docker/*.sh /root/

# temp hack until base is rebuilt - move curly to /usr/local/bin to overwrite older ver
mv /root/curly.sh /usr/local/bin/

# pacman packages
####

# define pacman packages
pacman_packages="ttf-dejavu xorg-fonts-misc terminus-font ttf-dejavu xfce4-terminal tint2 xorg-server-xvfb tigervnc openbox obconf obmenu python2-xdg coreutils"

# install compiled packages using pacman
if [[ ! -z "${pacman_packages}" ]]; then
	pacman -S --needed $pacman_packages --noconfirm
fi

# aor packages
####

# define arch official repo (aor) packages
aor_packages=""

# call aor script (arch official repo)
source /root/aor.sh

# aur packages
####

# define aur packages
aur_packages="ttf-font-awesome websockify novnc"

# call aur install script (arch user repo)
source /root/aur.sh

# config - openbox
####

# copy custom openbox theme
cp -r /home/nobody/openbox/Shiki-Brave /usr/share/themes/

# copy default openbox main config file to home directory (required to set theme)
mkdir -p /home/nobody/.config/openbox
cp /etc/xdg/openbox/rc.xml /home/nobody/.config/openbox/rc.xml

# edit openbox main config and set theme
sed -i -e 's~<name>Clearlooks</name>~<name>Shiki-Brave</name>~g' /home/nobody/.config/openbox/rc.xml

# edit openbox menu items to add in application
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
  <separator label="System" />
    <item label="Openbox Configuration Manager">
    <action name="Execute">
      <command>obconf</command>
      <startupnotify><enabled>yes</enabled></startupnotify>
    </action>
    </item>
    <item label="Log Out">
    <action name="Exit">
      <prompt>yes</prompt>
    </action>
    </item>
</menu>

</openbox_menu>
EOF

# container perms
####

# create file with contets of here doc
cat <<'EOF' > /tmp/permissions_heredoc
echo "[info] Setting permissions on files/folders inside container..." | ts '%Y-%m-%d %H:%M:%.S'

chown -R "${PUID}":"${PGID}" /tmp /usr/share/themes /home/nobody /usr/share/novnc
chmod -R 775 /tmp /usr/share/themes /home/nobody /usr/share/novnc

EOF

# replace permissions placeholder string with contents of file (here doc)
sed -i '/# PERMISSIONS_PLACEHOLDER/{
    s/# PERMISSIONS_PLACEHOLDER//g
    r /tmp/permissions_heredoc
}' /root/init.sh
rm /tmp/permissions_heredoc

# cleanup
yes|pacman -Scc
rm -rf /usr/share/locale/*
rm -rf /usr/share/man/*
rm -rf /usr/share/gtk-doc/*
rm -rf /tmp/*
