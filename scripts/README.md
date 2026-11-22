# Lab Scripts

## Implemented week-2 scripts

| File | Purpose | Verification |
| --- | --- | --- |
| [week2-permissions.sh](week2-permissions.sh) | Shared developers access and read-only audit role | Executed with sudo; allowed/denied operations and group inheritance passed |
| [week2-security.sh](week2-security.sh) | Dedicated admin key, SSH hardening, restricted UFW, protected rollback | Executed with sudo; independent key/rejection tests passed; confirmation retained changes |

These scripts target the existing lab accounts, paths, and network. Review [stage 02](../docs/02-users-permissions.md) before considering another run. The security script deliberately requires an initially inactive firewall and an external verifier; rerunning it against the now-active policy is not an upgrade workflow. Private keys and runtime outputs are outside Git.

## Automation artifacts

| File | Responsibility | Status |
| --- | --- | --- |
| lab-monitor.sh | Resource and Nginx status report | Installed and tested; timer pending |
| user-report.sh | Local users and lab groups | Pending week 4 |
| lab-backup.sh | Backup, archive validation, retention | Pending week 4 |

[lab-monitor.sh](lab-monitor.sh) is installed and tested both manually and through its oneshot service. Its active and inactive Nginx branches passed during week 3. Scheduling is pending. user-report.sh and lab-backup.sh are not implemented yet. Use LF line endings, quoted paths, Bash error handling, and meaningful VM execution tests. Commit the same contents installed under `/usr/local/bin`. Requirements are in [stage 04](../docs/04-automation.md).

## Completed week-3 deployment

[week3-services.sh](week3-services.sh) installs Nginx, a static connectivity page, the read-only monitor, and its oneshot unit. It adds only the subnet HTTP rule, coordinates Windows-side HTTP checks and a controlled interruption, and tests a restricted operator sudo policy. Privileged execution returned WEEK3_COMPLETE: local and Windows HTTP, controlled failure/recovery, the monitor service, and restricted operator checks passed. Installed script/unit/page/server-block contents match their local copies. The continuation detects fully installed Nginx packages to avoid repeating downloads. The recovery exercise restarts Nginx on unexpected exit. No general passwordless sudo or scheduled monitoring is enabled.
