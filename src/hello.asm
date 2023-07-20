section .data
    hello       db      "Hello, world!", 0x0A
    hello_len   equ     $ - hello
; --------------------------------
section .text

_hello:
    mov     rsi, hello_len
    mov     rdi, hello
    call    _write_stdout
    ret
