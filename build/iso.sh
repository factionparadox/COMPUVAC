#!/bin/sh
# Turns /target into a bootable live ISO. Runs inside the builder after root.sh.
# Plain GRUB, no theme: it's meant to look like that.
set -eu
T=/target W=/out/iso
VERSION=${VERSION:-$(date +%Y.%m)}
LABEL=COMPUVAC

echo ">>> COMPUVAC: fetching ISO tools for the builder"
mkdir -p /etc/portage/repos.conf
printf '[compuvac]\nlocation = /var/db/repos/compuvac\npriority = 100\n' \
	> /etc/portage/repos.conf/compuvac.conf
ln -snf /var/db/repos/compuvac/profiles/compuvac /etc/portage/make.profile
emerge --getbinpkg --usepkg --binpkg-respect-use=y --quiet --newuse \
	dev-libs/libisoburn sys-fs/mtools sys-fs/squashfs-tools sys-boot/grub

echo ">>> COMPUVAC: system settings"
# Green console from the very first line the kernel prints.
G=$(python3 - <<'PY'
red=[0]*16; blu=[0]*16
grn=[0,0x90,0xb0,0xb0,0x60,0x90,0xb0,0xb0, 0x40,0xc0,0xff,0xff,0x90,0xc0,0xff,0xff]
j=lambda v:",".join(str(x) for x in v)
print(f"vt.default_red={j(red)} vt.default_grn={j(grn)} vt.default_blu={j(blu)}")
PY
)
cat > "$T/etc/default/grub" <<GRUB
GRUB_DISTRIBUTOR="Compuvac"
GRUB_TIMEOUT=3
GRUB_TERMINAL=console
GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=3 $G"
GRUB_DISABLE_OS_PROBER=true
GRUB
echo "COMPUVAC $VERSION" > "$T/etc/compuvac/version"
cat > "$T/etc/issue" <<'ISSUE'

  COMPUVAC  ·  SPACE SECURITY SERVICE  ·  MAINTENANCE TERMINAL \l

ISSUE

echo ">>> COMPUVAC: live settings (the installer removes these)"
cat > "$T/etc/pam.d/ly-autologin" <<'PAM'
#%PAM-1.0
auth       required     pam_permit.so
account    include      login
password   include      login
session    include      login
PAM
touch "$T/etc/compuvac/live"
# The live user may act as root without a password (it has none to give).
printf 'permit nopass operator\npermit persist :wheel\n' > "$T/etc/doas.conf"; chmod 600 "$T/etc/doas.conf"
printf 'install|compuvac-install|COMMIT COMPUVAC TO DISK\n' > "$T/etc/compuvac/programs"
cfg="$T/etc/ly/config.ini"
sed -i 's|^auto_login_user *=.*|auto_login_user = operator|; s|^auto_login_session *=.*|auto_login_session = Compuvac|' "$cfg"

echo ">>> COMPUVAC: squashing root"
rm -rf "$W"; mkdir -p "$W/LiveOS" "$W/boot/grub"
cp "$T/boot/vmlinuz-live" "$W/boot/vmlinuz"
cp "$T/boot/initramfs-live.img" "$W/boot/initramfs.img"
mksquashfs "$T" "$W/LiveOS/squashfs.img" -comp zstd -Xcompression-level 19 -b 1M \
	-noappend -quiet -e boot/vmlinuz-live boot/initramfs-live.img \
	-e var/cache/distfiles var/cache/binpkgs var/tmp/portage

cat > "$W/boot/grub/grub.cfg" <<CFG
set timeout=5
set default=0
menuentry "COMPUVAC $VERSION" {
	linux /boot/vmlinuz root=live:CDLABEL=$LABEL rd.live.image rd.live.overlay.overlayfs=1 quiet loglevel=3 $G
	initrd /boot/initramfs.img
}
menuentry "COMPUVAC $VERSION (diagnostic)" {
	linux /boot/vmlinuz root=live:CDLABEL=$LABEL rd.live.image rd.live.overlay.overlayfs=1 $G
	initrd /boot/initramfs.img
}
CFG

ISO=/out/compuvac-$VERSION-x86_64.iso
grub-mkrescue -o "$ISO" "$W" -- -volid "$LABEL" >/dev/null 2>&1
rm -rf "$W"
echo ">>> COMPUVAC: $ISO ($(du -h "$ISO" | cut -f1))"
