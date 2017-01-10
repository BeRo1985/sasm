ImageBase = 0x400000
SectionAlignment = 0x4
FileAlignment = 0x4
StackReserve = 0x1000
StackCommit = 0x1000
HeapReserve = 0x1000
HeapCommit = 0x1000

.cpu(386)
.target(bin)
.startoffset(IMAGEBASE)

.code {
  .entrypoint
  .bits(16)

  CodeStart:

  db "MZ"
  push dx
  ret

  .bits(32)

  PEOptionalHeaderSize = PEOptionalHeaderEnd - PEOptionalHeader
  ImageSize = FileEnd - ImageBase
  ImportSize = ImportDirectoryEnd - ImportDirectory

  PEHeader:
  dd "PE\0\0"             // PE Signature
  dw 0x014C               // cpu (386)
  dw 2                    // number of sections
  dd "BEP\0"              // timestamp
  dd 0                    // symbol table address
  dd 0                    // number of symbols
  dw PEOptionalHeaderSize // size of optional header
  dw 0x010F               // characteristics

  PEOptionalHeader:
  dw 0x010B                         // magic
  dw 0                              // linker version
  dd 0                              // size of code section
  dd 0                              // size of initialised data
  dd 0                              // size of uninitialised data
  dd EntryPointAddress  - ImageBase // entry point address
  dd 0                              // base of code
  dd 0                              // base of data
  dd ImageBase                      // base of image
  dd SectionAlignment               // section Alignment
  dd FileAlignment                  // file Alignment
  dw 1                              // os version major
  dw 0                              // os version minor
  dw 0                              // image version major
  dw 0                              // image version minor
  dw 4                              // subsystem version major
  dw 0                              // subsystem version minor
  dd 0                              // win32 version (reserved)
  dd ImageSize                      // image size
  dd HeaderSize - ImageBase         // header size
  dd 0                              // checksum
  dw 0x0002                         // subsystem (GUI)
  dw 0                              // dll characteristics
  dd StackReserve                   // stack reserve size
  dd StackCommit                    // stack commit size
  dd HeapReserve                    // heap reserve size
  dd HeapCommit                     // heap commit size
  dd 0                              // loader flags (obsolete)
  dd 2                              // number of directory entries

  DirectoryEntries:
  dq 0                                // export
  dd ImportDirectory  - ImageBase     // import section rva
  dd ImportSize                       // import section size
  
  PEOptionalHeaderEnd:

  CodeSize = CodeEnd - CodeStart
  CodeHeader:  
  db "BeRo^fr!"            // name
  dd CodeSize              // virtual size
  dd CodeStart - ImageBase // rva
  dd CodeSize              // raw size
  dd CodeStart - ImageBase // raw pointer to data
  dd 0                     // pointer to relocations
  dd 0                     // pointer to line numbers
  dw 0                     // number of relocations
  dw 0                     // number of line numbers
  dd 0x0E0000020           // characteristics

  dummyheader:
  db "It's art"           // name
  dd 0                    // virtual size
  dd 0                    // rva
  dd 0                    // raw size
  dd 0                    // raw pointer to data
  dd 0                    // pointer to relocations
  dd 0                    // pointer to line numbers
  dw 0                    // number of relocations
  dw 0                    // number of line numbers
  dd 0x0E0000020          // characteristics

  HeaderSize:

  .align(4)

  ImportDirectory:
    dd 0, 0, 0xffffffff, KernelName - ImageBase, KernelTable - ImageBase
    dd 0, 0, 0, 0, 0
  
  KernelName: 
    db "kernel32.dll\0"
    
  NameLoadLibraryA: 
    db "\0\0LoadLibraryA\0"
  NameGetProcAddress: 
    db "\0\0GetProcAddress\0"
    
  KernelTable:
    LoadLibraryAAdr: 
      dd NameLoadLibraryA - ImageBase
    GetProcAddressAdr: 
      dd NameGetProcAddress - ImageBase
   dd 0

  LoadLibraryA = ImageBase + LoadLibraryAAdr
  GetProcAddress = ImageBase + GetProcAddressAdr
  ImportDirectoryEnd:

  EntryPointAddress:

  call [LoadLibraryAAdr]
  
  ret
  
  CodeEnd:
  
  FileEnd:

}