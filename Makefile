all: build run

build:
	mkdir -p dist
	gcc -o dist/main.o -c src/main.s
	ld -o dist/main dist/main.o

run:
	dist/main

clean:
	rm -fr dist