#!/bin/sh
# ZFS for the Compuvac root: built inside the root itself (chroot), so the
# kernel module is compiled against the kernel Compuvac actually ships.
set -eu
T=${T:-/target}
echo ">>> COMPUVAC: ZFS and ZFSBootMenu"
mkdir -p "$T/var/db/repos/gentoo" "$T/var/cache/distfiles" "$T/etc/portage/repos.conf"
for d in proc sys dev; do mkdir -p "$T/$d"; mount --rbind "/$d" "$T/$d"; done
mount --bind /var/db/repos/gentoo "$T/var/db/repos/gentoo"
mount --bind /var/db/repos/compuvac "$T/var/db/repos/compuvac"
mount --bind /var/cache/distfiles "$T/var/cache/distfiles"
cp /etc/resolv.conf "$T/etc/resolv.conf"
printf '[compuvac]\nlocation = /var/db/repos/compuvac\npriority = 100\n' > "$T/etc/portage/repos.conf/compuvac.conf"
rc=0
chroot "$T" env https_proxy="${https_proxy:-}" HTTPS_PROXY="${HTTPS_PROXY:-}" \
	emerge --getbinpkg --usepkg --binpkg-respect-use=y --binpkg-changed-deps=y \
	--quiet-build=y --update --newuse \
	sys-apps/systemd-utils sys-fs/zfs sys-fs/zfs-kmod sys-boot/zfsbootmenu || rc=$?
umount -R "$T/var/db/repos/gentoo" "$T/var/db/repos/compuvac" "$T/var/cache/distfiles"
for d in dev sys proc; do umount -R "$T/$d"; done
rm -f "$T/etc/resolv.conf"   # the builder's DNS; dhcpcd writes the real one
# The real overlay copy and an empty tree mountpoint stay behind for the installed system.
[ $rc = 0 ] && ls "$T"/lib/modules/*/extra/zfs.ko* >/dev/null 2>&1 && echo ">>> COMPUVAC: ZFS module built"
exit $rc
