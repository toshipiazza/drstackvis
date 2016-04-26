; compile with nasm -felf64 foo.asm; ld foo.o -o foo.out
bits 64
section .start
  global _start
_start:
  call func1    ; should see the address of `pop rax`
                ; because call implicitly pushes the
                ; address of pc onto the stack
  ; exit
  mov rax, 60
  syscall


func1:
  push rbp      ; this should be 0 initially,
  mov rbp, rsp  ; because there is no stack
                ; frame yet
  call func2

  mov rsp, rbp
  pop rbp
  ret

func2:
  push rbp
  mov rbp, rsp

  ; should be able to see on the stack
  ; at this point the return address,
  ; or the address of the above mov rax, 60
  ; followed by the saved ebp

  mov rsp, rbp
  pop rbp
  ret
