# COMPUVAC

Experimental Gentoo-based Distribution themed after 1980s computing like the BBC Micro and named after the supercomputer from Doctor Who and the Daleks Master Plan as a retro nod to an era where computers were still scary and AI was a distant threat for the writers of science fiction to play with such as HAL, BOSS and WOTAN.


> Space Security Service master computer.

A terminal-only Linux in the manner of an 80s home computer. No windows, no desktop:
Ly asks who you are, then one green phosphor screen owns the machine. Programs take
the whole screen; quitting one returns you to the console.

- **Base:** Gentoo, built from source (`BINPKGS=1` uses Gentoo's binaries for a quicker build)
- **Kernel:** 7.3.4 (gentoo-kernel)
- **Filesystem:** XFS, with plain GRUB (UEFI or BIOS)
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
