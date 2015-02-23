#! /bin/bash

as --gstabs rbt_cpu.s -o rbt_cpu.o
ld -dynamic-linker /lib/ld-linux.so.2 asmSerial.o -o rbt_cpu rbt_cpu.o -lc