    SYS_READ    equ     0
    SYS_WRITE   equ     1
    SYS_EXIT    equ     60
    STDIN       equ     0
    STDOUT      equ     1
; --------------------------------
section .bss
    input_len   equ     24
    input       resb    input_len
; --------------------------------
section .data
    prompt      db      "Your name: "
    prompt_len  equ     $ - prompt
    hello       db      "Hello, "
    hello_len   equ     $ - hello
; --------------------------------
section .text
    global  _start

_write_stdout:
    mov     rdx, rsi
    mov     rsi, rdi
    mov     rdi, STDOUT
    mov     rax, SYS_WRITE
    syscall
    ret

_read_stdin:
    mov     rdx, rsi
    mov     rsi, rdi
    mov     rdi, STDIN
    mov     rax, SYS_READ
    syscall
    ret

_exit:
    mov     rax, SYS_EXIT
    syscall
    ret

_start:
    mov     rsi, prompt_len
    mov     rdi, prompt
    call    _write_stdout

    mov     rsi, input_len
    mov     rdi, input
    call    _read_stdin
    push    rax

    mov     rsi, hello_len
    mov     rdi, hello
    call    _write_stdout

    pop     rsi
    mov     rdi, input
    call    _write_stdout

    xor     edi, edi
    call    _exit
