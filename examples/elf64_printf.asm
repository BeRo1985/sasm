.include("elf.inc")

.cpu(all)

.target(elf64)

.section(".text", SHF_ALLOC | SHF_EXECINSTR){
  .default(rel)
  .entrypoint
  .public(main)
  main:
  push rbp		
  mov rax, 0	
  mov rsi, offset TextString
  mov rdi, offset FormatString
  call printf	
  pop rbp	
  mov rax,0	
  ret		
}

.section(".data",  SHF_ALLOC | SHF_WRITE){
  TextString: db "Hello world!\0"
  FormatString: db "%s\n\0"
}

.external(printf)