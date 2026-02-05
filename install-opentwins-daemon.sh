#!/bin/bash
# install-opentwins-daemon.sh
# Создаёт systemd user service для автозапуска OpenTwins
# Запускать от обычного пользователя (не root)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_BIN="$HOME/.local/bin"
USER_SYSTEMD="$HOME/.config/systemd/user"

echo "=== Установка OpenTwins Daemon ==="

# 1. Создание директорий
mkdir -p "$USER_BIN" "$USER_SYSTEMD"

# 2. Создание startup скрипта
cat > "$USER_BIN/opentwins-start.sh" << 'STARTUP_SCRIPT'
#!/bin/bash
# OpenTwins Startup Script

set -euo pipefail

# === Configuration ===
MONGODB_TIMEOUT=60s
EXTAPI_RESTART_DELAY=5
EXTAPI_TIMEOUT=60s
DOCKER_RETRIES=30

NAMESPACE="opentwins"
MINIKUBE="/usr/local/bin/minikube"
KUBECTL="/usr/local/bin/kubectl"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "=== Starting OpenTwins ==="

# 0. Wait for Docker
log "Waiting for Docker to be ready..."
for i in $(seq 1 $DOCKER_RETRIES); do
    if docker info &>/dev/null; then
        log "Docker is ready"
        break
    fi
    if [ $i -eq $DOCKER_RETRIES ]; then
        log "ERROR: Docker failed to become ready after $DOCKER_RETRIES attempts"
        exit 1
    fi
    log "Docker not ready, retrying in 2s... ($i/$DOCKER_RETRIES)"
    sleep 2
done

# 1. Start Minikube
log "Starting Minikube..."
$MINIKUBE start
log "Minikube started successfully"

# 2. Wait for MongoDB
log "Waiting for MongoDB to be ready (timeout: $MONGODB_TIMEOUT)..."
if ! $KUBECTL wait --for=condition=ready pod \
    -l app.kubernetes.io/name=mongodb \
    -n "$NAMESPACE" \
    --timeout="$MONGODB_TIMEOUT"; then
    log "ERROR: MongoDB failed to become ready within $MONGODB_TIMEOUT"
    exit 1
fi
log "MongoDB is ready"

# 3. Restart Extended API
log "Restarting Extended API pod..."
$KUBECTL delete pod -n "$NAMESPACE" -l app.kubernetes.io/name=opentwins-ditto-extended-api --ignore-not-found=true

# 4. Wait for Extended API
log "Waiting $EXTAPI_RESTART_DELAY seconds for pod recreation..."
sleep "$EXTAPI_RESTART_DELAY"

log "Waiting for Extended API to be ready (timeout: $EXTAPI_TIMEOUT)..."
if ! $KUBECTL wait --for=condition=ready pod \
    -l app.kubernetes.io/name=opentwins-ditto-extended-api \
    -n "$NAMESPACE" \
    --timeout="$EXTAPI_TIMEOUT"; then
    log "ERROR: Extended API failed to become ready within $EXTAPI_TIMEOUT"
    exit 1
fi
log "Extended API is ready"

log "=== OpenTwins started successfully ==="
$MINIKUBE service list -n "$NAMESPACE" 2>/dev/null || true
STARTUP_SCRIPT

chmod +x "$USER_BIN/opentwins-start.sh"
echo "✓ Создан $USER_BIN/opentwins-start.sh"

# 3. Создание stop скрипта
cat > "$USER_BIN/opentwins-stop.sh" << 'STOP_SCRIPT'
#!/bin/bash
set -euo pipefail
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Stopping OpenTwins..."
/usr/local/bin/minikube stop
echo "[$(date '+%Y-%m-%d %H:%M:%S')] OpenTwins stopped"
STOP_SCRIPT

chmod +x "$USER_BIN/opentwins-stop.sh"
echo "✓ Создан $USER_BIN/opentwins-stop.sh"

# 4. Создание systemd service
cat > "$USER_SYSTEMD/opentwins.service" << EOF
[Unit]
Description=OpenTwins (Minikube + Kubernetes pods)
After=docker.service
Wants=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=$USER_BIN/opentwins-start.sh
ExecStop=$USER_BIN/opentwins-stop.sh
TimeoutStartSec=600
TimeoutStopSec=120

Environment=HOME=$HOME
Environment=PATH=/usr/local/bin:/usr/bin:/bin
Environment=MINIKUBE_HOME=$HOME/.minikube

[Install]
WantedBy=default.target
EOF

echo "✓ Создан $USER_SYSTEMD/opentwins.service"

# 5. Включение сервиса
systemctl --user daemon-reload
systemctl --user enable opentwins.service
echo "✓ Сервис включён"

# 6. Включение linger (для работы без логина)
if command -v loginctl &>/dev/null; then
    sudo loginctl enable-linger "$USER" 2>/dev/null || echo "⚠ Выполните вручную: sudo loginctl enable-linger $USER"
fi

echo ""
echo "=== OpenTwins Daemon установлен! ==="
echo ""
echo "Команды управления:"
echo "  systemctl --user status opentwins   # статус"
echo "  systemctl --user start opentwins    # запуск"
echo "  systemctl --user stop opentwins     # остановка"
echo "  journalctl --user -u opentwins -f   # логи"
