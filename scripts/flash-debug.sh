#!/bin/bash

# Opens a new tmux window with two panes for openocd and gdb for debugging

FIRMWARE="${1:-./zig-out/bin/Project-template-stm32}"
TARGET="${2:-./zig-out/bin/Project-template-stm32}"

SESSION="stm32-zig-template" # The name of the tmux session
WINDOW="debug-target" # The name of the tmux window to create/overwrite

if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux new-session -d -s "$SESSION" -n "$WINDOW"
else
    if tmux list-windows -t "$SESSION" | grep -q "$WINDOW"; then
        tmux kill-window -t "$SESSION:$WINDOW"
    fi
    tmux new-window -t "$SESSION" -n "$WINDOW"
fi

# Program the stm32
tmux send-keys -t "$SESSION:$WINDOW".0 "openocd -f interface/stlink.cfg -f $TARGET" C-m

# Connect and run GDB using commands in ./gdb-target.txt
tmux split-window -v -t "$SESSION:$WINDOW"
tmux send-keys -t "$SESSION:$WINDOW".1 "arm-none-eabi-gdb $FIRMWARE -x 'scripts/flash-debug.gdb'" C-m

tmux select-layout -t "$SESSION:$WINDOW" tiled

# Attach to tmux session
if [ -z "$TMUX" ]; then
    tmux attach-session -t "$SESSION"
fi
