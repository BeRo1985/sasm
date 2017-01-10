/***************************************************************************************
**
**                                TINE (This is not EFI)
**
**                           Version 1.00.2015.09.22.13.10.0000
**
****************************************************************************************
**
** A fake-(U)EFI boot loader, which loads a PE64 EFI application image on the 1 MB 
** boundary, but this boot loader doesn't emulate the (U)EFI API interface, because
** it's designed for kernel images, which can differ from what they are loaded, whether
** from a real (U)EFI or fake (U)EFI image boot loader, for to have a single kernel 
** image file for both BIOS/CSM and (U)EFI worlds, for to simplify the operating
** system development on x86-64 for to support both worlds. 
**
** When a PE64 EFI application image is loaded from this fake-(U)EFI boot loader, then
** the RAX register contains 0xbabeface and the RBX register contains a pointer to a
** multiboot-based data info structure (with informations to memory map, boot drive,
** etc.)
**
** It supports FAT12, FAT16 and FAT32 file systems with auto-detection, where the VBR
** boot sector must be loaded at 0x07c0:0x0000 / 0x0000:0x7c00 since this boot loader
** parses the BPB data from this memory place.
**
** You do need my own assembler SASM for to build this source code. For to get the 
** current stable SASM binary, write me a mail at benjamin[at]rosseaux[dot]de together
** with your used development operating system, so that I can compile my assembler for
** your OS.    
**
****************************************************************************************
**
** Copyright (C) 2015, Benjamin 'BeRo' Rosseaux ( benjamin[at]rosseaux[dot]de )
** All rights reserved.
** 
** Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are met:
** 
** 1. Redistributions of source code must retain the above copyright notice, this
**    list of conditions and the following disclaimer.
** 2. Redistributions in binary form must reproduce the above copyright notice,
**    this list of conditions and the following disclaimer in the documentation
**    and/or other materials provided with the distribution.
** 3. Neither the name of the copyright holders nor the names of its contributors 
**    may be used to endorse or promote products derived from this software without 
**    specific prior written permission.
** 
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
** ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
** WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
** DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
** ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
** (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
** LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
** ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
** SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
** 
** The views and conclusions contained in the software and documentation are those
** of the authors and should not be interpreted as representing official policies,
** either expressed or implied, of the author.
**
**************************************************************************************/

.cpu(all)
.target(bin)
.bits(16)
.startoffset(0x0700)                   // 0070:0000 (/ 0000:0700) where also the MS VBR boot sector would load us
          
CodeSegment = 0x0000                   // Maximal 29952 bytes code size for this code from 0x0000:0x0700 up to until 0x0000:07c00 
StackSegment = 0x2000                  // 64k stack
BufferSegment = 0x3000                 // 64k buffer segment just right after the 64k stack
FATBufferSegment = 0x4000              // FAT buffer segment just right after the 64k buffer

PagingTableAddress = 0x8000            // 1024 bytes after the boot sector address 0x7c00      

MemoryMapAddress = 0x50000             // where the ax=0xe820 int 0x15 memory map will stored

KernelLoadAddress = 0x1000000          // Load kernel raw data on the 16 MB boundary (after the possible ISA hole memory ranges)
KernelUncompressedAddress = 0x2000000  // Unpacked kernel on the 32 MB boundary 
KernelBaseAddress = 0x100000           // Load parsed kernel on the 1 MB boundary (maximal 14MB raw data size => 16 MB - (1 MB lower memory + 1 MB possible ISA hole memory ranges)

BootLoaderMagic = 0xbabeface           // instead multiboot signature 0x2badb002, since we're a fake-(U)EFI boot loader and not a multiboot-compliant boot loader 

VBRAddress = 0x7c00

vbsOemName = VBRAddress + 0x03
vbpbBytesPerSector = VBRAddress + 0x0b
vbpbSectorsPerCluster = VBRAddress + 0x0d
vbpbReservedSectors = VBRAddress + 0x0e
vbpbNumberOfFATs = VBRAddress + 0x10
vbpbRootEntries = VBRAddress + 0x11
vbpbTotalSectors = VBRAddress + 0x13
vbpbMedia = VBRAddress + 0x15
vbpbSectorsPerFAT = VBRAddress + 0x16
vbpbSectorsPerTrack = VBRAddress + 0x18
vbpbHeadsPerCylinder = VBRAddress + 0x1a
vbpbHiddenSectors = VBRAddress + 0x1C
vbpbTotalSectorsBig = VBRAddress + 0x20
vOfsDriveNumber equ VBRAddress + 0x24 
vbpb32SectorsPerFAT = VBRAddress + 0x24
vbpb32Flags = VBRAddress + 0x28
vbpb32Version = VBRAddress + 0x2a
vbpb32RootCluster = VBRAddress + 0x2c
vbpb32InfoSector = VBRAddress + 0x30
vbpb32BootBackupStart = VBRAddress + 0x32
vbpb32Reserved = VBRAddress + 0x34
vOfs32DriveNumber equ VBRAddress + 0x40  
 
FATWorkData = VBRAddress + 0x80
FATWorkDataFATSize = FATWorkData + 0
FATWorkDataSectorSizeBits = FATWorkData + 4
FATWorkDataClusterSizeBits = FATWorkData + 8
FATWorkDataNumSectors = FATWorkData + 12
FATWorkDataHiddenSectors = FATWorkData + 16
FATWorkDataFATOffset = FATWorkData + 20
FATWorkDataFATLength = FATWorkData + 24
FATWorkDataRootOffset = FATWorkData + 28
FATWorkDataRootMax = FATWorkData + 32
FATWorkDataDataOffset = FATWorkData + 36
FATWorkDataNumClusters = FATWorkData + 40
FATWorkDataFilePos = FATWorkData + 44
FATWorkDataRootCluster = FATWorkData + 48
FATWorkDataClusterEOFMarker = FATWorkData + 52
FATWorkDriveNumber = FATWorkData + 56
FATWorkFileCluster = FATWorkData + 60
FATWorkDataSectorsPerCluster = FATWorkData + 64
FATWorkDataBytesPerSector = FATWorkData + 68
    
.macro(GDTEntry)(gdtLimit,gdtBase_00_15,gdtBase_16_23,gdtType,gdtMisc,gdtBase_24_31){
  dw gdtLimit
  dw gdtBase_00_15
  db gdtBase_16_23
  db gdtType
  db gdtMisc
  db gdtBase_24_31
}

.macro(PrintMessage)(TextMessage){
  .local SkipLabel, TextData
    jmp SkipLabel
  TextData:
    db TextMessage 
    db 0 
  SkipLabel:    
    pushad
    mov si, offset TextData
    call PrintNullTerminatedString
    popad 
}

.macro(PrintHeximal)(Bits, Value){
  !if(Bits == 8){
    pushad
     mov al, Value
     call PrintHexByte
    popad
  }else if(Bits == 16){
    pushad
     mov ax, Value
     call PrintHexWord
    popad
  }else if(Bits == 32){
    pushad
     mov eax, Value
     call PrintHexDWord
    popad
  }
}

.macro(PrintDecimal)(Bits, Value){
  !if((Bits == 8) || (Bits == 16)){
    pushad
     movzx eax, Value
     call PrintDWord
    popad
  }else if(Bits == 32){
    pushad
     mov eax, Value
     call PrintDWord
    popad
  }
}

.struct(TFATDirectoryEntry){
  FileName byte(11)
  Attributes byte(1)
  Reserved byte(1)
  CreationTimeMillisecondOrChecksum byte(1)
  CreationTimeHourMinute word(1)
  CreatedDate word(1)
  LastAccessedDate word(1)
  ClusterHi32 word(1)
  Time word(1)
  Date word(1)
  Cluster word(1)
  Size dword(1)
}

////////////////////////

PEEXEMAGIC = 0x00004550

IMAGE_FILE_MACHINE_AMD64 = 0x8664

