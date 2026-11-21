# Changelog

V01-V03 are the original learning milestones, not semantic version releases. Their original dates were not recorded.

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
