# MikroTik Automation Scripts

This repository contains a script for managing MikroTik routers, specifically focusing on posting scripts and SNMP configurations.

## Features

- Bandwidth Script Management: Upload and remove bandwidth configuration scripts (bandwidth-10-211.rsc and bandwidth-10-144.rsc) to/from MikroTik routers in specified networks.
- SNMP Configuration: Automate SNMP settings for network supervision and management.
- Firewall Rules: Example included for adding firewall rules to allow SNMP traffic on specific network range.

## Prerequisites

- sshpass: Required for non-interactive SSH password authentication.

```bash
sudo apt install sshpass
```

- mysql: Required for retrieving IP addresses from the MySQL database.

```bash
sudo apt install mysql-client
```
## Installation

1. Clone the repository:

```bash
git clone https://github.com/codi639/mikrotik-automation.git
cd mikrotik-automation
```

2. Update configuration:

- Modify `username`, `password`, `script_path_211`, `script_path_144`, `remote_file_path`, `router_ips_211`, and `router_ips_144` variables in `mikrotik-automation.sh` according to your environment.
- Ensure SSH commands in `push_config_to_mikrotik.sh` are adapted if necessary, particularly regarding the `-o KexAlgorithms=diffie-hellman-group14-sha1` parameter, which may vary depending on your SSH server configuration.

## Usage

1. Run the script:

```bash
./mikrotik-automation.sh
```

2. Select the network:
   - Choose between Network 10.211.0.0/24 or Network 10.144.1.0/24.

3. Choose an action:
   - Push script: Uploads bandwidth script to routers.
   - Remove script: Removes bandwidth script from routers.
   - Push script and SNMP: Uploads bandwidth script and configures SNMP settings.
   - Remove script and SNMP: Removes bandwidth script and deactivates SNMP.

4. Follow on-screen instructions to complete the selected action.

## Example

- Push bandwidth script and SNMP configuration to routers in Network 10.211.0.0/24:

```bash
./mikrotik-automation.sh
Select an option:
0: Network 10.211.0.0/24
1: Network 10.144.1.0/24
exit: Exit
Enter your choice (0 or 1): 0
Select an action for Network 10.211.0.0/24:
0: Push script
1: Remove script
2: Push script and SNMP
3: Remove script and SNMP
5: Exit
Enter your choice (0, 1, 2, or 3): 2
```
