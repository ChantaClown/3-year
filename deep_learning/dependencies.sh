#!/bin/bash
# Update and Upgrade
sudo apt update && sudo apt upgrade -y

# Install python3 if not installed
sudo apt install -y python3.10 python3.10-venv python3-pip

# Generating a venv
python3.10 -m venv Deep-Learning

# Activating the virtual environment
source Deep-Learning/bin/activate

# Dependencies
pip install --upgrade pip
pip install keras tensorflow

echo "Environment setup is complete."

