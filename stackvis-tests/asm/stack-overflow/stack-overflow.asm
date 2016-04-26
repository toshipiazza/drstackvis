; compile with nasm -felf64 foo.asm; ld foo.o -o foo.out
bits 64
section .start
  global _start
_start:
  call func

  ; exit
  mov rax, 60
  syscall


func:
  push rbp
  mov rbp, rsp

  call func

  mov rsp, rbp
  pop rbp
  ret
