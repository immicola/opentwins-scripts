#!/usr/bin/env bash

# install-hono.sh
# Установка Eclipse Hono для интеграции с OpenTwins
# Запускать после установки OpenTwins: bash install-hono.sh
# Требования: OpenTwins должен быть установлен и работать

set -euo pipefail

# ========================================
# КОНФИГУРАЦИЯ
# ========================================
HONO_NAMESPACE="hono"
TENANT_NAME="opentwins-tenant"
TEST_DEVICE_ID="test-device-001"
TEST_AUTH_ID="test-device"
TEST_PASSWORD="test-secret"

# ========================================
# ПРОВЕРКА ЗАВИСИМОСТЕЙ
# ========================================
echo "=== 1. Проверка зависимостей ==="

if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl не найден. Установите kubectl."
    exit 1
fi

if ! command -v helm &> /dev/null; then
    echo "❌ helm не найден. Установите helm."
    exit 1
fi

if ! kubectl get namespace opentwins &> /dev/null; then
    echo "❌ Namespace opentwins не найден. Сначала установите OpenTwins."
    exit 1
fi

echo "✓ Все зависимости найдены"

# ========================================
# ДОБАВЛЕНИЕ HELM РЕПОЗИТОРИЯ
# ========================================
echo ""
echo "=== 2. Добавление Eclipse IoT Helm репозитория ==="
helm repo add eclipse-iot https://eclipse.org/packages/charts 2>/dev/null || true
helm repo update
echo "✓ Репозиторий добавлен"

# ========================================
# СОЗДАНИЕ VALUES ФАЙЛА
# ========================================
echo ""
echo "=== 3. Создание конфигурации Hono ==="

cat > /tmp/hono-values.yaml << 'EOF'
# Hono configuration for OpenTwins integration
useLoadBalancer: false

kafka:
  externalAccess:
    controller:
      service:
        type: NodePort
    broker:
      service:
        type: NodePort

adapters:
  http:
    enabled: true
  mqtt:
    enabled: true
  amqp:
    enabled: true

deviceRegistryExample:
  enabled: true
EOF

echo "✓ Конфигурация создана"

# ========================================
# УСТАНОВКА HONO
# ========================================
echo ""
echo "=== 4. Установка Eclipse Hono ==="

if helm status eclipse-hono -n ${HONO_NAMESPACE} &> /dev/null; then
    echo "⚠️  Eclipse Hono уже установлен. Пропускаем установку."
else
    echo "Устанавливаем Eclipse Hono (это может занять 5-10 минут)..."
    helm install eclipse-hono eclipse-iot/hono \
        --namespace ${HONO_NAMESPACE} \
        --create-namespace \
        --wait \
        --timeout 15m \
        -f /tmp/hono-values.yaml
    echo "✓ Eclipse Hono установлен"
fi

# ========================================
# ОЖИДАНИЕ ГОТОВНОСТИ ПОДОВ
# ========================================
echo ""
echo "=== 5. Ожидание готовности подов ==="
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=hono -n ${HONO_NAMESPACE} --timeout=300s
echo "✓ Все поды готовы"

# ========================================
# ПОЛУЧЕНИЕ URL СЕРВИСОВ
# ========================================
echo ""
echo "=== 6. Получение URL сервисов ==="

MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "localhost")
REGISTRY_PORT=$(kubectl get svc eclipse-hono-service-device-registry-ext -n ${HONO_NAMESPACE} -o jsonpath='{.spec.ports[0].nodePort}')
HTTP_PORT=$(kubectl get svc eclipse-hono-adapter-http -n ${HONO_NAMESPACE} -o jsonpath='{.spec.ports[0].nodePort}')
MQTT_PORT=$(kubectl get svc eclipse-hono-adapter-mqtt -n ${HONO_NAMESPACE} -o jsonpath='{.spec.ports[0].nodePort}')
DITTO_PORT=$(kubectl get svc opentwins-ditto-nginx -n opentwins -o jsonpath='{.spec.ports[0].nodePort}')

REGISTRY_URL="https://${MINIKUBE_IP}:${REGISTRY_PORT}"
HTTP_ADAPTER_URL="https://${MINIKUBE_IP}:${HTTP_PORT}"
MQTT_ADAPTER="${MINIKUBE_IP}:${MQTT_PORT}"
DITTO_URL="http://${MINIKUBE_IP}:${DITTO_PORT}"

