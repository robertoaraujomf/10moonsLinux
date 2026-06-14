#!/bin/bash
# Instala o driver da mesa 10moons
# Pode ser executado via terminal ou via .desktop (pkexec)
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=========================================="
echo " 10moons Tablet Driver - Instalação"
echo "=========================================="
echo ""

# Verificar se é root
if [ "$EUID" -ne 0 ]; then
    echo "[!] Este script precisa ser executado como root."
    echo "    Tente: sudo bash $0"
    exit 1
fi

# 1. Copiar driver para /opt
echo "[1/4] Copiando driver para /opt/10moons-driver/..."
rm -rf /opt/10moons-driver
cp -r "$DIR" /opt/10moons-driver
chown -R root:root /opt/10moons-driver
chmod -R 644 /opt/10moons-driver/*.py /opt/10moons-driver/*.yaml /opt/10moons-driver/*.txt 2>/dev/null || true
chmod 755 /opt/10moons-driver/driver.py

# 2. Instalar regra udev
echo "[2/4] Instalando regra udev..."
cp /opt/10moons-driver/99-10moons-tablet.rules /etc/udev/rules.d/99-10moons-tablet.rules
udevadm control --reload-rules

# 3. Instalar serviço systemd
echo "[3/4] Instalando serviço systemd..."
cp /opt/10moons-driver/10moons-tablet.service /etc/systemd/system/10moons-tablet.service
systemctl daemon-reload

# 4. Testar se o driver funciona
echo "[4/4] Testando conexão da mesa..."
if lsusb -d 08f2:6811 &>/dev/null; then
    echo "  Mesa detectada! Iniciando driver..."
    systemctl restart 10moons-tablet.service
    sleep 2
    if systemctl is-active --quiet 10moons-tablet.service; then
        echo "  ✅ Driver rodando!"
    else
        echo "  ⚠️  Driver não iniciou. Verifique: journalctl -u 10moons-tablet"
    fi
else
    echo "  ⚠️  Mesa não detectada. Conecte o USB e ela iniciará automaticamente."
fi

echo ""
echo ""
echo "=========================================="
echo " Instalação concluída!"

echo " A mesa 10moons agora funciona em área total"
echo " automaticamente ao conectar o USB."
echo ""
echo " Atalho de instalação criado no menu do sistema."
echo "=========================================="

# Criar .desktop no menu do sistema
cat > /usr/share/applications/10moons-tablet.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=10moons Tablet - Reinstalar
Comment=Reinstalar o driver da mesa digitalizadora 10moons
Exec=pkexec bash /opt/10moons-driver/install.sh
Icon=drive-removable-media-usb
Terminal=true
Categories=Settings;Hardware;
EOF

# Também criar um para desinstalar
cat > /usr/share/applications/10moons-tablet-uninstall.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=10moons Tablet - Desinstalar
Comment=Remover o driver da mesa digitalizadora 10moons
Exec=pkexec bash /opt/10moons-driver/uninstall.sh
Icon=drive-removable-media-usb
Terminal=true
Categories=Settings;Hardware;
EOF
