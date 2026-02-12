# Создание устройств в Eclipse Ditto

## Переменные

```bash
DITTO_URL="http://192.168.49.2:30525"
TENANT="gold-sapa-tenant"
```

---

## Общая Policy для всех счётчиков

```bash
curl -X PUT "${DITTO_URL}/api/2/policies/${TENANT}:all-meters" \
  -u "ditto:ditto" -H "Content-Type: application/json" \
  -d '{
    "entries": {
      "admin": {
        "subjects": {"nginx:ditto": {"type": "pre-authenticated"}},
        "resources": {
          "thing:/":   {"grant": ["READ","WRITE"], "revoke": []},
          "policy:/":  {"grant": ["READ","WRITE"], "revoke": []},
          "message:/": {"grant": ["READ","WRITE"], "revoke": []}
        }
      }
    }
  }'
```

---

## Однофазные счётчики (Orman)

Параметры: `voltage_v`, `frequency_hz`, `power_factor`, `total_energy_kwh`, `reactive_energy_var`, `status`

### 1. Лед 1 — ESP32_Orman_Meter_044631

```bash
curl -X PUT "${DITTO_URL}/api/2/things/${TENANT}:ESP32-Orman-Meter-044631" \
  -u "ditto:ditto" -H "Content-Type: application/json" \
  -d '{
    "policyId": "gold-sapa-tenant:all-meters",
    "attributes": {
      "name": "Лед 1",
      "deviceId": "ESP32_Orman_Meter_044631",
      "meterType": "single-phase",
      "location": "Shop Floor",
      "_isType": false
    },
    "features": {
      "measurements": {
        "properties": {
          "voltage_v": 0.0,
          "frequency_hz": 50.0,
          "power_factor": 0.0,
          "total_energy_kwh": 0.0,
          "reactive_energy_var": 0.0,
          "status": "offline"
        }
      }
    }
  }'
```

### 2. Лед 2 — ESP32_Orman_Meter_044890

```bash
curl -X PUT "${DITTO_URL}/api/2/things/${TENANT}:ESP32-Orman-Meter-044890" \
  -u "ditto:ditto" -H "Content-Type: application/json" \
  -d '{
    "policyId": "gold-sapa-tenant:all-meters",
    "attributes": {
      "name": "Лед 2",
      "deviceId": "ESP32_Orman_Meter_044890",
      "meterType": "single-phase",
      "location": "Shop Floor",
      "_isType": false
    },
    "features": {
      "measurements": {
        "properties": {
          "voltage_v": 0.0,
          "frequency_hz": 50.0,
          "power_factor": 0.0,
          "total_energy_kwh": 0.0,
          "reactive_energy_var": 0.0,
          "status": "offline"
        }
      }
    }
  }'
```

---

## Трёхфазные счётчики (Dala)

Параметры: `voltage_a_v`, `voltage_b_v`, `voltage_c_v`, `current_a_a`, `current_b_a`, `current_c_a`, `active_power_w`, `power_factor_total`, `frequency_hz`, `active_energy_positive_kwh`, `active_energy_negative_kwh`, `reactive_energy_positive_varh`, `reactive_energy_negative_varh`, `status`

### 3. Миксер 1 — ESP32_Dala_Meter_001990

```bash
curl -X PUT "${DITTO_URL}/api/2/things/${TENANT}:ESP32-Dala-Meter-001990" \
  -u "ditto:ditto" -H "Content-Type: application/json" \
  -d '{
    "policyId": "gold-sapa-tenant:all-meters",
    "attributes": {
      "name": "Миксер 1",
      "deviceId": "ESP32_Dala_Meter_001990",
      "meterType": "three-phase",
      "location": "Shop Floor",
      "_isType": false
    },
    "features": {
      "measurements": {
        "properties": {
          "voltage_a_v": 0.0,
          "voltage_b_v": 0.0,
          "voltage_c_v": 0.0,
          "current_a_a": 0.0,
          "current_b_a": 0.0,
          "current_c_a": 0.0,
          "active_power_w": 0.0,
          "power_factor_total": 0.0,
          "frequency_hz": 50.0,
          "active_energy_positive_kwh": 0.0,
          "active_energy_negative_kwh": 0.0,
          "reactive_energy_positive_varh": 0.0,
          "reactive_energy_negative_varh": 0.0,
          "status": "offline"
        }
      }
    }
  }'
```

