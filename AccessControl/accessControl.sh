#!/bin/bash


is_installed(){
	systemctl list-units --type=service --all | grep "$1"
}

monitor_ssh(){

	if ! is_installed "ssh" >/dev/null 2>/dev/null; then
		echo "[ERROR] SSH service is not installed. It can't be monitored"
		return
	fi


	if [ ! -f "/var/log/auth.log" ]; then
        	echo "File auth.log does not exist, downloading dependencies..."
        	apt update -qq >/dev/null 2>&1 && apt install -y rsyslog -qq >/dev/null 2>&1
        	echo "Dependencies installed."
	fi

	tail -F /var/log/auth.log 2>/dev/null | while read line; do
    	# Procesar líneas de SSH (auth.log)
    		if echo "$line" | grep -q "Accepted password"; then
        		IP=$(echo "$line" | awk '{print $(NF-3)}')
        		USER=$(echo "$line" | awk '{print $(NF-5)}')
        		echo -e "\n[SSH] Conexión exitosa:\nDireccion IP: $IP\nUsuario: $USER"
    		elif echo "$line" | grep -q "Failed password"; then
        		IP=$(echo "$line" | awk '{print $(NF-3)}')
        		USER=$(echo "$line" | awk '{print $(NF-5)}')
        		echo -e "\n[SSH] Intento fallido:\nDireccion IP: $IP\nUsuario: $USER"
		fi
	done
}

monitor_ftp(){

	if ! is_installed vsftpd >/dev/null 2>/dev/null; then
		echo "[ERROR] FTP service is not installed. It can't be monitored"
		return
	fi
	if [ ! -f "/var/log/vsftpd.log" ]; then
		echo "The FTP server is not configured to export logs to /var/log/vsftpd.log"
		exit 1
	fi

	tail -F /var/log/vsftpd.log 2>/dev/null | while read line; do
		if echo "$line" | grep -q "OK LOGIN"; then
        		USER=$(echo "$line" | awk -F'[][]' '{print $4}')  # Extraer usuario entre corchetes
        		IP=$(echo "$line" | grep -oE '::ffff:[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | sed 's/::ffff://')
        		echo -e "\n[FTP] Conexión exitosa:\nDireccion IP: $IP\nUsuario: $USER"
    		elif echo "$line" | grep -q "FAIL LOGIN"; then
        		USER=$(echo "$line" | awk -F'[][]' '{print $4}')  # Extraer usuario entre corchetes
        		IP=$(echo "$line" | grep -oE '::ffff:[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | sed 's/::ffff://')
		        echo -e "\n[FTP] Intento fallido:\nDireccion IP: $IP\nUsuario: $USER"
    		fi
	done
}

monitor_nfs(){
	if ! is_installed nfs-server >/dev/null 2>/dev/null; then
		echo "[ERROR] NFS server is not installed. It can't be monitored"
		return
	fi

	if ! grep -q '^RPCMOUNTDOPTS="--debug"' "/etc/default/nfs-kernel-server"; then
		echo 'RPCMOUNTDOPTS="--debug"' >> "/etc/default/nfs-kernel-server"
		echo "[INFO] RPCMOUNTDOPT=\"--debug\" have been added to /etc/default/nfs-kernel-server"
		systemctl restart nfs-kernel-server
	fi
	journalctl -fu nfs-mountd.service 2>/dev/null | while read line; do
		if echo "$line" | grep -q "client attached"; then
			IP=$(echo "$line" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
			echo -e "\n[NFS] Montaje exitoso:\nIP: $IP"
		elif echo "$line" | grep -q "client detached"; then
			IP=$(echo "$line" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
			echo -e "\n[NFS] Cliente desconectado:\nIP: $IP"
		fi
	done
}

monitor_mysql(){
	if ! is_installed mysql >/dev/null 2>/dev/null; then
		echo "[ERROR] MySQL Server is not installed. It can't be monitored"
		return
	fi
	mysql_conf="/etc/mysql/mysql.conf.d/mysqld.cnf"
	if ! grep -q "general_log_file" "$mysql_conf"; then
		echo "log_outptut = FILE" >>  "$mysql_conf"
		echo "general_log = 1" >> "$mysql_conf"
		echo "general_log_file = /var/log/mysql/mysql.log"  >> "$mysql_conf"
		echo "[INFO] Mysql configuration have been modified to take log reports"
		systemctl restart mysql
	fi

	declare -A active_users

 	tail -F "/var/log/mysql/mysql.log" 2>/dev/null | while read line; do
        	if echo "$line" | grep -q "Connect"; then
            		SESSION_ID=$(echo "$line" | awk '{print $2}')
            		USER=$(echo "$line" | awk '{print $4}' | cut -d '@' -f 1)
            		IP=$(echo "$line" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')

            		active_users["$SESSION_ID"]="$USER"
            		echo -e "\n[MySQL] Conexión exitosa\nUsuario: $USER\nIP: $IP"

        	elif echo "$line" | grep -q "Quit"; then
            		SESSION_ID=$(echo "$line" | awk '{print $2}')
            		USER=${active_users["$SESSION_ID"]}

		        if [ -n "$USER" ]; then
                		echo -e "\n[MySQL] Usuario desconectado\nUsuario: $USER"
                		unset active_users["$SESSION_ID"]
            		else
                		echo -e "\n[MySQL] Usuario desconocido desconectado (ID: $SESSION_ID)"
            		fi
        	fi
    	done

}


menu(){
	echo "-------------------------"
	echo "Select one option: "
	echo "1. Monitor SSH"
	echo "2. Monitor FTP"
	echo "3. Monitor NFS"
	echo "4. Monitor MySQL"
	echo "5. Monitor all"
	read -p "Set your option: " option
	echo "-------------------------"

	case $option in
		1)
			monitor_ssh
			;;
		2)
			monitor_ftp
			;;
		3)
			monitor_nfs
			;;
		4)
			monitor_mysql
			;;
		5)
			monitor_ssh &
			monitor_ftp &
			monitor_nfs &&
			monitor_mysql
			;;
		*)
			echo "The option is not valid."
			exit 2
			;;
	esac
}


menu
