.include("elf.inc")

.cpu(all)

.target(elf32)

//.external(_GLOBAL_OFFSET_TABLE_)
//.external(printf = "printf")

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
     
// PIC stuff
// push ebx
// call @getgot
// @getgot:  
// pop ebx
// add ebx, __gotpc__(_GLOBAL_OFFSET_TABLE_ + __no_relocation__(__here__ - @getgot))
}
 
.section(".data",  SHF_ALLOC | SHF_WRITE){
  TextString: db "Hello World!\n"
  TextLength = _here_ - offset TextString
}
