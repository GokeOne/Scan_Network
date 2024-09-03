#!/bin/bash


#Author GokeOne

# Color Definitions
C=$(printf '\033')
RED="${C}[1;31m"
GREEN="${C}[1;32m"
YELLOW="${C}[1;33m"
BLUE="${C}[1;34m"
MAGENTA="${C}[1;35m"
CYAN="${C}[1;36m"
LIGHT_GRAY="${C}[1;37m"
DARK_GRAY="${C}[1;90m"
NC="${C}[0m" # No Color
UNDERLINED="${C}[4m"
ITALIC="${C}[3m"
PARPADEO="${C}[1;5m"

# Report time mark
date=$(date +'%d_%m_%Y_%H%M%S')
report="report_$date.txt"
line=$(printf "%0.s-" {1..50})

write_report() {
        local message=$1
        echo -e "$message" >> $report
}

line() {
        echo "$line" >>$report
}


check_permission() {
    if [ "$EUID" -ne 0 ]; then
        write_report "${YELLOW}[WARNING]${NC} This script is not running as root. Some information might be incomplete."
        line
    fi
}


validate_ip() {
        local ip=$1
        #Ipv4
        if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
                IFS='.' read -r -a octetos <<< "$ip"
                for octeto in "${octetos[@]}"; do
                        if (( octeto < 0 || octeto > 255 )); then
                                echo "La direccion $ip es invalida"
                                return 1
                        fi
                done
                echo "La direccion $ip es valida"
                return 0
        fi
}



