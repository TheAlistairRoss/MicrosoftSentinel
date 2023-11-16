#!/bin/bash

# Function to display help message
display_help() {
    echo "Usage: $0 [option...]" >&2
    echo
    echo "   -u, --unattended     Run the script in unattended mode"
    echo "   -h, --help           Display this help message"
    echo
    exit 1
}

# Set default values
unattended=false

# Parse arguments
while getopts ":uh" opt; do
  case ${opt} in
    u ) # process option u
      unattended=true
      ;;
    h ) # process option h
      display_help
      ;;
    \? ) echo "Invalid option: $OPTARG" 1>&2
      display_help
      ;;
  esac
done
shift $((OPTIND -1))

# Check if script is run with sudo
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Check if Python is installed
if ! command -v python3 &> /dev/null
then
    if $unattended; then
        # Update package lists
        sudo apt-get update -y
        if [ $? -ne 0 ]; then
            echo "Failed to update package lists" 1>&2
            exit 1
        fi

        # Install Python3 and pip3 without asking for confirmation
        sudo apt-get install -y python3 python3-pip
        if [ $? -ne 0 ]; then
            echo "Failed to install Python3 and pip3" 1>&2
            exit 1
        fi
    else
        # Update package lists
        sudo apt-get update
        if [ $? -ne 0 ]; then
            echo "Failed to update package lists" 1>&2
            exit 1
        fi

        # Install Python3 and pip3 and ask for confirmation
        sudo apt-get install python3 python3-pip
        if [ $? -ne 0 ]; then
            echo "Failed to install Python3 and pip3" 1>&2
            exit 1
        fi
    fi
fi

# Install required Python modules
# Replace 'module1 module2' with the names of the modules your script requires
# pip3 install module1 module2

# Make the Python script executable
chmod +x contosoLogGen.py
if [ $? -ne 0 ]; then
    echo "Failed to make Python script executable" 1>&2
    exit 1
fi

# Move the Python script and service file to the appropriate locations
sudo mv contosoLogGen.py /opt/contosoLogGen/
if [ $? -ne 0 ]; then
    echo "Failed to move Python script" 1>&2
    exit 1
fi

sudo mv contosoLogGen.service /etc/systemd/system/
if [ $? -ne 0 ]; then
    echo "Failed to move service file" 1>&2
    exit 1
fi

# Reload the systemd daemon
sudo systemctl daemon-reload
if [ $? -ne 0 ]; then
    echo "Failed to reload systemd daemon" 1>&2
    exit 1
fi

# Start the service
sudo systemctl start contosoLogGen.service
if [ $? -ne 0 ]; then
    echo "Failed to start service" 1>&2
    exit 1
fi

# Enable the service to start on boot
sudo systemctl enable contosoLogGen.service
if [ $? -ne 0 ]; then
    echo "Failed to enable service" 1>&2
    exit 1
fi