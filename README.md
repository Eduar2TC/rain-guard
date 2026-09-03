# RainGuard

Sistema de alerta de lluvia para ciclistas.

## Descripción

RainGuard es una aplicación Android que detecta la aproximación de lluvia y avisa al usuario con anticipación suficiente para que pueda buscar refugio mientras está en bicicleta.

## Características MVP

- Monitoreo en segundo plano mediante Foreground Service
- Burbuja flotante sobre otras aplicaciones
- Alertas basadas en pronóstico meteorológico
- ETA aproximado de llegada de lluvia
- Consumo optimizado de batería

## Requisitos

- Android 8.0 (API 26) o superior
- Flutter 3.0+
- Dart 3.0+

## Instalación

```bash
# Clonar el repositorio
git clone <repository-url>

# Instalar dependencias
flutter pub get

# Ejecutar
flutter run
```

## Estructura del Proyecto

```
lib/
├── core/                    # Constantes, errores, logging, utils
├── domain/                  # Entidades, enums, repositorios
├── application/             # Use cases, estado
├── data/                    # Providers, datasources, modelos
├── presentation/            # Screens, widgets, controllers
└── platform/                # Platform channels
```

## Arquitectura

- **Flutter**: UI, configuración, onboarding
- **Kotlin**: Foreground Service, ubicación, overlay, notificaciones
- **Open-Meteo**: Datos meteorológicos (gratuito, sin API key)

## Fases de Desarrollo

1. Skeleton - Proyecto con comunicación Flutter↔Android
2. Location - GPS en background
3. Weather - Open-Meteo + cache
4. Prediction - ETA de lluvia
5. Alert Engine - Estados + anti-spam
6. Foreground Service - Monitoreo background
7. Bubble - Overlay flotante
8. Battery - Optimización
9. Debug - Herramientas
10. Testing

## Licencia

MIT
