# RouteMatch 🛵

**Optimizador inteligente de rutas para repartidores**

Detecta automáticamente pedidos en Uber Eats, Rappi y DiDi Food usando Android Accessibility Service, compara el desvío con tu ruta activa y te notifica al instante si el pedido conviene.

---

## Stack técnico

| Capa | Tecnología |
|------|-----------|
| UI | Flutter 3.x (Dart) |
| Estado | Provider + ChangeNotifier |
| Android nativo | Java — AccessibilityService, BroadcastReceiver, EventChannel |
| Comunicación Flutter↔Android | MethodChannel + EventChannel |
| Mapas y rutas | Google Maps Directions API |
| Almacenamiento | SharedPreferences (config) + JSON serialization |
| Diseño | Material 3, colores oscuros personalizados |

---

## Estructura del proyecto

```
routematch/
├── lib/
│   ├── main.dart                    ← App entry, bottom nav shell
│   ├── models/
│   │   └── order_model.dart         ← DetectedOrder, ActiveOrder, UserSettings
│   ├── services/
│   │   ├── app_state.dart           ← ChangeNotifier, estado global
│   │   ├── native_bridge.dart       ← MethodChannel/EventChannel wrapper
│   │   └── maps_service.dart        ← Google Maps Directions API
│   ├── screens/
│   │   ├── home_screen.dart         ← Dashboard principal
│   │   ├── order_analysis_screen.dart ← Análisis detallado por pedido
│   │   ├── settings_screen.dart     ← Sliders, switches, API key
│   │   └── history_screen.dart      ← Historial del día con resumen
│   ├── widgets/
│   │   └── common_widgets.dart      ← AppBadge, StatCard, GlowDot, etc.
│   └── utils/
│       └── theme.dart               ← AppColors, AppTheme, tipografía
│
└── android/app/src/main/
    ├── java/com/routematch/
    │   ├── MainActivity.java         ← FlutterActivity + canales nativos
    │   └── RouteMatchAccessibilityService.java ← Lector de pantalla
    ├── res/
    │   ├── xml/accessibility_service_config.xml
    │   └── values/strings.xml
    └── AndroidManifest.xml
```

---

## Setup paso a paso

### 1. Dependencias Flutter

```bash
flutter pub get
```

### 2. Google Maps API Key

1. Ve a https://console.cloud.google.com
2. Crea un proyecto o selecciona uno existente
3. Activa **Maps SDK for Android** y **Directions API**
4. Crea una API key con restricción para Android
5. En `android/app/build.gradle`, agrega:

```gradle
android {
    defaultConfig {
        manifestPlaceholders = [MAPS_API_KEY: "TU_API_KEY_AQUI"]
    }
}
```

O ponla directamente en la app desde la pantalla de **Configuración → Google Maps API Key**.

### 3. Configurar el package name

Asegúrate de que el package name en `AndroidManifest.xml` coincida con el de tu app:

```xml
package="com.routematch"
```

Si lo cambias, actualiza también en:
- `MainActivity.java` → `package com.routematch;`
- `RouteMatchAccessibilityService.java` → `package com.routematch;`

### 4. Build Android

```bash
flutter build apk --debug
# o
flutter build apk --release
```

### 5. Activar el Accessibility Service en el dispositivo

1. Instala la APK
2. Ve a **Ajustes → Accesibilidad → Servicios instalados**
3. Busca **RouteMatch — Optimizador de rutas**
4. Actívalo y concede los permisos
5. Regresa a la app — el banner verde confirmará que está activo

---

## Cómo funciona el flujo completo

```
[Uber Eats / Rappi / DiDi abierta]
        ↓
[AccessibilityService lee el texto en pantalla]
        ↓
[Detecta keywords: "nuevo pedido", "entregar en", etc.]
        ↓
[Extrae dirección con regex]
        ↓
[BroadcastIntent → MainActivity → EventChannel → Flutter]
        ↓
[AppState.triggerOrderAlert()]
        ↓
[Geocodifica dirección → Google Maps API]
        ↓
[Calcula desvío vs ruta activa]
        ↓
[Compara con filtros del usuario]
        ↓
[Muestra banner animado con "Conviene / No conviene"]
```

---

## Pantallas

### 1. Inicio
- Pedido activo en curso (app, dirección, km, ETA)
- Mapa con ruta actual (requiere API key)
- Banner de estado del Accessibility Service (animado)
- Lista de alertas del día con badge de conveniencia
- FAB "Simular pedido" para testing

### 2. Análisis de pedido
- Dirección detectada automáticamente (badge "Auto")
- Veredicto: Conviene / No conviene con explicación
- Barras de progreso animadas: desvío km, tiempo extra, ganancia
- Grid de detalles completos
- Mapa de desvío visual
- Botones Aceptar / Ignorar

### 3. Configuración
- Sliders: máx. minutos, máx. km, ganancia mínima
- Switches por app: Uber Eats, Rappi, DiDi, Otras
- Campo para Google Maps API Key
- Estado de permisos del sistema
- Guardado con SharedPreferences

### 4. Historial del día
- Resumen: total ganado, aceptados, ignorados, km ahorrados
- Barra de progreso de tasa de aceptación
- Desglose por app
- Lista completa con estado (Aceptado / Ignorado / Pendiente)

---

## Colores del diseño

```dart
bgDark:      #0d0d1a  // Fondo principal
bgHeader:    #1a1a2e  // Headers y nav
bgCard:      #16213e  // Cards
primary:     #1d9e75  // Verde (resultados positivos)
danger:      #e74c6f  // Rojo (negativos)
warning:     #f39c12  // Naranja (alertas)
uberEats:    #06C167
rappi:       #FF441F
didi:        #FF6900
```

---

## Notas importantes

- El Accessibility Service **solo lee texto visible en pantalla**, nunca intercepta datos de red ni credenciales.
- La detección de direcciones usa **regex sobre texto en pantalla** — puede requerir ajuste según versiones de las apps.
- En modo demo (sin Accessibility Service activo), usa el botón **"Simular pedido"** para probar toda la UI.
- El mapa en producción requiere Google Maps API Key válida; sin ella muestra un placeholder visual.
