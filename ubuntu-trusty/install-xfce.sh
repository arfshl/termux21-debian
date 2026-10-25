#!/usr/bin/env bash
set -euo pipefail

# Update and upgrade system
apt-get update && apt-get upgrade -y && apt-get autoremove -y

# Install Desktop, VNC, and basic utility
apt-get install apt-transport-https gnupg xfce4 xfce4-terminal dbus-x11 pulseaudio nano wget curl sudo adduser xdg-user-dirs xdg-user-dirs-gtk xubuntu-wallpapers xfce4-whiskermenu-plugin xubuntu-icon-theme xubuntu-default-settings xubuntu-artwork pavucontrol software-properties-common tightvncserver -y && apt clean
# apt-get install xubuntu-desktop -y && apt clean

# Adding user and password
sudo adduser --disabled-password --gecos "ubuntu-xfce" ubuntu-xfce && echo 'ubuntu-xfce:123' | chpasswd && echo 'ubuntu-xfce ALL=(ALL:ALL) ALL' >> /etc/sudoers.d/user

# Setup VNC server
# Create VNC configuration directory
mkdir -p /home/ubuntu-xfce/.vnc

# Create VNC password file (default 1234567890)
printf "12345678\n12345678\n" | vncpasswd /home/ubuntu-xfce/.vnc/passwd
chmod 600 /home/ubuntu-xfce/.vnc/passwd

# Create VNC startup script
cat << 'EOF' > /home/ubuntu-xfce/.vnc/xstartup
#!/bin/sh
xrdb $HOME/.Xresources
xsetroot -solid grey
export XKL_XMODMAP_DISABLE=1
export PULSE_SERVER=127.0.0.1
/usr/bin/dbus-launch --exit-with-session /usr/bin/startxfce4 &
EOF
chmod +x /home/ubuntu-xfce/.vnc/xstartup
chown -R ubuntu-xfce:ubuntu-xfce /home/ubuntu-xfce/.vnc

# Create script for starting VNC server
cat << 'EOF' > /usr/local/bin/startvnc
#!/bin/sh
export USER=ubuntu-xfce
export HOME=/home/ubuntu-xfce
su - ubuntu-xfce -c "vncserver :0 -geometry 1280x720 -depth 24"
echo 'VNC server address: 127.0.0.1:5900 Password: 12345678'
EOF
chmod +x /usr/local/bin/startvnc

# Create script for stopping VNC server
cat << 'EOF' > /usr/local/bin/stopvnc
#!/bin/sh
export USER=ubuntu-xfce
export HOME=/home/ubuntu-xfce
su - ubuntu-xfce -c "vncserver -kill :0"
rm -rf /home/ubuntu-xfce/.vnc/*:0.pid
rm -rf /home/ubuntu-xfce/.vnc/*:0.log
rm -rf /tmp/.X0-lock
rm -rf /tmp/.X11-unix/X0
EOF
chmod +x /usr/local/bin/stopvnc

# Create script for restarting VNC server
echo '#!/bin/sh
stopvnc
startvnc' >> /usr/local/bin/restartvnc

# Make it executable
cd /usr/local/bin
chmod +x startvnc
chmod +x stopvnc
chmod +x restartvnc
cd
chmod +x /home/ubuntu-xfce/.vnc/xstartup