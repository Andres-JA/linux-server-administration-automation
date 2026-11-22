#!/usr/bin/env bash
# Lab-specific installation, scheduled-execution tests, retention and restore proof.
# Package upgrades are intentionally excluded; available updates are recorded.
set -euo pipefail
export LC_ALL=C
(( EUID == 0 )) || { echo 'Run with sudo on the lab VM.' >&2; exit 1; }
exec 2>&1
[[ "$(hostname)" == linux-server ]]
STAGING=/home/devops/linux-lab-week4
UNITS=(lab-monitor.service lab-monitor.timer lab-backup.service lab-backup.timer)
for tool in systemctl systemd-analyze timedatectl tar sha256sum flock runuser getent curl diff; do
    command -v "$tool" >/dev/null || { echo "Missing command: $tool" >&2; exit 1; }
done
for artifact in lab-monitor.sh user-report.sh lab-backup.sh README-structure.txt "${UNITS[@]}"; do
    [[ -f "$STAGING/$artifact" && ! -L "$STAGING/$artifact" ]]
done
[[ -d /srv/project/src && ! -L /srv/project/src ]]
systemctl is-active --quiet ssh
systemctl is-active --quiet nginx
TOKEN="$(cat /proc/sys/kernel/random/uuid)"
STAMP="$(date -u +%Y%m%dT%H%M%S)-$$"
STATE="/var/backups/linux-lab/week4-$STAMP"
install -d -o root -g root -m 700 /var/backups/linux-lab "$STATE"
for artifact in lab-monitor.sh user-report.sh lab-backup.sh README-structure.txt "${UNITS[@]}"; do
    install -o root -g root -m 600 "$STAGING/$artifact" "$STATE/$artifact"
done
for script in lab-monitor.sh user-report.sh lab-backup.sh; do
    bash -n "$STATE/$script"
    if [[ -e "/usr/local/bin/$script" ]]; then cp -a "/usr/local/bin/$script" "$STATE/$script.before"; fi
done
for unit in "${UNITS[@]}"; do
    if [[ -e "/etc/systemd/system/$unit" ]]; then cp -a "/etc/systemd/system/$unit" "$STATE/$unit.before"; fi
done
if [[ -e /srv/project/README-structure.txt ]]; then cp -a /srv/project/README-structure.txt "$STATE/README-structure.before"; fi
timedatectl > "$STATE/timezone-before.txt"
timedatectl set-timezone America/Guayaquil

install -d -o root -g root -m 700 /var/backups/linux-lab/archives
install -o root -g root -m 755 "$STATE/lab-monitor.sh" /usr/local/bin/lab-monitor.sh
install -o root -g root -m 755 "$STATE/user-report.sh" /usr/local/bin/user-report.sh
install -o root -g root -m 750 "$STATE/lab-backup.sh" /usr/local/bin/lab-backup.sh
install -o root -g root -m 644 "$STATE/README-structure.txt" /srv/project/README-structure.txt
for unit in "${UNITS[@]}"; do
    install -o root -g root -m 644 "$STATE/$unit" "/etc/systemd/system/$unit"
done
systemd-analyze verify "${UNITS[@]/#//etc/systemd/system/}"
systemctl daemon-reload

echo '=== MONITOR MANUAL EXECUTION ==='
runuser -u devops -- /usr/local/bin/lab-monitor.sh
echo '=== USER REPORT ==='
runuser -u devops -- /usr/local/bin/user-report.sh
echo '=== BACKUP PRIVILEGE CHECK ==='
if runuser -u devops -- /usr/local/bin/lab-backup.sh; then
    echo 'FAIL: non-root backup unexpectedly succeeded.' >&2; exit 1
fi
echo 'PASS: non-root backup execution is denied.'

echo '=== BACKUP AND RESTORE ==='
TEST_NAME="week4-restore-$STAMP.txt"
TEST_FILE="/srv/project/src/$TEST_NAME"
[[ ! -e "$TEST_FILE" && ! -L "$TEST_FILE" ]]
printf 'Linux lab restore verification: %s\n' "$STAMP" > "$TEST_FILE"
chown root:developers "$TEST_FILE"
chmod 640 "$TEST_FILE"
BACKUP_OUTPUT="$(/usr/local/bin/lab-backup.sh)"
printf '%s\n' "$BACKUP_OUTPUT"
ARCHIVE="$(sed -n 's/^Backup created and archive listing verified: //p' <<< "$BACKUP_OUTPUT")"
[[ "$ARCHIVE" == /var/backups/linux-lab/archives/src-*.tar.gz && -f "$ARCHIVE" && ! -L "$ARCHIVE" ]]
RESTORE="$(mktemp -d /var/tmp/linux-lab-restore-XXXXXX)"
tar -xzf "$ARCHIVE" -C "$RESTORE"
if diff -- "$TEST_FILE" "$RESTORE/src/$TEST_NAME"; then
    echo 'diff exit code: 0'
