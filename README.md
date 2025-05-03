# gb-starter-kit

A customizable and ready-to-compile setup for Game Boy projects using RGBDS.
*Contains your bread and butter, yet guaranteed 100% kitchen-sink-free!*

> [!WARNING]
> Windows users: please use [WSL] or [MSYS2]!
> Due to a bug in Make, this project will **not** work outside of WSL!

**[The wiki] has information on how to use this project.**

Each sub-directory contains documentation of its own contents, in the form of a `README.md` file.
I suggest starting with `src/`.

## See also

If you want something more barebones, check out [gb-boilerplate](https://github.com/ISSOtm/gb-boilerplate).

Perhaps [a gbdev style guide](https://gbdev.io/guides/asmstyle) may be of interest to you?

I recommend the [Emulicious](https://emulicious.org) emulator for developing ROMs, as it has the best debugging features out there.
[SameBoy](https://github.com/LIJI32/SameBoy) is slightly more accurate, but has a more lackluster interface outside of macOS.

### Libraries

- [Variable-width font engine](https://github.com/ISSOtm/gb-vwf#readme)
- [Structs in RGBDS](https://github.com/ISSOtm/rgbds-structs#readme)
- [Sound drivers](https://github.com/ISSOtm/fortISSimO/wiki/Drivers-comparison)

[WSL]: https://learn.microsoft.com/en-us/windows/wsl/install
[MSYS2]: https://msys2.org
[the wiki]: https://github.com/ISSOtm/gb-starter-kit/wiki
