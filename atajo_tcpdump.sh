#!/bin/bash

# Comprobamos si se ejecuta como root (tcpdump lo requiere)
if [[ $EUID -ne 0 ]]; then
    echo "Este script debe ejecutarse como root o con sudo."
    exit 1
fi

# Variables por defecto

# Interfaz de red por defecto para la captura
INTERFAZ="eth0"

# Protocolo para filtrar.
PROTOCOLO=""                   

# Dirección IP para filtrar.
IP_FILTRO=""                    

# Puerto para filtrar.
PUERTO=""                       

# Tiempo de captura en segundos por defecto 10
DURACION=10                     

# Nombre de archivo para guardar captura. Incluye fecha/hora para evitar sobreescribir
ARCHIVO="captura_$(date +%Y%m%d_%H%M%S).pcap"

# Función de ayuda

function ayuda() {
    echo "Uso: $0 [-i interfaz] [-p protocolo] [-f IP] [-P puerto] [-d tiempo] [-s archivo]"
    echo
    echo "Opciones:"
    echo "  -i  Interfaz de red (por defecto: $INTERFAZ)"
    echo "  -p  Protocolo (tcp, udp, icmp...)"
    echo "  -f  Dirección IP para filtrar"
    echo "  -P  Puerto para filtrar"
    echo "  -d  Duración en segundos (por defecto: $DURACION segs)"
    echo "  -s  Nombre de archivo de salida (.pcap)"
    echo "  -h	Mostrar ayuda"
    echo "Ejemplo:"
    echo "  sudo $0 -i wlan0 -p tcp -f 192.168.1.10 -P 80 -d 20 -s salida.pcap"
    exit 1
}

# Lectura de parámetros

while getopts "i:p:f:P:d:s:h" opt; do
    case $opt in
        i) INTERFAZ=$OPTARG ;;
        p) PROTOCOLO=$OPTARG ;;
        f) IP_FILTRO=$OPTARG ;;
        P) PUERTO=$OPTARG ;; 
        d) DURACION=$OPTARG ;; 
        s) ARCHIVO=$OPTARG ;; 
        h) ayuda; exit 0;; 
        *) ayuda; exit 1;; 
    esac
done

# Construcción del filtro para tcpdump

FILTRO=""

[ -n "$PROTOCOLO" ] && FILTRO="$PROTOCOLO"

[ -n "$IP_FILTRO" ] && FILTRO="${FILTRO:+$FILTRO and }host $IP_FILTRO"

[ -n "$PUERTO" ] && FILTRO="${FILTRO:+$FILTRO and }port $PUERTO"

# Mostrar configuración antes de empezar
echo
echo "Interfaz: $INTERFAZ"
echo "Filtro: $FILTRO"
echo "Duración: $DURACION segundos"
echo "Guardando en: $ARCHIVO"
echo

# Ejecutar captura tcpdump
tcpdump -i "$INTERFAZ" $FILTRO -w "$ARCHIVO" &

PID=$!  # Guardamos el PID del proceso tcpdump para poder pararlo después

# Esperar el tiempo de captura especificado
sleep "$DURACION"

# Detener la captura
kill $PID

echo "Captura finalizada. Archivo guardado: $ARCHIVO"
