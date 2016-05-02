; compile with nasm -felf64 foo.asm; ld foo.o -o foo.out
bits 64
section .start
  global _start
_start:
  ; should see deadbeef in json
  mov rax, 0xdeadbeef
  push rax

  ; should see cafebabe in json
  mov rax, 0xcafebabe
  push rax

  ; exit
  mov rax, 60
  syscall

