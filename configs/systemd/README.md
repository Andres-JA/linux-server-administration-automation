# systemd Services and Timers

All four units are installed under `/etc/systemd/system/`; their SHA256 values match the repository copies.

| Unit | Execution model | Verified behavior |
| --- | --- | --- |
| [lab-monitor.service](lab-monitor.service) | Read-only devops oneshot with NoNewPrivileges, ProtectSystem, ProtectHome, PrivateTmp | Successful manual and automatic reports |
| [lab-monitor.timer](lab-monitor.timer) | OnBootSec=2min; OnUnitActiveSec=15min | Enabled/active; actual timer invocation verified |
| [lab-backup.service](lab-backup.service) | Root oneshot, UMask=0077, protected system/home, writes restricted to /var/backups/linux-lab | Validated restricted archives and successful service journal |
| [lab-backup.timer](lab-backup.timer) | Daily 02:00 server local time; Persistent=true | Enabled/active; actual timer invocation verified |

Server timezone is America/Guayaquil. The verification session used temporary runtime OnActiveSec=30s/45s drop-ins to exercise both timers without waiting overnight. Those files were removed, DropInPaths was empty, and the permanent next-backup time was checked. The daily 02:00 occurrence itself was not observed during the session.

A completed oneshot normally becomes inactive; Result=success and ExecMainStatus=0 establish completion. Services have no Install section and are scheduled by their enabled timers. See [stage 04](../../docs/04-automation.md) for evidence and restore/retention results.
