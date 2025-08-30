#!/bin/bash

# Ensure required tools are available
if ! command -v wpa_supplicant &>/dev/null; then
    echo "wpa_supplicant is not installed. Please install it first."
    exit 1
fi

if ! command -v iw &>/dev/null; then
    echo "iw is not installed. Please install it first."
    exit 1
fi

# Get the wireless interface name
interface=$(iw dev | awk '$1=="Interface"{print $2}')
if [[ -z "$interface" ]]; then
    echo "No wireless interface found. Exiting..."
    exit 1
fi

echo "Using wireless interface: $interface"

# Scan for available networks
echo "Scanning for available networks..."
sudo iw dev "$interface" scan | grep "SSID:" | awk -F: '{print $2}' | sed 's/^ *//' | nl -w2 -s'. '
available_networks=$(sudo iw dev "$interface" scan | grep "SSID:" | awk -F: '{print $2}' | sed 's/^ *//')

# Display available networks with numbers
echo "Available networks:"
echo "$available_networks" | nl -w2 -s'. '

# Prompt user to select a network
read -p "Enter the number of the network to connect: " network_number
selected_network=$(echo "$available_networks" | sed -n "${network_number}p")

if [[ -z "$selected_network" ]]; then
    echo "Invalid selection. Exiting..."
    exit 1
fi

echo "You selected: $selected_network"

# Prompt for Wi-Fi password
read -p "Enter the password for $selected_network: " password

# Generate wpa_supplicant configuration
config_file="/etc/wpa_supplicant/wpa_supplicant-${interface}.conf"

cat <<EOL | sudo tee "$config_file" > /dev/null
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
network={
    ssid="$selected_network"
    psk="$password"
}
EOL

echo "Generated wpa_supplicant configuration at $config_file."

# Start wpa_supplicant
echo "Starting wpa_supplicant..."
sudo wpa_supplicant -B -i "$interface" -c "$config_file"

# Obtain an IP address using DHCP
echo "Obtaining IP address..."
sudo dhclient "$interface"

# Confirm connection
if ping -c 3 8.8.8.8 &>/dev/null; then
    echo "Successfully connected to $selected_network."
else
    echo "Failed to connect to $selected_network. Check your configuration and try again."
fi
