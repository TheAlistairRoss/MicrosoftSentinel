#!/bin/bash



# Function to display help message
# Display help message with usage instructions
display_help() {
    echo "This script installs the log simulator on a Linux machine. It can be run in unattended mode or interactive mode and can install the script as a service to run on boot."
    echo "Usage: $0 [option...]" >&2
    echo
    echo "   -s, --install_as_service   Install the script as a service (default = false)"
    echo "   -u, --unattended           Run the script in unattended mode"
    echo "   -h, --help                 Display this help message"
    echo
    exit 1
}

source_path_to_python_script="../src/log_simulator.py"
source_path_to_service_file="log_simulator.service"
destination_path_to_log_simulator="/opt/log_simulator"
destination_path_to_service_file="/etc/systemd/system/log_simulator.service"

# Set default values
install_as_service=false
unattended=false

# Parse arguments
while getopts ":iuh" opt; do
  case ${opt} in
    i ) 
      install_as_service=true
      ;;
    u ) 
      unattended=true
      ;;
    h ) 
      display_help
      ;;
    \? ) 
      echo "Invalid option: $OPTARG" 1>&2
      display_help
      ;;
  esac
done

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
    fi
fi

# Make the Python script executable
chmod +x $source_path_to_python_script
if [ $? -ne 0 ]; then
    echo "Failed to make Python script executable" 1>&2
    exit 1
fi

# Move the Python script to the appropriate location
sudo mv $source_path_to_python_script $destination_path_to_log_simulator
if [ $? -ne 0 ]; then
    echo "Failed to move Python script" 1>&2
    exit 1
fi

if $install_as_service; then
    # Move the service file to the appropriate location
    sudo mv $source_path_to_service_file $destination_path_to_service_file
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
    sudo systemctl start log_simulator
    if [ $? -ne 0 ]; then
        echo "Failed to start service" 1>&2
        exit 1
    fi

    # Enable the service to start on boot
    sudo systemctl enable log_simulator
    if [ $? -ne 0 ]; then
        echo "Failed to enable service" 1>&2
        exit 1
    fi
fi