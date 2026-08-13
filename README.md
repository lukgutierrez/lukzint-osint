# LUKZINT — OSINT Social Analyzer

> Aplicación para análisis de **información pública** (OSINT) con arquitectura
> limpia, análisis asistido por IA multi-proveedor y generación de informes
> profesionales con verificación de fuentes.

Desarrollado por **Luk Gutierrez** (`@LukGutierrez`) — Ingeniería de Software y
recolección de inteligencia de fuentes abiertas (OSINT).

---

## Tabla de contenidos

- [¿Qué es?](#qué-es)
- [Características principales](#características-principales)
- [Modelo y arquitectura](#modelo-y-arquitectura)
- [Stack tecnológico](#stack-tecnológico)
- [Instalación](#instalación)
- [Configuración del análisis con IA](#configuración-del-análisis-con-ia)
- [Casos de uso con ejemplos](#casos-de-uso-con-ejemplos)
- [Ética y marco legal](#ética-y-marco-legal)
- [Testing y calidad](#testing-y-calidad)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Roadmap](#roadmap)

---

## ¿Qué es?

**LUKZINT** es un analizador OSINT que centraliza la investigación de *personas,
organizaciones o proyectos* a partir de lo que estas publican de forma pública.
En lugar de esparcir apuntes en hojas, la app permite:

1. Crear una **investigación** con objetivo claro.
2. Registrar el **perfil objetivo** (datos, foto, ocupación, ubicación).
3. Vincular sus **redes sociales** públicas.
4. Analizar **URLs públicas** (GitHub, sitios web) extrayendo evidencias.
5. Analizar con **IA** el contenido público de perfiles sociales (bio, posts).
6. Construir un **árbol genealógico / red de relaciones** visual.
7. Generar un **informe PDF** con fuentes, evidencias y limitaciones.

> ⚠️ Trabaja únicamente con información pública y autorizada. No accede a
> perfiles privados, no evita controles de acceso y no inventa datos.

---

## Características principales

| Área | Descripción |
| --- | --- |
| **Investigaciones** | Crear, editar, eliminar y consultar expedientes OSINT con estado (borrador / en curso / completada). |
| **Perfil objetivo** | Datos manuales de la persona: nombre, DNI, alias, ubicación, ocupación, notas y foto. |
| **Análisis de URLs** | Analiza repositorios **GitHub** (vía API oficial) y **sitios web** (metadatos, OpenGraph, encabezados). |
| **Análisis con IA** | Estructura hallazgos desde el contenido público que pegás: resumen + hallazgos con **categoría, confianza y evidencia**. |
| **Multi-proveedor IA** | Soporta **Gemini, OpenRouter, Groq y Mistral AI** con **fallback automático**. |
| **Red de relaciones** | Registro de familiares, parejas, amigos y colegas con foto y notas. |
| **Árbol genealógico** | Vista visual por generaciones centrada en el perfil objetivo. |
| **Informes PDF** | Reporte profesional con objetivo, fuentes, hallazgos, evidencias, relaciones y limitaciones. |
| **Multiplataforma** | Flutter: Android, iOS, Windows, macOS y Linux. |

---

## Modelo y arquitectura

Arquitectura limpia y modular con separación estricta de responsabilidades:

```
┌──────────────── Presentation ────────────────┐
│  Screens · Widgets · Controllers (ChangeNotifier) │
└──────────────────────┬────────────────────────┘
                       │ usecases
┌──────────────────── Domain ──────────────────┐
│  Entities · Repositories (interfaces) · Usecases │
└──────────────────────┬────────────────────────┘
                       │ repositories (impl)
┌──────────────────────▼────────────────────────┐
│                      Data                          │
│  Datasources: Gemini / OpenAI-compatible (Groq ·  │
│  OpenRouter · Mistral) · GitHub API · WebScraper · │
│  LocalStorage / JSON                              │
└──────────────────────┬────────────────────────┘
                       │
┌──────────────────── Core ────────────────────┐
│  Network · Settings · Storage · Errors · Theme │
└──────────────────────────────────────────────┘
```

**Principios aplicados:**

- **SOLID** y *Clean Code*
- **Separación de Concerns** (la UI no contiene lógica de negocio)
- **Inversión de Dependencias** (inyección manual, sin frameworks)
- Código **testeable** y mantenible; se evita la sobreingeniería

**Resiliencia de IA (fallback):** el análisis intenta primero el proveedor
principal configurado. Si falla (falta de clave, límite alcanzado, error de red
o respuesta inválida) y el *fallback automático* está activado, prueba
automáticamente con los demás proveedores configurados.

---

## Stack tecnológico

| Componente | Tecnología |
| --- | --- |
| Framework | Flutter / Dart |
| Estado | `ChangeNotifier` + inyección manual |
| Red | `http` (cliente nativo multiplataforma) |
| Persistencia | Archivos JSON locales (offline-first) |
| Informes | `pdf` + `printing` + `html` |
| Imágenes | `image_picker` |
| IA | Gemini API + APIs OpenAI-compatibles (Groq, OpenRouter, Mistral) |

Dependencias externas mínimas (regla del proyecto).

---

## Instalación

Requisitos: Flutter estable reciente y Dart.

```bash
# 1. Clonar el repositorio
git clone <url-del-repositorio>
cd osint_social_analyzer

# 2. Instalar dependencias
flutter pub get

# 3. Ejecutar análisis estático y tests
flutter analyze
flutter test

# 4. Correr la app (desktop, web, móvil)
flutter run -d windows   # o -d android, -d chrome, etc.
```

La aplicación funciona **offline** para almacenar investigaciones. Solo se
requiere conexión a internet para analizar URLs, consultar la API de GitHub o
usar el análisis con IA.

---

## Configuración del análisis con IA

La aplicación puede usar **cuatro proveedores gratuitos** (sin requerir tarjeta
de crédito para sus planes básicos). En **Ajustes** elegís el *proveedor
principal* y podés cargar la clave de cada uno:

| Proveedor | Cómo obtener la clave |
| --- | --- |
| **Google Gemini** | https://aistudio.google.com → *Get API key* → *Create API key* |
| **OpenRouter** | https://openrouter.ai/keys → modelos `:free` sin tarjeta |
| **Groq** | https://console.groq.com/keys → plan gratuito, muy rápido (`llama-3.3-70b`) |
| **Mistral AI** | https://console.mistral.ai → *API keys* → modo gratuito |

**Consejos:**

- Las claves se guardan **solo en tu dispositivo** (archivo JSON local).
- Con un solo proveedor configurado ya funciona; con más, activás la **resiliencia**.
- Si un proveedor falla (límite diario, caída), el fallback prueba el siguiente automáticamente.

---

## Casos de uso con ejemplos

### 1. Verificación de identidad de un perfil público en GitHub

> **Objetivo:** confirmar si un perfil de GitHub pertenece a una persona y qué
> información declara públicamente.

1. Creá la investigación "Verificación de perfil @jperez".
2. Andá a **Analizador** y pegá `https://github.com/jperez`.
3. LUKZINT consulta la API oficial y registra: login, nombre público, bio,
   compañía, ubicación, web, redes declaradas, repos, seguidores y antigüedad.
4. Cada hallazgo queda con su **evidencia** (campo de la API) y **confianza**.
5. Opcional: generá el **PDF** para compartir el informe con sus fuentes.

### 2. Análisis de contenido público de una red social con IA

> **Objetivo:** estructurar hallazgos de la bio y publicaciones públicas de un
> perfil de Instagram o TikTok **sin acceder a nada privado**.

1. Andá a **Análisis con IA** (dentro de la investigación o desde el flujo).
2. Elegí la plataforma y pegá el **texto literal** del perfil (bio, posts).
3. La IA devuelve un resumen objetivo y hallazgos categorizados con confianza
   y evidencia. Se muestra **qué proveedor** realizó el análisis.
4. El resultado se guarda como fuente vinculada a la investigación.

> **Diferencia clave:** la IA solo analiza lo que *vos* aportás en el mensaje.
> No hay scraping de perfiles privados ni inicio de sesión.

### 3. Construcción de un árbol genealógico / red de relaciones

> **Objetivo:** organizar la red social de la persona objetivo (familia,
> pareja, amigos, colegas) con información pública.

1. En la investigación, completá el **perfil objetivo** (con foto).
2. Agregá cada persona con su **vínculo** (padre, madre, abuelo/a, tío/a,
   hermano/a, primo/a, cónyuge, pareja, ex pareja, hijo/a, sobrino/a, nieto/a,
   amigo/a, colega…).
3. Activa **"Ver árbol genealógico"**: el perfil objetivo queda en el centro,
   ascendientes arriba y descendientes abajo, con ramas visuales.
4. La red también se incluye en el informe PDF.

### 4. Informe profesional con evidencias

> **Objetivo:** entregar un reporte ordenado y auditable.

1. Reuní fuentes y hallazgos en una investigación.
2. Presioná **Generar PDF**.
3. El PDF incluye: título, fecha, objetivo, perfil, redes, hallazgos con
   evidencias y URLs de origen, red de relaciones y **limitaciones del análisis**.

---

## Ética y marco legal

Este proyecto se desarrolla bajo límites estrictos:

- ✅ Solo información **pública y legalmente accesible**.
- ✅ Datos obtenidos mediante **fuentes autorizadas** (APIs oficiales, metadatos públicos).
- ✅ Respeta los términos de servicio de cada plataforma.
- ❌ **No accede** a perfiles privados, no salta controles de acceso ni evita autenticación.
- ❌ **No scraping** donde esté prohibido.
- ❌ No presenta **inferencias como hechos**; cada dato conserva su fuente y confianza.
- ❌ No genera **diagnósticos psicológicos** ni infiere **atributos sensibles**.

**Uso responsable:** el análisis OSINT es para fines legítimos (periodismo,
seguridad, verificación de identidad, investigación legal). El uso indebido de
la información puede ser ilegal. Usá siempre de forma ética y conforme a la
ley aplicable.

---

## Testing y calidad

Verificación obligatoria antes de dar por terminada una funcionalidad:

```bash
flutter analyze
flutter test
```

Suite de tests existente (10+ archivos, 30+ casos):

| Área | Cubrimiento |
| --- | --- |
| Datasources y repositorios | Web scraping, API de GitHub, análisis de URLs |
| IA multi-proveedor | Configuración, parser JSON del protocolo, fallback automático |
| Modelos y serialización | Persistencia JSON de investigaciones |
| Reportes | Generación de PDF válido y con relaciones |
| Validadores | URLs, GitHub, casos de uso |
| Widgets | Dashboard y pantalla de detalle (desktop angosto y ancho) |

---

## Estructura del proyecto

```
lib/
├── core/            # Network, settings, storage, theme, errors, utils
│   └── settings/    # AiProvider (Gemini · OpenRouter · Groq · Mistral)
├── data/
│   ├── datasources/
│   │   ├── gemini_ai_datasource.dart
│   │   ├── openai_compatible_ai_datasource.dart   # Groq/OpenRouter/Mistral
│   │   ├── failover_ai_datasource.dart            # fallback automático
│   │   ├── social_ai_protocol.dart                # prompt + parser JSON
│   │   ├── github_api_datasource.dart
│   │   ├── web_scraper_datasource.dart
│   │   └── local_storage_datasource.dart
│   ├── models/      # serialización JSON
│   └── repositories/# implementaciones
├── domain/
│   ├── entities/    # investigación, hallazgos, fuentes, relaciones, perfil
│   ├── repositories/# contratos (interfaces)
│   └── usecases/    # casos de uso
├── presentation/
│   ├── controllers/ # ChangeNotifier
│   ├── screens/     # dashboard, analizador, detalle, IA, ajustes
│   └── widgets/     # tarjeta de fuente, hallazgo, árbol genealógico, etc.
└── main.dart        # composición raíz (inyección de dependencias)
specs/               # especificación del producto
test/                # tests unitarios y de widgets
```

---

## Roadmap

- [x] Investigaciones, perfil objetivo y fuentes.
- [x] Análisis de URLs (GitHub + web).
- [x] Análisis con IA multi-proveedor con fallback.
- [x] Árbol genealógico visual.
- [x] Informes PDF con evidencias.
- [ ] Exportación de informes en formato HTML.
- [ ] Análisis de hashtags y trending topics públicos.
- [ ] Soporte de más proveedores gratuitos (Cerebras, SambaNova).
- [ ] Vista comparativa de fuentes duplicadas.
- [ ] Exportar/importar expedientes (respaldo).

---

© Luk Gutierrez — Proyecto personal de Ingeniería de Software y OSINT.
Usá responsablemente.