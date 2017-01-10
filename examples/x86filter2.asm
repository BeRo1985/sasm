.target(bin); 
.startoffset(0);
.cpu(all);

NBUFFERS = 20;

.struct(dataArea){
  buffer dword(NBUFFERS);
  offset dword(1)
  lastJump dword(1)
  nextFunc dword(1)
  jumpTable dword(1)
  codebuf byte(1)
  modrmbuf byte(1)
  _pad byte(2)
  funcTable dword(256)
}

fNM=0x0;      // no ModRM
fAM=0x1;      // no ModRM, "address mode" (jumps or direct addresses)
fMR=0x2;      // ModRM present
fMO=0x3;  // ModRM present, includes extra bits for opcode
fMODE=0x3;    // bitmask for mode

fNI=0x0;      // no immediate
fBI=0x4;      // byte immediate
fDI=0x8;      // dword immediate
fWI=0xc;      // word immediate
fTYPE=0xc;    // type mask

fAD=0x0;      // absolute address
fBR=0x4;      // byte relative jump target
fDR=0xc;      // dword relative jump target

fERR=0x0;     // denotes invalid opcodes   

.code{
  .bits(32)

  DisUnfilter:
          sub           esp, dataArea 
          mov           ebp, esp
          
          mov           ebx, edi
          sub           ebx, byte 4
          mov           [ebp+dataArea.offset], ebx
          
          xor           eax, eax
          mov           [ebp+dataArea.lastJump], eax
          inc           eax
          mov           [ebp+dataArea.nextFunc], eax
          mov           [ebp+dataArea.funcTable], eax
          neg           eax
          mov           [ebp+dataArea.jumpTable], eax
          
          lea           ebx, [esi+NBUFFERS*4]
          xor           ecx, ecx
          
  @init:  lodsd
          mov           [ebp+dataArea.Buffer+ecx*4], ebx
          add           ebx, eax
          inc           ecx
          cmp           cl, NBUFFERS
          jne           @init
          
          mov           esi, [ebp+dataArea.Buffer+1*4]
          xchg          esi, [ebp+dataArea.Buffer]
          
  @main:  cmp           esi, [ebp+dataArea.Buffer]
          jne           @chkjt // @gotins

          add           esp, dataArea 
          jmp           DefilterDone
          
  @chkjt: cmp           edi, [ebp+dataArea.jumpTable]
          jb            @gotins
          jne           @jtclr
          
          xchg          esi, [ebp+dataArea.Buffer+15*4]
          lodsd
          xchg          eax, ecx
          rep           movsd
          xchg          esi, [ebp+dataArea.Buffer+15*4]
          
  @jtclr: or            dword [ebp+dataArea.jumpTable], byte -1
          jmp           short @main
          
  @gotins:
          xor           eax, eax
          cmp           [ebp+dataArea.nextFunc], eax
          lodsb
          je            @testes
          
          cmp           al, 0xcc // int3 (padding used by vc)
          je            @testes

          lea           ecx, [edi-4]
          sub           ecx, [ebp+dataArea.offset]
          
          mov           ebx, [ebp+dataArea.funcTable]
          mov           [ebp+dataArea.funcTable+ebx*4], ecx
  @incm:  inc           byte [ebp+dataArea.funcTable]
          jz            @incm
          
          mov           byte [ebp+dataArea.nextFunc], 0
          
  @testes:
          cmp           al, 0xce // escape
          jne           @noesc
          
          movsb
          jmp           @main
          
  @noesc: stosb

          xor           edx, edx
          cmp           al, 0x66 // operand size prefix
          jne           @nopfx

          mov           dh, 1        
          lodsb
          stosb
          
  @nopfx: mov           [ebp+dataArea.codebuf], al
          mov           bl, al
          cmp           bl, 0xcc
          je            @isret
          sub           bl, 0xc2
          cmp           bl, 1
          ja            @noret
          
  @isret: mov           byte [ebp+dataArea.nextFunc], 1 // inc?
          
  @noret: 
          call          @PICCall
  @PICCall:          
          pop           ebx
          add           ebx, (offset Tables) - (offset @PICCall)
          cmp           al, 0x0f // two-byte opcode
          jne           @notwo
          
          lodsb
          stosb
          mov           ah, 1
          
  @notwo: shr           eax, 1                      // get flags
          xlatb
          jnc           @flagok
          shr           al, 4
  @flagok:
          and           al, 0xf
          mov           cl, al
          
          test          cl, fMR                     // mod/rm follows?
          jz            near @nomdrm
          
          lodsb
          stosb
          mov           [ebp+dataArea.modrmbuf], al
          mov           ch, al
          
          mov           al, cl
          and           al, fMODE
          cmp           al, fMO
          jne           @noxtra
          
          mov           cl, fMR|fNI
          test          ch, 0x38
          jnz           @noxtra
          mov           bl, [edi-2]
          test          bl, 0x08
          jnz           @noxtra
          add           cl, fBI
          test          bl, 0x01
          jz            @noxtra
          add           cl, fDI-fBI
          
  @noxtra:
          and           ch, 0xc7
          cmp           ch, 0xc4
          je            @nosib
          mov           al, ch
          and           al, 0x07
          cmp           al, 0x04
          jne           @nosib
          
          xchg          esi, [ebp+dataArea.Buffer+19*4]
          movsb
          xchg          esi, [ebp+dataArea.Buffer+19*4]
          
  @nosib: mov           dl, ch
          and           dl, 0xc0
          cmp           dl, 0x40
          jne           @nodis8
          
          movzx         ebx, ch
          and           bl, 0x07
          
          xchg          esi, [ebp+dataArea.Buffer+1*4+ebx*4]
          movsb
          xchg          esi, [ebp+dataArea.Buffer+1*4+ebx*4]
          
  @nodis8:
          cmp           dl, 0x80
          je            @dis32
          cmp           ch, 0x05
          je            @dis32
          test          dl, dl
          jnz           @nomdrm
          mov           al, [edi-1]
          and           al, 0x07
          cmp           al, 0x05
          jne           @nomdrm
          
  @dis32: xor           ebx, ebx
          cmp           ch, 5
          jne           @nomr5
          inc           ebx
  @nomr5: xchg          esi, [ebp+dataArea.Buffer+13*4+ebx*4]
          lodsd
          xchg          esi, [ebp+dataArea.Buffer+13*4+ebx*4]
          bswap         eax
          stosd
          
          cmp           word [ebp+dataArea.codebuf], 0x24ff
          jne           @nomdrm
          mov           ebx, [ebp+dataArea.jumpTable]
          cmp           eax, ebx
          jae           @nomdrm
          mov           [ebp+dataArea.jumpTable], eax

  @nomdrm:
          mov           al, cl
          and           al, fMODE
          cmp           al, fAM
          jne           near @noaddr
          
          shr           cl, 2
          jnz           @noad
          
          xchg          esi, [ebp+dataArea.Buffer+15*4]
          movsd
          xchg          esi, [ebp+dataArea.Buffer+15*4]
          jmp           @main
          
  @noad:  dec           cl
          jnz           @dwdrl
          
          xchg          esi, [ebp+dataArea.Buffer+9*4]
          movsb
          xchg          esi, [ebp+dataArea.Buffer+9*4]        
          jmp           @main
          
  @dwdrl: xor           ebx, ebx
          cmp           byte [edi-1], 0xe8
          je            @dwcal
          
          xchg          esi, [ebp+dataArea.Buffer+17*4]
          lodsd
          xchg          esi, [ebp+dataArea.Buffer+17*4]
          
          shr           eax, 1
          jnc           @jmpnc
          not           eax
          
  @jmpnc: add           eax, [ebp+dataArea.lastJump]
          mov           [ebp+dataArea.lastJump], eax
          jmp           short @storad
          
  @dwcal: xor           eax, eax
          xchg          esi, [ebp+dataArea.Buffer+16*4]
          lodsb
          xchg          esi, [ebp+dataArea.Buffer+16*4]
          test          al, al
          jz            @dcesc
          
          mov           eax, [ebp+dataArea.funcTable+eax*4]
          jmp           short @storad
          
  @dcesc: xchg          esi, [ebp+dataArea.Buffer+18*4]
          lodsd
          xchg          esi, [ebp+dataArea.Buffer+18*4]

          mov           ebx, [ebp+dataArea.funcTable]
          mov           [ebp+dataArea.funcTable+ebx*4], eax
  @dcinc: inc           byte [ebp+dataArea.funcTable]
          jz            @dcinc

  @storad:
          sub           eax, edi
          add           eax, [ebp+dataArea.offset]
          stosd
          jmp           @main
          
  @noaddr:
          shr           cl, 2
          jz            near @main
          
          dec           cl
          jnz           @dwow
          
          xchg          esi, [ebp+dataArea.Buffer+10*4]
          movsb
          xchg          esi, [ebp+dataArea.Buffer+10*4]
          jmp           @main
          
  @dwow:  dec           cl
          jnz           @word
          test          dh, dh
          jnz           @word
          
          xchg          esi, [ebp+dataArea.Buffer+12*4]
          movsd
          xchg          esi, [ebp+dataArea.Buffer+12*4]
          jmp           @main
          
  @word:  xchg          esi, [ebp+dataArea.Buffer+11*4]
          movsw
          xchg          esi, [ebp+dataArea.Buffer+11*4]
          jmp           @main
          
  !script{

    var fNM = 0x0;      // no ModRM
    var fAM = 0x1;      // no ModRM, "address mode" (jumps | direct addresses)
    var fMR = 0x2;      // ModRM present
    var fMO = 0x3;  // ModRM present, includes extra bits for opcode
    var fMODE = 0x3;    // bitmask for mode

    // no ModRM: size of immediate operand
    var fNI = 0x0;      // no immediate
    var fBI = 0x4;      // byte immediate
    var fDI = 0x8;      // dword immediate
    var fWI = 0xc;      // word immediate
    var fTYPE = 0xc;    // type mask

    // address mode: type of address operand
    var fAD = 0x0;      // absolute address
    var fBR = 0x4;      // byte relative jump target
    var fDR = 0xc;      // dword relative jump target

    // others
    var fERR = 0x9;     // denotes invalid opcodes      

    // 1-byte opcodes  0        1       2       3       4       5       6       7       8       9       a       b       c       d       e       f 
    var Table1 = [  fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fNM|fBI,fNM|fDI,fNM|fNI,fNM|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fNM|fBI,fNM|fDI,fNM|fNI,fNM|fNI,  // 0
                    fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fNM|fBI,fNM|fDI,fNM|fNI,fNM|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fNM|fBI,fNM|fDI,fNM|fNI,fNM|fNI,  // 1
                    fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fNM|fBI,fNM|fDI,fNM|fNI,fNM|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fNM|fBI,fNM|fDI,fNM|fNI,fNM|fNI,  // 2
                    fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fNM|fBI,fNM|fDI,fNM|fNI,fNM|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fNM|fBI,fNM|fDI,fNM|fNI,fNM|fNI,  // 3
                    fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,  // 4
                    fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,  // 5
                    fNM|fNI,fNM|fNI,fMR|fNI,fMR|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fDI,fMR|fDI,fNM|fBI,fMR|fBI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,  // 6
                    fAM|fBR,fAM|fBR,fAM|fBR,fAM|fBR,fAM|fBR,fAM|fBR,fAM|fBR,fAM|fBR,fAM|fBR,fAM|fBR,fAM|fBR,fAM|fBR,fAM|fBR,fAM|fBR,fAM|fBR,fAM|fBR,  // 7
                    fMR|fBI,fMR|fDI,fMR|fBI,fMR|fBI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,  // 8
                    fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fERR   ,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,  // 9
                    fAM|fAD,fAM|fAD,fAM|fAD,fAM|fAD,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fBI,fNM|fDI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,  // a
                    fNM|fBI,fNM|fBI,fNM|fBI,fNM|fBI,fNM|fBI,fNM|fBI,fNM|fBI,fNM|fBI,fNM|fDI,fNM|fDI,fNM|fDI,fNM|fDI,fNM|fDI,fNM|fDI,fNM|fDI,fNM|fDI,  // b
                    fMR|fBI,fMR|fBI,fNM|fWI,fNM|fNI,fMR|fNI,fMR|fNI,fMR|fBI,fMR|fDI,fERR   ,fNM|fNI,fNM|fWI,fNM|fNI,fNM|fNI,fNM|fBI,fERR   ,fNM|fNI,  // c
                    fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fNM|fBI,fNM|fBI,fNM|fNI,fNM|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,  // d
                    fAM|fBR,fAM|fBR,fAM|fBR,fAM|fBR,fNM|fBI,fNM|fBI,fNM|fBI,fNM|fBI,fAM|fDR,fAM|fDR,fAM|fAD,fAM|fBR,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,  // e
                    fNM|fNI,fERR   ,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fMO|fNI,fMO|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fMO|fNI,fMO|fNI]; // f

    // 2-byte opcodes  0       1       2       3       4       5       6       7       8       9       a       b       c       d       e       f
    var Table2 = [  fERR   ,fERR   ,fERR   ,fERR   ,fERR   ,fERR   ,fERR   ,fERR   ,fERR   ,fERR   ,fERR   ,fERR   ,fERR   ,fERR   ,fERR   ,fERR   ,  // 0
                    fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fERR   ,fERR   ,fERR   ,fERR   ,fERR   ,fERR   ,fERR   ,fERR   ,  // 1
                    fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fERR   ,fERR   ,fERR   ,fERR   ,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,  // 2
                    fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fERR   ,fERR   ,fERR   ,fERR   ,fERR   ,fERR   ,fERR   ,fERR   ,fERR   ,fERR   ,fERR   ,fERR   ,  // 3
                    fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,  // 4
                    fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,  // 5
                    fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,  // 6
                    fMR|fBI,fMR|fBI,fMR|fBI,fMR|fBI,fMR|fNI,fMR|fNI,fMR|fNI,fNM|fNI,fERR   ,fERR   ,fERR   ,fERR   ,fERR   ,fERR   ,fMR|fNI,fMR|fNI,  // 7
                    fAM|fDR,fAM|fDR,fAM|fDR,fAM|fDR,fAM|fDR,fAM|fDR,fAM|fDR,fAM|fDR,fAM|fDR,fAM|fDR,fAM|fDR,fAM|fDR,fAM|fDR,fAM|fDR,fAM|fDR,fAM|fDR,  // 8
                    fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,  // 9
                    fNM|fNI,fNM|fNI,fNM|fNI,fMR|fNI,fMR|fBI,fMR|fNI,fMR|fNI,fMR|fNI,fERR   ,fERR   ,fERR   ,fMR|fNI,fMR|fBI,fMR|fNI,fERR   ,fMR|fNI,  // a
                    fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fERR   ,fERR   ,fERR   ,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,  // b
                    fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,fNM|fNI,  // c
                    fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,  // d
                    fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,  // e
                    fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fMR|fNI,fERR   ]; // f
                  
    // escape opcodes using ModRM byte to get more variants
                  //  0       1           2         3         4         5         6         7
    var TableX = [fMR | fBI,fERR     ,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI, // escapes for 0xf6
                  fMR | fDI,fERR     ,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI, // escapes for 0xf7
                  fMR | fNI,fMR | fNI,fERR     ,fERR     ,fERR     ,fERR     ,fERR     ,fERR     , // escapes for 0xfe
                  fMR | fNI,fMR | fNI,fMR | fNI,fERR     ,fMR | fNI,fERR     ,fMR | fNI,fERR];     // escapes for 0xff
                                                                                           
    var Tables = new Array(256);
     
    function CombineTable1AndTable2(){
      for(var i = 0; i < 256; i++){
        var j = (i & 127) << 1; 
        var v = (i < 128) ? (Table1[j] | (Table1[j + 1] << 4)) : (Table2[j] | (Table2[j + 1] << 4));
        if((v & 0xf) == fERR){
          v &= 0xf0; 
        }
        if((v >> 4) == fERR){
          v &= 0x0f; 
        }
        Tables[i] = v;
      } 
    }

    function OutputCombinedTable1AndTable2(){
      Assembler.parse("Tables:");
      for(var i = 0; i < 256; i++){
        Assembler.parse("db " + Tables[i].toString());
      }
    }

    CombineTable1AndTable2();
    OutputCombinedTable1AndTable2();

  }
        
  DefilterDone:
  
}