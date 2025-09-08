#!/bin/sh

# Загрузка конфигурации
. "/usr/bin/owrt-ssh-tunnel/config.sh"

# Функция для логирования
log_message() {
    logger -t "owrt-ssh-tunnel" "$1"
    echo "$1"
}

# 1. Поднимает ssh соединение до сервера (используем autossh для надежности)
# 1.1 Ищет на сервере файл настроек структуры: Номер, MAC, Hostname, Порт SSH, Порт LuCi

# Получаем текущий MAC-адрес устройства (берем eth0, можно адаптировать)
DEVICE_MAC=$(ifconfig eth0 | grep -o -E '([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}' | head -n 1)
if [ -z "$DEVICE_MAC" ]; then
    log_message "Не удалось получить MAC-адрес устройства. Выход."
    exit 1
fi
DEVICE_HOSTNAME=$(hostname)

# Функция для выполнения команды на сервере через SSH (с sshpass)
run_remote_command() {
    sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        "$SERVER_USER@$SERVER_IP" "$1"
}

log_message "Подключаемся к серверу $SERVER_IP для получения конфигурации..."

# Проверяем наличие файла настроек на сервере
FILE_EXISTS=$(run_remote_command "[ -f $SERVER_CONFIG_FILE ] && echo 'true' || echo 'false'")

if [ "$FILE_EXISTS" = "false" ]; then
    log_message "Файл настроек $SERVER_CONFIG_FILE не найден на сервере. Создаем новый."
    # Создаем пустой файл на сервере
    run_remote_command "touch $SERVER_CONFIG_FILE"
    # Добавляем заголовок для удобства (опционально)
    run_remote_command "echo '# NUM, MAC, HOSTNAME, SSH_PORT, LUCI_PORT' >> $SERVER_CONFIG_FILE"
fi

# 1.2.1 По своему MAC адресу ищет соответствующую строчку в файле
# Скачиваем файл на локальную машину для парсинга
run_remote_command "cat $SERVER_CONFIG_FILE" > /tmp/owrt_devices.conf

LINE_DATA=$(grep "$DEVICE_MAC" /tmp/owrt_devices.conf)

SSH_PORT=""
LUCI_PORT=""
ENTRY_NUM=""

if [ -n "$LINE_DATA" ]; then
    log_message "Найдена существующая запись для MAC $DEVICE_MAC."
    # Парсим строку: Номер, MAC, Hostname, Порт SSH, Порт LuCi
    # Предполагаем, что разделитель - запятая и пробел
    ENTRY_NUM=$(echo "$LINE_DATA" | awk -F', ' '{print $1}')
    SSH_PORT=$(echo "$LINE_DATA" | awk -F', ' '{print $4}')
    LUCI_PORT=$(echo "$LINE_DATA" | awk -F', ' '{print $5}')
else
    log_message "Запись для MAC $DEVICE_MAC не найдена. Формируем новую."

    # Определяем следующий номер по порядку
    LAST_NUM_STR=$(grep -v '^#' /tmp/owrt_devices.conf | tail -n 1 | awk -F', ' '{print $1}')
    if [ -z "$LAST_NUM_STR" ]; then
        ENTRY_NUM="001"
    else
        LAST_NUM=$(printf "%d" "$LAST_NUM_STR") # Преобразуем в число
        NEXT_NUM=$((LAST_NUM + 1))
        ENTRY_NUM=$(printf "%03d" "$NEXT_NUM") # Форматируем как 001, 002 и т.д.
    fi

    # Формируем Порт SSH и Порт LuCi
    SSH_PORT="12$ENTRY_NUM"
    LUCI_PORT="18$ENTRY_NUM"

    # Формируем новую строку
    NEW_LINE="$ENTRY_NUM, $DEVICE_MAC, $DEVICE_HOSTNAME, $SSH_PORT, $LUCI_PORT"
    log_message "Создана новая запись: $NEW_LINE"

    # Добавляем новую строку в файл на сервере
    run_remote_command "echo '$NEW_LINE' >> $SERVER_CONFIG_FILE"
fi

rm /tmp/owrt_devices.conf # Удаляем временный файл

if [ -z "$SSH_PORT" ] || [ -z "$LUCI_PORT" ]; then
    log_message "Не удалось определить SSH_PORT или LUCI_PORT. Выход."
    exit 1
fi

log_message "Используемые порты: SSH=$SSH_PORT, LuCi=$LUCI_PORT"

# 1.3 Прокидывает порты 22 на Порт SSH и 80 на Порт LuCi
# Используем autossh для поддержания туннеля
log_message "Запускаем autossh туннель..."

# Параметры autossh:
# -M 0: Отключает порт мониторинга (autossh будет использовать свой механизм)
# -N: Не выполнять удаленную команду
# -T: Отключает выделение псевдо-терминала
# -f: Перейти в фон после успешного соединения
# -o "ExitOnForwardFailure yes": Выйти, если проброс портов не удался
# -o "ServerAliveInterval 30": Отправлять "keep-alive" пакеты каждые 30 секунд
# -o "ServerAliveCountMax 3": Если 3 "keep-alive" пакета не получены, разорвать соединение
# -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null: Отключает проверку ключей хоста (для первой установки, не рекомендуется для продакшена без понимания рисков)
# -R <remote_port>:22:<local_port>: Проброс порта SSH
# -R <remote_port>:80:<local_port>: Проброс порта LuCi

autossh -M 0 -N -T -f \
    -o "ExitOnForwardFailure yes" \
    -o "ServerAliveInterval 30" \
    -o "ServerAliveCountMax 3" \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -R "$SSH_PORT:localhost:22" \
    -R "$LUCI_PORT:localhost:80" \
    "$SERVER_USER@$SERVER_IP" \
    sshpass -p "$SERVER_PASSWORD" /usr/bin/autossh # sshpass для autossh

log_message "Autossh туннель запущен."

exit 0
