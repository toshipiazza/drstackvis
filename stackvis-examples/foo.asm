; compile with nasm -felf64 foo.asm; ld foo.o -o foo.out
; output from plugin should be as comments specify
section .start
  global _start
_start:
  mov rax, 0xdeadbeef
  push rax  ; should see 0xdeadbeef in the json
  mov rax, 0xcafebabe
  push rax  ; should see 0xcafebabe in the json
  call trap ; should see the address of `pop rax`
            ; because call implicitly pushes the
            ; address of pc onto the stack
trap:
  pop rax
  push rax  ; so we can check if we in fact got
            ; the address we said we did, the
            ; output from push rax should give
            ; us the address of `pop rax`, same
            ; as the previous write

  ; exit
  mov rax, 60
  syscall
