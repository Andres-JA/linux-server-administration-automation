#!/usr/bin/env bash
# Lab-specific week-3 deployment and externally verified recovery exercise.
# Run with sudo on linux-server. Never grants general passwordless sudo.
set -euo pipefail
export LC_ALL=C
(( EUID == 0 )) || { echo 'Run with sudo on the lab VM.' >&2; exit 1; }
exec 2>&1
[[ "$(hostname)" == linux-server ]]
STAGING=/home/devops/linux-lab-week3
MANAGEMENT_SUBNET=192.168.100.0/24
for tool in apt-get curl ufw systemctl systemd-analyze visudo runuser ssh-keygen; do
    command -v "$tool" >/dev/null || { echo "Missing command: $tool" >&2; exit 1; }
done
id devops >/dev/null
ufw status | grep -qx 'Status: active' || { echo 'Expected the confirmed week-2 firewall.' >&2; exit 1; }
for artifact in lab-monitor.sh lab-monitor.service index.html linux-lab.conf; do
    [[ -f "$STAGING/$artifact" && ! -L "$STAGING/$artifact" ]]
done
[[ ! -L /var/www/linux-lab ]]
if [[ -e /etc/nginx/sites-enabled/default && ! -L /etc/nginx/sites-enabled/default ]]; then
    echo 'Unexpected regular file at sites-enabled/default; review before replacing.' >&2
    exit 1
fi
TOKEN="$(cat /proc/sys/kernel/random/uuid)"
STAMP="$(date -u +%Y%m%dT%H%M%S)-$$"
STATE="/var/backups/linux-lab/week3-$STAMP"
install -d -o root -g root -m 700 /var/backups/linux-lab "$STATE"
for artifact in lab-monitor.sh lab-monitor.service index.html linux-lab.conf; do
    install -o root -g root -m 600 "$STAGING/$artifact" "$STATE/$artifact"
done
ufw status verbose > "$STATE/ufw-before.txt"
cp -a /etc/ufw "$STATE/ufw.before"
if [[ -d /etc/nginx ]]; then cp -a /etc/nginx "$STATE/nginx.before"; fi
if [[ -e /usr/local/bin/lab-monitor.sh ]]; then cp -a /usr/local/bin/lab-monitor.sh "$STATE/lab-monitor.before"; fi
if [[ -e /etc/systemd/system/lab-monitor.service ]]; then cp -a /etc/systemd/system/lab-monitor.service "$STATE/lab-monitor-service.before"; fi
bash -n "$STATE/lab-monitor.sh"

echo '=== PACKAGE INSTALLATION ==='
PACKAGE_STATUS="$(dpkg-query -W -f '${Status}\n' nginx nginx-common 2>/dev/null || true)"
if [[ "$PACKAGE_STATUS" == $'install ok installed\ninstall ok installed' ]]; then
    echo 'nginx and nginx-common are fully installed; skipping downloads.'
    DPKG_AUDIT="$(dpkg --audit)"
    [[ -z "$DPKG_AUDIT" ]] || { printf '%s\n' "$DPKG_AUDIT" >&2; exit 1; }
else
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
fi

# Once Nginx is installed, never leave it down if the exercise aborts.
trap 'status=$?; systemctl start nginx || true; exit "$status"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

install -d -o root -g root -m 755 /var/www/linux-lab
install -o root -g root -m 644 "$STATE/index.html" /var/www/linux-lab/index.html
install -o root -g root -m 644 "$STATE/linux-lab.conf" /etc/nginx/sites-available/linux-lab
if [[ -L /etc/nginx/sites-enabled/default ]]; then rm -- /etc/nginx/sites-enabled/default; fi
if [[ -e /etc/nginx/sites-enabled/linux-lab && ! -L /etc/nginx/sites-enabled/linux-lab ]]; then
    echo 'Unexpected regular file at sites-enabled/linux-lab.' >&2
    exit 1
fi
ln -sfn /etc/nginx/sites-available/linux-lab /etc/nginx/sites-enabled/linux-lab
nginx -t
systemctl enable --now nginx
systemctl reload nginx
ufw allow from "$MANAGEMENT_SUBNET" to any port 80 proto tcp comment 'Linux lab HTTP management subnet'
install -o root -g root -m 755 "$STATE/lab-monitor.sh" /usr/local/bin/lab-monitor.sh
install -o root -g root -m 644 "$STATE/lab-monitor.service" /etc/systemd/system/lab-monitor.service
systemd-analyze verify /etc/systemd/system/lab-monitor.service
systemctl daemon-reload

echo '=== NGINX INITIAL VALIDATION ==='
nginx -v
systemctl is-active nginx
systemctl is-enabled nginx
ss -ltnp '( sport = :80 )'
curl --fail --silent --show-error --head --max-time 10 http://127.0.0.1/
curl --fail --silent --show-error --max-time 10 http://127.0.0.1/ | grep -F 'Linux Server'

