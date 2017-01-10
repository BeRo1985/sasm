.include("pecoff.inc")

.cpu(all)

.target(pe64){
  imagebase = 0x400000
  codebase = 0x1000
  subsystem = IMAGE_SUBSYSTEM_WINDOWS_GUI
  characteristics = IMAGE_FILE_CHARACTERISTICS_EXE
}

.section(".text", IMAGE_SCN_CNT_CODE | IMAGE_SCN_MEM_READ | IMAGE_SCN_MEM_EXECUTE | IMAGE_SCN_ALIGN_16BYTES){
  .entrypoint
  //sub	rsp, 8*5 
  sub rsp, 0x100
  mov rcx, 0xf
  not rcx  
  and rsp, rcx    
  xor rcx, rcx
  mov rdx, offset Text
  mov r8, offset Title
  xor r9, r9
  call qword ptr abs MessageBox
  xor rcx, rcx
  call qword ptr abs ExitProcess
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
