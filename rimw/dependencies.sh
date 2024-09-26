#!/bin/bash

# Update package index
echo "Updating package index..."
sudo apt update -y

# Update package index after adding PPA
echo "Updating package index after adding PPA..."
sudo apt update -y

# Install OpenJDK 17
echo "Installing OpenJDK 20..."
sudo apt-get install openjdk-21-jdk maven

# Verify Java installation
echo "Verifying Java installation..."
if java -version >/dev/null 2>&1; then
    echo "Java installation was successful."
else
    echo "Java installation failed."
    exit 1
fi

# Set JAVA_HOME environment variable if necessary
echo "Setting JAVA_HOME..."
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))

# Optional: Add JAVA_HOME to the shell configuration (for future sessions)
echo "Exporting JAVA_HOME to .bashrc..."
echo "export JAVA_HOME=$JAVA_HOME" >> ~/.bashrc
echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.bashrc

# Reload .bashrc
source ~/.bashrc
