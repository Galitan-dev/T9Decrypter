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
    
    .loop:                          ; for dil in rdi..+si (for each character)
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

    .odd:                           ; two t9 char per byte, also:
    xor     r11, r11
    mov     r11b, [rdx + r12]       ; take first t9 char (0000 0101)
    shl     al, 4                   ; offset it 4 bits to the left (0101 0000)
    add     al, r11b                ; combine 2 chars (0101 1010)
    mov     [rdx + r12], al         ; store it
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
    cmp     dil, " "
    je      .space

    cmp     dil, "A"
    jb      .invalid

    cmp     dil, "z"
    ja      .invalid

    cmp     dil, "Z"
    jbe     .uppercase

    cmp     dil, "a"
    jae     .lowercase

    .invalid:
    mov     al, 0                   ; empty t9 char
    jmp     .end

    .space:
    mov     al, 10
    jmp     .end

    .uppercase:
    add     dil, 0x20               ; downcase

    .lowercase:
    sub     dil, "a"                ; - a

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
    
    .loop:                          ; for each t9 chars
    cmp     r8w, si
    ja      .next
    cmp     r8w, cx                 ; check if there is still some place in output 
    jae     .next

    xor     r10, r10
    mov     r10b, [rdi + r8]        ; split the byte in two t9 chars
    mov     r11b, r10b
    shr     r11b, 4
    shl     r11b, 4
    sub     r10b, r11b
    shr     r11b, 4

    push    rdi
    mov     dil, r10b
    call    _t9_char_to_str         ; format first t9 char
    cmp     al, 0                   ; if empty char
    je      .second                 ; don't save it

    mov     [rdx + r8 * 2], al      ; save it

    .second:
    mov     dil, r11b
    call    _t9_char_to_str         ; format second t9 char
    cmp     al, 0                   ; if empty char
    je      .then                   ; don't save it

    mov     [rdx + r8 * 2 + 1], al  ; save it

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

    cmp     dil, 0                  ; empty t9 char
    je      .none

    mov     al, dil                 
    add     al, "0"                 ; to ascii
    ret

    .space:
    mov     al, " "
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
    
    .loop:                          ; for each char in string
    cmp     r8w, si
    jae     .next
    cmp     r8w, cx                 ; check if there is still some space in output
    jae     .next

    mov     r10b, [rdi + r8]
    sub     r10b, "0"               ; map between 0 and 9

    cmp     r10b, 0                 ; if space
    jne     .not_space

    mov     r10b, 10                ; set it to 10 (zero is empty)

    .not_space:
    test    r8b, 1                  ; test if odd char
    jnz      .odd

    mov     [rdx + r12], r10b
    jmp     .continue

    .odd:
    xor     r11, r11
    mov     r11b, [rdx + r12]       ; get first char (0000 0101)
    shl     r10b, 4                 ; 4 bytes offset (0101 0000)
    add     r10b, r11b              ; join the two chars (0101 1010)
    mov     [rdx + r12], r10b       ; save them
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

    cmp     dil, 5                  ; t5 and t7 have four chars
    je      .four
    cmp     dil, 7
    je      .four

    jmp     .next

    .four:
    inc     r8b                     ; 4 possibilites for t7 and t9

    .next:
    mov     bl, r8b                 ; number of possibilities
    mov     rax, 3
    mul     dil                     ; 3 * t9 char

    cmp     dil, 6
    jb      .then

    inc     al                      ; t7 has four chars, offset 1 for t8 and t9

    .then:
    mov     dil, al
    add     dil, "a"                ; first ascii char
    add     dil, bl                 ; last ascii char (little endian)
    xor     rax, rax

    .loop:
    cmp     r8b, 0
    je      .end

    dec     dil
    shl     rax, 8                  ; offset rax to make space
    mov     al, dil                 ; push char in space
    dec     r8b                     ; next char
    jmp     .loop

    .space:
    mov     rax, " "
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

    cmp     r8w, si                 ; if no more t9 char
    jae     .print
    cmp     r8w, cx                 ; or if no more space in output
    jae     .print                  ; push combination

    mov     r12b, 1 
    and     r12b, r8b               ; odd flag
    shr     r8w, 1                  ; divide t9 char index per two (two t9 char per byte)

    xor     r10, r10
    mov     r10b, [rdi + r8]        ; get t9 char
    mov     r11b, r10b
    shr     r11b, 4
    shl     r11b, 4
    sub     r10b, r11b

    cmp     r12b, 0                 ; if odd flag is unset
    je      .even                   ; keep first t9 char
    
    mov     r10b, r11b              ; else take second t9 char
    shr     r10b, 4

    .even:
    cmp     r10b, 0                 ; if empty char, end it (works as the terminator here)
    je      .end

    push    r8
    push    rdi
    mov     dil, r10b
    call    _list_t9_char_possibilites  ; one t9 char, multiple ascii chars
    pop     rdi
    pop     r8
    shl     r8w, 1                  ; take back ouput index
    add     r8w, r12w               ; don't forget the last bit :)))

    .loop:
    cmp     bl, 0                   ; end if no more char
    je      .end

    mov     [rdx + r8], al          ; store in output current char
    inc     r8w 
    push    rax
    call     _list_t9_combinations  ; recursivity, continue with current combination and next t9 chars
    pop     rax
    dec     r8w

    shr     rax, 8                  ; get next possible char
    dec     bl                      ; one possibility eliminated
    jmp     .loop

    .print:
    push    rdi
    mov     rdi, r8
    call    r9                      ; callback, when a combination is found
    pop     rdi

    .end:
    pop     rbx
    pop     r11
    pop     r12
    pop     r10
    pop     r8
    ret

