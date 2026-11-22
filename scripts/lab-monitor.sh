#!/usr/bin/env bash
# Read-only resource report. Scheduling is introduced in week 4.
set -euo pipefail

echo '=== Linux Lab Monitoring ==='
echo "Timestamp: $(date --iso-8601=seconds)"
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime -p)"
echo '--- CPU / load ---'
echo "Logical CPUs: $(nproc)"
uptime
echo '--- Memory ---'
free -h
echo '--- Root filesystem ---'
df -h /
echo '--- Service status ---'
if systemctl is-active --quiet nginx; then
    echo 'nginx: active'
else
    echo 'nginx: NOT active'
fi
