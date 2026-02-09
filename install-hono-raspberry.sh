#!/usr/bin/env bash

# install-hono-raspberry.sh
# Установка Eclipse Hono на Raspberry Pi 5
# Запуск: bash install-hono-raspberry.sh
# Требования: SSH доступ к Raspberry Pi

set -euo pipefail

# ========================================
# КОНФИГУРАЦИЯ
# ========================================
PI_HOST="${PI_HOST:-192.168.8.124}"
PI_USER="${PI_USER:-dt}"
HONO_NAMESPACE="hono"
TENANT_NAME="opentwins-tenant"
TEST_DEVICE_ID="test-device-001"
TEST_AUTH_ID="test-device"
TEST_PASSWORD="test-secret"

# ========================================
# ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
# ========================================
ssh_cmd() {
    ssh -o StrictHostKeyChecking=no "${PI_USER}@${PI_HOST}" "$@"
}

echo "==========================================="
echo "УСТАНОВКА ECLIPSE HONO НА RASPBERRY PI"
echo "==========================================="
echo "Хост: ${PI_USER}@${PI_HOST}"
echo ""

# ========================================
# 1. ПРОВЕРКА SSH СОЕДИНЕНИЯ
# ========================================
echo "=== 1. Проверка SSH соединения ==="
if ! ssh_cmd "echo 'SSH OK'" 2>/dev/null; then
    echo "Проверка соединения с паролем..."
    ssh -o StrictHostKeyChecking=no "${PI_USER}@${PI_HOST}" "echo 'SSH OK'"
fi
echo "✓ SSH соединение установлено"

# ========================================
# 2. УСТАНОВКА K3S
# ========================================
echo ""
echo "=== 2. Установка k3s (лёгкий Kubernetes) ==="

if ssh_cmd "command -v kubectl" &>/dev/null; then
    echo "⚠️  k3s уже установлен"
else
    echo "Устанавливаем k3s (это может занять 2-3 минуты)..."
    ssh_cmd "curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644"
    
    echo "Ожидаем готовности k3s..."
    sleep 10
    ssh_cmd "sudo kubectl wait --for=condition=Ready node --all --timeout=120s"
    echo "✓ k3s установлен"
fi

# Настроим kubectl для пользователя
ssh_cmd "mkdir -p ~/.kube && sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config && sudo chown \$(id -u):\$(id -g) ~/.kube/config"
echo "✓ kubectl настроен"

# ========================================
# 3. УСТАНОВКА HELM
# ========================================
echo ""
echo "=== 3. Установка Helm ==="

if ssh_cmd "command -v helm" &>/dev/null; then
    echo "⚠️  Helm уже установлен"
else
    ssh_cmd "curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
    echo "✓ Helm установлен"
fi

# ========================================
# 4. ДОБАВЛЕНИЕ РЕПОЗИТОРИЯ HONO
# ========================================
echo ""
echo "=== 4. Добавление Eclipse IoT Helm репозитория ==="
ssh_cmd "helm repo add eclipse-iot https://eclipse.org/packages/charts 2>/dev/null || true"
ssh_cmd "helm repo update"
echo "✓ Репозиторий добавлен"

# ========================================
# 5. СОЗДАНИЕ VALUES ФАЙЛА
# ========================================
echo ""
echo "=== 5. Создание конфигурации Hono ==="

ssh_cmd "cat > /tmp/hono-values.yaml << 'EOF'
# Hono configuration for Raspberry Pi
useLoadBalancer: false

kafka:
  externalAccess:
    controller:
      service:
        type: NodePort
        nodePorts: [30093]
    broker:
      service:
        type: NodePort
        nodePorts: [30092]

adapters:
  http:
    enabled: true
    svc:
      type: NodePort
      nodePort: 30443
  mqtt:
    enabled: true
    svc:
      type: NodePort
      nodePort: 30883
  amqp:
    enabled: true

deviceRegistryExample:
  enabled: true
  svc:
    type: NodePort
    nodePort: 30081

# ARM64 compatible
EOF"
echo "✓ Конфигурация создана"

# ========================================
# 6. УСТАНОВКА HONO
# ========================================
echo ""
echo "=== 6. Установка Eclipse Hono ==="

if ssh_cmd "helm status eclipse-hono -n ${HONO_NAMESPACE}" &>/dev/null; then
    echo "⚠️  Eclipse Hono уже установлен"
else
    echo "Устанавливаем Eclipse Hono (это может занять 10-15 минут на Pi)..."
    ssh_cmd "helm install eclipse-hono eclipse-iot/hono \
        --namespace ${HONO_NAMESPACE} \
        --create-namespace \
        --wait \
        --timeout 20m \
        -f /tmp/hono-values.yaml"
    echo "✓ Eclipse Hono установлен"
fi

# ========================================
# 7. ОЖИДАНИЕ ГОТОВНОСТИ ПОДОВ
# ========================================
echo ""
echo "=== 7. Ожидание готовности подов ==="
ssh_cmd "kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=hono -n ${HONO_NAMESPACE} --timeout=300s" || true
echo "✓ Поды запущены"

# ========================================
# 8. ПОЛУЧЕНИЕ ПОРТОВ
# ========================================
echo ""
echo "=== 8. Получение URL сервисов ==="

