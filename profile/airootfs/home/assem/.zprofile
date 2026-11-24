# Start Sway automatically on the first virtual terminal.
# start-sway falls back to a CPU renderer if the GPU driver cannot init.
if [[ -z "$WAYLAND_DISPLAY" && "$XDG_VTNR" == 1 ]]; then
    exec /usr/local/bin/start-sway
fi
