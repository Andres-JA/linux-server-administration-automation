Linux administration lab - final directory policy

/srv/project              devops:developers 755 - administrator controls top-level entries
/srv/project/src          devops:developers 2770 - shared source tree with group inheritance
/srv/project/audit        root:auditors 2750 - read-only audit role
/srv/project/config       root:devops 750 - administrator-managed configuration
/srv/project/logs         root:devops 755 - project log directory
/srv/project/backups      root:root 700 - reserved legacy project backup location
/srv/project/tmp          root:root 1777 - shared temporary directory with sticky bit

Active backups: /var/backups/linux-lab/archives (root-only)
Backup source: /srv/project/src
Configuration link: /srv/project/config/app.conf -> /etc/project/app.conf
Installed operational scripts: /usr/local/bin
Installed service/timer units: /etc/systemd/system

Setgid preserves group inheritance. File modes and umask still determine write access.
The source backup archive contains src/ relative paths, not the entire server.
