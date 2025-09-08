#!/bin/sh

INSTALL_DIR="/usr/bin/owrt-ssh-tunnel"

echo "Удаление owrt-ssh-tunnel..."

# Остановка текущего autossh процесса (если запущен)
pkill -f "autossh.*owrt-ssh-tunnel"

# Удаление из автозагрузки
sed -i '\_owrt-tunnel.sh &\_d' /etc/rc.local

# Удаление директории установки
rm -rf "$INSTALL_DIR"

echo "owrt-ssh-tunnel успешно удален."
