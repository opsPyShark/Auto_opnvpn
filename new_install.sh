#!/bin/bash

# Убедитесь, что используете абсолютный путь к docker-compose.yml
DOCKER_COMPOSE_FILE="/root/antizapret/docker-compose.yml"

# Загружаем переменные из .env файла
set -a
source .env
set +a

# Проверка наличия необходимых переменных
if [ -z "$CHAT_ID" ] || [ -z "$BOT_TOKEN" ]; then
  echo "Ошибка: Не установлены переменные CHAT_ID или BOT_TOKEN в .env файле."
  exit 1
fi

# Установка Docker
echo "Установка Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
if [ $? -eq 0 ]; then
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
docker compose up -d --build
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
docker compose build
docker compose up -d
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
