# gb-starter-kit

A customizable and ready-to-compile bundle for Game Boy RGBDS projects. Contains your bread and butter, guaranteed 100% kitchen sink-free.

## Downloading

Downloading this repository requires some extra care, due to it using submodules. (If you know how to handle them, nothing more is needed.)

### Use as a template

You can [make a new repository using this one as a template](https://docs.github.com/en/github/creating-cloning-and-archiving-repositories/creating-a-repository-from-a-template) or click the green "Use this template" button near the top-right of this page.

### Cloning

If cloning this repo from scratch, make sure to pass the `--recursive` flag to `git clone`; if you have already cloned it, you can use `git submodule update --init` within the cloned repo.

If the project fails to build, and either `src/include/hardware.inc/` or `src/include/rgbds-structs/` are empty, try running `git submodule update --init`.

### Download ZIP

You can download a ZIP of this project by clicking the "Code" button next to the aforementioned green "Use this template" one. The resulting ZIP will however not contain the submodules, the files of which you will have to download manually.

## Setting up

Make sure you have [RGBDS](https://github.com/rednex/rgbds), at least version 0.4.0, and GNU Make installed. Python 3 is required for most scripts in the `src/tools/` folder.

## Customizing

Edit `project.mk` to customize most things specific to the project (like the game name, file name and extension, etc.). Everything has accompanying doc comments.

Everything in the `src` folder is the source, and can be freely modified however you want. The basic structure in place should hint you at how things are organized. If you want to create a new "module", you simply need to drop a `.asm` file in the `src` directory, name does not matter. All `.asm` files in that root directory will be individually compiled by RGBASM.

There is "basic" code in place, but some things need your manual intervention. Things requiring manual intervention will print an error message describing what needs to be changed, and a line number.

The file at `src/res/build_date.asm` is compiled individually to include a build date in your ROM. Always comes in handy, and displayed in the bundled error handler.

If you want to add resources, I recommend using the `src/res` folder. Add rules in the Makefile; there are several examples.

It is recommended that the start of your code be in `src/intro.asm`.

## Compiling

Simply open you favorite command prompt / terminal, place yourself in this directory (the one the Makefile is located in), and run the command `make`. This should create a bunch of things, including the output in the `bin` folder.

While this project is able to compile under "bare" Windows (i.e. without using MSYS2, Cygwin, etc.), it requires PowerShell, and is sometimes unreliable. You should try running `make` two or three times if it errors out.

If you get errors that you don't understand, try running `make clean`. If that gives the same error, try deleting the `deps` folder. If that still doesn't work, try deleting the `bin` and `obj` folders as well. If that still doesn't work, you probably did something wrong yourself.

## See also

If you want something more barebones, check out [gb-boilerplate](https://github.com/ISSOtm/gb-boilerplate).

Perhaps [a gbdev style guide](https://gbdev.io/guides/asmstyle) may be of interest to you?

I recommend the [BGB](https://bgb.bircd.org) emulator for developing ROMs on Windows and, via Wine, Linux and macOS (64-bit build available for Catalina). [SameBoy](https://github.com/LIJI32/SameBoy) is more accurate, but has a much worse interface outside of macOS.

### Libraries

- [Variable-width font engine](https://github.com/ISSOtm/gb-vwf)
- [structs in RGBDS](https://github.com/ISSOtm/rgbds-structs)
