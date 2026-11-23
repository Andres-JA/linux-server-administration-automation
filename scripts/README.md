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
| [lab-monitor.sh](lab-monitor.sh) | Resource and Nginx status report | Installed; manual/service/timer tests passed |
| [user-report.sh](user-report.sh) | Local users and lab groups | Installed; read-only execution passed |
| [lab-backup.sh](lab-backup.sh) | Protected archives, validation, locking, retention | Installed; service/timer, restore, retention and failure tests passed |

All three scripts are installed. The monitor's active/inactive branches were tested in week 3, and automatic invocation was verified in week 4. Matching operational copies live under /usr/local/bin with LF line endings. The backup is installed mode 750 and requires root; the reports are mode 755 and run unprivileged. Real archives and raw logs remain outside Git. See [stage 04](../docs/04-automation.md).

## Completed week-3 deployment

[week3-services.sh](week3-services.sh) installs Nginx, a static connectivity page, the read-only monitor, and its oneshot unit. It adds only the subnet HTTP rule, coordinates Windows-side HTTP checks and a controlled interruption, and tests a restricted operator sudo policy. Privileged execution returned WEEK3_COMPLETE: local and Windows HTTP, controlled failure/recovery, the monitor service, and restricted operator checks passed. Installed script/unit/page/server-block contents match their local copies. The continuation detects fully installed Nginx packages to avoid repeating downloads. The recovery exercise restarts Nginx on unexpected exit. No general passwordless sudo or scheduled monitoring is enabled.

## Completed week-4 deployment

[week4-automation.sh](week4-automation.sh) installed the reports, backup, four systemd units, and English directory reference. It verified a separate restore with diff 0, age-scoped retention in an isolated fixture, expected failure paths, and actual timer-triggered services. Temporary runtime timer overrides were removed before completion. Independent SSH/HTTP and artifact-hash checks allowed the root script to return WEEK4_COMPLETE and CORE_LAB_ACCEPTANCE_PASSED.

The lab installers are deployment/acceptance workflows, not generic production provisioning. Routine backups use lab-backup.service. Ubuntu package upgrades were explicitly left as separately recorded maintenance.
