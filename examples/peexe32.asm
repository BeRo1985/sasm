.include("pecoff.inc")

.cpu(all)

.target(pe32){
  imagebase = 0x400000
  codebase = 0x1000
  subsystem = IMAGE_SUBSYSTEM_WINDOWS_GUI  
  characteristics = IMAGE_FILE_CHARACTERISTICS_EXE
}

.section(".text", IMAGE_SCN_CNT_CODE | IMAGE_SCN_MEM_READ | IMAGE_SCN_MEM_EXECUTE | IMAGE_SCN_ALIGN_16BYTES){
  .entrypoint
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

/*
.section(".rsrc",  IMAGE_SCN_CNT_INITIALIZED_DATA | IMAGE_SCN_MEM_READ | IMAGE_SCN_MEM_SHARED | IMAGE_SCN_ALIGN_16BYTES){
  .directoryentry(IMAGE_DIRECTORY_ENTRY_RESOURCE){
    // your resource data stuff, but don't forget the RVA stuff 
  }
}*/

.library("kernel32.dll"){
  ExitProcess = "ExitProcess"
} 
  
.library("user32.dll"){
  MessageBox = "MessageBoxA"
}
