#!/bin/sh
# Script de Transmission: se ejecuta cuando un torrent termina.
# Variables que expone Transmission:
#   TR_TORRENT_DIR  -> directorio donde se descargó
#   TR_TORRENT_NAME -> nombre del torrent

TORRENT_DIR="$TR_TORRENT_DIR"
TORRENT_NAME="$TR_TORRENT_NAME"

LOGFILE="/config/on-complete.log"

echo "[$(date -Iseconds)] Torrent completado: '$TORRENT_NAME' en '$TORRENT_DIR'" >> "$LOGFILE"

# Directorio destino en Plex (mapeado a data/media/movies en el host)
DEST_ROOT="/movies"
DEST_DIR="${DEST_ROOT}/${TORRENT_NAME}"

mkdir -p "$DEST_DIR"

# Mover todos los archivos de vídeo al destino, ignorando 'sample'
find "$TORRENT_DIR" \
  -type f \
  \( -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.avi' -o -iname '*.mov' \) \
  ! -iname '*sample*' \
  -print0 | while IFS= read -r -d '' file; do
    echo "[$(date -Iseconds)] Moviendo '$file' -> '$DEST_DIR'" >> "$LOGFILE"
    mv "$file" "$DEST_DIR"/
done

echo "[$(date -Iseconds)] Fin script on-complete para '$TORRENT_NAME'" >> "$LOGFILE"
