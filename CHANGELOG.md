# Changelog

Major implementation and validation milestones. Detailed commands and evidence are linked from the [README](README.md).

## 2026-11-23 - Portfolio documentation

- Published the completed lab and explained the HTTP, scheduling, and restore evidence in the README.
- Condensed the project history into technical milestones.

## 2026-11-22 - Week 4: Automation and recovery

- Completed three Bash scripts, two systemd services, and two timers for reporting, monitoring, and protected backups.
- Verified automatic service execution with temporary test delays, then restored the permanent schedules: monitoring approximately every 15 minutes and backups daily at 02:00 America/Guayaquil.
- Restored a backup file separately with diff exit code 0 and matching SHA256 hashes; tested scoped retention and rejected invalid or unauthorized backup attempts.
- Revalidated the baseline and installed-file hashes, created a cold VM checkpoint after recovery from a stalled live snapshot, and completed the English documentation with 44 evidence images.
- Recorded 114 available Ubuntu updates as deferred maintenance; core completion does not imply a fully patched system.

## 2026-11-21 - Week 3: Services and troubleshooting

- Deployed Nginx and verified the English lab page from Windows, with HTTP restricted to the management subnet.
- Tested a controlled outage and recovery, inspected processes and logs, and validated the monitor service.
- Granted the operator only the exact Nginx restart command; unrelated sudo commands were denied.

## 2026-11-21 - Week 2: Access and security

- Reconciled shared development permissions and read-only audit access; verified allowed and denied operations.
- Hardened SSH with separate administrative keys, disabled password/root login, and tested the user allowlist.
- Enabled subnet-restricted UFW rules and confirmed access after testing the timed rollback safeguard.

## Initial milestones - Server and filesystem foundations

Original implementation dates were not recorded.

- Installed Ubuntu Server in VirtualBox and established SSH access from Windows using the existing bridged network.
- Created users, groups, and the `/srv/project` directory structure; practiced setgid, sticky-bit protection, symlinks, and filesystem inspection.
- Organized the repository into English documentation, scripts, configurations, and consistently named screenshots; excluded credentials, real archives, and local logs from Git.
