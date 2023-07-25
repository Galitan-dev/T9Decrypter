[T9 Decrypter](../README.md) Notes
====================================
This are the notes I have taken during the development
In comments, tx mean the touch x on a t9 keyboard

Strucure
------------------------------------
[src](../src)
- [main.asm](../src/main.asm): Program entry file, do all io
- [lib.asm](../src/lib.asm): Contains common useful functions like `_write_stdout`
- [words.asm](../src/words.asm): Index the [word dictionnary](#word-dictionnary-assetswordstxt)
- [t9.asm](../src/t9.asm): Contains shared functions relative to t9 like `_encode_t9`

Storage
------------------------------------
Working with 64 bits

### Types:
- string: a sequel of ascii bytes
- t9: a sequel of 4 bits integer bitween `0x0` and `0xA`<br>
    0x0: invalid
    0xA: space
    Thus, "bonjour" equals `0x7865662` in memory (little endian)

### Word Dictionnary: `assets/words.txt`
- *Head*: 676 lines, number of words begining which each pair of chars, aa, ab, ..., az, ba, ..., zz
- *Body*: a word per line

Pseudo code
------------------------------------
For mortals, here are a few functions in pseudocode. (Sometimes it's easier to do this before spitting out asm.)
This is not the exact translation because of the control flow (jumps)
### _encode_t9_char:

```python
a = 0x61 # a
if a is 0x20: #space
    return 0x0
if a in 0x41..=0x5A: # uppercase
    a -= 0x41
elif a in 0x61..=0x7A: # lowercase
    a -= 0x61
else:
    raise Error("Invalid character")
# a is a number between 0 and 26
if b is 25: # z
    return 9
b = 2 # offset
if b > 17: # r
    b -= 1
b += a / 3
return b
```
