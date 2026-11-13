# COMPUVAC

> Space Security Service master computer.

A terminal-only Linux in the manner of an 80s home computer. No windows, no desktop:
Ly asks who you are, then one green phosphor screen owns the machine. Programs take
the whole screen; quitting one returns you to the console.

- **Base:** Gentoo, with Gentoo's binary packages wherever they fit
- **Init:** sysvinit with plain rc scripts (`/etc/rc.d`, `/etc/rc.conf`). No OpenRC, no systemd.
- **Login:** Ly
- **Screen:** cage running cool-retro-term, full-screen, Monochrome Green
- **Files and editing:** Midnight Commander
- **Programs:** `Ctrl+Space`
- **Software:** `compuvac install NAME` asks about each optional function before building
- **Sounds:** synthesised at build time with sox

## Build

    sudo build/build

Needs podman and about 15 GB free. The ISO lands in `.build/out/`.
Write it to a stick with Rufus in DD mode, or `dd`.

## Install

Boot the stick. At the console press `Ctrl+Space`, choose **install**.
