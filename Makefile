all: build run

dev: build debug

build:
	mkdir -p dist
	nasm -f elf64 -g -o dist/main.o -I src src/main.asm
	ld -o dist/main dist/main.o

debug:
	gdb	dist/main

run:
	dist/main

clean:
	rm -fr dist