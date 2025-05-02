# Source assets directory

Put non-code assets in this directory, and add rules to the `Makefile` (at the root) to describe how they should be processed.
(Feel free to create sub-directories, too!)

Files in this directory are not special; instead, they are processed **on-demand** as the source files (`src/**/*.asm`) request them, **even indirectly**.
This has the nice side-effect that you're less likely to accidentally include unused data within your ROM.

For example, `src/lib/crash_handler.asm` has a `INCBIN "assets/crash_font.1bpp.pb8"`, which...

1. ...requests `assets/crash_font.1bpp.pb8`...
2. ...from `assets/crash_font.1bpp`...
3. ...from `src/assets/crash_font.png`.

...and thus all of these files will be generated one by one, simply because one `.asm` file requested the last one.

Importantly, **you should not** put generated files in this directory.
This is because they would not be removed by `make clean`, and that can cause all sorts of headaches.
(Conversely, you should not put any source files in `assets/`, because you'd lose them from a single `make clean`.)
