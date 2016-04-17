; compile with nasm -felf64 foo.asm; ld foo.o -o foo.out
bits 64
section .data
  should_not_trigger dq 0x0000000000000000

section .start
  global _start
_start:
  ; generic push to make sure the tool is working
  mov rax, 0xcafebabedeadbeef
  push rax

  ; write to .data section, should not appear in json
  mov [should_not_trigger], rax

  ; exit
  mov rax, 60
  syscall

