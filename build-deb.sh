#!/bin/bash
set -e

VERSION="1.1.0"
PACKAGE="10moons-tablet-driver"
BUILD_DIR="/tmp/${PACKAGE}_${VERSION}_all"

echo "=== Criando pacote .deb do driver 10moons Tablet ==="

rm -rf "$BUILD_DIR"

# Estrutura de diretórios
mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/opt/10moons-driver"
mkdir -p "$BUILD_DIR/lib/udev/rules.d"
mkdir -p "$BUILD_DIR/lib/systemd/system"

# Copiar arquivos do driver
cp driver.py "$BUILD_DIR/opt/10moons-driver/"
cp config-vin1060plus.yaml "$BUILD_DIR/opt/10moons-driver/"
cp requirements.txt "$BUILD_DIR/opt/10moons-driver/"
cp AUTOR.txt "$BUILD_DIR/opt/10moons-driver/"
cp LICENSE "$BUILD_DIR/opt/10moons-driver/"
cp README.md "$BUILD_DIR/opt/10moons-driver/"
cp start.sh "$BUILD_DIR/opt/10moons-driver/"
cp stop.sh "$BUILD_DIR/opt/10moons-driver/"

# Regra udev e serviço systemd
cp 99-10moons-tablet.rules "$BUILD_DIR/lib/udev/rules.d/"
cp 10moons-tablet.service "$BUILD_DIR/lib/systemd/system/"

# Control file
cat > "$BUILD_DIR/DEBIAN/control" << EOF
Package: $PACKAGE
Version: $VERSION
Section: utils
Priority: optional
Architecture: all
Depends: python3, python3-evdev, python3-usb, python3-yaml
Maintainer: Roberto Araujo de Moraes Freitas <robertoaraujomf@gmail.com>
Description: Driver Linux para mesa digitalizadora 10moons 1060 Plus
 Driver em Python para mesa digitalizadora 10moons 1060 Plus Black.
 Suporte a área total da mesa, botões personalizáveis e
 inicialização automática via udev/systemd ao conectar o USB.
 Homepage: https://github.com/robertoaraujomf/10moonsLinux
EOF

# postinst
cat > "$BUILD_DIR/DEBIAN/postinst" << 'EOF'
#!/bin/bash
set -e

echo "[postinst] Configurando driver 10moons Tablet..."

chown -R root:root /opt/10moons-driver
chmod -R 644 /opt/10moons-driver/*.py /opt/10moons-driver/*.yaml /opt/10moons-driver/*.txt 2>/dev/null || true
chmod 755 /opt/10moons-driver/driver.py

udevadm control --reload-rules
udevadm trigger

systemctl daemon-reload

if lsusb -d 08f2:6811 &>/dev/null; then
    echo "[postinst] Mesa detectada! Iniciando driver..."
    systemctl restart 10moons-tablet.service
fi

exit 0
EOF

# prerm (pré-remoção)
cat > "$BUILD_DIR/DEBIAN/prerm" << 'EOF'
#!/bin/bash
set -e

echo "[prerm] Parando driver 10moons Tablet..."
systemctl stop 10moons-tablet.service 2>/dev/null || true

exit 0
EOF

# postrm (pós-remoção)
cat > "$BUILD_DIR/DEBIAN/postrm" << 'EOF'
#!/bin/bash
set -e

case "$1" in
    purge)
        echo "[postrm] Removendo todos os arquivos do driver..."
        rm -rf /opt/10moons-driver
        ;;
    remove|upgrade|failed-upgrade|abort-install|abort-upgrade|disappear)
        ;;
esac

systemctl daemon-reload 2>/dev/null || true
udevadm control --reload-rules 2>/dev/null || true

exit 0
EOF

chmod 755 "$BUILD_DIR/DEBIAN/postinst"
chmod 755 "$BUILD_DIR/DEBIAN/prerm"
chmod 755 "$BUILD_DIR/DEBIAN/postrm"

# Construir o .deb
dpkg-deb --root-owner-group --build "$BUILD_DIR" > /dev/null

mv "/tmp/${PACKAGE}_${VERSION}_all.deb" "./${PACKAGE}_${VERSION}_all.deb"

echo ""
echo "=== Pacote criado: ${PACKAGE}_${VERSION}_all.deb ==="
echo ""
echo "Para instalar (clique duas vezes ou use o terminal):"
echo "  sudo dpkg -i ${PACKAGE}_${VERSION}_all.deb"
echo "  sudo apt install -f   # se houver dependências faltando"
