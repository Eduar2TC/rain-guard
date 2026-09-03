# RainGuard — Plan de Implementación MVP

## Arquitectura General

```
Flutter UI (Dart) ←→ Platform Channels ←→ Android Native (Kotlin)
                                                ↓
                                    ┌─────────────────────┐
                                    │ Foreground Service   │
                                    │ Location Updates     │
                                    │ Weather Polling      │
                                    │ Overlay Bubble       │
                                    │ Notifications        │
                                    └─────────────────────┘
```

## Fases de Implementación

---

### FASE 1 — Skeleton (Semana 1)

**Objetivo:** Proyecto compilable con comunicación Flutter↔Android.

**Tareas:**

1. Crear proyecto Flutter
2. Configurar `minSdkVersion: 26`
3. Crear estructura de directorios Clean Architecture
4. Configurar Riverpod
5. Crear `MethodChannel` y `EventChannel` en ambos lados
6. Verificar que Flutter puede invocar métodos Kotlin
7. Verificar que Kotlin puede enviar eventos a Flutter

**Entregable:**
- `flutter run` funciona
- Canal bidireccional funcional

**Archivos clave:**
```
lib/
  core/
    channels/
      method_channel_service.dart
      event_channel_service.dart
  domain/
    entities/
    enums/
  presentation/
    screens/
      home_screen.dart
android/app/src/main/kotlin/
  service/
  location/
  overlay/
  notification/
  weather/
  permissions/
```

---

### FASE 2 — Location (Semana 2)

**Objetivo:** App conoce posición GPS en tiempo real.

**Tareas:**

1. Implementar `GeoPoint` entity
2. Implementar `LocationRepository` (domain)
3. Implementar `AndroidLocationDataSource` (Kotlin)
4. Implementar `LocationManager.kt`
5. Solicitar `ACCESS_FINE_LOCATION`
6. Solicitar `ACCESS_BACKGROUND_LOCATION` (explicar al usuario)
7. Configurar `FusedLocationProviderClient`
8. Implementar ubicación adaptativa según velocidad
9. Exponer lat, lon, speed, bearing, accuracy a Flutter

**Entregable:**
- GPS funciona en foreground y background
- Datos de ubicación llegan a Flutter via EventChannel

---

### FASE 3 — Weather (Semana 2-3)

**Objetivo:** Datos meteorológicos funcionando.

**Tareas:**

1. Implementar `WeatherSnapshot` entity
2. Implementar `PrecipitationForecast` entity
3. Crear interfaz `WeatherProvider` (abstract)
4. Implementar `OpenMeteoProvider`
5. Implementar `WeatherRepository` con cache
6. Implementar `NetworkDataSource`
7. Implementar `LocalStorageDataSource` (SharedPreferences)
8. Configurar TTL para datos stale
9. Implementar detección de red (WiFi/Mobile/None)
10. Implementar retry con exponential backoff

**Endpoint Open-Meteo:**
```
https://api.open-meteo.com/v1/forecast?
  latitude={lat}&longitude={lon}
  &current=precipitation,rain,showers,temperature_2m,wind_speed_10m,wind_direction_10m,wind_gusts_10m,weather_code
  &minutely_15=precipitation
  &forecast_days=1
  &timezone=auto
```

**Entregable:**
- Weather data actualizado cada 5 min
- Cache funciona
- Sin datos → muestra "Sin conexión"
- Datos antiguos → muestra "Últimos datos: hace X min"

---

### FASE 4 — Prediction (Semana 3)

**Objetivo:** ETA de lluvia calculado.

**Tareas:**

1. Implementar `RainArrivalPrediction` entity
2. Implementar `PredictionConfidence` enum
3. Implementar `PrecipitationAnalyzer`
4. Implementar `RainArrivalPredictor`
5. Crear `PredictionFusionEngine` (weather-only para MVP)
6. Implementar clasificación de dirección del viento
7. Calcular ETA basado en:
   - Precipitación actual
   - Pronóstico 15-min
   - Dirección del viento
   - Distancia a zonas de precipitación

**Lógica conceptual:**
```
Si precipitation_actual > 0 → RAINING
Si pronóstico_15min > 0 → calcular ETA
  ETA = distancia_célula / velocidad_aproximada
  Si viento_ciela_hacia_usuario → reducir ETA
  Si viento_aleja → aumentar ETA
```

