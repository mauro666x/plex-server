# Plex Server Stack – Docker (MacBook Pro → Mini PC)

Este proyecto monta un stack de medios en Docker con:

- **Plex** (`lscr.io/linuxserver/plex`)
- **Transmission** (torrents)
- **FlexGet** (automatización: RSS, tareas, subtítulos, etc.)
- **Samba** (compartir media y descargas por SMB en la red)

Diseñado para:

1. Correr **temporalmente en tu MacBook Pro**.
2. Luego copiar la carpeta `plex-server` a un **mini PC Linux 24/7** y levantar exactamente el mismo entorno.

---

## 1. Estructura del proyecto

Dentro de tu carpeta `plex-server/`:

```text
plex-server/
├── docker-compose.yml
├── .env
├── .env.example
├── .gitignore
├── README.md
├── flexget/
│   ├── config.yml
│   └── custom-cont-init.d/
│       └── 10-subliminal.sh     # (opcional) instala soporte de subtítulos
├── transmission/
│   └── settings.json            # (lo genera/ajusta Transmission)
└── data/
    ├── media/                   # contenido que ve Plex y Samba
    │   ├── movies/
    │   └── tv/
    └── storage/                 # datos internos del stack
        ├── torrents/            # descargas de Transmission
        ├── tmp/                 # carpeta de transcode de Plex
        └── Plex Media Server/   # /config de Plex (BD, prefs, metadata, etc.)
```

Notas:

- Todo lo importante (config y metadatos de Plex, descargas, media) vive bajo `data/`.
- **NO** se recomienda versionar `data/` en Git (ya está en `.gitignore`).

---

## 2. Prerrequisitos

