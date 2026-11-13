#!/bin/sh
# Builds the Compuvac root filesystem into /target. Runs inside the builder
# (see build/in-builder). Binaries from Gentoo's binhost where they match;
# everything else is compiled straight into the root.
set -eu
T=/target
mkdir -p /etc/portage/repos.conf
printf '[compuvac]\nlocation = /var/db/repos/compuvac\npriority = 100\n' \
	> /etc/portage/repos.conf/compuvac.conf
ln -snf /var/db/repos/compuvac/profiles/compuvac /etc/portage/make.profile
cat >> /etc/portage/make.conf <<'MC'
FEATURES="${FEATURES} -news"
EMERGE_DEFAULT_OPTS="--getbinpkg --usepkg --binpkg-respect-use=y --binpkg-changed-deps=n --quiet-build=y"
MC

PKGS="@system sys-apps/compuvac-rc app-misc/compuvac
	sys-kernel/gentoo-kernel-bin sys-kernel/linux-firmware
	sys-boot/grub sys-boot/efibootmgr sys-fs/dosfstools sys-fs/e2fsprogs
	sys-block/parted sys-fs/squashfs-tools sys-kernel/dracut app-admin/doas net-wireless/iwd
	app-editors/nano sys-process/htop sys-apps/locale-gen"
[ "${NO_FIRMWARE:-}" ] && PKGS=$(echo "$PKGS" | sed 's#sys-kernel/linux-firmware##')

echo ">>> COMPUVAC: assembling root in $T"
mkdir -p "$T/usr/bin" "$T/usr/lib" "$T/usr/lib64"
# Merged /usr, exactly as Gentoo's 23.0 profiles expect.
[ -e "$T/bin" ]   || ln -s usr/bin "$T/bin"
[ -e "$T/sbin" ]  || ln -s usr/bin "$T/sbin"
[ -e "$T/lib" ]   || ln -s usr/lib "$T/lib"
[ -e "$T/lib64" ] || ln -s usr/lib64 "$T/lib64"
[ -e "$T/usr/sbin" ] || ln -s bin "$T/usr/sbin"
# Portage writes into ROOT's config: give the target the same profile.
mkdir -p "$T/etc/portage/repos.conf" "$T/var/db/repos"
cp /etc/portage/repos.conf/compuvac.conf "$T/etc/portage/repos.conf/"
cp /etc/portage/make.conf "$T/etc/portage/make.conf"
ln -snf ../../var/db/repos/compuvac/profiles/compuvac "$T/etc/portage/make.profile"
# Binhost trust: reuse the builder's keyring rather than bootstrapping one in $T.
rm -rf "$T/etc/portage/gnupg"; cp -a /etc/portage/gnupg "$T/etc/portage/gnupg"

emerge --root="$T" --config-root=/ --with-bdeps=n $PKGS

echo ">>> COMPUVAC: configuring"
# The installed system keeps its own copy of the overlay and the binhost settings.
rm -rf "$T/var/db/repos/compuvac"; cp -a /var/db/repos/compuvac "$T/var/db/repos/compuvac"
cp -a /etc/portage/binrepos.conf "$T/etc/portage/"
sed -i 's/^MAKEOPTS=.*/MAKEOPTS="-j4"/; /ipc-sandbox/d' "$T/etc/portage/make.conf"
cat > "$T/etc/locale.gen" <<'L'
en_GB.UTF-8 UTF-8
en_US.UTF-8 UTF-8
L
printf 'LANG=en_GB.UTF-8\n' > "$T/etc/env.d/02locale"
ln -snf ../usr/share/zoneinfo/UTC "$T/etc/localtime"
for d in proc sys dev; do mkdir -p "$T/$d"; mount --rbind /$d "$T/$d"; done
chroot "$T" /bin/sh -eu <<'CH'
locale-gen -q
env-update >/dev/null
# The live user is "agent" (Gentoo already has a system "operator"). Password is set by the installer; the live system logs in alone.
getent group seat >/dev/null || groupadd -r seat
id agent >/dev/null 2>&1 || useradd -m -G wheel,audio,video,input,seat -s /bin/bash agent
passwd -d agent >/dev/null
passwd -l root >/dev/null
printf 'permit persist :wheel\n' > /etc/doas.conf; chmod 600 /etc/doas.conf
printf '%s\n' 'tmpfs /tmp tmpfs nosuid,nodev 0 0' > /etc/fstab
CH
# Kernel + initramfs for the live image (squashfs root under an overlay).
KVER=$(ls "$T/lib/modules" | head -1)
chroot "$T" dracut -q --force --no-hostonly --add "dmsquash-live" \
	--kver "$KVER" "/boot/initramfs-live.img"
for d in dev sys proc; do umount -R "$T/$d"; done
cp "$T/lib/modules/$KVER/vmlinuz" "$T/boot/vmlinuz-live" 2>/dev/null ||
	cp "$T"/boot/vmlinuz-"$KVER"* "$T/boot/vmlinuz-live"
rm -f "$T"/boot/*.old
echo ">>> COMPUVAC: root complete ($(du -sh "$T" | cut -f1), kernel $KVER)"
