The crash handler
=================

When gb-starter-kit is built and run, after the hardware setup in `header.asm` finishes, it jumps to the main routine `Intro` in `intro.asm`.
A newly created project shows a crash dump displaying the following:

* "GAME CRASH!!" message explaining to the tester what just happened
* "Model", the value of `hConsoleType` set in `header.asm` to the initial value of `A` minus $11.  This is `00` for Game Boy Color or either `F0` or `EE` for monochrome.
* Values of processor register pairs `AF`, `BC`, `DE`, `HL`, and `SP`
* Two views of 24 bytes of memory, initially centered around `HL` and `SP`.
  Much of VRAM ($9000–$941F and $9D94–9FFF) is invalid, as the crash handler uses VRAM to display its output.
* Hardware registers `LCDC`, `KEY1` (shown as `K1`, valid on GBC only), and `IE`
* Three bank numbers:
  `R` is the value of `hCurROMBank`, a variable in HRAM that should reflect the bank switched into ROM $4000–$7FFF.
  `V` and `W` are the current VRAM and WRAM $D000–$DFFF banks.
  Only the least significant bits of `V` and `W` are valid on Game Boy Color: 1 bit of `V` and 3 bits of `W`.
  On monochrome systems, `V` and `W` are meaningless.
  The SRAM bank number is not displayed.
* Date and time when the ROM was built.

The memory views can be scrolled.
This is initially locked to prevent accidental scrolling when the dump first appears or when photographing the screen.
To unlock scrolling, hold the A and B Buttons for half a second.
Then press Up and Down on the Control Pad to change the address by $10 bytes (two lines), hold the A Button and press the Control Pad to change it by $100 bytes, or press the B Button to switch focus between views.
The address indicated by the corresponding `View:` is the address of the second row's leftmost byte.
Despite what the spacing might suggest, bytes are displayed in order and not swapped.

In a debugging emulator with exceptions on reading uninitialized memory, unlocking the memory views can cause continuous exceptions.
To temporarily suppress these exceptions in bgb, use `Run > Run not this break` (Ctrl+F9).

Calling the crash handler
-------------------------

To call the crash handler from your code, add one of these:

    rst Crash  ; Always cause a crash
    error nc   ; Crash if the carry flag is false
    error c    ; Crash if the carry flag is true
    error nz   ; Crash if the zero flag is false
    error z    ; Crash if the zero flag is true

You may also see the crash handler if the program counter goes out of bounds.
The makefile passes options to `rgblink` and `rgbfix` that pad unused areas of ROM with value $FF, which happens to be
the opcode for `rst $0038` (that is, `rst Crash`).

Customization
-------------

The debug screen is 19 characters wide and scrolled by 4 pixels, so as not to put information close to the shadow cast on the screen by the lens.
To customize the message, edit `.header` in `src/crash_handler.asm`.

(Aside: In the past, some manufacturers have refused to manufacture cartridges that crash or display obvious debugging information.
The sneaky developers of *Sonic 3D Blast* and *The New Tetris* disguised their crash screens as a way to unlock cheats.)

To customize the font, edit `src/res/crash_font.png` in GIMP, LibreSprite, or another paint program.
The character map is rearranged to put `A` through `F` next to `0` through `9` to simplify displaying hexadecimal numbers.
The capital `T` and some punctuation are reordered to simplify conversion of the characters `-:T` in the ISO 8601 date and time from ASCII.