### 4. Миксер 2 — ESP32_Dala_Meter_002006

```bash
curl -X PUT "${DITTO_URL}/api/2/things/${TENANT}:ESP32-Dala-Meter-002006" \
  -u "ditto:ditto" -H "Content-Type: application/json" \
  -d '{
    "policyId": "gold-sapa-tenant:all-meters",
    "attributes": {
      "name": "Миксер 2",
      "deviceId": "ESP32_Dala_Meter_002006",
      "meterType": "three-phase",
      "location": "Shop Floor",
      "_isType": false
    },
    "features": {
      "measurements": {
        "properties": {
          "voltage_a_v": 0.0,
          "voltage_b_v": 0.0,
          "voltage_c_v": 0.0,
          "current_a_a": 0.0,
          "current_b_a": 0.0,
          "current_c_a": 0.0,
          "active_power_w": 0.0,
          "power_factor_total": 0.0,
          "frequency_hz": 50.0,
          "active_energy_positive_kwh": 0.0,
          "active_energy_negative_kwh": 0.0,
          "reactive_energy_positive_varh": 0.0,
          "reactive_energy_negative_varh": 0.0,
          "status": "offline"
        }
      }
    }
  }'
```

### 5. Формовка — ESP32_Dala_Meter_002003

```bash
curl -X PUT "${DITTO_URL}/api/2/things/${TENANT}:ESP32-Dala-Meter-002003" \
  -u "ditto:ditto" -H "Content-Type: application/json" \
  -d '{
    "policyId": "gold-sapa-tenant:all-meters",
    "attributes": {
      "name": "Формовка",
      "deviceId": "ESP32_Dala_Meter_002003",
      "meterType": "three-phase",
      "location": "Shop Floor",
      "_isType": false
    },
    "features": {
      "measurements": {
        "properties": {
          "voltage_a_v": 0.0,
          "voltage_b_v": 0.0,
          "voltage_c_v": 0.0,
          "current_a_a": 0.0,
          "current_b_a": 0.0,
          "current_c_a": 0.0,
          "active_power_w": 0.0,
          "power_factor_total": 0.0,
          "frequency_hz": 50.0,
          "active_energy_positive_kwh": 0.0,
          "active_energy_negative_kwh": 0.0,
          "reactive_energy_positive_varh": 0.0,
          "reactive_energy_negative_varh": 0.0,
          "status": "offline"
        }
      }
    }
  }'
```

### 6. Расстойка 1 — ESP32_Dala_Meter_002004

```bash
curl -X PUT "${DITTO_URL}/api/2/things/${TENANT}:ESP32-Dala-Meter-002004" \
  -u "ditto:ditto" -H "Content-Type: application/json" \
  -d '{
    "policyId": "gold-sapa-tenant:all-meters",
    "attributes": {
      "name": "Расстойка 1",
      "deviceId": "ESP32_Dala_Meter_002004",
      "meterType": "three-phase",
      "location": "Shop Floor",
      "_isType": false
    },
    "features": {
      "measurements": {
        "properties": {
          "voltage_a_v": 0.0,
          "voltage_b_v": 0.0,
          "voltage_c_v": 0.0,
          "current_a_a": 0.0,
          "current_b_a": 0.0,
          "current_c_a": 0.0,
          "active_power_w": 0.0,
          "power_factor_total": 0.0,
          "frequency_hz": 50.0,
          "active_energy_positive_kwh": 0.0,
          "active_energy_negative_kwh": 0.0,
          "reactive_energy_positive_varh": 0.0,
          "reactive_energy_negative_varh": 0.0,
          "status": "offline"
        }
      }
    }
  }'
```

### 7. Расстойка 2 — ESP32_Dala_Meter_002024

