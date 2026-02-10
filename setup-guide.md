# Инструкция: Установка и удаление OpenTwins, Hono, Unity Plugin

---

# Установка

## 1. OpenTwins

```bash
helm repo add ertis https://ertis-research.github.io/Helm-charts/
helm repo update

cat > opentwins-values.yaml << 'EOF'
grafana:
  persistence:
    enabled: true
    size: 2Gi
  initChownData:
    enabled: false
  securityContext:
    runAsUser: 472
    runAsGroup: 472
    fsGroup: 472
EOF

minikube start --driver=docker --memory=12288 --cpus=6

helm upgrade --install opentwins ertis/OpenTwins \
    --namespace opentwins \
    --create-namespace \
    -f opentwins-values.yaml \
    --wait \
    --timeout 20m

# Ожидание MongoDB (Extended API крашится без неё)
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=mongodb -n opentwins --timeout=120s

# Перезапуск Extended API (он часто падает при первом старте)
kubectl delete pod -n opentwins -l app.kubernetes.io/name=opentwins-ditto-extended-api --ignore-not-found=true
sleep 5

# Опционально
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=opentwins-ditto-extended-api -n opentwins --timeout=60s

# Проверка подов
kubectl get pods -n opentwins
```

### Настройка Grafana

```bash
minikube service opentwins-grafana -n opentwins --url
```

Тут все должно быть настроено, просто проверьте что в Grafana у плагина OpenTwins во вкладке Policies имеются policy в поисковой строке.

- Логин: `admin` / `admin`
- Administration → Plugins → OpenTwins → Configuration:
  - **Eclipse Ditto URL**: `http://opentwins-ditto-nginx.opentwins.svc.cluster.local`
  - **Ditto Extended API URL**: `http://opentwins-ditto-extended-api.opentwins.svc.cluster.local:8080`
  - **Username**: `ditto`, **Password**: `ditto`

---

## 2. Unity Plugin (панель визуализации в Grafana)

```bash
bash install-unity-plugin.sh
```

---

## 3. Unity WebGL (деплой билда как контейнер)

```bash
# Первый деплой (указать путь к папке с index.html)
bash deploy-unity-webgl.sh /путь/к/папке/с/билдом

# Обновление билда
bash deploy-unity-webgl.sh /путь/к/новому/билду --update
```

После деплоя Unity будет доступен по адресу `http://<MINIKUBE-IP>:32000`.
Этот URL используется в Grafana Unity панели.

Подробнее: см. [deploy-unity-webgl.md](deploy-unity-webgl.md)

---

## 4. Eclipse Hono

```bash
bash install-hono.sh
```

Затем подключение Ditto ↔ Hono:

```bash
bash configure-ditto-hono-ssl.sh
```

---

## 5. Systemd-демон автозапуска

```bash
bash install-opentwins-daemon.sh
```

---

## 6. Финальная проверка

```bash
# Поды OpenTwins
kubectl get pods -n opentwins

# Поды Hono
kubectl get pods -n hono

# Helm-релизы
helm list -A

# Проверить демон
systemctl --user status opentwins
```

---
---

# Удаление

Удалять нужно в **обратном** порядке установки: демон → Hono → connections → Unity plugin → OpenTwins.

## 1. Отключение systemd-демона

```bash
systemctl --user stop opentwins
systemctl --user disable opentwins
rm ~/.config/systemd/user/opentwins.service
rm ~/.local/bin/opentwins-start.sh ~/.local/bin/opentwins-stop.sh
systemctl --user daemon-reload
```

---

## 2. Удаление Eclipse Hono

```bash
# Запускаем minikube (если остановлен)
minikube start

# Удаление helm-релиза
helm uninstall eclipse-hono -n hono

# Удаление PVC (данные Kafka, Zookeeper и т.д.)
kubectl delete pvc --all -n hono

# Удаление namespace
kubectl delete namespace hono
```

**Проверка:**
```bash
kubectl get all -n hono   # Должен быть пустой или "not found"
```

---

## 3. Удаление Hono-Ditto Connection

Если в Ditto создано соединение с Hono — удалите его:

```bash
DITTO_URL="http://$(minikube ip):$(kubectl get svc opentwins-ditto-nginx -n opentwins -o jsonpath='{.spec.ports[0].nodePort}')"

# Посмотреть все connections
curl -s "${DITTO_URL}/api/2/connections" -u "devops:foobar" | jq -r '.[].id'

# Удалить каждый connection (подставьте ID)
curl -X DELETE "${DITTO_URL}/api/2/connections/<CONNECTION_ID>" -u "devops:foobar"
```

---

## 4. Удаление Unity WebGL (контейнер)

```bash
kubectl delete deployment unity-webgl -n opentwins
kubectl delete service unity-webgl-svc -n opentwins
```

---

## 5. Удаление Unity Plugin (из Grafana)

```bash
GRAFANA_POD=$(kubectl get pod -n opentwins -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}')

# Удалить файлы плагина
kubectl exec -n opentwins "$GRAFANA_POD" -- rm -rf /var/lib/grafana/plugins/ertis-unity-panel

# Перезапустить Grafana
kubectl delete pod -n opentwins "$GRAFANA_POD"
kubectl wait --for=condition=ready pod -n opentwins -l app.kubernetes.io/name=grafana --timeout=120s
```

---

## 6. Удаление OpenTwins

```bash
# Удаление helm-релиза
helm uninstall opentwins -n opentwins

# Удаление PVC (данные MongoDB, Grafana и т.д.)
kubectl delete pvc --all -n opentwins

# Удаление namespace
kubectl delete namespace opentwins

# Удаление helm-репозиториев (опционально)
helm repo remove ertis
helm repo remove eclipse-iot
```

**Проверка:**
```bash
kubectl get all -n opentwins   # "not found"
kubectl get all -n hono        # "not found"
helm list -A                   # Не должно быть opentwins и eclipse-hono
```

---

## 7. (Опционально) Полный сброс Minikube

Если нужно начать совсем с нуля:

```bash
minikube delete
minikube start --driver=docker --memory=12288 --cpus=6
```
