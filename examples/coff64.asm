.include("pecoff.inc")

.cpu(all)

.target(coff64)

.section(".text", IMAGE_SCN_CNT_CODE | IMAGE_SCN_MEM_READ | IMAGE_SCN_MEM_EXECUTE | IMAGE_SCN_ALIGN_16BYTES){
  .default(rel)
  .entrypoint
  .public(main)
  main:
  //sub	rsp, 8*5 
  sub rsp, 0x100
  mov rcx, 0xf
  not rcx  
  and rsp, rcx    
  xor rcx, rcx
  mov rdx, offset Text
  mov r8, offset Title
  xor r9, r9
  call MessageBox
  xor rcx, rcx
  call ExitProcess
}
 
.section(".data",  IMAGE_SCN_CNT_INITIALIZED_DATA | IMAGE_SCN_MEM_READ | IMAGE_SCN_MEM_WRITE | IMAGE_SCN_ALIGN_16BYTES){
  Title: db "Test", 0
  Text: db "Hello world!\0"
}

.section(".bss", IMAGE_SCN_CNT_UNINITIALIZED_DATA | IMAGE_SCN_MEM_READ | IMAGE_SCN_MEM_WRITE | IMAGE_SCN_ALIGN_16BYTES){
  TestData2: db 0, 0
}

.external(ExitProcess = "ExitProcess")
.external(MessageBox = "MessageBoxA")
