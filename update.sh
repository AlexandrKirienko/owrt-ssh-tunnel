#!/bin/sh

# URL репозитория
REPO_URL="https://raw.githubusercontent.com/your_github_username/owrt-ssh-tunnel/main"
INSTALL_DIR="/usr/bin/owrt-ssh-tunnel"

echo "Обновление owrt-ssh-tunnel..."

# Остановка текущего autossh процесса (если запущен)
pkill -f "autossh.*owrt-ssh-tunnel"

# Скачивание нового основного скрипта
echo "Скачиваем owrt-tunnel.sh..."
wget -O "$INSTALL_DIR/owrt-tunnel.sh" "$REPO_URL/owrt-tunnel.sh"
chmod +x "$INSTALL_DIR/owrt-tunnel.sh"

echo "Обновление завершено. Запускаем обновленный скрипт."
"$INSTALL_DIR/owrt-tunnel.sh" &
