.include("elf.inc")

.cpu(all)

.target(elf64)

.section(".text", SHF_ALLOC | SHF_EXECINSTR){
  .default(rel)
  .entrypoint
  .public(main)
  main:
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, offset TextString
	mov	rdx, TextLength       
	syscall
	
  mov rax, 60
  mov rdi, 0	
  syscall
  
  ret
}
 
.section(".data",  SHF_ALLOC){
  TextString: db "Hello world!\n"
  TextLength = __here__ - offset TextString
}
