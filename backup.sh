#!/bin/bash

# Directory dove salvare i backup
BACKUP_DIR="backup"
# Nome del database
DB_NAME="nphp"
# Nome del container
DB_CONTAINER="mariadb"
# Nome dell'utente e password del database
DB_USER="php"
DB_PASSWORD="php"

# Crea la directory di backup se non esiste
mkdir -p "$BACKUP_DIR"

# Nome del file di backup con timestamp
BACKUP_FILE="$BACKUP_DIR/backup_${DB_NAME}_$(date +'%Y%m%d_%H%M%S').sql"

# Esegui il backup
docker exec "$DB_CONTAINER" mysqldump -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" > "$BACKUP_FILE"

# Rimuovi i backup più vecchi di 7 giorni
find "$BACKUP_DIR" -type f -name "backup_${DB_NAME}_*.sql" -mtime +7 -exec rm {} \;

# Messaggio di conferma
echo "Backup completato: $BACKUP_FILE"
