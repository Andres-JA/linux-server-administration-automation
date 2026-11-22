#!/usr/bin/env bash
# Phase 1 of week 2. Run locally on the lab VM with sudo.
# Changes project permissions and adds a locked, local audit account.
# Reports SSH/UFW state without changing either service.
set -euo pipefail
export LC_ALL=C

if (( EUID != 0 )); then
    echo "Run this script with sudo on the lab VM." >&2
    exit 1
fi

PROJECT=/srv/project
SOURCE="$PROJECT/src"
AUDIT="$PROJECT/audit"

for command in getent id stat find readlink install useradd groupadd runuser ufw sshd; do
    command -v "$command" >/dev/null || { echo "Missing command: $command" >&2; exit 1; }
done
for account in dev cloud admin devops; do
    id "$account" >/dev/null
done
getent group developers >/dev/null
for account in dev cloud; do
    id -nG "$account" | tr ' ' '\n' | grep -qx developers || {
        echo "$account must already belong to developers." >&2
        exit 1
    }
done

[[ -d "$SOURCE" && ! -L "$PROJECT" && ! -L "$SOURCE" ]]
[[ "$(readlink -f "$SOURCE")" == /srv/project/src ]]
[[ ! -L "$AUDIT" ]]

# Capture existing ownership and modes outside the repository before changes.
STAMP="$(date -u +%Y%m%dT%H%M%S)-$$"
STATE="/var/backups/linux-lab/week2-$STAMP"
install -d -o root -g root -m 700 /var/backups/linux-lab "$STATE"
find -P "$SOURCE" -xdev -printf '%m %U %G %p\n' > "$STATE/source-permissions-before.txt"
stat -c '%a %u %g %n' "$PROJECT" > "$STATE/project-permissions-before.txt"
cp -a /etc/ssh/sshd_config "$STATE/sshd_config.before"
cp -a /etc/ssh/sshd_config.d "$STATE/sshd_config.d.before"
ufw status verbose > "$STATE/ufw-before.txt"

if ! getent group auditors >/dev/null; then
    groupadd auditors
fi
if ! id auditor >/dev/null 2>&1; then
    useradd --create-home --shell /bin/bash --gid auditors --comment 'Local read-only audit role' auditor
fi
id -nG auditor | tr ' ' '\n' | grep -qx auditors || {
    echo "Existing auditor account is not in auditors; refusing to change its memberships." >&2
    exit 1
}
if id -nG auditor | tr ' ' '\n' | grep -Eq '^(sudo|admins|developers)$'; then
    echo "Auditor has conflicting privileged/project-write memberships; review manually." >&2
    exit 1
fi

echo '=== SHARED DEVELOPMENT DIRECTORY ==='
# Users work inside src; only the administrator can replace top-level role directories.
chown devops:developers "$PROJECT"
chmod 755 "$PROJECT"
# Keep existing file owners and executable bits. Do not follow symlinks or cross mounts.
find -P "$SOURCE" -xdev -type d -exec chgrp developers {} +
find -P "$SOURCE" -xdev -type d -exec chmod g+rwx,g+s,o-rwx {} +
find -P "$SOURCE" -xdev -type f -exec chgrp developers {} +
find -P "$SOURCE" -xdev -type f -exec chmod g+rw,o-rwx {} +

install -d -o root -g auditors -m 2750 "$AUDIT"
if [[ ! -e "$AUDIT/readme.txt" && ! -L "$AUDIT/readme.txt" ]]; then
    printf '%s\n' 'Read-only audit evidence for the Linux administration lab.' > "$AUDIT/readme.txt"
    chown root:auditors "$AUDIT/readme.txt"
    chmod 640 "$AUDIT/readme.txt"
fi

echo '=== ROLE MEMBERSHIPS ==='
id dev
id cloud
id auditor
echo '=== FINAL DIRECTORY MODES ==='
stat -c '%a %U:%G %n' "$SOURCE" "$AUDIT" "$AUDIT/readme.txt"

DEV_FILE="$(runuser -u dev -- mktemp "$SOURCE/week2-dev-XXXXXX.txt")"
CLOUD_FILE="$(runuser -u cloud -- mktemp "$SOURCE/week2-cloud-XXXXXX.txt")"
trap 'rm -f -- "$DEV_FILE" "$CLOUD_FILE"' EXIT
[[ "$(stat -c %G "$DEV_FILE")" == developers ]]
[[ "$(stat -c %G "$CLOUD_FILE")" == developers ]]
echo 'PASS: dev and cloud can create files; both files inherit developers.'
stat -c '%a %U:%G %n' "$DEV_FILE" "$CLOUD_FILE"
echo 'NOTE: setgid controls group inheritance; file write permissions still depend on umask.'
runuser -u dev -- chmod 660 "$DEV_FILE"
runuser -u cloud -- bash -c 'printf "%s\n" "shared-write-test" >> "$1"' bash "$DEV_FILE"
echo 'PASS: cloud can append to a dev-owned file when group-write permission is set.'

echo '=== AUDITOR ALLOWED/DENIED OPERATIONS ==='
runuser -u auditor -- cat "$AUDIT/readme.txt"
echo 'PASS: auditor can read the audit file.'
if runuser -u auditor -- test -w "$AUDIT"; then
    echo 'FAIL: auditor can write in audit directory.' >&2
    exit 1
fi
DENIED_NAME="$AUDIT/week2-denied-$STAMP.txt"
[[ ! -e "$DENIED_NAME" && ! -L "$DENIED_NAME" ]]
if runuser -u auditor -- touch "$DENIED_NAME"; then
    rm -f -- "$DENIED_NAME"
    echo 'FAIL: auditor unexpectedly created a file.' >&2
    exit 1
fi
echo 'PASS: auditor write is denied (expected).'
if runuser -u auditor -- test -x "$SOURCE"; then
    echo 'FAIL: auditor can traverse private development directory.' >&2
    exit 1
fi
echo 'PASS: auditor cannot traverse the development directory.'

echo '=== SSH EFFECTIVE CONFIGURATION (READ ONLY) ==='
sshd -t
sshd -T | grep -E '^(port|passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication|permitrootlogin|allowusers) '
echo '=== FIREWALL (READ ONLY) ==='
ufw status verbose
echo '=== SUDO POLICIES (READ ONLY) ==='
sudo -l -U dev || true
sudo -l -U auditor || true
echo "State recorded in $STATE"
echo 'WEEK2_PHASE1_COMPLETE'
echo 'SSH hardening and firewall changes have NOT been applied by this script.'
