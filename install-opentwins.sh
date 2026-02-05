#!/usr/bin/env bash

# install-opentwins.sh
# Полная установка OpenTwins на Debian/Ubuntu + Minikube + Helm
# Запускать с sudo: sudo bash install-opentwins.sh
# Требования: минимум 12–16 GB свободной RAM, 6+ CPU

set -euo pipefail

echo "=== 1. Обновление системы и установка базовых пакетов ==="
apt update && apt upgrade -y
apt install -y curl wget unzip apt-transport-https ca-certificates gnupg lsb-release

echo "=== 2. Установка Docker ==="
if ! command -v docker &> /dev/null; then
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    REAL_USER="${SUDO_USER:-$USER}"
    if [ "$REAL_USER" = "root" ]; then
        echo "Ошибка: Не запускайте этот скрипт напрямую от root. Используйте sudo."
        exit 1
    fi

    if ! id -nG "$REAL_USER" | grep -qw docker; then
        echo "Добавляем пользователя $REAL_USER в группу docker..."
        usermod -aG docker "$REAL_USER"
        echo "✓ Пользователь добавлен в группу docker"
    fi
    
    systemctl enable --now docker
else
    echo "✓ Docker уже установлен."
fi

echo "=== 3. Установка Minikube ==="
if ! command -v minikube &> /dev/null; then
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    install minikube-linux-amd64 /usr/local/bin/minikube
    rm -f minikube-linux-amd64
    echo "✓ Minikube установлен"
else
    echo "✓ Minikube уже установлен"
fi

echo "=== 4. Установка kubectl ==="
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    install kubectl /usr/local/bin/kubectl
    rm -f kubectl
    echo "✓ kubectl установлен"
else
    echo "✓ kubectl уже установлен"
fi

echo "=== 5. Установка Helm ==="
if ! command -v helm &> /dev/null; then
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    echo "✓ Helm установлен"
else
    echo "✓ Helm уже установлен"
fi

REAL_USER="${SUDO_USER:-$USER}"

echo ""
echo "=========================================="
echo "СИСТЕМНАЯ ЧАСТЬ ЗАВЕРШЕНА"
echo "=========================================="
echo ""
echo "Теперь выполните следующие команды ОТ ИМЕНИ ОБЫЧНОГО ПОЛЬЗОВАТЕЛЯ ($REAL_USER):"
echo ""
echo "1. Обновите права группы docker в текущем терминале:"
echo "   newgrp docker"
echo ""
echo "2. Запустите Minikube:"
echo "   minikube start --driver=docker --memory=12288 --cpus=6"
echo ""
echo "3. Добавьте репозиторий Helm:"
echo "   helm repo add ertis https://ertis-research.github.io/Helm-charts/"
echo "   helm repo update"
echo ""
echo "4. Установите OpenTwins с persistent storage:"
cat << 'VALUES_HINT'
   cat > opentwins-values.yaml << 'EOF'
grafana:
  persistence:
    enabled: true
    size: 1Gi
EOF

   helm upgrade --install opentwins ertis/OpenTwins \
       --namespace opentwins \
       --create-namespace \
       -f opentwins-values.yaml \
       --wait \
       --timeout 20m
VALUES_HINT
echo ""
echo "5. Проверьте статус подов:"
echo "   kubectl get pods -n opentwins -w"
echo ""
echo "6. Получите URL сервисов:"
echo "   minikube service opentwins-grafana -n opentwins --url"
echo "   minikube service opentwins-ditto-nginx -n opentwins --url"
echo "   minikube service opentwins-ditto-extended-api -n opentwins --url"
echo ""
echo "7. Создайте политику безопасности (замените <DITTO_NGINX_URL> на фактический):"
cat << 'POLICY_HINT'
   curl -X PUT 'http://<DITTO_NGINX_URL>/api/2/policies/org.bakery:policy' \
     -u 'ditto:ditto' \
     -H 'Content-Type: application/json' \
     -d '{
    "entries": {
        "admin": {
            "subjects": { "nginx:ditto": { "type": "pre-authenticated" } },
            "resources": {
                "thing:/": { "grant": [ "READ","WRITE" ], "revoke": [] },
                "policy:/": { "grant": [ "READ","WRITE" ], "revoke": [] },
                "message:/": { "grant": [ "READ","WRITE" ], "revoke": [] }
            }
        }
    }
}'
POLICY_HINT
echo ""
echo "8. Зайдите в Grafana (логин: admin, пароль: admin) и настройте плагин OpenTwins:"
echo "   Administration -> Plugins -> OpenTwins -> Configuration"
echo "   - Eclipse Ditto URL: <адрес ditto-nginx>"
echo "   - Ditto Extended API URL: <адрес ditto-extended-api>"
echo "   - Username: ditto"
echo "   - Password: ditto"
echo "   - Default Policy ID: org.bakery:policy"
echo ""
echo "9. Установите демон автозапуска:"
echo "   bash install-opentwins-daemon.sh"
echo ""
echo "10. Установите Unity плагин (опционально):"
echo "    bash install-unity-plugin.sh"
echo ""
echo "=========================================="
