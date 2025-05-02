# Source directory

All `.asm` files in this directory are automatically picked up on by the build system, as well as any files they `INCLUDE`/`INCBIN`.
([Rationale](http://github.com/ISSOtm/gb-starter-kit/wiki/Design-decisions#automatic-dependency-discovery))
If you want a file not to be automatically assembled, simply give it the `.inc` extension.
(Really, any extension besides `.asm` will do, but `.inc` is the most common, and your syntax highlighter should handle it well.)

`include/` is for the files that are to be included from; see that directory's README for more information.

You should add new source code files to this directory!
