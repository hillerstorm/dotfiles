#!/bin/bash
#
# Detects World of Warcraft open/close via Hyprland socket events.
# When WoW opens:  swap it to master, remove gaps, hide the bar
# When WoW closes: restore gaps, show the bar
#
# Works on both Omarchy 3.x (waybar) and 4.x/quattro (Quickshell bar).

SOCK="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
WOW_TITLE="World of Warcraft"
WOW_ADDR=""
WOW_WORKSPACE=""

# Quattro note: the shell watches a flag literally named "bar-off", and
# omarchy-toggle-bar passes its argument straight through to that flag —
# so "on" creates bar-off (bar HIDDEN) and "off" removes it (bar shown).
# Confirmed by omarchy's test/shell.d/toggle-test.sh.
hide_bar() {
    if command -v omarchy-toggle-bar >/dev/null 2>&1; then
        omarchy-toggle-bar on
    else
        # 3.x: only toggle if waybar is currently visible
        pgrep -x waybar >/dev/null && omarchy-toggle-waybar
    fi
}

show_bar() {
    if command -v omarchy-toggle-bar >/dev/null 2>&1; then
        omarchy-toggle-bar off
    else
        # 3.x: only toggle if waybar is currently hidden
        pgrep -x waybar >/dev/null || omarchy-toggle-waybar
    fi
}

wow_opened() {
    local addr="$1" workspace="$2"
    WOW_ADDR="$addr"
    WOW_WORKSPACE="$workspace"

    # Swap WoW to master (center) position and maximize viewport
    hyprctl dispatch focuswindow "address:0x${addr}"
    hyprctl dispatch layoutmsg swapwithmaster master
    hyprctl dispatch fullscreenstate 0 2

    # Remove gaps and borders (only if currently on)
    local gaps
    gaps=$(hyprctl getoption general:gaps_out -j | jq -r '.custom' | awk '{print $1}')
    [[ "$gaps" != "0" ]] && omarchy-hyprland-window-gaps-toggle

    hide_bar
}

wow_closed() {
    # Restore gaps and borders (only if currently off)
    local gaps
    gaps=$(hyprctl getoption general:gaps_out -j | jq -r '.custom' | awk '{print $1}')
    [[ "$gaps" == "0" ]] && omarchy-hyprland-window-gaps-toggle

    show_bar

    WOW_ADDR=""
    WOW_WORKSPACE=""
}

socat -U - "UNIX-CONNECT:${SOCK}" | while IFS= read -r line; do
    case "$line" in
        openwindow\>\>*)
            # Format: openwindow>>ADDRESS,WORKSPACE,CLASS,TITLE
            data="${line#openwindow>>}"
            addr="${data%%,*}";    rest="${data#*,}"
            workspace="${rest%%,*}"; rest="${rest#*,}"
            class="${rest%%,*}";   title="${rest#*,}"

            if [[ "$title" == "$WOW_TITLE" ]]; then
                wow_opened "$addr" "$workspace"
            fi
            ;;
        closewindow\>\>*)
            # Format: closewindow>>ADDRESS
            addr="${line#closewindow>>}"
            if [[ "$addr" == "$WOW_ADDR" ]]; then
                wow_closed
            fi
            ;;
    esac
done
