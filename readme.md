# Plex + Transmission + Flexget + Samba (linuxserver/plex)

Stack pensado para:

1. Correr en tu MacBook Pro de forma temporal.
2. Copiar la carpeta `plex-server` tal cual a un mini PC (Linux) y dejarlo 24/7.

Incluye:

- Plex (imagen `lscr.io/linuxserver/plex`)
- Transmission (torrents)
- Flexget (automatización)
- Samba (compartir carpetas por red)

---

## Estructura del proyecto

```text
plex-server/
├── docker-compose.yml
├── .env
├── .env.example
├── README.md
├── flexget/
│   ├── config.yml
│   └── custom-cont-init.d/
│       └── 00-readme.txt
├── transmission/
└── data/
    ├── media/
    │   ├── movies/
    │   └── tv/
    └── storage/
        ├── torrents/
        ├── tmp/
        └── Plex Media Server/