- **Docker** + **Docker Compose** instalados.
- MacBook y otros dispositivos (TV, móvil, etc.) en la **misma red local**.
- Cuenta de **Plex** (https://plex.tv).
- Espacio suficiente en disco para:
  - Medios (`data/media`),
  - Descargas (`data/storage/torrents`),
  - Metadata y cachés (`data/storage/Plex Media Server`, `data/storage/tmp`).

En tu Mac, idealmente:

- Desactivar suspensión mientras la uses como servidor (o al menos cuando esté enchufada).
- Si puedes, conecta la Mac al router por Ethernet.

---

## 3. Variables de entorno – `.env` y `.env.example`

Cambios de configuración se manejan vía `.env`.

### 3.1. `.env.example`

Archivo de plantilla (no sensible) que se versiona:

```bash
TZ=America/Bogota

PUID=1000
PGID=1000

MEDIA=./data/media
STORAGE=./data/storage

# Plex (linuxserver)
PLEX_CLAIM=claim-xxxxxxxxxxxxxxxx

# Samba (SMB)
SAMBA_USER=mauro
SAMBA_PASS=CambiaEstaClave

# Transmission
TR_USERNAME=transmission
TR_PASSWORD=OtraClaveSegura

# FlexGet (WebUI)
FLEXGET_WEBUI_PASS=UnaClaveFuerte_Larga123!
```

- `TZ`: zona horaria.
- `PUID` / `PGID`: IDs de usuario/grupo que usará Plex/FlexGet (en macOS 1000/1000 suele funcionar; en Linux, usar `id -u` / `id -g` del usuario real).
- `MEDIA`: ruta host donde están las pelis/series.
- `STORAGE`: ruta host para cosas internas (torrents, tmp, config Plex).
- `PLEX_CLAIM`: token de claim de Plex (solo lo necesitas el **primer** arranque para asociar el servidor a tu cuenta; luego puede quedar vacío).
- `SAMBA_USER` / `SAMBA_PASS`: credenciales para conectarte por SMB.
- `TR_USERNAME` / `TR_PASSWORD`: login para la UI de Transmission.
- `FLEXGET_WEBUI_PASS`: password fuerte para la WebUI de FlexGet.

### 3.2. Crear `.env` a partir del ejemplo

```bash
cd plex-server
cp .env.example .env
# Editar .env con tus valores reales
```

---

## 4. Crear carpetas necesarias

Desde la raíz del proyecto (`plex-server/`):

```bash
mkdir -p data/media/movies
mkdir -p data/media/tv

mkdir -p data/storage/torrents
mkdir -p data/storage/tmp
mkdir -p "data/storage/Plex Media Server"

mkdir -p flexget/custom-cont-init.d
mkdir -p transmission
```

---

## 5. Contenedores del stack

### 5.1. Plex (lscr.io/linuxserver/plex)

En `docker-compose.yml`:

- Monta:

  - `/config` → `data/storage/Plex Media Server`
  - `/data`   → `data/media`
  - `/transcode` → `data/storage/tmp`

- Expone puertos (mejora compatibilidad con TVs):

  - `32400/tcp` (web y API principal),
  - `3005/tcp`, `8324/tcp`, `32469/tcp`,
  - `1900/udp`, `32410/udp`, `32412/udp`, `32413/udp`, `32414/udp`.

En la UI de Plex:

- Librería de Películas → ruta **`/data/movies`**.
- Librería de Series → ruta **`/data/tv`**.

### 5.2. Transmission

- `./transmission:/config`
- `${STORAGE}/torrents:/downloads` → host: `data/storage/torrents`.

Config clave en `transmission/settings.json` (se edita con el contenedor parado):

```json
"download-dir": "/downloads",
"incomplete-dir-enabled": true,
"incomplete-dir": "/downloads/incomplete",
"rpc-whitelist-enabled": false
```

Con `rpc-whitelist-enabled: false` evitas el error `403: Unauthorized IP Address` en la UI.

### 5.3. FlexGet

- Config principal: `flexget/config.yml`
- Volúmenes:
  - `/config` → `flexget/`
  - `/downloads` → `data/storage/torrents`
  - `/storage` → `data/media`
- WebUI:
  - Interno: puerto `5050`
  - Expuesto: `5050:5050`

Password de la WebUI = `FLEXGET_WEBUI_PASS` (de `.env`).

### 5.4. Samba (SMB) – sin chocar con el SMB nativo de macOS

El contenedor Samba (`dperson/samba`) escucha en 139/445 *dentro* del contenedor, pero en el host usamos puertos **no estándar**:

- `1139:139`
- `1445:445`

De esta forma no chocamos con el file sharing nativo de macOS.

Comparte:

- `media` → `${MEDIA}` (`data/media`)
- `downloads` → `${STORAGE}/torrents` (`data/storage/torrents`)

Desde otro equipo de la red:

- En macOS → Finder → `⌘K` →  
  `smb://IP_DE_TU_MAC:1445/media`  
  `smb://IP_DE_TU_MAC:1445/downloads`

---

## 6. Levantar el stack

Desde `plex-server/`:

```bash
docker compose up -d
```

Ver contenedores:

```bash
docker ps --format 'table {{.Names}}	{{.Ports}}'
```

---

## 7. Accesos

- **Plex**  
  - Mac: `http://localhost:32400/web`  
  - Otros dispositivos: `http://IP_DE_TU_MAC:32400/web`

- **Transmission**  
  - `http://localhost:9091`  
  - Usuario/clave: `TR_USERNAME` / `TR_PASSWORD` (de `.env`).

- **FlexGet WebUI**  
  - `http://localhost:5050`  
  - Password: `FLEXGET_WEBUI_PASS`.

- **Samba (SMB)**  
  - Desde otro Mac: `smb://IP_DE_TU_MAC:1445/media`  
    Usuario/clave: `SAMBA_USER` / `SAMBA_PASS`.

---

## 8. Automatización de subtítulos con FlexGet (opcional)

Para usar FlexGet + `subliminal` y descargar subtítulos automáticamente:

1. Script de init en `flexget/custom-cont-init.d/10-subliminal.sh`:

   ```bash
   #!/usr/bin/with-contenv bash
   pip install "flexget[subliminal]"
   ```

   Asegúrate de que sea ejecutable:

   ```bash
   chmod +x flexget/custom-cont-init.d/10-subliminal.sh
   docker compose restart flexget
   ```

2. Ejemplo de tarea en `flexget/config.yml`:

   ```yaml
   web_server:
     bind: 0.0.0.0
     port: 5050

   tasks:
     get-subtitles:
       filesystem:
         path:
           - /storage/movies
         regexp: '.*\.(mp4|mkv|avi)$'
         recursive: yes
         retrieve: files
       accept_all: yes
       seen: local
       subliminal:
         languages:
           - spa
           - eng
         providers:
           - opensubtitles
         single: no
         hearing_impaired: no
         authentication:
           opensubtitles:
             username: TU_USER
             password: TU_PASS
   ```

3. Ejecutar la tarea manualmente:

   ```bash
   docker exec -it flexget flexget -c /config/config.yml execute --task get-subtitles --now
   ```

Los `.srt` aparecerán junto a los `.mp4` en `data/media/movies` y Plex podrá detectarlos.

---

## 9. Migrar al mini PC (Linux)

Cuando tengas el mini PC:

1. Instala Docker + Docker Compose.
2. Copia la carpeta `plex-server` tal cual desde la Mac al mini PC (por ejemplo con `tar` o `rsync`).
3. Ajusta en `.env`:
   - `PUID` / `PGID` a los del usuario Linux (`id -u`, `id -g`).
   - `MEDIA` y `STORAGE` si los discos van a vivir en rutas distintas (por ejemplo `/srv/media`, `/srv/storage`).
4. En el mini PC:

   ```bash
   cd /ruta/a/plex-server
   docker compose up -d
   ```

Plex levantará con la **misma** configuración:

- Librerías,
- Estado de visto/no visto,
- Metadatos,
- Descargas previas de Transmission,
- Config de FlexGet y Samba.

---

## 10. Notas finales

- El warning de Docker Compose sobre `version: "3.7"` siendo obsoleto se puede ignorar o puedes eliminar la línea `version` del `docker-compose.yml` para que no aparezca.
- Realiza backups periódicos de:
  - `data/storage/Plex Media Server` (config y DB de Plex),
  - `flexget/config.yml`,
  - `transmission/settings.json` (si hiciste mucha personalización).

Con esto tienes un stack sólido, portable y fácil de mantener, listo para reproducir en tu mini PC cuando llegue 🚀
