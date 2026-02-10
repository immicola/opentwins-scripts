#!/bin/bash
# deploy-unity-webgl.sh
# Деплоит Unity WebGL билд в OpenTwins (Minikube)
# Использование: bash deploy-unity-webgl.sh /путь/к/папке/с/index.html
# Для обновления: bash deploy-unity-webgl.sh /путь/к/папке/с/index.html --update

set -euo pipefail

NAMESPACE="opentwins"
IMAGE_NAME="unity-webgl"
NODE_PORT=32000

# === Проверка аргументов ===
if [ $# -lt 1 ]; then
    echo "Использование: $0 <путь_к_папке_с_билдом> [--update]"
    echo "  Папка должна содержать index.html, Build/ и TemplateData/"
    echo ""
    echo "Примеры:"
    echo "  $0 ~/my-game/Build        # Первый деплой"
    echo "  $0 ~/my-game/Build --update  # Обновление билда"
    exit 1
fi

BUILD_DIR="$1"
UPDATE_MODE=false
if [ "${2:-}" = "--update" ]; then
    UPDATE_MODE=true
fi

# === Проверка папки ===
if [ ! -f "$BUILD_DIR/index.html" ]; then
    echo "ОШИБКА: index.html не найден в $BUILD_DIR"
    exit 1
fi

echo "=== Деплой Unity WebGL ==="
echo "Папка билда: $BUILD_DIR"

# === Генерация версии (timestamp) ===
VERSION="v$(date +%Y%m%d%H%M%S)"
IMAGE_TAG="${IMAGE_NAME}:${VERSION}"
echo "Образ: $IMAGE_TAG"

# === Создание временных файлов для Docker ===
TEMP_DIR=$(mktemp -d)

cat > "$TEMP_DIR/Dockerfile" << 'DOCKERFILE'
FROM nginx:alpine
COPY default.conf /etc/nginx/conf.d/default.conf
COPY build/ /usr/share/nginx/html/
DOCKERFILE

cat > "$TEMP_DIR/default.conf" << 'NGINXCONF'
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    add_header Access-Control-Allow-Origin *;

    location ~ .+\.(data|symbols\.json)\.br$ {
        gzip off;
        add_header Content-Encoding br;
        default_type application/octet-stream;
    }
    location ~ .+\.js\.br$ {
        gzip off;
        add_header Content-Encoding br;
        default_type application/javascript;
    }
    location ~ .+\.wasm\.br$ {
        gzip off;
        add_header Content-Encoding br;
        default_type application/wasm;
    }
    location / {
        try_files $uri $uri/ /index.html;
    }
}
NGINXCONF

# Копируем билд во временную папку
cp -r "$BUILD_DIR" "$TEMP_DIR/build"

# === Сборка Docker образа ===
echo "Сборка Docker образа..."
docker build -t "$IMAGE_TAG" "$TEMP_DIR"

# === Загрузка в Minikube ===
echo "Загрузка образа в Minikube..."
minikube image load "$IMAGE_TAG"

if [ "$UPDATE_MODE" = true ]; then
    # === Обновление существующего деплоймента ===
    echo "Обновление деплоймента..."
    kubectl set image deployment/unity-webgl unity-webgl="$IMAGE_TAG" -n "$NAMESPACE"
    kubectl rollout status deployment/unity-webgl -n "$NAMESPACE" --timeout=60s
else
    # === Создание деплоймента и сервиса ===
    echo "Создание Kubernetes ресурсов..."

    kubectl apply -f - << YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: unity-webgl
  namespace: $NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: unity-webgl
  template:
    metadata:
      labels:
        app: unity-webgl
    spec:
      containers:
      - name: unity-webgl
        image: $IMAGE_TAG
        imagePullPolicy: Never
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: unity-webgl-svc
  namespace: $NAMESPACE
spec:
  type: NodePort
  selector:
    app: unity-webgl
  ports:
    - port: 80
      targetPort: 80
      nodePort: $NODE_PORT
YAML

    echo "Ожидание готовности..."
    kubectl wait --for=condition=ready pod -n "$NAMESPACE" -l app=unity-webgl --timeout=60s
fi

# === Cleanup ===
rm -rf "$TEMP_DIR"

# === Результат ===
MINIKUBE_IP=$(minikube ip)
echo ""
echo "=== Unity WebGL задеплоен! ==="
echo "URL: http://${MINIKUBE_IP}:${NODE_PORT}"
echo ""
echo "Для Grafana Unity панели используйте этот URL"
