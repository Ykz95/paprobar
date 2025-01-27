#!/bin/bash

# Variables
DOCKER_INTERFACE="docker0" # Interfaz de red de Docker
INTERNAL_PROXY_IP="172.17.0.2" # IP del reverse proxy interno (ajusta según tu configuración)
EXTERNAL_PROXY_IP="YOUR_HOST_IP" # IP del host (ajusta según tu configuración)

# Limpia las reglas existentes
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

# Establece políticas predeterminadas (bloqueo por defecto)
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# Permitir tráfico de loopback (localhost)
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# SSH: Permitir tráfico SSH solo en el puerto 1130
iptables -A INPUT -p tcp --dport 1130 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport 1130 -m conntrack --ctstate ESTABLISHED -j ACCEPT

# DNS: Permitir tráfico DNS (puertos 53 UDP/TCP)
iptables -A INPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT -p tcp --dport 53 -j ACCEPT
iptables -A OUTPUT -p udp --sport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --sport 53 -j ACCEPT

# Permitir comunicación entre el reverse proxy interno y externo
# Tráfico desde el reverse proxy interno (Docker) al host
iptables -A INPUT -i $DOCKER_INTERFACE -s $INTERNAL_PROXY_IP -d $EXTERNAL_PROXY_IP -p tcp -m multiport --dports 80,443 -j ACCEPT
iptables -A OUTPUT -o $DOCKER_INTERFACE -s $EXTERNAL_PROXY_IP -d $INTERNAL_PROXY_IP -p tcp -m multiport --sports 80,443 -j ACCEPT

# Permitir conexiones ya establecidas y relacionadas
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Bloquear todo lo demás (esto ya está cubierto por las políticas predeterminadas)

# Guarda las reglas
iptables-save > /etc/iptables/rules.v4

echo "Reglas de iptables configuradas con éxito."
