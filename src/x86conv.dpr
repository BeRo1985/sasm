program x86conv;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{$ifdef Win32}
 {$APPTYPE CONSOLE}
{$endif}
{$ifdef Win64}
 {$APPTYPE CONSOLE}
{$endif}

uses
  SysUtils,
  Classes,
  Math;

const FileHint='{ Don''t edit! This file is a auto-generated file by x86conv! }'#13#10;

procedure ParseStringIntoStringList(const StringList:TStringList;const StringValue:ansistring);
var StringPosition,StringLength:longint;
    Line:ansistring;
    CurrentChar:ansichar;
begin
 StringPosition:=1;
 StringLength:=length(StringValue);
 Line:='';
 while StringPosition<=StringLength do begin
  CurrentChar:=StringValue[StringPosition];
  case CurrentChar of
   #10:begin
    StringList.Add(Line);
    Line:='';
   end;
   #13:begin
   end;
   else begin
    Line:=Line+CurrentChar;
   end;
  end;
  inc(StringPosition);
 end;
 if length(Line)>0 then begin
  StringList.Add(Line);
 end;
end;

const OPTYPE_SHIFT=0;
      OPTYPE_BITS=4;
      OPTYPE_MASK=((uint64(1) shl OPTYPE_BITS)-1) shl OPTYPE_SHIFT;

      MODIFIER_SHIFT=4;
      MODIFIER_BITS=3;
      MODIFIER_MASK=((uint64(1) shl MODIFIER_BITS)-1) shl MODIFIER_SHIFT;

      REG_CLASS_SHIFT=7;
      REG_CLASS_BITS=10;
      REG_CLASS_MASK=((uint64(1) shl REG_CLASS_BITS)-1) shl REG_CLASS_SHIFT;

      SUBCLASS_SHIFT=17;
      SUBCLASS_BITS=8;
      SUBCLASS_MASK=((uint64(1) shl SUBCLASS_BITS)-1) shl SUBCLASS_SHIFT;

      SPECIAL_SHIFT=25;
      SPECIAL_BITS=7;
      SPECIAL_MASK=((uint64(1) shl SPECIAL_BITS)-1) shl SPECIAL_SHIFT;

      SIZE_SHIFT=32;
      SIZE_BITS=11;
      SIZE_MASK=((uint64(1) shl SIZE_BITS)-1) shl SIZE_SHIFT;

      OPMASK_SHIFT=0;
      OPMASK_BITS=4;
      OPMASK_MASK=((uint64(1) shl OPMASK_BITS)-1) shl OPMASK_SHIFT;
      OPMASK_K0=(uint64(0) shl OPMASK_SHIFT) and OPMASK_MASK;
      OPMASK_K1=(uint64(1) shl OPMASK_SHIFT) and OPMASK_MASK;
      OPMASK_K2=(uint64(2) shl OPMASK_SHIFT) and OPMASK_MASK;
      OPMASK_K3=(uint64(3) shl OPMASK_SHIFT) and OPMASK_MASK;
      OPMASK_K4=(uint64(4) shl OPMASK_SHIFT) and OPMASK_MASK;
      OPMASK_K5=(uint64(5) shl OPMASK_SHIFT) and OPMASK_MASK;
      OPMASK_K6=(uint64(6) shl OPMASK_SHIFT) and OPMASK_MASK;
      OPMASK_K7=(uint64(7) shl OPMASK_SHIFT) and OPMASK_MASK;

      Z_SHIFT=4;
      Z_BITS=1;
      Z_MASK=((uint64(1) shl Z_BITS)-1) shl Z_SHIFT;
      Z_VAL0=(uint64(1) shl Z_SHIFT) and Z_MASK;

      BRDCAST_SHIFT=5;
      BRDCAST_BITS=1;
      BRDCAST_MASK=((uint64(1) shl BRDCAST_BITS)-1) shl BRDCAST_SHIFT;
      BRDCAST_VAL0=(uint64(1) shl BRDCAST_SHIFT) and BRDCAST_MASK;

      STATICRND_SHIFT=6;
      STATICRND_BITS=1;
      STATICRND_MASK=((uint64(1) shl STATICRND_BITS)-1) shl STATICRND_SHIFT;

      SAE_SHIFT=7;
      SAE_BITS=1;
      SAE_MASK=((uint64(1) shl SAE_BITS)-1) shl SAE_SHIFT;

      BRSIZE_SHIFT=8;
      BRSIZE_BITS=2;
      BRSIZE_MASK=((uint64(1) shl BRSIZE_BITS)-1) shl BRSIZE_SHIFT;

      BR_BITS32=uint64(1) shl (BRSIZE_SHIFT+0);
      BR_BITS64=uint64(1) shl (BRSIZE_SHIFT+1);

      BRNUM_SHIFT=10;
      BRNUM_BITS=2;
      BRNUM_MASK=((uint64(1) shl BRNUM_BITS)-1) shl BRNUM_SHIFT;

      BR_1TO2=(0 shl BRNUM_SHIFT) and BRNUM_MASK;
      BR_1TO4=(1 shl BRNUM_SHIFT) and BRNUM_MASK;
      BR_1TO8=(2 shl BRNUM_SHIFT) and BRNUM_MASK;
      BR_1TO16=(3 shl BRNUM_SHIFT) and BRNUM_MASK;

      ODF_MASK=OPMASK_MASK;
      ODF_Z=Z_MASK;
      ODF_B32=BRDCAST_MASK or BR_BITS32;
      ODF_B64=BRDCAST_MASK or BR_BITS64;
      ODF_ER=STATICRND_MASK;
      ODF_SAE=SAE_MASK;

function OP_GENMASK(const Bits,Shift:longint):uint64;
begin
 result:=((uint64(1) shl Bits)-1) shl Shift;
end;

function OP_GENBIT(const Bits,Shift:longint):uint64;
begin
 result:=uint64(1) shl (Bits+Shift);
end;

function GEN_OPTYPE(const Bit:longint):uint64;
begin
 result:=OP_GENBIT(Bit,OPTYPE_SHIFT);
end;

function GEN_MODIFIER(const Bit:longint):uint64;
begin
 result:=OP_GENBIT(Bit,MODIFIER_SHIFT);
end;

function GEN_REG_CLASS(const Bit:longint):uint64;
begin
 result:=OP_GENBIT(Bit,REG_CLASS_SHIFT);
end;

function GEN_SUBCLASS(const Bit:longint):uint64;
begin
 result:=OP_GENBIT(Bit,SUBCLASS_SHIFT);
end;

function GEN_SPECIAL(const Bit:longint):uint64;
begin
 result:=OP_GENBIT(Bit,SPECIAL_SHIFT);
end;

function GEN_SIZE(const Bit:longint):uint64;
begin
 result:=OP_GENBIT(Bit,SIZE_SHIFT);
end;

function UInt64ToHex(const x:uint64):ansistring;
const HexChars:array[0..15] of ansichar='0123456789abcdef';
begin
 result:=HexChars[(x shr 60) and $f]+
         HexChars[(x shr 56) and $f]+
         HexChars[(x shr 52) and $f]+
         HexChars[(x shr 48) and $f]+
         HexChars[(x shr 44) and $f]+
         HexChars[(x shr 40) and $f]+
         HexChars[(x shr 36) and $f]+
         HexChars[(x shr 32) and $f]+
         HexChars[(x shr 28) and $f]+
         HexChars[(x shr 24) and $f]+
         HexChars[(x shr 20) and $f]+
         HexChars[(x shr 16) and $f]+
         HexChars[(x shr 12) and $f]+
         HexChars[(x shr 8) and $f]+
         HexChars[(x shr 4) and $f]+
         HexChars[(x shr 0) and $f];
end;

var OF_REGISTER,OF_IMMEDIATE,OF_REGMEM,OF_MEMORY,OF_BITS8,OF_BITS16,OF_BITS32,OF_BITS64,OF_BITS80,OF_BITS128,OF_BITS256,OF_BITS512,
    OF_FAR,OF_NEAR,OF_SHORT,OF_TO,OF_COLON,OF_STRICT,OF_REG_CLASS_CDT,OF_REG_CLASS_GPR,OF_REG_CLASS_SREG,OF_REG_CLASS_FPUREG,
    OF_REG_CLASS_RM_MMX,OF_REG_CLASS_RM_XMM,OF_REG_CLASS_RM_YMM,OF_REG_CLASS_RM_ZMM,OF_REG_CLASS_OPMASK,OF_REG_CLASS_BND,OF_REG_EA,
    OF_RM_GPR,OF_REG_GPR,OF_REG8,OF_REG16,OF_REG32,OF_REG64,OF_FPUREG,OF_FPU0,OF_RM_MMX,OF_MMXREG,OF_RM_XMM,OF_XMMREG,OF_RM_YMM,
    OF_YMMREG,OF_RM_ZMM,OF_ZMMREG,OF_RM_OPMASK,OF_OPMASKREG,OF_OPMASK0,OF_RM_K,OF_KREG,OF_RM_BND,OF_BNDREG,OF_REG_CDT,OF_REG_CREG,
    OF_REG_DREG,OF_REG_TREG,OF_REG_SREG,OF_REG_ES,OF_REG_CS,OF_REG_SS,OF_REG_DS,OF_REG_FS,OF_REG_GS,OF_REG_FSGS,OF_REG_SEG67,
    OF_REG_SMASK,OF_REG_ACCUM,OF_REG_AL,OF_REG_AX,OF_REG_EAX,OF_REG_RAX,OF_REG_COUNT,OF_REG_CL,OF_REG_CX,OF_REG_ECX,OF_REG_RCX,
    OF_REG_DATA,OF_REG_DL,OF_REG_DX,OF_REG_EDX,OF_REG_RDX,OF_REG_HIGH,OF_REG_NOTACC,OF_REG_RIP,OF_REG8NA,OF_REG16NA,OF_REG32NA,
    OF_REG64NA,OF_MEM_OFFS,OF_IP_REL,OF_XMEM,OF_YMEM,OF_ZMEM,OF_MEMORY_ANY,OF_UNITY,OF_SBYTEWORD,OF_SBYTEDWORD,OF_SDWORD,
    OF_UDWORD,OF_RM_XMM_L16,OF_XMM0,OF_XMM_L16,OF_RM_YMM_L16,OF_YMM0,OF_YMM_L16,OF_RM_ZMM_L16,OF_ZMM0,OF_ZMM_L16:uint64;