**Entregable:**
- ETA aproximado calculado
- Confianza asignada (0.0 - 1.0)

---

### FASE 5 — Alert Engine (Semana 3-4)

**Objetivo:** Sistema de alertas con anti-spam y hysteresis.

**Tareas:**

1. Implementar `RainRiskState` enum
2. Implementar `AlertEngine`
3. Implementar máquina de estados:
   ```
   IDLE → WATCH → APPROACHING → WARNING → IMMINENT → RAINING → PASSED → IDLE
   ```
4. Implementar hysteresis (2-3 ciclos para cambiar de RAINING)
5. Implementar anti-sparo (máx 1 alerta por transición)
6. Implementar `RainEventDetector`
7. Implementar `RainEvent` entity
8. Configurar umbrales:
   - WATCH: ~15 min
   - APPROACHING: ~10 min
   - WARNING: ~5 min
   - IMMINENT: ≤ 2 min
   - RAINING: 0 min
9. Generar `AlertDecision` con:
   - shouldNotify
   - newState
   - message
   - priority
   - sound/vibration

**Entregable:**
- Estado cambia correctamente
- No spam de notificaciones
- Hysteresis funciona

---

### FASE 6 — Foreground Service (Semana 4)

**Objetivo:** Monitoreo funcional en background.

**Tareas:**

1. Implementar `RainMonitorForegroundService.kt`
2. Declarar en `AndroidManifest.xml`
3. Configurar `FOREGROUND_SERVICE_LOCATION`
4. Configurar `FOREGROUND_SERVICE_DATA_SYNC` (Android 14+)
5. Implementar `PermissionManager.kt`
6. Implementar `NotificationManager.kt`
7. Implementar notificación persistente:
   - Estado idle: "RainGuard activo · lluvia no cercana"
   - Con alerta: "RainGuard · lluvia en ~X min"
8. Implementar acciones en notificación: Pausar, Detener, Abrir
9. Integrar:
   - Location updates
   - Weather updates
   - Prediction
   - Alert engine
10. Manejar `ForegroundServiceStartNotAllowedException`
11. Implementar `MonitoringScheduler` (adaptive polling)

**Frecuencias:**
```
NORMAL: 5-10 min
WATCH: 5 min
APPROACHING: 2-5 min
WARNING: 1-2 min
RAINING: 2-5 min
```

**Entregable:**
- Monitoreo funciona con app minimizada
- Notificación persistente visible
- Acciones de notificación funcionan

---

### FASE 7 — Bubble (Semana 4-5)

**Objetivo:** Burbuja flotante funcional.

**Tareas:**

1. Implementar `RainBubbleManager.kt`
2. Implementar `RainBubbleView.kt`
3. Solicitar `SYSTEM_ALERT_WINDOW`
4. Crear overlay con `WindowManager` + `TYPE_APPLICATION_OVERLAY`
5. Implementar estados visuales:
   ```
   NORMAL: ☀️
   WATCH: 🌦️ 15
   APPROACHING: 🌧️ 10
   WARNING: ⚠️ 5
   IMMINENT: 🚨 2
   RAINING: 🌧️ NOW
   ```
6. Implementar drag (mover)
7. Implementar tap (abrir app)
8. Implementar long press (menú)
9. Guardar/restaurar posición X/Y
10. Implementar toggle ON/OFF en settings
11. Manejar revocación de permiso
12. Comunicar estado a Flutter via MethodChannel

**Entregable:**
- Burbuja visible sobre otras apps
- Arrastrable
- Estados visuales correctos
- Tap abre app
- Posición persiste

---

### FASE 8 — Battery (Semana 5)

**Objetivo:** Consumo de batería optimizado.

**Tareas:**

1. Implementar detección de nivel de batería
2. Implementar detección de restricciones de batería
3. Integrar en `MonitoringScheduler`
4. Implementar modo ahorro:
   ```
   battery < 15% → reducir frecuencia
   battery < 5% → modo ultra-ahorro
   ```
5. Implementar guía de optimización de batería
6. Detectar fabricantes agresivos
7. Implementar botón "Optimizar batería"
8. Reducir precisión GPS cuando no es crítica
9. Minimizar network requests

