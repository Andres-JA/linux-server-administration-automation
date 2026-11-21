# systemd Services and Timers

**Status: implementation pending.** [Stage 04](../../docs/04-automation.md) requires two oneshot services and two timers.

| Planned file | Behavior |
| --- | --- |
| `lab-monitor.service` | Run `/usr/local/bin/lab-monitor.sh` |
| `lab-monitor.timer` | Run after boot and approximately every 15 minutes |
| `lab-backup.service` | Run `/usr/local/bin/lab-backup.sh` with backup permissions |
| `lab-backup.timer` | Run daily at 02:00 server time with `Persistent=true` |

Test scripts before scheduling. Commit unit contents matching `/etc/systemd/system`. Capture timer listings, service exit results, and journal output including a scheduled execution. A successful oneshot can return to `inactive (dead)` after completion.
