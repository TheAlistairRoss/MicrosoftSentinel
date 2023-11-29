#cloud-config - AMA - Ubuntu Log Source

runcmd:
  # update apt-get
  - sudo apt-get update
  
  # Allow root to have 65536 open files
  - echo "root         -    nofile         65536" | sudo tee -a /etc/security/limits.conf
  
  # Allow any to have 65536 open files
  - echo "*         -    nofile         65536" | sudo tee -a /etc/security/limits.conf
  
  # copy ./rsyslog-50-default.conf to /etc/rsyslog.d/50-default.conf and force copy
  - sudo cp -f ./rsyslog-50-default.conf /etc/rsyslog.d/50-default.conf

  # Create force Log Generator Directory in current directory 
  - mkdir -p ./LogGenerator

  # Download Log Generator to ./LogGenerator
  - cd ./LogGenerator
  - wget https://raw.githubusercontent.com/TheAlistairRoss/LinuxLogGenerator/main/downloader/downloader.sh || echo "Failed to download downloader.sh"

  # make the downloader.sh executable, with error checking
  - chmod +x ./downloader.sh && echo "downloader.sh is now executable" || echo "Failed to make downloader.sh executable"

  # execute the downloader.sh script
  - ./downloader.sh || echo "Failed to execute downloader.sh"
  
 # Check that ./LogGenerator/install/install.sh exists and then execute with sudo.
  - if [ -f ./LogGenerator/install/install.sh ]; then sudo ./LogGenerator/install/install.sh --install_as_service; else echo "Failed to find ./LogGenerator/install/install.sh"; fi