valid_marker() {
    local path="$1"
    [[ -f "$path" && ! -L "$path" ]] &&
        [[ "$(stat -c %U "$path")" == devops ]] &&
        grep -qxF "$TOKEN" "$path"
}
wait_for_marker() {
    local path="$1" seconds="$2" deadline=$((SECONDS + $2))
    until valid_marker "$path"; do
        (( SECONDS < deadline )) || { echo "Missing external verification: $path" >&2; return 1; }
        sleep 1
    done
}
echo "WEEK3_READY_FOR_HTTP_TEST $TOKEN"
echo 'Nginx is running. Tell the verifier you are ready; keep this command running.'
wait_for_marker "$STAGING/http-initial-$TOKEN" 3600

echo '=== CONTROLLED SERVICE INTERRUPTION ==='
systemctl stop nginx
if systemctl is-active --quiet nginx; then echo 'Nginx failed to stop.' >&2; exit 1; fi
echo 'nginx: inactive (expected)'
if curl --silent --show-error --head --max-time 5 http://127.0.0.1/; then
    echo 'Unexpected HTTP response while Nginx is stopped.' >&2
    exit 1
else
    CURL_EXIT=$?
    [[ "$CURL_EXIT" -eq 7 ]] || { echo "Unexpected curl failure: $CURL_EXIT" >&2; exit 1; }
    echo 'Local curl exit 7: connection refused (expected).'
fi
/usr/local/bin/lab-monitor.sh | grep -F 'nginx: NOT active'
echo "WEEK3_NGINX_STOPPED $TOKEN"
wait_for_marker "$STAGING/http-stopped-$TOKEN" 45
systemctl start nginx
systemctl is-active --quiet nginx
curl --fail --silent --show-error --head --max-time 10 http://127.0.0.1/
echo 'PASS: Nginx restarted and local HTTP recovered.'

echo '=== PROCESSES AND JOURNAL ==='
pgrep -a nginx
ps -C nginx -o pid,ppid,user,%cpu,%mem,args
journalctl -u nginx -n 18 --no-pager

echo '=== MONITOR MANUAL EXECUTION ==='
runuser -u devops -- /usr/local/bin/lab-monitor.sh
echo '=== MONITOR ONESHOT SERVICE ==='
systemctl start lab-monitor.service
MONITOR_STATE="$(systemctl show lab-monitor.service -p Result -p ExecMainStatus -p ActiveState)"
printf '%s\n' "$MONITOR_STATE"
grep -qx 'Result=success' <<< "$MONITOR_STATE"
grep -qx 'ExecMainStatus=0' <<< "$MONITOR_STATE"
journalctl -u lab-monitor.service -n 28 --no-pager

echo '=== OPTIONAL LEAST-PRIVILEGE OPERATOR ==='
if ! getent group operators >/dev/null; then groupadd operators; fi
if ! id operator >/dev/null 2>&1; then
    useradd --create-home --shell /bin/bash --gid operators --comment 'Local Nginx operator' operator
fi
id -nG operator | tr ' ' '\n' | grep -qx operators
if id -nG operator | tr ' ' '\n' | grep -Eq '^(sudo|admins|developers)$'; then
    echo 'Operator has conflicting privileged groups; review manually.' >&2
    exit 1
fi
SYSTEMCTL="$(command -v systemctl)"
printf 'operator ALL=(root) NOPASSWD: %s restart nginx\n' "$SYSTEMCTL" > "$STATE/lab-operator.sudoers"
visudo -cf "$STATE/lab-operator.sudoers"
if [[ -e /etc/sudoers.d/lab-operator ]]; then cp -a /etc/sudoers.d/lab-operator "$STATE/lab-operator.before"; fi
install -o root -g root -m 440 "$STATE/lab-operator.sudoers" /etc/sudoers.d/lab-operator
visudo -c
sudo -l -U operator
runuser -u operator -- sudo -n "$SYSTEMCTL" restart nginx
echo 'PASS: operator can restart Nginx with the exact permitted command.'
if runuser -u operator -- sudo -n /usr/bin/id; then
    echo 'FAIL: operator unexpectedly has general sudo.' >&2
    exit 1
fi
echo 'PASS: unrelated sudo id is denied.'
systemctl is-active --quiet nginx
echo '=== FINAL FIREWALL POLICY ==='
ufw status verbose
echo "WEEK3_READY_FOR_FINAL_HTTP $TOKEN"
wait_for_marker "$STAGING/http-final-$TOKEN" 180
echo 'WEEK3_COMPLETE'
echo "Pre-change state recorded in $STATE"
echo 'Nginx and the monitor service are installed; scheduling and backups remain week 4.'
