# Copyright 2026 Compuvac
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="comp-src (software requisition) and compuvac (tune, rebuild, status)"
HOMEPAGE="https://example.invalid/compuvac"
S="${WORKDIR}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64"

RDEPEND="
	app-portage/gentoolkit
	app-portage/portage-utils
	app-eselect/eselect-repository
	app-misc/compuvac-session
	sys-apps/portage
	sys-apps/compuvac-hardware
	app-portage/cpuid2cpuflags
	app-admin/doas
	sys-block/parted
	sys-boot/grub
	sys-fs/dosfstools
	sys-fs/xfsprogs
	sys-fs/squashfs-tools
	sys-kernel/dracut
"

src_install() {
	dobin "${FILESDIR}"/comp-src "${FILESDIR}"/compuvac-install
	# One program, two names: comp-src for software, compuvac for the machine.
	dosym comp-src /usr/bin/compuvac
}
