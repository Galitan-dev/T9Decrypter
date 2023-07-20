    %include      "lib.asm"
    %include      "hello.asm"
; --------------------------------
section .text
    global  _start

_start:
    call    _hello

    xor     edi, edi
    call    _exit
