#!/bin/bash

#########################################################################################
# This script automates the process of sending scripts to MikroTik routers and          #
# configuring SNMP settings.                                                            #
#########################################################################################

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Example usage
username="admin"
password="admin"
script_path_211="/root/supervision_mikrotik/bandwidth-10-211.rsc"
script_path_144="/root/supervision_mikrotik/bandwidth-10-144.rsc"
remote_file_path="/bandwidth.rsc"

# List of router IPs
router_ips_211="/root/supervision_mikrotik/router-10-211.txt"
router_ips_144="/root/supervision_mikrotik/router-10-144.txt"

# Function to upload file to MikroTik router
upload_script_to_router() {
    local router_ip=$1
    local username=$2
    local password=$3
    local local_file_path=$4
    local remote_file_path=$5
    
    # Use scp to upload the file
    sshpass -p$password scp -q -oUserKnownHostsFile="/dev/null" -oStrictHostKeyChecking=no \
    -oConnectTimeout=5 -oKexAlgorithms=diffie-hellman-group14-sha1 "$local_file_path" \
    "$username"@"$router_ip":"$remote_file_path"
    
    # Check if scp command was successful
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}File uploaded successfully to $router_ip.${NC}"
    else
        echo -e "${RED}Failed to upload file to $router_ip.${NC}"
    fi

    # Use ssh to automate execution of the script
    sshpass -p$password ssh -q -oUserKnownHostsFile="/dev/null" -oStrictHostKeyChecking=no \
    -oConnectTimeout=5 -oKexAlgorithms=diffie-hellman-group14-sha1 "$username"@"$router_ip" \
    '/system scheduler add name=bandwidth interval=5m on-event="/import bandwidth.rsc"'

    # Check if ssh command was successful
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Script successfully automated on $router_ip.${NC}"
    else
        echo -e "${RED}Failed to automate script on $router_ip.${NC}"
    fi
}

# Function to disable script and SNMP on router
disable_script_to_router() {
    local router_ip=$1
    local username=$2
    local password=$3
    local local_file_path=$4
    local remote_file_path=$5

    # Remove file from router
    sshpass -p$password ssh -q -oUserKnownHostsFile="/dev/null" -oStrictHostKeyChecking=no \
    -oConnectTimeout=5 -oKexAlgorithms=diffie-hellman-group14-sha1 "$username"@"$router_ip" \
    "/file remove $remote_file_path"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}File removed successfully from $router_ip.${NC}"
    else
        echo -e "${RED}Failed to remove file from $router_ip.${NC}"
    fi

    # Remove automation
    sshpass -p$password ssh -q -oUserKnownHostsFile="/dev/null" -oStrictHostKeyChecking=no \
    -oConnectTimeout=5 -oKexAlgorithms=diffie-hellman-group14-sha1 "$username"@"$router_ip" \
    '/system scheduler remove bandwidth'
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Automation removed successfully from $router_ip.${NC}"
    else
        echo -e "${RED}Failed to remove automation from $router_ip.${NC}"
    fi
}

# Function to upload SNMP configuration to router
upload_snmp_to_router() {
    local router_ip=$1
    local username=$2
    local password=$3

    # Set SNMP community
    sshpass -p$password ssh -q -oUserKnownHostsFile="/dev/null" -oStrictHostKeyChecking=no \
    -oConnectTimeout=5 -oKexAlgorithms=diffie-hellman-group14-sha1 "$username"@"$router_ip" \
    '/snmp community set public name=supervision addresses=::/0'

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}SNMP community successfully set on $router_ip.${NC}"
    else
        echo -e "${RED}Failed to set SNMP community on $router_ip.${NC}"
    fi

    # Activate SNMP
    sshpass -p$password ssh -q -oUserKnownHostsFile="/dev/null" -oStrictHostKeyChecking=no \
    -oConnectTimeout=5 -oKexAlgorithms=diffie-hellman-group14-sha1 "$username"@"$router_ip" \
    '/snmp set enabled=yes'

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}SNMP successfully activated on $router_ip.${NC}"
    else
        echo -e "${RED}Failed to activate SNMP on $router_ip.${NC}"
    fi
}

# Function to disable SNMP configuration on router
disable_snmp_to_router() {
    local router_ip=$1
    local username=$2
    local password=$3

    # Change SNMP community
    sshpass -p$password ssh -q -oUserKnownHostsFile="/dev/null" -oStrictHostKeyChecking=no \
    -oConnectTimeout=5 -oKexAlgorithms=diffie-hellman-group14-sha1 "$username"@"$router_ip" \
    '/snmp community set supervision name=public'

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}SNMP community successfully changed on $router_ip.${NC}"
    else
        echo -e "${RED}Failed to change SNMP community on $router_ip.${NC}"
    fi

    # Deactivate SNMP
    sshpass -p$password ssh -q -oUserKnownHostsFile="/dev/null" -oStrictHostKeyChecking=no \
    -oConnectTimeout=5 -oKexAlgorithms=diffie-hellman-group14-sha1 "$username"@"$router_ip" \
    '/snmp set enabled=no'

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}SNMP successfully deactivated on $router_ip.${NC}"
    else
        echo -e "${RED}Failed to deactivate SNMP on $router_ip.${NC}"
    fi
}

