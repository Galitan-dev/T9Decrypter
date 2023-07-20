all: build run

build:
	mkdir -p dist
	nasm -f elf64 -g -o dist/main.o src/main.asm
	ld dist/main.o -o dist/main

debug:
	gdb	dist/main

run:
	dist/main

clean:
	rm -fr dist