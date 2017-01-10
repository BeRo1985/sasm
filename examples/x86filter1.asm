.target(bin);
.startoffset(0);
.cpu(all);

MAXINSTR=15;

OP_2BYTE=0x0f;     // start of 2-byte opcode
OP_OSIZE=0x66;     // operand size prefix
OP_CALLF=0x9a;
OP_RETNI=0xc2;     // ret near+immediate
OP_RETN=0xc3;
OP_ENTER=0xc8;
OP_INT3=0xcc;
OP_INTO=0xce;
OP_CALLN=0xe8;
OP_JMPF=0xea;
OP_ICEBP=0xf1;

// escape codes we use (these need to be 1-byte opcodes without an address or immediate operand!)
ESCAPE=OP_ICEBP;
JUMPTAB=OP_INTO;

fNM=0x0;      // no ModRM
fAM=0x1;      // no ModRM, "address mode" (jumps or direct addresses)
fMR=0x2;      // ModRM present
fMEXTRA=0x3;  // ModRM present, includes extra bits for opcode
fMODE=0x3;    // bitmask for mode

// no ModRM: size of immediate operand
fNI=0x0;      // no immediate
fBI=0x4;      // byte immediate
fWI=0x8;      // word immediate
fDI=0xc;      // dword immediate
fTYPE=0xc;    // type mask

// address mode: type of address operand
fAD=0x0;      // absolute address
fDA=0x4;      // dword absolute jump target
fBR=0x8;      // byte relative jump target
fDR=0xc;      // dword relative jump target

// others
fERR=0xf;     // denotes invalid opcodes      

fMRfNI = fMR | fNI;

ST_OP=0;                   // prefixes, first byte of opcode
ST_SIB=1;                  // SIB byte
ST_CALL_IDX=2;             // call table index
ST_DISP8_R0=3;             // byte displacement on ModRM, reg no. 0 and following
ST_DISP8_R1=4;
ST_DISP8_R2=5;
ST_DISP8_R3=6;
ST_DISP8_R4=7;
ST_DISP8_R5=8;
ST_DISP8_R6=9;
ST_DISP8_R7=10;
ST_JUMP8=11;                 // short jump
ST_IMM8=12;                  // 8-bit immediate
ST_IMM16=13;                 // 16-bit immediate
ST_IMM32=14;                 // 32-bit immediate
ST_DISP32=15;                // 32-bit displacement
ST_ADDR32=16;                // 32-bit direct address
ST_CALL32=17;                // 32-bit call target
ST_JUMP32=18;                // 32-bit jump target

ST_MAX=19;

// these components of the instruction stream are also identified
// seperately, but stored together with another stream since there's
// high correlation between them (or just because one streams provides
// good context to predict the other)
ST_MODRM=ST_OP;         // ModRM byte
ST_OP2=ST_OP;           // second byte of opcode
ST_AJUMP32=ST_JUMP32;   // absolute jump target
ST_JUMPTBL_COUNT=ST_OP;

.struct(TDisUnFilterData){
  DestStart dword(1);
  StreamEnd dword(1);
  NextIsFunc dword(1);
  Start dword(1);
  Offset16Prefix dword(1);
  Streams dword(ST_MAX);
  FuncTable dword(256);
}

DisUnFilterDataSize = TDisUnFilterData;