procedure GenerateOpFlags;
begin

 OF_REGISTER:=GEN_OPTYPE(0);
 OF_IMMEDIATE:=GEN_OPTYPE(1);
 OF_REGMEM:=GEN_OPTYPE(2);
 OF_MEMORY:=GEN_OPTYPE(3) or OF_REGMEM;

 OF_BITS8:=GEN_SIZE(0);
 OF_BITS16:=GEN_SIZE(1);
 OF_BITS32:=GEN_SIZE(2);
 OF_BITS64:=GEN_SIZE(3);
 OF_BITS80:=GEN_SIZE(4);
 OF_BITS128:=GEN_SIZE(5);
 OF_BITS256:=GEN_SIZE(6);
 OF_BITS512:=GEN_SIZE(7);
 OF_FAR:=GEN_SIZE(8);
 OF_NEAR:=GEN_SIZE(9);
 OF_SHORT:=GEN_SIZE(10);

 OF_TO:=GEN_MODIFIER(0);
 OF_COLON:=GEN_MODIFIER(1);
 OF_STRICT:=GEN_MODIFIER(2);

 OF_REG_CLASS_CDT:=GEN_REG_CLASS(0);
 OF_REG_CLASS_GPR:=GEN_REG_CLASS(1);
 OF_REG_CLASS_SREG:=GEN_REG_CLASS(2);
 OF_REG_CLASS_FPUREG:=GEN_REG_CLASS(3);
 OF_REG_CLASS_RM_MMX:=GEN_REG_CLASS(4);
 OF_REG_CLASS_RM_XMM:=GEN_REG_CLASS(5);
 OF_REG_CLASS_RM_YMM:=GEN_REG_CLASS(6);
 OF_REG_CLASS_RM_ZMM:=GEN_REG_CLASS(7);
 OF_REG_CLASS_OPMASK:=GEN_REG_CLASS(8);
 OF_REG_CLASS_BND:=GEN_REG_CLASS(9);
 
 OF_REG_EA:=OF_REGMEM or OF_REGISTER;
 OF_RM_GPR:=OF_REG_CLASS_GPR or OF_REGMEM;
 OF_REG_GPR:=OF_REG_CLASS_GPR or OF_REGMEM or OF_REGISTER;
 OF_REG8:=OF_REG_CLASS_GPR or OF_BITS8 or OF_REGMEM or OF_REGISTER;
 OF_REG16:=OF_REG_CLASS_GPR or OF_BITS16 or OF_REGMEM or OF_REGISTER;
 OF_REG32:=OF_REG_CLASS_GPR or OF_BITS32 or OF_REGMEM or OF_REGISTER;
 OF_REG64:=OF_REG_CLASS_GPR or OF_BITS64 or OF_REGMEM or OF_REGISTER;
 OF_FPUREG:=OF_REG_CLASS_FPUREG or OF_REGISTER;
 OF_FPU0:=GEN_SUBCLASS(1) or OF_REG_CLASS_FPUREG or OF_REGISTER;
 OF_RM_MMX:=OF_REG_CLASS_RM_MMX or OF_REGMEM;
 OF_MMXREG:=OF_REG_CLASS_RM_MMX or OF_REGMEM or OF_REGISTER;
 OF_RM_XMM:=OF_REG_CLASS_RM_XMM or OF_REGMEM;
 OF_XMMREG:=OF_REG_CLASS_RM_XMM or OF_REGMEM or OF_REGISTER;
 OF_RM_YMM:=OF_REG_CLASS_RM_YMM or OF_REGMEM;
 OF_YMMREG:=OF_REG_CLASS_RM_YMM or OF_REGMEM or OF_REGISTER;
 OF_RM_ZMM:=OF_REG_CLASS_RM_ZMM or OF_REGMEM;
 OF_ZMMREG:=OF_REG_CLASS_RM_ZMM or OF_REGMEM or OF_REGISTER;
 OF_RM_OPMASK:=OF_REG_CLASS_OPMASK or OF_REGMEM;
 OF_OPMASKREG:=OF_REG_CLASS_OPMASK or OF_REGMEM or OF_REGISTER;
 OF_OPMASK0:=GEN_SUBCLASS(1) or OF_REG_CLASS_OPMASK or OF_REGMEM or OF_REGISTER;
 OF_RM_K:=OF_RM_OPMASK;
 OF_KREG:=OF_OPMASKREG;
 OF_RM_BND:=OF_REG_CLASS_BND or OF_REGMEM;
 OF_BNDREG:=OF_REG_CLASS_BND or OF_REGMEM or OF_REGISTER;
 OF_REG_CDT:=OF_REG_CLASS_CDT or OF_BITS32 or OF_REGISTER;
 OF_REG_CREG:=GEN_SUBCLASS(1) or OF_REG_CLASS_CDT or OF_BITS32 or OF_REGISTER;
 OF_REG_DREG:=GEN_SUBCLASS(2) or OF_REG_CLASS_CDT or OF_BITS32 or OF_REGISTER;
 OF_REG_TREG:=GEN_SUBCLASS(3) or OF_REG_CLASS_CDT or OF_BITS32 or OF_REGISTER;
 OF_REG_SREG:=OF_REG_CLASS_SREG or OF_BITS16 or OF_REGISTER;

 OF_REG_ES:=GEN_SUBCLASS(0) or GEN_SUBCLASS(2) or OF_REG_CLASS_SREG or OF_BITS16 or OF_REGISTER;
 OF_REG_CS:=GEN_SUBCLASS(1) or GEN_SUBCLASS(2) or OF_REG_CLASS_SREG or OF_BITS16 or OF_REGISTER;
 OF_REG_SS:=GEN_SUBCLASS(0) or GEN_SUBCLASS(3) or OF_REG_CLASS_SREG or OF_BITS16 or OF_REGISTER;
 OF_REG_DS:=GEN_SUBCLASS(1) or GEN_SUBCLASS(3) or OF_REG_CLASS_SREG or OF_BITS16 or OF_REGISTER;
 OF_REG_FS:=GEN_SUBCLASS(0) or GEN_SUBCLASS(4) or OF_REG_CLASS_SREG or OF_BITS16 or OF_REGISTER;
 OF_REG_GS:=GEN_SUBCLASS(1) or GEN_SUBCLASS(4) or OF_REG_CLASS_SREG or OF_BITS16 or OF_REGISTER;
 OF_REG_FSGS:=GEN_SUBCLASS(4) or OF_REG_CLASS_SREG or OF_BITS16 or OF_REGISTER;
 OF_REG_SEG67:=GEN_SUBCLASS(5) or OF_REG_CLASS_SREG or OF_BITS16 or OF_REGISTER;

 OF_REG_SMASK:=SUBCLASS_MASK;
 OF_REG_ACCUM:=GEN_SUBCLASS(1) or OF_REG_CLASS_GPR or OF_REGMEM or OF_REGISTER;
 OF_REG_AL:=GEN_SUBCLASS(1) or OF_REG_CLASS_GPR or OF_BITS8 or OF_REGMEM or OF_REGISTER;
 OF_REG_AX:=GEN_SUBCLASS(1) or OF_REG_CLASS_GPR or OF_BITS16 or OF_REGMEM or OF_REGISTER;
 OF_REG_EAX:=GEN_SUBCLASS(1) or OF_REG_CLASS_GPR or OF_BITS32 or OF_REGMEM or OF_REGISTER;
 OF_REG_RAX:=GEN_SUBCLASS(1) or OF_REG_CLASS_GPR or OF_BITS64 or OF_REGMEM or OF_REGISTER;
 OF_REG_COUNT:=GEN_SUBCLASS(5) or GEN_SUBCLASS(2) or OF_REG_CLASS_GPR or OF_REGMEM or OF_REGISTER;
 OF_REG_CL:=GEN_SUBCLASS(5) or GEN_SUBCLASS(2) or OF_REG_CLASS_GPR or OF_BITS8 or OF_REGMEM or OF_REGISTER;
 OF_REG_CX:=GEN_SUBCLASS(5) or GEN_SUBCLASS(2) or OF_REG_CLASS_GPR or OF_BITS16 or OF_REGMEM or OF_REGISTER;
 OF_REG_ECX:=GEN_SUBCLASS(5) or GEN_SUBCLASS(2) or OF_REG_CLASS_GPR or OF_BITS32 or OF_REGMEM or OF_REGISTER;
 OF_REG_RCX:=GEN_SUBCLASS(5) or GEN_SUBCLASS(2) or OF_REG_CLASS_GPR or OF_BITS64 or OF_REGMEM or OF_REGISTER;
 OF_REG_DATA:=GEN_SUBCLASS(5) or GEN_SUBCLASS(3) or OF_REG_CLASS_GPR or OF_REGMEM or OF_REGISTER;
 OF_REG_DL:=GEN_SUBCLASS(5) or GEN_SUBCLASS(3) or OF_REG_CLASS_GPR or OF_BITS8 or OF_REGMEM or OF_REGISTER;
 OF_REG_DX:=GEN_SUBCLASS(5) or GEN_SUBCLASS(3) or OF_REG_CLASS_GPR or OF_BITS16 or OF_REGMEM or OF_REGISTER;
 OF_REG_EDX:=GEN_SUBCLASS(5) or GEN_SUBCLASS(3) or OF_REG_CLASS_GPR or OF_BITS32 or OF_REGMEM or OF_REGISTER;
 OF_REG_RDX:=GEN_SUBCLASS(5) or GEN_SUBCLASS(3) or OF_REG_CLASS_GPR or OF_BITS64 or OF_REGMEM or OF_REGISTER;
 OF_REG_HIGH:=GEN_SUBCLASS(5) or GEN_SUBCLASS(4) or OF_REG_CLASS_GPR or OF_BITS8 or OF_REGMEM or OF_REGISTER;
 OF_REG_NOTACC:=GEN_SUBCLASS(5);
 OF_REG_RIP:=GEN_SUBCLASS(7) or OF_REG_CLASS_GPR or OF_BITS64 or OF_REGISTER;
 OF_REG8NA:=GEN_SUBCLASS(5) or OF_REG_CLASS_GPR or OF_BITS8 or OF_REGMEM or OF_REGISTER;
 OF_REG16NA:=GEN_SUBCLASS(5) or OF_REG_CLASS_GPR or OF_BITS16 or OF_REGMEM or OF_REGISTER;
 OF_REG32NA:=GEN_SUBCLASS(5) or OF_REG_CLASS_GPR or OF_BITS32 or OF_REGMEM or OF_REGISTER;
 OF_REG64NA:=GEN_SUBCLASS(5) or OF_REG_CLASS_GPR or OF_BITS64 or OF_REGMEM or OF_REGISTER;

 OF_MEM_OFFS:=GEN_SUBCLASS(1) or OF_MEMORY;
 OF_IP_REL:=GEN_SUBCLASS(2) or OF_MEMORY;
 OF_XMEM:=GEN_SUBCLASS(3) or OF_MEMORY;
 OF_YMEM:=GEN_SUBCLASS(4) or OF_MEMORY;
 OF_ZMEM:=GEN_SUBCLASS(5) or OF_MEMORY;

 OF_UNITY:=GEN_SUBCLASS(0) or OF_IMMEDIATE;
 OF_SBYTEWORD:=GEN_SUBCLASS(1) or OF_IMMEDIATE;
 OF_SBYTEDWORD:=GEN_SUBCLASS(2) or OF_IMMEDIATE;
 OF_SDWORD:=GEN_SUBCLASS(3) or OF_IMMEDIATE;
 OF_UDWORD:=GEN_SUBCLASS(4) or OF_IMMEDIATE;

 OF_RM_XMM_L16:=GEN_SUBCLASS(6) or OF_RM_XMM;
 OF_XMM0:=GEN_SUBCLASS(1) or GEN_SUBCLASS(6) or OF_XMMREG;
 OF_XMM_L16:=GEN_SUBCLASS(6) or OF_XMMREG;

 OF_RM_YMM_L16:=GEN_SUBCLASS(6) or OF_RM_YMM;
 OF_YMM0:=GEN_SUBCLASS(1) or GEN_SUBCLASS(6) or OF_YMMREG;
 OF_YMM_L16:=GEN_SUBCLASS(6) or OF_YMMREG;

 OF_RM_ZMM_L16:=GEN_SUBCLASS(6) or OF_RM_ZMM;
 OF_ZMM0:=GEN_SUBCLASS(1) or GEN_SUBCLASS(6) or OF_ZMMREG;
 OF_ZMM_L16:=GEN_SUBCLASS(6) or OF_ZMMREG;

 OF_MEMORY_ANY:=OF_MEMORY or OF_RM_GPR or OF_RM_MMX or OF_RM_XMM_L16 or OF_RM_YMM_L16 or OF_RM_ZMM_L16 or OF_RM_OPMASK or OF_RM_BND;

end;

{$ifdef fpc}
 {$undef OldDelphi}
{$else}
 {$ifdef conditionalexpressions}
  {$if CompilerVersion>=23.0}
   {$undef OldDelphi}
type qword=uint64;
     ptruint=NativeUInt;
     ptrint=NativeInt;
  {$else}
   {$define OldDelphi}
  {$ifend}
 {$else}
  {$define OldDelphi}
 {$endif}
{$endif}
{$ifdef OldDelphi}
type qword=int64;
{$ifdef cpu64}
     ptruint=qword;
     ptrint=int64;
{$else}
     ptruint=longword;
     ptrint=longint;
{$endif}
{$endif}

type PIFlags=^TIFlags;
     TIFlags=set of byte;

const EmptyIFlags:TIFlags=[];

var RecordedIFlags:array of TIFlags;
    CountRecordedIFlags:longint;

type TSortCompareFunction=function(const a,b:pointer):longint;

function IntLog2(x:longword):longword; {$ifdef cpu386}assembler; register;
asm
 test eax,eax
 jz @Done
 bsr eax,eax
 @Done:
end;
{$else}
begin
 x:=x or (x shr 1);
 x:=x or (x shr 2);
 x:=x or (x shr 4);
 x:=x or (x shr 8);
 x:=x or (x shr 16);
 x:=x shr 1;
 x:=x-((x shr 1) and $55555555);
 x:=((x shr 2) and $33333333)+(x and $33333333);
 x:=((x shr 4)+x) and $0f0f0f0f;
 x:=x+(x shr 8);
 x:=x+(x shr 16);
 result:=x and $3f;
end;
{$endif}

procedure DirectIntroSort(Items:pointer;Left,Right,ElementSize:longint;CompareFunc:TSortCompareFunction);
type PByteArray=^TByteArray;
     TByteArray=array[0..$3fffffff] of byte;
     PStackItem=^TStackItem;
     TStackItem=record
      Left,Right,Depth:longint;
     end;
var Depth,i,j,Middle,Size,Parent,Child:longint;
    Pivot,Temp:pointer;
    StackItem:PStackItem;
    Stack:array[0..31] of TStackItem;
begin
 if Left<Right then begin
  GetMem(Temp,ElementSize);
  GetMem(Pivot,ElementSize);
  try
   StackItem:=@Stack[0];
   StackItem^.Left:=Left;
   StackItem^.Right:=Right;
   StackItem^.Depth:=IntLog2((Right-Left)+1) shl 1;
   inc(StackItem);
   while ptruint(pointer(StackItem))>ptruint(pointer(@Stack[0])) do begin
    dec(StackItem);
    Left:=StackItem^.Left;
    Right:=StackItem^.Right;
    Depth:=StackItem^.Depth;
    if (Right-Left)<16 then begin
     // Insertion sort
     for i:=Left+1 to Right do begin
      j:=i-1;
      if (j>=Left) and (CompareFunc(pointer(@PByteArray(Items)^[j*ElementSize]),pointer(@PByteArray(Items)^[i*ElementSize]))>0) then begin
       Move(PByteArray(Items)^[i*ElementSize],Temp^,ElementSize);
       repeat
        Move(PByteArray(Items)^[j*ElementSize],PByteArray(Items)^[(j+1)*ElementSize],ElementSize);
        dec(j);
       until not ((j>=Left) and (CompareFunc(pointer(@PByteArray(Items)^[j*ElementSize]),Temp)>0));
       Move(Temp^,PByteArray(Items)^[(j+1)*ElementSize],ElementSize);
      end;
     end;
    end else begin
     if (Depth=0) or (ptruint(pointer(StackItem))>=ptruint(pointer(@Stack[high(Stack)-1]))) then begin
      // Heap sort
      Size:=(Right-Left)+1;
      i:=Size div 2;
      repeat
       if i>Left then begin
        dec(i);
        Move(PByteArray(Items)^[(Left+i)*ElementSize],Temp^,ElementSize);
       end else begin
        if Size=0 then begin
         break;
        end else begin
         dec(Size);
         Move(PByteArray(Items)^[(Left+Size)*ElementSize],Temp^,ElementSize);
         Move(PByteArray(Items)^[Left*ElementSize],PByteArray(Items)^[(Left+Size)*ElementSize],ElementSize);
        end;
       end;
       Parent:=i;
       Child:=(i*2)+1;
       while Child<Size do begin
        if ((Child+1)<Size) and (CompareFunc(pointer(@PByteArray(Items)^[((Left+Child)+1)*ElementSize]),pointer(@PByteArray(Items)^[(Left+Child)*ElementSize]))>0) then begin
         inc(Child);
        end;
        if CompareFunc(pointer(@PByteArray(Items)^[(Left+Child)*ElementSize]),Temp)>0 then begin
         Move(PByteArray(Items)^[(Left+Child)*ElementSize],PByteArray(Items)^[(Left+Parent)*ElementSize],ElementSize);
         Parent:=Child;
         Child:=(Parent*2)+1;
        end else begin
         break;
        end;
       end;
       Move(Temp^,PByteArray(Items)^[(Left+Parent)*ElementSize],ElementSize);
      until false;
     end else begin
      // Quick sort width median-of-three optimization
      Middle:=Left+((Right-Left) shr 1);
      if (Right-Left)>3 then begin
       if CompareFunc(pointer(@PByteArray(Items)^[Left*ElementSize]),pointer(@PByteArray(Items)^[Middle*ElementSize]))>0 then begin
        Move(PByteArray(Items)^[Left*ElementSize],Temp^,ElementSize);
        Move(PByteArray(Items)^[Middle*ElementSize],PByteArray(Items)^[Left*ElementSize],ElementSize);
        Move(Temp^,PByteArray(Items)^[Middle*ElementSize],ElementSize);
       end;
       if CompareFunc(pointer(@PByteArray(Items)^[Left*ElementSize]),pointer(@PByteArray(Items)^[Right*ElementSize]))>0 then begin
        Move(PByteArray(Items)^[Left*ElementSize],Temp^,ElementSize);
        Move(PByteArray(Items)^[Right*ElementSize],PByteArray(Items)^[Left*ElementSize],ElementSize);
        Move(Temp^,PByteArray(Items)^[Right*ElementSize],ElementSize);
       end;
       if CompareFunc(pointer(@PByteArray(Items)^[Middle*ElementSize]),pointer(@PByteArray(Items)^[Right*ElementSize]))>0 then begin
        Move(PByteArray(Items)^[Middle*ElementSize],Temp^,ElementSize);
        Move(PByteArray(Items)^[Right*ElementSize],PByteArray(Items)^[Middle*ElementSize],ElementSize);
        Move(Temp^,PByteArray(Items)^[Right*ElementSize],ElementSize);
       end;
      end;
      Move(PByteArray(Items)^[Middle*ElementSize],Pivot^,ElementSize);
      i:=Left;
      j:=Right;
      repeat
       while (i<Right) and (CompareFunc(pointer(@PByteArray(Items)^[i*ElementSize]),Pivot)<0) do begin
        inc(i);
       end;
       while (j>=i) and (CompareFunc(pointer(@PByteArray(Items)^[j*ElementSize]),Pivot)>0) do begin
        dec(j);
       end;
       if i>j then begin
        break;
       end else begin
        if i<>j then begin
         Move(PByteArray(Items)^[i*ElementSize],Temp^,ElementSize);
         Move(PByteArray(Items)^[j*ElementSize],PByteArray(Items)^[i*ElementSize],ElementSize);
         Move(Temp^,PByteArray(Items)^[j*ElementSize],ElementSize);
        end;
        inc(i);
        dec(j);
       end;
      until false;
      if i<Right then begin
       StackItem^.Left:=i;
       StackItem^.Right:=Right;
       StackItem^.Depth:=Depth-1;
       inc(StackItem);
      end;
      if Left<j then begin
       StackItem^.Left:=Left;
       StackItem^.Right:=j;
       StackItem^.Depth:=Depth-1;
       inc(StackItem);
      end;
     end;
    end;
   end;
  finally
   FreeMem(Pivot);
   FreeMem(Temp);
  end;
 end;
end;

procedure IndirectIntroSort(Items:pointer;Left,Right:longint;CompareFunc:TSortCompareFunction);
type PPointers=^TPointers;
     TPointers=array[0..$ffff] of pointer;
     PStackItem=^TStackItem;
     TStackItem=record
      Left,Right,Depth:longint;
     end;
var Depth,i,j,Middle,Size,Parent,Child:longint;
    Pivot,Temp:pointer;
    StackItem:PStackItem;
    Stack:array[0..31] of TStackItem;
