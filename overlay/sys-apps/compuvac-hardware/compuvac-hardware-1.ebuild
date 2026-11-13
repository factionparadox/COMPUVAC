# Copyright 2026 Compuvac
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Compuvac laptop support: power, thermals, Wi-Fi, Bluetooth, fingerprint, function keys"
HOMEPAGE="https://github.com/factionparadox/compuvac"
S="${WORKDIR}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64"

# Chosen for the Framework Laptop 13 Pro (Intel Core Ultra Series 3), but
# nothing here is specific to it: any laptop benefits.
RDEPEND="
	app-misc/brightnessctl
	dev-python/evdev
	media-video/pipewire[sound-server,pipewire-alsa]
	media-video/wireplumber
	net-dns/openresolv
	net-wireless/bluez
	net-wireless/iwd
	sys-apps/dbus
	sys-apps/fwupd
	sys-auth/fprintd
	sys-auth/polkit
	sys-firmware/sof-firmware
	sys-power/acpid
	sys-power/power-profiles-daemon
	sys-power/thermald
"

src_install() {
	dobin "${FILESDIR}"/compuvac-{keys,network,power}
	exeinto /usr/libexec/compuvac
	doexe "${FILESDIR}"/acpi-handler
	insinto /etc/acpi/events
	newins "${FILESDIR}"/acpi-lid compuvac-lid
	newins "${FILESDIR}"/acpi-power compuvac-power
	insinto /etc/iwd
	newins "${FILESDIR}"/iwd-main.conf main.conf
	insinto /etc/polkit-1/rules.d
	doins "${FILESDIR}"/50-compuvac.rules
}

pkg_postinst() {
	local f="${EROOT}"/etc/dhcpcd.conf
	# iwd addresses Wi-Fi itself; dhcpcd keeps to wired links.
	if [[ -f ${f} ]] && ! grep -q '^denyinterfaces wlan\*' "${f}"; then
		printf '\n# Compuvac: Wi-Fi is handled by iwd\ndenyinterfaces wlan*\n' >> "${f}"
	fi
	# Fingerprint for doas, falling back to the password when none is enrolled.
	f="${EROOT}"/etc/pam.d/doas
	if [[ -f ${f} ]] && ! grep -q pam_fprintd "${f}"; then
		sed -i '1a auth\t\tsufficient\tpam_fprintd.so' "${f}"
	fi
}
