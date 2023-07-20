    SYS_READ    equ     0
    SYS_WRITE   equ     1
    SYS_EXIT    equ     60
    SYS_TIME    equ     201
    STDIN       equ     0
    STDOUT      equ     1
    ASCII_0     equ     0x30
    ASCII_9     equ     0x39
; --------------------------------
section .bss
    ninput_len  equ     24
    ninput      resb    ninput_len
    yinput_len  equ     5
    yinput      resb    yinput_len
    age_len     equ     10
    age         resb    age_len
; --------------------------------
section .data
    nprompt     db      "Your name: "
    nprompt_len equ     $ - nprompt
    yprompt     db      "Your birthday year: "
    yprompt_len equ     $ - yprompt
    hello       db      "Hello, "
    hello_len   equ     $ - hello
    yr          db      "You are "
    yr_len      equ     $ - yr
    year        equ     2023
    yo          db      " years old", 0x0A
    yo_len      equ     $ - yo
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

; rdi: number
; rsi: exponant
; rax: result
_power:
    mov     rax, 1
    mov     r8, 0

    .loop:
    cmp     r8, rsi
    je      .done
    mul     rdi
    inc     r8
    jmp     .loop

    .done:
    ret

; rdi: adress of first byte
; rsi: length
; rax: result
; rbx: status, (0: ok, 1: err)
_parse_int:
    xor     rax, rax
    xor     rbx, rbx
    add     rdi, rsi            ; start at end of string
    dec     rdi                 ; indices starts at 0
    mov     r8, 0

    .loop:
    cmp     r8, rsi
    je      .done

    xor     r9, r9
    neg     r8
    mov     r9b, [rdi + r8]     ; index from end
    neg     r8

    cmp     r9b, ASCII_0 
    jb      .err
    cmp     r9b, ASCII_9
    ja      .err
    sub     r9, ASCII_0
    
    push    rax
    push    rdi
    push    rsi
    push    r8
    mov     rdi, 10
    mov     rsi, r8
    call    _power
    mul     r9
    mov     r9, rax
    pop     r8
    pop     rsi
    pop     rdi
    pop     rax
    add     rax, r9

    inc     r8
    jmp     .loop

    .done:
    ret

    .err:
    inc     rbx
    ret

; rdi: adress of first byte of output
; rsi: number to render
_to_str:

    xor rax, rax
    mov rax, rsi
    mov r8, 10
    xor r9, r9

    .loop:
    cmp rax, 0
    jbe .write
    xor rdx, rdx
    .here:
    div r8d
    add rdx, ASCII_0
    push rdx
    inc r9
    jmp .loop

    .write:
    cmp r9, 0
    je .next

    inc rdi
    pop rax
    mov [rdi], al
    dec r9
    jmp .write

    .next:
    ret

_start:
    mov     rsi, nprompt_len
    mov     rdi, nprompt
    call    _write_stdout

    mov     rsi, ninput_len
    mov     rdi, ninput
    call    _read_stdin
    push    rax                 ; keep input size in stack

    mov     rsi, yprompt_len
    mov     rdi, yprompt
    call    _write_stdout

    mov     rsi, yinput_len
    mov     rdi, yinput
    call    _read_stdin

    mov     rsi, rax
    dec     rsi                 ; ignore Enter
    mov     rdi, yinput
    call    _parse_int

    cmp     rbx, 0
    je      .next

    mov     edi, ebx            ; when parsing error
    call    _exit

    .next:
    mov     rsi, year           
    sub     rsi, rax            ; calculate age
    mov     rdi, age            ; render age
    call    _to_str

    mov     rsi, hello_len
    mov     rdi, hello
    call    _write_stdout

    pop     rsi                 ; retrieve input size from stack
    mov     rdi, ninput
    call    _write_stdout

    mov     rsi, yr_len
    mov     rdi, yr
    call    _write_stdout

    mov     rsi, age_len
    mov     rdi, age
    call    _write_stdout

    mov     rsi, yo_len
    mov     rdi, yo
    call    _write_stdout

    xor     edi, edi
    call    _exit
