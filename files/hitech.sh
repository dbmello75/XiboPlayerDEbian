#!/bin/bash

# Creating 'hitech' User
useradd -s /bin/bash hitech && mkdir /home/hitech && chown hitech:hitech /home/hitech && usermod -aG sudo hitech && echo hitech:MyPass123123 | chpasswd
echo xibocli:MyPass123123 | chpasswd

# Configure passwordless sudo for the user

echo "Configuring passwordless sudo for hitech..."
#
# Including users to sudo
#
echo "hitech ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/hitech
echo "xibocli ALL=(ALL) NOPASSWD: /usr/local/bin/post-install.sh" > /etc/sudoers.d/xibocli
echo "xibocli ALL=(ALL) NOPASSWD: /usr/local/bin/start_terminal.sh" >> /etc/sudoers.d/xibocli

chmod 440 /etc/sudoers.d/xibocli
chmod 440 /etc/sudoers.d/hitech


#Backup Xibo player data do make it easy to restore
#echo "*/5 * * * * root sudo /usr/local/bin/xibo-backup.sh >> /var/log/xibo_backup.log 2>&1" > /etc/cron.d/xibo-backup

chown -R 1000:1000 -R /home/xibocli/ 
