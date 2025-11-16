#!/bin/bash

# Welcome message
echo "Starting Termux setup... Please be patient."

# Ensure storage access is granted (essential for first-time Termux users)
termux-setup-storage

# Update and upgrade Termux packages
apt update -y && apt upgrade -y

# Install required packages
pkg install proot-distro -y

# Install Ubuntu using proot-distro
proot-distro install ubuntu || {
    echo "❌ Ubuntu installation failed. Please check your internet connection or storage space."
    exit 1
}

# Create 'pd' command for easy Ubuntu login
echo "proot-distro login ubuntu" > /data/data/com.termux/files/usr/bin/pdu
chmod +x /data/data/com.termux/files/usr/bin/pdu

# Final instructions
echo -e "\n✅ Setup complete!"
echo "Type 'pdu' and press Enter to start Ubuntu."
echo "If you face issues, restart Termux and try again."
