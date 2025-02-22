#!/usr/bin/awk -f
BEGIN {
	in_code = 0
}

/nwendcode/ {
	in_code = 0
	print "\\end{pygmented}"
}

in_code {
	gsub(/\\\{/, "{")
	gsub(/\\\}/, "}")
	gsub(/\\\\/, "\\")
	if (/^\\LA/) {
		$0 = "|" $0 "|"
	}
}

/nwbegincode/ {
	in_code = 1
	$0 = $0 "\\begin{pygmented}[lang=makefile,boxing method=tcolorbox]"
	if (/Makefile/) { # `escapeinside` breaks some of the highlighting, for some reason...
		sub(/\]/, ",escapeinside=||]")
	}
}

{ print }
