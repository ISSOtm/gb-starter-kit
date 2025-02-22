# gb-starter-kit documentation

This branch of `gb-starter-kit` contains the build system's documentation.

Partly as a fun (for myself) exercise, this was done using [literate programming]; in other words, the build system *itself* is extracted from its own documentation.
This is why changes intended for the build system on the “official” branch (`master`) should be done here.
(As a bonus, it should also help ensure that the documentation is never forgotten about!)

The literate programming system in use here is [Noweb] (2.13 on my machine).
This *does* mean that writing some LaTeX is required; [the LaTeX wikibook] offers introduction, help, and advice.

As soon as changes are pushed to this branch, CI will automatically run `noweave` to update the PDF file published at https://eldred.fr/gb-starter-kit/build-system.pdf, and `notangle` to update the `master` branch.

[literate programming]: https://en.wikipedia.org/wiki/Literate_programming
[Noweb]: https://github.com/nrnrnr/noweb
[the LaTeX wikibook]: https://en.wikibooks.org/wiki/LaTeX
