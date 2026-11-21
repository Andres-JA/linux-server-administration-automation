# SSH Configuration

The existing allowlist is documented in [stage 02](../../docs/02-users-permissions.md). A complete verified hardening configuration has not yet been exported from the VM.

The planned artifact is `00-lab-hardening.conf`, installed under `/etc/ssh/sshd_config.d/`. After a second key-based session succeeds, the guide calls for disabling password and keyboard-interactive authentication, enabling public keys, and prohibiting root login.

Keep a working session and the VirtualBox console available. Check `sudo sshd -t` and the effective configuration with `sudo sshd -T` before reloading and retesting access. The allowlist needs permitted/denied login checks too.

Add the file after testing and document its interaction with the existing `AllowUsers` directive. Never copy private keys or authorized-key contents here.