# Main loop for user interaction
choice=""

while [[ $choice != "exit" ]]; do
    echo "Select an option:"
    echo -e "0: ${YELLOW}Network 10.211.0.0/24${NC}"
    echo -e "1: ${YELLOW}Network 10.144.1.0/24${NC}"
    echo -e "exit: ${YELLOW}Exit${NC}"

    read -p "Enter your choice (0 or 1): " choice

    case $choice in
        0)
            echo "Select an action for Network 10.211.0.0/24:"
            echo -e "0: ${YELLOW}Push script${NC}"
            echo -e "1: ${YELLOW}Remove script${NC}"
            echo -e "2: ${YELLOW}Push script and SNMP${NC}"
            echo -e "3: ${YELLOW}Remove script and SNMP${NC}"
            echo -e "5: ${YELLOW}Exit${NC}"

            read -p "Enter your choice (0, 1, 2, or 3): " choice2
            case $choice2 in
                0)
                    # Upload script to routers
                    for router_ip in $(cat $router_ips_211); do
                        upload_script_to_router "$router_ip" "$username" "$password" \
                        "$script_path_211" "$remote_file_path"
                        echo
                    done
                    ;;
                1)
                    # Remove script from routers
                    for router_ip in $(cat $router_ips_211); do
                        disable_script_to_router "$router_ip" "$username" "$password" \
                        "$script_path_211" "$remote_file_path"
                        echo
                    done
                    ;;
                2)
                    # Upload script and SNMP config to routers
                    for router_ip in $(cat $router_ips_211); do
                        upload_script_to_router "$router_ip" "$username" "$password" \
                        "$script_path_211" "$remote_file_path"
                        upload_snmp_to_router "$router_ip" "$username" "$password"
                        echo
                    done
                    ;;
                3)
                    # Remove script and SNMP config from routers
                    for router_ip in $(cat $router_ips_211); do
                        disable_script_to_router "$router_ip" "$username" "$password" \
                        "$script_path_211" "$remote_file_path"
                        disable_snmp_to_router "$router_ip" "$username" "$password"
                        echo
                    done
                    ;;
                5)
                    echo "Exiting..."
                    ;;
                *)
                    echo -e "${RED}Invalid option. Please select again.${NC}"
                    ;;
            esac
            ;;
        1)
            echo "Select an action for Network 10.144.1.0/24:"
            echo -e "0: ${YELLOW}Push script${NC}"
            echo -e "1: ${YELLOW}Remove script${NC}"
            echo -e "2: ${YELLOW}Push script and SNMP${NC}"
            echo -e "3: ${YELLOW}Remove script and SNMP${NC}"
            echo -e "5: ${YELLOW}Exit${NC}"

            read -p "Enter your choice (0, 1, 2, or 3): " choice2
            case $choice2 in
                0)
                    # Upload script to routers
                    for router_ip in $(cat $router_ips_144); do
                        upload_script_to_router "$router_ip" "$username" "$password" \
                        "$script_path_144" "$remote_file_path"
                        echo
                    done
                    ;;
                1)
                    # Remove script from routers
                    for router_ip in $(cat $router_ips_144); do
                        disable_script_to_router "$router_ip" "$username" "$password" \
                        "$script_path_144" "$remote_file_path"
                        echo
                    done
                    ;;
                2)
                    # Upload script and SNMP config to routers
                    for router_ip in $(cat $router_ips_144); do
                        upload_script_to_router "$router_ip" "$username" "$password" \
                        "$script_path_144" "$remote_file_path"
                        upload_snmp_to_router "$router_ip" "$username" "$password"
                        
                        # Example of additional firewall rule addition
                        sshpass -p$password ssh -q -oUserKnownHostsFile="/dev/null" \
                        -oStrictHostKeyChecking=no -oConnectTimeout=5 \
                        -oKexAlgorithms=diffie-hellman-group14-sha1 "$username"@"$router_ip" \
                        '/ip firewall filter add place-before=2 chain=input protocol=udp \
                        dst-port=161 src-address=10.144.0.35 action=accept comment="Allow SNMP traffic"'

                        echo
                    done
                    ;;
                3)
                    # Remove script and SNMP config from routers
                    for router_ip in $(cat $router_ips_144); do
                        disable_script_to_router "$router_ip" "$username" "$password" \
                        "$script_path_144" "$remote_file_path"
                        disable_snmp_to_router "$router_ip" "$username" "$password"
                        echo
                    done
                    ;;
                5)
                    echo "Exiting..."
                    ;;
                *)
                    echo -e "${RED}Invalid option. Please select again.${NC}"
                    ;;
            esac
            ;;
        exit)
            echo "Exiting..."
            ;;
        *)
            echo -e "${RED}Invalid option. Please select again.${NC}"
            ;;
    esac
done
