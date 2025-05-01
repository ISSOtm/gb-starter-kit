#!/usr/bin/env python3
import re
import sys

if len(sys.argv) != 2:
	print(f"Usage: {sys.argv[0]} <map file>", file=sys.stderr)
	exit(1)

max_non_empty_bank = 0
BANK = re.compile(r"^\s*ROMX bank #(\d+):", re.IGNORECASE)
TOTAL_EMPTY = re.compile(r"^\s*TOTAL EMPTY: \$(\w+) bytes")
with open(sys.argv[1], "rt") as map_file:
	while True:
		line = map_file.readline()
		if len(line) == 0:
			break

		bank_match = BANK.match(line)
		if bank_match is not None:
			# Keep reading lines until finding `TOTAL EMPTY`.
			while True:
				line = map_file.readline()
				assert len(line) != 0 # Should not happen with a well-formed map file.

				match = TOTAL_EMPTY.match(line)
				if match is not None:
					if int(match[1], 16) != 0x3fff:
						max_non_empty_bank = max(max_non_empty_bank, int(bank_match[1]))
					break

print(max_non_empty_bank + 1)
