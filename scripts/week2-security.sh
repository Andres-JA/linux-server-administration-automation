#!/usr/bin/env bash
# Lab-specific SSH/UFW phase. Invoke with sudo from a working session.
# Waits for the remote verifier before applying changes, then requires two
# independent key-login acknowledgements before confirming a timed rollback.
set -euo pipefail
export LC_ALL=C
(( EUID == 0 )) || { echo 'Run with sudo on the lab VM.' >&2; exit 1; }

STAGING=/home/devops/linux-lab-week2
HARDENING=/etc/ssh/sshd_config.d/00-lab-hardening.conf
ADMIN_AUTH=/home/admin/.ssh/authorized_keys
SOURCE_IP=192.168.100.176
MANAGEMENT_SUBNET=192.168.100.0/24
for tool in sshd ssh-keygen ufw systemd-run systemctl install stat grep cp; do
    command -v "$tool" >/dev/null || { echo "Missing: $tool" >&2; exit 1; }
done
[[ "$(hostname)" == linux-server ]]
[[ "$(getent passwd admin | cut -d: -f6)" == /home/admin ]]
[[ "$(getent passwd devops | cut -d: -f6)" == /home/devops ]]
[[ ! -L /home/admin && ! -L /home/admin/.ssh && ! -L "$ADMIN_AUTH" ]]
[[ ! -L "$HARDENING" ]]
grep -qx 'IPV6=yes' /etc/default/ufw
ufw status | grep -qx 'Status: inactive' || {
    echo 'Existing firewall policy is active; review it before applying this lab-specific script.' >&2
    exit 1
}
sshd -t
INITIAL_EFFECTIVE="$(sshd -T)"
grep -qx 'allowusers devops' <<< "$INITIAL_EFFECTIVE"
grep -qx 'allowusers admin' <<< "$INITIAL_EFFECTIVE"
[[ -s /home/devops/.ssh/authorized_keys ]]
ssh-keygen -lf "$STAGING/admin-key.pub" >/dev/null
[[ "$(wc -l < "$STAGING/admin-key.pub")" -eq 1 ]]
grep -q '^ssh-ed25519 ' "$STAGING/admin-key.pub"

# Waiting here makes no access changes and does not start the rollback clock.
# Only fixed marker contents are read; marker files are never executed as root.
TOKEN="$(cat /proc/sys/kernel/random/uuid)"
START_MARKER="$STAGING/start-$TOKEN"
DEVOPS_MARKER="$STAGING/devops-verified-$TOKEN"
ADMIN_MARKER="/home/admin/.ssh/admin-verified-$TOKEN"
valid_marker() {
    local path="$1" owner="$2"
    [[ -f "$path" && ! -L "$path" ]] &&
        [[ "$(stat -c %U "$path")" == "$owner" ]] &&
        grep -qxF "$TOKEN" "$path"
}
echo "WEEK2_READY_FOR_VERIFIER $TOKEN"
echo 'No changes yet. Tell the remote verifier you are ready; keep this command running.'
DEADLINE=$((SECONDS + 3600))
until valid_marker "$START_MARKER" devops; do
    (( SECONDS < DEADLINE )) || { echo 'Verifier did not start; exiting without changes.' >&2; exit 1; }
    sleep 2
done
# Check for concurrent changes again before taking the recovery snapshot.
ufw status | grep -qx 'Status: inactive'
sshd -t
echo 'Verifier is connected; starting the protected apply phase now.'

STAMP="$(date -u +%Y%m%dT%H%M%S)-$$"
STATE="/var/backups/linux-lab/week2-security-$STAMP"
UNIT="linux-lab-week2-rollback-$(date +%s)-$$"
install -d -o root -g root -m 700 /var/backups/linux-lab "$STATE"
cp -a /etc/ufw "$STATE/ufw.before"
cp -a /etc/default/ufw "$STATE/default-ufw.before"
cp -a /etc/ssh/sshd_config "$STATE/sshd_config.before"
cp -a "$STAGING/admin-key.pub" "$STATE/admin-key.pub"
if [[ -e "$HARDENING" ]]; then cp -a "$HARDENING" "$STATE/hardening.before"; fi
if [[ -e "$ADMIN_AUTH" ]]; then cp -a "$ADMIN_AUTH" "$STATE/admin-authorized-keys.before"; fi

