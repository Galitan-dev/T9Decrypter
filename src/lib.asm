    SYS_READ    equ     0
    SYS_WRITE   equ     1
    SYS_EXIT    equ     60
    SYS_TIME    equ     201
    STDIN       equ     0
    STDOUT      equ     1
    ASCII_0     equ     0x30
    ASCII_9     equ     0x39
; --------------------------------
section .text

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

; rdi:  prompt address
; rsi:  prompt length
; rdx:  input adress
; rcx:  input length 
_prompt:
    push    rdx
    mov     rdi, rdi
    mov     rsi, rsi
    call    _write_stdout
    pop     rdx

    mov     rdi, rdx
    mov     rsi, rcx
    call    _read_stdin
    dec rax                         ; ignore line break

    ret

; ; rdi:  prompt address
; ; rsi:  prompt length
; ; rdx:  input adress
; ; rcx:  input length 
; ; rax:  result
; _prompt_int:
    
;     call    _prompt

;     mov     rdi, rdx
;     mov     rsi, rax
;     dec     rsi                     ; skip line break
;     call    _parse_int

;     ret

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

; ; rdi: adress of first byte of output
; ; rsi: number to render
; _to_str:

;     xor rax, rax
;     mov rax, rsi
;     mov r8, 10
;     xor r9, r9

;     .loop:
;     cmp rax, 0
;     jbe .write
;     xor rdx, rdx
;     .here:
;     div r8d
;     add rdx, ASCII_0
;     push rdx
;     inc r9
;     jmp .loop

;     .write:
;     cmp r9, 0
;     je .next

;     inc rdi
;     pop rax
;     mov [rdi], al
;     dec r9
;     jmp .write

;     .next:
;     ret