.code{
  .bits(32);

  // esi = Src
  // edi = Dst
  
  pushad

  // mov esi, dword ptr Source
  // mov edi, dword ptr Destination

  sub esp, DisUnFilterDataSize
  mov ebp, esp

  call @DisUnFilterPICCallLabel
  @DisUnFilterPICCallLabel:
  pop edx
  sub edx,offset @DisUnFilterPICCallLabel

  // for i:=0 to 255 do begin
  // FuncTable[i]:=0;
  // end;
  cld
  xor eax, eax
  mov ecx, eax
  inc ch
  push edi
  lea edi, [ebp + TDisUnFilterData.FuncTable]
  rep stosd
  pop edi

  // NextIsFunc:=true;
  not eax
  mov dword ptr [ebp + TDisUnFilterData.NextIsFunc], eax

  // DestStart:=Destination;
  mov dword ptr [ebp + TDisUnFilterData.DestStart], edi

  // Hdr:=Source;
  // Cur:=@Hdr[ST_MAX*sizeof(longword)];
  // for i:=0 to ST_MAX-1 do begin
  //  Stream[i]:=Cur;
  //  inc(Cur,longword(pointer(Hdr)^));
  //  inc(pansichar(Hdr),sizeof(longword));
  // end;
  // StreamEnd:=Stream[ST_OP+1];
  lea ebx, [esi + ST_MAX * 4] // ebx = Cur
  xor ecx, ecx
  @DisUnFilterStreamInitLoop:
    mov dword ptr [ebp + TDisUnFilterData.Streams + ecx * 4], ebx
    lodsd
    add ebx, eax
    inc ecx
    cmp cl, ST_MAX
    jne @DisUnFilterStreamInitLoop
  @DisUnFilterStreamInitLoopDone:
  mov eax, dword ptr [ebp + TDisUnFilterData.Streams + (ST_OP + 1) * 4]
  mov dword ptr [ebp + TDisUnFilterData.StreamEnd], eax

  @DisUnFilterStreamMainLoop:

    mov esi, dword ptr [ebp + TDisUnFilterData.Streams + ST_OP * 4]
    cmp esi, dword ptr [ebp + TDisUnFilterData.StreamEnd]
    jae DisUnFilterStreamMainLoopDone

     // Code:=Fetch8(Stream[ST_OP]);
     lodsb
     mov dword ptr [ebp + TDisUnFilterData.Streams + ST_OP * 4], esi
     
     // if Code=JUMPTAB then begin // jump table escape
     cmp al, JUMPTAB
     jne @DisUnFilterNoJumpTableEscape

       // Count:=Fetch8(Stream[ST_JUMPTBL_COUNT])+1;
       mov esi, dword ptr [ebp + TDisUnFilterData.Streams + ST_JUMPTBL_COUNT * 4]
       movzx ecx, byte ptr [esi]
       inc esi
       inc ecx
       mov dword ptr [ebp + TDisUnFilterData.Streams + ST_JUMPTBL_COUNT * 4], esi

       // for i:=0 to Count-1 do begin 
       @DisUnFilterJumpTableEscapeLoop:

         // Ind:=Fetch8(Stream[ST_CALL_IDX]);
         mov esi, dword ptr [ebp + TDisUnFilterData.Streams + ST_CALL_IDX * 4]
         movzx eax, byte ptr [esi]
         inc esi
         mov dword ptr [ebp + TDisUnFilterData.Streams + ST_CALL_IDX * 4], esi

         test eax, eax
         jz @DisUnFilterJumpTableEscapeIndIsZero
         @DisUnFilterJumpTableEscapeIndIsNonZero:

           // Target:=MoveToFront(FuncTable,Ind-1,FuncTable[Ind-1]);
           dec eax
           mov ebx, dword ptr [ebp + TDisUnFilterData.FuncTable + eax * 4]
           call @DisUnFilterMoveToFront

           jmp @DisUnFilterJumpTableEscapeIndIsZeroSkip
         @DisUnFilterJumpTableEscapeIndIsZero:

           // Target:=Fetch32B(Stream[ST_CALL32]);
           mov esi, dword ptr [ebp + TDisUnFilterData.Streams + ST_CALL32 * 4]
           lodsd
           bswap eax
           mov dword ptr [ebp + TDisUnFilterData.Streams + ST_CALL32 * 4], esi

           // AddMoveToFront(FuncTable,Target);
           call @DisUnFilterAddMoveToFront

         @DisUnFilterJumpTableEscapeIndIsZeroSkip:

         // Write32(Dest,Target);
         stosd

         loop @DisUnFilterJumpTableEscapeLoop

       // continue;
       jmp @DisUnFilterStreamMainLoop

     @DisUnFilterNoJumpTableEscape:

     // if NextIsFunc and (Code<>OP_INT3) then begin 
     mov ecx, dword ptr [ebp + TDisUnFilterData.NextIsFunc]
     jecxz @DisUnFilterStreamNoNextIsFuncAndOpINT3
     cmp al, OP_INT3
     je @DisUnFilterStreamNoNextIsFuncAndOpINT3
     @DisUnFilterStreamNextIsFuncAndOpINT3:
       push eax
       // AddMoveToFront(FuncTable,Dest);
       mov eax, edi
       call @DisUnFilterAddMoveToFront
       //  NextIsFunc:=false;
       xor eax, eax
       mov dword ptr [ebp + TDisUnFilterData.NextIsFunc], eax
       pop eax
     @DisUnFilterStreamNoNextIsFuncAndOpINT3:

     // if Code=ESCAPE then begin
     cmp al, ESCAPE
     jne @DisUnFilterNoEscape
     @DisUnFilterEscape:
       mov esi, dword ptr [ebp + TDisUnFilterData.Streams + ST_OP * 4]
       movsb
       mov dword ptr [ebp + TDisUnFilterData.Streams + ST_OP * 4], esi
       jmp @DisUnFilterNoEscapeSkip
     @DisUnFilterNoEscape:

       // Write8(Dest,Code);
       stosb

       // o16:=false;
       xor ebx, ebx

       // if Code=OP_OSIZE then
       cmp al, OP_OSIZE
       jne @DisUnFilterNoEscapeOPOSIZESkip
         not ebx // o16:=true;
         // Code:=Copy8(Dest,Stream[ST_OP]);
         mov esi, dword ptr [ebp + TDisUnFilterData.Streams + ST_OP * 4]
         lodsb
         stosb
         mov dword ptr [ebp + TDisUnFilterData.Streams + ST_OP * 4], esi
       @DisUnFilterNoEscapeOPOSIZESkip:

       mov dword ptr [ebp + TDisUnFilterData.Offset16Prefix], ebx

       // if Code in [OP_RETNI,OP_RETN,OP_INT3] then begin
       cmp al, OP_RETNI
       je @DisUnFilterRETNIRETNINT3
       cmp al, OP_RETN
       je @DisUnFilterRETNIRETNINT3
       cmp al, OP_INT3
       jne @DisUnFilterRETNIRETNINT3Skip
       @DisUnFilterRETNIRETNINT3:
         // NextIsFunc:=true;
         xor ebx, ebx
         not ebx
         mov dword ptr [ebp + TDisUnFilterData.NextIsFunc], ebx
       @DisUnFilterRETNIRETNINT3Skip:

       // if Code=OP_2BYTE then begin
       cmp al, OP_2BYTE
       jne @DisUnFilterNoOP2BYTE
       @DisUnFilterOP2BYTE:
         // Flags:=Table2[Copy8(Dest,Stream[ST_OP2])];
         mov esi, dword ptr [ebp + TDisUnFilterData.Streams + ST_OP2 * 4]
         movzx ecx, byte ptr [esi]
         mov byte ptr [edi], cl
         inc esi
         inc edi
         mov dword ptr [ebp + TDisUnFilterData.Streams + ST_OP2 * 4], esi
         inc ch // ch is one, and therefore ecx above 255
         // mov cl, byte ptr [Table2 + edx + ecx]
       jmp @DisUnFilterNoOP2BYTESkip
       @DisUnFilterNoOP2BYTE:
         // Flags:=Table1[Code];
         movzx ecx, al
         // ch is zero, and therefore ecx below 256
         // mov cl, byte ptr [Table1 + edx + ecx]
       @DisUnFilterNoOP2BYTESkip:

       // optimized form of: (Tables[ecx >> 1] >> ((ecx & 1) << 2)) & 15
       // Table1 contents goes nibble-wise from 0 to 127
       // Table2 contents goes nibble-wise from 128 to 255
       shr ecx, 1
       mov cl, byte ptr [Tables + edx + ecx]
       jnc @DisUnFilterOddTableFlag
        shr cl, 4
       @DisUnFilterOddTableFlag:
       and cl, 15

       // if Code in [OP_CALLF,OP_JMPF,OP_ENTER] then begin
       cmp al, OP_CALLF
       je @DisUnFilterCALLFJMPFENTER
       cmp al, OP_JMPF
       je @DisUnFilterCALLFJMPFENTER
       cmp al, OP_ENTER
       jne @DisUnFilterCALLFJMPFENTERSkip
       @DisUnFilterCALLFJMPFENTER:
         // Copy16Chk(ST_IMM16);
         mov bl, ST_IMM16
         call @DisUnFilterCopy16
       @DisUnFilterCALLFJMPFENTERSkip:

       // if (Flags and fMR)<>0 then begin
       test cl, fMR
       je @DisPackUnFilterNofMR

         // modrm:=Copy8(Dest,Stream[ST_MODRM]);
         mov esi, dword ptr [ebp + TDisUnFilterData.Streams + ST_MODRM * 4]
         mov bl, byte ptr [esi]
         mov byte ptr [edi], bl
         inc esi
         inc edi
         mov dword ptr [ebp + TDisUnFilterData.Streams + ST_MODRM * 4], esi

         // sib:=0;
         xor bh, bh

         // if Flags=fMEXTRA then begin
         cmp cl, fMEXTRA
         jne @DisPackUnFilterNotfEXTRA
           mov cl, fMRfNI
           test bl, 56
           jnz @DisPackUnFilterNotfEXTRA
           mov ch, byte ptr [edi - 2]
           test ch, 8
           jnz @DisPackUnFilterNotfEXTRA
           add cl, fBI
           test ch, 1
           jz @DisPackUnFilterNotfEXTRA
           add cl, fDI - fBI
           // Flags:=TableX[((modrm shr 3) and 7) or ((Code and $01) shl 3) or ((Code and $8) shl 1)];
//         mov ah, bl
//         shr ah, 3
//         and ah, 7
//         mov ch, al
//         and ch, 1
//         shl ch, 3
//         or ah, ch
//         mov ch, al
//         and ch, 8
//         shl ch, 1
//         or ah, ch
//         movzx ecx, ah
//         mov cl, byte ptr [TableX + edx + ecx]
         @DisPackUnFilterNotfEXTRA:

         // if ((modrm and 7)=4) and (modrm<$c0) then begin
         mov ah, bl
         and ah, 7
         cmp ah, 4
         jne @DisPackUnFilterNoSIB
         cmp bl, 192
         jae @DisPackUnFilterNoSIB
           // sib:=Copy8(Dest,Stream[ST_SIB]);
           mov esi, dword ptr [ebp + TDisUnFilterData.Streams + ST_SIB * 4]
           mov bh, byte ptr [esi]
           mov byte ptr [edi], bh
           inc esi
           inc edi
           mov dword ptr [ebp + TDisUnFilterData.Streams + ST_SIB * 4], esi
         @DisPackUnFilterNoSIB:

         // if (modrm and $c0)=$40 then begin
         mov ah, bl
         and ah, 192
         cmp ah, 64
         jne @DisPackUnfilterNoDISPR
           push ebx
           // st:=(modrm and 7)+ST_DISP8_R0;
           and bl, 7
           add bl, ST_DISP8_R0
           movzx ebx, bl
           // Copy8Chk(st);
           mov esi, dword ptr [ebp + TDisUnFilterData.Streams + ebx * 4]
           movsb
           mov dword ptr [ebp + TDisUnFilterData.Streams + ebx * 4], esi
           pop ebx
         @DisPackUnfilterNoDISPR:

         // if ((modrm and $c0)=$80) or ((modrm and $c7)=$05) or (((modrm<$40) and ((sib and 7)=5))) then begin
         mov ah, bl
         and ah, 192
         cmp ah, 128
         je @DisPackUnFilterADDR32orDISP32
         mov ah, bl
         and ah, 199
         cmp ah, 5
         je @DisPackUnFilterADDR32orDISP32
         cmp bl, 64
         jae @DisPackUnFilterNoADDR32orDISP32
         mov ah, bh
         and ah, 7
         cmp ah, 5
         jne @DisPackUnFilterNoADDR32orDISP32
         @DisPackUnFilterADDR32orDISP32:
           // if (modrm and $c7)=$05 then begin
           //  st:=ST_ADDR32;
           // end else begin
           //  st:=ST_DISP32;
           // end;
           and bl, 199
           sub bl, 5
           neg bl
           sbb bl, bl
           add bl, ST_ADDR32
           // Copy32Chk(st);
           call @DisUnFilterCopy32
         @DisPackUnFilterNoADDR32orDISP32:

       @DisPackUnFilterNofMR:

       // if (Flags and fMODE)=fAM then begin
       mov ah, cl
       and ah, fMODE
       cmp ah, fAM
       jne @DisPackUnFilterNofMODEfAM

         // case Flags and fTYPE of
         mov ah, cl
         and ah, fTYPE

         // fAD:begin
         cmp ah, fAD
         je @DisPackUnFilterfMODEfAMfAD
         // fDA:begin
         cmp ah, fDA
         je @DisPackUnFilterfMODEfAMfDA
         // fBR:begin
         cmp ah, fBR
         je @DisPackUnFilterfMODEfAMfBR
         // fDR:begin
         cmp ah, fDR
         je @DisPackUnFilterfMODEfAMfDR
         jmp @DisPackUnFilterNofMODEfAMSkip

           @DisPackUnFilterfMODEfAMfAD:
             // Copy32Chk(ST_ADDR32);
             mov bl, ST_ADDR32
             jmp @DisPackUnFilterNofMODEfAMCopy32

           @DisPackUnFilterfMODEfAMfDA:
             // Copy32Chk(ST_AJUMP32);
             mov bl, ST_AJUMP32
             jmp @DisPackUnFilterNofMODEfAMCopy32

           @DisPackUnFilterfMODEfAMfBR:
             // Copy8Chk(ST_JUMP8);
             mov esi, dword ptr [ebp + TDisUnFilterData.Streams + ST_JUMP8 * 4]
             movsb
             mov dword ptr [ebp + TDisUnFilterData.Streams + ST_JUMP8 * 4], esi
             jmp @DisPackUnFilterNofMODEfAMSkip

           @DisPackUnFilterfMODEfAMfDR:
             // if Code=OP_CALLN then begin
             cmp al, OP_CALLN
             jne @DisPackUnFilterfMODEfAMfDRNoOPCALLN

               // Ind:=Fetch8(Stream[ST_CALL_IDX]);
               mov esi, dword ptr [ebp + TDisUnFilterData.Streams + ST_CALL_IDX * 4]
               movzx eax, byte ptr [esi]
               inc esi
               mov dword ptr [ebp + TDisUnFilterData.Streams + ST_CALL_IDX * 4], esi

               test eax, eax
               jz @DisUnFilterfMODEfAMfDRIndIsZero
               @DisUnFilterfMODEfAMfDRIndIsNonZero:

                 // Target:=MoveToFront(FuncTable,Ind-1,FuncTable[Ind-1]);
                 dec eax
                 mov ebx, dword ptr [ebp + TDisUnFilterData.FuncTable + eax * 4]
                 call @DisUnFilterMoveToFront

                 jmp @DisUnFilterfMODEfAMfDRIndIsZeroSkip
               @DisUnFilterfMODEfAMfDRIndIsZero:

                 // Target:=Fetch32B(Stream[ST_CALL32]);
                 mov esi, dword ptr [ebp + TDisUnFilterData.Streams + ST_CALL32 * 4]
                 lodsd
                 bswap eax
                 mov dword ptr [ebp + TDisUnFilterData.Streams + ST_CALL32 * 4], esi

                 // AddMoveToFront(FuncTable,Target);
                 call @DisUnFilterAddMoveToFront

               @DisUnFilterfMODEfAMfDRIndIsZeroSkip:

               jmp @DisPackUnFilterfMODEfAMfDRNoOPCALLNSkip

             @DisPackUnFilterfMODEfAMfDRNoOPCALLN:

               // Target:=Fetch32B(Stream[ST_JUMP32]);
               mov esi, dword ptr [ebp + TDisUnFilterData.Streams + ST_JUMP32 * 4]
               lodsd
               bswap eax
               mov dword ptr [ebp + TDisUnFilterData.Streams + ST_JUMP32 * 4], esi

             @DisPackUnFilterfMODEfAMfDRNoOPCALLNSkip:

             // dec(Target,Dest+4);
             sub eax, byte 4
             sub eax, edi

             // Write32(Dest,Target);
             stosd
             jmp @DisPackUnFilterNofMODEfAMSkip

       @DisPackUnFilterNofMODEfAM:

         // case Flags and fTYPE of
         mov ah, cl
         and ah, fTYPE

         // fBI:begin
         cmp ah, fBI
         je @DisPackUnFilterNofMODEfAMfBI
         cmp ah, fWI
         je @DisPackUnFilterNofMODEfAMfWI
         cmp ah, fDI
         je @DisPackUnFilterNofMODEfAMfDI
         jmp @DisPackUnFilterNofMODEfAMSkip

          @DisPackUnFilterNofMODEfAMfBI:
             // Copy8Chk(ST_IMM8);
             mov esi, dword ptr [ebp + TDisUnFilterData.Streams + ST_IMM8 * 4]
             movsb
             mov dword ptr [ebp + TDisUnFilterData.Streams + ST_IMM8 * 4], esi
            jmp @DisPackUnFilterNofMODEfAMSkip

          @DisPackUnFilterNofMODEfAMfWI:
            // Copy16Chk(ST_IMM16);
            mov bl, ST_IMM16
            call @DisUnFilterCopy16
            jmp @DisPackUnFilterNofMODEfAMSkip

          @DisPackUnFilterNofMODEfAMfDI:
            // if o16 then begin
            cmp dword ptr [ebp + TDisUnFilterData.Offset16Prefix], 0
            jne @DisPackUnFilterNofMODEfAMfWI
            // Copy32Chk(ST_IMM32);
            mov bl, ST_IMM32
            @DisPackUnFilterNofMODEfAMCopy32:
              call @DisUnFilterCopy32

       @DisPackUnFilterNofMODEfAMSkip:

     @DisUnFilterNoEscapeSkip:

    jmp @DisUnFilterStreamMainLoop

  @DisUnFilterCopy16:
    push eax
    movzx ebx, bl
    mov esi, dword ptr [ebp + TDisUnFilterData.Streams + ebx * 4]
    lodsw
    xchg ah, al
    stosw
    mov dword ptr [ebp + TDisUnFilterData.Streams + ebx * 4], esi
    pop eax
    ret

  @DisUnFilterCopy32:
    push eax
    movzx ebx, bl
    mov esi, dword ptr [ebp + TDisUnFilterData.Streams + ebx * 4]
    lodsd
    bswap eax
    stosd
    mov dword ptr [ebp + TDisUnFilterData.Streams + ebx * 4], esi
    pop eax
    ret

  @DisUnFilterAddMoveToFront:
    mov ebx, eax // Val = Val
    xor eax, eax // Pos = 255
    not al

  @DisUnFilterMoveToFront:
    // eax = Pos
    // ebx = Val
    push ecx
    push edx
    lea edx, [ebp + TDisUnFilterData.FuncTable + eax * 4]
    mov ecx, eax
    jecxz @DisUnFilterMoveToFrontDone
    @DisUnFilterMoveToFrontLoop:
      mov eax, dword ptr [edx - 4]
      mov dword ptr [edx], eax
      sub edx, byte 4
      loop @DisUnFilterMoveToFrontLoop
    @DisUnFilterMoveToFrontDone:
      // p[0]:=Val;
      mov dword ptr [edx], ebx
      // result:=Val;
      mov eax, ebx
      pop edx
      pop ecx
      ret

/*      
  TableX:
    db fMR | fBI,fERR   ,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI // escapes for 0xf6
    db fMR | fDI,fERR   ,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI // escapes for 0xf7
    db fMR | fNI,fMR | fNI,fERR   ,fERR   ,fERR   ,fERR   ,fERR   ,fERR              // escapes for 0xfe
    db fMR | fNI,fMR | fNI,fMR | fNI,fERR   ,fMR | fNI,fERR   ,fMR | fNI,fERR        // escapes for 0xff
*/
  
  !script{

    var fNM = 0x0;      // no ModRM
    var fAM = 0x1;      // no ModRM, "address mode" (jumps | direct addresses)
    var fMR = 0x2;      // ModRM present
    var fMEXTRA = 0x3;  // ModRM present, includes extra bits for opcode
    var fMODE = 0x3;    // bitmask for mode

    // no ModRM: size of immediate operand
    var fNI = 0x0;      // no immediate
    var fBI = 0x4;      // byte immediate
    var fWI = 0x8;      // word immediate
    var fDI = 0xc;      // dword immediate
    var fTYPE = 0xc;    // type mask

    // address mode: type of address operand
    var fAD = 0x0;      // absolute address
    var fDA = 0x4;      // dword absolute jump target
    var fBR = 0x8;      // byte relative jump target
    var fDR = 0xc;      // dword relative jump target

    // others
    var fERR = 0xf;     // denotes invalid opcodes      

    // 1-byte opcodes  0         1         2         3         4         5         6         7         8        9          a         b         c         d         e         f
    var Table1 = [fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fNM | fBI,fNM | fDI,fNM | fNI,fNM | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fNM | fBI,fNM | fDI,fNM | fNI,fNM | fNI, // 0
                  fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fNM | fBI,fNM | fDI,fNM | fNI,fNM | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fNM | fBI,fNM | fDI,fNM | fNI,fNM | fNI, // 1
                  fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fNM | fBI,fNM | fDI,fNM | fNI,fNM | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fNM | fBI,fNM | fDI,fNM | fNI,fNM | fNI, // 2
                  fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fNM | fBI,fNM | fDI,fNM | fNI,fNM | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fNM | fBI,fNM | fDI,fNM | fNI,fNM | fNI, // 3
                  fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI, // 4
                  fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI, // 5
                  fNM | fNI,fNM | fNI,fMR | fNI,fMR | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fDI,fMR | fDI,fNM | fBI,fMR | fBI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI, // 6
                  fAM | fBR,fAM | fBR,fAM | fBR,fAM | fBR,fAM | fBR,fAM | fBR,fAM | fBR,fAM | fBR,fAM | fBR,fAM | fBR,fAM | fBR,fAM | fBR,fAM | fBR,fAM | fBR,fAM | fBR,fAM | fBR, // 7
                  fMR | fBI,fMR | fDI,fMR | fBI,fMR | fBI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI, // 8
                  fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fAM | fDA,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI, // 9
                  fAM | fAD,fAM | fAD,fAM | fAD,fAM | fAD,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fBI,fNM | fDI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI, // a
                  fNM | fBI,fNM | fBI,fNM | fBI,fNM | fBI,fNM | fBI,fNM | fBI,fNM | fBI,fNM | fBI,fNM | fDI,fNM | fDI,fNM | fDI,fNM | fDI,fNM | fDI,fNM | fDI,fNM | fDI,fNM | fDI, // b
                  fMR | fBI,fMR | fBI,fNM | fWI,fNM | fNI,fMR | fNI,fMR | fNI,fMR | fBI,fMR | fDI,fNM | fBI,fNM | fNI,fNM | fWI,fNM | fNI,fNM | fNI,fNM | fBI,fERR     ,fNM | fNI, // c
                  fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fNM | fBI,fNM | fBI,fNM | fNI,fNM | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI, // d
                  fAM | fBR,fAM | fBR,fAM | fBR,fAM | fBR,fNM | fBI,fNM | fBI,fNM | fBI,fNM | fBI,fAM | fDR,fAM | fDR,fAM | fAD,fAM | fBR,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI, // e
                  fNM | fNI,fERR     ,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fMEXTRA  ,fMEXTRA  ,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI, fMEXTRA ,fMEXTRA];  // f

    // 2-byte opcodes  0         1         2         3         4         5         6         7         8        9          a         b         c         d         e         f
    var Table2 = [fERR     ,fERR     ,fERR     ,fERR     ,fERR     ,fERR     ,fNM | fNI,fERR     ,fNM | fNI,fNM | fNI,fERR     ,fERR     ,fERR     ,fERR     ,fERR     ,fERR   ,   // 0
                  fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fERR     ,fERR     ,fERR     ,fERR     ,fERR     ,fERR     ,fERR   ,   // 1
                  fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fERR     ,fERR     ,fERR     ,fERR     ,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI, // 2
                  fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fERR     ,fNM | fNI,fERR     ,fERR     ,fERR     ,fERR     ,fERR     ,fERR     ,fERR     ,fERR   ,   // 3
                  fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI, // 4
                  fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI, // 5
                  fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI, // 6
                  fMR | fBI,fMR | fBI,fMR | fBI,fMR | fBI,fMR | fNI,fMR | fNI,fMR | fNI,fNM | fNI,fERR     ,fERR     ,fERR     ,fERR     ,fERR     ,fERR     ,fMR | fNI,fMR | fNI, // 7
                  fAM | fDR,fAM | fDR,fAM | fDR,fAM | fDR,fAM | fDR,fAM | fDR,fAM | fDR,fAM | fDR,fAM | fDR,fAM | fDR,fAM | fDR,fAM | fDR,fAM | fDR,fAM | fDR,fAM | fDR,fAM | fDR, // 8
                  fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI, // 9
                  fNM | fNI,fNM | fNI,fNM | fNI,fMR | fNI,fMR | fBI,fMR | fNI,fMR | fNI,fMR | fNI,fERR     ,fERR     ,fERR     ,fMR | fNI,fMR | fBI,fMR | fNI,fERR     ,fMR | fNI, // a
                  fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fERR     ,fERR     ,fERR     ,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI, // b
                  fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI,fNM | fNI, // c
                  fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI, // d
                  fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI, // e
                  fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fMR | fNI,fERR];     // f
                  
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

  DisUnFilterStreamMainLoopDone:

  add esp, DisUnFilterDataSize

  popad

  // ret
  
} 