**Entregable:**
- Batería optimizada
- Modo ahorro funciona
- Usuario puede desactivar restricciones

---

### FASE 9 — Debug (Semana 5-6)

**Objetivo:** Herramientas de debugging.

**Tareas:**

1. Implementar `DebugScreen`
2. Mostrar:
   - Location (lat, lon, accuracy, speed, bearing)
   - Last weather update
   - Data age
   - Provider
   - Rain state
   - ETA
   - Confidence
   - Polling interval
   - Battery level
   - Network state
   - Overlay state
   - Service state
3. Implementar logger estructurado
4. Niveles: DEBUG, INFO, WARNING, ERROR
5. Logs importantes:
   - monitoring_started/stopped
   - location_updated
   - weather_updated
   - prediction_changed
   - alert_triggered
   - overlay_created/removed
   - provider_error

**Entregable:**
- Debug screen funcional
- Logs completos

---

### FASE 10 — Testing (Semana 6)

**Objetivo:** Tests principales funcionando.

**Tareas:**

1. Unit tests para:
   - `RainArrivalPredictor`
   - `AlertEngine`
   - `PredictionFusionEngine`
   - `MonitoringScheduler`
   - `RainEventDetector`
2. Casos de prueba:
   - No rain
   - Rain now
   - Rain in 15 min
   - Rain in 10 min
   - Rain in 5 min
   - Rain in 2 min
   - Rain passes
   - Stale data
   - No network
   - Low battery
   - GPS inaccurate
   - Rapid location change
   - User moving toward rain
   - User moving away from rain
3. Integration tests básicas
4. Verificar en dispositivos reales

**Entregable:**
- Tests pasan
- Cobertura razonable del dominio

---

## Criterios de Aceptación MVP

| # | Criterio | Estado |
|---|----------|--------|
| 1 | Instala correctamente | ☐ |
| 2 | Onboarding + permisos | ☐ |
| 3 | Iniciar monitoreo | ☐ |
| 4 | Foreground Service funciona | ☐ |
| 5 | Ubicación en background | ☐ |
| 6 | Weather API responde | ☐ |
| 7 | Precipitación calculada | ☐ |
| 8 | ETA aproximado | ☐ |
| 9 | Alert Engine cambia estado | ☐ |
| 10 | Notificación aparece | ☐ |
| 11 | Bubble aparece | ☐ |
| 12 | Bubble arrastrable | ☐ |
| 13 | Bubble ocultable | ☐ |
| 14 | Monitoreo sin bubble | ☐ |
| 15 | Sin internet → degrada | ☐ |
| 16 | Sin GPS → maneja | ☐ |
| 17 | Datos stale identificados | ☐ |
| 18 | Sin spam notificaciones | ☐ |
| 19 | Pantalla apagada funciona | ☐ |
| 20 | Android 14 funciona | ☐ |
| 21 | Android 15 funciona | ☐ |
| 22 | Tests principales pasan | ☐ |

---

## Métrica Principal

**RAIN WARNING LEAD TIME**

¿Cuántos minutos antes de la lluvia real consiguió avisar?

| Resultado | Descripción |
|-----------|-------------|
| 15 min | Excelente |
| 10 min | Bueno |
| 5 min | Aceptable |
| 2 min | Tardío |
| Demasiado tarde | Fallido |
| Falso positivo | Debe minimizarse |

---

## Directorio Final

```
alerta_lluvia/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   ├── errors/
│   │   ├── logging/
│   │   └── utils/
│   ├── domain/
│   │   ├── entities/
│   │   ├── enums/
│   │   ├── repositories/
│   │   └── services/
│   ├── application/
│   │   ├── use_cases/
│   │   └── state/
│   ├── data/
│   │   ├── providers/
│   │   ├── datasources/
│   │   ├── models/
│   │   └── repositories/
│   ├── presentation/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── controllers/
│   └── platform/
│       └── channels/
├── android/app/src/main/
│   ├── kotlin/
│   │   └── com/rainGuard/
│   │       ├── service/
│   │       ├── location/
│   │       ├── overlay/
│   │       ├── notification/
│   │       ├── weather/
│   │       └── permissions/
│   └── AndroidManifest.xml
├── test/
└── PLAN.md
```
