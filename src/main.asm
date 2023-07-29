    %include    "lib.asm"
    %include    "words.asm"
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
                    "  - 3: Decrypt a T9 sequel", 0x0A, \
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

    cmp     al, 3
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

    mov     rsi, rdi
    mov     rdi, output
    call    _write_stdout

    mov     rdi, lb
    mov     rsi, lb_len
    call    _write_stdout

    pop     rsi
    pop     rdi
    ret

_decrypt:
    call    _load_words             ; load and index words in memory

    push    rdi
    push    rsi
    push    rdx
    push    rcx
    push    r8
    push    r9

    mov     rdx, t9
    mov     cx, t9_len
    call    _str_to_t9

    .here:
    mov     rdi, t9
    mov     si, ax
    mov     rdx, output
    mov     cx, output_len
    xor     r8, r8
    mov     r9, .on_combination
    call    _decrypt_t9

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

    mov     rsi, rdi
    mov     rdi, output
    call    _write_stdout

    mov     rdi, lb
    mov     rsi, lb_len
    call    _write_stdout

    pop     rsi
    pop     rdi
    ret

_start:
    pop     r10                     ; argc: number of arguments ...
    dec     r10                     ; ... including program name
    pop     rax                     ; argv[0] = program name

    cmp     r10b, 1
    jb      .mode

    pop     rdi                     ; argv[1]
    mov     r8b, [rdi]
    sub     r8b, 0x30
    jmp     .next

    .mode:
    call    _select_mode
    mov     r8b, al

    .next:
    cmp     r10b, 2
    jb      .input

    pop     rdi
    xor     r11b, r11b
    xor     rsi, rsi

    .loop:
    mov     r11b, [rdi + rsi]

    cmp     r11b, 0x00
    je      .then

    inc     rsi
    jmp     .loop

    .input:
    mov     rdi, prompt
    mov     rsi, prompt_len
    mov     rdx, input
    mov     rcx, input_len
    call    _prompt

    mov     rdi, input
    mov     rsi, rax

    .then:
    push    .print                    ; point the ret to .end

    cmp     r8b, 1
    je      _encoder

    cmp     r8b, 2
    je      _combinations

    cmp     r8b, 3
    je      _decrypt
    
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
