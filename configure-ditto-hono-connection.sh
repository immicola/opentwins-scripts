#!/bin/bash
# configure-ditto-hono-connection.sh
# Creates a connection from OpenTwins Ditto to Hono's Kafka
# Uses internal cluster networking with SASL PLAIN authentication

set -e

# Configuration
HONO_TENANT="opentwins-tenant"
DITTO_URL="http://192.168.49.2:30525"
DEVOPS_PWD="foobar"

# Kafka internal address - using INTERNAL listener (port 9094 = SASL_PLAINTEXT)
# Note: Port 9092 uses SASL_SSL which requires certificates
KAFKA_BOOTSTRAP="eclipse-hono-kafka-controller-0.eclipse-hono-kafka-controller-headless.hono.svc.cluster.local:9094"

echo "Creating Hono Kafka connection in Ditto for tenant: $HONO_TENANT"
echo "Using internal Kafka bootstrap: $KAFKA_BOOTSTRAP"

# Create Hono connection (Kafka-based with SASL PLAIN over TCP)
curl -X POST "${DITTO_URL}/api/2/connections" \
  -u "devops:${DEVOPS_PWD}" \
  -H "Content-Type: application/json" \
  --max-time 60 \
  -d '{
    "name": "hono-kafka-connection",
    "connectionType": "kafka",
    "connectionStatus": "open",
    "uri": "tcp://hono:hono-secret@eclipse-hono-kafka-controller-0.eclipse-hono-kafka-controller-headless.hono.svc.cluster.local:9094",
    "specificConfig": {
      "bootstrapServers": "eclipse-hono-kafka-controller-0.eclipse-hono-kafka-controller-headless.hono.svc.cluster.local:9094",
      "saslMechanism": "plain"
    },
    "sources": [
      {
        "addresses": ["hono.telemetry.'${HONO_TENANT}'"],
        "consumerCount": 1,
        "authorizationContext": ["nginx:ditto"],
        "qos": 0,
        "enforcement": {
          "input": "'${HONO_TENANT}':{{ header:device_id }}",
          "filters": ["{{ entity:id }}"]
        },
        "payloadMapping": ["Ditto"]
      },
      {
        "addresses": ["hono.event.'${HONO_TENANT}'"],
        "consumerCount": 1,
        "authorizationContext": ["nginx:ditto"],
        "qos": 1,
        "enforcement": {
          "input": "'${HONO_TENANT}':{{ header:device_id }}",
          "filters": ["{{ entity:id }}"]
        },
        "payloadMapping": ["Ditto"]
      }
    ],
    "targets": []
  }'

echo ""
echo "Done! Connection created."
echo ""
echo "Test telemetry with:"
echo "curl -i -k -u \"test-device@opentwins-tenant:test-secret\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{\"topic\":\"opentwins-tenant/test-device-001/things/twin/commands/modify\",\"path\":\"/features/temperature/properties/value\",\"value\":42.5}' \\"
echo "  \"https://192.168.49.2:30443/telemetry\""
