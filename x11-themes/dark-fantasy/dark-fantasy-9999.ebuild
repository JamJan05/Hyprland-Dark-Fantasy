# Copyright 2026 JamJan05
# Distributed under the terms of the MIT License

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )

inherit git-r3 python-any-r1 udev

DESCRIPTION="Dark Souls-styled Hyprland desktop: HUD, tile menu, Cogwheel, hyprlock and SDDM theme"
HOMEPAGE="https://github.com/JamJan05/Hyprland-Dark-Fantasy"
EGIT_REPO_URI="https://github.com/JamJan05/Hyprland-Dark-Fantasy.git"

LICENSE="MIT"
SLOT="0"
# Live ebuild: KEYWORDS stay empty on purpose. Accept it with
#   x11-themes/dark-fantasy **
# in /etc/portage/package.accept_keywords.
KEYWORDS=""
IUSE="sddm l10n_pl"

# The same list as PAKIETY in bootstrap.sh and "Requirements" in the README.
# The USE flags mirror gentoo/package.use/hyprland-desktop: without them the
# bar has no player, tray or Wi-Fi module and the Nerd Font glyphs are missing.
# The ~amd64 keywords for the Hyprland stack cannot come from an ebuild -
# gentoo/package.accept_keywords/hyprland-desktop is installed next to the
# desktop files and pkg_postinst points at it.
RDEPEND="
	gui-wm/hyprland
	gui-apps/hyprlock
	gui-apps/hypridle
	gui-apps/hyprpaper
	gui-apps/hyprshot
	gui-apps/waybar[mpris,network,pipewire,tray,upower,wifi]
	gui-apps/quickshell
	gui-apps/swaync
	gui-apps/wl-clipboard
	app-misc/cliphist
	gui-apps/rofi-wayland
	gui-apps/grim
	gui-apps/slurp
	sys-auth/hyprpolkitagent
	gui-libs/xdg-desktop-portal-hyprland
	media-video/pipewire
	media-video/wireplumber
	media-sound/playerctl
	app-misc/brightnessctl
	sys-power/power-profiles-daemon
	net-wireless/bluez
	dev-python/dbus-python
	dev-python/pygobject
	app-misc/jq
	x11-terms/kitty
	app-misc/yazi
	app-misc/tty-clock
	sys-process/btop
	dev-python/pillow
	media-fonts/nerdfonts[jetbrainsmono]
	media-fonts/eb-garamond
	x11-themes/adw-gtk3
	x11-themes/papirus-icon-theme
	x11-themes/bibata-xcursors
	sddm? ( gui-apps/sddm )
"
# tools/skaluj-ikony-menu.py makes the 256 px tile icons at build time (see
# src_compile); it needs Pillow for the Python the build runs with.
BDEPEND="
	${PYTHON_DEPS}
	$(python_gen_any_dep 'dev-python/pillow[${PYTHON_USEDEP}]')
"

python_check_deps() {
	python_has_version "dev-python/pillow[${PYTHON_USEDEP}]"
}

# Where the desktop files land. The per-user part (~/.config, ~/.local) is
# copied from here by "dark-fantasy-install", which is install.sh from the
# repository run from this directory - Portage installs as root and must not
# touch a home directory.
DF_SHARE="/usr/share/${PN}"

src_compile() {
	# The 256 px menu tile icons (assets/ikony-menu/256/) are build output,
	# not part of the repository. From a git clone install.sh generates them
	# itself, but ${DF_SHARE} is read-only for the user, so the package has
	# to ship them ready - install.sh then only copies them.
	"${EPYTHON}" tools/skaluj-ikony-menu.py || die "generating the tile icons failed"
}

