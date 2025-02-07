# Requirements

Para poder utilizar este script necesitaremos tener instalados nmap y snmpwalk.
`apt install nmap snmp`

# Para que sirve

Es una herramienta para controlar la red, nos da información básica de los equipos que esten conectados.

- Nos enumera todos los equipos de la red
- Enumera información snmp (en caso de que este disponible)
- Analiza los puertos abiertos de los equipos
- Identifica el sistema operativo a partir del ttl

# Uso

Para imprimir la información en pantalla:
`./netControl.sh`

Para guardar la información en un archivo:
`./netControl.sh > report.txt`