else
    echo 'FAIL: restored content differs from source.' >&2; exit 1
fi
sha256sum "$TEST_FILE" "$RESTORE/src/$TEST_NAME"
echo "Archive tested: $ARCHIVE"
echo "Restored file: $RESTORE/src/$TEST_NAME"
if runuser -u devops -- test -r "$ARCHIVE"; then
    echo 'FAIL: archive is readable by non-root devops.' >&2; exit 1
fi
echo 'PASS: backup archive is restricted to root; restore content matches.'

echo '=== ISOLATED RETENTION AND MISSING-SOURCE TESTS ==='
FIXTURE="$(mktemp -d /var/tmp/linux-lab-retention-XXXXXX)"
install -d -o root -g root -m 700 "$FIXTURE/src" "$FIXTURE/archives"
printf '%s\n' 'Disposable retention fixture; no production source data.' > "$FIXTURE/src/example.txt"
FIXTURE_OUTPUT="$(/usr/local/bin/lab-backup.sh --source "$FIXTURE/src" --destination "$FIXTURE/archives")"
CURRENT="$(sed -n 's/^Backup created and archive listing verified: //p' <<< "$FIXTURE_OUTPUT")"
OLD="$FIXTURE/archives/src-20000101T000000Z-retention.tar.gz"
UNRELATED="$FIXTURE/archives/keep-unrelated.tar.gz"
cp -- "$CURRENT" "$OLD"
printf '%s\n' 'Unrelated file: retention must leave this alone.' > "$UNRELATED"
touch -d '10 days ago' "$OLD" "$UNRELATED"
mkdir "$FIXTURE/archives/keep-directory"
/usr/local/bin/lab-backup.sh --source "$FIXTURE/src" --destination "$FIXTURE/archives"
[[ ! -e "$OLD" && -f "$UNRELATED" && -d "$FIXTURE/archives/keep-directory" ]]
echo 'PASS: aged matching archive removed; unrelated file and directory preserved.'
if /usr/local/bin/lab-backup.sh --source "$FIXTURE/missing/src" --destination "$FIXTURE/archives"; then
    echo 'FAIL: missing source unexpectedly succeeded.' >&2; exit 1
fi
echo 'PASS: missing-source backup fails before producing an archive.'
echo "Retention fixture retained for inspection: $FIXTURE"

echo '=== MANUAL SERVICE RESULTS ==='
systemctl start lab-monitor.service lab-backup.service
for service in lab-monitor.service lab-backup.service; do
    PROPERTIES="$(systemctl show "$service" -p ActiveState -p Result -p ExecMainStatus -p InvocationID)"
    printf '%s\n%s\n' "$service" "$PROPERTIES"
    grep -qx 'Result=success' <<< "$PROPERTIES"
    grep -qx 'ExecMainStatus=0' <<< "$PROPERTIES"
done
MONITOR_BEFORE="$(systemctl show lab-monitor.service -p ExecMainStartTimestampMonotonic --value)"
BACKUP_BEFORE="$(systemctl show lab-backup.service -p ExecMainStartTimestampMonotonic --value)"
MONITOR_BEFORE="${MONITOR_BEFORE:-0}"
BACKUP_BEFORE="${BACKUP_BEFORE:-0}"

# Exercise real timer-triggered invocations without waiting for tomorrow at 02:00.
# These temporary runtime delays are explicitly removed after the test.
MONITOR_OVERRIDE=/run/systemd/system/lab-monitor.timer.d/90-lab-verification.conf
BACKUP_OVERRIDE=/run/systemd/system/lab-backup.timer.d/90-lab-verification.conf
[[ ! -e "$MONITOR_OVERRIDE" && ! -L "$MONITOR_OVERRIDE" && ! -e "$BACKUP_OVERRIDE" && ! -L "$BACKUP_OVERRIDE" ]]
cleanup_verification() {
    rm -f -- "$MONITOR_OVERRIDE" "$BACKUP_OVERRIDE"
    systemctl daemon-reload
    systemctl restart lab-monitor.timer lab-backup.timer
}
trap 'status=$?; cleanup_verification || true; exit "$status"' EXIT
install -d -o root -g root -m 755 "$(dirname "$MONITOR_OVERRIDE")" "$(dirname "$BACKUP_OVERRIDE")"
printf '[Timer]\nOnActiveSec=30s\n' > "$MONITOR_OVERRIDE"
printf '[Timer]\nOnActiveSec=45s\n' > "$BACKUP_OVERRIDE"
systemctl daemon-reload
systemctl enable --now lab-monitor.timer lab-backup.timer
echo '=== WAITING FOR REAL TIMER TRIGGERS ==='
echo 'Temporary runtime verification: monitor after 30s, backup after 45s.'
DEADLINE=$((SECONDS + 180))
while :; do
    MONITOR_AFTER="$(systemctl show lab-monitor.service -p ExecMainStartTimestampMonotonic --value)"
    BACKUP_AFTER="$(systemctl show lab-backup.service -p ExecMainStartTimestampMonotonic --value)"
    if [[ "${MONITOR_AFTER:-0}" -gt "$MONITOR_BEFORE" && "${BACKUP_AFTER:-0}" -gt "$BACKUP_BEFORE" ]] &&
       systemctl show lab-monitor.service -p Result --value | grep -qx success &&
       systemctl show lab-backup.service -p Result --value | grep -qx success &&
       systemctl show lab-monitor.service -p ActiveState --value | grep -qx inactive &&
       systemctl show lab-backup.service -p ActiveState --value | grep -qx inactive; then
        break
    fi
    (( SECONDS < DEADLINE )) || { echo 'Timer verification timed out.' >&2; exit 1; }
    sleep 2
