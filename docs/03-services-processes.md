# 03 - Services and Processes

[Back to project overview](../README.md)

**Status: planned.** Nginx deployment, service recovery, and custom systemd execution are not currently evidenced.

## Goal

Deploy an HTTP site, diagnose processes and logs, and recover from a controlled interruption.

## Acceptance checklist

- [ ] Install Nginx and serve a lab page.
- [ ] Record an active service, port 80 listener, and local HTTP 200 response.
- [ ] Verify HTTP from Windows and document the matching firewall rule.
- [ ] Inspect processes with `pgrep -a nginx`, resource usage, and `journalctl -u nginx`.
- [ ] Stop Nginx, record failed HTTP access, restart it, and record recovery.
- [ ] Create and test `lab-monitor.sh` from [stage 04](04-automation.md) before installing its oneshot service.
- [ ] Capture successful monitor journal output. A successful oneshot may show `inactive (dead)` after completion.
- [ ] If using an operator role, validate the specific Nginx restart permission and denial of unrelated sudo commands.

## Evidence to collect

| Proposed filename in screenshots/ | Required content |
| --- | --- |
| `services-01-nginx-web-page.png` | Page in the Windows browser |
| `services-02-nginx-status.png` | Active service and HTTP 200 |
| `services-03-processes-logs.png` | Processes and relevant journal output |
| `services-04-service-recovery.png` | Controlled failure and recovery |
| `services-05-monitor-service.png` | Successful monitor service journal |

Add image links after capturing results. Record actual commands, observations, one troubleshooting finding, and configurations matching the installed files. See [systemd delivery requirements](../configs/systemd/README.md).
