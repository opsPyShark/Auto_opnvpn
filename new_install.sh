#!/bin/bash

# Функция для поиска файла .env на всем сервере
find_env_file() {
  find / -name ".env" 2>/dev/null | head -n 1
}

# Путь к docker-compose.yml
DOCKER_COMPOSE_FILE="/root/auto_opnvpn/antizapret/docker-compose.yml"

# Поиск и загрузка переменных из .env файла
ENV_FILE=$(find_env_file)
if [ -z "$ENV_FILE" ]; then
  echo "Ошибка: Файл .env не найден на сервере."
  exit 1
fi

echo "Загружаем переменные из $ENV_FILE"
set -a
source "$ENV_FILE"
set +a

# Проверка наличия необходимых переменных
if [ -z "$CHAT_ID" ] || [ -z "$BOT_TOKEN" ]; then
  echo "Ошибка: Не установлены переменные CHAT_ID или BOT_TOKEN в файле .env."
  exit 1
fi

# Установка Docker
echo "Установка Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
if sudo sh get-docker.sh; then
  echo "Docker установлен успешно."
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="Docker установлен успешно."
else
  echo "Ошибка при установке Docker."
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="Ошибка при установке Docker."
  exit 1
fi

# Клонирование репозитория
echo "Клонирование репозитория..."
git clone https://github.com/xtrime-ru/antizapret-vpn-docker.git antizapret
if [ $? -eq 0 ]; then
  echo "Репозиторий успешно склонирован."
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="Репозиторий успешно склонирован."
else
  echo "Ошибка при клонировании репозитория."
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="Ошибка при клонировании репозитория."
  exit 1
fi

cd antizapret

# Сборка и запуск контейнеров
echo "Сборка и запуск контейнеров..."
docker compose -f "$DOCKER_COMPOSE_FILE" up -d --build
if [ $? -eq 0 ]; then
  echo "Контейнеры успешно собраны и запущены."
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="Контейнеры успешно собраны и запущены."
else
  echo "Ошибка при сборке и запуске контейнеров."
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="Ошибка при сборке и запуске контейнеров."
  exit 1
fi

# Обновление репозитория и контейнеров
echo "Обновление репозитория и контейнеров..."
git pull
docker compose -f "$DOCKER_COMPOSE_FILE" build
docker compose -f "$DOCKER_COMPOSE_FILE" up -d
if [ $? -eq 0 ]; then
  echo "Репозиторий и контейнеры успешно обновлены."
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="Репозиторий и контейнеры успешно обновлены."
else
  echo "Ошибка при обновлении репозитория и контейнеров."
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="Ошибка при обновлении репозитория и контейнеров."
  exit 1
fi

# Проверка существования новых ключей
KEYS_PATH="client_keys"
if [ ! -d "$KEYS_PATH" ]; then
  echo "Директория $KEYS_PATH не существует. Проверьте состояние контейнеров."
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="Ошибка: Директория $KEYS_PATH не существует. Проверьте состояние контейнеров."
  exit 1
fi

# Пути к файлам
FILES=("antizapret-client-tcp.ovpn" "antizapret-client-udp.ovpn")

# Отправка файлов в Telegram
for FILE in "${FILES[@]}"; do
  FILE_PATH="$KEYS_PATH/$FILE"
  if [ -f "$FILE_PATH" ]; then
    echo "Отправка файла $FILE_PATH в Telegram..."
    curl -F chat_id="$CHAT_ID" -F document=@"$FILE_PATH" "https://api.telegram.org/bot$BOT_TOKEN/sendDocument"
    echo "Файл $FILE_PATH отправлен в Telegram."
  else
    echo "Файл $FILE_PATH не существует"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="Ошибка: Файл $FILE_PATH не существует."
  fi
done
