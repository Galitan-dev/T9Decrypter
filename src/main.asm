    SYS_WRITE   equ 1
    SYS_EXIT    equ 60
    STDOUT      equ 1
; --------------------------------
section .data
    hello       db  "Hello, world!", 0x0A
    hello_len   equ $ - hello
; --------------------------------
section .text
    global  _start

_start
    mov     rdx, hello_len
    mov     rsi, hello
    mov     rdi, STDOUT
    mov     rax, SYS_WRITE
    syscall

    xor     edi, edi
    mov     rax, SYS_EXIT
    syscall
