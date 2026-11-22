# systemd Services and Timers

## Implemented and tested

[lab-monitor.service](lab-monitor.service) is installed under `/etc/systemd/system/`. Its contents match the local copy. The unit runs the read-only monitor as devops, with NoNewPrivileges, ProtectSystem=strict, ProtectHome, and PrivateTmp. Manual execution and the oneshot journal were verified in [stage 03](../../docs/03-services-processes.md).

The completed unit reports inactive with Result=success and ExecMainStatus=0. It has no Install section and is not enabled as a continuously running service.

## Pending week-4 scheduling

| Planned file | Behavior |
| --- | --- |
| lab-monitor.timer | Run the existing monitor after boot and approximately every 15 minutes |
| lab-backup.service | Run the future backup script with required backup permissions |
| lab-backup.timer | Run daily at 02:00 server time with Persistent=true |

No monitor/backup timer has been installed. Test and commit matching copies of future units only when authorized; see [stage 04](../../docs/04-automation.md).
