#!/bin/bash

# Update and upgrade packages
apt update -y && apt upgrade -y

# Install essential packages
apt install -y git box64 sudo jq unzip || {
    echo "❌ Failed to install required packages. Please check your internet connection."
    exit 1
}

# Clean up old Playit repository keys if they exist
sudo apt-key del '16AC CC32 BD41 5DCC 6F00  D548 DA6C D75E C283 9680' 2>/dev/null
sudo rm -f /etc/apt/sources.list.d/playit-cloud.list

# Add Playit Cloud repository
curl -SsL https://playit-cloud.github.io/ppa/key.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/playit.gpg >/dev/null
echo "deb [signed-by=/etc/apt/trusted.gpg.d/playit.gpg] https://playit-cloud.github.io/ppa/data ./" | sudo tee /etc/apt/sources.list.d/playit-cloud.list

# Update package lists again
sudo apt update -y

# Install Playit
apt install -y playit || {
    echo "❌ Failed to install Playit. Please check your repository settings."
    exit 1
}

# Download and set up the Minecraft Bedrock server
wget -q --show-progress https://github.com/debojitsantra/BedrockServerTermux/releases/download/v7.0/server.zip || {
    echo "❌ Failed to download server.zip. Check your internet connection or the link."
    exit 1
}

unzip -o server.zip || {
    echo "❌ Failed to unzip server.zip. Ensure there's enough storage."
    exit 1
}

# Configure server files
cd server || {
    echo "❌ 'server' folder not found. Unzip process may have failed."
    exit 1
}

chmod +x bedrock_server start.sh

# Return to home directory
cd

# Final message
echo -e "\n✅ Environment setup complete!"
