# 04 - Bash Automation and Recovery

[Back to project overview](../README.md)

**Status: planned.** Scripts, timers, backups, and restoration tests have not yet been delivered or validated.

## Goal

Automate operational reports and daily backups, then prove that an archived file can be restored without changes.

## Required artifacts

| Artifact | Purpose | Acceptance |
| --- | --- | --- |
| `scripts/lab-monitor.sh` | Timestamp, hostname, uptime, CPU/load, RAM, disk, Nginx state | Manual execution and successful service journal |
| `scripts/user-report.sh` | Local human-user candidates and lab groups | Bounded UID range and final role names |
| `scripts/lab-backup.sh` | Compression, archive validation, retention | Restricted archive access and documented source/retention |
| `configs/systemd/lab-monitor.service` | Run the monitor once | Successful exit and report |
| `configs/systemd/lab-monitor.timer` | Schedule monitoring | Approximately every 15 minutes |
| `configs/systemd/lab-backup.service` | Run the backup once | Successful exit and verified archive |
| `configs/systemd/lab-backup.timer` | Schedule backups | Daily 02:00 server time with persistent catch-up |

The guide backs up `/srv/lab/engineering`; the existing lab uses `/srv/project/src`. Choose the actual source before implementation. Scripts, roles, units, and restore commands must agree with that choice.

## Acceptance checklist

- [ ] Write and manually test all three scripts on Ubuntu with error handling and quoted paths.
- [ ] Commit the tested contents and install matching copies under `/usr/local/bin`.
- [ ] Install matching units in `/etc/systemd/system`, reload systemd, and enable both timers.
- [ ] Record the timezone and next scheduled executions.
- [ ] Capture manual service runs and timer-triggered runs in the journal.
- [ ] Create a known test file before backup; validate the archive listing.
- [ ] Restore into a separate temporary directory and compare with the unchanged source using `diff`.
- [ ] Record archive identity, restore path, comparison result, and `diff` exit code; completion requires `0`.
- [ ] Keep real archives and generated reports outside Git.

## Evidence to collect

| Proposed filename in screenshots/ | Required content |
| --- | --- |
| `automation-01-monitor-output.png` | Resource report |
| `automation-02-user-report.png` | Actual users and lab groups |
| `automation-03-backup-created.png` | Archive and readability check |
| `automation-04-timers-active.png` | Both timers and next executions |
| `automation-05-backup-journal.png` | Successful backup journal |
| `automation-06-backup-restore.png` | Restore comparison and exit code 0 |

Add links only when evidence exists. Archive readability alone does not establish recoverability; the restore comparison is the final acceptance check.
