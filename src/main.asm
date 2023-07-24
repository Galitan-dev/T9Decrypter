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
                    "  - 2: Get all word combinations from a T9 sequel", 0x0A, \
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
    push    rdi
    push    rsi
    push    rdx
    push    rcx

    mov     rdi, select
    mov     rsi, select_len
    mov     rdx, mode
    mov     rcx, mode_len
    call    _prompt_int
    
    cmp     al, 1
    jb      _select_mode

    cmp     al, 2
    ja      _select_mode

    pop     rcx
    pop     rdx
    pop     rsi
    pop     rdi
    ret

_encoder:
    push    rdi
    push    rsi
    push    rdx
    push    rcx

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

    mov     al, 1                   ; flag to print output buffer

    pop     rcx
    pop     rdx
    pop     rsi
    pop     rdi
    ret

_combinations:
    push    rdi
    push    rsi
    push    rdx
    push    rcx
    push    r8
    push    r9

    mov     rdi, input
    mov     si, ax
    mov     rdx, t9
    mov     cx, t9_len
    call    _str_to_t9

    mov     rdi, t9
    mov     si, ax
    mov     rdx, output
    mov     cx, output_len
    xor     r8, r8
    mov     r9, .on_combination
    call    _list_t9_combinations

    mov     al, 0                   ; unset flag to print output buffer
    
    pop     r9
    pop     r8
    pop     rcx
    pop     rdx
    pop     rsi
    pop     rdi
    ret
    
    .on_combination:
    push    rdi
    push    rsi

    mov     rdi, output
    mov     rsi, output_len
    call    _write_stdout

    mov     rdi, lb
    mov     rsi, lb_len
    call    _write_stdout

    pop     rsi
    pop     rdi
    ret

_start:
    call    _select_mode
    mov     r8b, al
    
    mov     rdi, prompt
    mov     rsi, prompt_len
    mov     rdx, input
    mov     rcx, input_len
    call    _prompt

    push    .print                    ; point the ret to .end

    cmp     r8b, 1
    je      _encoder

    cmp     r8b, 2
    je      _combinations
    
    .print:
    cmp     al, 0                   ; flag to print output buffer
    je      .end

    mov     rdi, result
    mov     rsi, result_len
    call    _write_stdout

    mov     rdi, output
    mov     rsi, output_len
    call    _write_stdout

    mov     rdi, lb
    mov     rsi, lb_len
    call    _write_stdout

    .end:
    xor     edi, edi
    call    _exit
