unit TRILinker;
{$ifdef fpc}
 {$mode delphi}
 {$ifdef cpui386}
  {$define cpu386}
 {$endif}
 {$ifdef cpu386}
  {$asmmode intel}
 {$endif}
{$endif}

interface

uses Windows{$ifdef CreamTrackerGUI},SysUtils,Classes,NativeCodeMemoryManager{$endif}{$ifdef memdebug},FastMM4{$endif};

type TGetNameCode=function(Name:pansichar):ansichar;

     TGetExternalPointer=function(Context:pointer;Name:pansichar):pointer;

     TSetPublicPointer=procedure(Context:pointer;Name:pansichar;ThePointer:pointer);

     PTRIInstance=^TTRIInstance;
     TTRIInstance=record
      ImageData:pointer;
      ImageSize:longint;
      CodeSize:longint;
     end;

function ComparePAnsiChar(a,b:pansichar):boolean; register;

{$ifdef CreamTrackerGUI}
procedure TRIStrip(RawCode:pointer;RawCodeSize:longint;var OutputData:pointer;var OutputSize:longint;GetNameCode:TGetNameCode);
{$endif}
function TRILink(RawCode:pointer;RawCodeSize:longint;Context:pointer;GetExternalPointer:TGetExternalPointer;SetPublicPointer:TSetPublicPointer):PTRIInstance;
function TRIFree(Instance:PTRIInstance):boolean;

implementation

{$undef OldDelphi}
{$ifndef fpc}
 {$ifdef conditionalexpressions}
  {$if CompilerVersion>=23.0}
   {$undef OldDelphi}
type qword=uint64;
     ptruint=NativeUInt;
     ptrint=NativeInt;
  {$elseif true}
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