```bash
curl -X PUT "${DITTO_URL}/api/2/things/${TENANT}:ESP32-Dala-Meter-002024" \
  -u "ditto:ditto" -H "Content-Type: application/json" \
  -d '{
    "policyId": "gold-sapa-tenant:all-meters",
    "attributes": {
      "name": "Расстойка 2",
      "deviceId": "ESP32_Dala_Meter_002024",
      "meterType": "three-phase",
      "location": "Shop Floor",
      "_isType": false
    },
    "features": {
      "measurements": {
        "properties": {
          "voltage_a_v": 0.0,
          "voltage_b_v": 0.0,
          "voltage_c_v": 0.0,
          "current_a_a": 0.0,
          "current_b_a": 0.0,
          "current_c_a": 0.0,
          "active_power_w": 0.0,
          "power_factor_total": 0.0,
          "frequency_hz": 50.0,
          "active_energy_positive_kwh": 0.0,
          "active_energy_negative_kwh": 0.0,
          "reactive_energy_positive_varh": 0.0,
          "reactive_energy_negative_varh": 0.0,
          "status": "offline"
        }
      }
    }
  }'
```

### 8. WACHTEL COL — ESP32_Dala_Meter_007085

```bash
curl -X PUT "${DITTO_URL}/api/2/things/${TENANT}:ESP32-Dala-Meter-007085" \
  -u "ditto:ditto" -H "Content-Type: application/json" \
  -d '{
    "policyId": "gold-sapa-tenant:all-meters",
    "attributes": {
      "name": "WACHTEL COL",
      "deviceId": "ESP32_Dala_Meter_007085",
      "meterType": "three-phase",
      "location": "Shop Floor",
      "_isType": false
    },
    "features": {
      "measurements": {
        "properties": {
          "voltage_a_v": 0.0,
          "voltage_b_v": 0.0,
          "voltage_c_v": 0.0,
          "current_a_a": 0.0,
          "current_b_a": 0.0,
          "current_c_a": 0.0,
          "active_power_w": 0.0,
          "power_factor_total": 0.0,
          "frequency_hz": 50.0,
          "active_energy_positive_kwh": 0.0,
          "active_energy_negative_kwh": 0.0,
          "reactive_energy_positive_varh": 0.0,
          "reactive_energy_negative_varh": 0.0,
          "status": "offline"
        }
      }
    }
  }'
```

### 9. BT WACHTEL COL — ESP32_Dala_Meter_006906

```bash
curl -X PUT "${DITTO_URL}/api/2/things/${TENANT}:ESP32-Dala-Meter-006906" \
  -u "ditto:ditto" -H "Content-Type: application/json" \
  -d '{
    "policyId": "gold-sapa-tenant:all-meters",
    "attributes": {
      "name": "BT WACHTEL COL",
      "deviceId": "ESP32_Dala_Meter_006906",
      "meterType": "three-phase",
      "location": "Shop Floor",
      "_isType": false
    },
    "features": {
      "measurements": {
        "properties": {
          "voltage_a_v": 0.0,
          "voltage_b_v": 0.0,
          "voltage_c_v": 0.0,
          "current_a_a": 0.0,
          "current_b_a": 0.0,
          "current_c_a": 0.0,
          "active_power_w": 0.0,
          "power_factor_total": 0.0,
          "frequency_hz": 50.0,
          "active_energy_positive_kwh": 0.0,
          "active_energy_negative_kwh": 0.0,
          "reactive_energy_positive_varh": 0.0,
          "reactive_energy_negative_varh": 0.0,
          "status": "offline"
        }
      }
    }
  }'
```

### 10. BT WACHTEL — ESP32_Dala_Meter_006411

```bash
curl -X PUT "${DITTO_URL}/api/2/things/${TENANT}:ESP32-Dala-Meter-006411" \
  -u "ditto:ditto" -H "Content-Type: application/json" \
  -d '{
    "policyId": "gold-sapa-tenant:all-meters",
    "attributes": {
      "name": "BT WACHTEL",
      "deviceId": "ESP32_Dala_Meter_006411",
      "meterType": "three-phase",
      "location": "Shop Floor",
      "_isType": false
    },
    "features": {
      "measurements": {
        "properties": {
          "voltage_a_v": 0.0,
          "voltage_b_v": 0.0,
          "voltage_c_v": 0.0,
          "current_a_a": 0.0,
          "current_b_a": 0.0,
          "current_c_a": 0.0,
          "active_power_w": 0.0,
          "power_factor_total": 0.0,
          "frequency_hz": 50.0,
          "active_energy_positive_kwh": 0.0,
          "active_energy_negative_kwh": 0.0,
          "reactive_energy_positive_varh": 0.0,
          "reactive_energy_negative_varh": 0.0,
          "status": "offline"
        }
      }
    }
  }'
```

