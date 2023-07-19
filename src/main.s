.global _start

.text

_print:
        mov     %rsi, %rsi
        mov     %rdi, %rdx
        mov     $1, %rax
        mov     $1, %rdi
        syscall
        ret

_start:
        mov     $hw, %rsi
        mov     $hwl, %rdi
        call    _print

        mov     $60, %rax
        xor     %rdi, %rdi
        syscall

.data

hw:
        .ascii  "Hello, world!\n"
        hwl     = . - hw
