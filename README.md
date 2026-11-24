# Live USB

A portable **Arch Linux + Sway** workstation on a USB stick — the main desktop environment, not a rescue-only image.

Boot it on an x86_64 PC and work in Sway with Waybar and a desktop background. The live image is read-only; changes are temporary by default, and an optional unencrypted persistence partition keeps them when needed.

## Goals

- **The USB is the main desktop.** Sway, Waybar, kitty, and a background are part of the live system.
- **Read-only live image.** The USB is never written to in temporary mode.
- **Optional persistence.** Kali Live-style writable space when you need to keep changes.
- **No encryption.** Persistence is intentionally unencrypted.
- **Minimal.** No mako, no notification daemon, no swayidle, no display manager, no bulk security suite.
- **CTF-focused.** Only the tools used for CTF work and daily terminal use.
- **Broad hardware support.** BIOS and UEFI on x86_64.
- **Reproducible.** Archiso profile, package lists, documented build.

## Storage model

| Layer | Location | Writable | Survives reboot |
|---|---|---|---|
| Live image | ISO9660 + squashfs on the USB | No | Yes, until reflashed |
| Temporary overlay | RAM (`tmpfs`) | Yes | No |
| Persistence overlay | ext4 partition labeled `persistence` | Yes | Yes |

How it works:

- The live system is mounted from a read-only squashfs image.
- Archiso adds a writable overlay. In the default mode, the overlay is in RAM. You can write files and change settings, but they disappear on reboot and the USB is not written to.
- In persistent mode, the overlay lives on the ext4 partition. Changes survive reboots. The live image is still read-only; only the persistence partition is written.
- This is the same idea as Kali Live: a read-only live system plus optional persistence.
- There is no encryption. Do not store sensitive data on the persistence partition.

## Boot menu

| Entry | Behavior | Status |
|---|---|---|
| Live system | Read-only USB + RAM overlay; changes lost on reboot | Configured |
| Live USB Persistence | Read-only USB + ext4 persistence; changes saved | Configured; create the partition after flashing |
| Speech | Accessibility boot | Configured |
| Memtest86+ | RAM test | Configured |
| Reboot / power off | — | Configured |