### 11. BT WACHTEL COM — ESP32_Dala_Meter_007108

```bash
curl -X PUT "${DITTO_URL}/api/2/things/${TENANT}:ESP32-Dala-Meter-007108" \
  -u "ditto:ditto" -H "Content-Type: application/json" \
  -d '{
    "policyId": "gold-sapa-tenant:all-meters",
    "attributes": {
      "name": "BT WACHTEL COM",
      "deviceId": "ESP32_Dala_Meter_007108",
      "meterType": "three-phase",
      "location": "Shop Floor",
      "_isType": false
    },
    "features": {
      "measurements": {
        "properties": {
          "voltage_a_v": 0.0,
          "voltage_b_v": 0.0,
          "voltage_c_v": 0.0,
          "current_a_a": 0.0,
          "current_b_a": 0.0,
          "current_c_a": 0.0,
          "active_power_w": 0.0,
          "power_factor_total": 0.0,
          "frequency_hz": 50.0,
          "active_energy_positive_kwh": 0.0,
          "active_energy_negative_kwh": 0.0,
          "reactive_energy_positive_varh": 0.0,
          "reactive_energy_negative_varh": 0.0,
          "status": "offline"
        }
      }
    }
  }'
```

### 12. WACHTEL COM — ESP32_Dala_Meter_002008

```bash
curl -X PUT "${DITTO_URL}/api/2/things/${TENANT}:ESP32-Dala-Meter-002008" \
  -u "ditto:ditto" -H "Content-Type: application/json" \
  -d '{
    "policyId": "gold-sapa-tenant:all-meters",
    "attributes": {
      "name": "WACHTEL COM",
      "deviceId": "ESP32_Dala_Meter_002008",
      "meterType": "three-phase",
      "location": "Shop Floor",
      "_isType": false
    },
    "features": {
      "measurements": {
        "properties": {
          "voltage_a_v": 0.0,
          "voltage_b_v": 0.0,
          "voltage_c_v": 0.0,
          "current_a_a": 0.0,
          "current_b_a": 0.0,
          "current_c_a": 0.0,
          "active_power_w": 0.0,
          "power_factor_total": 0.0,
          "frequency_hz": 50.0,
          "active_energy_positive_kwh": 0.0,
          "active_energy_negative_kwh": 0.0,
          "reactive_energy_positive_varh": 0.0,
          "reactive_energy_negative_varh": 0.0,
          "status": "offline"
        }
      }
    }
  }'
```

### 13. MIWE 1 — Baker1_001989_ESP32_Dala_Meter

```bash
curl -X PUT "${DITTO_URL}/api/2/things/${TENANT}:Baker1-001989-ESP32-Dala-Meter" \
  -u "ditto:ditto" -H "Content-Type: application/json" \
  -d '{
    "policyId": "gold-sapa-tenant:all-meters",
    "attributes": {
      "name": "MIWE 1",
      "deviceId": "Baker1_001989_ESP32_Dala_Meter",
      "meterType": "three-phase",
      "location": "Shop Floor",
      "_isType": false
    },
    "features": {
      "measurements": {
        "properties": {
          "voltage_a_v": 0.0,
          "voltage_b_v": 0.0,
          "voltage_c_v": 0.0,
          "current_a_a": 0.0,
          "current_b_a": 0.0,
          "current_c_a": 0.0,
          "active_power_w": 0.0,
          "power_factor_total": 0.0,
          "frequency_hz": 50.0,
          "active_energy_positive_kwh": 0.0,
          "active_energy_negative_kwh": 0.0,
          "reactive_energy_positive_varh": 0.0,
          "reactive_energy_negative_varh": 0.0,
          "status": "offline"
        }
      }
    }
  }'
```

