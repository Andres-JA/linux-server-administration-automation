#!/usr/bin/env bash
# Read-only account report; UID range is a heuristic, not proof of human ownership.
set -euo pipefail

echo '=== Local human-user candidates: 1000 <= UID < 65534 ==='
getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 {print $1 " | UID=" $3 " | home=" $6}'
echo '=== Lab groups ==='
for group in developers operators auditors admins; do
    if ! getent group "$group"; then
        echo "Missing expected lab group: $group" >&2
        exit 1
    fi
done
