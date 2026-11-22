#!/usr/bin/env bash
# Defaults target the lab source tree. Overrides support isolated acceptance tests.
set -euo pipefail
umask 077

SOURCE_DIR=/srv/project/src
BACKUP_DIR=/var/backups/linux-lab/archives
RETENTION_DAYS=7
while (( $# )); do
    case "$1" in
        --source) (( $# >= 2 )) || exit 2; SOURCE_DIR="$2"; shift 2 ;;
        --destination) (( $# >= 2 )) || exit 2; BACKUP_DIR="$2"; shift 2 ;;
        --retention-days) (( $# >= 2 )) || exit 2; RETENTION_DAYS="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
done
(( EUID == 0 )) || { echo 'ERROR: backup must run as root.' >&2; exit 1; }
[[ "$RETENTION_DAYS" =~ ^[1-9][0-9]{0,3}$ ]] || { echo 'ERROR: retention must be a positive number of days (up to four digits).' >&2; exit 2; }
(( RETENTION_DAYS <= 3650 )) || { echo 'ERROR: retention is outside the supported range.' >&2; exit 2; }
[[ -d "$SOURCE_DIR" && ! -L "$SOURCE_DIR" ]] || { echo "ERROR: source directory is missing or is a symlink: $SOURCE_DIR" >&2; exit 1; }
SOURCE_DIR="$(readlink -f -- "$SOURCE_DIR")"
[[ "$SOURCE_DIR" != / ]] || { echo 'ERROR: refusing the filesystem root as a source.' >&2; exit 1; }
SOURCE_NAME="$(basename -- "$SOURCE_DIR")"
[[ "$SOURCE_NAME" =~ ^[[:alnum:]_-]+$ ]] || { echo 'ERROR: source basename must contain only letters, numbers, underscore or hyphen.' >&2; exit 2; }
[[ ! -L "$BACKUP_DIR" ]] || { echo 'ERROR: destination must not be a symlink.' >&2; exit 1; }
BACKUP_DIR="$(realpath -m -- "$BACKUP_DIR")"
[[ "$BACKUP_DIR" != / && "$BACKUP_DIR" != "$SOURCE_DIR" && "$BACKUP_DIR" != "$SOURCE_DIR/"* ]] || {
    echo 'ERROR: destination must be outside the source tree and cannot be /.' >&2
    exit 1
}
install -d -o root -g root -m 700 "$BACKUP_DIR"
exec 9> "$BACKUP_DIR/.backup.lock"
flock -n 9 || { echo 'ERROR: another backup is already running for this destination.' >&2; exit 1; }

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
TEMP_ARCHIVE="$(mktemp --tmpdir="$BACKUP_DIR" ".${SOURCE_NAME}-${STAMP}-XXXXXX.partial")"
trap '[[ -z "${TEMP_ARCHIVE:-}" ]] || rm -f -- "$TEMP_ARCHIVE"' EXIT
tar -czf "$TEMP_ARCHIVE" -C "$(dirname -- "$SOURCE_DIR")" -- "$SOURCE_NAME"
tar -tzf "$TEMP_ARCHIVE" > /dev/null
ARCHIVE_NAME="$(basename -- "$TEMP_ARCHIVE" .partial)"
ARCHIVE="$BACKUP_DIR/${ARCHIVE_NAME#.}.tar.gz"
# A hard link publishes the validated archive atomically and refuses replacement.
ln -- "$TEMP_ARCHIVE" "$ARCHIVE"
rm -- "$TEMP_ARCHIVE"
TEMP_ARCHIVE=''

echo "Backup created and archive listing verified: $ARCHIVE"
stat -c 'Archive permissions: %a %U:%G' "$ARCHIVE"
sha256sum "$ARCHIVE"
echo "Retention: delete only ${SOURCE_NAME}-*.tar.gz at this destination with at least $RETENTION_DAYS complete 24-hour periods."
find "$BACKUP_DIR" -maxdepth 1 -type f -name "${SOURCE_NAME}-*.tar.gz" -mtime "+$((RETENTION_DAYS - 1))" -print -delete
echo 'BACKUP_COMPLETE'
