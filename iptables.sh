#!/bin/bash

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
iptables -P OUTPUT ACCEPT

# Permitir tráfico de loopback (localhost)
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Permitir tráfico SSH solo en el puerto 1130
iptables -A INPUT -p tcp --dport 1130 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport 1130 -m conntrack --ctstate ESTABLISHED -j ACCEPT

# Permitir tráfico HTTP (80) y HTTPS (443) para el reverse proxy
iptables -A INPUT -p tcp -m multiport --dports 80,443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp -m multiport --sports 80,443 -m conntrack --ctstate ESTABLISHED -j ACCEPT

# Permitir tráfico DNS (puertos 53 UDP/TCP)
iptables -A INPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT -p tcp --dport 53 -j ACCEPT
iptables -A OUTPUT -p udp --sport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --sport 53 -j ACCEPT

# Permitir tráfico interno entre el servidor y Docker
iptables -A INPUT -i docker0 -j ACCEPT
iptables -A OUTPUT -o docker0 -j ACCEPT
iptables -A FORWARD -i docker0 -o docker0 -j ACCEPT

# Permitir conexiones ya establecidas y relacionadas
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Bloquear todo lo demás (esto ya está cubierto por las políticas predeterminadas)

# Guarda las reglas
iptables-save > /etc/iptables/rules.v4

echo "Reglas de iptables configuradas con éxito."