done
for timer in lab-monitor.timer lab-backup.timer; do
    systemctl show "$timer" -p ActiveState -p LastTriggerUSec -p Triggers
done
printf 'Monitor start monotonic before: %s\nMonitor start monotonic after: %s\n' "$MONITOR_BEFORE" "$MONITOR_AFTER"
printf 'Backup start monotonic before: %s\nBackup start monotonic after: %s\n' "$BACKUP_BEFORE" "$BACKUP_AFTER"
echo 'PASS: new successful service invocations were triggered by active timers.'
cleanup_verification
trap - EXIT

echo '=== PERMANENT TIMER SCHEDULE ==='
timedatectl
systemctl list-timers --all --no-pager | grep -E 'NEXT|lab-monitor|lab-backup'
for timer in lab-monitor.timer lab-backup.timer; do
    systemctl is-enabled "$timer"
    systemctl show "$timer" -p ActiveState -p DropInPaths -p NextElapseUSecRealtime -p NextElapseUSecMonotonic
done
echo 'Permanent monitor: OnBootSec=2min and OnUnitActiveSec=15min.'
echo 'Permanent backup: daily 02:00 America/Guayaquil, Persistent=true.'
echo 'Temporary 30s/45s runtime verification files have been removed.'
echo '=== BACKUP SERVICE JOURNAL ==='
journalctl -u lab-backup.service -n 24 --no-pager
echo '=== MONITOR SERVICE JOURNAL ==='
journalctl -u lab-monitor.service -n 22 --no-pager

echo '=== SYSTEM BASELINE AND FINAL ACCEPTANCE ==='
hostnamectl | grep -E 'Static hostname|Operating System|Kernel|Virtualization|Architecture'
nproc
free -h
df -h /
ip -4 -br addr
ip -4 route
systemctl is-active ssh nginx lab-monitor.timer lab-backup.timer
sshd -t
sshd -T | grep -E '^(passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication|permitrootlogin|allowusers) '
ufw status verbose
for account in dev cloud admin auditor operator; do id "$account"; done
readlink -f /srv/project/config/app.conf
[[ -f /srv/project/config/app.conf ]]
echo 'PASS: configuration symlink target exists.'
echo '=== PACKAGE MAINTENANCE CHECKPOINT ==='
echo 'Available updates are recorded from the existing APT metadata; no system upgrade was requested.'
apt list --upgradable 2>/dev/null | awk 'NR>1 {count++} END {printf "Available package updates in current metadata: %d\n", count}'
echo 'OS patching remains a separately selected maintenance task.'
echo '=== INSTALLED ARTIFACT HASHES ==='
sha256sum /usr/local/bin/lab-monitor.sh /usr/local/bin/user-report.sh /usr/local/bin/lab-backup.sh \
    /etc/systemd/system/lab-monitor.service /etc/systemd/system/lab-monitor.timer \
    /etc/systemd/system/lab-backup.service /etc/systemd/system/lab-backup.timer \
    /srv/project/README-structure.txt
echo "WEEK4_READY_FOR_FINAL_VERIFY $TOKEN"
echo 'Keep this command running for independent SSH/HTTP and file-match checks.'
MARKER="$STAGING/final-verified-$TOKEN"
DEADLINE=$((SECONDS + 3600))
until [[ -f "$MARKER" && ! -L "$MARKER" ]] &&
      [[ "$(stat -c %U "$MARKER")" == devops ]] && grep -qxF "$TOKEN" "$MARKER"; do
    (( SECONDS < DEADLINE )) || { echo 'External final verification did not arrive.' >&2; exit 1; }
    sleep 2
done
echo 'WEEK4_COMPLETE'
echo 'CORE_LAB_ACCEPTANCE_PASSED'
echo "Pre-change state: $STATE"
