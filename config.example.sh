#!/bin/sh
# Пример файла конфигурации для owrt-ssh-tunnel
# Этот файл будет скопирован и назван config.sh при установке

SERVER_IP="your_server_ip"              # IP-адрес вашего VPS/сервера
SERVER_USER="your_server_user"          # Логин для SSH на сервере
SERVER_PASSWORD="your_server_password"  # Пароль для SSH на сервере (ВНИМАНИЕ: хранение пароля в открытом виде небезопасно!)
SERVER_CONFIG_FILE="/root/owrt_devices.conf" # Путь к файлу с настройками устройств на сервере