.struct(TPE64Header){
  Signature dword(1)
  CPUType word(1)
  NumberOfSections word(1)
  TimeStamp dword(1)
  PointerToSymbolTable dword(1)
  NumberOfSymbols dword(1)
  SizeOfOptionalHeader word(1)
  Characteristics word(1)
  Magic word(1)
  MajorLinkerVersion byte(1)
  MinorLinkerVersion byte(1)
  SizeOfCode dword(1)
  SizeOfInitializedData dword(1)
  SizeOfUninitializedData dword(1)
  AddressOfEntryPoint dword(1)
  BaseOfCode dword(1)
  BaseOfImage qword(1)
  SectionAlignment dword(1)
  FileAlignment dword(1)
  MajorOperatingSystemVersion word(1)
  MinorOperatingSystemVersion word(1)
  MajorImageVersion word(1)
  MinorImageVersion word(1)
  MajorSubsystemVersion word(1)
  MinorSubsystemVersion word(1)
  Win32VersionValue dword(1)
  ImageSize dword(1)
  HeaderSize dword(1)
  CheckSum dword(1)
  SubSystem word(1)
  DLLCharacteristics word(1)
  StackReserve qword(1)
  StackCommit qword(1)
  HeapReserve qword(1)
  HeapCommit qword(1)
  LoaderFlags dword(1)
  NumberOfRVAAndSizes dword(1)
  ExportRVA dword(1)
  ExportSize dword(1)
  ImportRVA dword(1)
  ImportSize dword(1)
  ResourceRVA dword(1)
  ResourceSize dword(1)
  ExceptionRVA dword(1)
  ExceptionSize dword(1)
  SecurityRVA dword(1)
  SecuritySize dword(1)
  RelocationRVA dword(1)
  RelocationSize dword(1)
  DebugRVA dword(1)
  DebugSize dword(1)
  ImageDescRVA dword(1)
  ImageDescSize dword(1)
  MachineRVA dword(1)
  MachineSize dword(1)
  TLSRVA dword(1)
  TLSSize dword(1)
}

.struct(TPE64SectionHeader){
  Name byte(8)
  VirtualSize dword(1)
  RVA dword(1)
  PhysicalSize dword(1)
  PhysicalOfs dword(1)
  Reserved dword(3)
  Flags dword(1)
}

.struct(TPE64Relocation){
  PageRVA dword(1)
  BlockSize dword(1)
}

////////////////////////