; rdi:  t9 address
; si:   t9 length
; rdx:  ascii adress
; cx:   max ascii length (overflow will be ignored)
; r8w:  t9 offset (set to zero)
; r9:   callback address
; rdi:  callback: output length
_decrypt_t9:
    push    r8
    push    r10
    push    r12
    push    r11
    push    rbx

    cmp     r8w, si                 ; if no more t9 char
    jae     .print
    cmp     r8w, cx                 ; or if no more space in output
    jae     .print                  ; push combination

    mov     r12b, 1
    and     r12b, r8b               ; odd flag
    shr     r8w, 1                  ; divide t9 char index per two (two t9 char per byte)

    xor     r10, r10
    mov     r10b, [rdi + r8]        ; get t9 char
    mov     r11b, r10b
    shr     r11b, 4
    shl     r11b, 4
    sub     r10b, r11b

    cmp     r12b, 0                 ; if odd flag is unset
    je      .even                   ; keep first t9 char
    
    mov     r10b, r11b              ; else take second t9 char
    shr     r10b, 4

    .even:
    cmp     r10b, 0                 ; if empty char, end it (works as the terminator here)
    je      .end

    push    r8
    push    rdi
    mov     dil, r10b
    call    _list_t9_char_possibilites  ; one t9 char, multiple ascii chars
    pop     rdi
    pop     r8
    shl     r8w, 1                  ; take back ouput index
    add     r8w, r12w               ; don't forget the last bit :)))

    .loop:
    cmp     bl, 0                   ; end if no more char
    je      .end

    mov     [rdx + r8], al          ; store current char in output
    push    rax                     ; save next possible chars (made me hard times)

    push    rdi
    push    rsi
    mov     rdi, rdx
    mov     rsi, r8
    inc     rsi
    call    _is_word_possible       ; test if word if possible
    pop     rsi
    pop     rdi

    test    rax, rax
    jz      .not_possible           ; skip recursivity if not possible (branch destroyed)

    inc     r8w
    push    rax
    call     _decrypt_t9            ; recursivity, continue with current combination and next t9 chars
    pop     rax
    dec     r8w

    .not_possible:
    pop     rax
    shr     rax, 8                  ; get next possible char
    dec     bl                      ; one possibility eliminated
    jmp     .loop

    .print:
    push    rdi
    mov     rdi, r8
    call    r9                      ; callback, when a combination is found
    pop     rdi

    .end:
    pop     rbx
    pop     r11
    pop     r12
    pop     r10
    pop     r8
    ret
