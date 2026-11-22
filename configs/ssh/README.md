# SSH Configuration

[00-lab-hardening.conf](00-lab-hardening.conf) is installed under `/etc/ssh/sshd_config.d/` on the lab VM. Its contents were compared byte for byte with this local copy after successful protected confirmation.

It disables password and keyboard-interactive authentication, enables public keys, and prohibits root SSH login. The existing main configuration retains `AllowUsers devops admin`. Separate administrative keys were tested from Windows after applying SSH and UFW changes. A password-only attempt and a disallowed dev account were rejected.

See [stage 02](../../docs/02-users-permissions.md) for tests, evidence, and rollback behavior. The [security script](../../scripts/week2-security.sh) is specific to this lab and assumes the recorded network, account names, and initially inactive firewall; it is not a generic production installer.

Private keys remain outside the repository. Do not copy private keys or authorized_keys contents here.
