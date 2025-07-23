# stm32-zig-template

This is a example firmware template for STM32 projects using [stm32-zig-build](https://github.com/jdf18/stm32-zig-build), designed to work with the Zig build system and libopencm3. It provides a starting point for writing embedded applications in C++ (or any other language supported by Zig).

- Zig build system integration
- Uses libopencm3 for hardware abstraction
- Easily compile for other targets (including local machine)
- Simple to add build steps to improve development experience 

## Getting Started

**Prerequisites**:
- Zig (0.14.1 tested)
- Python 3.10 or newer
- make and a C compiler
- Optionally: ARM flashing/debugging tools (e.g., OpenOCD)

Clone this repository:
``` bash
git clone --recurse-submodules https://github.com/jdf18/stm32-zig-template
cd stm32-zig-template
```

Generate device.zig file for your microcontroller:
1. Edit the config.yaml to include your target chip.
2. Run `python3 stm32-zig-build/setup.py`<br>
*(This will generate the devices.zig file for your chosen STM32 chips.)*
3. Edit the `build.zig` and update the device id of the `stm32_chip` variable to be the full device part name of the chip you are using.

## Building the project

Running the following command will produce both native and target binaries under ./zig-out:
```bash
zig build
```

You can then flash it using your preferred tool.

### Extra build steps

These are not all necessary and will vary between project but these are some examples which I decided to include:

- `zig build native`: Builds only the local executable.
- `zig build target`: Builds only the firmware for the stm32.
- `zig build run`: Builds and runs the local version of the software.
- `zig build debug`: Builds and opens gdb running the local version of the software.
- `zig build flash`: Builds the firmware for the stm32 then runs `scripts/flash.sh` which can be configured for your specific microcontroller.
- `zig build debug-target`: Builds the firmware for the stm32 then runs `scripts/flash-debug.sh` which can be configured for your specific microcontroller and preferred debugging environment.

## Project Structure

```
.
├── build.zig             # Zig build script
├── config.yaml           # Chip configuration file
├── src/                  # Application source code
│   └── main.cpp          # Your application's entry point
├── stm32-zig-build/      # Zig helper scripts and libopencm3 submodule
│   └── ...               # (subtree from https://github.com/jdf18/stm32-zig-build)
└── zig-out/              # Zig build output directory
```

## Acknowledgements

- [stm32-zig-build](https://github.com/jdf18/stm32-zig-build): The zig helper scripts that make the `build.zig` file not completely awful to read
- [libopencm3](https://github.com/libopencm3/libopencm3): Lightweight C library for ARM Cortex-M microcontrollers
- [Zig](https://github.com/ziglang/zig): The language used for this build system

## License

This project is released under the MIT License. See the [LICENSE](https://github.com/jdf18/stm32-zig-template/blob/main/LICENSE) file for details.