The default RAM overlay is 256 MiB. Increase it with `cow_spacesize=4G` (or another value that fits the machine's RAM) when you need more temporary space.

## Desktop

The USB boots into a Sway session with Waybar and a background after login. It is the main working environment.

| Component | Choice | State |
|---|---|---|
| Compositor | Sway | Working |
| Status bar | Waybar | Starts with Sway |
| Background | swaybg, solid `#1e1e2e` | Starts with Sway |
| Terminal | Kitty | Working |
| Launcher | — | Not included |
| Login | tty1 + zsh, user `assem` | Sway starts after login |

Waybar is configured with modules for workspaces, clock, network, and battery. It is configured minimally in `~/.config/waybar/`.

**Intentionally not used:** mako, dunst, any notification daemon, swayidle, a display manager, and tray applets.

### Keybindings

| Key | Action |
|---|---|
| `Mod4+Return` | Open kitty |
| `Mod4+w` | Close focused window |
| `Mod4+Shift+c` | Reload Sway |
| `Mod4+Shift+e` | Exit Sway |

`Mod4` is the Super/Windows key.

### CTF tools

The image is a terminal-first CTF workstation. It already includes:

- `nmap`, `tcpdump`
- Python 3, `git`, `curl`, `wget`, `jq`
- `neovim`, `vim`, `nano`
- OpenSSH, OpenVPN
- `dig`/`drill` from `bind` and `ldns`
- The releng partitioning, filesystem, LVM, mdadm, cryptsetup, testdisk, and clonezilla tools

Add only the CTF tools you actually use. There is no Kali-style bulk toolkit, no Metasploit/Ghidra/Burp Suite by default, and no browser unless you add one.

## Current state

- Existing x86_64 ISO: `build/archlinux-2026.11.24-x86_64.iso`; rebuilt with the current desktop, persistence, graphics, and renderer-fallback changes.
- Archiso 92, releng-derived profile; Syslinux for BIOS, systemd-boot for UEFI.
- Live user `assem` (UID/GID 1000, `wheel`, zsh) with password-protected sudo.
- Sway starts on `tty1` after login.
- Waybar and the solid-color background are configured to start with Sway.
- Networking: iwd + systemd-networkd + systemd-resolved, ModemManager, sshd.
- NetworkManager is installed but not enabled; the active stack is iwd + systemd-networkd.
- Persistent boot entries are configured for UEFI and BIOS; create the `persistence` partition after flashing.
- No encryption, by design.
- x86_64 only in practice; the aarch64 package list lacks the desktop stack.

## Hardware compatibility

The goal is to boot on as many x86_64 PCs as practical.

Included:

- `linux` with `linux-firmware`, `linux-firmware-marvell`, `amd-ucode`, `intel-ucode`, and `sof-firmware`.
- Wi-Fi, Ethernet, and WWAN via iwd, wpa_supplicant, systemd-networkd, and ModemManager.
- Storage tools for ext4, XFS, Btrfs, F2FS, exFAT, NTFS, LVM, mdadm, and more.
- PipeWire audio.
- Mesa graphics with Vulkan ICDs: `vulkan-swrast` (lavapipe software fallback), `vulkan-intel`, `vulkan-radeon`, and `vulkan-nouveau`.
- The live user is in `video`, `render`, `audio`, `input`, and other device groups so it can open `/dev/dri` and input devices.
- Sway falls back to the CPU-only `pixman` renderer if EGL/Vulkan initialization fails, so the desktop can still start on machines without a working GPU driver.

Limitations:

- NVIDIA proprietary drivers are not included; the live system uses nouveau. Add `nvidia-open` only if you are prepared to test it. Sway also supports proprietary drivers only with `SWAY_UNSUPPORTED_GPU=1`, which is intentionally not set.
- The pixman fallback is slow; it is meant as a safety net, not a daily-driver renderer.
- Some Wi-Fi adapters need out-of-tree drivers or firmware not in the official repositories.
- Secure Boot is not supported; disable it in the firmware or enroll the bootloader manually.
- ARM machines are not supported yet.
- "Every PC" is a goal, not a guarantee. Test on the hardware you care about.

## Project structure

```text
live_usb/
├── profile/
│   ├── airootfs/                  # overlay copied into the live system
│   │   ├── etc/                   # users, sudo, hostname, services
│   │   ├── home/assem/            # .zprofile, Sway, Waybar, kitty configs
│   │   ├── root/                  # root shell and archiso scripts
│   │   └── usr/local/bin/         # archiso helper scripts
│   ├── efiboot/                   # systemd-boot entries (UEFI)
│   ├── grub/                      # GRUB configs (currently unused)
│   ├── syslinux/                  # BIOS boot menus
│   ├── bootstrap_packages         # packages for the bootstrap tarball
│   ├── packages.x86_64            # x86_64 package list
│   ├── packages.aarch64           # aarch64 package list
│   ├── pacman.conf                # build-time pacman configuration
│   └── profiledef.sh              # ISO metadata, bootmodes, permissions
├── build/                         # generated ISOs (gitignored)
├── tmp/                           # mkarchiso work directory (gitignored)
└── README.md
```

## Configuration map

| File | Purpose |
|---|---|
| `profile/profiledef.sh` | ISO name, label, version, boot modes, compression, permissions |
| `profile/pacman.conf` | Build-time repositories: `core` and `extra` only |
| `profile/packages.x86_64` | Releng package set plus Sway and CTF tools |
| `profile/packages.aarch64` | Releng package set; desktop stack not added |
| `profile/airootfs/etc/passwd` | Live user and shells |
| `profile/airootfs/etc/group` | `wheel` and device-group membership (`video`, `render`, etc.) |
| `profile/airootfs/etc/shadow` | Password hashes |
| `profile/airootfs/etc/sudoers.d/assem` | Password-required sudo for `wheel` |
| `profile/airootfs/home/assem/.zprofile` | Starts `start-sway` on `tty1` |
| `profile/airootfs/usr/local/bin/start-sway` | Launches Sway with a GPU-to-CPU renderer fallback |
| `profile/airootfs/home/assem/.config/sway/config` | Sway keybindings, Waybar, background |
| `profile/airootfs/home/assem/.config/waybar/config` | Minimal Waybar modules |
| `profile/airootfs/home/assem/.config/waybar/style.css` | Waybar appearance |
| `profile/airootfs/home/assem/.config/kitty/kitty.conf` | Kitty appearance |
| `profile/efiboot/loader/loader.conf` | UEFI menu timeout and default entry |
| `profile/syslinux/*.cfg` | BIOS boot menus and entries |
| `profile/airootfs/etc/mkinitcpio.conf.d/archiso.conf` | Archiso initramfs hooks |

Notes:

- `profile/grub/` exists but GRUB is not an active boot mode.
- Services are enabled through symlinks under `profile/airootfs/etc/systemd/system/*.wants/`.
- There is no encryption.
- Secure Boot is not supported.

## Build

Requirements:

- An Arch Linux host.
- `archiso`.
- Root privileges.
- At least ~10 GB of free disk space.

```bash
sudo pacman -S --needed archiso
sudo mkarchiso -v -w ./tmp -o ./build ./profile
```

The ISO is written to `build/archlinux-YYYY.MM.DD-x86_64.iso`. Both `tmp/` and `build/` are gitignored.

If a build fails, remove the work directory before retrying:

```bash
sudo rm -rf ./tmp
```

## Write to USB

> **Warning:** this overwrites the target device completely. Double-check the device name with `lsblk` first.

```bash
sudo dd if=build/archlinux-YYYY.MM.DD-x86_64.iso of=/dev/sdX bs=4M status=progress oflag=sync
sync
```

Replace `/dev/sdX` with the whole USB device, not a partition (for example `/dev/sdb`, not `/dev/sdb1`).

## Add persistence

Persistence follows the Archiso model. The profile already includes the persistent boot entries for UEFI and BIOS. Do **not** create a Kali `persistence.conf`; Archiso ignores it.

### 1. Create the partition

After writing the ISO, create a new partition in the free space:

```bash
lsblk
sudo fdisk /dev/sdX
# n -> p -> Enter -> Enter -> Enter -> w
```

This creates a new partition, usually `/dev/sdX3`. Confirm with `lsblk`.

### 2. Format it

```bash
sudo mkfs.ext4 -L persistence /dev/sdX3
```

The label must be `persistence`.

### 3. Use the persistent boot entry

The profile already includes the persistent entries:

- UEFI: `profile/efiboot/loader/entries/04-archiso-persistent.conf`
- BIOS: the `live_persistent` label in `profile/syslinux/archiso_sys-linux.cfg`

For reference, the UEFI entry is:

```text
title    Live USB Persistence
sort-key 04
linux    /%INSTALL_DIR%/boot/%ARCH%/vmlinuz-linux
initrd   /%INSTALL_DIR%/boot/%ARCH%/initramfs-linux.img
options  archisobasedir=%INSTALL_DIR% archisosearchuuid=%ARCHISO_UUID% cow_label=persistence cow_persistent=P cow_directory=live_usb %KERNEL_PARAMS%
```

The BIOS entry uses the same kernel parameters.

If you want more temporary space in the non-persistent entry, add `cow_spacesize=4G` to its `options`/`APPEND` line.

### 4. Boot the persistent entry

No rebuild is needed; the persistent entries are already in the profile. Boot the USB and choose **Live USB Persistence**.

Rebuilding and reflashing the ISO later destroys the persistence partition. Back up important files first.

### 5. Verify

Boot the persistent entry, then:

```bash
mount | grep cowspace
```

It should show the `persistence` partition instead of `tmpfs`.

Create a test file, reboot into the persistent entry, and check that it is still there:

```bash
touch /home/assem/persistence-test
# reboot
ls /home/assem/persistence-test
```

### Notes

- The persistence partition stores overlay data under `live_usb/upperdir`, not a normal root filesystem tree.
- `cow_directory=live_usb` keeps the path stable if you back up and restore the persistence partition across ISO rebuilds.
- Size the partition for what you plan to install and save. The overlay grows as needed.
- Persistence is unencrypted. Anyone with the USB can read it.
- Reflashing the ISO destroys the partition. Keep backups on another drive.
- The live image itself is never modified; only the persistence partition is written.

## Update the USB

There is no in-place ISO update. To update:

1. Boot the persistent entry and copy your files to another drive.
2. Reflash the new ISO.
3. Recreate and format the persistence partition.
4. Boot the persistent entry again and copy the files back from the other drive.

Copy files from inside the running live system, not by writing directly into the overlay directory. Keeping a second USB drive is the simplest way to test a new build without losing the working one.

## Test

The `run_archiso` helper boots the image in QEMU:

```bash
# UEFI (default)
run_archiso -i build/archlinux-YYYY.MM.DD-x86_64.iso

# BIOS
run_archiso -b -i build/archlinux-YYYY.MM.DD-x86_64.iso
```

It requires `qemu-desktop` and `edk2-ovmf`. Also test on real hardware: Wi-Fi, GPU, audio, suspend keys, and USB boot are not fully exercised by a VM.

If Sway fails with `MESA: ZINK: vkCreateInstance failed (VK_ERROR_INCOMPATIBLE_DRIVER)` or `EGL_NOT_INITIALIZED`, the image is missing a Vulkan ICD or the user lacks access to `/dev/dri`. This profile now ships Vulkan ICDs, adds the live user to `video`/`render`, and falls back to the pixman renderer. Rebuild the ISO after changing any of these.

If it still fails, collect this from the failing machine:

```bash
lspci -nnk | grep -A3 -E 'VGA|3D'
ls -l /dev/dri
dmesg | grep -Ei 'drm|gpu|nouveau|i915|amdgpu|vmwgfx|virtio'
```

You can also test the last-resort renderer directly from a TTY with `WLR_RENDERER=pixman sway`. If that works, the problem is GPU/EGL initialization; if it does not, the problem is elsewhere in the Sway session.

## Roadmap

### Live system

- [x] Install Archiso and initialize the profile.
- [x] Add the Sway desktop and development packages.
- [x] Create the live user and grant sudo access.
- [x] Start Sway automatically after login on `tty1`.
- [x] Build the x86_64 ISO.
- [x] Configure Waybar and a solid-color background.
- [ ] Rebuild and verify the desktop changes.
- [ ] Choose a launcher (optional).
- [x] Add the persistent boot entry.
- [ ] Test persistence on real hardware.
- [x] Add GPU/Vulkan packages and a software renderer fallback.
- [ ] Add Bluetooth packages if needed.
- [ ] Test on multiple x86_64 PCs (BIOS and UEFI).
- [ ] Bring `packages.aarch64` to parity with x86_64.
- [ ] Add release checksums.
- [ ] Add CTF tools only as needed.

## Security notes

- Persistence is unencrypted by choice. Do not store passwords, keys, or sensitive documents on it.
- Live credentials are baked into the image. Change them before distributing it.
- `sshd` allows password login, including root. Disable it or use key-only authentication on untrusted networks.
- Secure Boot is not supported. Disable it in the firmware or enroll the bootloader manually.
- Verify checksums before flashing and use a trusted USB drive.

## Philosophy

One environment, everywhere. Keep the live image read-only, make persistence opt-in, skip notification and idle daemons, and include only the tools that earn their place.