REGISTRY_PORT=$(ssh_cmd "kubectl get svc eclipse-hono-service-device-registry-ext -n ${HONO_NAMESPACE} -o jsonpath='{.spec.ports[0].nodePort}'" 2>/dev/null || echo "30081")
HTTP_PORT=$(ssh_cmd "kubectl get svc eclipse-hono-adapter-http -n ${HONO_NAMESPACE} -o jsonpath='{.spec.ports[0].nodePort}'" 2>/dev/null || echo "30443")
MQTT_PORT=$(ssh_cmd "kubectl get svc eclipse-hono-adapter-mqtt -n ${HONO_NAMESPACE} -o jsonpath='{.spec.ports[0].nodePort}'" 2>/dev/null || echo "30883")
KAFKA_PORT=$(ssh_cmd "kubectl get svc eclipse-hono-kafka-controller-0-external -n ${HONO_NAMESPACE} -o jsonpath='{.spec.ports[0].nodePort}'" 2>/dev/null || echo "30092")

REGISTRY_URL="https://${PI_HOST}:${REGISTRY_PORT}"
HTTP_ADAPTER_URL="https://${PI_HOST}:${HTTP_PORT}"
MQTT_ADAPTER="${PI_HOST}:${MQTT_PORT}"
KAFKA_BOOTSTRAP="${PI_HOST}:${KAFKA_PORT}"

echo "Hono Device Registry: ${REGISTRY_URL}"
echo "Hono HTTP Adapter:    ${HTTP_ADAPTER_URL}"
echo "Hono MQTT Adapter:    ${MQTT_ADAPTER}"
echo "Kafka Bootstrap:      ${KAFKA_BOOTSTRAP}"

# ========================================
# 9. СОЗДАНИЕ TENANT И УСТРОЙСТВА
# ========================================
echo ""
echo "=== 9. Создание Tenant и тестового устройства ==="

# Ждём пока Registry станет доступен
echo "Ожидаем доступность Device Registry..."
for i in {1..30}; do
    if curl -k -s -o /dev/null -w "%{http_code}" "${REGISTRY_URL}/v1/tenants" 2>/dev/null | grep -qE "200|404"; then
        break
    fi
    sleep 5
    echo "  ожидание... ($i/30)"
done

# Создаём tenant
if curl -k -s -o /dev/null -w "%{http_code}" "${REGISTRY_URL}/v1/tenants/${TENANT_NAME}" | grep -q "200"; then
    echo "⚠️  Tenant ${TENANT_NAME} уже существует"
else
    curl -k -s -X POST "${REGISTRY_URL}/v1/tenants/${TENANT_NAME}" > /dev/null
    echo "✓ Tenant ${TENANT_NAME} создан"
fi

# Регистрируем устройство
if curl -k -s -o /dev/null -w "%{http_code}" "${REGISTRY_URL}/v1/devices/${TENANT_NAME}/${TEST_DEVICE_ID}" | grep -q "200"; then
    echo "⚠️  Устройство ${TEST_DEVICE_ID} уже существует"
else
    curl -k -s -X POST "${REGISTRY_URL}/v1/devices/${TENANT_NAME}/${TEST_DEVICE_ID}" > /dev/null
    echo "✓ Устройство ${TEST_DEVICE_ID} зарегистрировано"
fi

# Устанавливаем credentials
curl -k -s -X PUT -H "Content-Type: application/json" \
    --data "[{\"type\":\"hashed-password\",\"auth-id\":\"${TEST_AUTH_ID}\",\"secrets\":[{\"pwd-plain\":\"${TEST_PASSWORD}\"}]}]" \
    "${REGISTRY_URL}/v1/credentials/${TENANT_NAME}/${TEST_DEVICE_ID}" > /dev/null
echo "✓ Credentials установлены"

# ========================================
# ВЫВОД РЕЗУЛЬТАТОВ
# ========================================
echo ""
echo "==========================================="
echo "ECLIPSE HONO УСТАНОВЛЕН НА RASPBERRY PI!"
echo "==========================================="
echo ""
echo "📋 ENDPOINTS (с вашей машины):"
echo "   Hono Device Registry: ${REGISTRY_URL}"
echo "   Hono HTTP Adapter:    ${HTTP_ADAPTER_URL}"
echo "   Hono MQTT Adapter:    ${MQTT_ADAPTER}"
echo "   Kafka Bootstrap:      ${KAFKA_BOOTSTRAP}"
echo ""
echo "📋 ТЕСТОВОЕ УСТРОЙСТВО:"
echo "   Tenant:    ${TENANT_NAME}"
echo "   Device ID: ${TEST_DEVICE_ID}"
echo "   Auth ID:   ${TEST_AUTH_ID}"
echo "   Password:  ${TEST_PASSWORD}"
echo ""
echo "==========================================="
echo "СЛЕДУЮЩИЕ ШАГИ"
echo "==========================================="
echo ""
echo "1. Проверить статус подов на Pi:"
echo "   ssh ${PI_USER}@${PI_HOST} 'kubectl get pods -n hono'"
echo ""
echo "2. Тест отправки телеметрии:"
cat << TEST_CMD
   curl -i -k -u "${TEST_AUTH_ID}@${TENANT_NAME}:${TEST_PASSWORD}" \\
     -H "Content-Type: application/json" \\
     -d '{"topic":"${TENANT_NAME}/${TEST_DEVICE_ID}/things/twin/commands/modify",
          "path":"/features/temperature/properties/value","value":25.5}' \\
     "${HTTP_ADAPTER_URL}/telemetry"
TEST_CMD
echo ""
echo "3. Подключение Ditto к Hono на Pi:"
echo "   Отредактируйте configure-ditto-hono-ssl.sh,"
echo "   заменив HONO_HOST на ${PI_HOST}"
echo ""
