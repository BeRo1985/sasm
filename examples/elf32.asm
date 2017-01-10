.include("elf.inc")

.cpu(all)

.target(elf32)

.section(".text", SHF_ALLOC | SHF_EXECINSTR){
  .entrypoint
  .public(main)
  main:
	mov	eax,4		              
	mov	ebx,1		              
	mov	ecx,offset TextString 
	mov	edx,TextLength        
	int	0x80		              
	
	mov	eax,1		              
	mov	ebx,0		              
	int	0x80		         

  ret  
}
 
.section(".data",  SHF_ALLOC){
  TextString: db "Hello world!\n"
  TextLength = __here__ - offset TextString
}
