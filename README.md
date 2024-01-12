# gb-starter-kit

A customizable and ready-to-compile bundle for Game Boy RGBDS projects.
Contains your bread and butter, but guaranteed 100% kitchen sink-free.

> [!WARNING]
> Windows users: please use WSL! Due to a bug in Make, this project will **not** work outside of WSL!

## Downloading

Downloading this repository requires some extra care, due to it using submodules.
(If you know how to handle them, nothing more is needed.)

### Use as a template

You can [make a new repository using this one as a template](https://docs.github.com/en/github/creating-cloning-and-archiving-repositories/creating-a-repository-from-a-template) or click the green "Use this template" button near the top-right of this page.

### Cloning

If cloning this repo from scratch, make sure to pass the `--recursive` flag to `git clone`; if you have already cloned it, you can use `git submodule update --init` within the cloned repo.

If the project fails to build, and either `src/include/hardware.inc/` or `src/include/rgbds-structs/` are empty, try running `git submodule update --init`.

### Download ZIP

You can download a ZIP of this project by clicking the "Code" button next to the aforementioned green "Use this template" one.
The resulting ZIP will however not contain the submodules, the files of which you will have to download manually.

## Setting up

Make sure you have [RGBDS](https://github.com/rednex/rgbds), at least version 0.6.0, and GNU Make installed, at least version 3.0.
Python 3 is required for most scripts in the `src/tools/` folder.

## Customizing

Edit `project.mk` to customize most things specific to the project (like the game name, file name and extension, etc.).
Everything has accompanying doc comments.

Everything in the `src` directory is the source, and can be freely modified however you want.
Any `.asm` files in that directory (and its sub-directories, recursively) will be individually assembled, automatically.
If you need some files not to be assembled directly (because they are only meant to be `INCLUDE`d), you can either rename them (typically, to `.inc`), or move them outside of `src` (typically, to a directory called `include`).

The file at `src/assets/build_date.asm` is compiled individually to include a build date in your ROM.
Always comes in handy.

If you want to add resources, I recommend using the `src/assets` directory.
Add rules in the Makefile; an example is provided for compressing files using PB16 (a variation of [PackBits](https://wiki.nesdev.com/w/index.php/Tile_compression#PackBits)).

## Compiling

Simply open you favorite command prompt / terminal, place yourself in this directory (the one the Makefile is located in), and run the command `make`.
This should create a bunch of things, including the output in the `bin` directory.

> [!IMPORTANT]
> While this project is able to compile under "bare" Windows (i.e. without using MSYS2, Cygwin, etc.), it requires PowerShell.

Pass the `-s` flag to `make` if it spews too much input for your tastes.
Päss the `-j <N>` flag to `make` to build more things in parallel, replacing `<N>` with however many things you want to build in parallel; your number of (logical) CPU cores is often a good pick (so, `-j 8` for me), run the command `nproc` to obtain it.

If you get errors that you don't understand, try running `make clean`.
If that gives the same error, try deleting the `assets` directory.
If that still doesn't work, try deleting the `bin` and `obj` directories as well.
If that still doesn't work, feel free to ask for help.

## See also

If you want something more barebones, check out [gb-boilerplate](https://github.com/ISSOtm/gb-boilerplate).

Perhaps [a gbdev style guide](https://gbdev.io/guides/asmstyle) may be of interest to you?

I recommend the [BGB](https://bgb.bircd.org) emulator for developing ROMs on Windows and, via Wine, Linux and macOS (64-bit build available for Catalina).
[SameBoy](https://github.com/LIJI32/SameBoy) is more accurate, but has a more lackluster interface outside of macOS.

### Libraries

- [Variable-width font engine](https://github.com/ISSOtm/gb-vwf)
- [Structs in RGBDS](https://github.com/ISSOtm/rgbds-structs)
