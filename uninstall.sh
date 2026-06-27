#!/bin/bash
# Desinstala o driver da mesa 10moons
set -e

if [ "$EUID" -ne 0 ]; then
    echo "[!] Execute com sudo: sudo bash $0"
    exit 1
fi

echo "Desinstalando driver 10moons..."

# Parar serviço
systemctl stop 10moons-tablet.service 2>/dev/null || true
systemctl disable 10moons-tablet.service 2>/dev/null || true

# Remover arquivos
rm -f /etc/systemd/system/10moons-tablet.service
rm -f /etc/udev/rules.d/99-10moons-tablet.rules
rm -f /usr/share/applications/10moons-tablet.desktop
rm -f /usr/share/applications/10moons-tablet-uninstall.desktop
rm -rf /opt/10moons-driver

systemctl daemon-reload
udevadm control --reload-rules

echo "Driver desinstalado. Desplugue e replugue a mesa para restaurar o driver padrão do kernel."