# Protected recovery files are generated before changing access settings.
{
    printf '#!/usr/bin/env bash\nset -euo pipefail\nSTATE=%q\nHARDENING=%q\nADMIN_AUTH=%q\n' "$STATE" "$HARDENING" "$ADMIN_AUTH"
    cat <<'ROLLBACK'
[[ ! -e "$STATE/confirmed" ]] || exit 0
ufw --force disable
cp -a "$STATE/ufw.before/." /etc/ufw/
cp -a "$STATE/default-ufw.before" /etc/default/ufw
if [[ -e "$STATE/hardening.before" ]]; then
    cp -a "$STATE/hardening.before" "$HARDENING"
else
    rm -f -- "$HARDENING"
fi
if [[ -e "$STATE/admin-authorized-keys.before" ]]; then
    cp -a "$STATE/admin-authorized-keys.before" "$ADMIN_AUTH"
else
    rm -f -- "$ADMIN_AUTH"
fi
sshd -t
systemctl reload ssh
touch "$STATE/rolled-back"
printf 'Rolled back SSH hardening, admin authorized_keys, and the previously inactive UFW policy.\n'
ROLLBACK
} > "$STATE/rollback.sh"
{
    printf '#!/usr/bin/env bash\nset -euo pipefail\nSTATE=%q\nUNIT=%q\n' "$STATE" "$UNIT"
    cat <<'CONFIRM'
(( EUID == 0 )) || { echo 'Run with sudo.' >&2; exit 1; }
[[ ! -e "$STATE/rolled-back" ]] || { echo 'Rollback already ran. Do not confirm; review state.' >&2; exit 1; }
systemctl is-active --quiet "$UNIT.timer" || { echo 'Rollback timer is no longer active; inspect state before confirming.' >&2; exit 1; }
sshd -t
systemctl stop "$UNIT.timer"
if systemctl is-active --quiet "$UNIT.service"; then
    echo 'Rollback service has already started. Do not confirm; review state.' >&2
    exit 1
fi
[[ ! -e "$STATE/rolled-back" ]]
touch "$STATE/confirmed"
echo 'WEEK2_SECURITY_CONFIRMED'
CONFIRM
} > "$STATE/confirm.sh"
chmod 700 "$STATE/rollback.sh" "$STATE/confirm.sh"
bash -n "$STATE/rollback.sh"
bash -n "$STATE/confirm.sh"

systemd-run --unit="$UNIT" --on-active=10m --timer-property=AccuracySec=1s "$STATE/rollback.sh"
trap 'status=$?; if (( status != 0 )); then echo "Apply failed; rolling back." >&2; bash "$STATE/rollback.sh"; systemctl stop "$UNIT.timer" || true; fi; exit "$status"' EXIT

install -d -o admin -g "$(id -gn admin)" -m 700 /home/admin/.ssh
if [[ ! -e "$ADMIN_AUTH" ]]; then
    install -o admin -g "$(id -gn admin)" -m 600 /dev/null "$ADMIN_AUTH"
fi
chown admin:"$(id -gn admin)" "$ADMIN_AUTH"
chmod 600 "$ADMIN_AUTH"
PUBLIC_KEY="$(cat "$STATE/admin-key.pub")"
if ! grep -qxF "$PUBLIC_KEY" "$ADMIN_AUTH"; then
    # A separating newline also handles an existing file without a final newline.
    printf '\n%s\n' "$PUBLIC_KEY" >> "$ADMIN_AUTH"
fi
cat > "$HARDENING" <<'SSHCONFIG'
# Linux lab: validate key login before disabling password authentication.
# The main configuration retains AllowUsers devops admin.
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
PermitRootLogin no
SSHCONFIG
chown root:root "$HARDENING"
chmod 644 "$HARDENING"
sshd -t
EFFECTIVE="$(sshd -T -C "user=devops,host=windows-lab,addr=$SOURCE_IP")"
for setting in 'passwordauthentication no' 'kbdinteractiveauthentication no' 'pubkeyauthentication yes' 'permitrootlogin no'; do
    grep -qxF "$setting" <<< "$EFFECTIVE"
done
systemctl reload ssh
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow from "$MANAGEMENT_SUBNET" to any port 22 proto tcp comment 'Linux lab management subnet'
ufw --force enable
echo '=== EFFECTIVE SSH ==='
sshd -T | grep -E '^(passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication|permitrootlogin|allowusers) '
echo '=== FIREWALL ==='
ufw status verbose
echo 'WEEK2_SECURITY_APPLIED_PENDING_CONFIRMATION'
printf 'Automatic rollback is armed for 10 minutes. Keep your current SSH session open.\n'
printf 'For immediate manual rollback:\nsudo bash %s/rollback.sh\n' "$STATE"
echo "WEEK2_WAITING_FOR_KEY_CHECKS $TOKEN"
DEADLINE=$((SECONDS + 300))
until valid_marker "$DEVOPS_MARKER" devops && valid_marker "$ADMIN_MARKER" admin; do
    (( SECONDS < DEADLINE )) || { echo 'Independent key checks did not arrive; reverting.' >&2; exit 1; }
    sleep 2
done
bash "$STATE/confirm.sh"
echo 'Both administrative key connections were acknowledged. Automatic rollback cancelled.'
