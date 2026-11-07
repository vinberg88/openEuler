#!/bin/bash
set -euo pipefail

version="${1:?openEuler version is required}"
default_name="${2:?default WSL name is required}"
release_path="${3:?openEuler repository release path is required}"

# WSL expects this file to exist during startup. The minimal container image
# does not ship one, which otherwise causes a noisy mount error.
install -m 0644 /dev/null /etc/fstab

# Replace the upstream metalink configuration with pinned official HTTPS URLs.
# Old innovation releases can disappear from the metalink service even while
# their repositories remain available at repo.openeuler.org.
install -d -m 0755 /usr/lib/wsl/upstream-yum.repos.d /etc/yum.repos.d
for repo_file in /etc/yum.repos.d/*.repo; do
    [ -e "$repo_file" ] || continue
    cp -a "$repo_file" /usr/lib/wsl/upstream-yum.repos.d/
done
rm -f /etc/yum.repos.d/*.repo

cat > /usr/lib/wsl/openEuler.repo <<EOF
[OS]
name=openEuler ${release_path} - OS
baseurl=https://repo.openeuler.org/openEuler-${release_path}/OS/\$basearch/
enabled=1
gpgcheck=1
gpgkey=https://repo.openeuler.org/openEuler-${release_path}/OS/\$basearch/RPM-GPG-KEY-openEuler
metadata_expire=6h
skip_if_unavailable=False

[everything]
name=openEuler ${release_path} - everything
baseurl=https://repo.openeuler.org/openEuler-${release_path}/everything/\$basearch/
enabled=1
gpgcheck=1
gpgkey=https://repo.openeuler.org/openEuler-${release_path}/OS/\$basearch/RPM-GPG-KEY-openEuler
metadata_expire=6h
skip_if_unavailable=False

[EPOL]
name=openEuler ${release_path} - EPOL
baseurl=https://repo.openeuler.org/openEuler-${release_path}/EPOL/main/\$basearch/
enabled=1
gpgcheck=1
gpgkey=https://repo.openeuler.org/openEuler-${release_path}/OS/\$basearch/RPM-GPG-KEY-openEuler
metadata_expire=6h
skip_if_unavailable=False

[update]
name=openEuler ${release_path} - updates
baseurl=https://repo.openeuler.org/openEuler-${release_path}/update/\$basearch/
enabled=1
gpgcheck=1
gpgkey=https://repo.openeuler.org/openEuler-${release_path}/OS/\$basearch/RPM-GPG-KEY-openEuler
metadata_expire=1h
skip_if_unavailable=False
EOF
install -m 0644 /usr/lib/wsl/openEuler.repo /etc/yum.repos.d/openEuler.repo

cat > /usr/local/sbin/openeuler-wsl-repair-repos <<'EOF'
#!/bin/bash
set -euo pipefail
install -m 0644 /usr/lib/wsl/openEuler.repo /etc/yum.repos.d/openEuler.repo
for repo_file in /etc/yum.repos.d/*.repo; do
    [ "$repo_file" = /etc/yum.repos.d/openEuler.repo ] && continue
    rm -f "$repo_file"
done
dnf clean all
dnf -q makecache --refresh
printf 'openEuler-förråden är återställda och testade.\n'
EOF
chmod 0755 /usr/local/sbin/openeuler-wsl-repair-repos

# Keep the resulting WSL image useful but compact. Only the base OS repository
# is needed while installing the WSL essentials.
dnf -y --disablerepo='*' --enablerepo=OS install dbus systemd systemd-pam sudo passwd util-linux

install -d -m 0755 /usr/lib/wsl /etc/sudoers.d /etc/profile.d

cat > /etc/wsl.conf <<'EOF'
[boot]
systemd=true

[automount]
enabled=true
root=/mnt/
options="metadata,umask=22,fmask=022"

[interop]
enabled=true
appendWindowsPath=true

[network]
generateHosts=true
generateResolvConf=true
EOF
chmod 0644 /etc/wsl.conf

cat > /etc/wsl-distribution.conf <<EOF
[oobe]
command=/usr/lib/wsl/oobe.sh
defaultUid=1000
defaultName=${default_name}

[shortcut]
enabled=true

[windowsterminal]
enabled=true
profileTemplate=/usr/lib/wsl/terminal-profile.json
EOF
chmod 0644 /etc/wsl-distribution.conf

cat > /usr/lib/wsl/oobe.sh <<'EOF'
#!/bin/bash
set -euo pipefail

readonly default_uid=1000

printf '\nVälkommen till openEuler för WSL!\n'
cat /etc/openEuler-release 2>/dev/null || true
printf '\nSkapa ditt vanliga Linux-konto.\n'

if getent passwd "$default_uid" >/dev/null; then
    printf 'Ett konto med UID %s finns redan; kontoskapandet hoppas över.\n' "$default_uid"
    exit 0
fi

while true; do
    read -r -p 'Nytt användarnamn: ' username
    if [[ ! "$username" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; then
        printf 'Använd små bokstäver, siffror, _ eller -, och börja med bokstav eller _.\n'
        continue
    fi
    if getent passwd "$username" >/dev/null; then
        printf 'Användarnamnet finns redan. Välj ett annat.\n'
        continue
    fi
    break
done

useradd --create-home --uid "$default_uid" --groups wheel --shell /bin/bash "$username"
printf '\nVälj ett lösenord för %s:\n' "$username"
if ! passwd "$username"; then
    userdel --remove "$username" >/dev/null 2>&1 || true
    printf 'Kontot kunde inte färdigställas. Försök igen nästa gång.\n' >&2
    exit 1
fi

printf '\nKlart! Kontot %s är nu standardkonto och kan använda sudo.\n\n' "$username"
EOF
chmod 0755 /usr/lib/wsl/oobe.sh

cat > /etc/sudoers.d/10-wheel <<'EOF'
%wheel ALL=(ALL) ALL
EOF
chmod 0440 /etc/sudoers.d/10-wheel

cat > /usr/lib/wsl/terminal-profile.json <<EOF
{
  "profiles": [
    {
      "colorScheme": "openEuler ${version}",
      "font": { "face": "Cascadia Mono" },
      "startingDirectory": "~"
    }
  ],
  "schemes": [
    {
      "name": "openEuler ${version}",
      "background": "#101820",
      "foreground": "#F2F5F7",
      "cursorColor": "#00B5E2",
      "selectionBackground": "#264653",
      "black": "#101820",
      "red": "#E76F51",
      "green": "#2A9D8F",
      "yellow": "#E9C46A",
      "blue": "#00B5E2",
      "purple": "#A78BFA",
      "cyan": "#41C7C7",
      "white": "#D7E0E5",
      "brightBlack": "#647780",
      "brightRed": "#FF8066",
      "brightGreen": "#52D3B8",
      "brightYellow": "#FFE08A",
      "brightBlue": "#54D6FF",
      "brightPurple": "#C4A7FF",
      "brightCyan": "#6FE7E7",
      "brightWhite": "#FFFFFF"
    }
  ]
}
EOF
chmod 0644 /usr/lib/wsl/terminal-profile.json

cat > /etc/profile.d/00-openeuler-wsl.sh <<'EOF'
if [ -t 1 ] && [ -z "${OPEN_EULER_WSL_BANNER_SHOWN:-}" ]; then
    export OPEN_EULER_WSL_BANNER_SHOWN=1
    printf '\033[1;36mopenEuler på WSL\033[0m  ·  '
    cat /etc/openEuler-release 2>/dev/null || true
fi
EOF
chmod 0644 /etc/profile.d/00-openeuler-wsl.sh

# Units that expect physical networking or early-boot device setup tend to
# delay or degrade a WSL boot. Mask only when the unit exists.
for unit in \
    systemd-resolved.service \
    systemd-networkd.service \
    NetworkManager.service \
    systemd-tmpfiles-setup-dev-early.service \
    tmp.mount; do
    if [ -e "/usr/lib/systemd/system/$unit" ] || [ -e "/etc/systemd/system/$unit" ]; then
        ln -sfn /dev/null "/etc/systemd/system/$unit"
    fi
done

# Do not distribute runtime identity, logs, caches, or WSL-generated DNS state.
: > /etc/machine-id
rm -f /var/lib/dbus/machine-id /etc/resolv.conf
rm -rf /var/cache/dnf/* /var/log/dnf* /var/log/hawkey.log /var/log/journal/*
dnf clean all >/dev/null 2>&1 || true

# Validate the configuration before export.
bash -n /usr/lib/wsl/oobe.sh
visudo -cf /etc/sudoers >/dev/null
test -x /usr/bin/sudo
test -x /usr/bin/passwd
test -x /usr/bin/mount
test -x /usr/bin/systemctl
test -x /usr/bin/dbus-daemon
test -x /usr/local/sbin/openeuler-wsl-repair-repos
grep -q '^baseurl=https://repo.openeuler.org/' /etc/yum.repos.d/openEuler.repo
if grep -Eq '^[[:space:]]*(metalink|mirrorlist)=' /etc/yum.repos.d/openEuler.repo; then
    printf 'Unexpected mirror configuration remains in openEuler.repo.\n' >&2
    exit 1
fi
test -s /etc/wsl-distribution.conf
printf 'Configured %s for WSL.\n' "$(cat /etc/openEuler-release)"
exit 0
