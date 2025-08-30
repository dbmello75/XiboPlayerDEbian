#!/bin/bash

# Configuration file path
config_file="/etc/X11/xorg.conf.d/10-monitor.conf"

# Find the connected monitor
connected_output=$(su - xibocli -c "export DISPLAY=:0 ; xrandr --query | grep ' connected' | awk '{print \$1}'")

# Check if a monitor is connected
if [[ -z "$connected_output" ]]; then
    echo "No connected monitor found. Exiting..."
    exit 1
fi

# Prompt user for orientation with "Normal" as the default
echo "Choose monitor orientation (default: Normal):"
echo "1 - Normal"
echo "2 - Left"
echo "3 - Right"
read -p "Enter your choice (1/2/3): " choice

# Use "1" (Normal) if no input is provided
choice=${choice:-1}

# Determine the rotation based on user input
case $choice in
    1)
        rotation="normal"
        ;;
    2)
        rotation="left"
        ;;
    3)
        rotation="right"
        ;;
    *)
        echo "Invalid choice. Please enter 1, 2, or 3."
        exit 1
        ;;
esac

# Handle configuration file based on orientation
if [[ "$rotation" == "normal" ]]; then
    # Delete the configuration file if the orientation is normal
    if [[ -f "$config_file" ]]; then
        echo "Orientation is Normal. Deleting configuration file..."
         rm -f "$config_file"
    else
        echo "Orientation is Normal. No configuration file to delete."
    fi
else
    # Create or update the configuration file for Left or Right orientation
    echo "Setting orientation to $rotation. Updating configuration file..."
     bash -c "cat > $config_file" <<EOL
# Persistent monitor configuration
Section "Monitor"
    Identifier "$connected_output"
    Option "Rotate" "$rotation"
EndSection
EOL
fi

# Notify user of changes
if [[ "$rotation" == "normal" ]]; then
    echo "Monitor orientation set to Normal. Configuration file removed."
else
    echo "Monitor orientation set to $rotation. Configuration file updated at $config_file."
fi
sleep 3
