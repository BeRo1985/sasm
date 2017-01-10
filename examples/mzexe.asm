.cpu(386)

.target(mzexe){
  stack = 0x8000
  heap = 0x0
  startoffset = 0x100
}

.segment(CodeSegment){
  .entrypoint
  main:
  mov ax, seg16 DataSegment  
  mov ds, ax
  mov ah, 0x9
  mov dx, ofs16 TextString
  int 0x21
  mov ah, 0x4c
  int 0x21
}

.segment(DataSegment){
  TextString: db "Hello world!\r\n$"
}