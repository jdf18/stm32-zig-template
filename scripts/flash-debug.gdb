set confirm off

set height unlimited 
# stops enter to scroll

target extended-remote :3333

# Program the target
monitor reset halt
load
monitor reset init

break main
break blocking_handler

set height 10

run

lay src

#exit # if exit after running, can then be used to time programs using `time zig build debug-target`
