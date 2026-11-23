# Live USB

A custom Arch Linux Live USB environment built with **Archiso**, designed to provide a lightweight, keyboard-driven desktop and a practical set of system and networking tools.

## Goals

- Minimal resource usage.
- Fast boot and startup.
- Lightweight graphical environment.
- Portable development and troubleshooting tools.
- Clean, reproducible ISO builds.
- Support for different hardware configurations.

## Desktop Environment

| Component | Choice |
|---|---|
| Base system | Arch Linux |
| ISO builder | Archiso |
| Wayland compositor | Sway |
| Status bar | Waybar |
| Terminal | Kitty |
| Wallpaper | swaybg |
| Launcher | To be determined |

## Project Structure

```text
live_usb/
└── profile/
    ├── airootfs/
    ├── efiboot/
    ├── grub/
    ├── syslinux/
    ├── bootstrap_packages
    ├── packages.aarch64
    ├── packages.x86_64
    ├── pacman.conf
    └── profiledef.sh
```

The project uses the official Archiso `releng` profile as its starting point.

## Development Roadmap

- [x] Install Archiso.
- [x] Initialize the custom Archiso profile.
- [ ] Customize the package selection.
- [ ] Configure Sway and Waybar.
- [ ] Configure Kitty and terminal appearance.
- [ ] Set up automatic graphical login.
- [ ] Add development and networking tools.
- [ ] Build the ISO.
- [ ] Test the ISO in a virtual machine.
- [ ] Test hardware compatibility.
- [ ] Flash and test the USB drive.

## Building

The ISO will be built using:

```bash
sudo mkarchiso -v -w ./work -o ./out ./profile
```

## Testing

Virtual machine testing will be performed before flashing the ISO to physical media.

## Philosophy

Keep it small. Keep it fast. Include only what is necessary.

No unnecessary desktop services or heavyweight applications. Every package should have a reason to exist.

---

**Status:** Initial development.
