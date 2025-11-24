#!/usr/bin/with-contenv bash
set -e

VARS_FILE="/config/variables.yml"

# Genera un variables.yml simple con las credenciales de OpenSubtitles.
# Si ya tienes más variables ahí y las quieres conservar, habría que hacer merge;
# de momento esto lo sobrescribe.
cat > "$VARS_FILE" <<EOF
OS_USER: "${OS_USER:-}"
OS_PASS: "${OS_PASS:-}"
EOF
