; --------------------------------
section .text

; rdi:  ascii adress
; si:   ascii length
; rdx:  t9 adress
; cx:   max t9 length (overflow will be ignored)
_encode_t9:

    mov     r10, rdi
    xor     r8, r8
    xor     r12, r12
    
    .loop:
    cmp     r8w, si
    jae     .next
    cmp     r8w, cx
    jae     .next

    push    r8
    xor     rdi, rdi
    mov     dil, [r10 + r8]
    call    _encode_t9_char
    pop     r8

    test    r8b, 1
    jnz      .odd

    mov     [rdx + r12], al
    jmp     .continue

    .odd:
    xor     r11, r11
    mov     r11b, [rdx + r12]
    shl     al, 4
    add     al, r11b
    mov     [rdx + r12], al
    inc     r12w

    .continue:
    inc     r8w
    jmp     .loop
    
    .next:
    mov     rax, r12
    ret

; see docs/notes.md#_encode_t9_char
; affects rdi, rax and r8
; dil:  ascii char
; al:   t9 char
_encode_t9_char:
    ; map character between 0 and 26
    cmp     dil, 0x20
    je      .space

    cmp     dil, 0x41
    jb      .invalid

    cmp     dil, 0x7A
    ja      .invalid

    cmp     dil, 0x5A
    jbe     .uppercase

    cmp     dil, 0x61
    jae     .lowercase

    .invalid:
    mov     al, 0
    ret

    .space:
    mov     al, 10
    ret

    .uppercase:
    add     dil, 0x20               ; downcase

    .lowercase:
    sub     dil, 0x61               ; - a

    cmp     dil, 25                 ; z
    je      .z

    xor     rax, rax                ; remove previous div trash...
    mov     al, dil                 ; a = al, b = dil
    mov     dil, 2                  ; starts at t2...

    cmp     al, 18                  ; r
    jb      .next                   ; ...but t7 has 4 chars      

    dec     al

    .next:                          ; a / 3 + b
    mov     r8b, 3
    div     r8b                     ; not for later: divide whole rax, so keep an eye on the most significant bits ;(
    add     al, dil                  
    ret

    .z:
    mov     al, 9
    ret


; rdi:  t9 adress
; si:   t9 length
; rdx:  ascii representation adress
; cx:   max representation length (overflow will be ignored)
_t9_to_str:
    xor     r8, r8
    
    .loop:
    cmp     r8w, si
    ja      .next
    cmp     r8w, cx
    jae     .next

    xor     r10, r10
    mov     r10b, [rdi + r8]
    mov     r11b, r10b
    shr     r11b, 4
    shl     r11b, 4
    sub     r10b, r11b
    shr     r11b, 4

    push    rdi
    mov     dil, r10b
    call    _t9_char_to_str
    cmp     al, 0
    je      .second

    mov     [rdx + r8 * 2], al

    .second:
    mov     dil, r11b
    call    _t9_char_to_str
    cmp     al, 0
    je      .then

    mov     [rdx + r8 * 2 + 1], al

    .then:
    pop     rdi

    inc     r8w
    jmp     .loop
    
    .next:
    ret

; dil:  t9
; al:   ascii representation
_t9_char_to_str:
    cmp     dil, 10
    je      .space

    cmp     dil, 0
    je      .none

    mov     al, dil
    add     al, 0x30
    ret

    .space:
    mov     al, 0x30
    ret

    .none:
    mov     al, 0
    ret