begin
 if Left<Right then begin
  StackItem:=@Stack[0];
  StackItem^.Left:=Left;
  StackItem^.Right:=Right;
  StackItem^.Depth:=IntLog2((Right-Left)+1) shl 1;
  inc(StackItem);
  while ptruint(pointer(StackItem))>ptruint(pointer(@Stack[0])) do begin
   dec(StackItem);
   Left:=StackItem^.Left;
   Right:=StackItem^.Right;
   Depth:=StackItem^.Depth;
   if (Right-Left)<16 then begin
    // Insertion sort
    for i:=Left+1 to Right do begin
     Temp:=PPointers(Items)^[i];
     j:=i-1;
     if (j>=Left) and (CompareFunc(PPointers(Items)^[j],Temp)>0) then begin
      repeat
       PPointers(Items)^[j+1]:=PPointers(Items)^[j];
       dec(j);
      until not ((j>=Left) and (CompareFunc(PPointers(Items)^[j],Temp)>0));
      PPointers(Items)^[j+1]:=Temp;
     end;
    end;
   end else begin
    if (Depth=0) or (ptruint(pointer(StackItem))>=ptruint(pointer(@Stack[high(Stack)-1]))) then begin
     // Heap sort
     Size:=(Right-Left)+1;
     i:=Size div 2;
     Temp:=nil;
     repeat
      if i>Left then begin
       dec(i);
       Temp:=PPointers(Items)^[Left+i];
      end else begin
       if Size=0 then begin
        break;
       end else begin
        dec(Size);
        Temp:=PPointers(Items)^[Left+Size];
        PPointers(Items)^[Left+Size]:=PPointers(Items)^[Left];
       end;
      end;
      Parent:=i;
      Child:=(i*2)+1;
      while Child<Size do begin
       if ((Child+1)<Size) and (CompareFunc(PPointers(Items)^[Left+Child+1],PPointers(Items)^[Left+Child])>0) then begin
        inc(Child);
       end;
       if CompareFunc(PPointers(Items)^[Left+Child],Temp)>0 then begin
        PPointers(Items)^[Left+Parent]:=PPointers(Items)^[Left+Child];
        Parent:=Child;
        Child:=(Parent*2)+1;
       end else begin
        break;
       end;
      end;
      PPointers(Items)^[Left+Parent]:=Temp;
     until false;
    end else begin
     // Quick sort width median-of-three optimization
     Middle:=Left+((Right-Left) shr 1);
     if (Right-Left)>3 then begin
      if CompareFunc(PPointers(Items)^[Left],PPointers(Items)^[Middle])>0 then begin
       Temp:=PPointers(Items)^[Left];
       PPointers(Items)^[Left]:=PPointers(Items)^[Middle];
       PPointers(Items)^[Middle]:=Temp;
      end;
      if CompareFunc(PPointers(Items)^[Left],PPointers(Items)^[Right])>0 then begin
       Temp:=PPointers(Items)^[Left];
       PPointers(Items)^[Left]:=PPointers(Items)^[Right];
       PPointers(Items)^[Right]:=Temp;
      end;
      if CompareFunc(PPointers(Items)^[Middle],PPointers(Items)^[Right])>0 then begin
       Temp:=PPointers(Items)^[Middle];
       PPointers(Items)^[Middle]:=PPointers(Items)^[Right];
       PPointers(Items)^[Right]:=Temp;
      end;
     end;
     Pivot:=PPointers(Items)^[Middle];
     i:=Left;
     j:=Right;
     repeat
      while (i<Right) and (CompareFunc(PPointers(Items)^[i],Pivot)<0) do begin
       inc(i);
      end;
      while (j>=i) and (CompareFunc(PPointers(Items)^[j],Pivot)>0) do begin
       dec(j);
      end;
      if i>j then begin
       break;
      end else begin
       if i<>j then begin
        Temp:=PPointers(Items)^[i];
        PPointers(Items)^[i]:=PPointers(Items)^[j];
        PPointers(Items)^[j]:=Temp;
       end;
       inc(i);
       dec(j);
      end;
     until false;
     if i<Right then begin
      StackItem^.Left:=i;
      StackItem^.Right:=Right;
      StackItem^.Depth:=Depth-1;
      inc(StackItem);
     end;
     if Left<j then begin
      StackItem^.Left:=Left;
      StackItem^.Right:=j;
      StackItem^.Depth:=Depth-1;
      inc(StackItem);
     end;
    end;
   end;
  end;
 end;
end;

const MaxOperands=5;

type TChars=set of ansichar;

function Parse(const s:ansistring;const c:TChars;var Position:longint;const DoContinue:boolean):ansistring;
var StartPosition,EndPosition,StringLength:longint;
begin
 StartPosition:=Position;
 EndPosition:=Position-1;
 StringLength:=length(s);
 while Position<=StringLength do begin
  if s[Position] in c then begin
   EndPosition:=Position-1;
   inc(Position);
   if DoContinue then begin
    while (Position<=StringLength) and (s[Position] in c) do begin
     inc(Position);
    end;
   end;
   break;
  end else begin
   EndPosition:=Position;
   inc(Position);
  end;
 end;
 result:=copy(s,StartPosition,(EndPosition-StartPosition)+1);
end;

type PIFlagBit=^TIFlagBit;
     TIFlagBit=record
      Name:ansistring;
      Bit:longint;
      Description:ansistring;
     end;

     PInstruction=^TInstruction;
     TInstruction=record
      Name:ansistring;
      Operands:array[0..MaxOperands-1] of ansistring;
      OperandDecorators:array[0..MaxOperands-1] of ansistring;
      Sequence:ansistring;
      SequenceLength:longint;
      Flags:TIFlags;
      CountOperands:longint;
      Relax:longint;
      Index:longint;
     end;

     PRegister=^TRegister;
     TRegister=record
      RegisterName:ansistring;
      RegisterClass:ansistring;
      RegisterNumber:longint;
      RegisterFlags:ansistring;
     end;

     PCondition=^TCondition;
     TCondition=record
      Name:ansistring;
      Code:byte;
     end;

const Conditions:array[0..29] of TCondition=((Name:'O';Code:$00),
                                             (Name:'NO';Code:$01),
                                             (Name:'B';Code:$02),
                                             (Name:'C';Code:$02),
                                             (Name:'NAE';Code:$02),
                                             (Name:'NB';Code:$03),
                                             (Name:'NC';Code:$03),
                                             (Name:'AE';Code:$03),
                                             (Name:'E';Code:$04),
                                             (Name:'Z';Code:$04),
                                             (Name:'NE';Code:$05),
                                             (Name:'NZ';Code:$05),
                                             (Name:'BE';Code:$06),
                                             (Name:'NA';Code:$06),
                                             (Name:'NBE';Code:$07),
                                             (Name:'A';Code:$07),
                                             (Name:'S';Code:$08),
                                             (Name:'NS';Code:$09),
                                             (Name:'P';Code:$0a),
                                             (Name:'PE';Code:$0a),
                                             (Name:'NP';Code:$0b),
                                             (Name:'PO';Code:$0b),
                                             (Name:'L';Code:$0c),
                                             (Name:'NGE';Code:$0c),
                                             (Name:'NL';Code:$0d),
                                             (Name:'GE';Code:$0d),
                                             (Name:'LE';Code:$0e),
                                             (Name:'NG';Code:$0e),
                                             (Name:'NLE';Code:$0f),
                                             (Name:'G';Code:$0f));

var Instructions:array of TInstruction;
    PInstructions:array of PInstruction;
    CountInstructions:longint;
    Registers:array of TRegister;
    CountRegisters:longint;
    IFlagBits:array of TIFlagBit;
    CountIFlagBits,IFlagDWords,MaxIFlagBit:longint;
    MaxInstructionTemplateSequenceLength:longint;
    CurrentInstruction:PInstruction;
    InstructionNames:TStringList;
    InstructionRanges:array of array[0..3] of longint;

function SortInstructions(const a,b:pointer):longint;
begin
 result:=CompareStr(PInstruction(a)^.Name,PInstruction(b)^.Name);
 if result=0 then begin
  result:=PInstruction(a)^.Index-PInstruction(b)^.Index;
  if result=0 then begin
   result:=PInstruction(a)^.SequenceLength-PInstruction(b)^.SequenceLength;
  end;
 end;
end;

procedure AddIFlagBit(const IFlagBitName:ansistring;const IFlagBit:longint;const IFlagBitDescription:ansistring);
var Index:longint;
    AIFlagBit:PIFlagBit;
begin
 Index:=CountIFlagBits;
 inc(CountIFlagBits);
 if CountIFlagBits>length(IFlagBits) then begin
  SetLength(IFlagBits,CountIFlagBits*2);
 end;
 AIFlagBit:=@IFlagBits[Index];
 AIFlagBit^.Name:=IFlagBitName;
 AIFlagBit^.Bit:=IFlagBit;
 AIFlagBit^.Description:=IFlagBitDescription;
end;

function AddIFlags(const IFlags:TIFlags):longint;
var i:longint;
begin
 for i:=0 to CountRecordedIFlags-1 do begin
  if RecordedIFlags[i]=IFlags then begin
   result:=i;
   exit;
  end;
 end;
 result:=CountRecordedIFlags;
 inc(CountRecordedIFlags);
 if CountRecordedIFlags>length(RecordedIFlags) then begin
  SetLength(RecordedIFlags,CountRecordedIFlags*2);
 end;
 RecordedIFlags[result]:=IFlags;
end;

procedure IFlagsSetBit(var IFlags:TIFlags;const Bit:byte);
begin
 Include(IFlags,Bit);
end;

procedure IFlagsSetFlag(var IFlags:TIFlags;const Flag:ansistring);
var i:longint;
begin
 for i:=0 to CountIFlagBits-1 do begin
  if IFlagBits[i].Name=Flag then begin
   Include(IFlags,IFlagBits[i].Bit);
   exit;
  end;
 end;
 writeln(Flag);
 readln;
end;

procedure AddInstruction(const Name,Operand0,Operand1,Operand2,Operand3,Operand4,OperandEncoding,OperandTuple,Sequence,Flags:ansistring;const CountOperands,Relax,ConditionCode:longint);
var Index,i,j,k,h,SequenceStringLength,FlagsStringLength,SequenceLength,Op,OpEx,b,m,w,l,p,LiteralIndex,ImmCode,minmap:longint;
    Instruction:PInstruction;
    PrefixOK,HasNDS:boolean;
    s,s2,s3,CodeSequence,CodeFlags,Decorator,VEXName:ansistring;
    c,LastImm:ansichar;
    OpPos:array[ansichar] of longint;
    IFlags:TIFlags;
 function Octal(o:longword):longword;
 begin
  result:=(((o shr 0) and 7) shl 0) or (((o shr 4) and 7) shl 3) or (((o shr 8) and 7) shl 6) or (((o shr 12) and 7) shl 9);
 end;
 function PutCode(x:byte):longint;
 begin
  CodeSequence:=CodeSequence+ansichar(byte(x));
  result:=length(CodeSequence);
 end;
begin
 Index:=CountInstructions;
 inc(CountInstructions);
 if CountInstructions>length(Instructions) then begin
  SetLength(Instructions,CountInstructions*2);
 end;
 Instruction:=@Instructions[Index];
 Instruction^.Name:=Name;
 Instruction^.Operands[0]:=Operand0;
 Instruction^.Operands[1]:=Operand1;
 Instruction^.Operands[2]:=Operand2;
 Instruction^.Operands[3]:=Operand3;
 Instruction^.Operands[4]:=Operand4;
 Instruction^.CountOperands:=CountOperands;
 Instruction^.Relax:=Relax;
 Instruction^.Index:=Index;

 for c:=#$00 to #$ff do begin
  OpPos[c]:=-1;
 end;

 h:=Relax;
 op:=0;
 for i:=1 to length(OperandEncoding) do begin
  c:=OperandEncoding[i];
  if c='+' then begin
   dec(Op);
  end else begin
   if c in ['A'..'Z'] then begin
    inc(byte(c),byte(ansichar('a'))-byte(ansichar('A')));
   end;
   if (h and 1)<>0 then begin
    dec(Op);
   end;
   h:=h shr 1;
   OpPos[c]:=Op;
   inc(Op);
  end;
 end;

 SequenceStringLength:=length(Sequence);
 FlagsStringLength:=length(Flags);

 for i:=0 to CountOperands-1 do begin
  s:=Instruction^.Operands[i];
  j:=1;
  k:=length(s);
  Decorator:='';
  s3:='';
  while j<=k do begin
   s2:=UpperCase(trim(Parse(s,['|'],j,false)));
   if s2='B32' then begin
    if length(Decorator)>0 then begin
     Decorator:=Decorator+' or ';
    end;
    Decorator:=Decorator+'ODF_B32';
   end else if s2='B64' then begin
    if length(Decorator)>0 then begin
     Decorator:=Decorator+' or ';
    end;
    Decorator:=Decorator+'ODF_B64';
   end else if s2='MASK' then begin
    if length(Decorator)>0 then begin
     Decorator:=Decorator+' or ';
    end;
    Decorator:=Decorator+'ODF_MASK';
   end else if s2='Z' then begin
    if length(Decorator)>0 then begin
     Decorator:=Decorator+' or ';
    end;
    Decorator:=Decorator+'ODF_Z';
   end else if s2='ER' then begin
    if length(Decorator)>0 then begin
     Decorator:=Decorator+' or ';
    end;
    Decorator:=Decorator+'ODF_ER';
   end else if s2='SAE' then begin
    if length(Decorator)>0 then begin
     Decorator:=Decorator+' or ';
    end;
    Decorator:=Decorator+'ODF_SAE';
   end;
  end;
  Instruction^.OperandDecorators[i]:=Decorator;
 end;