.code {

  // We're loaded at 0070:0000 
  
  {
    LoaderEntryPoint:
      jmp short SkipSignature
    Signature: 
      db "TINE\0"
      !script{
          var MillisecondsElapsedSince1January1970_00_00_00_UTC = Date.now();
          var TimeDateString = (new Date()).toUTCString();
          Assembler.parse("dq " + MillisecondsElapsedSince1January1970_00_00_00_UTC);
          Assembler.parse("db \"" + TimeDateString + "\\0\"");
      }    
    SkipSignature:

      // Jump from 0070:0000 into 0000:0700 space, so that CS and DS can be zero
      jmp word 0x0000:offset StartCode 
    StartCode:
      
      // Setup stack
      mov ax, StackSegment
      mov ss, ax           
      mov sp, 0xffff         
      
      // Data segment = code segment
      push cs
      pop ds
      
      call ClearScreen
      
      PrintMessage "Loading system . . .\r\n"      
                       
      PrintMessage "Enabling A20 line . . . "      
      call EnableA20                                      // Enable A20 line
      jz Hang
      PrintMessage "done!\r\n"      

      PrintMessage "Enabling unreal mode . . . "      
      call EnableUnrealMode                               // Enable unreal mode for FS segment register 
      jz Hang
      PrintMessage "done!\r\n"      

      PrintMessage "Checking for 64-bit capable processor . . . "      
      call CheckLongMode
      jz Hang
      PrintMessage "done!\r\n"      
 
      PrintMessage "Getting memory map . . . "      
      call GetMemoryMap                                   // Get memory map 
      jz Hang
      mov ebx, 24
      mul ebx 
      mov dword ptr [BootInfoMemoryMapLength], eax
      PrintMessage "done! "
      pushad
       mov eax, dword ptr [MemorySize]
       mov edx, dword ptr [MemorySize+4]
       shrd eax, edx, 20
       shr edx, 20
       call PrintDWord
      popad
      PrintMessage " MB RAM found . . .\r\n"
        
      PrintMessage "Initializing FAT file system . . . "      
      call InitializeFATFileSystem                        // Detect and initialize FAT file system
      jz Hang
      PrintMessage "done! FAT"
      PrintDecimal 32, dword ptr cs:[FATWorkDataFATSize]
      PrintMessage " file system found . . .\r\n"
      
      PrintMessage "Searching kernel image file . . . "      
      call FindFile
      jz Hang
      PrintMessage "done!\r\n"      
      
      PrintMessage "Loading kernel image file . . . "      
      call LoadKernel
      je Hang
      PrintMessage "done!\r\n"      
      
      PrintMessage "Parsing kernel image and jumping to kernel image entry point . . .\r\n"      
      
    EnterProtectedMode:
      cli
     
      push cs             
      pop ds             
      lgdt cs:[GDTDescriptor]                             // Load the GDT descriptor
      
      lidt cs:[IDTDescriptor]                             // Load the IDT descriptor
      
      mov eax, cr0          
      or eax, 1             
      mov cr0, eax          
  
      jmp dword 0x0008:(CodeSegment << 4) + (offset Code32)

    KernelEntryPoint:
      dd 0
      
    .bits(32)
    Code32:
      mov ax, 0x10      
      mov ds, ax        
      mov es, ax        
      mov fs, ax        
      mov gs, ax        
      mov ss, ax        
      mov esp, 0x90000  

      jmp dword 0x0008:(CodeSegment << 4) + (offset Code32ReloadSegments)
    Code32ReloadSegments:

      // Check for LZBRABIN signature    
      mov ebx, KernelLoadAddress
      cmp dword ptr [ebx], 'RBZL' 
      jne KernelUncompressed
      cmp dword ptr [ebx + 4], 'GMIA' 
      jne KernelUncompressed
      
    KernelUncompress:  
      mov edx, KernelUncompressedAddress
      push edx
      add ebx, 8 + 4
      call LZBRADepacker
      pop ebx
      
    KernelUncompressed:
    
      cmp dword ptr [ebx], 'FLE\x7F'  
      je KernelLoadELF
      
    KernelLoadPE:        
      mov eax, ebx
      cmp word ptr [eax], 'ZM'   
      jne KernelLoadFlat
      add eax, dword ptr [eax + 0x3c]
      cmp word ptr [eax], 'EP'   
      jne KernelLoadFlat      
      mov edi, KernelBaseAddress
      call LoadPE64    
      mov dword ptr [KernelEntryPoint], eax
      jmp KernelLoadFlatSkip
      
    KernelLoadELF:
    KernelLoadELFHang:
      jmp KernelLoadELFHang
      jmp KernelLoadFlatSkip
     
    KernelLoadFlat:
      
      mov esi, ebx
      mov edi, KernelBaseAddress
      mov dword ptr [KernelEntryPoint], edi
      mov ecx, 0xe00000 >> 2
      cld
      rep movsd

    KernelLoadFlatSkip:    
      
      call BuildPagingTable      
    
      // Entering long mode
      
      // Disabling paging
      mov eax, cr0       
      and eax, 0x7fffffff
      mov cr0, eax       
      
      // Build new page table directory
      
      // Set the paging table address into CR3 
      mov eax, PagingTableAddress  
      mov cr3, eax          
    
      // Set the PAE enable bit in CR4
      mov eax, cr4
      or eax, 0x20
      mov cr4, eax
      
      // Enable long mode by setting the EFER.LME flag in MSR 0xC0000080
      mov ecx, 0x0c0000080
      rdmsr
      or eax, 0x100
      wrmsr 

      // Enabling paging and protected mode
      mov eax, cr0
      or eax, 0x80000001
      mov cr0, eax      

      lgdt [GDT64Descriptor]       
      
      jmp dword 0x0008:(CodeSegment << 4) + (offset Code64)
      
    .bits(64)
    Code64:   
    
      mov ax, 0x0010
      mov ds, ax
      mov es, ax
      mov fs, ax
      mov gs, ax
      mov ss, ax
     
      mov rax, BootLoaderMagic
      mov rbx, (CodeSegment << 4) + (offset BootInfo)
      
      // Calling kernel entry point
      xor rdx, rdx
      mov edx, dword ptr [KernelEntryPoint]
      call rdx
      
    Code64Hang:
      hlt
      jmp Code64Hang
      
    .bits(16)
    Hang:
      PrintMessage "ERROR ! ! !\r\n"      
      HangLoop:
      hlt
      jmp HangLoop  
  } 
  
  { // Build a paging table for the first maximal 64 MB of memory 
    PagingTablePML4T = PagingTableAddress
    PagingTablePDPT = PagingTableAddress + 0x1000 
    PagingTablePDT = PagingTableAddress + 0x2000 
    PagingTablePT = PagingTableAddress + 0x3000     
    PagingTable16MB = 16777216
    PagingTableSize = 67108864                      // must be dividable by 2 megabytes (because 1 PT = 2 megabytes)
    .bits(32)
    BuildPagingTable:
      
      // Truncating detected memory size down to 64 MB for our initial paging table
      mov edx, dword ptr [MemorySize + 4] 
      test edx, edx
      jnz BuildPagingTableSizeTruncate      
      mov edx, dword ptr MemorySize
      mov eax, PagingTable16MB
      cmp edx, eax
      cmovl edx, eax
      cmp edx, PagingTableSize
      jle BuildPagingTableSizeNoTruncate
    BuildPagingTableSizeTruncate: 
      mov edx, PagingTableSize 
    BuildPagingTableSizeNoTruncate:          
      
      // Clear paging table memory range 
      xor eax, eax    
      mov ecx, ((PagingTablePT - PagingTablePML4T) + (PagingTableSize >> 10)) >> 2 // PML4T + PDPT + PDT + PT
      mov edi, PagingTableAddress
      rep stosd
      
      // Maps 256 TB
      mov dword ptr [PagingTablePML4T], PagingTablePDPT | 000000000011b                     // Present, R/W, Supervisor     

      // Maps 512 GB
      mov dword ptr [PagingTablePDPT], PagingTablePDT | 000000000011b                       // Present, R/W, Supervisor       

      // Maps 1 GB
      mov eax, PagingTablePT | 000000000011b       // Present, R/W, Supervisor       
      mov ebx, PagingTablePDT
      mov ecx, edx
      shr ecx, 21                                  // divide by 2 megabytes   
      jecxz BuildPagingTablePDTLoopSkip
    BuildPagingTablePDTLoop:
      mov dword ptr [ebx], eax
      add eax, 0x1000
      add ebx, 0x08
      dec ecx
      jnz BuildPagingTablePDTLoop
    BuildPagingTablePDTLoopSkip:  
      
      // Maps PagingTableSize in 2 megabytes PT blocks with 4 kilobytes per entry
      mov eax, 000000000011b // Present, R/W, Supervisor   
      mov ecx, edx          
      shr ecx, 12            // divide by 4 kilobytes     
      mov edi, PagingTablePT
    BuildPagingTableLoop:
      mov dword ptr [edi], eax
      add edi, 8
      add eax, 0x1000
      dec ecx
      jnz BuildPagingTableLoop
      
      ret
  }

  {
    .bits(32)

    LZBRADepackerFlagModel = 0
    LZBRADepackerPrevMatchModel = 2
    LZBRADepackerMatchLowModel = 3
    LZBRADepackerLiteralModel = 35
    LZBRADepackerGamma0Model = 291
    LZBRADepackerGamma1Model = 547
    LZBRADepackerSizeModels = 803

    LZBRADepackerLocalSize = (LZBRADepackerSizeModels + 2) * 4
    LZBRADepackerModels = -LZBRADepackerLocalSize
    LZBRADepackerRange = LZBRADepackerModels + (LZBRADepackerSizeModels * 4)
    LZBRADepackerCode = LZBRADepackerRange + 4

    LZBRADepacker:
      push ebp
      mov ebp, esp
      sub esp, LZBRADepackerLocalSize

      push ebx
      push ecx
      push edx
      push esi
      push edi

      cld
      mov esi, ebx

      lodsd
      mov dword ptr [ebp + LZBRADepackerCode], eax

      xor eax,eax
      not eax
      mov dword ptr [ebp + LZBRADepackerRange], eax

      not eax
      mov ah, 0x08 // mov eax, 2048
      mov ecx, LZBRADepackerSizeModels
      lea edi, [ebp + LZBRADepackerModels]
      repe stosd

      mov edi, edx
      push edi

      jmp LZBRADepackerMain

    LZBRADepackerDecodeBit: // result = eax, Move = ecx, ModelIndex = eax
      push ebx
      push edx

      // Bound:=(Range shr 12)*Model[ModelIndex];
      lea edx, [ebp + LZBRADepackerModels + eax * 4]
      mov eax, dword ptr [edx]
      mov ebx, dword ptr [ebp + LZBRADepackerRange]
      shr ebx, 12
      push edx
      imul eax, ebx
      pop edx

      // if Code<Bound then begin
      cmp eax, dword ptr [ebp + LZBRADepackerCode]
      jbe LZBRADepackerDecodeBitYes

      // Range:=Bound;
      mov dword ptr [ebp+LZBRADepackerRange],eax

      // inc(Model[ModelIndex],(4096-Model[ModelIndex]) shr Move);
      xor eax, eax // mov eax, 4096
      mov ah, 0x10
      sub eax, dword ptr [edx]
      shr eax, cl
      add dword ptr [edx], eax

      // result:=0;
      xor eax, eax

      jmp LZBRADepackerCheckRenormalization

    LZBRADepackerDecodeBitYes:

      // dec(Code,Bound);
      sub dword ptr [ebp + LZBRADepackerCode], eax

      // dec(Range,Bound);
      sub dword ptr [ebp + LZBRADepackerRange], eax

      // dec(Model[ModelIndex],Model[ModelIndex] shr Move);
      mov eax, dword ptr [edx]
      shr eax, cl
      sub dword ptr [edx], eax

      // result:=1;
      xor eax, eax
      inc eax
      jmp LZBRADepackerCheckRenormalization

    LZBRADepackerDoRenormalization:
      shl dword ptr [ebp + LZBRADepackerCode], 8
      movzx edx, byte ptr [esi]
      inc esi
      or dword ptr [ebp + LZBRADepackerCode], edx
      shl dword ptr [ebp + LZBRADepackerRange], 8
    LZBRADepackerCheckRenormalization:
      cmp dword ptr [ebp + LZBRADepackerRange], 0x1000000
      jb LZBRADepackerDoRenormalization

      pop edx
      pop ebx

      bt eax, 0 // Carry flay = first LSB bit of eax
      ret

    LZBRADepackerDecodeTree: // result = eax, MaxValue = eax, Move = ecx, ModelIndex = edx
      push edi
      mov edi, eax
      // result:=1;
      xor eax, eax
      inc eax
    LZBRADepackerDecodeTreeLoop:
      // while result<MaxValue do begin
      cmp eax, edi
      jge LZBRADepackerDecodeTreeLoopDone
      // result:=(result shl 1) or DecodeBit(ModelIndex+result,Move);
      push eax
      add eax, edx
      call LZBRADepackerDecodeBit
      pop eax
      adc eax, eax
      jmp LZBRADepackerDecodeTreeLoop
    LZBRADepackerDecodeTreeLoopDone:
      sub eax, edi
      pop edi
      ret

    LZBRADepackerDecodeGamma: // result = eax, ModelIndex = edx
      push ebx
      push edx
      mov edx, dword ptr [esp + 12] // First parameter offset = 2 pushs + call address = (4*2)+2 = 12
      xor eax, eax         // result:=1;
      inc eax
      mov ebx, eax         // Conext:=1;
    LZBRADepackerDecodeGammaLoop:
      push eax
      mov cl,5             // Move:=5;
      lea eax, [edx + ebx] // ModelIndex+Context
      call LZBRADepackerDecodeBit
      adc bl, bl           // Context:=(Context shl 1) or NewBit;
      lea eax, [edx + ebx] // ModelIndex+Context
      call LZBRADepackerDecodeBit
      mov cl, al
      pop eax
      add eax, eax         // Value:=(Value shl 1) or NewBit;
      or al, cl
      add bl, bl
      or bl, cl
      test bl, 2
      jnz LZBRADepackerDecodeGammaLoop
      pop edx
      pop ebx
      ret 4

    LZBRADepackerMain:
      xor ebx, ebx // Last offset
      xor edx, edx // bit 1=LastWasMatch, bit 0=Flag

    LZBRADepackerLoop:

      // if Flag then begin
      test dl, 1
      jz LZBRADepackerLiteral

    LZBRADepackerMatch:
      // if (not LastWasMatch) and (DecodeBit(PrevMatchModel,5)<>0) then begin
      test dl, 2
      jnz LZBRADepackerNormalMatch
      xor eax, eax // PrevMatchModel
      mov al, LZBRADepackerPrevMatchModel
      mov cl, 5
      call LZBRADepackerDecodeBit
      jnc LZBRADepackerNormalMatch
      xor ecx, ecx // Len=0
      jmp LZBRADepackerDoMatch
    LZBRADepackerNormalMatch:

      // Offset:=DecodeGamma(Gamma0Model);
      push LZBRADepackerGamma0Model
      call LZBRADepackerDecodeGamma

      // if Offset=0 then exit;
      test eax, eax
      jz LZBRADepackerWeAreDone

      // dec(Offset,2);
      lea ebx, [eax - 2]

      // Offset:=((Offset shl 4)+DecodeTree(MatchLowModel+(ord(Offset<>0) shl 4),16,5))+1;
      push edx
      test ebx, ebx
      setnz dl
      movzx edx, dl
      shl edx, 4
      add edx, LZBRADepackerMatchLowModel
      mov cl, 5
      xor eax, eax
      mov al, 16
      call LZBRADepackerDecodeTree
      pop edx
      shl ebx, 4
      lea ebx, [eax + ebx + 1]

      // Len:=ord(Offset>=96)+ord(Offset>=2048);
      xor ecx, ecx
      xor eax, eax
      cmp ebx, 2048
      setge al
      add ecx, eax
      cmp ebx, 96
      setge al
      add ecx, eax                                                           

      LZBRADepackerDoMatch:

      or dl,2 // LastWasMatch = true

      // inc(Len,DecodeGamma(Gamma1Model));
      push ecx
      push LZBRADepackerGamma1Model
      call LZBRADepackerDecodeGamma
      pop ecx
      add ecx, eax

      push esi
      mov esi, edi
      sub esi, ebx
      repe movsb
      pop esi

      jmp LZBRADepackerNextFlag

    LZBRADepackerLiteral:
      // byte(pointer(Destination)^):=DecodeTree(LiteralModel,256,4);
      push edx
      xor eax, eax // mov eax, 256
      inc ah
      mov cl, 4
      mov edx, LZBRADepackerLiteralModel
      call LZBRADepackerDecodeTree
      pop edx
      // inc(Destination);
      stosb
      // LastWasMatch:=false;
      and dl,0xfd

    LZBRADepackerNextFlag:
      // Flag:=boolean(byte(DecodeBit(FlagModel+byte(boolean(LastWasMatch)),5)));
      movzx eax, dl
      and al, 1
      mov cl, 5
      call LZBRADepackerDecodeBit
      and dl, 0xfe
      or dl, al

      jmp LZBRADepackerLoop

    LZBRADepackerWeAreDone:

      mov eax, edi
      pop edi
      sub eax, edi

      pop edi
      pop esi
      pop edx
      pop ecx
      pop ebx

      mov esp, ebp
      pop ebp
      ret
          
  }
  
  {
    .bits(32)
    LoadPE64:
      push ebx
      push ecx
      push esi

      // eax = PE Header
      // esi/ebx = MZ-EXE Header
      mov esi, ebx
      mov eax, ebx
      add eax, dword ptr [eax + 0x3c]

      // Clear memory
      push eax
      push edi
      mov ecx, dword ptr [eax + TPE64Header.ImageSize]
      xor eax, eax
       push ecx
        shr ecx, 2
        rep stosd
       pop ecx
       and ecx, 0x3
       rep stosb
      pop edi
      pop eax

      // Copy PE image header
      push esi
      push edi
      mov ecx, dword ptr [eax + TPE64Header.HeaderSize]
       push ecx
        shr ecx, 2
        rep movsd
       pop ecx
       and ecx, 0x3
       rep movsb
      pop edi
      pop esi

      movzx ecx, word ptr [eax + TPE64Header.NumberOfSections]
      movzx ebx, word ptr [eax + TPE64Header.SizeOfOptionalHeader]
      lea ebx, [ebx + eax + TPE64Header.Magic]

      // Copy sections
      LoadPEEXECopySectionLoop:
       push ecx
       push esi
       push edi
       add esi, dword ptr [ebx + TPE64SectionHeader.PhysicalOfs]
       add edi, dword ptr [ebx + TPE64SectionHeader.RVA]
       mov ecx, dword ptr [ebx + TPE64SectionHeader.PhysicalSize]
        push ecx
         shr ecx, 2
         rep movsd
        pop ecx
        and ecx, 0x3
        rep movsb
       pop edi
       pop esi
       pop ecx
       add ebx, TPE64SectionHeader
       dec ecx
      jnz LoadPEEXECopySectionLoop

      mov eax, dword ptr [eax + TPE64Header.AddressOfEntryPoint]

      pop esi
      pop ecx
      pop ebx

      push ebx
      mov ebx, edi
      call LoadPERelocate
      add eax, ebx
      pop ebx

      ret

      // --- Subroutine
      LoadPERelocate:
      pushad
      
      mov edi, ebx
      add edi, dword [edi + 0x3c]

      mov edx, ebx
      sub edx, dword ptr [edi + TPE64Header.BaseOfImage]
      mov dword ptr [edi + TPE64Header.BaseOfImage], ebx

      mov esi, dword ptr [edi + TPE64Header.RelocationRVA]
      test esi, esi
      jz LoadPERelocateDone

      mov ecx, dword ptr [edi + TPE64Header.RelocationSize]
      test ecx, ecx
      jz LoadPERelocateDone

      LoadPERelocateMore:
       mov ebp, dword ptr [ebx + esi + TPE64Relocation.PageRVA]
       mov ecx, dword ptr [ebx + esi + TPE64Relocation.BlockSize]
       test ecx, ecx
       jz LoadPERelocateDone

       sub ecx, TPE64Relocation
       add esi, TPE64Relocation

       LoadPERelocateNext:
        movzx eax, word ptr [ebx + esi]
        mov edi, eax
        and edi, 0xfff
        add edi, ebp
        shr eax, 12

        dec eax
        jz LoadPERelocateHIGH
        dec eax
        jz LoadPERelocateLOW
        dec eax
        jz LoadPERelocateHIGHLOW
        dec eax
        jz LoadPERelocateHIGHADJ
        sub eax, 6
        jz LoadPERelocateDIR64
        jmp LoadPERelocateSkip
         LoadPERelocateHIGH:
          push edx
           shr edx, 16
           add word ptr [ebx + edi], dx
          pop edx
          jmp LoadPERelocateSkip
         LoadPERelocateLOW:
          add word ptr [ebx + edi], dx
          jmp LoadPERelocateSkip
         LoadPERelocateHIGHLOW:
          add dword ptr [ebx + edi], edx
          jmp LoadPERelocateSkip
         LoadPERelocateHIGHADJ:
          add esi, 2
          sub ecx, 2
          mov eax,dword ptr [ebx + edi - 2] // Lo Hi (Little endian)
        // or to be absolute safe:
        // mov ax, word ptr [ebx + edi]
        // shl eax, 16
          mov ax, word ptr [ebx + esi]
          lea eax, [eax + edx + 0x8000]
          shr eax, 16
          mov word ptr [ebx + edi], dx
          jmp LoadPERelocateSkip
         LoadPERelocateDIR64:
          add dword ptr [ebx + edi], edx
          adc dword ptr [ebx + edi + 4], 0
          jmp LoadPERelocateSkip
        LoadPERelocateSkip:

        add esi, 2
        sub ecx, 2
        jnz LoadPERelocateNext
       jmp LoadPERelocateMore

      LoadPERelocateDone:
       clc
      popad
      ret
  }
  
  { // Enable A20 line, if it's not enabled yet  
    .bits(16)
    EnableA20:
      pushad
      
      call CheckA20
      jnz EnableA20Done
      
    EnableA20WithBIOS:           
      mov cx, 16
    EnableA20WithBIOSLoop:           
      mov ax, 0x2401
      int 0x15      
      call CheckA20
      jnz EnableA20Done
      dec cx
      jnz EnableA20WithBIOSLoop

    EnableA20With8042Controller:           
      mov cx, 16
    EnableA20With8042ControllerLoop:           
      cli

      // Disable keyboard
      call EnableA20Wait
      mov al, 0xad
      out 0x64, al

      // Read from input
      call EnableA20Wait
      mov al, 0xd0
      out 0x64, al
    EnableA20WaitLoop:
      in al, 0x64
      test al, 1
      jz EnableA20WaitLoop
      in al, 0x60

      // Write to output
      push eax
      call EnableA20Wait
      mov al, 0xd1
      out 0x64, al
      call EnableA20Wait
      pop eax
      or al, 2
      out 0x60, al

      // Enable keyboard
      call EnableA20Wait
      mov al, 0xae
      out 0x64, al

      call EnableA20Wait
      
      sti
      
      call CheckA20
      jnz EnableA20Done
      dec cx
      jnz EnableA20With8042ControllerLoop

    FastEnableA20:
      mov cx, 16
    FastEnableA20Loop:
      in al, 0x92
      test al, 2
      jnz FastEnableA20Done
      or al, 2
      and al, 0xfe
      out 0x92, al
    FastEnableA20Done:                
      call CheckA20
      jnz EnableA20Done
      dec cx
      jnz FastEnableA20Loop
      
    EnableA20Hang:
      jmp EnableA20Hang
     
    EnableA20Done:
      popad
      ret
  }

  {  
    .bits(16)
    EnableA20Wait:
      in al, 0x64
      test al, 2
      jnz EnableA20Wait
      ret
  }
   
  {
    .bits(16)
    CheckA20:
      pushf
      push ds
      push es
      push di
      push si
   
      cli
   
      xor ax, ax // ax = 0
      mov es, ax
   
      not ax // ax = 0xFFFF
      mov ds, ax
   
      mov di, 0x0500
      mov si, 0x0510
   
      mov al, byte ptr es:[di]
      push ax
   
      mov al, byte ptr ds:[si]
      push ax
   
      mov byte ptr es:[di], 0x00
      mov byte ptr ds:[si], 0xFF
   
      cmp byte ptr es:[di], 0xFF
   
      pop ax
      mov byte ptr ds:[si], al
   
      pop ax
      mov byte ptr es:[di], al
   
      mov ax, 0
      je CheckA20Exit
   
      mov ax, 1
   
    CheckA20Exit:
      pop si
      pop di
      pop es
      pop ds
      popf   
      test ax, ax
      ret           
  }

  { 
    .bits(16)
    CheckLongMode:
      pushad
      pushfd

      pop eax
      mov ecx, eax
      xor eax, 0x200000
      push eax
      popfd

      pushfd
      pop eax
      xor eax, ecx
      shr eax, 21
      and eax, 1
      push ecx
      popfd

      test eax, eax
      jz CheckLongModeNoLongMode

      mov eax, 0x80000000
      cpuid

      cmp eax, 0x80000001
      jb CheckLongModeNoLongMode

      mov eax, 0x80000001
      cpuid
      test edx, 1 << 29
      jz CheckLongModeNoLongMode

      xor eax, eax
      not eax

      jmp CheckLongModeNoLongModeSkip
    
    CheckLongModeNoLongMode: 
      xor eax, eax
      
    CheckLongModeNoLongModeSkip:
      
      test eax, eax
      popad
      ret
  }
  
  { // Enable unreal mode for FS segment Value
    .bits(16)
    EnableUnrealMode:      
      xor ax, ax     
      mov ds, ax              // DS = 0
      mov fs, ax              // FS = 0

      pushad
      
      cli                     // no interrupts
      
      // Disable NMIs
      mov dx, 0x70 
      in al, dx
      or al, 0x80
      out dx, al

      push ds                 // save real mode
      push fs

      lgdt cs:[GDTDescriptor] // load GDT

      mov eax, cr0            // switch to pmode by
      or al,1                 // set pmode bit
      mov cr0, eax

      jmp NoCrash             // tell 386/486 to not crash
      NoCrash:

      mov bx, 0x10            // select descriptor 2
      mov fs, bx              // 0x10 = 10000b

      and al, 0xfe            // back to realmode
      mov cr0, eax            // by toggling bit again

      pop fs                  // get back old segment
      pop ds
      
      // Enable NMIs
      mov dx, 0x70 
      in al, dx
      and al, 0x7f
      out dx, al
      
      sti                     // re-enable interrupts
      
      popad
      
      xor ax,ax
      not ax
      test ax,ax
      
      ret
  }

  { // Get memory map
    .bits(16)
    GetMemoryMap:   
      push bp
      mov bp, sp
      sub sp, 4
      pushad   
      mov ax, MemoryMapAddress >> 4
      mov es, ax
      xor di, di
      xor ebx, ebx                      // ebx must be 0 to start
      mov dword ptr ss:[bp - 4], ebx    // no entries yet
      mov dword ptr cs:[MemorySize + 0], ebx
      mov dword ptr cs:[MemorySize + 4], ebx
      mov edx, 0x0534d4150              // Place "SMAP" into edx
      mov eax, 0xe820
      mov dword ptr es:[di + 20], 1     // force a valid ACPI 3.X entry
      mov ecx, 24                       // ask for 24 bytes
      int 0x15      
      jc GetMemoryMapFailed             // carry set on first call means "unsupported function"
      mov edx, 0x0534d4150              // Some BIOSes apparently trash this Value?
      cmp eax, edx                      // on success, eax must have been reset to "SMAP"
      jne GetMemoryMapFailed
      test ebx, ebx                     // ebx = 0 implies list is only 1 entry long (worthless)
      je GetMemoryMapFailed
      jmp GetMemoryMapJumpIn
    GetMemoryMapLoop:
      mov eax, 0xe820                   // eax, ecx get trashed on every int 0x15 call
      mov dword ptr es:[di + 20], 1     // force a valid ACPI 3.X entry
      mov ecx, 24                       // ask for 24 bytes again
      int 0x15
      jc GetMemoryMapSuccess            // carry set means "end of list already reached"
      mov edx, 0x0534d4150              // repair potentially trashed Value
    GetMemoryMapJumpIn:
      test cx, cx    
      jz GetMemoryMapSkip               // skip any 0 length entries
      cmp cl, 20                        // got a 24 byte ACPI 3.X response?
      jbe GetMemoryMapNotExtended
      test byte es:[di + 20], 1         // if so: is the "ignore this data" bit clear?
      je GetMemoryMapSkip
    GetMemoryMapNotExtended:
      mov ecx, dword ptr es:[di + 8]    // get lower uint32_t of memory region length
      or ecx, dword ptr es:[di + 12]    // "or" it with upper uint32_t to test for zero
      jz GetMemoryMapSkip               // if length uint64_t is 0, skip entry
      mov eax, dword ptr es:[di + 0]
      mov ecx, dword ptr es:[di + 4]
      add eax, dword ptr es:[di + 8]
      adc ecx, dword ptr es:[di + 12]
      cmp dword ptr cs:[MemorySize + 4], ecx
      ja GetMemoryMapNotBigger
      cmp dword ptr cs:[MemorySize + 0], eax
      jae GetMemoryMapNotBigger
      mov dword ptr cs:[MemorySize + 0], eax
      mov dword ptr cs:[MemorySize + 4], ecx
      GetMemoryMapNotBigger:
      mov ecx, dword ptr ss:[bp - 4]
      inc ecx                           // got a good entry: increment count, move to next storage spot 
      mov dword ptr ss:[bp - 4], ecx
      add di, 24
    GetMemoryMapSkip:
      test ebx, ebx                     // if ebx resets to 0, list is complete
      jne  GetMemoryMapLoop
      jmp GetMemoryMapSuccess
    GetMemoryMapFailed:
      xor eax, eax 
      mov dword ptr ss:[bp - 4], eax
    GetMemoryMapSuccess:      
      popad
      mov eax, dword ptr ss:[bp - 4]      
      mov sp, bp
      pop bp      
      test eax, eax
      ret 
  }

  {
    .bits(16)
    ClearScreen:
      push bp
      mov bp, sp
      pushad
      mov ax, 0x0003  // Text mode 
      int 0x10
      mov ax, 0x0600  // Clear the screen
      xor cx, cx      // from (0,0)
      mov dx, 0x184f  // to (24,79)
      mov bh, 0x07    // keep light grey display
      int 0x10
      mov ah, 0x02    // Set cursor position
      xor dx, dx      // at (0, 0)
      mov bh, dh      // page=0
      int 0x10
      popad
      mov sp, bp
      pop bp      
      ret
  }
  
  {
    .bits(16)
    PrintChar:
      pushad
      mov ah, 0x0e      // Write char and attributes at cursor pos
      mov bx, 0x0700    // page=0, attributes is light grey and black
      int 0x10      
      popad
      ret
  }
  
  {
    PrintNullTerminatedString:
      push bp
      mov bp, sp
      pushad
      mov ax, 0x0e00    // Write char and attributes at cursor pos
      mov bx, 0x0700    // page=0, attributes is light grey and black
    PrintNullTerminatedStringLoop:
      lodsb
      or al, al
      jz PrintNullTerminatedStringDone
      int 0x10
      jmp PrintNullTerminatedStringLoop
    PrintNullTerminatedStringDone: 
      popad
      mov sp, bp
      pop bp      
      ret
  }
  
  {
    .bits(16)
    PrintHexChar:
      pushad
      and al, 0x0f
      mov ah, 0x0e    // Write char and attributes at cursor pos
      mov bx, 0x0700    // page=0, attributes is light grey and black
      cmp al, 0xa
      jae PrintHexCharOverTen
        add al, '0'
        jmp PrintHexCharOverTenSkip
      PrintHexCharOverTen:
        add al, 'a' - 0xa
      PrintHexCharOverTenSkip:
      int 0x10
      popad
      ret
  }
  
  {
    .bits(16)
    PrintHexByte:
      pushad
      rol al, 4
      call PrintHexChar     
      rol al, 4
      call PrintHexChar     
      popad
      ret
  }
  
  {
    .bits(16)
    PrintHexWord:
      pushad
      rol ax, 8
      call PrintHexByte
      rol ax, 8
      call PrintHexByte
      popad
      ret
  }
  
  {
    .bits(16)
    PrintHexDWord:
      pushad
      rol eax, 16
      call PrintHexWord
      rol eax, 16
      call PrintHexWord
      popad
      ret
  }
  
  {
   .bits(16)
   PrintDWord:
      pushad
      test eax, eax
      jz PrintDWordZero
      xor ecx, ecx 
      mov ebx, 10 
    PrintDWordFillLoop: 
      xor edx, edx
      div ebx
      inc ecx
      push dx
      test eax, eax 
      jnz PrintDWordFillLoop
    PrintDWordPrintLoop: 
      pop ax 
      call PrintHexChar
      dec ecx 
      jnz PrintDWordPrintLoop
      jmp PrintDWordZeroSkip 
    PrintDWordZero:
      call PrintHexChar
    PrintDWordZeroSkip:
      popad
      ret
  }
  
  {
    .bits(16)
    InitializeFATFileSystem:
      push bp
      mov bp, sp
      pushad
      
      // FATWorkData.SectorSizeBits:=log2(PBootSectorFAT1216(pointer(@BootSector))^.BytesPerSector);
      movzx eax, word ptr cs:[vbpbBytesPerSector]
      mov dword ptr cs:[FATWorkDataBytesPerSector], eax 
      bsf eax, eax
      mov dword ptr cs:[FATWorkDataSectorSizeBits], eax 
      mov ebx, eax
      
      // FATWorkData.ClusterSizeBits:=FATWorkData.SectorSizeBits+integer(log2(PBootSectorFAT1216(pointer(@BootSector))^.SectorsPerCluster));
      movzx eax, byte ptr cs:[vbpbSectorsPerCluster]
      mov dword ptr cs:[FATWorkDataSectorsPerCluster], eax 
      bsf eax, eax
      add eax, ebx
      mov dword ptr cs:[FATWorkDataClusterSizeBits], eax 
  
      /* if PBootSectorFAT1216(pointer(@BootSector))^.TotalSectors<>0 then begin
      **  FATWorkData.NumSectors:=PBootSectorFAT1216(pointer(@BootSector))^.TotalSectors;
      ** end else begin
      **  FATWorkData.NumSectors:=PBootSectorFAT1216(pointer(@BootSector))^.TotalSectorsBig;
      ** end;
      */
      movzx eax, word ptr cs:[vbpbTotalSectors]
      test eax, eax
      jnz InitializeFATFileSystemNoTotalSectorsBig
        mov eax, dword ptr cs:[vbpbTotalSectorsBig]
    InitializeFATFileSystemNoTotalSectorsBig: 
      mov dword ptr cs:[FATWorkDataNumSectors], eax
      
      // FATWorkData.HiddenSectors:=PBootSectorFAT1216(pointer(@BootSector))^.HiddenSectors;
      mov eax, dword ptr cs:[vbpbHiddenSectors]
      mov dword ptr cs:[FATWorkDataHiddenSectors], eax

      // FATWorkData.FATOffset:=PBootSectorFAT1216(pointer(@BootSector))^.ReservedSectors;
      movzx eax, word ptr cs:[vbpbReservedSectors]
      mov dword ptr cs:[FATWorkDataFATOffset], eax
      
      /* if PBootSectorFAT1216(pointer(@BootSector))^.SectorsPerFAT<>0 then begin
      **  FATWorkData.FATLength:=PBootSectorFAT1216(pointer(@BootSector))^.SectorsPerFAT;
      ** end else begin
      **  FATWorkData.FATLength:=PBootSectorFAT32(pointer(@BootSector))^.FAT32SectorsPerFAT;
      ** end;
      */
      movzx eax, word ptr cs:[vbpbSectorsPerFAT]
      test eax, eax
      jnz InitializeFATFileSystemNoFAT32SectorsPerFAT
    InitializeFATFileSystemFAT32SectorsPerFAT:   
      movzx eax, word ptr cs:[vbpb32SectorsPerFAT]
    InitializeFATFileSystemNoFAT32SectorsPerFAT: 
      mov dword ptr cs:[FATWorkDataFATLength], eax
      
      // FATWorkData.RootOffset:=FATWorkData.FATOffset+(PBootSectorFAT1216(pointer(@BootSector))^.NumberOfFATs*FATWorkData.FATLength);
      movzx eax, byte ptr cs:[vbpbNumberOfFATs]
      mul dword ptr cs:[FATWorkDataFATLength]
      add eax, dword ptr cs:[FATWorkDataFATOffset]
      mov dword ptr cs:[FATWorkDataRootOffset], eax
       
      // FATWorkData.RootMax:=sizeof(TFATDirectoryEntry)*PBootSectorFAT1216(pointer(@BootSector))^.RootEntries;
      movzx eax, word ptr cs:[vbpbRootEntries]
      mov ebx, TFATDirectoryEntry
      mul ebx
      mov dword ptr cs:[FATWorkDataRootMax], eax
      
      // FATWorkData.DataOffset:=FATWorkData.RootOffset+((FATWorkData.RootMax-1) shr FATWorkData.SectorSizeBits)+1;
      dec eax
      mov ecx, dword ptr cs:[FATWorkDataSectorSizeBits]
      shr eax, cl
      add eax, dword ptr cs:[FATWorkDataRootOffset]
      inc eax
      mov dword ptr cs:[FATWorkDataDataOffset], eax
  
      // FATWorkData.NumClusters:=2+((FATWorkData.NumSectors-FATWorkData.DataOffset) div PBootSectorFAT1216(pointer(@BootSector))^.SectorsPerCluster);
      mov eax, dword ptr cs:[FATWorkDataNumSectors]
      sub eax, dword ptr cs:[FATWorkDataDataOffset]
      xor edx, edx
      div dword ptr cs:[FATWorkDataSectorsPerCluster]
      add eax, 2
      mov dword ptr cs:[FATWorkDataNumClusters], eax

      // FATWorkData.FilePos:=0;       
      xor eax, eax
      mov dword ptr cs:[FATWorkDataFilePos], eax
      
      cmp word ptr cs:[vbpbSectorsPerFAT],0
      je DetectFATFileSystemTypeFAT32
    DetectFATFileSystemTypeFAT12orFAT16:
     
      /* if FATWorkData.RootMax=0 then begin
      **  exit;
      ** end;      
      */
      mov eax, dword ptr cs:[FATWorkDataRootMax]
      test eax, eax
      jz DetectFATFileSystemTypeUnknown
      
      // FATWorkData.RootCluster:=-1;
      xor eax, eax
      not eax
      mov dword ptr cs:[FATWorkDataRootCluster], eax
      
      /* if FATWorkData.NumClusters>4087 then begin
      **  FATWorkData.FATSize:=16;
      **  FATWorkData.ClusterEOFMarker:=$fff8;
      ** end else begin
      **  FATWorkData.FATSize:=12;
      **  FATWorkData.ClusterEOFMarker:=$ff8;
      ** end;
      */
      mov eax, dword ptr cs:[FATWorkDataNumClusters]
      cmp eax, 4087
      ja DetectFATFileSystemTypeFAT16
    DetectFATFileSystemTypeFAT12:
      mov eax, 12
      mov ebx, 0x00000ff8
      jmp DetectFATFileSystemTypeFAT16Skip  
    DetectFATFileSystemTypeFAT16:  
      mov eax, 16
      mov ebx, 0x0000fff8
    DetectFATFileSystemTypeFAT16Skip:  
    
      movzx ecx, byte ptr cs:[vOfsDriveNumber]
      jmp DetectFATFileSystemTypeDone

    DetectFATFileSystemTypeFAT32:    
     
      mov ax, word ptr cs:[vbpbRootEntries]
      test ax, ax
      jnz DetectFATFileSystemTypeUnknown       
      
      movzx eax, word ptr cs:[vbpb32Flags]
      test eax, 0x0080
      jnz DetectFATFileSystemTypeFAT32FATMirroringEnabled
    DetectFATFileSystemTypeFAT32FATMirroringDisabled:
      // FAT mirroring is disabled, get active FAT

      // ActiveFAT:=PBootSectorFAT32(pointer(@BootSector))^.FAT32Flags and $f;
      and eax, 0xf

      // if ActiveFAT>=PBootSectorFAT32(pointer(@BootSector))^.NumberOfFATs then begin
      //  exit;
      // end;
      cmp al, byte ptr cs:[vbpbNumberOfFATs]
      jae DetectFATFileSystemTypeUnknown

      // inc(FATWorkData.FATOffset,ActiveFAT*FATWorkData.FATLength);
      mul dword ptr cs:[FATWorkDataFATLength]
      add dword ptr cs:[FATWorkDataFATOffset], eax            
      
    DetectFATFileSystemTypeFAT32FATMirroringEnabled:
    
      // FATWorkData.RootCluster:=PBootSectorFAT32(pointer(@BootSector))^.FAT32RootCluster;
      mov eax, dword ptr cs:[vbpb32RootCluster]
      mov dword ptr cs:[FATWorkDataRootCluster], eax

      mov eax, 32
      mov ebx, 0xffffff8
      movzx ecx, byte ptr cs:[vOfs32DriveNumber]
      jmp DetectFATFileSystemTypeDone

    DetectFATFileSystemTypeUnknown:
      xor eax, eax
      xor ebx, ebx
      xor ecx, ecx
        
    DetectFATFileSystemTypeDone:
      mov dword ptr cs:[FATWorkDataFATSize], eax
      mov dword ptr cs:[FATWorkDataClusterEOFMarker], ebx      
      mov dword ptr cs:[FATWorkDriveNumber], ecx
     
      test eax, eax
      jz DetectFATFileSystemTypeCheckFail
     
      push eax
      push ds
      push es
      mov ax, BufferSegment
      mov es, ax
      xor di, di
      mov eax, dword ptr cs:[FATWorkDataFATOffset]
      mov ecx, 1
      call ReadSector
      mov ecx, dword ptr es:[0]
      pop es
      pop ds
      or ecx,0x08
      pop eax
      
      cmp eax,12
      je DetectFATFileSystemTypeCheckFAT12
      cmp eax,16
      je DetectFATFileSystemTypeCheckFAT16
      cmp eax,32
      je DetectFATFileSystemTypeCheckFAT32
      jmp DetectFATFileSystemTypeCheckFail
    DetectFATFileSystemTypeCheckFAT12:        
      movzx ebx, byte ptr cs:[vbpbMedia]
      or ebx, 0x0f08 
      and ecx, 0x0fff
      cmp ebx, ecx
      jne DetectFATFileSystemTypeCheckFail
      jmp DetectFATFileSystemTypeCheckDone
    DetectFATFileSystemTypeCheckFAT16:  
      movzx ebx, byte ptr cs:[vbpbMedia]
      or ebx, 0xff08 
      and ecx, 0xffff
      cmp ebx, ecx
      jne DetectFATFileSystemTypeCheckFail
      jmp DetectFATFileSystemTypeCheckDone
    DetectFATFileSystemTypeCheckFAT32:  
      movzx ebx, byte ptr cs:[vbpbMedia]
      or ebx, 0x0fffff08 
      and ecx, 0x0fffffff
      cmp ebx, ecx
      jne DetectFATFileSystemTypeCheckFail
      jmp DetectFATFileSystemTypeCheckDone
     
    DetectFATFileSystemTypeCheckFail:  
      xor eax, eax
      mov dword ptr cs:[FATWorkDataFATSize], eax
      mov dword ptr cs:[FATWorkDataClusterEOFMarker], eax      
      mov dword ptr cs:[FATWorkDriveNumber], eax
    DetectFATFileSystemTypeCheckDone: 
      popad
      mov sp, bp
      pop bp      
      mov eax, dword ptr cs:[FATWorkDriveNumber]
      mov dword ptr cs:[BootInfoBootDevice], eax
      cmp dword ptr cs:[FATWorkDataFATSize], 12
      jne DoNotReadFullFAT
    ReadFullFAT:
      // Load the entrie FAT (maximum 6 kilobytes for FAT12)
      pushad
      mov eax,dword ptr cs:[FATWorkDataFATOffset]
      mov ecx,dword ptr cs:[FATWorkDataFATLength]
      push word FATBufferSegment
      pop es
      call ReadSector
      popad      
    DoNotReadFullFAT:  
      mov eax, dword ptr cs:[FATWorkDataFATSize]
      test eax, eax
      ret
    
  }
  
  {    
    .bits(16)
    FindFile:

      pushad

      ReadFATRootDirectory:
      cmp word ptr cs:[FATWorkDataFATSize], 32
      je FindFileFAT32
    ReadFATRootDirectoryFAT12FAT16:
      
      push word BufferSegment
      pop es
      
      mov eax, dword ptr cs:[FATWorkDataRootMax] 
      mov ecx, dword ptr cs:[FATWorkDataBytesPerSector]
      add eax, ecx
      dec eax
      xor edx, edx
      div ecx
      mov ecx, eax
      
      mov eax, dword ptr cs:[FATWorkDataRootOffset]
     
      call ReadSector
              
      push word BufferSegment
      pop es
      xor di, di
      
      push cs
      pop ds

      cmp word ptr cs:[FATWorkDataFATSize], 32
      je FindFileFAT32
      
    FindFileFAT12FAT16: 
      mov si, offset KernelFileName
      mov dx, word ptr cs:[vbpbRootEntries] 
    FindNextFileFAT12FAT16:
   
/*/  push di
      mov al,byte ptr es:[di]
      test al,al
      jz FindNextFileFAT12FAT16PrintSkip
      mov cx, 11
    FindNextFileFAT12FAT16PrintLoop: 
      mov al,byte ptr es:[di]
      inc di      
      call PrintChar    
      loop FindNextFileFAT12FAT16PrintLoop
    FindNextFileFAT12FAT16PrintSkip: 
      pop di/**/
      
      mov cx, 11
      pusha
      rep cmpsb
      popa
      je short FindFileFoundFAT1216
      add di, TFATDirectoryEntry
      dec dx
      jnz short FindNextFileFAT12FAT16
      jmp FindFileFail
    FindFileFoundFAT1216:
      push word ptr es:[di + TFATDirectoryEntry.ClusterHi32]
      push word ptr es:[di + TFATDirectoryEntry.Cluster]
      pop dword ptr cs:[FATWorkFileCluster]
      jmp FindFileDone  
    
    FindFileFAT32:   
      push word BufferSegment
      pop es
      mov esi, dword ptr cs:[FATWorkDataRootCluster]    
    FindFileMainFAT32:
      call ReadCluster
      shr ebx, 5
      push esi
      xor di, di
    FindFileNextFAT32:
      mov si, offset KernelFileName
      mov cx, 11
      pusha
      rep cs: cmpsb
      popa
      je short FindFileFoundFAT32     
      add di, byte 32
      dec bx
      jnz short FindFileNextFAT32
      pop esi
      cmp esi, 0xffffff8
      jb short FindFileMainFAT32
      jmp FindFileFail
      FindFileFoundFAT32:        
      push word ptr es:[di + TFATDirectoryEntry.ClusterHi32]
      push word ptr es:[di + TFATDirectoryEntry.Cluster]
      pop dword ptr cs:[FATWorkFileCluster]
     jmp FindFileDone
      
    FindFileFail:
      xor eax, eax
      mov dword ptr cs:[FATWorkFileCluster], eax
      
    FindFileDone:
      popad
      mov eax, dword ptr cs:[FATWorkFileCluster]
      test eax, eax
      ret
  
  }
  
  {
    .bits(16)
    LoadKernel:
      pushad
      
      mov ebp, KernelLoadAddress
      
      mov esi, dword ptr cs:[FATWorkFileCluster] 

      push word BufferSegment
      pop es
      
    LoadKernelLoop:
            
      push ebp
      call ReadCluster
      jc short LoadKernelNextIsDone
      xor eax, eax  
      not eax       
      jmp LoadKernelNextIsNotDone
    LoadKernelNextIsDone:
      xor eax, eax  
    LoadKernelNextIsNotDone:            
      pop ebp
      
      xor edi, edi
    LoadKernelCopyLoop:
      mov dl, byte ptr es:[di]
      mov byte ptr fs:[ebp], dl
      inc edi
      inc ebp
      dec ebx   
      jnz LoadKernelCopyLoop
     
      test eax, eax
      jnz short LoadKernelLoop
    LoadKernelDone:      
      cmp ebp, KernelLoadAddress      
      popad
      ret
  }
  
  {
    .bits(16)
    ReadSector:
      
      pushad

      movzx dx, byte ptr cs:[FATWorkDriveNumber]
      test dl, 0x80
      jnz ReadSectorNoLBA 
      
    ReadSectorTestLBA:
      mov ax,0x4100
      mov bx,0x55aa
      int 0x13
      jc ReadSectorNoLBA
      
      cmp bx,0xaa55
      je ReadSectorLBA
            
    ReadSectorNoLBA:
      popad
      
      push di

      xor bx, bx
      mov edx, eax
      shr edx, 16

    ReadSectorNoLBANext:
      mov di, 5

    ReadSectorNoLBAMore:
      pushad

      add ax, word ptr cs:[FATWorkDataHiddenSectors]
      adc dx, word ptr cs:[FATWorkDataHiddenSectors + 2]
      
      xor cx, cx

      xchg ax, cx
      xchg ax, dx

      div word ptr cs:[vbpbSectorsPerTrack]

      xchg ax, cx

      div word ptr cs:[vbpbSectorsPerTrack]

      xchg dx, cx
      inc cx

      div word ptr cs:[vbpbHeadsPerCylinder]

      mov ch, al
      shl ah, 6
      or cl, ah

      mov dh, dl

      mov dl, byte ptr cs:[FATWorkDriveNumber]

      mov ax, 0x201
      int 0x13
      jnc ReadSectorNoLBADone

      mov ah, 0
      int 0x13

      popad

      dec di
      jnz ReadSectorNoLBAMore
      jmp Hang
    ReadSectorNoLBADone:
      popad
      
      add bx, word ptr cs:[FATWorkDataBytesPerSector]
      inc ax
      jnz ReadSectorNoLBASkip
      inc dx
    ReadSectorNoLBASkip:
      dec cx
      jnz ReadSectorNoLBANext
      
      pop di
      ret
      
    ReadSectorLBA:
      popad 
      
      push edx
      push esi
      push ds

      xor edx, edx
      add eax, dword ptr cs:[FATWorkDataHiddenSectors]
      adc edx, 0
      
      push edx       // LBA Hi
      push eax       // LBA Lo
      push es        // Buffer Segment
      push word 0    // Buffer Offset
      push cx        // Sector read count
      push word 0x10 // Record size
      
      mov eax, dword ptr cs:[FATWorkDataBytesPerSector]
      movzx ecx, cx
      mul ecx
      mov ebx, eax

      mov ah, 0x42
      mov dl, byte ptr cs:[FATWorkDriveNumber]
      
      push ss
      pop ds
      mov si, sp

      int 0x13
      jc Hang

      add esp,16
      
      pop ds
      pop esi
      pop edx
      ret
  }
  
  { // Read cluster procedure
    .bits(16)
    ReadCluster:
      lea eax, [esi - 2]
      
      mov ecx, dword ptr cs:[FATWorkDataSectorsPerCluster]
      mul ecx

      add eax, dword ptr cs:[FATWorkDataDataOffset]
            
      call ReadSector
      
      mov edx, dword ptr cs:[FATWorkDataFATSize]
      cmp edx, 32
      je ReadClusterFAT32
      cmp edx, 16
      je ReadClusterFAT16

     ReadClusterFAT12:
     
      // OldCluster:=CurrentCluster;
      mov eax, esi
     
      // (esi * 3) / 2
      imul esi, eax, 3
      shr esi, 1

      // Get next cluster
      push ds
      push word FATBufferSegment
      pop ds
      movzx esi, word ptr ds:[si]
      pop ds

      test eax, 1
      jz short ReadClusterEvenFAT12
      shr esi, 4
      ReadClusterEvenFAT12:
      
      // EOF Test
      and esi, 0xfff
      cmp esi, 0xff8
      cmc    
      ret
      
    ReadClusterFAT16:
     
      mov eax, 2
      mul esi
      div dword ptr cs:[FATWorkDataBytesPerSector]
      mov esi, edx

      push es

      push word FATBufferSegment
      pop es

      movzx ecx, word ptr cs:[vbpbReservedSectors]
      add eax, ecx      
      
      mov ecx, 1
      
      call ReadSector

      // Get next cluster
      movzx esi, word ptr es:[si]

      pop es

      cmp esi,0xfff8
      cmc      
      ret
      
    ReadClusterFAT32:

      mov eax,dword ptr cs:[FATWorkDataBytesPerSector]
      xchg eax, esi
      shl eax, 2
      div esi

      push dx

      movzx esi, word ptr cs:[vbpbReservedSectors]
      add esi, eax

      movzx eax, word ptr cs:[vbpb32Flags]
      and al, 0xf
      mul dword ptr cs:[vbpb32SectorsPerFAT]

      add eax, esi

      pop si

      push es
      push ebx

      push word FATBufferSegment
      pop es

      mov ecx, 1

      call ReadSector

      mov esi, dword ptr es:[si]

      pop ebx
      pop es

      and esi, 0xfffffff
      cmp esi, 0xffffff8
      cmc
      ret
  }

  {
    MemorySize:
      dq 0
  }
  
  {
    .align(16)
    BootInfo:
      dd 0x00000042       // Flags
      resd 2
    BootInfoBootDevice:
      dd 0
      resd 7
    BootInfoMemoryMapLength:
      dd 0
    BootInfoMemoryMapAddress:
      dd MemoryMapAddress
      resd 11
  }
  
  {
    .align(16)
    GDTDescriptor:
      dw ((offset GDTTableEnd) - (offset GDTTable)) - 1   // last byte in table
      dd (CodeSegment << 4) + (offset GDTTable)           // start of table
    GDTTable:
      GDTTableEntry0:
        GDTEntry 0x0000, 0x0000, 0x00, 000000000b, 000000000b, 0x00   // entry 0 is always unused
      GDTTableEntry1: // Code, Present, Ring 0, Code, Non-conforming, Readable, Page-granular
        GDTEntry 0xffff, 0x0000, 0x00, 010011010b, 011001111b, 0x00
      GDTTableEntry2: // Data, Present, Ring 0, Data, Expand-up, Writable, Page-granular
        GDTEntry 0xffff, 0x0000, 0x00, 010010010b, 011001111b, 0x00
      GDTTableEntry3: // 64-bit code 
        GDTEntry 0xffff, 0x0000, 0x00, 010011011b, 010101111b, 0x00
    .comment{
      GDTTableEntry4: // Interrupts
        GDTEntry 0xffff, 0x1000, 0x00, 010011110b, 011001111b, 0x00
    } 
    GDTTableEnd:    
  }
  
  {
    .align(16)
    GDT64Descriptor:
      dw ((offset GDT64TableEnd) - (offset GDT64Table)) - 1   // last byte in table
      dd (CodeSegment << 4) + (offset GDT64Table)             // start of table
    GDT64Table:
      GDT64TableEntry0:
        GDTEntry 0x0000, 0x0000, 0x00, 000000000b, 000000000b, 0x00   // entry 0 is always unused
      GDT64TableEntry1: // Ring0 code 
        GDTEntry 0x0000, 0x0000, 0x00, 010011010b, 000100000b, 0x00
      GDT64TableEntry2: // Ring0 data
        GDTEntry 0x0000, 0x0000, 0x00, 010010010b, 000100000b, 0x00
      GDT64TableEntry3: // Ring3 code 
        GDTEntry 0x0000, 0x0000, 0x00, 011111010b, 000100000b, 0x00
      GDT64TableEntry4: // Ring3 data
        GDTEntry 0x0000, 0x0000, 0x00, 011110010b, 000100000b, 0x00
    GDT64TableEnd:    
  }
  
  {
    .align(16)
    IDTDescriptor:
    IDTLength:
      dw 0
    IDTBase:
      dd 0
  }
  
  {
    KernelFileName: db "KERNEL  BIN"
  }                    
 
  .comment{ // just for as reference for the procedural BuildPagingTable routine above, therefore commented out
    .align(4096)
    PagingTableAddress:
    PagingTablePML4T: // Maps 256 TB
      dq (offset PagingTablePDPT) | 000000000011b    // Present, R/W, Supervisor
      //resq 511
      dq 511 dup (0)
    PagingTablePDPT: // Maps 512 GB
      dq (offset PagingTablePDT) | 000000000011b    // Present, R/W, Supervisor
      //resq 511
      dq 511 dup (0)
    PagingTablePDT: // Maps 1 GB
      dq (offset PagingTablePT) | 000000000011b     // Present, R/W, Supervisor
      //resq 511
      dq 511 dup (0)
    PagingTablePT: // Maps 2 MB (4 KB per entry)
    !if(1){
      !script{
         // Feel the power of ECMAScript/JavaScript :-)
         for(var i = 0; i < 512; i++){ 
            Assembler.parse("dq " + (i * 4096) + " | 000000000011b"); // Present, R/W, Supervisor
         }
      }
    }else{
      !repeat(512){
         .local FreezedCounter
         !set FreezedCounter = __COUNTER__
         dq (FreezedCounter * 4096) | 000000000011b      // Present, R/W, Supervisor
      }
    }
  }
  
}