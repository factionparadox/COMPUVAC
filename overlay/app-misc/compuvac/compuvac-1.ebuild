# Copyright 2026 Compuvac
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Compuvac software requisition: Portage, asked politely"
HOMEPAGE="https://example.invalid/compuvac"
S="${WORKDIR}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64"

RDEPEND="
	app-portage/gentoolkit
	app-misc/compuvac-session
	sys-apps/portage
"

src_install() {
	dobin "${FILESDIR}"/compuvac
}