{if Sequence='o32 b8+r id' then begin
  if Sequence='o32 b8+r id' then begin
  end;
 end;{}

 LastImm:='h';
 PrefixOK:=true;
 CodeSequence:='';
 LiteralIndex:=0;
 i:=1;
 while i<=SequenceStringLength do begin
  s:=LowerCase(trim(Parse(Sequence,[#1..#32],i,false)));
  if s='o16' then begin
   PutCode(Octal($0320));
  end else if s='o32' then begin
   PutCode(Octal($0321));
  end else if s='odf' then begin
   PutCode(Octal($0322));
  end else if s='o64' then begin
   PutCode(Octal($0324));
  end else if s='o64nw' then begin
   PutCode(Octal($0323));
  end else if s='a16' then begin
   PutCode(Octal($0310));
  end else if s='a32' then begin
   PutCode(Octal($0311));
  end else if s='adf' then begin
   PutCode(Octal($0312));
  end else if s='a64' then begin
   PutCode(Octal($0313));
  end else if s='!osp' then begin
   PutCode(Octal($0364));
  end else if s='!asp' then begin
   PutCode(Octal($0365));
  end else if s='f2i' then begin
   PutCode(Octal($0332));
  end else if s='f3i' then begin
   PutCode(Octal($0333));
  end else if s='mustrep' then begin
   PutCode(Octal($0336));
  end else if s='mustrepne' then begin
   PutCode(Octal($0337));
  end else if s='rex.l' then begin
   PutCode(Octal($0334));
  end else if s='norexb' then begin
   PutCode(Octal($0314));
  end else if s='norexx' then begin
   PutCode(Octal($0315));
  end else if s='norexr' then begin
   PutCode(Octal($0316));
  end else if s='norexw' then begin
   PutCode(Octal($0317));
  end else if s='repe' then begin
   PutCode(Octal($0335));
  end else if s='nohi' then begin
   PutCode(Octal($0325));
  end else if s='nof3' then begin
   PutCode(Octal($0326));
  end else if s='norep' then begin
   PutCode(Octal($0331));
  end else if s='wait' then begin
   PutCode(Octal($0341));
  end else if s='resb' then begin
   PutCode(Octal($0340));
  end else if s='np' then begin
   PutCode(Octal($0360));
  end else if s='jcc8' then begin
   PutCode(Octal($0370));
  end else if s='jmp8' then begin
   PutCode(Octal($0371));
  end else if s='jlen' then begin
   PutCode(Octal($0373));
  end else if s='hlexr' then begin
   PutCode(Octal($0271));
  end else if s='hlenl' then begin
   PutCode(Octal($0272));
  end else if s='hle' then begin
   PutCode(Octal($0273));

  end else if s='vsibx' then begin
   PutCode(Octal($0374));
  end else if s='vm32x' then begin
   PutCode(Octal($0374));
  end else if s='vm64x' then begin
   PutCode(Octal($0374));

  end else if s='vsiby' then begin
   PutCode(Octal($0375));
  end else if s='vm32y' then begin
   PutCode(Octal($0375));
  end else if s='vm64y' then begin
   PutCode(Octal($0375));

  end else if s='vsibz' then begin
   PutCode(Octal($0376));
  end else if s='vm32z' then begin
   PutCode(Octal($0376));
  end else if s='vm64z' then begin
   PutCode(Octal($0376));

  end else begin
   if PrefixOK and ((s='66') or (s='f2') or (s='f3')) then begin
    if s='66' then begin
     PutCode(Octal($0361));
    end else if s='f2' then begin
     PutCode(Octal($0332));
    end else if s='f3' then begin
     PutCode(Octal($0333));
    end;
   end else if (length(s)=2) and ((s[1] in ['0'..'9','a'..'f','A'..'F']) and (s[2] in ['0'..'9','a'..'f','A'..'F'])) then begin
    if LiteralIndex=0 then begin
     LiteralIndex:=PutCode(Octal($001));
     PutCode(StrToIntDef('$'+s,0));
    end else if LiteralIndex>0 then begin
     if byte(ansichar(CodeSequence[LiteralIndex]))<4 then begin
      CodeSequence[LiteralIndex]:=ansichar(byte(byte(ansichar(CodeSequence[LiteralIndex]))+1));
      PutCode(StrToIntDef('$'+s,0));
     end else begin
      writeln('Too long literal');
      halt(1);
     end;
    end;
    PrefixOK:=false;
   end else if s='/r' then begin
    if (OpPos['r']<0) or (OpPos['m']<0) then begin
     writeln('/r requires r and m operands');
     halt(1);
    end;
    OpEx:=0;
    if (OpPos['r'] and 4)<>0 then begin
     OpEx:=OpEx or 5;
    end;
    if (OpPos['m'] and 4)<>0 then begin
     OpEx:=OpEx or 6;
    end;
    if OpEx<>0 then begin
     PutCode(OpEx);
    end;
    if OpPos['x']>=0 then begin
     PutCode(Octal($014)+longword(OpPos['x'] and 3));
    end;
    PutCode(Octal($0100)+longword(((OpPos['m'] and 3) shl 3)+(OpPos['r'] and 3)));
    PrefixOK:=false;
   end else if (length(s)=2) and (s[1]='/') and (s[2] in ['0'..'7']) then begin
    if OpPos['m']<0 then begin
     writeln(s+' requires m operand');
     halt(1);
    end;
    if (OpPos['m'] and 4)<>0 then begin
     PutCode(6);
    end;
    PutCode(Octal($0200)+longword(((OpPos['m'] and 3) shl 3)+(byte(ansichar(s[2]))-byte(ansichar('0')))));
    PrefixOK:=false;
   end else if (length(s)>2) and (((s[1]='v') and (s[2]='e') and (s[3]='x')) or ((s[1]='x') and (s[2]='o') and (s[3]='p'))) then begin
    if (s[1]='v') and (s[2]='e') and (s[3]='x') then begin
     // vex
     b:=0;
     VEXName:='vex';
    end else begin
     // xop
     b:=1;
     VEXName:='xop';
    end;
    m:=-1;
    w:=2;
    l:=-1;
    p:=0;
    j:=1;
    HasNDS:=false;
    if j<=length(s) then begin
     Parse(s,['.'],j,false);
     while j<=length(s) do begin
      s2:=LowerCase(trim(Parse(s,['.'],j,false)));
      if (s2='128') or (s2='l0') or (s2='lz') then begin
       l:=0;
      end else if (s2='256') or (s2='l1') then begin
       l:=1;
      end else if s2='lig' then begin
       l:=2;
      end else if s2='w0' then begin
       w:=0;
      end else if s2='w1' then begin
       w:=1;
      end else if s2='wig' then begin
       w:=2;
      end else if s2='ww' then begin
       w:=3;
      end else if s2='p0' then begin
       p:=0;
      end else if (s2='p1') or (s2='66') then begin
       p:=1;
      end else if (s2='p2') or (s2='f3') then begin
       p:=2;
      end else if (s2='p3') or (s2='f2') then begin
       p:=3;
      end else if s2='0f' then begin
       m:=1;
      end else if s2='0f38' then begin
       m:=2;
      end else if s2='0f3a' then begin
       m:=3;
      end else if (length(s2)>1) and (s2[1]='m') and (s2[2] in ['0'..'9']) then begin
       m:=StrToIntDef(copy(s2,2,length(s2)-1),0);
      end else if (s2='nds') or (s2='ndd') or (s2='dds') then begin
       if OpPos['v']<0 then begin
        writeln(VEXName+'.'+s2+' requires v operands');
        halt(1);
       end;
       HasNDS:=true;
      end else begin
       writeln(s2+' unknown identifier');
       halt(1);
      end;
     end;
     if (m<0) or (w<0) or (l<0) or (p<0) then begin
      writeln('Missing fields in ',UpperCase(VEXName),' specification ',s);
      halt(1);
     end;
     if (OpPos['v']>=0) and not HasNDS then begin
      writeln('''v'' operand without ',VEXName,'.nds or ',VEXName,'.ndd');
      halt(1);
     end;
     if b<>0 then begin
      minmap:=8;
     end else begin
      minmap:=0;
     end;
     if (m<minmap) or (m>31) then begin
      writeln('Only maps ',minmap,'-31 are valid for ',VEXName);
      halt(1);
     end;
     if OpPos['v']>=0 then begin
      PutCode(Octal($0260)+longword(OpPos['v'] and 3));
     end else begin
      PutCode(Octal($0270));
     end;
     PutCode((b shl 6)+m);
     PutCode((w shl 4)+(l shl 2)+p);
     PrefixOK:=false;
    end;
   end else if (length(s)>3) and ((s[1]='e') and (s[2]='v') and (s[3]='e') and (s[4]='x')) then begin
    // evex
    b:=4;
    m:=-1;
    w:=2;
    l:=-1;
    p:=0;
    j:=1;
    HasNDS:=false;
    if j<=length(s) then begin
     Parse(s,['.'],j,false);
     while j<=length(s) do begin
      s2:=LowerCase(trim(Parse(s,['.'],j,false)));
      if (s2='128') or (s2='l0') or (s2='lz') or (s2='lig') then begin
       l:=0;
      end else if (s2='256') or (s2='l1') then begin
       l:=1;
      end else if (s2='512') or (s2='l2') then begin
       l:=2;
      end else if s2='w0' then begin
       w:=0;
      end else if s2='w1' then begin
       w:=1;
      end else if s2='wig' then begin
       w:=2;
      end else if s2='ww' then begin
       w:=3;
      end else if s2='p0' then begin
       p:=0;
      end else if (s2='p1') or (s2='66') then begin
       p:=1;
      end else if (s2='p2') or (s2='f3') then begin
       p:=2;
      end else if (s2='p3') or (s2='f2') then begin
       p:=3;
      end else if s2='0f' then begin
       m:=1;
      end else if s2='0f38' then begin
       m:=2;
      end else if s2='0f3a' then begin
       m:=3;
      end else if (length(s2)>1) and (s2[1]='m') and (s2[2] in ['0'..'9']) then begin
       m:=StrToIntDef(copy(s2,2,length(s2)-1),0);
      end else if (s2='nds') or (s2='ndd') or (s2='dds') then begin
       if OpPos['v']<0 then begin
        writeln('vex.'+s2+' requires v operands');
        halt(1);
       end;
       HasNDS:=true;
      end else begin
       writeln(s2+' unknown identifier');
       halt(1);
      end;
     end;
     if (m<0) or (w<0) or (l<0) or (p<0) then begin
      writeln('Missing fields in EVEX specification ',s);
      halt(1);
     end;
     if (OpPos['v']>=0) and not HasNDS then begin
      writeln('''v'' operand without evex.nds or evex.ndd');
      halt(1);
     end;
     if m>15 then begin
      writeln('Only maps 0-15 are valid for EVEX');
     end;
     if OpPos['v']>=0 then begin
      PutCode(Octal($0240)+longword(OpPos['v'] and 3));
     end else begin
      PutCode(Octal($0250));
     end;
     PutCode((b shl 6)+m);
     PutCode((w shl 4)+(l shl 2)+p);
     if OperandTuple='fv' then begin
      PutCode(Octal($300)+Octal($001));
     end else if OperandTuple='hv' then begin
      PutCode(Octal($300)+Octal($002));
     end else if OperandTuple='fvm' then begin
      PutCode(Octal($300)+Octal($003));
     end else if OperandTuple='t1s8' then begin
      PutCode(Octal($300)+Octal($004));
     end else if OperandTuple='t1s16' then begin
      PutCode(Octal($300)+Octal($005));
     end else if OperandTuple='t1s' then begin
      PutCode(Octal($300)+Octal($006));
     end else if OperandTuple='t1f32' then begin
      PutCode(Octal($300)+Octal($007));
     end else if OperandTuple='t1f64' then begin
      PutCode(Octal($300)+Octal($010));
     end else if OperandTuple='t2' then begin
      PutCode(Octal($300)+Octal($011));
     end else if OperandTuple='t4' then begin
      PutCode(Octal($300)+Octal($012));
     end else if OperandTuple='t8' then begin
      PutCode(Octal($300)+Octal($013));
     end else if OperandTuple='hvm' then begin
      PutCode(Octal($300)+Octal($014));
     end else if OperandTuple='qvm' then begin
      PutCode(Octal($300)+Octal($015));
     end else if OperandTuple='ovm' then begin
      PutCode(Octal($300)+Octal($016));
     end else if OperandTuple='m128' then begin
      PutCode(Octal($300)+Octal($017));
     end else if OperandTuple='dup' then begin
      PutCode(Octal($300)+Octal($020));
     end else if length(trim(OperandTuple))<>0 then begin
      writeln('Unknown tuple: ',OperandTuple);
      readln;
      halt(1);
     end else begin
      PutCode(Octal($300));
     end;
     PrefixOK:=false;
    end;
   end else if s='/is4' then begin
    if OpPos['s']<0 then begin
     writeln(s+' requires s operand');
     halt(1);
    end;
    if OpPos['i']>=0 then begin
     PutCode(Octal($0172));
     PutCode((OpPos['s'] shl 3)+OpPos['i']);
    end else begin
     if (OpPos['s'] and 4)<>0 then begin
      PutCode(Octal($05));
     end;
     PutCode(Octal($174)+longword(OpPos['s'] shl 3));
    end;
    PrefixOK:=false;
   end else if (length(s)>=6) and ((s[1]='/') and (s[2]='i') and (s[3]='s') and (s[4]='4') and (s[5]='=') and (s[6] in ['0'..'9'])) then begin
    if OpPos['s']<0 then begin
     writeln(s+' requires s operand');
     halt(1);
    end;
    m:=StrToIntDef(copy(s,6,length(s)-5),0);
    if (m<0) or (m>15) then begin
     writeln('invalid imm4 value');
     halt(1);
    end;
    PutCode(Octal($0173));
    PutCode((OpPos['s'] shl 4)+m);
    PrefixOK:=false;
   end else if (length(s)=4) and ((s[1] in ['0'..'9','a'..'f','A'..'F']) and (s[2] in ['0'..'9','a'..'f','A'..'F']) and (s[3]='+') and (s[4]='s')) then begin
    if OpPos['i']<0 then begin
     writeln(s+' requires i operand');
     halt(1);
    end;
    if (OpPos['i'] and 4)<>0 then begin
     PutCode(Octal($0005));
    end;
    PutCode(OpPos['i'] and 3);
    PutCode(StrToIntDef('$'+copy(s,1,2),0));
    PrefixOK:=false;
   end else if (length(s)=4) and ((s[1] in ['0'..'9','a'..'f','A'..'F']) and (s[2] in ['0'..'9','a'..'f','A'..'F']) and (s[3]='+') and (s[4]='c')) then begin
    if LiteralIndex=0 then begin
     LiteralIndex:=PutCode(Octal($001));
     PutCode(longword(StrToIntDef('$'+copy(s,1,2),0))+longword(ConditionCode));
    end else if LiteralIndex>0 then begin
     if byte(ansichar(CodeSequence[LiteralIndex]))<4 then begin
      CodeSequence[LiteralIndex]:=ansichar(byte(byte(ansichar(CodeSequence[LiteralIndex]))+1));
      PutCode(longword(StrToIntDef('$'+copy(s,1,2),0))+longword(ConditionCode));
     end else begin
      LiteralIndex:=PutCode(Octal($001));
      PutCode(longword(StrToIntDef('$'+copy(s,1,2),0))+longword(ConditionCode));
     end;
    end;
    PrefixOK:=false;
   end else if (length(s)=4) and ((s[1] in ['0'..'9','a'..'f','A'..'F']) and (s[2] in ['0'..'9','a'..'f','A'..'F']) and (s[3]='+') and (s[4]='r')) then begin
    if OpPos['r']<0 then begin
     writeln(s+' requires i operand');
     halt(1);
    end;
    if (OpPos['r'] and 4)<>0 then begin
     PutCode(Octal($0005));
    end;
    PutCode(Octal($0010)+longword(OpPos['r'] and 3));
    PutCode(StrToIntDef('$'+copy(s,1,2),0));
    PrefixOK:=false;
   end else if (length(s)>=2) and (s[1]='\') and (s[2] in ['0'..'7']) then begin
    PutCode(Octal(StrToIntDef('$'+copy(s,2,length(s)-1),0)));
   end else if (length(s)=3) and (s[1]='\') and (s[1] in ['0'..'9','a'..'f','A'..'F']) and (s[2] in ['0'..'9','a'..'f','A'..'F']) then begin
    PutCode(StrToIntDef('$'+copy(s,2,2),0));
   end else begin
    if s='ib' then begin
     ImmCode:=Octal($0020);
    end else if s='ib,u' then begin
     ImmCode:=Octal($0024);
    end else if s='iw' then begin
     ImmCode:=Octal($0030);
    end else if s='ib,s' then begin
     ImmCode:=Octal($0274);
    end else if s='iwd' then begin
     ImmCode:=Octal($0034);
    end else if s='id' then begin
     ImmCode:=Octal($0040);
    end else if s='id,s' then begin
     ImmCode:=Octal($0254);
    end else if s='iwdq' then begin
     ImmCode:=Octal($0044);
    end else if s='rel8' then begin
     ImmCode:=Octal($0050);
    end else if s='iq' then begin
     ImmCode:=Octal($0054);
    end else if s='rel16' then begin
     ImmCode:=Octal($0060);
    end else if s='rel' then begin
     ImmCode:=Octal($0064);
    end else if s='rel32' then begin
     ImmCode:=Octal($0070);
    end else if s='seg' then begin
     ImmCode:=Octal($0074);
    end else begin
     ImmCode:=-1;
    end;
    if ImmCode<0 then begin
     writeln('unknown operation: '+s);
     halt(1);
    end else begin
     if s='seg' then begin
      if LastImm<'i' then begin
       writeln('seg without an immediate operand');
       halt(1);
      end;
     end else begin
      inc(LastImm);
      if LastImm>'j' then begin
       writeln('too many immediate operands');
       halt(1);
      end;
     end;
     if OpPos[LastImm]<0 then begin
      writeln(s+' requires '+LastImm+' operand');
      halt(1);
     end;
     if (OpPos[LastImm] and 4)<>0 then begin
      PutCode(Octal($0005));
     end;
     PutCode(longword(ImmCode)+longword(OpPos[LastImm] and 3));
     PrefixOK:=false;
    end;
   end;
  end;
 end;

 SequenceLength:=length(CodeSequence);

 IFlags:=[];
 i:=1;
 while i<=FlagsStringLength do begin
  s:=UpperCase(trim(Parse(Flags,[','],i,false)));
  if s<>'ND' then begin
   if s='X64' then begin
    IFlagsSetFlag(IFlags,'LONG');
    IFlagsSetFlag(IFlags,'X86_64');
   end else begin
    IFlagsSetFlag(IFlags,s);
   end;
  end;
 end;
 if (pos('vex.',LowerCase(Sequence))>0) or (pos('xop.',LowerCase(Sequence))>0) then begin
  IFlagsSetFlag(IFlags,'VEX');
 end;
 if pos('evex.',LowerCase(Sequence))>0 then begin
  IFlagsSetFlag(IFlags,'EVEX');
 end;

 for i:=0 to CountOperands-1 do begin
  s:=Instruction^.Operands[i];
  j:=1;
  k:=length(s);
  s3:='';
  while j<=k do begin
   s2:=UpperCase(trim(Parse(s,['|'],j,false)));
   if s2='VOID' then begin
    s2:='OF_VOID';
   end else if s2='SHORT' then begin
    s2:='OF_SHORT';
   end else if s2='NEAR' then begin
    s2:='OF_NEAR';
   end else if s2='FAR' then begin
    s2:='OF_FAR';
   end else if s2='TO' then begin
    s2:='OF_TO';
   end else if s2='COLON' then begin
    s2:='OF_COLON';
   end else if s2='IMM' then begin
    s2:='OF_IMMEDIATE';
   end else if s2='IMM8' then begin
    s2:='OF_IMMEDIATE or OF_BITS8';
   end else if s2='IMM16' then begin
    s2:='OF_IMMEDIATE or OF_BITS16';
   end else if s2='IMM32' then begin
    s2:='OF_IMMEDIATE or OF_BITS32';
   end else if s2='IMM64' then begin
    s2:='OF_IMMEDIATE or OF_BITS64';
   end else if s2='IMM128' then begin
    s2:='OF_IMMEDIATE or OF_BITS128';
   end else if s2='IMM256' then begin
    s2:='OF_IMMEDIATE or OF_BITS256';
   end else if s2='MEM' then begin
    s2:='OF_MEMORY';
   end else if s2='MEM8' then begin
    s2:='OF_MEMORY or OF_BITS8';
   end else if s2='MEM16' then begin
    s2:='OF_MEMORY or OF_BITS16';
   end else if s2='MEM32' then begin
    s2:='OF_MEMORY or OF_BITS32';
   end else if s2='MEM64' then begin
    s2:='OF_MEMORY or OF_BITS64';
   end else if s2='MEM80' then begin
    s2:='OF_MEMORY or OF_BITS80';
   end else if s2='MEM128' then begin
    s2:='OF_MEMORY or OF_BITS128';
   end else if s2='MEM256' then begin
    s2:='OF_MEMORY or OF_BITS256';
   end else if s2='MEM_OFFS' then begin
    s2:='OF_MEM_OFFS';
   end else if s2='REG' then begin
    s2:='OF_REG_GPR';
   end else if s2='REG8' then begin
    s2:='OF_REG_GPR or OF_BITS8';
   end else if s2='REG16' then begin
    s2:='OF_REG_GPR or OF_BITS16';
   end else if s2='REG32' then begin
    s2:='OF_REG_GPR or OF_BITS32';
   end else if s2='REG64' then begin
    s2:='OF_REG_GPR or OF_BITS64';
   end else if s2='RM8' then begin
    s2:='OF_RM_GPR or OF_BITS8';
   end else if s2='RM16' then begin
    s2:='OF_RM_GPR or OF_BITS16';
   end else if s2='RM32' then begin
    s2:='OF_RM_GPR or OF_BITS32';
   end else if s2='RM64' then begin
    s2:='OF_RM_GPR or OF_BITS64';
   end else if s2='REG_EA' then begin
    s2:='OF_REG_EA';
   end else if s2='REG_ACCUM' then begin
    s2:='OF_REG_ACCUM';
   end else if s2='REG_SMASK' then begin
    s2:='OF_REG_SMASK';
   end else if s2='REG_AL' then begin
    s2:='OF_REG_AL';
   end else if s2='REG_AX' then begin
    s2:='OF_REG_AX';
   end else if s2='REG_EAX' then begin
    s2:='OF_REG_EAX';
   end else if s2='REG_RAX' then begin
    s2:='OF_REG_RAX';
   end else if s2='REG_COUNT' then begin
    s2:='OF_REG_COUNT';
   end else if s2='REG_CL' then begin
    s2:='OF_REG_CL';
   end else if s2='REG_CX' then begin
    s2:='OF_REG_CX';
   end else if s2='REG_ECX' then begin
    s2:='OF_REG_ECX';
   end else if s2='REG_RCX' then begin
    s2:='OF_REG_RCX';
   end else if s2='REG_DL' then begin
    s2:='OF_REG_DL';
   end else if s2='REG_DX' then begin
    s2:='OF_REG_DX';
   end else if s2='REG_EDX' then begin
    s2:='OF_REG_EDX';
   end else if s2='REG_RDX' then begin
    s2:='OF_REG_RDX';
   end else if s2='REG_HIGH' then begin
    s2:='OF_REG_HIGH';
   end else if s2='REG_NOTACC' then begin
    s2:='OF_REG_NOTACC';
   end else if s2='REG_DS' then begin
    s2:='OF_REG_DS';
   end else if s2='REG_ES' then begin
    s2:='OF_REG_ES';
   end else if s2='REG_FS' then begin
    s2:='OF_REG_FS';
   end else if s2='REG_GS' then begin
    s2:='OF_REG_GS';
   end else if s2='REG_SS' then begin
    s2:='OF_REG_SS';
   end else if s2='REG8NA' then begin
    s2:='OF_REG8NA';
   end else if s2='REG16NA' then begin
    s2:='OF_REG16NA';
   end else if s2='REG32NA' then begin
    s2:='OF_REG32NA';
   end else if s2='REG64NA' then begin
    s2:='OF_REG64NA';
   end else if s2='UNITY' then begin
    s2:='OF_UNITY';
   end else if s2='SBYTE16' then begin
    s2:='OF_SBYTE16';
   end else if s2='SBYTE32' then begin
    s2:='OF_SBYTE32';
   end else if s2='SBYTE64' then begin
    s2:='OF_SBYTE64';
   end else if s2='BYTENESS' then begin
    s2:='OF_BYTENESS';
   end else if s2='SDWORD64' then begin
    s2:='OF_SDWORD64';
   end else if s2='UDWORD64' then begin
    s2:='OF_UDWORD64';
   end else if s2='FPUREG' then begin
    s2:='OF_FPUREG';
   end else if s2='FPU0' then begin
    s2:='OF_FPU0';
   end else if s2='REG_CREG' then begin
    s2:='OF_REG_CREG';
   end else if s2='REG_DREG' then begin
    s2:='OF_REG_DREG';
   end else if s2='REG_TREG' then begin
    s2:='OF_REG_TREG';
   end else if s2='REG_SREG' then begin
    s2:='OF_REG_SREG';
   end else if s2='REG_CS' then begin
    s2:='OF_REG_CS';
   end else if s2='REG_DESS' then begin
    s2:='OF_REG_DESS';
   end else if s2='REG_FSGS' then begin
    s2:='OF_REG_FSGS';
   end else if s2='REG_SEG67' then begin
    s2:='OF_REG_SEG67';
   end else if s2='MMXREG' then begin
    s2:='OF_MMXREG';
   end else if s2='MMXRM' then begin
    s2:='OF_RM_MMX';
   end else if s2='MMXRM8' then begin
    s2:='OF_RM_MMX or OF_BITS8';
   end else if s2='MMXRM16' then begin
    s2:='OF_RM_MMX or OF_BITS16';
   end else if s2='MMXRM32' then begin
    s2:='OF_RM_MMX or OF_BITS32';
   end else if s2='MMXRM64' then begin
    s2:='OF_RM_MMX or OF_BITS64';
   end else if s2='MMXRM128' then begin
    s2:='OF_RM_MMX or OF_BITS128';
   end else if s2='MMXRM256' then begin
    s2:='OF_RM_MMX or OF_BITS256';
   end else if s2='XMM0' then begin
    s2:='OF_XMM0';
   end else if s2='SBYTEWORD' then begin
    s2:='OF_SBYTEWORD';
   end else if s2='SBYTEWORD16' then begin
    s2:='OF_SBYTEWORD or OF_BITS16';
   end else if s2='SBYTEWORD32' then begin
    s2:='OF_SBYTEWORD32 or OF_BITS32';
   end else if s2='SBYTEDWORD' then begin
    s2:='OF_SBYTEDWORD';
   end else if s2='SBYTEDWORD32' then begin
    s2:='OF_SBYTEDWORD or OF_BITS32';
   end else if s2='SBYTEDWORD64' then begin
    s2:='OF_SBYTEDWORD or OF_BITS64';
   end else if s2='UDWORD' then begin
    s2:='OF_UDWORD';
   end else if s2='SDWORD' then begin
    s2:='OF_SDWORD';
   end else if s2='XMEM' then begin
    s2:='OF_XMEM';
   end else if s2='XMEM32' then begin
    s2:='OF_XMEM or OF_BITS32';
   end else if s2='XMEM64' then begin
    s2:='OF_XMEM or OF_BITS64';
   end else if s2='YMEM' then begin
    s2:='OF_YMEM';
   end else if s2='YMEM32' then begin
    s2:='OF_YMEM or OF_BITS32';
   end else if s2='YMEM64' then begin
    s2:='OF_YMEM or OF_BITS64';
   end else if s2='BNDREG' then begin
    s2:='OF_BNDREG';
   end else if s2='KREG' then begin
    s2:='OF_KREG';
   end else if s2='KRM' then begin
    s2:='OF_RM_K';
   end else if s2='KRM8' then begin
    s2:='OF_RM_K or OF_BITS8';
   end else if s2='KRM16' then begin
    s2:='OF_RM_K or OF_BITS16';
   end else if s2='KRM32' then begin
    s2:='OF_RM_K or OF_BITS32';
   end else if s2='KRM64' then begin
    s2:='OF_RM_K or OF_BITS64';
   end else if s2='MEM512' then begin
    s2:='OF_MEMORY or OF_BITS512';
   end else if s2='ZMEM32' then begin
    s2:='OF_ZMEM or OF_BITS32';
   end else if s2='ZMEM64' then begin
    s2:='OF_ZMEM or OF_BITS64';
   end else if s2='ZMEM512' then begin
    s2:='OF_ZMEM or OF_BITS512';
   end else if s2='B32' then begin
    s2:='';
   end else if s2='B64' then begin
    s2:='';
   end else if s2='MASK' then begin
    s2:='';
   end else if s2='Z' then begin
    s2:='';
   end else if s2='ER' then begin
    s2:='';
   end else if s2='SAE' then begin
    s2:='';
   end else begin
    if pos('evex.',Sequence)=0 then begin
     if s2='XMMREG' then begin
      s2:='OF_XMM_L16';
     end else if s2='XMMRM' then begin
      s2:='OF_RM_XMM_L16';
     end else if s2='XMMRM16' then begin
      s2:='OF_RM_XMM_L16 or OF_BITS16';
     end else if s2='XMMRM32' then begin
      s2:='OF_RM_XMM_L16 or OF_BITS32';
     end else if s2='XMMRM64' then begin
      s2:='OF_RM_XMM_L16 or OF_BITS64';
     end else if s2='XMMRM128' then begin
      s2:='OF_RM_XMM_L16 or OF_BITS128';
     end else if s2='XMMRM256' then begin
      s2:='OF_RM_XMM_L16 or OF_BITS256';
     end else if s2='XMMRM512' then begin
      s2:='OF_RM_XMM_L16 or OF_BITS512';
     end else if s2='YMMREG' then begin
      s2:='OF_YMM_L16';
     end else if s2='YMMRM' then begin
      s2:='OF_RM_YMM_L16';
     end else if s2='YMMRM16' then begin
      s2:='OF_RM_YMM_L16 or OF_BITS16';
     end else if s2='YMMRM32' then begin
      s2:='OF_RM_YMM_L16 or OF_BITS32';
     end else if s2='YMMRM64' then begin
      s2:='OF_RM_YMM_L16 or OF_BITS64';
     end else if s2='YMMRM128' then begin
      s2:='OF_RM_YMM_L16 or OF_BITS128';
     end else if s2='YMMRM256' then begin
      s2:='OF_RM_YMM_L16 or OF_BITS256';
     end else if s2='YMMRM512' then begin
      s2:='OF_RM_YMM_L16 or OF_BITS512';
     end else if s2='ZMMREG' then begin
      s2:='OF_ZMM_L16';
     end else if s2='ZMMRM16' then begin
      s2:='OF_RM_ZMM_L16 or OF_BITS16';
     end else if s2='ZMMRM32' then begin
      s2:='OF_RM_ZMM_L16 or OF_BITS32';
     end else if s2='ZMMRM64' then begin
      s2:='OF_RM_ZMM_L16 or OF_BITS64';
     end else if s2='ZMMRM128' then begin
      s2:='OF_RM_ZMM_L16 or OF_BITS128';
     end else if s2='ZMMRM256' then begin
      s2:='OF_RM_ZMM_L16 or OF_BITS256';
     end else if s2='ZMMRM512' then begin
      s2:='OF_RM_ZMM_L16 or OF_BITS512';
     end else begin
      writeln(s2);
      readln;
      halt(1);
     end;
    end else begin
     if s2='XMMREG' then begin
      s2:='OF_XMMREG';
     end else if s2='XMMRM' then begin
      s2:='OF_RM_XMM';
     end else if s2='XMMRM8' then begin
      s2:='OF_RM_XMM or OF_BITS8';
     end else if s2='XMMRM16' then begin
      s2:='OF_RM_XMM or OF_BITS16';
     end else if s2='XMMRM32' then begin
      s2:='OF_RM_XMM or OF_BITS32';
     end else if s2='XMMRM64' then begin
      s2:='OF_RM_XMM or OF_BITS64';
     end else if s2='XMMRM128' then begin
      s2:='OF_RM_XMM or OF_BITS128';
     end else if s2='XMMRM256' then begin
      s2:='OF_RM_XMM or OF_BITS256';
     end else if s2='XMMRM512' then begin
      s2:='OF_RM_XMM or OF_BITS512';
     end else if s2='YMMREG' then begin
      s2:='OF_YMMREG';
     end else if s2='YMMRM' then begin
      s2:='OF_RM_YMM';
     end else if s2='YMMRM8' then begin
      s2:='OF_RM_YMM or OF_BITS8';
     end else if s2='YMMRM16' then begin
      s2:='OF_RM_YMM or OF_BITS16';
     end else if s2='YMMRM32' then begin
      s2:='OF_RM_YMM or OF_BITS32';
     end else if s2='YMMRM64' then begin
      s2:='OF_RM_YMM or OF_BITS64';
     end else if s2='YMMRM128' then begin
      s2:='OF_RM_YMM or OF_BITS128';
     end else if s2='YMMRM256' then begin
      s2:='OF_RM_YMM or OF_BITS256';
     end else if s2='YMMRM512' then begin
      s2:='OF_RM_YMM or OF_BITS512';
     end else if s2='ZMMREG' then begin
      s2:='OF_ZMMREG';
     end else if s2='ZMMRM8' then begin
      s2:='OF_RM_ZMM or OF_BITS8';
     end else if s2='ZMMRM16' then begin
      s2:='OF_RM_ZMM or OF_BITS16';
     end else if s2='ZMMRM32' then begin
      s2:='OF_RM_ZMM or OF_BITS32';
     end else if s2='ZMMRM64' then begin
      s2:='OF_RM_ZMM or OF_BITS64';
     end else if s2='ZMMRM128' then begin
      s2:='OF_RM_ZMM or OF_BITS128';
     end else if s2='ZMMRM256' then begin
      s2:='OF_RM_ZMM or OF_BITS256';
     end else if s2='ZMMRM512' then begin
      s2:='OF_RM_ZMM or OF_BITS512';
     end else begin
      writeln(s2);
      readln;
      halt(1);
     end;
    end;
   end;
   if length(s2)>0 then begin
    if length(s3)>0 then begin
     s3:=s3+' or ';
    end;
    s3:=s3+s2;
   end;
  end;
  Instruction^.Operands[i]:=s3;
 end;
 if (CountOperands=1) and (Instruction^.Operands[0]='OF_VOID') then begin
  Instruction.CountOperands:=0;
 end;

 Instruction^.Sequence:=CodeSequence;
 Instruction^.SequenceLength:=SequenceLength;

 Instruction^.Flags:=IFlags;

end;

procedure AddRegister(const RegisterName,RegisterClass:ansistring;const RegisterNumber:longint;const RegisterFlags:ansistring);
var Index:longint;
    ARegister:PRegister;
begin
 Index:=CountRegisters;
 inc(CountRegisters);
 if CountRegisters>length(Registers) then begin
  SetLength(Registers,CountRegisters*2);
 end;
 ARegister:=@Registers[Index];
 ARegister^.RegisterName:=RegisterName;
 ARegister^.RegisterClass:=RegisterClass;
 ARegister^.RegisterNumber:=RegisterNumber;
 if length(trim(RegisterFlags))>0 then begin
  ARegister^.RegisterFlags:=RegisterFlags;
 end else begin
  ARegister^.RegisterFlags:='0';
 end;
end;

procedure ConvertImportByHashCode;
var Src:file;
    Dst:TEXT;
    B,C:byte;
    S:string;
begin
 assignfile(Src,'x86ibhcode.dat');
 {$I-}reset(Src,1);{$I+}
 if IOResult=0 then begin
  assignfile(Dst,'x86ibhcode.inc');
  {$I-}rewrite(Dst);{$I+}
  if IOResult=0 then begin
   writeln(Dst,FileHint);
   writeln(Dst,'const IBHCodeSize=',FILESIZE(Src),';');
   write(Dst,'      IBHCodeData:array[1..IBHCodeSize] of byte=(');
   C:=0;
   while not eof(Src) do begin
    blockread(Src,B,1);
    str(B,S);
    if FILESIZE(Src)<>FILEPOS(Src) then S:=S+',';
    C:=C+length(S);
    write(Dst,S);
    if C>40 then begin
     if FILESIZE(Src)<>FILEPOS(Src) then begin
      writeln(Dst);
      write(Dst,'                                                 ');
     end;
     C:=0;
    end;
   end;
   writeln(Dst,');');
   closefile(Dst);
  end;
  closefile(Src);
 end;
end;

var Lines:TStringList;
    LineIndex,OperandsLength,i,j,k,h,CountOperands,OpMask,RegisterNumber:longint;
    Line,Opcode,Operands,OperandEncoding,OperandTuple,Sequence,Flags,s,s2,s3,RegisterName,RegisterClass:ansistring;
    Keywords:TStringList;
    KeywordKinds:TStringList;
    Prefixes:TStringList;
    Relaxed:boolean;
    OperandArray:array[0..MaxOperands-1] of ansistring;
    TempOperandArray:array[0..MaxOperands-1] of ansistring;
    OperandRelaxed:array[0..MaxOperands-1] of boolean;
    Instruction:TInstruction;
    OutFile:TextFile;
begin
 GenerateOpFlags;
 ConvertImportByHashCode;
 Instructions:=nil;
 CountInstructions:=0;
 try

  Registers:=nil;
  CountRegisters:=0;
  try

   IFlagBits:=nil;
   CountIFlagBits:=0;
   try

    RecordedIFlags:=nil;
    CountRecordedIFlags:=0;
    try

     begin
      AddIFlagBit('SM',0,'Size match');
      AddIFlagBit('SM2',1,'Size match first two operands');
      AddIFlagBit('SB',2,'Unsized operands can''t be non-byte');
      AddIFlagBit('SW',3,'Unsized operands can''t be non-word');
      AddIFlagBit('SD',4,'Unsized operands can''t be non-dword');
      AddIFlagBit('SQ',5,'Unsized operands can''t be non-qword');
      AddIFlagBit('SO',6,'Unsized operands can''t be non-oword');
      AddIFlagBit('SY',7,'Unsized operands can''t be non-yword');
      AddIFlagBit('SZ',8,'Unsized operands can''t be non-zword');
      AddIFlagBit('SIZE',9,'Unsized operands must match the bitsize');
      AddIFlagBit('SX',10,'Unsized operands not allowed');
      AddIFlagBit('AR0',11,'SB,SW,SD applies to argument 0');
      AddIFlagBit('AR1',12,'SB,SW,SD applies to argument 1');
      AddIFlagBit('AR2',13,'SB,SW,SD applies to argument 2');
      AddIFlagBit('AR3',14,'SB,SW,SD applies to argument 3');
      AddIFlagBit('AR4',15,'SB,SW,SD applies to argument 4');
      AddIFlagBit('OPT',16,'Optimizing assembly only');
      AddIFlagBit('PRIV',32,'Privileged instruction');
      AddIFlagBit('SMM',33,'Only valid in SMM');
      AddIFlagBit('PROT',34,'Protected mode only');
      AddIFlagBit('LOCK',35,'Lockable if operand 0 is memory');
      AddIFlagBit('NOLONG',36,'Not available in long mode');
      AddIFlagBit('LONG',37,'Long mode');
      AddIFlagBit('NOHLE',38,'HLE prefixes forbidden');
      AddIFlagBit('MIB',39,'disassemble with split EA');
      AddIFlagBit('BND',40,'BND (0xF2) prefix available');
      AddIFlagBit('UNDOC',41,'Undocumented');
      AddIFlagBit('HLE',42,'HLE prefixed');
      AddIFlagBit('FPU',43,'FPU');
      AddIFlagBit('MMX',44,'MMX');
      AddIFlagBit('3DNOW',45,'3DNow!');
      AddIFlagBit('SSE',46,'SSE (KNI,MMX2)');
      AddIFlagBit('SSE2',47,'SSE2');
      AddIFlagBit('SSE3',48,'SSE3 (PNI)');
      AddIFlagBit('VMX',49,'VMX');
      AddIFlagBit('SSSE3',50,'SSSE3');
      AddIFlagBit('SSE4A',51,'AMD SSE4a');
      AddIFlagBit('SSE41',52,'SSE4.1');
      AddIFlagBit('SSE42',53,'SSE4.2');
      AddIFlagBit('SSE5',54,'SSE5');
      AddIFlagBit('AVX',55,'AVX (128b)');
      AddIFlagBit('AVX2',56,'AVX2 (256b)');
      AddIFlagBit('FMA',57,'');
      AddIFlagBit('BMI1',58,'');
      AddIFlagBit('BMI2',59,'');
      AddIFlagBit('TBM',60,'');
      AddIFlagBit('RTM',61,'');
      AddIFlagBit('INVPCID',62,'');
      AddIFlagBit('AVX512',64,'AVX-512F (512b)');
      AddIFlagBit('AVX512CD',65,'AVX-512 Conflict Detection');
      AddIFlagBit('AVX512ER',66,'AVX-512 Exponential and Reciprocal');
      AddIFlagBit('AVX512PF',67,'AVX-512 Prefetch');
      AddIFlagBit('MPX',68,'MPX');
      AddIFlagBit('SHA',69,'SHA');
      AddIFlagBit('PREFETCHWT1',70,'PREFETCHWT1');
      AddIFlagBit('AVX512VL',71,'AVX-512 Vector Length Orthogonality');
      AddIFlagBit('AVX512DQ',72,'AVX-512 Dword and Qword');
      AddIFlagBit('AVX512BW',73,'AVX-512 Byte and Word');
      AddIFlagBit('AVX512IFMA',74,'AVX-512 IFMA instructions');
      AddIFlagBit('AVX512VBMI',75,'AVX-512 VBMI instructions');
      AddIFlagBit('OBSOLETE',93,'Instruction removed from architecture');
      AddIFlagBit('VEX',94,'VEX or XOP encoded instruction');
      AddIFlagBit('EVEX',95,'EVEX encoded instruction');
      AddIFlagBit('8086',96,'8086');
      AddIFlagBit('186',97,'186+');
      AddIFlagBit('286',98,'286+');
      AddIFlagBit('386',99,'386+');
      AddIFlagBit('486',100,'486+');
      AddIFlagBit('PENT',101,'Pentium');
      AddIFlagBit('P6',102,'P6');
      AddIFlagBit('KATMAI',103,'Katmai');
      AddIFlagBit('WILLAMETTE',104,'Willamette');
      AddIFlagBit('PRESCOTT',105,'Prescott');
      AddIFlagBit('X86_64',106,'x86-64 (long or legacy mode)');
      AddIFlagBit('NEHALEM',107,'Nehalem');
      AddIFlagBit('WESTMERE',108,'Westmere');
      AddIFlagBit('SANDYBRIDGE',109,'Sandy Bridge');
      AddIFlagBit('FUTURE',110,'Future processor (not yet disclosed)');
      AddIFlagBit('IA64',111,'IA64 (in x86 mode)');
      AddIFlagBit('CYRIX',126,'Cyrix-specific');
      AddIFlagBit('AMD',127,'AMD-specific');
      SetLength(IFlagBits,CountIFlagBits);
      MaxIFlagBit:=0;
      for i:=0 to CountIFlagBits-1 do begin
       MaxIFlagBit:=Max(MaxIFlagBit,IFlagBits[i].Bit);
      end;
      IFlagDWords:=(MaxIFlagBit shr 5)+1;
      if IFlagDWords>0 then begin
      end;
     end;

     InstructionRanges:=nil;
     try

      Keywords:=TStringList.Create;
      KeywordKinds:=TStringList.Create;
      try

       Prefixes:=TStringList.Create;
       try

        Lines:=TStringList.Create;
        try
         Lines.LoadFromFile('x86ins.txt');
         for LineIndex:=0 to Lines.Count-1 do begin
          Line:=trim(Lines[LineIndex]);

          i:=1;

          for j:=0 to MaxOperands-1 do begin
           OperandArray[j]:='';
           OperandRelaxed[j]:=false;
          end;
          
          Opcode:=trim(Parse(Line,[#1..#32],i,true));
          Operands:=trim(Parse(Line,[#1..#32],i,true));
          Parse(Line,['['],i,true);
          Sequence:=trim(Parse(Line,[']'],i,true));
          j:=pos(':',Sequence);
          if j>0 then begin
           OperandEncoding:=copy(Sequence,1,j-1);
           Delete(Sequence,1,j);
           Sequence:=trim(Sequence);
           j:=pos(':',Sequence);
           if j>0 then begin
            OperandTuple:=LowerCase(copy(Sequence,1,j-1));
            Delete(Sequence,1,j);
            Sequence:=trim(Sequence);
           end else begin
            OperandTuple:='';
           end;
          end else begin
           OperandEncoding:='';
           OperandTuple:='';
          end;
          Parse(Line,[#1..#32],i,true);
          Flags:=trim(Parse(Line,[#1..#32],i,true));

          Operands:=StringReplace(Operands,':','|colon,',[rfReplaceAll]);
          OperandsLength:=length(Operands);

          Relaxed:=false;
          h:=0;
          i:=1;
          while i<=OperandsLength do begin
           s:=trim(Parse(Operands,[','],i,false));
           if pos('*',s)>0 then begin
            OperandRelaxed[h]:=true;
            s:=StringReplace(s,'*','',[rfReplaceAll]);
           end else begin
            OperandRelaxed[h]:=false;
           end;
           OperandArray[h]:=s;
           inc(h);
          end;
          CountOperands:=h;
          while h<MaxOperands do begin
           OperandArray[h]:='';
           inc(h);
          end;
          if (length(Opcode)>2) and ((Opcode[length(Opcode)-1]='c') and (Opcode[length(Opcode)]='c')) then begin
           for i:=low(Conditions) to high(Conditions) do begin
            AddInstruction(copy(Opcode,1,length(Opcode)-2)+Conditions[i].Name,OperandArray[0],OperandArray[1],OperandArray[2],OperandArray[3],OperandArray[4],OperandEncoding,OperandTuple,Sequence,Flags,CountOperands,0,Conditions[i].Code);
           end;
          end else begin
           AddInstruction(Opcode,OperandArray[0],OperandArray[1],OperandArray[2],OperandArray[3],OperandArray[4],OperandEncoding,OperandTuple,Sequence,Flags,CountOperands,0,0);
           if Relaxed then begin
            OpMask:=0;
            for i:=0 to CountOperands-1 do begin
             if OperandRelaxed[i] then begin
              OpMask:=OpMask or (1 shl i);
             end;
            end;
            for i:=1 to (1 shl CountOperands)-1 do begin
             if (i and not OpMask)=0 then begin
              k:=not i;
              h:=0;
              for j:=0 to CountOperands-1 do begin
               if (k and 1)<>0 then begin
                TempOperandArray[h]:=OperandArray[j];
                inc(h);
               end;
               k:=k shr 1;
              end;
              k:=h;
              while h<MaxOperands do begin
               TempOperandArray[h]:='';
               inc(h);
              end;
              AddInstruction(Opcode,TempOperandArray[0],TempOperandArray[1],TempOperandArray[2],TempOperandArray[3],TempOperandArray[4],OperandEncoding,OperandTuple,Sequence,Flags,k,i,0);
             end;
            end;
           end;
          end;

         end;
        finally
         Lines.Free;
        end;
        SetLength(Instructions,CountInstructions);
        SetLength(PInstructions,CountInstructions);
        for i:=0 to CountInstructions-1 do begin
         PInstructions[i]:=@Instructions[i];
        end;
        IndirectIntroSort(@PInstructions[0],0,CountInstructions-1,@SortInstructions);

        Lines:=TStringList.Create;
        try
         Lines.LoadFromFile('x86regs.txt');
         for LineIndex:=0 to Lines.Count-1 do begin
          Line:=trim(Lines[LineIndex]);
          i:=1;

          RegisterName:=UpperCase(trim(Parse(Line,[#1..#32],i,true)));
          RegisterClass:=trim(Parse(Line,[#1..#32],i,true));
          //Parse(Line,[#1..#32],i,true);
          RegisterNumber:=StrToIntDef(trim(Parse(Line,[#1..#32],i,true)),0);
          Flags:=trim(Parse(Line,[#1..#32],i,true));

          i:=pos('-',RegisterName);
          if i>0 then begin
           k:=0;
           h:=0;
           for j:=i-1 downto 1 do begin
            if RegisterName[j] in ['0'..'9'] then begin
             k:=j;
            end else begin
             break;
            end;
           end;
           for j:=i+1 to length(RegisterName) do begin
            if RegisterName[j] in ['0'..'9'] then begin
             h:=j;
            end else begin
             break;
            end;
           end;
           s:=copy(RegisterName,h+1,length(RegisterName)-h);
           j:=k;
           k:=StrToIntDef(copy(RegisterName,k,i-k),0);
           h:=StrToIntDef(copy(RegisterName,i+1,h-i),0);
           RegisterName:=copy(RegisterName,1,j-1);
           for i:=k to h do begin
            AddRegister(RegisterName+IntToStr(i)+s,RegisterClass,RegisterNumber,Flags);
            inc(RegisterNumber);
           end;
          end else begin
           AddRegister(RegisterName,RegisterClass,RegisterNumber,Flags);
          end;
         end;
        finally
         Lines.Free;
        end;
        SetLength(Registers,CountRegisters);

        Lines:=TStringList.Create;
        try
         Lines.LoadFromFile('x86keywords.txt');
         Lines.Sort;
         for LineIndex:=0 to Lines.Count-1 do begin
          Line:=trim(Lines[LineIndex]);
          i:=1;
          Keywords.Add(UpperCase(trim(Parse(Line,[' '],i,true))));
          KeywordKinds.Add(UpperCase(trim(Parse(Line,[';'],i,true))));
         end;
        finally
         Lines.Free;
        end;

        Lines:=TStringList.Create;
        try
         Lines.LoadFromFile('x86prefixes.txt');
         for LineIndex:=0 to Lines.Count-1 do begin
          Line:=trim(Lines[LineIndex]);
          i:=1;
          Prefixes.Add(UpperCase(trim(Parse(Line,[';'],i,false))));
         end;
        finally
         Lines.Free;
        end;
        Prefixes.Sort;

        InstructionNames:=TStringList.Create;
        try

         MaxInstructionTemplateSequenceLength:=1;
         for i:=0 to CountInstructions-1 do begin
          if MaxInstructionTemplateSequenceLength<PInstructions[i]^.SequenceLength then begin
           MaxInstructionTemplateSequenceLength:=PInstructions[i]^.SequenceLength;
          end;
          if InstructionNames.IndexOf(PInstructions[i]^.Name)<0 then begin
           InstructionNames.Add(PInstructions[i]^.Name);
          end;
         end;
         InstructionNames.Sort;
         SetLength(InstructionRanges,InstructionNames.Count);
         for i:=0 to InstructionNames.Count-1 do begin
          InstructionRanges[i,0]:=-1;
          InstructionRanges[i,1]:=-1;
          InstructionRanges[i,2]:=0;
          InstructionRanges[i,3]:=0;
         end;
         for i:=0 to CountInstructions-1 do begin
          j:=InstructionNames.IndexOf(PInstructions[i]^.Name);
          if InstructionRanges[j,0]<0 then begin
           InstructionRanges[j,0]:=i;
          end;
          InstructionRanges[j,1]:=i;
          k:=0;
          for h:=0 to PInstructions[i]^.CountOperands-1 do begin
           if pos('256',PInstructions[i]^.Operands[h])>0 then begin
            if k<256 then begin
             k:=256;
            end;
           end else if pos('128',PInstructions[i]^.Operands[h])>0 then begin
            if k<128 then begin
             k:=128;
            end;
           end else if pos('64',PInstructions[i]^.Operands[h])>0 then begin
            if k<64 then begin
             k:=64;
            end;
           end else if pos('32',PInstructions[i]^.Operands[h])>0 then begin
            if k<32 then begin
             k:=32;
            end;
           end else if pos('16',PInstructions[i]^.Operands[h])>0 then begin
            if k<16 then begin
             k:=16;
            end;
           end else if pos('8',PInstructions[i]^.Operands[h])>0 then begin
            if k<8 then begin
             k:=8;
            end;
           end;
          end;
          if InstructionRanges[j,2]<k then begin
           InstructionRanges[j,2]:=k;
          end;
          if InstructionRanges[j,3]<PInstructions[i]^.CountOperands then begin
           InstructionRanges[j,3]:=PInstructions[i]^.CountOperands;
          end;
         end;

         AddIFlags([]);

         AssignFile(OutFile,'SASMDataContent.inc');
         Rewrite(OutFile);
         writeln(OutFile,FileHint);
         writeln(OutFile,'const CountInstructionTemplates=',CountInstructions,';');
         writeln(OutFile,'      CountOpcodes=',InstructionNames.Count+1,';');
         writeln(OutFile,'      CountKeywords=',Keywords.Count+1,';');
         writeln(OutFile,'      CountPrefixes=',Prefixes.Count+1,';');
         writeln(OutFile,'      CountRegisterTemplates=',CountRegisters,';');
         writeln(OutFile,'      MaxInstructionTemplateOperands=',MaxOperands,';');
         writeln(OutFile,'      MaxInstructionTemplateSequenceLength=',MaxInstructionTemplateSequenceLength,';');
         writeln(OutFile,'      OPTYPE_SHIFT=0;');
         writeln(OutFile,'      OPTYPE_BITS=4;');
         writeln(OutFile,'      OPTYPE_MASK=((uint64(1) shl OPTYPE_BITS)-1) shl OPTYPE_SHIFT;');
         writeln(OutFile,'      MODIFIER_SHIFT=4;');
         writeln(OutFile,'      MODIFIER_BITS=3;');
         writeln(OutFile,'      MODIFIER_MASK=((uint64(1) shl MODIFIER_BITS)-1) shl MODIFIER_SHIFT;');
         writeln(OutFile,'      REG_CLASS_SHIFT=7;');
         writeln(OutFile,'      REG_CLASS_BITS=10;');
         writeln(OutFile,'      REG_CLASS_MASK=((uint64(1) shl REG_CLASS_BITS)-1) shl REG_CLASS_SHIFT;');
         writeln(OutFile,'      SUBCLASS_SHIFT=17;');
         writeln(OutFile,'      SUBCLASS_BITS=8;');
         writeln(OutFile,'      SUBCLASS_MASK=((uint64(1) shl SUBCLASS_BITS)-1) shl SUBCLASS_SHIFT;');
         writeln(OutFile,'      SPECIAL_SHIFT=25;');
         writeln(OutFile,'      SPECIAL_BITS=7;');
         writeln(OutFile,'      SPECIAL_MASK=((uint64(1) shl SPECIAL_BITS)-1) shl SPECIAL_SHIFT;');
         writeln(OutFile,'      SIZE_SHIFT=32;');
         writeln(OutFile,'      SIZE_BITS=11;');
         writeln(OutFile,'      SIZE_MASK=((uint64(1) shl SIZE_BITS)-1) shl SIZE_SHIFT;');
         writeln(OutFile,'      OPMASK_SHIFT=0;');
         writeln(OutFile,'      OPMASK_BITS=4;');
         writeln(OutFile,'      OPMASK_MASK=((uint64(1) shl OPMASK_BITS)-1) shl OPMASK_SHIFT;');
         writeln(OutFile,'      OPMASK_K0=(uint64(0) shl OPMASK_SHIFT) and OPMASK_MASK;');
         writeln(OutFile,'      OPMASK_K1=(uint64(1) shl OPMASK_SHIFT) and OPMASK_MASK;');
         writeln(OutFile,'      OPMASK_K2=(uint64(2) shl OPMASK_SHIFT) and OPMASK_MASK;');
         writeln(OutFile,'      OPMASK_K3=(uint64(3) shl OPMASK_SHIFT) and OPMASK_MASK;');
         writeln(OutFile,'      OPMASK_K4=(uint64(4) shl OPMASK_SHIFT) and OPMASK_MASK;');
         writeln(OutFile,'      OPMASK_K5=(uint64(5) shl OPMASK_SHIFT) and OPMASK_MASK;');
         writeln(OutFile,'      OPMASK_K6=(uint64(6) shl OPMASK_SHIFT) and OPMASK_MASK;');
         writeln(OutFile,'      OPMASK_K7=(uint64(7) shl OPMASK_SHIFT) and OPMASK_MASK;');
         writeln(OutFile,'      Z_SHIFT=4;');
         writeln(OutFile,'      Z_BITS=1;');
         writeln(OutFile,'      Z_MASK=((uint64(1) shl Z_BITS)-1) shl Z_SHIFT;');
         writeln(OutFile,'      Z_VAL0=(uint64(1) shl Z_SHIFT) and Z_MASK;');
         writeln(OutFile,'      BRDCAST_SHIFT=5;');
         writeln(OutFile,'      BRDCAST_BITS=1;');
         writeln(OutFile,'      BRDCAST_MASK=((uint64(1) shl BRDCAST_BITS)-1) shl BRDCAST_SHIFT;');
         writeln(OutFile,'      BRDCAST_VAL0=(uint64(1) shl BRDCAST_SHIFT) and BRDCAST_MASK;');
         writeln(OutFile,'      STATICRND_SHIFT=6;');
         writeln(OutFile,'      STATICRND_BITS=1;');
         writeln(OutFile,'      STATICRND_MASK=((uint64(1) shl STATICRND_BITS)-1) shl STATICRND_SHIFT;');
         writeln(OutFile,'      SAE_SHIFT=7;');
         writeln(OutFile,'      SAE_BITS=1;');
         writeln(OutFile,'      SAE_MASK=((uint64(1) shl SAE_BITS)-1) shl SAE_SHIFT;');
         writeln(OutFile,'      BRSIZE_SHIFT=8;');
         writeln(OutFile,'      BRSIZE_BITS=2;');
         writeln(OutFile,'      BRSIZE_MASK=((uint64(1) shl BRSIZE_BITS)-1) shl BRSIZE_SHIFT;');
         writeln(OutFile,'      BR_BITS32=uint64(1) shl (BRSIZE_SHIFT+0);');
         writeln(OutFile,'      BR_BITS64=uint64(1) shl (BRSIZE_SHIFT+1);');
         writeln(OutFile,'      BRNUM_SHIFT=10;');
         writeln(OutFile,'      BRNUM_BITS=2;');
         writeln(OutFile,'      BRNUM_MASK=((uint64(1) shl BRNUM_BITS)-1) shl BRNUM_SHIFT;');
         writeln(OutFile,'      BR_1TO2=(0 shl BRNUM_SHIFT) and BRNUM_MASK;');
         writeln(OutFile,'      BR_1TO4=(1 shl BRNUM_SHIFT) and BRNUM_MASK;');
         writeln(OutFile,'      BR_1TO8=(2 shl BRNUM_SHIFT) and BRNUM_MASK;');
         writeln(OutFile,'      BR_1TO16=(3 shl BRNUM_SHIFT) and BRNUM_MASK;');
         writeln(OutFile,'      ODF_MASK=OPMASK_MASK;');
         writeln(OutFile,'      ODF_Z=Z_MASK;');
         writeln(OutFile,'      ODF_B32=BRDCAST_MASK or BR_BITS32;');
         writeln(OutFile,'      ODF_B64=BRDCAST_MASK or BR_BITS64;');
         writeln(OutFile,'      ODF_ER=STATICRND_MASK;');
         writeln(OutFile,'      ODF_SAE=SAE_MASK;');
         writeln(OutFile,'      TFLAG_BRC=1;');
         writeln(OutFile,'      TFLAG_BRC_OPT=2;');
         writeln(OutFile,'      TFLAG_BRC_ANY=TFLAG_BRC or TFLAG_BRC_OPT;');
         writeln(OutFile,'      TFLAG_BRDCAST=4;');
         for i:=0 to CountIFlagBits-1 do begin
          writeln(OutFile,'      IF_',IFlagBits[i].Name,'=',IFlagBits[i].Bit,';');
         end;
         writeln(OutFile,'      OF_REGISTER=uint64($',UInt64ToHex(OF_REGISTER),');');
         writeln(OutFile,'      OF_IMMEDIATE=uint64($',UInt64ToHex(OF_IMMEDIATE),');');
         writeln(OutFile,'      OF_REGMEM=uint64($',UInt64ToHex(OF_REGMEM),');');
         writeln(OutFile,'      OF_MEMORY=uint64($',UInt64ToHex(OF_MEMORY),');');
         writeln(OutFile,'      OF_BITS8=uint64($',UInt64ToHex(OF_BITS8),');');
         writeln(OutFile,'      OF_BITS16=uint64($',UInt64ToHex(OF_BITS16),');');
         writeln(OutFile,'      OF_BITS32=uint64($',UInt64ToHex(OF_BITS32),');');
         writeln(OutFile,'      OF_BITS64=uint64($',UInt64ToHex(OF_BITS64),');');
         writeln(OutFile,'      OF_BITS80=uint64($',UInt64ToHex(OF_BITS80),');');
         writeln(OutFile,'      OF_BITS128=uint64($',UInt64ToHex(OF_BITS128),');');
         writeln(OutFile,'      OF_BITS256=uint64($',UInt64ToHex(OF_BITS256),');');
         writeln(OutFile,'      OF_BITS512=uint64($',UInt64ToHex(OF_BITS512),');');
         writeln(OutFile,'      OF_FAR=uint64($',UInt64ToHex(OF_FAR),');');
         writeln(OutFile,'      OF_NEAR=uint64($',UInt64ToHex(OF_NEAR),');');
         writeln(OutFile,'      OF_SHORT=uint64($',UInt64ToHex(OF_SHORT),');');
         writeln(OutFile,'      OF_TO=uint64($',UInt64ToHex(OF_TO),');');
         writeln(OutFile,'      OF_COLON=uint64($',UInt64ToHex(OF_COLON),');');
         writeln(OutFile,'      OF_STRICT=uint64($',UInt64ToHex(OF_STRICT),');');
         writeln(OutFile,'      OF_REG_CLASS_CDT=uint64($',UInt64ToHex(OF_REG_CLASS_CDT),');');
         writeln(OutFile,'      OF_REG_CLASS_GPR=uint64($',UInt64ToHex(OF_REG_CLASS_GPR),');');
         writeln(OutFile,'      OF_REG_CLASS_SREG=uint64($',UInt64ToHex(OF_REG_CLASS_SREG),');');
         writeln(OutFile,'      OF_REG_CLASS_FPUREG=uint64($',UInt64ToHex(OF_REG_CLASS_FPUREG),');');
         writeln(OutFile,'      OF_REG_CLASS_RM_MMX=uint64($',UInt64ToHex(OF_REG_CLASS_RM_MMX),');');
         writeln(OutFile,'      OF_REG_CLASS_RM_XMM=uint64($',UInt64ToHex(OF_REG_CLASS_RM_XMM),');');
         writeln(OutFile,'      OF_REG_CLASS_RM_YMM=uint64($',UInt64ToHex(OF_REG_CLASS_RM_YMM),');');
         writeln(OutFile,'      OF_REG_CLASS_RM_ZMM=uint64($',UInt64ToHex(OF_REG_CLASS_RM_ZMM),');');
         writeln(OutFile,'      OF_REG_CLASS_OPMASK=uint64($',UInt64ToHex(OF_REG_CLASS_OPMASK),');');
         writeln(OutFile,'      OF_REG_CLASS_BND=uint64($',UInt64ToHex(OF_REG_CLASS_BND),');');
         writeln(OutFile,'      OF_REG_EA=uint64($',UInt64ToHex(OF_REG_EA),');');
         writeln(OutFile,'      OF_RM_GPR=uint64($',UInt64ToHex(OF_RM_GPR),');');
         writeln(OutFile,'      OF_REG_GPR=uint64($',UInt64ToHex(OF_REG_GPR),');');
         writeln(OutFile,'      OF_REG8=uint64($',UInt64ToHex(OF_REG8),');');
         writeln(OutFile,'      OF_REG16=uint64($',UInt64ToHex(OF_REG16),');');
         writeln(OutFile,'      OF_REG32=uint64($',UInt64ToHex(OF_REG32),');');
         writeln(OutFile,'      OF_REG64=uint64($',UInt64ToHex(OF_REG64),');');
         writeln(OutFile,'      OF_FPUREG=uint64($',UInt64ToHex(OF_FPUREG),');');
         writeln(OutFile,'      OF_FPU0=uint64($',UInt64ToHex(OF_FPU0),');');
         writeln(OutFile,'      OF_RM_MMX=uint64($',UInt64ToHex(OF_RM_MMX),');');
         writeln(OutFile,'      OF_MMXREG=uint64($',UInt64ToHex(OF_MMXREG),');');
         writeln(OutFile,'      OF_RM_XMM=uint64($',UInt64ToHex(OF_RM_XMM),');');
         writeln(OutFile,'      OF_XMMREG=uint64($',UInt64ToHex(OF_XMMREG),');');
         writeln(OutFile,'      OF_RM_YMM=uint64($',UInt64ToHex(OF_RM_YMM),');');
         writeln(OutFile,'      OF_YMMREG=uint64($',UInt64ToHex(OF_YMMREG),');');
         writeln(OutFile,'      OF_RM_ZMM=uint64($',UInt64ToHex(OF_RM_ZMM),');');
         writeln(OutFile,'      OF_ZMMREG=uint64($',UInt64ToHex(OF_ZMMREG),');');
         writeln(OutFile,'      OF_RM_OPMASK=uint64($',UInt64ToHex(OF_RM_OPMASK),');');
         writeln(OutFile,'      OF_OPMASKREG=uint64($',UInt64ToHex(OF_OPMASKREG),');');
         writeln(OutFile,'      OF_OPMASK0=uint64($',UInt64ToHex(OF_OPMASK0),');');
         writeln(OutFile,'      OF_RM_K=uint64($',UInt64ToHex(OF_RM_K),');');
         writeln(OutFile,'      OF_KREG=uint64($',UInt64ToHex(OF_KREG),');');
         writeln(OutFile,'      OF_RM_BND=uint64($',UInt64ToHex(OF_RM_BND),');');
         writeln(OutFile,'      OF_BNDREG=uint64($',UInt64ToHex(OF_BNDREG),');');
         writeln(OutFile,'      OF_REG_CDT=uint64($',UInt64ToHex(OF_REG_CDT),');');
         writeln(OutFile,'      OF_REG_CREG=uint64($',UInt64ToHex(OF_REG_CREG),');');
         writeln(OutFile,'      OF_REG_DREG=uint64($',UInt64ToHex(OF_REG_DREG),');');
         writeln(OutFile,'      OF_REG_TREG=uint64($',UInt64ToHex(OF_REG_TREG),');');
         writeln(OutFile,'      OF_REG_SREG=uint64($',UInt64ToHex(OF_REG_SREG),');');
         writeln(OutFile,'      OF_REG_ES=uint64($',UInt64ToHex(OF_REG_ES),');');
         writeln(OutFile,'      OF_REG_CS=uint64($',UInt64ToHex(OF_REG_CS),');');
         writeln(OutFile,'      OF_REG_SS=uint64($',UInt64ToHex(OF_REG_SS),');');
         writeln(OutFile,'      OF_REG_DS=uint64($',UInt64ToHex(OF_REG_DS),');');
         writeln(OutFile,'      OF_REG_FS=uint64($',UInt64ToHex(OF_REG_FS),');');
         writeln(OutFile,'      OF_REG_GS=uint64($',UInt64ToHex(OF_REG_GS),');');
         writeln(OutFile,'      OF_REG_FSGS=uint64($',UInt64ToHex(OF_REG_FSGS),');');
         writeln(OutFile,'      OF_REG_SEG67=uint64($',UInt64ToHex(OF_REG_SEG67),');');
         writeln(OutFile,'      OF_REG_SMASK=uint64($',UInt64ToHex(OF_REG_SMASK),');');
         writeln(OutFile,'      OF_REG_ACCUM=uint64($',UInt64ToHex(OF_REG_ACCUM),');');
         writeln(OutFile,'      OF_REG_AL=uint64($',UInt64ToHex(OF_REG_AL),');');
         writeln(OutFile,'      OF_REG_AX=uint64($',UInt64ToHex(OF_REG_AX),');');
         writeln(OutFile,'      OF_REG_EAX=uint64($',UInt64ToHex(OF_REG_EAX),');');
         writeln(OutFile,'      OF_REG_RAX=uint64($',UInt64ToHex(OF_REG_RAX),');');
         writeln(OutFile,'      OF_REG_COUNT=uint64($',UInt64ToHex(OF_REG_COUNT),');');
         writeln(OutFile,'      OF_REG_CL=uint64($',UInt64ToHex(OF_REG_CL),');');
         writeln(OutFile,'      OF_REG_CX=uint64($',UInt64ToHex(OF_REG_CX),');');
         writeln(OutFile,'      OF_REG_ECX=uint64($',UInt64ToHex(OF_REG_ECX),');');
         writeln(OutFile,'      OF_REG_RCX=uint64($',UInt64ToHex(OF_REG_RCX),');');
         writeln(OutFile,'      OF_REG_DL=uint64($',UInt64ToHex(OF_REG_DL),');');
         writeln(OutFile,'      OF_REG_DX=uint64($',UInt64ToHex(OF_REG_DX),');');
         writeln(OutFile,'      OF_REG_EDX=uint64($',UInt64ToHex(OF_REG_EDX),');');
         writeln(OutFile,'      OF_REG_RDX=uint64($',UInt64ToHex(OF_REG_RDX),');');
         writeln(OutFile,'      OF_REG_HIGH=uint64($',UInt64ToHex(OF_REG_HIGH),');');
         writeln(OutFile,'      OF_REG_NOTACC=uint64($',UInt64ToHex(OF_REG_NOTACC),');');
         writeln(OutFile,'      OF_REG_RIP=uint64($',UInt64ToHex(OF_REG_RIP),');');
         writeln(OutFile,'      OF_REG8NA=uint64($',UInt64ToHex(OF_REG8NA),');');
         writeln(OutFile,'      OF_REG16NA=uint64($',UInt64ToHex(OF_REG16NA),');');
         writeln(OutFile,'      OF_REG32NA=uint64($',UInt64ToHex(OF_REG32NA),');');
         writeln(OutFile,'      OF_REG64NA=uint64($',UInt64ToHex(OF_REG64NA),');');
         writeln(OutFile,'      OF_MEM_OFFS=uint64($',UInt64ToHex(OF_MEM_OFFS),');');
         writeln(OutFile,'      OF_IP_REL=uint64($',UInt64ToHex(OF_IP_REL),');');
         writeln(OutFile,'      OF_XMEM=uint64($',UInt64ToHex(OF_XMEM),');');
         writeln(OutFile,'      OF_YMEM=uint64($',UInt64ToHex(OF_YMEM),');');
         writeln(OutFile,'      OF_ZMEM=uint64($',UInt64ToHex(OF_ZMEM),');');
         writeln(OutFile,'      OF_MEMORY_ANY=uint64($',UInt64ToHex(OF_MEMORY_ANY),');');
         writeln(OutFile,'      OF_UNITY=uint64($',UInt64ToHex(OF_UNITY),');');
         writeln(OutFile,'      OF_SBYTEWORD=uint64($',UInt64ToHex(OF_SBYTEWORD),');');
         writeln(OutFile,'      OF_SBYTEDWORD=uint64($',UInt64ToHex(OF_SBYTEDWORD),');');
         writeln(OutFile,'      OF_SDWORD=uint64($',UInt64ToHex(OF_SDWORD),');');
         writeln(OutFile,'      OF_UDWORD=uint64($',UInt64ToHex(OF_UDWORD),');');
         writeln(OutFile,'      OF_RM_XMM_L16=uint64($',UInt64ToHex(OF_RM_XMM_L16),');');
         writeln(OutFile,'      OF_XMM0=uint64($',UInt64ToHex(OF_XMM0),');');
         writeln(OutFile,'      OF_XMM_L16=uint64($',UInt64ToHex(OF_XMM_L16),');');
         writeln(OutFile,'      OF_RM_YMM_L16=uint64($',UInt64ToHex(OF_RM_YMM_L16),');');
         writeln(OutFile,'      OF_YMM0=uint64($',UInt64ToHex(OF_YMM0),');');
         writeln(OutFile,'      OF_YMM_L16=uint64($',UInt64ToHex(OF_YMM_L16),');');
         writeln(OutFile,'      OF_RM_ZMM_L16=uint64($',UInt64ToHex(OF_RM_ZMM_L16),');');
         writeln(OutFile,'      OF_ZMM0=uint64($',UInt64ToHex(OF_ZMM0),');');
         writeln(OutFile,'      OF_ZMM_L16=uint64($',UInt64ToHex(OF_ZMM_L16),');');
         writeln(OutFile,'      RegSTART=longint(0);');
         writeln(OutFile,'      RegNONE=longint(0);');
         for i:=0 to CountRegisters-1 do begin
          writeln(OutFile,'      Reg',Registers[i].RegisterName,'=longint(',i+1,');');
         end;
         writeln(OutFile,'      RegEND=longint(',CountRegisters,');');
         writeln(OutFile,'      OpSTART=longint(0);');
         writeln(OutFile,'      OpNONE=longint(0);');
         for i:=0 to InstructionNames.Count-1 do begin
          writeln(OutFile,'      Op',InstructionNames[i],'=longint(',i+1,');');
         end;
         writeln(OutFile,'      OpEND=longint(',InstructionNames.Count,');');
         writeln(OutFile,'      KeySTART=longint(0);');
         writeln(OutFile,'      KeyNONE=longint(0);');
         for i:=0 to Keywords.Count-1 do begin
          writeln(OutFile,'      Key',Keywords[i],'=longint(',i+1,');');
         end;
         writeln(OutFile,'      KeyLAST=longint(',Keywords.Count+1,');');
         writeln(OutFile,'      PrefixSTART=longint(0);');
         writeln(OutFile,'      PrefixNONE=longint(0);');
         for i:=0 to Prefixes.Count-1 do begin
          writeln(OutFile,'      Prefix',Prefixes[i],'=longint(',i+1,');');
         end;
         writeln(OutFile,'      PrefixEND=longint(',Prefixes.Count+1,');');
         writeln(OutFile,'type PInstructionFlag=^TInstructionFlag;');
         writeln(OutFile,'     TInstructionFlag=0..',MaxIFlagBit,';');
         writeln(OutFile,'     PInstructionFlags=^TInstructionFlags;');
         writeln(OutFile,'     TInstructionFlags=set of TInstructionFlag;');
         writeln(OutFile,'     POperandFlags=^TOperandFlags;');
         writeln(OutFile,'     TOperandFlags=uint64;');
         writeln(OutFile,'     PDecoratorFlags=^TDecoratorFlags;');
         writeln(OutFile,'     TDecoratorFlags=uint64;');
         writeln(OutFile,'     PInstructionTemplate=^TInstructionTemplate;');
         writeln(OutFile,'     TInstructionTemplate=record');
         writeln(OutFile,'      Name:ansistring;');
         writeln(OutFile,'      Operands:array[0..MaxInstructionTemplateOperands-1] of TOperandFlags;');
         writeln(OutFile,'      Decorators:array[0..MaxInstructionTemplateOperands-1] of TDecoratorFlags;');
         writeln(OutFile,'      Sequence:array[0..MaxInstructionTemplateSequenceLength-1] of byte;');
         writeln(OutFile,'      Flags:TInstructionFlags;');
         writeln(OutFile,'      CountOperands:longint;');
         writeln(OutFile,'      SequenceLength:longint;');
         writeln(OutFile,'      Opcode:longint;');
         writeln(OutFile,'     end;');
         writeln(OutFile,'     PInstructionTemplates=^TInstructionTemplates;');
         writeln(OutFile,'     TInstructionTemplates=array[0..CountInstructionTemplates-1] of TInstructionTemplate;');
         writeln(OutFile,'     POpcodeTemplate=^TOpcodeTemplate;');
         writeln(OutFile,'     TOpcodeTemplate=record');
         writeln(OutFile,'      Name:ansistring;');
         writeln(OutFile,'      FromTemplateIndex:longint;');
         writeln(OutFile,'      ToTemplateIndex:longint;');
         writeln(OutFile,'      BitSize:longint;');
         writeln(OutFile,'      MaximalCountOperands:longint;');
         writeln(OutFile,'     end;');
         writeln(OutFile,'     POpcodeTemplates=^TOpcodeTemplates;');
         writeln(OutFile,'     TOpcodeTemplates=array[0..CountOpcodes-1] of TOpcodeTemplate;');
         writeln(OutFile,'     PKeywordKind=^TKeywordKind;');
         writeln(OutFile,'     TKeywordKind=(kkGLOBAL,kkOPCODE,kkPREFIX,kkDIRECTIVE,kkREGISTER,kkEXPRESSION,kkSTRUCT,kkPSEUDOOP,kkDATAPSEUDOOP,kkEQU,kkIFELSE);');
         writeln(OutFile,'     PKeywordKinds=^TKeywordKinds;');
         writeln(OutFile,'     TKeywordKinds=set of TKeywordKind;');
         writeln(OutFile,'     PKeywordTemplate=^TKeywordTemplate;');
         writeln(OutFile,'     TKeywordTemplate=record');
         writeln(OutFile,'      Name:ansistring;');
         writeln(OutFile,'      Kind:TKeywordKinds;');
         writeln(OutFile,'     end;');
         writeln(OutFile,'     PKeywordTemplates=^TKeywordTemplates;');
         writeln(OutFile,'     TKeywordTemplates=array[0..CountKeywords-1] of TKeywordTemplate;');
         writeln(OutFile,'     PPrefixTemplate=^TPrefixTemplate;');
         writeln(OutFile,'     TPrefixTemplate=record');
         writeln(OutFile,'      Name:ansistring;');
         writeln(OutFile,'     end;');
         writeln(OutFile,'     PPrefixTemplates=^TPrefixTemplates;');
         writeln(OutFile,'     TPrefixTemplates=array[0..CountPrefixes-1] of TPrefixTemplate;');
         writeln(OutFile,'const InstructionTemplates:TInstructionTemplates=');
         writeln(OutFile,' (');
         for i:=0 to CountInstructions-1 do begin
          CurrentInstruction:=PInstructions[i];
          writeln(OutFile,'  (');
          writeln(OutFile,'   Name:''',CurrentInstruction^.Name,''';');
          write(OutFile,'   Operands:(');
          for j:=0 to MaxOperands-1 do begin
           if (j>=CurrentInstruction^.CountOperands) or (length(CurrentInstruction^.Operands[j])=0) then begin
            write(OutFile,'0');
           end else begin
            write(OutFile,CurrentInstruction^.Operands[j]);
           end;
           if (j+1)<MaxOperands then begin
            write(OutFile,',');
           end;
          end;
          writeln(OutFile,');');
          write(OutFile,'   Decorators:(');
          for j:=0 to MaxOperands-1 do begin
           if (j>=CurrentInstruction^.CountOperands) or (length(CurrentInstruction^.OperandDecorators[j])=0) then begin
            write(OutFile,'0');
           end else begin
            write(OutFile,CurrentInstruction^.OperandDecorators[j]);
           end;
           if (j+1)<MaxOperands then begin
            write(OutFile,',');
           end;
          end;
          writeln(OutFile,');');
          write(OutFile,'   Sequence:(');
          for j:=0 to MaxInstructionTemplateSequenceLength-1 do begin
           if j>=CurrentInstruction^.SequenceLength then begin
            write(OutFile,'0');
           end else begin
            write(OutFile,byte(ansichar(CurrentInstruction^.Sequence[j+1])));
           end;
           if (j+1)<MaxInstructionTemplateSequenceLength then begin
            write(OutFile,',');
           end;
          end;
          writeln(OutFile,');');
          write(OutFile,'   Flags:[');
          k:=0;
          for j:=0 to MaxIFlagBit do begin
           if byte(j) in CurrentInstruction^.Flags then begin
            if k>0 then begin
             write(OutFile,',');
            end;
            for h:=0 to CountIFlagBits-1 do begin
             if IFlagBits[h].Bit=j then begin
              write(OutFile,'IF_',IFlagBits[h].Name);
              break;
             end;
            end;
            inc(k);
           end;
          end;
          writeln(OutFile,'];');
          writeln(OutFile,'   CountOperands:',CurrentInstruction^.CountOperands,';');
          writeln(OutFile,'   SequenceLength:',CurrentInstruction^.SequenceLength,';');
          writeln(OutFile,'   Opcode:',InstructionNames.IndexOf(CurrentInstruction^.Name)+1,';');
          if (i+1)<CountInstructions then begin
           writeln(OutFile,'  ),');
          end else begin
           writeln(OutFile,'  )');
          end;
         end;
         writeln(OutFile,' );');
         writeln(OutFile,'const OpcodeTemplates:TOpcodeTemplates=');
         writeln(OutFile,' (');
         writeln(OutFile,'  (');
         writeln(OutFile,'   Name:'''';');
         writeln(OutFile,'   FromTemplateIndex:-1;');
         writeln(OutFile,'   ToTemplateIndex:-2;');
         writeln(OutFile,'   BitSize:0;');
         writeln(OutFile,'   MaximalCountOperands:0;');
         writeln(OutFile,'  ),');
         for i:=0 to InstructionNames.Count-1 do begin
          writeln(OutFile,'  (');
          writeln(OutFile,'   Name:''',InstructionNames[i],''';');
          writeln(OutFile,'   FromTemplateIndex:',InstructionRanges[i,0],';');
          writeln(OutFile,'   ToTemplateIndex:',InstructionRanges[i,1],';');
          writeln(OutFile,'   BitSize:',InstructionRanges[i,2],';');
          writeln(OutFile,'   MaximalCountOperands:',InstructionRanges[i,3],';');
          if (i+1)<InstructionNames.Count then begin
           writeln(OutFile,'  ),');
          end else begin
           writeln(OutFile,'  )');
          end;
         end;
         writeln(OutFile,' );');
         writeln(OutFile,'type PRegisterTemplate=^TRegisterTemplate;');
         writeln(OutFile,'     TRegisterTemplate=record');
         writeln(OutFile,'      RegisterName:ansistring;');
         writeln(OutFile,'      RegisterClass:TOperandFlags;');
         writeln(OutFile,'      RegisterNumber:longint;');
         writeln(OutFile,'      RegisterFlags:longword;');
         writeln(OutFile,'     end;');
         writeln(OutFile,'     PRegisterTemplates=^TRegisterTemplates;');
         writeln(OutFile,'     TRegisterTemplates=array[0..CountRegisterTemplates] of TRegisterTemplate;');
         writeln(OutFile,'const RegisterTemplates:TRegisterTemplates=');
         writeln(OutFile,' (');
         writeln(OutFile,'  (');
         writeln(OutFile,'   RegisterName:'''';');
         writeln(OutFile,'   RegisterClass:0;');
         writeln(OutFile,'   RegisterNumber:0;');
         writeln(OutFile,'   RegisterFlags:0;');
         writeln(OutFile,'  ),');
         for i:=0 to CountRegisters-1 do begin
          writeln(OutFile,'  (');
          writeln(OutFile,'   RegisterName:''',Registers[i].RegisterName,''';');
          writeln(OutFile,'   RegisterClass:OF_',Registers[i].RegisterClass,';');
          writeln(OutFile,'   RegisterNumber:',Registers[i].RegisterNumber,';');
          writeln(OutFile,'   RegisterFlags:',Registers[i].RegisterFlags,';');
          if (i+1)<CountRegisters then begin
           writeln(OutFile,'  ),');
          end else begin
           writeln(OutFile,'  )');
          end;
         end;
         writeln(OutFile,' );');
         writeln(OutFile,'const KeywordTemplates:TKeywordTemplates=');
         writeln(OutFile,' (');
         writeln(OutFile,'  (');
         writeln(OutFile,'   Name:'''';');
         writeln(OutFile,'   Kind:[];');
         writeln(OutFile,'  ),');
         for i:=0 to Keywords.Count-1 do begin
          writeln(OutFile,'  (');
          writeln(OutFile,'   Name:''',Keywords[i],''';');
          s:='';
          s2:=trim(KeywordKinds[i]);
          j:=1;
          while (j<=length(s2)) and (s2[j] in [#1..#32]) do begin
           inc(j);
          end;
          while j<=length(s2) do begin
           if length(s)>0 then begin
            s:=s+',';
           end;
           s:=s+'kk'+Parse(s2,[#1..#32],j,true);
           while (j<=length(s2)) and (s2[j] in [#1..#32]) do begin
            inc(j);
           end;
          end;
          writeln(OutFile,'   Kind:[',s,'];');
          if (i+1)<Keywords.Count then begin
           writeln(OutFile,'  ),');
          end else begin
           writeln(OutFile,'  )');
          end;
         end;
         writeln(OutFile,' );');
         writeln(OutFile,'const PrefixTemplates:TPrefixTemplates=');
         writeln(OutFile,' (');
         writeln(OutFile,'  (');
         writeln(OutFile,'   Name:'''';');
         writeln(OutFile,'  ),');
         for i:=0 to Prefixes.Count-1 do begin
          writeln(OutFile,'  (');
          writeln(OutFile,'   Name:''',Prefixes[i],''';');
          if (i+1)<Prefixes.Count then begin
           writeln(OutFile,'  ),');
          end else begin
           writeln(OutFile,'  )');
          end;
         end;
         writeln(OutFile,' );');
         CloseFile(OutFile);

        finally
         InstructionNames.Free;
        end;

       finally
        Prefixes.Free;
       end;

      finally
       Keywords.Free;
       KeywordKinds.Free;
      end;

     finally
      SetLength(InstructionRanges,0);
     end;

    finally
     SetLength(RecordedIFlags,0);
    end;

   finally
    SetLength(IFlagBits,0);
   end;

  finally
   SetLength(Registers,0);
  end;

 finally
  SetLength(Instructions,0);
 end;
end.
