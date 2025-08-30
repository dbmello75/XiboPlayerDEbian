# Xibo Player Debian Auto Installer


This project is intended to Install a new Debian with XFDE Windows Manager

Why not Ubuntu?!? Just because, period. 

- Any Help is welcome. 


## USB preparation

- Download Debian NetInst ( Or the Full DVD)
    - https://www.debian.org/CD/netinst/
- Prapare the flash-drive boot
    - In linux use createUSB ${\color{red} ( Be careful, it needs improvement. ) }$
    - In Windows use you favorite tool ( Rufus, etc...)
- Use syncUSB to copy the files. 


**Table of Contents**

## Deployment

### 1. grub.cfg

- Set collor
- Set custon Splash
- Set to ask for hostname (This is optional, comments in the file)
- Set domain Name (This is optional, comments in the file)
- Set preseed.cfg

### 2.  ( preseed.cfg)

#### 2.1. Install Debian Automatic ( preseed.cfg)
- Set locale, keyboard and timezone/clock
- Ask for he hostname
- Network is DHCP
- If 2 interfaces availabe, it ask for a Network interface
- Partitioning is Automatic
- Set user root passwd and Create user xibocli
- Install XFDE, sudo, iw, ssh ( and watever you whant. )
- Copy .deb files  ${\color{red} ( not working yet, need help ) }$
    - Remount /cdrom in RW mode
    - Not working. My idea was to copy the files to the USB to make the instalation faster. 
    - Copy .deb files to /cdrom/DebFiles ${\color{red} ( not working yet) }$

#### 2.2. Run late commands

- Setup xibocli XFDE Autologin
- Set UUFI name to Xibo Client
- Copy Install Files folder
	- Copy splash.png
	- Copy post-install.sh, start_terminal.sh and xibo-backup.sh
    - xibocli.opvn 
        - All traffic going trought a VPN
        - ${\color{red} ( not in use yet ) }$
    - Copy Xibo Player config Files 
    - Create Lib folder
	- Copy id_rsa file
    - Copy and Run hitech.sh

### 3. Run hitech.sh Script
- Add User hitech
- Change xibocli passwd
- Create hitech sudoers file
- Create xibocli sudoers file
- Fix sudoers files permissions
- Fix /home/xibocli permissions
- Reboot machine

### 4. Run post-install.sh Script
- Set machine Name ( if needed )
- Set up WIFI ( if needed ) ${\color{red} ( not working yet) }$
- Set VPN ${\color{red} ( not working/in use yet) }$
- Add machine to RMM Console. ( to remote managing.) 
- Install xibo-player
- Setup xibo-player conf Files
    - Set Display ID
	- Rename DisplayID in playerSetting.xml ${\color{red} ( not working yet) }$
- Set Display Orientation
- Set xibo-player to Auto Start
- Remove Instalation Scripts
- Update grup
- Create alias:
	- xibo-id (${\color{green} ( show displayId ) }$
- Open xibo-player ${\color{red} ( Not Working Yet) }$
- Reboot the machine.

### 5. PowerShell/bash USB Sync (syncUSB.[sh|ps1] ) 

This is not part of the instalation it self

- Zip the Files listed in FilesToSync.txt
- Copy Zip files to the USB
- Extract the files on the USB
- Eject the USB Drive

### 6. To-do List
- Xibo Player name on UUFI boot menu
- only ask for wifi if the WIFI interface is present
- Wifi Script
- Copy the Previus downloaded .deb files to target 
- Display Name not going to the CMS interface.
- Automatic aprove And rename Displays trough API 