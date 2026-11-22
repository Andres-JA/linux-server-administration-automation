# 04 - Bash Automation and Recovery

[Back to project overview](../README.md)

## At a glance

| State | Meaning |
| --- | --- |
| Already documented | lab-monitor.sh and lab-monitor.service are installed and verified through manual execution and a successful oneshot journal in week 3. |
| Remaining | Implement user-report.sh, lab-backup.sh, the backup service, both timers, and a verified backup restore; schedule the existing monitor. |
| Stage status | Monitoring prerequisite complete; scheduled automation and recovery pending. |

**Status: monitoring prerequisite complete; week-4 automation pending.** The monitor script and its oneshot unit were installed and tested in week 3. No monitor/backup timers, user-report/backup scripts, or restore tests have been implemented yet.

## Goal

Automate operational reports and daily backups, then prove that an archived file can be restored without changes.

## Required artifacts

| Artifact | Purpose | Acceptance |
| --- | --- | --- |
| [scripts/lab-monitor.sh](../scripts/lab-monitor.sh) | Timestamp, hostname, uptime, CPU/load, RAM, disk, Nginx state | Completed: manual execution and successful service journal |
| `scripts/user-report.sh` | Local human-user candidates and lab groups | Bounded UID range and final role names |
| `scripts/lab-backup.sh` | Compression, archive validation, retention | Restricted archive access and documented source/retention |
| [configs/systemd/lab-monitor.service](../configs/systemd/lab-monitor.service) | Run the monitor once | Completed: successful exit and journal report |
| `configs/systemd/lab-monitor.timer` | Schedule monitoring | Approximately every 15 minutes |
| `configs/systemd/lab-backup.service` | Run the backup once | Successful exit and verified archive |
| `configs/systemd/lab-backup.timer` | Schedule backups | Daily 02:00 server time with persistent catch-up |

The guide backs up `/srv/lab/engineering`; the existing lab uses `/srv/project/src`. Choose the actual source before implementation. Scripts, roles, units, and restore commands must agree with that choice.

## Acceptance checklist

- [x] Install and test the monitor script and oneshot unit (completed in week 3).
- [ ] Write and test user-report.sh and lab-backup.sh on Ubuntu with error handling and quoted paths.
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