### 14. MIWE 2 — ESP32_Dala_Meter_001994

```bash
curl -X PUT "${DITTO_URL}/api/2/things/${TENANT}:ESP32-Dala-Meter-001994" \
  -u "ditto:ditto" -H "Content-Type: application/json" \
  -d '{
    "policyId": "gold-sapa-tenant:all-meters",
    "attributes": {
      "name": "MIWE 2",
      "deviceId": "ESP32_Dala_Meter_001994",
      "meterType": "three-phase",
      "location": "Shop Floor",
      "_isType": false
    },
    "features": {
      "measurements": {
        "properties": {
          "voltage_a_v": 0.0,
          "voltage_b_v": 0.0,
          "voltage_c_v": 0.0,
          "current_a_a": 0.0,
          "current_b_a": 0.0,
          "current_c_a": 0.0,
          "active_power_w": 0.0,
          "power_factor_total": 0.0,
          "frequency_hz": 50.0,
          "active_energy_positive_kwh": 0.0,
          "active_energy_negative_kwh": 0.0,
          "reactive_energy_positive_varh": 0.0,
          "reactive_energy_negative_varh": 0.0,
          "status": "offline"
        }
      }
    }
  }'
```

---

## Сводная таблица

| # | Название | Device ID | Thing ID | Тип |
|---|----------|-----------|----------|-----|
| 1 | Лед 1 | ESP32_Orman_Meter_044631 | gold-sapa-tenant:ESP32-Orman-Meter-044631 | Однофазный |
| 2 | Лед 2 | ESP32_Orman_Meter_044890 | gold-sapa-tenant:ESP32-Orman-Meter-044890 | Однофазный |
| 3 | Миксер 1 | ESP32_Dala_Meter_001990 | gold-sapa-tenant:ESP32-Dala-Meter-001990 | Трёхфазный |
| 4 | Миксер 2 | ESP32_Dala_Meter_002006 | gold-sapa-tenant:ESP32-Dala-Meter-002006 | Трёхфазный |
| 5 | Формовка | ESP32_Dala_Meter_002003 | gold-sapa-tenant:ESP32-Dala-Meter-002003 | Трёхфазный |
| 6 | Расстойка 1 | ESP32_Dala_Meter_002004 | gold-sapa-tenant:ESP32-Dala-Meter-002004 | Трёхфазный |
| 7 | Расстойка 2 | ESP32_Dala_Meter_002024 | gold-sapa-tenant:ESP32-Dala-Meter-002024 | Трёхфазный |
| 8 | WACHTEL COL | ESP32_Dala_Meter_007085 | gold-sapa-tenant:ESP32-Dala-Meter-007085 | Трёхфазный |
| 9 | BT WACHTEL COL | ESP32_Dala_Meter_006906 | gold-sapa-tenant:ESP32-Dala-Meter-006906 | Трёхфазный |
| 10 | BT WACHTEL | ESP32_Dala_Meter_006411 | gold-sapa-tenant:ESP32-Dala-Meter-006411 | Трёхфазный |
| 11 | BT WACHTEL COM | ESP32_Dala_Meter_007108 | gold-sapa-tenant:ESP32-Dala-Meter-007108 | Трёхфазный |
| 12 | WACHTEL COM | ESP32_Dala_Meter_002008 | gold-sapa-tenant:ESP32-Dala-Meter-002008 | Трёхфазный |
| 13 | MIWE 1 | Baker1_001989_ESP32_Dala_Meter | gold-sapa-tenant:Baker1-001989-ESP32-Dala-Meter | Трёхфазный |
| 14 | MIWE 2 | ESP32_Dala_Meter_001994 | gold-sapa-tenant:ESP32-Dala-Meter-001994 | Трёхфазный |

## Порядок выполнения

1. Задать переменные
2. Создать **одну общую Policy** `gold-sapa-tenant:all-meters`
3. Создать все 14 Things по порядку

> **Важно:** Уже созданный Thing `Лед 1` и его старую Policy `ESP32-Orman-Meter-044631` нужно пересоздать с новым `policyId: all-meters`.

