section .bss
    words_len   equ     4253831
    words       resb    words_len
    windex_len  equ     5408
    windex      resb    windex_len
; --------------------------------
section .data
    words_path  db      "assets/words.txt", 0
; --------------------------------
section .text

_load_words:
    call    _read_words
    call    _index_words

    ret

_read_words:
    push    rdi
    push    rsi
    push    rdx

    mov     rax, 2                  ; open file
    mov     rdi, words_path
    xor     rsi, rsi                ; read-only flag
    syscall

    mov     rdi, rax                ; save file descriptor (will be used in two next syscalls)

    xor     rax, rax                ; read file
    mov     rsi, words              ; destination address
    mov     rdx, words_len          ; how much (max)
    syscall

    mov     rax, 3                  ; close file
    syscall

    pop     rdx
    pop     rsi
    pop     rdi
    ret

_index_words:
    push    rdi
    push    rsi
    push    r8
    push    r10
    push    r11
    push    r12

    mov     rdi, words
    mov     rsi, words_len
    add     rsi, rdi
    mov     r8b, 1                  ; new word flag
    mov     r12w, 0                 ; last first two chars

    .loop:
    cmp     rdi, rsi
    jae     .next

    xor     r10w, r10w
    mov     r10b, [rdi]
    xor     r11w, r11w
    mov     r11b, [rdi + 1]

    cmp     r10b, 0x0A              ; check if first char is \n
    je      .between_two_words      ; otherwise the word would lose a char :o
    cmp     r11b, 0x0A              ; check if second char is \n
    je      .new_word

    test    r8b, r8b
    jz      .continue               ; if not a new word, skip

    xor     r8b, r8b                ; reset flag

    shl     r11w, 8                 ; assemble two first chars
    add     r10w, r11w

    cmp     r10w, r12w              ; if not a new pair, skip
    je      .continue

    mov     r12w, r10w              ; save pair as new

    push    rdi
    xor     rdi, rdi
    mov     di, r10w   
    call    _char_pair_index        ; get index address
    pop     rdi

    mov     [rax], rdi              ; save address in index
    jmp     .continue

    .between_two_words:
    dec     rdi

    .new_word:
    mov     r8b, 1

    .continue:
    add     rdi, 2
    jmp     .loop

    .next:
    mov     rsi, windex             ; end
    mov     rdi, windex_len         ; length
    add     rdi, rsi                ; start

    mov     r8, words               ; last_index
    add     r8, words_len

    .filler:                        ; set each index of char pair (i.e, bb) with no word to next existing char pair
    cmp     rdi, rsi
    jbe     .end

    mov     r10, [rdi]
    sub     rdi, 8
    
    cmp     r10, 0
    jne     .defined

    mov     [rdi + 8], r8
    jmp     .filler

    .defined:
    mov     r8, r10
    jmp     .filler

    .end:
    pop     r12
    pop     r11
    pop     r10
    pop     r8
    pop     rsi
    pop     rdi
    ret

; rdi: two chars
; rax: address in memory of index
_char_pair_index:
    push    r8
    push    rbx
    push    rdx

    xor     rax, rax
    xor     rbx, rbx
    
    mov     al, dil                 ; split chars
    shr     rdi, 8
    mov     bl, dil

    sub     al, "a"                ; map between 0 and 25 included
    sub     bl, "a"

    mov     r8, 26
    mul     r8                      ; 26 pairs for each char
    add     rax, rbx

    mov     r8, 8
    mul     r8                      ; 8 bytes for each index
    add     rax, windex             ; memory heap offset

    pop     rdx
    pop     rbx
    pop     r8
    ret

; rdi: word address
; rsi: word length
_is_word_possible:
    push    rdi
    push    r8
    push    r10
    push    r11
    push    r12
    push    r14

    cmp     rsi, 2
    jb      .possible

    mov     r10, rdi
    push    rdi
    xor     rdi, rdi
    mov     di, [r10]
    call    _char_pair_index        ; get index of first word with same beginning
    pop     rdi

    mov     r10, [rax]              ; start
    mov     r11, [rax + 8]          ; end
    xor     r8, r8
    xor     r14, r14

    .compare:
    cmp     r10, r11
    jae     .impossible

    test    r14, r14
    jnz     .not_equal

    cmp     r8, rsi
    jae     .possible

    .not_equal:
    mov     r12b, [r10]
    mov     r13b, [rdi + r8]

    cmp     r12b, 0x0A
    jne     .next

    xor     r8, r8
    xor     r14, r14
    inc     r10
    jmp     .compare

    .next:
    cmp     r12b, r13b
    je      .then
    
    mov     r14, 1                  ; words not equal

    .then:
    inc     r8
    inc     r10
    jmp     .compare

    .impossible:
    xor     rax, rax
    jmp     .end

    .possible:
    mov     rax, 1

    .end:
    pop     r14
    pop     r12
    pop     r11
    pop     r10
    pop     r8
    pop     rdi
    ret
