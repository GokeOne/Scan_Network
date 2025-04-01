# Monitoring Script

## Description
This script monitors various services on a Linux system, including SSH, FTP, NFS and MySQL. It provides real-time logging of succesful and failed connection attempts, mounts, and disconnections.

## Features
- Monitors SSH logins and failed attempts
- Tracks FTP login successes and failures
- Detects NFS mounts and disconnections
- Logs MySQL connections and disconnections
- Ensures necessary log files and settings are configured

## Prerequisites
Make sure the necessary services are installed to successfully run the script:
- SSH (`openssh-server`)
- FTP (`vsftpd`)
- NFS (`nfs-kernel-server`)
- MySQL(`mysql-server`)

## Installation
No installation is required. Just make the script executable:
`chmod +x accessControl.sh`

## Usage
Run the script and select a monitoring option:
`./accessControl.sh`

## Menu Options
- 1: Monitor SSH
- 2: Monitor FTP
- 3: Monitor NFS
- 4: Monitor MySQL
- 5: Monitor all services

# How it works
- The script checks if each service is installed before monitoring
- It configures logging if necessary
- It continuosly reads log files and extracts relevan information using `grep` and `awk`
- Real-Time notifications are displayed on successful and failed connections


## Notes
- The script modifies MySQL logging settings if necessary and restarts the service
- If `auth.log` is missing, it attempts to install rsyslog
- NFS debugging options are enabled if required