src_install() {
	insinto "${DF_SHARE}"
	doins -r config assets local sbin sddm sudoers udev openrc gentoo tools \
		install.sh README.md README.pl.md LICENSE

	# doins installs everything 0644; install.sh copies the scripts with
	# "cp -p", so they must be executable already here.
	local f
	while IFS= read -r -d '' f; do
		fperms 0755 "${DF_SHARE}/${f}"
	done < <(find local/bin sbin tools install.sh sddm/install-theme.sh -type f -print0)

	# Shortcut for the user: "dark-fantasy-install [--apply]".
	dobin "${FILESDIR}/dark-fantasy-install"

	# --- CPU power limit (AMD laptops, ryzenadj) -------------------------
	# The repository keeps the script in /usr/local/sbin, because that is
	# where "install" by hand belongs. A package must not write to /usr/local,
	# so here it goes to /usr/sbin and the two places that name the path -
	# the sudo rule and the Cogwheel service - follow in the installed copies.
	dosbin sbin/df-limit-mocy
	sed -e "s|/usr/local/sbin/df-limit-mocy|${EPREFIX}/usr/sbin/df-limit-mocy|g" \
		sudoers/dark-fantasy-moc > "${T}/dark-fantasy-moc" || die
	insinto /etc/sudoers.d
	insopts -m0440
	doins "${T}/dark-fantasy-moc"
	insopts -m0644
	sed -i -e "s|/usr/local/sbin/df-limit-mocy|${EPREFIX}/usr/sbin/df-limit-mocy|g" \
		"${ED}${DF_SHARE}/config/quickshell/dark-fantasy/services/LimitMocy.qml" \
		"${ED}${DF_SHARE}/sudoers/dark-fantasy-moc" || die

	# Battery charge limit from the Cogwheel without a password prompt.
	udev_dorules udev/99-dark-fantasy-bateria.rules

	# Backlight and SDDM Num Lock from the last session, before login (OpenRC).
	doinitd openrc/dark-fantasy-stan

	# --- Login screen ----------------------------------------------------
	if use sddm; then
		insinto /usr/share/sddm/themes/${PN}
		doins -r sddm/${PN}/.
		if use l10n_pl; then
			sed -i -e 's/^language=.*/language=pl/' \
				"${ED}/usr/share/sddm/themes/${PN}/theme.conf" || die
		fi
		# The greeter runs as the "sddm" user and cannot read a home
		# directory, so the wallpaper is copied into the theme.
		insinto /usr/share/sddm/themes/${PN}/backgrounds
		newins assets/wallpaper.png wallpaper.png

		# "zz-" sorts after kde_settings.conf (Plasma's SDDM module), and SDDM
		# reads /etc/sddm.conf.d alphabetically with the last file winning.
		insinto /etc/sddm.conf.d
		newins - zz-${PN}.conf <<-EOF
			# Login theme (x11-themes/${PN}).
			[Theme]
			Current=${PN}
		EOF
	fi

	dodoc docs/*.md
	docinto pl
	dodoc docs/pl/*.md
}

pkg_postinst() {
	udev_reload

	elog "The desktop files are in ${EPREFIX}${DF_SHARE}. Copy them into your"
	elog "home AS YOUR OWN USER (no root):"
	elog "    dark-fantasy-install            # shows the plan, changes nothing"
	elog "    dark-fantasy-install --apply    # copies into ~/.config, keeps your local edits"
	elog "then 'hyprctl reload' or log in again. Run it again after every update"
	elog "of this package - the shell, bar and Hyprland read the copies in ~/.config."
	elog
	elog "The Hyprland stack is ~amd64. The keywords it needs are listed in"
	elog "    ${EPREFIX}${DF_SHARE}/gentoo/package.accept_keywords/hyprland-desktop"
	elog
	elog "OpenRC, backlight and Num Lock before the login screen (optional):"
	elog "    rc-update add dark-fantasy-stan default"
	elog "AMD CPU power limit per profile (optional): needs ryzenadj in /usr/local/bin and"
	elog "iomem=relaxed on the kernel command line; the sudo rule and"
	elog "${EPREFIX}/usr/sbin/df-limit-mocy are already in place."
	if use sddm; then
		elog "SDDM: the theme is the default through /etc/sddm.conf.d/zz-${PN}.conf."
	fi
}

pkg_postrm() {
	udev_reload
}
