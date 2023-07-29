    SYS_READ    equ     0
    SYS_WRITE   equ     1
    SYS_EXIT    equ     60
    SYS_TIME    equ     201
    STDIN       equ     0
    STDOUT      equ     1
; --------------------------------
section .text

_write_stdout:
    push    rdx
    push    rsi
    push    rdi

    mov     rdx, rsi
    mov     rsi, rdi
    mov     rdi, STDOUT
    mov     rax, SYS_WRITE
    syscall

    pop     rdi
    pop     rsi
    pop     rdx
    ret

_read_stdin:
    push    rdx
    push    rsi
    push    rdi

    mov     rdx, rsi
    mov     rsi, rdi
    mov     rdi, STDIN
    mov     rax, SYS_READ
    syscall

    pop     rdi
    pop     rsi
    pop     rdx
    ret

; rdi:  prompt address
; rsi:  prompt length
; rdx:  input adress
; rcx:  input length 
_prompt:
    push    rdi
    push    rsi

    mov     rdi, rdi
    mov     rsi, rsi
    call    _write_stdout

    mov     rdi, rdx
    mov     rsi, rcx
    call    _read_stdin
    dec     rax                         ; ignore line break

    pop     rsi
    pop     rdi
    ret

; rdi:  prompt address
; rsi:  prompt length
; rdx:  input adress
; rcx:  input length 
; rax:  result
_prompt_int:
    push    rdi
    push    rsi
    push    rbx

    call    _prompt

    mov     rdi, rdx
    mov     rsi, rax
    call    _parse_int

    pop    rbx
    pop     rsi
    pop     rdi
    ret

_exit:
    mov     rax, SYS_EXIT
    syscall
    ret

; rdi: number
; rsi: exponant
; rax: result
_power:
    push    r8

    mov     rax, 1
    mov     r8, 0

    .loop:
    cmp     r8, rsi
    je      .done
    mul     rdi
    inc     r8
    jmp     .loop

    .done:
    pop     r8
    ret

; rdi: adress of first byte
; rsi: length
; rax: result
; rbx: status, (0: ok, 1: err)
_parse_int:
    push    r9
    push    rdi

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

    cmp     r9b, "0" 
    jb      .err
    cmp     r9b, "9"
    ja      .err
    sub     r9, "0"
    
    push    rax
    push    rdi
    push    rsi
    mov     rdi, 10
    mov     rsi, r8
    call    _power
    mul     r9
    pop     rsi
    pop     rdi
    pop     r9
    add     rax, r9

    inc     r8
    jmp     .loop

    .err:
    inc     rbx

    .done:
    pop     rdi
    pop     r9
    ret
