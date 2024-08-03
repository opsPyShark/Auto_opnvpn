#!/bin/bash

# Убедитесь, что используете абсолютный путь к docker-compose.yml
DOCKER_COMPOSE_FILE="/root/auto_opnvpn/antizapret/docker-compose.yml"

# Проверка наличия файла docker-compose.yml
if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
  echo "Ошибка: Файл $DOCKER_COMPOSE_FILE не найден."
  exit 1
fi

echo "Найден файл docker-compose.yml: $DOCKER_COMPOSE_FILE"

# Загружаем переменные из .env файла
set -a
source .env
set +a

# Проверка наличия необходимых переменных
if [ -z "$CHAT_ID" ] || [ -z "$BOT_TOKEN" ]; then
  echo "Ошибка: Не установлены переменные CHAT_ID или BOT_TOKEN в .env файле."
  exit 1
fi

# Проверка состояния Docker
function check_docker() {
  if ! docker compose -f "$DOCKER_COMPOSE_FILE" ps | grep -q "Up"; then
    echo "Docker контейнеры не запущены. Проверка состояния..."
    return 1
  else
    echo "Docker контейнеры запущены."
    return 0
  fi
}

# Запуск проверки состояния контейнеров
if ! check_docker; then
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="Ошибка: Docker контейнеры не запущены."
  exit 1
fi

# Остановка и удаление контейнеров
echo "Остановка и удаление контейнеров..."
docker compose -f "$DOCKER_COMPOSE_FILE" down
echo "Ожидание удаления контейнеров..."
until ! docker compose -f "$DOCKER_COMPOSE_FILE" ps | grep -q "Up"; do
  sleep 1
done
echo "Контейнеры удалены."

# Удаление старых ключей
echo "Удаление старых ключей..."
rm -rf easyrsa3/pki/
rm -rf client_keys/
echo "Старые ключи удалены."

# Запуск контейнеров
echo "Запуск контейнеров..."
docker compose -f "$DOCKER_COMPOSE_FILE" up -d
echo "Ожидание запуска контейнеров..."
until docker compose -f "$DOCKER_COMPOSE_FILE" ps | grep -q "Up"; do
  sleep 1
done

# Проверка успешного запуска контейнеров
if check_docker; then
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="Docker контейнеры успешно запущены."
else
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="Ошибка: Docker контейнеры не были запущены."
  exit 1
fi

echo "Контейнеры запущены."

# Проверка существования новых ключей
KEYS_PATH="antizapret/client_keys"
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
