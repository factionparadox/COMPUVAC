# Copyright 2026 Compuvac
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Compuvac operator session: full-screen green terminal, launcher, sounds"
HOMEPAGE="https://example.invalid/compuvac"
S="${WORKDIR}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64"

RDEPEND="
	app-misc/mc
	app-shells/bash
	app-shells/fzf
	gui-wm/cage
	media-sound/alsa-utils
	sys-apps/less
	sys-process/htop
	x11-misc/ly
	x11-terms/cool-retro-term
	sys-apps/dbus
	media-video/pipewire[sound-server,pipewire-alsa]
	media-video/wireplumber
"
BDEPEND="media-sound/sox"

src_compile() {
	sh "${FILESDIR}"/make-sounds "${S}"/sounds || die "sound synthesis failed"
}

src_install() {
	dobin "${FILESDIR}"/compuvac-{session,console,run,help,sound}
	insinto /usr/share/compuvac
	doins "${FILESDIR}"/{bashrc,programs,ly.conf}
	insinto /usr/share/compuvac/sounds
	doins "${S}"/sounds/*.wav
	insinto /usr/share/mc/skins
	doins "${FILESDIR}"/compuvac.ini
	insinto /usr/share/wayland-sessions
	doins "${FILESDIR}"/compuvac.desktop
	keepdir /etc/compuvac
	insinto /etc/compuvac
	doins "${FILESDIR}"/logo.txt
	insinto /etc/xdg/fastfetch
	newins "${FILESDIR}"/fastfetch.jsonc config.jsonc
	insinto /usr/share/compuvac
	doins "${FILESDIR}"/os-release
}

pkg_postinst() {
	# Compuvac names itself (baselayout's os-release says Gentoo).
	rm -f "${EROOT}"/etc/os-release
	cp "${EROOT}"/usr/share/compuvac/os-release "${EROOT}"/etc/os-release

	# Apply Compuvac's settings over Ly's own config, key by key.
	local cfg="${EROOT}"/etc/ly/config.ini key val
	[[ -f ${cfg} ]] || return 0
	while IFS='=' read -r key val; do
		key=${key// /}; val=${val# }
		[[ -z ${key} || ${key} == \#* ]] && continue
		if grep -q "^${key} *=" "${cfg}"; then
			sed -i "s|^${key} *=.*|${key} = ${val}|" "${cfg}"
		else
			echo "${key} = ${val}" >> "${cfg}"
		fi
	done < "${EROOT}"/usr/share/compuvac/ly.conf
}
