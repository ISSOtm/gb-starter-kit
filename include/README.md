# Include directory

This directory is for files that are meant to be included from the “main” source files.

`defines.inc` includes all other files, so that it's sufficient to `INCLUDE "defines.inc"` instead of having to `INCLUDE` four or so files at the top of each `.asm` file.

Note that `debugfile.inc`, `hardware.inc`, and `rgbds-structs` are *submodules*.
That is, they are other code repositories "included" into this one.
They tend to be a little finicky, unfortunately.

## `debugfile.inc`

`debugfile.inc` provides some macros that can be used to more easily debug your game.

[Its wiki has more information](http://github.com/ISSOtm/debugfile.inc/wiki), especially on what macros there are and how to use them.

## `hardware.inc`

`hardware.inc` is the ubiquitous “hardware interface names” file.

The best way to learn it, is to read through [Pan Docs] to get an idea of the names of the registers and their behaviours; then you can read `hardware.inc` directly and look for each register's name to see what useful constants may be attached to it.

Note that there are also some constants not named in Pan Docs, such as MBC access constants (`rROMB0` etc.).
For that reason, I also recommend giving the entire file a read.

## `rgbds-structs`

`structs.inc` provides C-like `struct` functionality in RGBDS.

Its README's “Usage” section should get you started.

[Pan Docs]: http://gbdev.io/pandocs/
