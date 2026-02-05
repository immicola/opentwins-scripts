#!/bin/bash
# configure-ditto-hono-connection.sh
# Creates a connection from OpenTwins Ditto to Hono's Kafka

set -e

# Configuration
HONO_TENANT="opentwins-tenant"
DITTO_URL="http://192.168.49.2:30525"
DEVOPS_PWD="foobar"

# Kafka internal address (accessible within cluster)
KAFKA_BOOTSTRAP="eclipse-hono-kafka.hono.svc.cluster.local:9092"

# Get Kafka certificate
KAFKA_CERT=$(kubectl get secret eclipse-hono-kafka-example-keys -n hono -o jsonpath="{.data.tls\.crt}" | base64 --decode | tr -d '\n' | sed 's/E-----/E-----\\n/g' | sed 's/-----END/\\n-----END/g')

echo "Creating Hono connection in Ditto for tenant: $HONO_TENANT"

# Create Hono connection (Kafka-based)
curl -X POST "${DITTO_URL}/api/2/connections" \
  -u "devops:${DEVOPS_PWD}" \
  -H "Content-Type: application/json" \
  -d '{
    "connectionType": "kafka",
    "connectionStatus": "open",
    "uri": "ssl://hono:hono-secret@eclipse-hono-kafka.hono.svc.cluster.local:9092",
    "specificConfig": {
      "bootstrapServers": "eclipse-hono-kafka.hono.svc.cluster.local:9092",
      "saslMechanism": "scram-sha-512"
    },
    "sources": [
      {
        "addresses": ["hono.telemetry.'${HONO_TENANT}'"],
        "consumerCount": 1,
        "authorizationContext": ["nginx:ditto"],
        "qos": 0,
        "enforcement": {
          "input": "{{ header:device_id }}",
          "filters": ["{{ entity:id }}"]
        },
        "headerMapping": {},
        "payloadMapping": ["Ditto"],
        "replyTarget": {
          "enabled": true,
          "address": "hono.command.'${HONO_TENANT}'/{{ thing:id }}",
          "headerMapping": {
            "device_id": "{{ thing:id }}",
            "subject": "{{ header:subject | fn:default(topic:action-subject) | fn:default(topic:criterion) }}-response",
            "correlation-id": "{{ header:correlation-id }}"
          },
          "expectedResponseTypes": ["response", "error"]
        },
        "acknowledgementRequests": {
          "includes": []
        }
      },
      {
        "addresses": ["hono.event.'${HONO_TENANT}'"],
        "consumerCount": 1,
        "authorizationContext": ["nginx:ditto"],
        "qos": 1,
        "enforcement": {
          "input": "{{ header:device_id }}",
          "filters": ["{{ entity:id }}"]
        },
        "headerMapping": {},
        "payloadMapping": ["Ditto"],
        "replyTarget": {
          "enabled": true,
          "address": "hono.command.'${HONO_TENANT}'/{{ thing:id }}",
          "headerMapping": {
            "device_id": "{{ thing:id }}",
            "subject": "{{ header:subject | fn:default(topic:action-subject) | fn:default(topic:criterion) }}-response",
            "correlation-id": "{{ header:correlation-id }}"
          },
          "expectedResponseTypes": ["response", "error"]
        },
        "acknowledgementRequests": {
          "includes": []
        }
      }
    ],
    "targets": [
      {
        "address": "hono.command.'${HONO_TENANT}'/{{ thing:id }}",
        "topics": [
          "_/_/things/live/commands",
          "_/_/things/live/messages"
        ],
        "authorizationContext": ["nginx:ditto"],
        "headerMapping": {
          "device_id": "{{ thing:id }}",
          "subject": "{{ header:subject | fn:default(topic:action-subject) }}",
          "correlation-id": "{{ header:correlation-id }}"
        }
      }
    ],
    "ca": "'"${KAFKA_CERT}"'",
    "validateCertificates": true
  }'

echo ""
echo "Done! Connection created."
