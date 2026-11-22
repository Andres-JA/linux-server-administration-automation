# Lab Scripts

## Implemented week-2 scripts

| File | Purpose | Verification |
| --- | --- | --- |
| [week2-permissions.sh](week2-permissions.sh) | Shared developers access and read-only audit role | Executed with sudo; allowed/denied operations and group inheritance passed |
| [week2-security.sh](week2-security.sh) | Dedicated admin key, SSH hardening, restricted UFW, protected rollback | Executed with sudo; independent key/rejection tests passed; confirmation retained changes |

These scripts target the existing lab accounts, paths, and network. Review [stage 02](../docs/02-users-permissions.md) before considering another run. The security script deliberately requires an initially inactive firewall and an external verifier; rerunning it against the now-active policy is not an upgrade workflow. Private keys and runtime outputs are outside Git.

## Later milestones

Nginx, the resource monitor, scheduled tasks, and backup scripts are outside this week-2 publication. Requirements are documented in [stage 03](../docs/03-services-processes.md) and [stage 04](../docs/04-automation.md). Their tested implementation will be published separately.
