#!/usr/bin/env bash

# install-kanto-raspberry.sh
# Установка Eclipse Kanto на Raspberry Pi 5
# Kanto — лёгкий edge-стек с поддержкой ARM64
# Интегрируется с Hono и Ditto

set -euo pipefail

# ========================================
# КОНФИГУРАЦИЯ
# ========================================
PI_HOST="${PI_HOST:-192.168.8.124}"
PI_USER="${PI_USER:-dt}"
KANTO_VERSION="1.0.0"
KANTO_ARCH="arm64"  # arm64 для Pi 5

# URL твоего Hono (на основной машине)
HONO_HOST="${HONO_HOST:-}"
HONO_MQTT_PORT="${HONO_MQTT_PORT:-}"
TENANT_ID="${TENANT_ID:-opentwins-tenant}"
DEVICE_ID="${DEVICE_ID:-raspberry-pi-001}"
AUTH_ID="${AUTH_ID:-raspberry-pi}"
PASSWORD="${PASSWORD:-raspberry-secret}"

# ========================================
# ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
# ========================================
ssh_cmd() {
    ssh -o StrictHostKeyChecking=no "${PI_USER}@${PI_HOST}" "$@"
}

scp_file() {
    scp -o StrictHostKeyChecking=no "$1" "${PI_USER}@${PI_HOST}:$2"
}

echo "==========================================="
echo "УСТАНОВКА ECLIPSE KANTO НА RASPBERRY PI"
echo "==========================================="
echo "Хост: ${PI_USER}@${PI_HOST}"
echo "Kanto версия: ${KANTO_VERSION}"
echo ""

# ========================================
# 1. ПРОВЕРКА SSH
# ========================================
echo "=== 1. Проверка SSH соединения ==="
ssh_cmd "echo 'SSH OK'"
echo "✓ SSH соединение установлено"

# ========================================
# 2. ОЧИСТКА СТАРЫХ УСТАНОВОК (если есть)
# ========================================
echo ""
echo "=== 2. Очистка предыдущих установок ==="

# Удаляем Hono/k3s если были установлены
if ssh_cmd "command -v k3s-uninstall.sh" &>/dev/null; then
    echo "Удаляем k3s..."
    ssh_cmd "sudo /usr/local/bin/k3s-uninstall.sh" || true
fi

# Удаляем старый Kanto если есть
if ssh_cmd "dpkg -l | grep -q kanto" &>/dev/null; then
    echo "Удаляем старый Kanto..."
    ssh_cmd "sudo apt-get remove -y kanto" || true
fi

echo "✓ Очистка завершена"

# ========================================
# 3. УСТАНОВКА CONTAINERD
# ========================================
echo ""
echo "=== 3. Установка containerd ==="

if ssh_cmd "command -v containerd" &>/dev/null; then
    echo "⚠️  containerd уже установлен"
else
    echo "Устанавливаем containerd через apt..."
    ssh_cmd "sudo apt-get update -qq && sudo apt-get install -y containerd"
    
    # Создаём конфигурацию по умолчанию
    ssh_cmd "sudo mkdir -p /etc/containerd && sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null"
    
    # Запускаем и включаем сервис
    ssh_cmd "sudo systemctl enable --now containerd"
    echo "✓ containerd установлен и запущен"
fi

# ========================================
# 4. СКАЧИВАНИЕ И УСТАНОВКА KANTO
# ========================================
echo ""
echo "=== 4. Установка Eclipse Kanto ==="

KANTO_DEB="kanto_${KANTO_VERSION}_linux_${KANTO_ARCH}.deb"
KANTO_URL="https://github.com/eclipse-kanto/kanto/releases/download/v${KANTO_VERSION}/${KANTO_DEB}"

echo "Загружаем ${KANTO_DEB}..."
ssh_cmd "wget -q ${KANTO_URL} -O /tmp/${KANTO_DEB}"

echo "Устанавливаем Kanto..."
ssh_cmd "sudo apt install -y /tmp/${KANTO_DEB}"

echo "✓ Eclipse Kanto установлен"

# ========================================
# 5. ПРОВЕРКА СЕРВИСОВ
# ========================================
echo ""
echo "=== 5. Проверка сервисов Kanto ==="
sleep 3

ssh_cmd "systemctl is-active suite-connector.service || true"
ssh_cmd "systemctl is-active container-management.service || true"
ssh_cmd "systemctl is-active software-update.service || true"

echo ""
echo "Статус всех сервисов:"
ssh_cmd "systemctl status suite-connector container-management --no-pager -l" || true

# ========================================
# ВЫВОД РЕЗУЛЬТАТОВ
# ========================================
echo ""
echo "==========================================="
echo "ECLIPSE KANTO УСТАНОВЛЕН НА RASPBERRY PI!"
echo "==========================================="
echo ""
echo "📋 УСТАНОВЛЕННЫЕ СЕРВИСЫ:"
echo "   • suite-connector     — подключение к облаку (Hono)"
echo "   • container-management — управление контейнерами"
echo "   • software-update     — OTA обновления"
echo "   • file-upload/backup  — работа с файлами"
echo "   • system-metrics      — метрики системы"
echo ""
echo "==========================================="
echo "СЛЕДУЮЩИЕ ШАГИ"
echo "==========================================="
echo ""
echo "1. Настройте подключение к Hono:"
echo "   На Pi отредактируйте /etc/suite-connector/config.json"
echo ""
echo "2. Укажите адрес вашего Hono сервера (MQTT):"
cat << 'CONFIG'
   ssh ${PI_USER}@${PI_HOST}
   sudo nano /etc/suite-connector/config.json
   
   Измените:
   {
     "address": "mqtts://YOUR_HONO_HOST:YOUR_MQTT_PORT",
     "tenantId": "opentwins-tenant",
     "deviceId": "raspberry-pi-001",
     "authId": "raspberry-pi",
     "password": "raspberry-secret"
   }
CONFIG
echo ""
echo "3. Перезапустите suite-connector:"
echo "   ssh ${PI_USER}@${PI_HOST} 'sudo systemctl restart suite-connector'"
echo ""
echo "4. Проверьте логи:"
echo "   ssh ${PI_USER}@${PI_HOST} 'journalctl -u suite-connector -f'"
echo ""
