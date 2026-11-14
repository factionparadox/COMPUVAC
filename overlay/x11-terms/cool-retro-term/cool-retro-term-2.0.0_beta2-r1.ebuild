# Copyright 2026 Compuvac
# Distributed under the terms of the GNU General Public License v2
# cool-retro-term: the CRT terminal that is Compuvac's whole screen. Not packaged in Gentoo
# or GURU; this follows upstream's 2.0.0-beta2 tag (Qt 6) with its submodules.
EAPI=8

inherit git-r3 qmake-utils xdg

DESCRIPTION="Terminal emulator which mimics the look and feel of old cathode tube screens"
HOMEPAGE="https://github.com/Swordfish90/cool-retro-term"
EGIT_REPO_URI="https://github.com/Swordfish90/cool-retro-term.git"
EGIT_COMMIT="1394ce82fa53d2a87d5adc4d99f9eeba598ea53d"

LICENSE="GPL-3 GPL-2"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="
	dev-qt/qtbase:6[gui,widgets,sql,sqlite]
	dev-qt/qtdeclarative:6
	dev-qt/qt5compat:6
"
RDEPEND="${DEPEND}
	dev-qt/qtwayland:6
"
PATCHES=(
	# Compuvac: animate only while an effect moves; Compuvac and Compuvac Calm
	# profiles (green phosphor, Terminus)
	"${FILESDIR}"/${PN}-2.0.0_beta2-compuvac.patch
)

BDEPEND="dev-qt/qtshadertools:6"

src_configure() {
	eqmake6 PREFIX="${EPREFIX}/usr"
}

src_install() {
	emake INSTALL_ROOT="${D}" install
	einstalldocs
}
