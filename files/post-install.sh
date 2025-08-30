#!/bin/bash
#################################################
echo "Step 01... Choose the Machine Name"
sleep 2
#################################################

# Prompt the user for a hostname
echo "Enter the machine name:"
read -p "Keep it blank for no change: " new_hostname

# Check if the user entered a hostname
if [[ -n "$new_hostname" ]]; then
    # Set the hostname
    echo "$new_hostname" > /etc/hostname
    sed -i "s/127.0.1.1.*/127.0.1.1    $new_hostname/" /etc/hosts

    # Apply changes
    hostnamectl set-hostname "$new_hostname"
	sleep 2

    echo "Hostname updated to: $new_hostname"
else
    echo "No changes made to the hostname."
	sleep 2
fi
# Run OpenVPN
#openvpn --config /root/install_files/xibocli.ovpn &

#################################################
echo "Step 01.1... Choose Wifi Network"
sleep 2
#################################################

# Prompt the user for a hostname
echo "Will you use WIFI"
read -p "Hit Y to change, enter to skip: " wifi 

# Check if the user entered a hostname
if [[ -n "$wifi" ]]; then
	sleep 2
	/usr/local/bin/wifi-connect.sh
else
    echo "No changes made."
	sleep 2
fi
# Run OpenVPN
#openvpn --config /root/install_files/xibocli.ovpn &

###############################################3
clear
echo "Step 02... Choose Orientation"
sleep 3
#################################################

/usr/local/bin/orientation.sh

echo

#################################################
clear
echo "Step 03... Adding to machine to RMM console"
sleep 3
#################################################

#cp /root/install_files/rmmagent-linux.sh /usr/local/bin/
# Downloading the agent install from source 
wget -P /usr/local/bin/ https://raw.githubusercontent.com/netvolt/LinuxRMM-Script/main/rmmagent-linux.sh
chmod +x /usr/local/bin/rmmagent-linux.sh

/usr/local/bin/agent.sh

# Install Snap applications
#################################################
clear
echo "Step 04... Install Xibo Player"
sleep 3
#################################################

snap install snapd 
snap install xibo-player --channel=stable

# Retrieve the hostname
hostname=$(hostname)

# Path to playerSettings.xml
xml_file="/home/xibocli/snap/xibo-player/common/playerSettings.xml"

# Replace <displayName>Display</displayName> with the hostname
sed -i "s|<displayName>.*</displayName>|<displayName>${hostname}</displayName>|" "$xml_file"

# Verify the change
echo "Updated playerSettings.xml with hostname: $hostname"

clear
echo "Coping Xibo configuration files..."
sleep 3
# Copy configuration files
# Moved to preseed.cfg
#mkdir -p /home/xibocli/snap/xibo-player/common/
#mkdir -p /home/xibocli/XiboLib
#cp /root/install_files/playerSettings.xml /home/xibocli/snap/xibo-player/common/playerSettings.xml
#cp /root/install_files/cmsSettings.xml /home/xibocli/snap/xibo-player/common/cmsSettings.xml
echo '@/snap/bin/xibo-player' > /home/xibocli/.config/lxsession/LXDE/autostart

echo "Setting Display ID..."
# Path to playerSettings.xml
display_ID=$(/usr/bin/tr -dc 'A-Za-z0-9' < /dev/urandom | /usr/bin/head -c 32)
echo "Display ID:" $displayId
sleep 2
xml_file="/home/xibocli/snap/xibo-player/common/cmsSettings.xml"  
# Replace <displayName>Display</displayName> with the hostname
sed -i "s|<displayId>.*</displayId>|<displayId>${display_ID}</displayId>|" "$xml_file"
chown -R xibocli:xibocli /home/xibocli/

#################################################
clear
echo "Step 05... Updating grud image..."
sleep 2
#################################################

update-grub

#################################################
clear
echo "Step 06... Cleaning files..."
sleep 2
#################################################
echo "alias xibo-id="grep Id /home/xibocli/snap/xibo-player/common/cmsSettings.xml"" >> /etc/profile.d/00-aliases.sh
chmod +x /etc/profile.d/00-aliases.sh

#su - xibocli -c "export DISPLAY=:0 ; /snap/bin/xibo-player"

rm /usr/local/bin/post-install.sh
rm /etc/sudoers.d/xibocli

echo "Reboot machine......"

sleep 5

reboot