function ComparePAnsiChar(a,b:pansichar):boolean; register;
var ac,bc:ansichar;
begin
 result:=true;
 if assigned(a) and assigned(b) then begin
  while (a^<>#0) and (b^<>#0) do begin
   ac:=a^;
   bc:=b^;
   if ac in ['A'..'Z'] then begin
    inc(ac,ord('a')-ord('A'));
   end;
   if bc in ['A'..'Z'] then begin
    inc(bc,ord('a')-ord('A'));
   end;
   if ac<>bc then begin
    result:=false;
    break;
   end;
   inc(a);
   inc(b);
  end;
  if a^<>b^ then begin
   result:=false;
  end;
 end;
end;

{$ifdef CreamTrackerGUI}
procedure TRIStrip(RawCode:pointer;RawCodeSize:longint;var OutputData:pointer;var OutputSize:longint;GetNameCode:TGetNameCode);
var OutputAllocated:longint;
 function Write(const Src;Bytes:longint):longint;
 begin
  if (OutputSize+Bytes)>=OutputAllocated then begin
   while (OutputSize+Bytes)>=OutputAllocated do begin
    inc(OutputAllocated,OutputAllocated);
   end;
{$ifdef memdebug}ScanMemoryPoolForCorruptions;{$endif}
   ReallocMem(OutputData,OutputAllocated);
{$ifdef memdebug}ScanMemoryPoolForCorruptions;{$endif}
  end;
  Move(Src,PAnsiChar(OutputData)[OutputSize],Bytes);
  inc(OutputSize,Bytes);
  result:=Bytes;
 end;
var ImageCodeSize,ImageSize,ImageRelocations,ImagePublics,i,Position,Len:longint;
    r,p:pansichar;
    t,Bits,Relative:byte;
    ExternalName,PublicName:pansichar;
    OutputImageRelocations,OutputImageRelocationsOffset,OutputImagePublics,OutputImagePublicsOffset:longint;
    NameCode:ansichar;
begin
 OutputSize:=0;
 OutputAllocated:=65536;
 GetMem(OutputData,OutputAllocated);
 if assigned(RawCode) and (RawCodeSize>0) then begin
  if not ((pansichar(RawCode)[0]='T') and (pansichar(RawCode)[1]='R') and (pansichar(RawCode)[2]='I') and (pansichar(RawCode)[3]=#00)) then begin
   exit;
  end;
  Write(pansichar(RawCode)[0],4*SizeOf(ansichar));
  ImageCodeSize:=longint(pointer(@pansichar(RawCode)[4])^);
  Write(ImageCodeSize,SizeOf(longint));
  ImageSize:=longint(pointer(@pansichar(RawCode)[8])^);
  Write(ImageSize,SizeOf(longint));
  ImageRelocations:=longint(pointer(@pansichar(RawCode)[12])^);
  Write(ImageRelocations,SizeOf(longint));
  ImagePublics:=longint(pointer(@pansichar(RawCode)[16])^);
  Write(ImagePublics,SizeOf(longint));
  Write(pansichar(RawCode)[20],4*SizeOf(ansichar));
  Write(pansichar(RawCode)[24],4*SizeOf(ansichar));
  r:=pointer(@pansichar(RawCode)[longint(pointer(@pansichar(RawCode)[20])^)]);
  p:=pointer(@pansichar(RawCode)[longint(pointer(@pansichar(RawCode)[24])^)]);
  Write(pointer(@pansichar(RawCode)[28])^,ImageCodeSize);
  OutputImageRelocations:=0;
  OutputImageRelocationsOffset:=OutputSize;
  for i:=1 to ImageRelocations do begin
   t:=byte(pointer(r)^);
   inc(r);
   case t of
    1:begin
     // Relocation
     inc(OutputImageRelocations);
     Write(t,sizeof(byte));
     Write(byte(pointer(r)^),sizeof(byte)); // Bits
     inc(r);
     Write(byte(pointer(r)^),sizeof(byte)); // Relative
     inc(r);
     Write(longint(pointer(r)^),sizeof(longint)); // Position
     inc(r,sizeof(longint));
    end;
    2:begin
     // External
     Bits:=byte(pointer(r)^);
     inc(r);
     Relative:=byte(pointer(r)^);
     inc(r);
     Position:=longint(pointer(r)^);
     inc(r,sizeof(longint));
     Len:=longint(pointer(r)^);
     inc(r,sizeof(longint));
     ExternalName:=pointer(r);
     inc(r,Len);
     if assigned(addr(GetNameCode)) then begin
      NameCode:=GetNameCode(ExternalName);
     end else begin
      NameCode:=#$00;
     end;
     if NameCode<>#$00 then begin
      inc(OutputImageRelocations);
      Write(t,sizeof(byte));
      Write(Bits,sizeof(byte));
      Write(Relative,sizeof(byte));
      Write(Position,sizeof(longint));
      Len:=2;
      Write(Len,sizeof(longint));
      Write(NameCode,sizeof(ansichar));
      NameCode:=#0;
      Write(NameCode,sizeof(ansichar));
     end;
    end;
    3:begin
     // Import
     inc(OutputImageRelocations);
     Write(t,sizeof(byte));
     Write(byte(pointer(r)^),sizeof(byte)); // Bits
     inc(r);
     Write(byte(pointer(r)^),sizeof(byte)); // Relative
     inc(r);
     Write(longint(pointer(r)^),sizeof(longint)); // Position
     inc(r,sizeof(longint));
     Len:=longint(pointer(r)^);
     Write(Len,sizeof(longint)); // Len
     inc(r,sizeof(longint));
     Write(r^,Len); // LibName
     inc(r,Len);
     Len:=longint(pointer(r)^);
     Write(Len,sizeof(longint)); // Len
     inc(r,sizeof(longint));
     Write(r^,Len); // LibImportName
     inc(r,Len);
    end;
   end;
  end;
{$ifdef memdebug}ScanMemoryPoolForCorruptions;{$endif}
  // Publics
  OutputImagePublics:=0;
  OutputImagePublicsOffset:=OutputSize;
  for i:=1 to ImagePublics do begin
   Len:=longint(pointer(p)^);
   inc(p,sizeof(longint));
   PublicName:=p;
   inc(p,Len);
   Position:=longint(pointer(p)^);
   inc(p,sizeof(longint));
   if assigned(addr(GetNameCode)) then begin
    NameCode:=GetNameCode(PublicName);
   end else begin
    NameCode:=#$00;
   end;
   if NameCode<>#$00 then begin
    inc(OutputImagePublics);
    Len:=2;
    Write(Len,sizeof(longint));
    Write(NameCode,sizeof(ansichar));
    NameCode:=#0;
    Write(NameCode,sizeof(ansichar));
    Write(Position,sizeof(longint));
   end;
  end;
  longint(pointer(@pansichar(OutputData)[12])^):=OutputImageRelocations;
  longint(pointer(@pansichar(OutputData)[16])^):=OutputImagePublics;
  longint(pointer(@pansichar(OutputData)[20])^):=OutputImageRelocationsOffset;
  longint(pointer(@pansichar(OutputData)[24])^):=OutputImagePublicsOffset;
  ReallocMem(OutputData,OutputSize);
 end;
end;
{$endif}

function TRILink(RawCode:pointer;RawCodeSize:longint;Context:pointer;GetExternalPointer:TGetExternalPointer;SetPublicPointer:TSetPublicPointer):PTRIInstance;
var ImageCodeSize,ImageSize,ImageRelocations,ImagePublics,i,Position,Len:longint;
    r,p,ExternalName,LibName,LibImportName,PublicName:pansichar;
    t,Bits:byte;
    Relative:boolean;
    ExternalPointer,LibImportPointer,ImageData:pointer;
begin
 result:=nil;
 if assigned(RawCode) and (RawCodeSize>0) then begin
{$ifdef memdebug}ScanMemoryPoolForCorruptions;{$endif}
  if not ((pansichar(RawCode)[0]='T') and (pansichar(RawCode)[1]='R') and (pansichar(RawCode)[2]='I') and (pansichar(RawCode)[3]=#00)) then begin
   exit;
  end;
  ImageCodeSize:=longint(pointer(@pansichar(RawCode)[4])^);
  ImageSize:=longint(pointer(@pansichar(RawCode)[8])^);
  ImageRelocations:=longint(pointer(@pansichar(RawCode)[12])^);
  ImagePublics:=longint(pointer(@pansichar(RawCode)[16])^);
  r:=pointer(@pansichar(RawCode)[longint(pointer(@pansichar(RawCode)[20])^)]);
  p:=pointer(@pansichar(RawCode)[longint(pointer(@pansichar(RawCode)[24])^)]);
{$ifdef memdebug}ScanMemoryPoolForCorruptions;{$endif}
  GetMem(result,SizeOf(TTRIInstance));
{$ifdef memdebug}ScanMemoryPoolForCorruptions;{$endif}
{$ifdef CreamTrackerGUI}
  ImageData:=NativeCodeMemoryManagerInstance.GetMemory(ImageSize);
{$else}
  ImageData:=VirtualAlloc(nil,ImageSize,MEM_COMMIT,PAGE_EXECUTE_READWRITE);
{$endif}
{$ifdef memdebug}ScanMemoryPoolForCorruptions;{$endif}
  result^.ImageData:=ImageData;
  result^.ImageSize:=ImageSize;
  result^.CodeSize:=ImageCodeSize;
  FillChar(ImageData^,ImageSize,AnsiChar(#0));
  Move(pointer(@pansichar(RawCode)[28])^,ImageData^,ImageCodeSize);
{$ifdef memdebug}ScanMemoryPoolForCorruptions;{$endif}
  for i:=1 to ImageRelocations do begin
   t:=byte(pointer(r)^);
   inc(r);
   case t of
    1:begin
     // Relocation
     Bits:=byte(pointer(r)^);
     inc(r);
     Relative:=byte(pointer(r)^)<>0;
     inc(r);
     Position:=longint(pointer(r)^);
     inc(r,sizeof(longint));
     if not Relative then begin
      case Bits of
       8:begin
        inc(byte(pointer(@pansichar(ImageData)[Position])^),ptruint(ImageData));
       end;
       16:begin
        inc(word(pointer(@pansichar(ImageData)[Position])^),ptruint(ImageData));
       end;
       32:begin
        inc(longword(pointer(@pansichar(ImageData)[Position])^),ptruint(ImageData));
       end;
       64:begin
        inc(int64(pointer(@pansichar(ImageData)[Position])^),ptruint(ImageData));
       end;
      end;
     end;
    end;
    2:begin
     // External
     Bits:=byte(pointer(r)^);
     inc(r);
     Relative:=byte(pointer(r)^)<>0;
     inc(r);
     Position:=longint(pointer(r)^);
     inc(r,sizeof(longint));
     Len:=longint(pointer(r)^);
     inc(r,sizeof(longint));
     ExternalName:=pointer(r);
     inc(r,Len);
     if assigned(@GetExternalPointer) then begin
      ExternalPointer:=GetExternalPointer(Context,ExternalName);
     end else begin
      ExternalPointer:=nil;
     end;
     if assigned(ExternalPointer) then begin
      if Relative then begin
       case Bits of
        8:begin
         inc(byte(pointer(@pansichar(ImageData)[Position])^),ptruint(ExternalPointer)-ptruint(ImageData));
        end;
        16:begin
         inc(word(pointer(@pansichar(ImageData)[Position])^),ptruint(ExternalPointer)-ptruint(ImageData));
        end;
        32:begin
         inc(longword(pointer(@pansichar(ImageData)[Position])^),ptruint(ExternalPointer)-ptruint(ImageData));
        end;
        64:begin
         inc(int64(pointer(@pansichar(ImageData)[Position])^),ptruint(ExternalPointer)-ptruint(ImageData));
        end;
       end;
      end else begin
       case Bits of
        8:begin
         inc(byte(pointer(@pansichar(ImageData)[Position])^),ptruint(ExternalPointer));
        end;
        16:begin
         inc(word(pointer(@pansichar(ImageData)[Position])^),ptruint(ExternalPointer));
        end;
        32:begin
         inc(longword(pointer(@pansichar(ImageData)[Position])^),ptruint(ExternalPointer));
        end;
        64:begin
         inc(int64(pointer(@pansichar(ImageData)[Position])^),ptruint(ExternalPointer));
        end;
       end;
      end;
     end;
    end;
    3:begin
     // Import
     Bits:=byte(pointer(r)^);
     inc(r);
     Relative:=byte(pointer(r)^)<>0;
     inc(r);
     Position:=longint(pointer(r)^);
     inc(r,sizeof(longint));
     Len:=longint(pointer(r)^);
     inc(r,sizeof(longint));
     LibName:=r;
     inc(r,Len);
     Len:=longint(pointer(r)^);
     inc(r,sizeof(longint));
     LibImportName:=r;
     inc(r,Len);
     LibImportPointer:=GetProcAddress(LoadLibraryA(LibName),LibImportName);
     if Relative then begin
      case Bits of
       8:begin
        inc(byte(pointer(@pansichar(ImageData)[Position])^),ptruint(LibImportPointer)-ptruint(ImageData));
       end;
       16:begin
        inc(word(pointer(@pansichar(ImageData)[Position])^),ptruint(LibImportPointer)-ptruint(ImageData));
       end;
       32:begin
        inc(longword(pointer(@pansichar(ImageData)[Position])^),ptruint(LibImportPointer)-ptruint(ImageData));
       end;
       64:begin
        inc(int64(pointer(@pansichar(ImageData)[Position])^),ptruint(LibImportPointer)-ptruint(ImageData));
       end;
      end;
     end else begin
      case Bits of
       8:begin
        inc(byte(pointer(@pansichar(ImageData)[Position])^),ptruint(LibImportPointer));
       end;
       16:begin
        inc(word(pointer(@pansichar(ImageData)[Position])^),ptruint(LibImportPointer));
       end;
       32:begin
        inc(longword(pointer(@pansichar(ImageData)[Position])^),ptruint(LibImportPointer));
       end;
       64:begin
        inc(int64(pointer(@pansichar(ImageData)[Position])^),ptruint(LibImportPointer));
       end;
      end;
     end;
    end;
   end;
  end;
{$ifdef memdebug}ScanMemoryPoolForCorruptions;{$endif}
  // Publics
  for i:=1 to ImagePublics do begin
   Len:=longint(pointer(p)^);
   inc(p,sizeof(longint));
   PublicName:=p;
   inc(p,Len);
   Position:=longint(pointer(p)^);
   inc(p,sizeof(longint));
   if assigned(@SetPublicPointer) then begin
    SetPublicPointer(Context,PublicName,pointer(@pansichar(ImageData)[Position]));
   end;
  end;
 end;
{$ifdef memdebug}ScanMemoryPoolForCorruptions;{$endif}
end;

function TRIFree(Instance:PTRIInstance):boolean;
begin
 result:=assigned(Instance);
 if result then begin
{$ifdef memdebug}ScanMemoryPoolForCorruptions;{$endif}
{$ifdef CreamTrackerGUI}
  NativeCodeMemoryManagerInstance.FreeMemory(Instance^.ImageData);
{$else}
  VirtualFree(Instance^.ImageData,Instance^.ImageSize,MEM_DECOMMIT);
{$endif}
{$ifdef memdebug}ScanMemoryPoolForCorruptions;{$endif}
  FreeMem(Instance);
{$ifdef memdebug}ScanMemoryPoolForCorruptions;{$endif}
 end;
end;
{$hints on}

end.