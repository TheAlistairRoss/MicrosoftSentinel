#cloud-config - Ubuntu Log Source

# update apt-get
sudo apt-get update

# install pip3
sudo apt-get install -y python3-pip

# installl unzip
sudo apt-get install -y unzip
  
# Allow root to have 65536 open files
echo "root         -    nofile         65536" | sudo tee -a /etc/security/limits.conf
  
# Allow any to have 65536 open files
echo "*         -    nofile         65536" | sudo tee -a /etc/security/limits.conf

# copy ./rsyslog-50-default.conf to /etc/rsyslog.d/50-default.conf and force copy
sudo cp -f ./rsyslog-50-default.conf /etc/rsyslog.d/50-default.conf

# restart rsyslog
sudo systemctl restart rsyslog

# install the log forwarder "https://learn.microsoft.com/en-us/azure/sentinel/connect-cef-ama#run-the-installation-script"
sudo wget -O Forwarder_AMA_installer.py https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/DataConnectors/Syslog/Forwarder_AMA_installer.py&&sudo python Forwarder_AMA_installer.py