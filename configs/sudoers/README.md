# Restricted Operator Policy

[lab-operator](lab-operator) records the exact rule installed as `/etc/sudoers.d/lab-operator` (root-owned, mode 0440). The installer validated it with visudo before installation and validated the complete sudoers configuration afterward.

The locked local operator may execute only `/usr/bin/systemctl restart nginx` as root without a password. That operation succeeded; an unrelated sudo id operation was denied. The role does not have general sudo or SSH access and cannot edit Nginx configuration.

The executable path was obtained on this lab host. Verify it before using the policy on another system. See [stage 03](../../docs/03-services-processes.md) for the real tests.
