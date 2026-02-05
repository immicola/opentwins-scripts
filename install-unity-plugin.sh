#!/bin/bash
# install-unity-plugin.sh
# Устанавливает Unity плагин в Grafana (OpenTwins)
# Запускать от обычного пользователя (не root)

set -euo pipefail

NAMESPACE="opentwins"
PLUGIN_URL="https://github.com/ertis-research/grafana-panel-unity/releases/latest/download/ertis-unity-panel.zip"
TEMP_DIR=$(mktemp -d)

echo "=== Установка Unity плагина в Grafana ==="

# 1. Проверка что Grafana работает
echo "Проверка Grafana..."
GRAFANA_POD=$(kubectl get pod -n "$NAMESPACE" -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
if [ -z "$GRAFANA_POD" ]; then
    echo "ОШИБКА: Grafana pod не найден в namespace $NAMESPACE"
    exit 1
fi
echo "Найден pod: $GRAFANA_POD"

# 2. Скачивание плагина
echo "Скачивание плагина..."
cd "$TEMP_DIR"
wget -q "$PLUGIN_URL" -O ertis-unity-panel.zip
unzip -q ertis-unity-panel.zip

# 3. Копирование в Grafana
echo "Копирование плагина в Grafana..."
kubectl cp ./ertis-unity-panel "$NAMESPACE/$GRAFANA_POD:/var/lib/grafana/plugins/ertis-unity-panel"

# 4. Перезапуск Grafana
echo "Перезапуск Grafana..."
kubectl delete pod -n "$NAMESPACE" "$GRAFANA_POD"

echo "Ожидание готовности Grafana..."
kubectl wait --for=condition=ready pod -n "$NAMESPACE" -l app.kubernetes.io/name=grafana --timeout=120s

# 5. Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo "=== Unity плагин установлен! ==="
echo "Откройте Grafana → Add visualization → Unity"
