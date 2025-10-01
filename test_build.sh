#!/usr/bin/env bash
cd nes-ide/examples/hello-world/ && make clean && make -j1 && mv hello.nes ../../../test.nes && mv hello.chr ../../../test.chr && cd ../../..
mednafen test.nes | grep "Unrecognized file format" >&2 || false && exit 1
echo 'test.nes header (64 bytes):' && xxd -g1 -l64 test.nes || true && echo && echo 'PRG count byte (offset 4):' && xxd -p -s 4 -l1 test.nes || true && echo && echo 'test.chr header (first 32 bytes):' && xxd -g1 -l32 test.chr || true
cd ../../..