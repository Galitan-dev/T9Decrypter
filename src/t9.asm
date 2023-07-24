; --------------------------------
section .text

; rdi:  ascii adress
; si:   ascii length
; rdx:  t9 adress
; cx:   max t9 length (overflow will be ignored)
_encode_t9:
    push    r10
    push    r8
    push    r12
    push    rdi
    push    r11

    mov     r10, rdi
    xor     r8, r8
    xor     r12, r12
    
    .loop:
    cmp     r8w, si
    jae     .next
    cmp     r8w, cx
    jae     .next

    xor     rdi, rdi
    mov     dil, [r10 + r8]
    call    _encode_t9_char

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

    pop     r11
    pop     rdi
    pop     r12
    pop     r8
    pop     r10
    ret

; see docs/notes.md#_encode_t9_char
; dil:  ascii char
; al:   t9 char
_encode_t9_char:
    push    r8
    push    rdi

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
    jmp     .end

    .space:
    mov     al, 10
    jmp     .end

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
    jmp     .end

    .z:
    mov     al, 9

    .end:
    pop     rdi
    pop     r8
    ret


; rdi:  t9 adress
; si:   t9 length
; rdx:  ascii representation adress
; cx:   max representation length (overflow will be ignored)
_t9_to_str:
    push    r8
    push    r10
    push    r11

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
    pop     r11
    pop     r10
    pop     r8
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

; rdi:  ascii representation address
; si:   ascii representation length
; rdx:  t9 address
; dx:   max t9 length (overflow will be ignored)
; ax:   output length
_str_to_t9:
    push    r8
    push    r12
    push    rbx
    push    r10
    push    r11

    xor     r8, r8
    xor     r12, r12
    xor     rbx, rbx
    
    .loop:
    cmp     r8w, si
    jae     .next
    cmp     r8w, cx
    jae     .next

    mov     r10b, [rdi + r8]
    sub     r10b, 0x30

    cmp     r10b, 0
    jne     .not_space

    mov     r10b, 10

    .not_space:
    test    r8b, 1
    jnz      .odd

    mov     [rdx + r12], r10b
    jmp     .continue

    .odd:
    xor     r11, r11
    mov     r11b, [rdx + r12]
    shl     r10b, 4
    add     r10b, r11b
    mov     [rdx + r12], r10b
    inc     r12w

    .continue:
    inc     r8w
    jmp     .loop

    .next:
    mov     ax, r8w

    pop     r11
    pop     r10
    pop     rbx
    pop     r12
    pop     r8
    ret

; dil:  t9 byte
; rax:  characters each on one byte
; bl:   number of possibilities
_list_t9_char_possibilites:
    push    r8
    push    rdi

    cmp     dil, 2                  ; invalid
    jb     .end

    cmp     dil, 10                 ; invalid
    ja      .end

    cmp     dil, 10                 ; space
    je      .space

    mov     r8b, 3                  ; number of possibilities
    sub     dil, 2                  ; between 0 and 7 included

    cmp     dil, 5
    je      .four
    cmp     dil, 7
    je      .four

    jmp     .next

    .four:
    inc     r8b                     ; 4 possibilites for t7 and t9

    .next:
    mov     bl, r8b
    mov     rax, 3
    mul     dil

    cmp     dil, 6
    jb      .then

    inc     al                     ; t7 has four chars, offset 1 for t8 and t9

    .then:
    mov     dil, al
    add     dil, 0x41
    add     dil, bl
    xor     rax, rax

    .loop:
    cmp     r8b, 0
    je      .end

    dec     dil
    shl     rax, 8
    mov     al, dil
    dec     r8b
    jmp     .loop

    .space:
    mov     rax, 0x20
    mov     rbx, 1

    .end:
    pop     rdi
    pop     r8
    ret

; rdi:  t9 address
; si:   t9 length
; rdx:  ascii adress
; cx:   max ascii length (overflow will be ignored)
; r8w:  t9 offset (set to zero)
; r9:   callback address
; rdi:  callback: output length
_list_t9_combinations:
    push    r8
    push    r10
    push    r12
    push    r11
    push    rbx

    cmp     r8w, si
    jae     .print
    cmp     r8w, cx
    jae     .print

    mov     r12b, 1
    and     r12b, r8b               ; odd flag
    shr     r8w, 1

    xor     r10, r10
    mov     r10b, [rdi + r8]
    mov     r11b, r10b
    shr     r11b, 4
    shl     r11b, 4
    sub     r10b, r11b

    cmp     r12b, 0
    je      .even
    
    mov     r10b, r11b
    shr     r10b, 4

    .even:
    cmp     r10b, 0
    je      .end

    push    r8
    push    rdi
    mov     dil, r10b
    call    _list_t9_char_possibilites
    pop     rdi
    pop     r8
    shl     r8w, 1
    add     r8w, r12w

    .loop:
    cmp     bl, 0
    je      .end

    mov     [rdx + r8], al
    inc     r8w
    push    rax
    call     _list_t9_combinations
    pop     rax
    dec     r8w

    shr     rax, 8
    dec     bl
    .here:
    jmp     .loop

    .print:
    push    rdi
    mov     rdi, r8
    call    r9
    pop     rdi

    .end:
    pop     rbx
    pop     r11
    pop     r12
    pop     r10
    pop     r8
    ret
