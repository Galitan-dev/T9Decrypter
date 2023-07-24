# T9 Decrypter
A T9 Decryper in nasm assembly x86_64 (intel 64 bits)<br>
Made from scratch.

This is an entry in [the second devcode challenge](docs/challenge.pdf)<br>
[View notes](docs/notes.md)

## Roadmap

- [x] 🧱 Basic Program
- [x] 🙋‍♂️ Mode Selector
- [x] 💿 T9 optimal storage
- [x] 🎉 I: T9 Encoder
- [x] 🎉 II: T9 Combinations Listing
- [x] 📚 Callee convention (push registers used in current function)
- [ ] 🙋‍♂️ Extract arguments from command line
- [ ] 💿 Efficient words indexing
- [ ] 🎉 III: T9 Decrypter
- [ ] 📚 Improve Comments
- [ ] 📚 Pseudo code for t9 functions
- [ ] 📦 Delivery

## Usage

### Linux
Install nasm with

    $ sudo apt-get update
    $ sudo apt-get install nasm

and run project with

    $ make all
    or
    $ make build
    $ dist/main

### Windows & MacOS
Coming soon ^^