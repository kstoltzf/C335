#! /bin/bash

as --gstabs cpu.s -o cpu.o
ld -dynamic-linker /lib/ld-linux.so.2 -o cpu cpu.o -lc