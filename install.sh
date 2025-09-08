#!/bin/sh

# Переменные для сервера (можно отредактировать в config.sh после установки)
SERVER_IP="your_server_ip"
SERVER_USER="your_server_user"
SERVER_PASSWORD="your_server_password" # Внимание: хранение пароля в скрипте не безопасно!

# URL репозитория
REPO_URL="https://raw.githubusercontent.com/your_github_username/owrt-ssh-tunnel/main"
INSTALL_DIR="/usr/bin/owrt-ssh-tunnel"

echo "Установка owrt-ssh-tunnel..."

# Проверка наличия необходимых утилит
if ! command -v wget >/dev/null; then
    echo "Устанавливаем wget..."
    opkg update
    opkg install wget
fi

if ! command -v autossh >/dev/null; then
    echo "Устанавливаем autossh..."
    opkg update
    opkg install autossh
fi

if ! command -v sshpass >/dev/null; then
    echo "Устанавливаем sshpass..."
    opkg update
    opkg install sshpass
fi

# Создание директории для установки
mkdir -p "$INSTALL_DIR"

# Скачивание основного скрипта
echo "Скачиваем owrt-tunnel.sh..."
wget -O "$INSTALL_DIR/owrt-tunnel.sh" "$REPO_URL/owrt-tunnel.sh"
chmod +x "$INSTALL_DIR/owrt-tunnel.sh"

# Создание файла конфигурации
echo "Создаем файл конфигурации $INSTALL_DIR/config.sh..."
cat << EOF > "$INSTALL_DIR/config.sh"
#!/bin/sh
SERVER_IP="$SERVER_IP"
SERVER_USER="$SERVER_USER"
SERVER_PASSWORD="$SERVER_PASSWORD"
SERVER_CONFIG_FILE="/root/owrt_devices.conf" # Путь к файлу настроек на сервере
EOF
chmod +x "$INSTALL_DIR/config.sh"

# Добавление в автозагрузку (например, через /etc/rc.local или отдельный сервис)
echo "Добавляем скрипт в автозагрузку..."
# Самый простой способ:
echo "$INSTALL_DIR/owrt-tunnel.sh &" >> /etc/rc.local
# Более правильный способ - создать init-скрипт или procd-сервис, но для простоты начнем с rc.local.

echo "Установка завершена. Вы можете отредактировать $INSTALL_DIR/config.sh."
echo "Запускаем owrt-tunnel.sh в первый раз..."
"$INSTALL_DIR/owrt-tunnel.sh" &
