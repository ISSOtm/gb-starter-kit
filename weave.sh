#!/bin/bash
set -euo pipefail

mkdir -p out
noweave -x -n -t4 Makefile.nw | ./filter.awk >Makefile.tex
xelatex -synctex=1 -interaction=nonstopmode -output-directory=out build-system.tex
pygmentex out/build-system.snippets
xelatex -synctex=1 -interaction=nonstopmode -output-directory=out build-system.tex
xelatex -synctex=1 -interaction=nonstopmode -output-directory=out build-system.tex
