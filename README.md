# Ahorrant Web

Versión web de **Ahorrant** — finanzas personales gamificadas para universitarios.
Misma lógica, mismos módulos y mismo diseño que la app Android (`C:\WEB\Ahorrant`),
adaptados a las restricciones del navegador.

## Módulos

| Módulo | Funcionalidad | Estado en web |
|---|---|---|
| **Inicio** | Resumen financiero, movimientos, formulario de registro manual | Completo |
| **Hormiguero** | Hormigasoles, racha, mascota virtual, nivel/XP, objetivo diario | Completo |
| **Armario** | Tienda de artículos, inventario persistente, equipar/desequipar | Completo |
| **Metas** | CRUD de metas de ahorro, progreso, premio de Hormigasoles | Completo |
| **Clases** | 10 microlecciones con enlace directo al video de YouTube | Completo |
| **Progreso** | Ingresos, gastos, gastos hormiga, metas, HS recaudados, filtros y desglose por día | Completo |

## Diferencias con la versión Android

- **Registro automático por notificaciones: no disponible.** La lectura de
  notificaciones del sistema requiere el `NotificationListenerService` de
  Android (Kotlin). En web el servicio se degrada de forma segura y el
  registro se hace con el formulario manual ("Agregar Movimiento").
- **Base de datos:** en Android es SQLite nativo; en web SQLite corre
  compilado a **WebAssembly** (`sqlite3.wasm`) dentro de un *shared worker*
  (`sqflite_sw.js`) y guarda los datos en **IndexedDB**.
- **Preferencias:** `shared_preferences` usa `localStorage` en web.

Todo lo demás (gamificación, guardado local, videos de YouTube, assets)
funciona igual que en Android.

## Requisitos

- Flutter 3.10+ (probado con 3.47.9 / Dart 3.13.7)
- Navegador moderno (Chrome, Edge, Firefox, Safari)

## Puesta en marcha

```bash
# 1. Instalar dependencias
flutter pub get

# 2. Generar los archivos de SQLite para web (solo la primera vez,
#    o si se borran web/sqlite3.wasm y web/sqflite_sw.js)
dart run sqflite_common_ffi_web:setup

# 3. Ejecutar en el navegador
flutter run -d chrome

# 4. Compilar para producción
flutter build web --release
```

El resultado queda en `build\web\`.

> `web/sqlite3.wasm` y `web/sqflite_sw.js` **deben** subirse junto al
> `index.html` al desplegar. Si se regeneran, vuelve a correr el paso 2.

## Publicar

`build\web\` es un sitio estático: sirve con Nginx, Apache, GitHub Pages,
Netlify, Vercel o Firebase Hosting. Ejemplo con Python:

```bash
cd build/web
python -m http.server 8080
```

> Si se publica en una subcarpeta, compila con
> `flutter build web --release --base-href /mi-ruta/`.

## Estructura

```
lib/
├── main.dart                    # Entrada + barra inferior (6 módulos)
├── models/
│   ├── articulo_tienda.dart     # Catálogo de la tienda
│   ├── clase_model.dart         # Microlecciones + video de YouTube
│   ├── goal_model.dart          # Metas de ahorro
│   ├── mascot_model.dart        # Estados de la mascota
│   ├── registro_hormigasoles.dart # Historial de HS (ganados/gastados)
│   └── transaction_model.dart   # Movimientos
├── screens/
│   ├── inicio_screen.dart       # Dashboard + registro manual
│   ├── hormiguero_screen.dart   # Gamificación
│   ├── armario_screen.dart      # Tienda / guarderropa
│   ├── metas_screen.dart        # CRUD de metas
│   ├── clases_screen.dart       # Microlecciones (YouTube)
│   └── progreso_screen.dart     # Métricas y filtros por periodo
├── services/
│   ├── database_helper.dart     # SQLite (IndexedDB en web)
│   ├── gamification_service.dart# Hormigasoles, XP, inventario (persistente)
│   ├── notification_service.dart# Solo Android; en web es no-op seguro
│   └── sync_service.dart        # Sincronización con backend (no activa)
├── theme/app_theme.dart         # Paleta y tema
└── widgets/mascota_animada.dart # Mascota animada
```

## Comandos útiles

```bash
flutter analyze        # análisis estático
flutter test           # tests
flutter build web      # build debug
flutter build web --release
```
