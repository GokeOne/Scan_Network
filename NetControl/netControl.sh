#!/bin/bash

# Función para determinar el sistema operativo basado en el TTL
determinar_so() {
    ttl=$1
    if [[ $ttl -le 64 ]]; then
        echo "Linux"
    elif [[ $ttl -le 128 ]]; then
        echo "Windows"
    elif [[ $ttl -le 255 ]]; then
        echo "Solaris/AIX"
    else
        echo "Desconocido"
    fi
}

# Función para escanear la red
escanear_red() {
    echo "=== Escaneando la red ==="
    # Obtener la red local (por ejemplo, 192.168.1.0/24)
    red_local=$(ip route | awk '/default/ {print $3}' | cut -d. -f1-3).0/24

    # Escanear la red con nmap
    nmap -sn $red_local -oG - | awk '/Up$/ {print $2}' | while read ip; do
        echo "Equipo encontrado: $ip"
        analizar_equipo $ip
    done
}

# Función para analizar un equipo
analizar_equipo() {
    ip=$1
    echo "Analizando equipo: $ip"

    # Intentar ping para obtener el TTL
    ttl=$(ping -c 1 $ip | grep "ttl=" | awk '{print $6}' | cut -d= -f2)
    if [[ -n $ttl ]]; then
        so=$(determinar_so $ttl)
        echo "  Sistema operativo detectado: $so (TTL: $ttl)"
    else
        echo "  Ping bloqueado o no responde."
        # Intentar escaneo de puertos como alternativa
        echo "  Intentando escaneo de puertos..."
        puertos_abiertos=$(nmap -Pn $ip | grep "open" | awk '{print $1}' | tr '\n' ' ')
        if [[ -n $puertos_abiertos ]]; then
            echo "  Puertos abiertos: $puertos_abiertos"
        else
            echo "  No se encontraron puertos abiertos."
        fi
    fi

    # Intentar obtener información con SNMP
    echo "  Intentando obtener información con SNMP..."
    snmp_info=$(snmpwalk -v2c -c public $ip 2>/dev/null)
    if [[ -n $snmp_info ]]; then
        echo "  Información SNMP:"
        echo "$snmp_info" | head -n 5  # Mostrar solo las primeras 5 líneas para no saturar la salida
    else
        echo "  SNMP no está habilitado o no se pudo acceder."
    fi

    echo "----------------------------------------"
}

# Iniciar el escaneo
escanear_red