---

## Отправка тестовых данных (все 14 устройств)

### Однофазные (Orman)

```bash
# Лед 1
curl -s -X PATCH "${DITTO_URL}/api/2/things/${TENANT}:ESP32-Orman-Meter-044631/features/measurements/properties" \
  -u "ditto:ditto" -H "Content-Type: application/merge-patch+json" \
  -d '{"voltage_v":221.3,"frequency_hz":50.01,"power_factor":0.88,"total_energy_kwh":874.2,"reactive_energy_var":156.8,"status":"online"}'

# Лед 2
curl -s -X PATCH "${DITTO_URL}/api/2/things/${TENANT}:ESP32-Orman-Meter-044890/features/measurements/properties" \
  -u "ditto:ditto" -H "Content-Type: application/merge-patch+json" \
  -d '{"voltage_v":219.8,"frequency_hz":49.99,"power_factor":0.91,"total_energy_kwh":432.1,"reactive_energy_var":89.3,"status":"online"}'
```

### Трёхфазные (Dala)

```bash
# Миксер 1
curl -s -X PATCH "${DITTO_URL}/api/2/things/${TENANT}:ESP32-Dala-Meter-001990/features/measurements/properties" \
  -u "ditto:ditto" -H "Content-Type: application/merge-patch+json" \
  -d '{"voltage_a_v":228.5,"voltage_b_v":230.1,"voltage_c_v":229.3,"current_a_a":12.4,"current_b_a":11.8,"current_c_a":13.1,"active_power_w":8520,"power_factor_total":0.92,"frequency_hz":50.02,"active_energy_positive_kwh":1542.7,"active_energy_negative_kwh":0,"reactive_energy_positive_varh":312.5,"reactive_energy_negative_varh":0,"status":"online"}'

# Миксер 2
curl -s -X PATCH "${DITTO_URL}/api/2/things/${TENANT}:ESP32-Dala-Meter-002006/features/measurements/properties" \
  -u "ditto:ditto" -H "Content-Type: application/merge-patch+json" \
  -d '{"voltage_a_v":231.2,"voltage_b_v":229.8,"voltage_c_v":230.5,"current_a_a":8.7,"current_b_a":9.1,"current_c_a":8.3,"active_power_w":5940,"power_factor_total":0.89,"frequency_hz":50.01,"active_energy_positive_kwh":987.3,"active_energy_negative_kwh":0,"reactive_energy_positive_varh":201.4,"reactive_energy_negative_varh":0,"status":"online"}'

# Формовка
curl -s -X PATCH "${DITTO_URL}/api/2/things/${TENANT}:ESP32-Dala-Meter-002003/features/measurements/properties" \
  -u "ditto:ditto" -H "Content-Type: application/merge-patch+json" \
  -d '{"voltage_a_v":229.1,"voltage_b_v":228.7,"voltage_c_v":230.2,"current_a_a":15.3,"current_b_a":14.9,"current_c_a":15.7,"active_power_w":10450,"power_factor_total":0.94,"frequency_hz":50.00,"active_energy_positive_kwh":2341.8,"active_energy_negative_kwh":0,"reactive_energy_positive_varh":478.2,"reactive_energy_negative_varh":0,"status":"online"}'

# Расстойка 1
curl -s -X PATCH "${DITTO_URL}/api/2/things/${TENANT}:ESP32-Dala-Meter-002004/features/measurements/properties" \
  -u "ditto:ditto" -H "Content-Type: application/merge-patch+json" \
  -d '{"voltage_a_v":230.4,"voltage_b_v":231.0,"voltage_c_v":229.8,"current_a_a":6.2,"current_b_a":5.9,"current_c_a":6.5,"active_power_w":4280,"power_factor_total":0.91,"frequency_hz":50.01,"active_energy_positive_kwh":1123.4,"active_energy_negative_kwh":0,"reactive_energy_positive_varh":198.7,"reactive_energy_negative_varh":0,"status":"online"}'

# Расстойка 2
curl -s -X PATCH "${DITTO_URL}/api/2/things/${TENANT}:ESP32-Dala-Meter-002024/features/measurements/properties" \
  -u "ditto:ditto" -H "Content-Type: application/merge-patch+json" \
  -d '{"voltage_a_v":228.9,"voltage_b_v":229.5,"voltage_c_v":230.1,"current_a_a":5.8,"current_b_a":6.1,"current_c_a":5.5,"active_power_w":3950,"power_factor_total":0.90,"frequency_hz":49.99,"active_energy_positive_kwh":987.6,"active_energy_negative_kwh":0,"reactive_energy_positive_varh":167.3,"reactive_energy_negative_varh":0,"status":"online"}'

# WACHTEL COL
curl -s -X PATCH "${DITTO_URL}/api/2/things/${TENANT}:ESP32-Dala-Meter-007085/features/measurements/properties" \
  -u "ditto:ditto" -H "Content-Type: application/merge-patch+json" \
  -d '{"voltage_a_v":231.5,"voltage_b_v":230.8,"voltage_c_v":232.1,"current_a_a":22.1,"current_b_a":21.7,"current_c_a":22.5,"active_power_w":15200,"power_factor_total":0.95,"frequency_hz":50.02,"active_energy_positive_kwh":4521.3,"active_energy_negative_kwh":0,"reactive_energy_positive_varh":892.1,"reactive_energy_negative_varh":0,"status":"online"}'

# BT WACHTEL COL
curl -s -X PATCH "${DITTO_URL}/api/2/things/${TENANT}:ESP32-Dala-Meter-006906/features/measurements/properties" \
  -u "ditto:ditto" -H "Content-Type: application/merge-patch+json" \
  -d '{"voltage_a_v":229.8,"voltage_b_v":230.3,"voltage_c_v":229.1,"current_a_a":18.4,"current_b_a":17.9,"current_c_a":18.8,"active_power_w":12700,"power_factor_total":0.93,"frequency_hz":50.00,"active_energy_positive_kwh":3678.9,"active_energy_negative_kwh":0,"reactive_energy_positive_varh":723.4,"reactive_energy_negative_varh":0,"status":"online"}'

# BT WACHTEL
curl -s -X PATCH "${DITTO_URL}/api/2/things/${TENANT}:ESP32-Dala-Meter-006411/features/measurements/properties" \
  -u "ditto:ditto" -H "Content-Type: application/merge-patch+json" \
  -d '{"voltage_a_v":230.2,"voltage_b_v":229.6,"voltage_c_v":231.0,"current_a_a":19.7,"current_b_a":20.1,"current_c_a":19.3,"active_power_w":13600,"power_factor_total":0.94,"frequency_hz":50.01,"active_energy_positive_kwh":3912.5,"active_energy_negative_kwh":0,"reactive_energy_positive_varh":756.8,"reactive_energy_negative_varh":0,"status":"online"}'

# BT WACHTEL COM
curl -s -X PATCH "${DITTO_URL}/api/2/things/${TENANT}:ESP32-Dala-Meter-007108/features/measurements/properties" \
  -u "ditto:ditto" -H "Content-Type: application/merge-patch+json" \
  -d '{"voltage_a_v":228.7,"voltage_b_v":229.2,"voltage_c_v":228.5,"current_a_a":16.3,"current_b_a":15.8,"current_c_a":16.7,"active_power_w":11200,"power_factor_total":0.92,"frequency_hz":50.00,"active_energy_positive_kwh":2987.1,"active_energy_negative_kwh":0,"reactive_energy_positive_varh":589.3,"reactive_energy_negative_varh":0,"status":"online"}'

# WACHTEL COM
curl -s -X PATCH "${DITTO_URL}/api/2/things/${TENANT}:ESP32-Dala-Meter-002008/features/measurements/properties" \
  -u "ditto:ditto" -H "Content-Type: application/merge-patch+json" \
  -d '{"voltage_a_v":230.9,"voltage_b_v":231.3,"voltage_c_v":230.5,"current_a_a":20.5,"current_b_a":21.0,"current_c_a":20.1,"active_power_w":14100,"power_factor_total":0.93,"frequency_hz":50.02,"active_energy_positive_kwh":4102.7,"active_energy_negative_kwh":0,"reactive_energy_positive_varh":812.6,"reactive_energy_negative_varh":0,"status":"online"}'

# MIWE 1
curl -s -X PATCH "${DITTO_URL}/api/2/things/${TENANT}:Baker1-001989-ESP32-Dala-Meter/features/measurements/properties" \
  -u "ditto:ditto" -H "Content-Type: application/merge-patch+json" \
  -d '{"voltage_a_v":229.4,"voltage_b_v":230.0,"voltage_c_v":229.7,"current_a_a":25.8,"current_b_a":26.2,"current_c_a":25.4,"active_power_w":17800,"power_factor_total":0.96,"frequency_hz":50.01,"active_energy_positive_kwh":5678.3,"active_energy_negative_kwh":0,"reactive_energy_positive_varh":1045.2,"reactive_energy_negative_varh":0,"status":"online"}'

# MIWE 2
curl -s -X PATCH "${DITTO_URL}/api/2/things/${TENANT}:ESP32-Dala-Meter-001994/features/measurements/properties" \
  -u "ditto:ditto" -H "Content-Type: application/merge-patch+json" \
  -d '{"voltage_a_v":230.6,"voltage_b_v":229.9,"voltage_c_v":231.2,"current_a_a":24.3,"current_b_a":23.8,"current_c_a":24.7,"active_power_w":16900,"power_factor_total":0.95,"frequency_hz":50.00,"active_energy_positive_kwh":5234.1,"active_energy_negative_kwh":0,"reactive_energy_positive_varh":978.6,"reactive_energy_negative_varh":0,"status":"online"}'
```

