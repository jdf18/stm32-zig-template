#!/bin/bash

FIRMWARE="${1:-./zig-out/bin/Project-template-stm32}"
TARGET="${2:-./zig-out/bin/Project-template-stm32}"

openocd -f interface/stlink.cfg -f $TARGET -c "program $FIRMWARE verify reset exit"