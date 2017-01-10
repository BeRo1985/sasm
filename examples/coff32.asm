.include("pecoff.inc")

.cpu(all)

.target(coff32)

.section(".text", IMAGE_SCN_CNT_CODE | IMAGE_SCN_MEM_READ | IMAGE_SCN_MEM_EXECUTE | IMAGE_SCN_ALIGN_16BYTES){
  .entrypoint
  .public(main)
  main:
  invoke MessageBox, byte 0, dword Text, dword Title, byte 0
  invoke ExitProcess, byte 0
}
 
.section(".data",  IMAGE_SCN_CNT_INITIALIZED_DATA | IMAGE_SCN_MEM_READ | IMAGE_SCN_MEM_WRITE | IMAGE_SCN_ALIGN_16BYTES){
  Title: db "Test", 0
  Text: db "Hello world!\0"
}

.section(".bss", IMAGE_SCN_CNT_UNINITIALIZED_DATA | IMAGE_SCN_MEM_READ | IMAGE_SCN_MEM_WRITE | IMAGE_SCN_ALIGN_16BYTES){
  TestData2: db 0, 0
}

.external(ExitProcess = "_ExitProcess@4")
.external(MessageBox = "_MessageBoxA@16")
