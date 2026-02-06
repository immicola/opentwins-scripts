#!/bin/bash
# configure-ditto-hono-ssl.sh
# Creates SSL-encrypted Kafka connection from Ditto to Hono
# Uses self-signed CA certificate for validation

set -e

HONO_TENANT="opentwins-tenant"
DITTO_URL="http://192.168.49.2:30525"
DEVOPS_PWD="foobar"
CONNECTION_NAME="hono-kafka-ssl-connection"

# SSL listener (CLIENT) on port 9092
# Cross-namespace: opentwins → hono
KAFKA_BOOTSTRAP="eclipse-hono-kafka-controller-0.eclipse-hono-kafka-controller-headless.hono.svc.cluster.local:9092"

echo "=== Ditto-Hono SSL Connection Setup ==="
echo "Tenant: $HONO_TENANT"
echo "Kafka:  $KAFKA_BOOTSTRAP (SSL)"

# Extract CA certificate and escape newlines for JSON
echo "Extracting CA certificate from Kubernetes secret..."
CA_CERT=$(kubectl get secret eclipse-hono-kafka-example-keys -n hono \
  -o jsonpath="{.data.ca\.crt}" | base64 --decode | awk '{printf "%s\\n", $0}')

if [ -z "$CA_CERT" ]; then
  echo "ERROR: Failed to extract CA certificate"
  exit 1
fi
echo "CA certificate extracted successfully"

# Delete existing connection if present
echo "Checking for existing connection..."
curl -s -X DELETE "${DITTO_URL}/api/2/connections/${CONNECTION_NAME}" \
  -u "devops:${DEVOPS_PWD}" 2>/dev/null || true

# Create connection JSON
cat <<EOF > /tmp/hono-ssl-connection.json
{
  "name": "${CONNECTION_NAME}",
  "connectionType": "kafka",
  "connectionStatus": "open",
  "uri": "ssl://hono:hono-secret@${KAFKA_BOOTSTRAP}",
  "ca": "${CA_CERT}",
  "validateCertificates": true,
  "specificConfig": {
    "bootstrapServers": "${KAFKA_BOOTSTRAP}",
    "saslMechanism": "plain"
  },
  "sources": [
    {
      "addresses": ["hono.telemetry.${HONO_TENANT}"],
      "consumerCount": 1,
      "authorizationContext": ["nginx:ditto"],
      "qos": 0,
      "enforcement": {
        "input": "${HONO_TENANT}:{{ header:device_id }}",
        "filters": ["{{ entity:id }}"]
      },
      "payloadMapping": ["Ditto"]
    },
    {
      "addresses": ["hono.event.${HONO_TENANT}"],
      "consumerCount": 1,
      "authorizationContext": ["nginx:ditto"],
      "qos": 1,
      "enforcement": {
        "input": "${HONO_TENANT}:{{ header:device_id }}",
        "filters": ["{{ entity:id }}"]
      },
      "payloadMapping": ["Ditto"]
    }
  ],
  "targets": []
}
EOF

echo "Creating SSL connection..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${DITTO_URL}/api/2/connections" \
  -u "devops:${DEVOPS_PWD}" \
  -H "Content-Type: application/json" \
  --max-time 60 \
  -d @/tmp/hono-ssl-connection.json)

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
  echo "✅ SSL connection created successfully!"
  echo ""
  echo "Verifying connection status..."
  sleep 2
  curl -s "${DITTO_URL}/api/2/connections/${CONNECTION_NAME}/status" \
    -u "devops:${DEVOPS_PWD}" | jq -r '.liveStatus // .connectionStatus // "unknown"'
else
  echo "❌ Failed to create connection (HTTP $HTTP_CODE)"
  echo "$BODY" | jq . 2>/dev/null || echo "$BODY"
  exit 1
fi

rm -f /tmp/hono-ssl-connection.json
echo ""
echo "Done!"
