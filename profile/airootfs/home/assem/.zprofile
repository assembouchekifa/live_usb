# Start Sway automatically on the first virtual terminal.
if [[ -z "$WAYLAND_DISPLAY" && "$XDG_VTNR" == 1 ]]; then
    exec sway
fi