echo "Hono Device Registry: ${REGISTRY_URL}"
echo "Hono HTTP Adapter:    ${HTTP_ADAPTER_URL}"
echo "Hono MQTT Adapter:    ${MQTT_ADAPTER}"
echo "Ditto API:            ${DITTO_URL}"

# ========================================
# СОЗДАНИЕ TENANT И УСТРОЙСТВА
# ========================================
echo ""
echo "=== 7. Создание Tenant и тестового устройства ==="

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
# ВЫВОД ИНСТРУКЦИЙ
# ========================================
echo ""
echo "=========================================="
echo "ECLIPSE HONO УСТАНОВЛЕН УСПЕШНО!"
echo "=========================================="
echo ""
echo "📋 ENDPOINTS:"
echo "   Hono Device Registry: ${REGISTRY_URL}"
echo "   Hono HTTP Adapter:    ${HTTP_ADAPTER_URL}"
echo "   Hono MQTT Adapter:    ${MQTT_ADAPTER}"
echo "   Ditto API:            ${DITTO_URL}"
echo ""
echo "📋 ТЕСТОВОЕ УСТРОЙСТВО:"
echo "   Tenant:    ${TENANT_NAME}"
echo "   Device ID: ${TEST_DEVICE_ID}"
echo "   Auth ID:   ${TEST_AUTH_ID}"
echo "   Password:  ${TEST_PASSWORD}"
echo ""
echo "=========================================="
echo "СЛЕДУЮЩИЕ ШАГИ: ПОДКЛЮЧЕНИЕ DITTO К HONO"
echo "=========================================="
echo ""
echo "1. Создайте Policy в Ditto:"
cat << POLICY_CMD
   curl -X PUT "${DITTO_URL}/api/2/policies/${TENANT_NAME}:${TEST_DEVICE_ID}" \\
     -u "ditto:ditto" \\
     -H "Content-Type: application/json" \\
     -d '{
       "entries": {
         "admin": {
           "subjects": {"nginx:ditto": {"type": "pre-authenticated"}},
           "resources": {
             "thing:/": {"grant": ["READ","WRITE"], "revoke": []},
             "policy:/": {"grant": ["READ","WRITE"], "revoke": []},
             "message:/": {"grant": ["READ","WRITE"], "revoke": []}
           }
         }
       }
     }'
POLICY_CMD
echo ""
echo "2. Создайте Thing (Digital Twin) в Ditto:"
cat << THING_CMD
   curl -X PUT "${DITTO_URL}/api/2/things/${TENANT_NAME}:${TEST_DEVICE_ID}" \\
     -u "ditto:ditto" \\
     -H "Content-Type: application/json" \\
     -d '{
       "policyId": "${TENANT_NAME}:${TEST_DEVICE_ID}",
       "attributes": {"manufacturer": "Test"},
       "features": {"temperature": {"properties": {"value": null}}}
     }'
THING_CMD
echo ""
echo "3. Создайте Hono Connection в Ditto (запустите скрипт):"
echo "   bash configure-ditto-hono-connection.sh"
echo ""
echo "4. Отправьте тестовую телеметрию через HTTP:"
cat << TEST_CMD
   curl -i -k -u "${TEST_AUTH_ID}@${TENANT_NAME}:${TEST_PASSWORD}" \\
     -H "Content-Type: application/json" \\
     -d '{"topic":"${TENANT_NAME}/${TEST_DEVICE_ID}/things/twin/commands/modify",
          "path":"/features/temperature/properties/value","value":25.5}' \\
     "${HTTP_ADAPTER_URL}/telemetry"
TEST_CMD
echo ""
echo "5. Отправьте тестовую телеметрию через MQTT:"
cat << MQTT_CMD
   mosquitto_pub -h ${MINIKUBE_IP} -p ${MQTT_PORT} \\
     -u "${TEST_AUTH_ID}@${TENANT_NAME}" -P "${TEST_PASSWORD}" \\
     --insecure -t telemetry \\
     -m '{"topic":"${TENANT_NAME}/${TEST_DEVICE_ID}/things/twin/commands/modify",
          "path":"/features/temperature/properties/value","value":30.0}'
MQTT_CMD
echo ""
echo "6. Проверьте Thing в Ditto:"
echo "   curl -s \"${DITTO_URL}/api/2/things/${TENANT_NAME}:${TEST_DEVICE_ID}\" -u \"ditto:ditto\" | jq ."
echo ""
echo "=========================================="
echo "ПРОВЕРКА УСТАНОВКИ"
echo "=========================================="
echo "   kubectl get pods -n hono"
echo "   kubectl get svc -n hono"
echo ""
