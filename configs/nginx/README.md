# Nginx Lab Configuration

The tested server block [linux-lab.conf](linux-lab.conf) is installed as `/etc/nginx/sites-available/linux-lab`, with a symlink in sites-enabled. The packaged default site's symlink was removed; its source configuration remains in sites-available.

The [HTML fixture](index.html) is installed under `/var/www/linux-lab/index.html` with root ownership. Both installed files were compared byte for byte with these copies. Nginx syntax, local HTTP, Windows HTTP, and controlled restart recovery passed.

The block listens on IPv4/IPv6 port 80; UFW permits IPv4 HTTP only from the lab subnet. See [stage 03](../../docs/03-services-processes.md) for the actual network, test results, and screenshots. The static page does not claim to report live service state.
