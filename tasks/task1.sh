#!/bin/bash

LOG_FILE="/var/log/dev_setup.log"

# Логирование в системный журнал, консоль и файл
log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "$timestamp - $level: $message" | tee -a "$LOG_FILE"
    logger -t dev_setup "$level: $message"
}

# Проверка на root
if [ "$(id -u)" -ne 0 ]; then
    echo "Скрипт должен быть запущен с правами root"
    exit 1
fi

# Обработка опции	
while getopts ":d:" opt; do
    case $opt in
        d) base_dir="$OPTARG";;
        \?)
            echo "Неизвестная опция: -$OPTARG"
            exit 1
            ;;
        :)
            echo "Не передано значение для опции -$OPTARG"
            exit 1
            ;;
    esac
done

# Если путь не указан — запросим
if [ -z "$base_dir" ]; then
    read -p "Введите базовый путь для рабочих директорий: " base_dir
fi

# Создаем базовую директорию
mkdir -p "$base_dir" || { log ERROR "Не удалось создать $base_dir"; exit 1; }
log INFO "Базовая директория $base_dir готова"

# Создаем группу dev, если её нет
if ! getent group dev >/dev/null; then
    groupadd dev && log INFO "Создана группа dev"
else
    log INFO "Группа dev уже существует"
fi

# Добавляем правило sudo без пароля для группы dev
if [ ! -f /etc/sudoers.d/dev-group ]; then
    echo "%dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev-group
    chmod 440 /etc/sudoers.d/dev-group
    log INFO "Настроено sudo для группы dev"
else
    log INFO "Настройка sudo для группы dev уже существует"
fi

# Получаем пользователей с UID >= 1000 кроме nobody
users=$(getent passwd | awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}')

# Добавляем пользователей в группу dev
for user in $users; do
    if ! id -nG "$user" | grep -qw "dev"; then
        usermod -aG dev "$user"
        log INFO "Пользователь $user добавлен в группу dev"
    else
        log INFO "Пользователь $user уже в группе dev"
    fi
done

# Создаем рабочие директории
for user in $users; do
    dir="$base_dir/${user}_workdir"
    mkdir -p "$dir" || { log ERROR "Не удалось создать директорию $dir"; continue; }

    chown "$user:$user" "$dir"
    chmod 660 "$dir"

    setfacl -m g:dev:r-x "$dir"

    log INFO "Директория $dir создана для $user"
done

log INFO "Настройка завершена"
exit 0
