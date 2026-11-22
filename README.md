# Linux Server Administration & Automation

Hands-on Ubuntu Server lab demonstrating remote administration, local identity management, Linux permissions, and filesystem operations. The published week-2 milestone adds key-only SSH, a restricted firewall, and verified group-based access controls. Later service/automation work is published separately.

**Published milestone: week 2 completed and verified.** The repository includes 23 original screenshots and four new permissions/SSH/firewall captures. Subsequent stages are not included in this publication.

## Demonstrated skills

| Area | Work documented | Evidence |
| --- | --- | --- |
| Server administration | VirtualBox installation and SSH access from Windows | [Server setup](docs/01-server-setup.md) |
| Identity and access | Shared development access, read-only audit role, sudo checks, SSH keys/allowlist, and UFW | [Users and permissions](docs/02-users-permissions.md) |
| Filesystem operations | Ownership, setgid, sticky bit, symlinks, file searches, disk and mount inspection | [Filesystem lab](docs/05-filesystem.md) |
| Troubleshooting | Network adapter change to restore connectivity; denied deletion in a sticky-bit directory | [Setup findings](docs/01-server-setup.md#troubleshooting) and [permission test](docs/05-filesystem.md#observed-access-control-test) |

## Lab environment

```text
Windows host (PowerShell / SSH client)
    |
    | Local network through a bridged VirtualBox adapter
    v
Ubuntu Server 26.04 LTS VM
    |-- devops: administrative account
    |-- dev / cloud / admin: role-based test accounts
    `-- /srv/project: permissions and filesystem exercises
```

Recorded resources: 2 GB RAM and a 25 GB virtual disk. Hostname: `linux-server`.

The reference guide uses Ubuntu 24.04, NAT + Host-only, and `/srv/lab`. This repository preserves the existing 26.04 lab, bridged network, account names, and `/srv/project` paths. The final week-2 policy is documented and tested in stage 02; its allowed management subnet is the bridged lab LAN.

**Tools used in this milestone:** Ubuntu Server, VirtualBox, OpenSSH, UFW, Bash, Linux filesystem utilities, systemd rollback timers, Git.

## Documentation and progress

**Published progress: through week 2.** Week 1 still has baseline/snapshot/timezone evidence tasks. Services and automation are separate publication milestones. Chapter 05 preserves original filesystem work; it is not a fifth week.

The two tested week-2 scripts and SSH configuration are included below. Documents for later stages describe their requirements; their implementation is outside this publication.

| Stage | Scope | Status |
| --- | --- | --- |
| [01 - Server setup](docs/01-server-setup.md) | VM, networking, remote access | Existing setup documented; full baseline checks remain |
| [02 - Users, permissions and security](docs/02-users-permissions.md) | Accounts, sudo, SSH, firewall | Completed and verified; four new evidence captures |
| [03 - Services and processes](docs/03-services-processes.md) | Nginx, logs, recovery | Not yet published |
| [04 - Automation and recovery](docs/04-automation.md) | Bash, timers, backup restoration | Not yet published |
| [05 - Filesystem operations](docs/05-filesystem.md) | Additional original exercises | Documented; source permissions reconciled in stage 02 |

## Repository layout

```text
.
|-- README.md
|-- CHANGELOG.md
|-- docs/                 # Four guide stages + original filesystem lab
|-- scripts/              # Tested week-2 access/security scripts
|-- configs/
|   |-- ssh/              # Tested SSH hardening configuration
|   `-- systemd/          # Service and timer requirements
|-- screenshots/          # Original evidence with English filenames
`-- .gitignore
```

## Selected evidence

### Independent administrative key logins

![Successful SSH key connections for devops and admin](screenshots/users-09-ssh-key-login.png)

### Shared development and read-only audit access

![Allowed and denied role-based permission tests](screenshots/users-08-permission-tests.png)

### Restricted firewall

![Active subnet-restricted UFW and confirmed security change](screenshots/users-11-ufw-rules.png)

Full evidence and provenance are documented in stage 02. The new VM images display actual saved execution records; original milestone images retain their original language/output.

## Engineering findings

- Setgid controls group inheritance. File modes and umask still determine group write access.
- The later filesystem exercise had removed developer write access. Week 2 reconciled source to `2770 devops:developers` and verified shared writes and denied audit writes.
- SSH allowlisting, key authentication, and firewall rules were validated separately. A timed rollback protected changes until independent key checks confirmed access.

## Scope and verification

This is a local learning lab. Original evidence records prior milestones. Week-2 scripts were executed on the VM and independently tested from Windows. Later-stage planning documents do not imply that their implementation is included in this publication.

Keep passwords, private keys, environment secrets, and real backup archives outside Git. See the [change history](CHANGELOG.md) for the original milestones and repository reorganization.
