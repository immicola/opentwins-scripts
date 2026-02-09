# Добавление Unity WebGL билда в OpenTwins

## Подготовка

Убедитесь что у вас есть готовый Unity WebGL билд — папка с файлами:
- `index.html`
- `Build/` (содержит `.data`, `.wasm`, `.js` файлы)
- `TemplateData/`

---

## Шаг 1. Создание Docker-образа

В папке с Unity билдом (где лежит `index.html`) создайте два файла:

**Dockerfile:**
```dockerfile
FROM nginx:alpine
COPY default.conf /etc/nginx/conf.d/default.conf
COPY . /usr/share/nginx/html
```

**default.conf:**
```nginx
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
```

---

## Шаг 2. Сборка и загрузка в Minikube

```bash
# Собрать образ
docker build -t my-unity-game:v1 .

# Загрузить в Minikube (не нужен Docker Hub)
minikube image load my-unity-game:v1
```

---

## Шаг 3. Деплой в Kubernetes

Создайте файл `unity-k8s.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: unity-webgl
  namespace: opentwins
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
        image: my-unity-game:v1
        imagePullPolicy: Never    # Берём локальный образ
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: unity-webgl-svc
  namespace: opentwins
spec:
  type: NodePort
  selector:
    app: unity-webgl
  ports:
    - port: 80
      targetPort: 80
      nodePort: 32000
```

```bash
kubectl apply -f unity-k8s.yaml

# Проверка
kubectl get pods -n opentwins | grep unity
```

---

## Шаг 4. Проверка

```bash
# Узнать IP
minikube ip

# Открыть в браузере
# http://<MINIKUBE-IP>:32000
```

Если игра загрузилась — готово!

---

## Шаг 5. Подключение в Grafana

1. Откройте Grafana
2. Создайте новый дашборд → Add visualization → **Unity**
3. В URL укажите: `http://<MINIKUBE-IP>:32000`

---

## Обновление билда

При загрузке нового билда:

```bash
# Пересобрать образ с новым тегом
docker build -t my-unity-game:v2 .
minikube image load my-unity-game:v2

# Обновить деплоймент
kubectl set image deployment/unity-webgl unity-webgl=my-unity-game:v2 -n opentwins
```
