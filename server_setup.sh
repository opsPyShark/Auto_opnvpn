#!/bin/bash

# Обновление системы
echo "Updating system..."
sudo apt-get update -y
sudo apt-get upgrade -y

# Установка необходимых зависимостей
echo "Installing git..."
sudo apt-get install git -y

# Клонирование репозитория
echo "Cloning repository..."
git clone https://github.com/opsPyShark/auto_opnvpn

# Переход в каталог репозитория
cd auto_opnvpn

# Запуск скрипта new_install.sh
echo "Running new_install.sh..."
chmod +x new_install.sh
./new_install.sh

echo "Done!"
