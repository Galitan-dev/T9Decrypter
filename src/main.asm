    %include    "lib.asm"
    %include    "t9.asm"
; --------------------------------
section .bss
    mode_len    equ     1
    mode        resb    mode_len
    input_len   equ     100
    input       resb    input_len
    t9_len      equ     100
    t9          resb    t9_len
    output_len  equ     100
    output      resb    output_len
; --------------------------------
section .data
    select      db  "Please select a mode: ", 0X0A, \
                    "  - 1: T9 Encoder", 0x0A, \
                    "  x 2: Get all word combinations from a T9 sequel", 0x0A, \
                    "  x 3: Decrypt a T9 sequel", 0x0A, \
                    "> "
    select_len  equ $ - select
    prompt      db  "Input: "
    prompt_len  equ $ - prompt
    result      db  "Result: "
    result_len  equ $ - result
    lb          db  0x0A
    lb_len      equ $ - lb
; --------------------------------
section .text
    global  _start


_select_mode:
    mov     rdi, select
    mov     rsi, select_len
    mov     rdx, mode
    mov     rcx, mode_len
    call    _prompt_int
    
    cmp     al, 1
    jb      _select_mode

    cmp     al, 2
    ja      _select_mode

    ret

_encoder:
    mov     rdi, input
    mov     si, ax
    mov     rdx, t9
    mov     cx, t9_len
    call    _encode_t9

    mov     rdi, t9
    mov     si, ax
    mov     rdx, output
    mov     cx, output_len
    call    _t9_to_str

    ret

_start:
    call    _select_mode
    mov     r8b, al
    
    mov     rdi, prompt
    mov     rsi, prompt_len
    mov     rdx, input
    mov     rcx, input_len
    call    _prompt

    push    .end                    ; point the ret to .end
    cmp     r8b, 1
    je      _encoder
    
    .end:
    mov     rdi, result
    mov     rsi, result_len
    call    _write_stdout

    mov     rdi, output
    mov     rsi, output_len
    call    _write_stdout

    mov     rdi, lb
    mov     rsi, lb_len
    call    _write_stdout

    xor     edi, edi
    call    _exit
