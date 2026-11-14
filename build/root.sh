#!/bin/sh
# Builds the Compuvac root filesystem into /target. Runs inside the builder
# (see build/in-builder). Everything is compiled from source by default.
# BINPKGS=1 takes Gentoo's ready-made binaries wherever they match instead
# (much quicker; the result is the same system).
set -eu
T=/target
# Some packages, when installed into $T, run one of $T's own programs inside this
# builder to index their modules (glib's gio-querymodules, gdk-pixbuf's loader
# query). Those programs need glib here too, so the builder gets it first, as a
# binary from the stock profile: the builder never ships. The indexes are then
# regenerated properly inside $T after everything is installed.
emerge --getbinpkg --usepkg --quiet --oneshot --noreplace dev-libs/glib

mkdir -p /etc/portage/repos.conf
printf '[compuvac]\nlocation = /var/db/repos/compuvac\npriority = 100\n' \
	> /etc/portage/repos.conf/compuvac.conf
ln -snf /var/db/repos/compuvac/profiles/compuvac /etc/portage/make.profile
cat >> /etc/portage/make.conf <<'MC'
FEATURES="${FEATURES} -news"
MC
# Every core compiles. MARCH tunes for one CPU: MARCH=native when building on
# the machine Compuvac will run on (e.g. the Framework), which also sets
# CPU_FLAGS_X86 to match; the result then only runs on that kind of CPU.
J=$(nproc)
echo "MAKEOPTS=\"-j$J -l$J\"" >> /etc/portage/make.conf
if [ -n "${MARCH:-}" ]; then
	F="-O2 -pipe -march=$MARCH"
	printf 'COMMON_FLAGS="%s"\nCFLAGS="%s"\nCXXFLAGS="%s"\nFCFLAGS="%s"\nFFLAGS="%s"\n' \
		"$F" "$F" "$F" "$F" "$F" >> /etc/portage/make.conf
	if [ "$MARCH" = native ]; then
		emerge --getbinpkg --usepkg --quiet --oneshot --noreplace app-portage/cpuid2cpuflags >/dev/null
		cf=$(cpuid2cpuflags); case $cf in '*/*'*) ;; *) cf="*/* $cf" ;; esac
		echo "$cf" > /etc/portage/package.use/00cpu-flags
		mkdir -p "$T/etc/portage/package.use"
		cp /etc/portage/package.use/00cpu-flags "$T/etc/portage/package.use/"
	fi
fi
echo ">>> COMPUVAC: $J jobs, ${MARCH:+-march=$MARCH, }$([ "${BINPKGS:-0}" = 1 ] && echo 'Gentoo binaries where they match' || echo 'everything from source')"
if [ "${BINPKGS:-0}" = 1 ]; then
	echo 'EMERGE_DEFAULT_OPTS="--getbinpkg --usepkg --binpkg-respect-use=y --binpkg-changed-deps=n --quiet-build=y"' >> /etc/portage/make.conf
	KERNEL=sys-kernel/gentoo-kernel-bin
else
	echo 'EMERGE_DEFAULT_OPTS="--quiet-build=y"' >> /etc/portage/make.conf
	KERNEL=sys-kernel/gentoo-kernel
fi

PKGS="@system sys-apps/compuvac-rc app-misc/compuvac
	$KERNEL sys-kernel/linux-firmware
	sys-boot/grub sys-boot/efibootmgr sys-fs/dosfstools sys-fs/xfsprogs
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
# The installed Compuvac compiles its own software, however this root was built.
# 'compuvac tune' later fits the CPU lines to the machine it runs on.
TF="-O2 -pipe${MARCH:+ -march=$MARCH}"
cat > "$T/etc/portage/make.conf" <<MC
# COMPUVAC: this machine compiles its own software from source.
# Run 'compuvac tune' on the machine itself to fit these lines to its CPU.
COMMON_FLAGS="$TF"
CFLAGS="\${COMMON_FLAGS}"
CXXFLAGS="\${COMMON_FLAGS}"
FCFLAGS="\${COMMON_FLAGS}"
FFLAGS="\${COMMON_FLAGS}"
MAKEOPTS="-j$J -l$J"

ACCEPT_LICENSE="*"
LC_MESSAGES=C.UTF-8
FEATURES="\${FEATURES} -news"
EMERGE_DEFAULT_OPTS="--quiet-build=y"
MC
ln -snf ../../var/db/repos/compuvac/profiles/compuvac "$T/etc/portage/make.profile"
# Binhost trust: reuse the builder's keyring rather than bootstrapping one in $T.
rm -rf "$T/etc/portage/gnupg"; cp -a /etc/portage/gnupg "$T/etc/portage/gnupg"

emerge --root="$T" --config-root=/ --with-bdeps=n --update --deep --newuse $PKGS

echo ">>> COMPUVAC: configuring"
# The installed system keeps its own copy of the overlay and the binhost settings.
rm -rf "$T/var/db/repos/compuvac"; cp -a /var/db/repos/compuvac "$T/var/db/repos/compuvac"
cp -a /etc/portage/binrepos.conf "$T/etc/portage/"
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
# Module indexes, built by this system's own tools (see the note at the top).
[ -x /usr/bin/gio-querymodules ] && gio-querymodules /usr/lib64/gio/modules
[ -x /usr/bin/gdk-pixbuf-query-loaders ] && gdk-pixbuf-query-loaders --update-cache
command -v update-mime-database >/dev/null && update-mime-database /usr/share/mime
# The live user is "operator". Gentoo ships a legacy system account of that name
# (no home, no shell) that nothing here uses; it is retired to free the name.
# The installer sets the real operator's name and password; the live system logs in alone.
getent group seat >/dev/null || groupadd -r seat
if [ "$(id -u operator 2>/dev/null)" != "" ] && [ "$(id -u operator)" -lt 1000 ]; then
	userdel operator
fi
userdel -r agent 2>/dev/null || true   # the live user of earlier builds
id operator >/dev/null 2>&1 || useradd -m -G wheel,audio,video,input,seat -s /bin/bash operator
passwd -d operator >/dev/null
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
