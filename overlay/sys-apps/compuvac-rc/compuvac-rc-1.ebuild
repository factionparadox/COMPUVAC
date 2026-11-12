# Copyright 2026 Compuvac
# Distributed under the terms of the GNU General Public License v2
EAPI=8
DESCRIPTION="Compuvac's start-up: sysvinit with plain BSD-style rc scripts"
HOMEPAGE="https://github.com/factionparadox/compuvac"
S="${WORKDIR}"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64"
RDEPEND="
	sys-apps/sysvinit
	sys-apps/util-linux
	sys-apps/kbd
	sys-apps/iproute2
	sys-process/procps
	sys-process/psmisc
	sys-auth/seatd[server]
	media-sound/alsa-utils
	net-misc/dhcpcd
	virtual/udev
"

src_install() {
	insinto /etc/rc.d
	doins "${FILESDIR}"/rc.d/functions
	exeinto /etc/rc.d
	local f
	for f in "${FILESDIR}"/rc.d/*; do
		[[ ${f##*/} == functions ]] || doexe "${f}"
	done
	insinto /etc
	doins "${FILESDIR}"/rc.conf
	insinto /usr/share/compuvac-rc
	doins "${FILESDIR}"/inittab
}

pkg_postinst() {
	# sysvinit owns /etc/inittab; Compuvac's replaces it
	cp "${EROOT}"/usr/share/compuvac-rc/inittab "${EROOT}"/etc/inittab || die
}