---

## Grafana Flux Query

```flux
from(bucket: "default")
  |> range(start: -30d)
  |> filter(fn: (r) => r["_measurement"] == "mqtt_consumer")
  |> filter(fn: (r) => r["thingId"] =~ /gold-sapa-tenant:.*/)
  |> filter(fn: (r) => r["_field"] =~ /^value_(voltage|current|active_power|frequency|power_factor|active_energy|reactive_energy|total_energy)/)
  |> group(columns: ["thingId", "_field"])
  |> last()
  |> group(columns: ["thingId"])
  |> pivot(rowKey: ["_time"], columnKey: ["_field"], valueColumn: "_value")
  |> group()
```

## Unity MeterReceiver — Inspector Bindings

| # | displayName | thingId | meterType |
|---|-------------|---------|-----------|
| 1 | Лед 1 | gold-sapa-tenant:ESP32-Orman-Meter-044631 | single-phase |
| 2 | Лед 2 | gold-sapa-tenant:ESP32-Orman-Meter-044890 | single-phase |
| 3 | Миксер 1 | gold-sapa-tenant:ESP32-Dala-Meter-001990 | three-phase |
| 4 | Миксер 2 | gold-sapa-tenant:ESP32-Dala-Meter-002006 | three-phase |
| 5 | Формовка | gold-sapa-tenant:ESP32-Dala-Meter-002003 | three-phase |
| 6 | Расстойка 1 | gold-sapa-tenant:ESP32-Dala-Meter-002004 | three-phase |
| 7 | Расстойка 2 | gold-sapa-tenant:ESP32-Dala-Meter-002024 | three-phase |
| 8 | WACHTEL COL | gold-sapa-tenant:ESP32-Dala-Meter-007085 | three-phase |
| 9 | BT WACHTEL COL | gold-sapa-tenant:ESP32-Dala-Meter-006906 | three-phase |
| 10 | BT WACHTEL | gold-sapa-tenant:ESP32-Dala-Meter-006411 | three-phase |
| 11 | BT WACHTEL COM | gold-sapa-tenant:ESP32-Dala-Meter-007108 | three-phase |
| 12 | WACHTEL COM | gold-sapa-tenant:ESP32-Dala-Meter-002008 | three-phase |
| 13 | MIWE 1 | gold-sapa-tenant:Baker1-001989-ESP32-Dala-Meter | three-phase |
| 14 | MIWE 2 | gold-sapa-tenant:ESP32-Dala-Meter-001994 | three-phase |