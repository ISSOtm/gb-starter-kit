#!/usr/bin/env python3
"""
PB8 encoder
Copyright 2019 Damian Yerrick
[License: zlib]

PB8 can be thought of as either of two things:

- Run-length encoding (RLE) of a stream, with unary-coded run lengths
- LZSS with a fixed distance of 1 and a fixed copy length of 1

Each packet represents 8 bytes of uncompressed data.  The bits
of the first byte in a packet, ordered from MSB to LSB, encode
which of the following eight bytes repeat the previous byte.
A 0 means a literal byte follows; a 1 means a repeat.
"""
import itertools
import sys
import argparse

def ichunk(data, count):
    """Turn an iterable into lists of a fixed length."""
    data = iter(data)
    while True:
        b = list(itertools.islice(data, count))
        if len(b) == 0: break
        yield b

def pb8(data):
    """Compress an iterable of bytes into a generator of PB8 packets."""
    prev = 0
    for unco in ichunk(data, 8):
        # Pad the chunk to a multiple of 8 bytes
        if len(unco) < 8:
            unco.extend(unco[-1:]*(8 - len(unco)))

        packet = bytearray(1)
        for i, value in enumerate(unco):
            if value == prev:
                packet[0] |= 0x80 >> i
            else:
                packet.append(value)
                prev = value
        yield packet

def parse_argv(argv):
    p = argparse.ArgumentParser()
    p.add_argument("infile")
    p.add_argument("outfile")
    return p.parse_args(argv[1:])

def main(argv=None):
    args = parse_argv(argv or sys.argv)
    with open(args.infile, "rb") as infp:
        data = infp.read()
    with open(args.outfile, "wb") as outfp:
        outfp.writelines(pb8(data))

def test():
    tests = [
        ()
    ]
    s = b"ABAHBHCHCECEFEFE"
    print(b''.join(pb8(s)).hex())

if __name__=='__main__':
    main()
##    test()
