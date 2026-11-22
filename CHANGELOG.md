# Changelog

V01-V03 are the original learning milestones, not semantic version releases. Their original dates were not recorded.

## 2026-11-22 - Week 2 publication

- Published the four permissions, key-login, SSH-hardening, and UFW evidence captures.
- Published tested week-2 scripts, matching SSH configuration, and English access-control documentation.
- Updated the public README to the week-2 checkpoint; implementation was verified on 2026-11-21.
- Kept week-3 implementation and evidence local for a later publication.

## 2026-11-21 - Week 3 services and processes

- Installed Nginx and a root-owned English HTTP fixture; retained SSH restrictions and allowed HTTP only from the lab subnet.
- Verified exact page content and HTTP 200 from Windows, refused connections during a controlled stop, and successful HTTP recovery.
- Recorded master/worker processes, listeners, and journal transitions.
- Installed and tested the read-only Bash monitor and hardened devops oneshot unit; verified Result=success and ExecMainStatus=0.
- Added a locked operator role with only the exact Nginx restart sudo command; permitted/denied tests passed.
- Preserved the interrupted initial package-install output; continuation detects fully installed packages and skips duplicate downloads.
- Added six pointer-free captures, installed-file documentation, and updated private progress tracking. Timers, backup/report scripts, and restoration remain week 4.
- Added line-ending attributes for Linux scripts/configuration so Windows checkouts retain executable Bash-compatible LF files.
- Recorded in a local commit on 2026-11-22; no push for this milestone.

## 2026-11-21 - Week 2 access and security

- Reconciled source access to devops:developers mode 2770; added auditors with read-only audit access.
- Executed permitted/denied permission tests and verified sudo denial for dev/auditor.
- Installed matching SSH hardening with separate administrative keys; verified fresh devops/admin sessions, rejected password-only access, and journal-confirmed AllowUsers denial.
- Enabled default-deny incoming UFW with SSH allowed from the actual bridged lab subnet.
- Demonstrated timed rollback, then confirmed the revised change after independent key checks; verified no rollback timer remained scheduled.
- Added four pointer-free native VM captures of actual execution records plus a current VM-configuration capture; updated public English documentation and private task tracking.
- Week-2 implementation and evidence were published on 2026-11-22.

## 2026-11-21 - Progress clarification

- Added completed-versus-remaining summaries to all five technical chapters.
- Clarified that the current guide stage is week 2, that stage 03/04 documents are plans, and that chapter 05 is supplementary work.
- Clarified that requirements directories do not yet contain implemented scripts or service units.
- Excluded PDF copies of the private guide and task checklist from version control.

## 2026-11-21 - Portfolio organization

### Changed

- Moved setup, account, and filesystem notes into `docs/`.
- Consolidated 23 screenshots into `screenshots/` with English names and stage prefixes, preserving original image contents.
- Rewrote public documentation in English with demonstrated skills, evidence links, actual environment differences, and explicit status.
- Preserved Ubuntu 26.04, bridged networking, existing accounts, and `/srv/project` paths.
- Explained the differing permissions between the account and filesystem exercises.

### Added

- Planned-stage documents for services/processes and automation/recovery.
- Delivery requirements under `scripts/`, `configs/ssh/`, and `configs/systemd/`.
- Ignore rules for private planning, credentials, archives, and runtime output.

## V03 - Filesystem operations

- Extended `/srv/project/` with source, configuration, logs, backups, and temporary directories.
- Applied modes including `755`, `750`, `700`, and `1777`.
- Captured denied deletion of another user's file in a sticky-bit directory.
- Linked project configuration to `/etc/project/app.conf`.
- Practiced file searches, disk/inode usage, and mount inspection.
- Created an on-server structure reference and 13 screenshots.

The later source ownership differs from V02's shared model; reconciliation is pending.

## V02 - User management

- Created `developers` and `admins` groups and `dev`, `cloud`, and `admin` accounts.
- Assigned supplementary groups and organized `/srv/project/`.
- Applied shared directory permissions and setgid; the original notes record group-inheritance checks.
- Captured sudo denial for `dev` and sudo access for `admin`.
- Edited SSH configuration with `AllowUsers devops admin` and captured the active service.
- Captured a UID-based account listing and seven screenshots in total.

Effective SSH policy, key-only login, and firewall checks remain pending.

## V01 - Server setup

- Installed Ubuntu Server 26.04 LTS in VirtualBox with `devops` and hostname `linux-server`.
- Recorded initial package preparation and OpenSSH installation.
- Connected from Windows using SSH and captured three screenshots.
- Changed NAT to bridged networking after an address/connectivity issue. SSH subsequently succeeded; the underlying DHCP cause was not established.