startup(){
	clear
	echo "${GREEN}SCANNER${NC}"
	echo
	while true; do
		read -p "Enter the ip to scan: " ip
		if validate_ip "$ip"; then
			break
		fi
	done

	echo
	echo
	echo "Enter \"f\" or \"s\" "
	read -p "Do you want to do a full scan(f) or specific scan(s): " type_scan
	type_scan=$(echo -n $type_scan | tr '[:upper:]' '[:lower:]')

	if [ "$type_scan" = "f" ]; then
		echo "[${BLUE}INFO${NC}]Take a coffee this may take some time... :)"
		for port in {1..65535}; do
			response=$(nc -q 1 -zv $ip $port 2>&1)
			if [[ "$response" == *'open'* ]]; then
				write_report "The port $port is ${BLUE}open${NC}"
			else
				write_report "The port $port is ${RED}close${NC}"
			fi
		done
	elif [ "$type_scan" = "s" ]; then
		read -p "Enter port to scan: " port
		case $port in
			21)
				resposne=$(nc -zv $ip $port 2>&1)
				if [[ "$response" == *"open"* || "$response" == *"succeeded"* ]]; then
					version=$(echo -e "\r\n" | nc -q 1 $ip $port)
					write_report "The port $port is ${BLUE}open${NC}"
					write_report "$version"
					echo "[${CYAN}INFO${NC}]Generating report..."
				else
					echo "The port is closed"
				fi
			;;
			22)
				response=$(nc -zv $ip $port 2>&1)
				if [[ "$response" == *"open"* || "$response" == *"succeeded"* ]]; then
					version=$(echo -e "\r\n" | nc $ip $port)
					write_report "The port $port is ${BLUE}open${NC}"
					write_report "$version"
                                        echo "[${CYAN}INFO${NC}]Generating report..."

				else
					echo "The port is closed"
				fi
			;;
			23)
				response=$(nc -zv $ip $port 2>&1)
				if [[ "$response" == *"open"* || "$response" == *"succeeded"* ]]; then
					version=$(telnet -V $ip)
					write_report "The port $port is ${BLUE}open${NC}"
					write_report "$version"
                                        echo "[${CYAN}INFO${NC}]Generating report..."
				else
					echo "The port is closed"
				fi


			;;
			25)
				response=$(nc -zv $ip $port 2>&1)
				if [[ "$response" == *"open"* || "$response" == *"succeeded"* ]]; then
					version=$(echo -e "EHLO example.com\r\n" | nc -q 1 172.16.10.89 25)
					write_report "The port $port is ${BLUE}open${NC}"
					write_report "$version"
                                        echo "[${CYAN}INFO${NC}]Generating report..."
				else
					echo "The port is closed"
				fi

			;;
			80)
				response=$(nc -zv $ip $port 2>&1)
				if [[ "$response" == *"open"* ]]; then
					version=$(echo -e "HEAD / HTTP/1.0\r\n\r\n" | nc $ip $port | grep Server)
					write_report "The port $port is ${BLUE}open${NC}"
					write_report "$version"
                                        echo "[${CYAN}INFO${NC}]Generating report..."
				else
					echo "The port is closed"
				fi
			;;
			110)
				response=$(nc -zv $ip $port 2>&1)
				if [[ "$response" == *"open"* || "$response" == *"succeeded"* ]]; then
					version=$(echo -e "\r\n" | nc -q 1 $ip $port)
                                        write_report "The port $port is ${BLUE}open${NC}"
					write_report "$version"
                                        echo "[${CYAN}INFO${NC}]Generating report..."
				else
					write_report "The port is closed"
				fi
			;;
			143)
				response=$(nc -zv $ip $port 2>&1)
				if [[ "$response" == *"open"* || "$response" == *"succeeded"* ]]; then
					version=$(echo -e "\r\n\r" | nc -q 1 172.16.10.89 143)
					write_report "The port $port is ${BLUE}open${NC}"
					write_report "$version"
                                        echo "[${CYAN}INFO${NC}]Generating report..."
				else
					write_report "The port is closed"
				fi
			;;
			139)
				response=$(nc -zv $ip $port 2>&1)
				if [[ "$response" == *"open"* || "$response" == *"succeeded"* ]]; then
					version=$(smbclient -L //$ip -N)
					write_report "The port $port is ${BLUE}open${NC}"
					write_report "$version"
                                        echo "[${CYAN}INFO${NC}]Generating report..."
				else
					write_report "The port is closed"
				fi
			;;
			445)
                                response=$(nc -zv $ip $port 2>&1)
                                if [[ "$response" == *"open"* || "$response" == *"succeeded"* ]]; then
                                        version=$(smbclient -L //$ip -N)
                                        write_report "The port $port is ${BLUE}open${NC}"
                                        write_report "$version"
                                        echo "[${CYAN}INFO${NC}]Generating report..."
                                else
                                        write_report "The port is closed"
                                fi
			;;
			443)
				response=$(nc -zv $ip $port 2>&1)
				if [[ "$response" == *"open"* || "$response" == *"succeeded"* ]]; then
					version=$(echo -e "HEAD / HTTP/1.0\r\n\r\n" | openssl s_client -connect $ip:443 2>/dev/null | grep "Server:")
					write_report "The port $port is ${BLUE}open${NC}"
					write_report "$version"
                                        echo "[${CYAN}INFO${NC}]Generating report..."
				else
					write_report "The port is closed"
				fi
			;;
			3306)
				response=$(nc -zv $ip $port 2>&1)
				if [[ "$response" == *"open"* || "$response" == *"succeeded"* ]]; then
					version=$(echo -e "\r\n" | nc -q 1 $ip $port)
                                        write_report "The port $port is ${BLUE}open${NC}"
                                        write_report "$version"
                                        echo "[${CYAN}INFO${NC}]Generating report..."
                                else
                                        write_report "The port is closed"
                                fi

			;;
			*)
				response=$(nc -zv $ip $port 2>&1)
				if [[ "$response" == *"open"* || "$response" == *"succeeded"* ]]; then
					version=$(echo -e "\r\n" | nc -q 1 $ip $port)
                                        write_report "The port $port is ${BLUE}open${NC}"
                                        write_report "$version"
                                        echo "[${CYAN}INFO${NC}]Generating report..."
                                else
                                        write_report "The port is closed"
                                fi
			;;

		esac
	else
		echo "Enter a valid option."
		echo "Exiting...."
		exit 1

	fi
}

startup
