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

procedure Formatx86Ins;
var Lines,NewLines:TStringList;
    LineIndex,i,j:longint;
    Line,Opcode,Operands,OperandEncoding,OperandTuple,Sequence,Flags:ansistring;
    MaxOpcodeLen,MaxOperandsLen,MaxSequenceLen:longint;
begin
 MaxOpcodeLen:=0;
 MaxOperandsLen:=0;
 MaxSequenceLen:=0;
 Lines:=TStringList.Create;
 NewLines:=TStringList.Create;
 try
  Lines.LoadFromFile('x86ins.txt');

  for LineIndex:=0 to Lines.Count-1 do begin
   Line:=StringReplace(trim(Lines[LineIndex]),#9,#32,[rfReplaceAll]);

   repeat
    i:=pos(';',Line);
    if i>0 then begin
     Line:=trim(copy(Line,1,i-1));
    end else begin
     i:=pos('#',Line);
     if i>0 then begin
      Line:=trim(copy(Line,1,i-1));
     end else begin
      break;
     end;
    end;
   until false;

   if length(Line)=0 then begin
    continue;
   end;

   i:=1;

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
     OperandTuple:=copy(Sequence,1,j-1);
     Delete(Sequence,1,j);
     Sequence:=trim(Sequence);
    end else begin
     OperandTuple:='';
    end;
   end else begin
    OperandEncoding:='';
    OperandTuple:='';
   end;
   while length(OperandEncoding)<4 do begin
    OperandEncoding:=' '+OperandEncoding;
   end;
   while length(OperandTuple)<5 do begin
    OperandTuple:=' '+OperandTuple;
   end;
   Sequence:='['+OperandEncoding+': '+OperandTuple+': '+Sequence+']';
   Parse(Line,[#1..#32],i,true);
   Flags:=trim(Parse(Line,[#1..#32],i,true));

   MaxOpcodeLen:=max(MaxOpcodeLen,length(Opcode));
   MaxOperandsLen:=max(MaxOperandsLen,length(Operands));
   MaxSequenceLen:=max(MaxSequenceLen,length(Sequence));
  end;

  for LineIndex:=0 to Lines.Count-1 do begin
   Line:=StringReplace(trim(Lines[LineIndex]),#9,#32,[rfReplaceAll]);

   repeat
    i:=pos(';',Line);
    if i>0 then begin
     Line:=trim(copy(Line,1,i-1));
    end else begin
     i:=pos('#',Line);
     if i>0 then begin
      Line:=trim(copy(Line,1,i-1));
     end else begin
      break;
     end;
    end;
   until false;

   if length(Line)=0 then begin
    continue;
   end;

   i:=1;

   Opcode:=trim(Parse(Line,[#1..#32],i,true));
   if (Opcode='DB') or
      (Opcode='DW') or
      (Opcode='DD') or
      (Opcode='DQ') or
      (Opcode='DT') or
      (Opcode='DO') or
      (Opcode='DY') or
      (Opcode='DZ') or
      (Opcode='RESB') or
      (Opcode='RESW') or
      (Opcode='RESD') or
      (Opcode='RESQ') or
      (Opcode='REST') or
      (Opcode='RESO') or
      (Opcode='RESY') or
      (Opcode='RESZ') or
      (Opcode='EQU') or
      (Opcode='INCBIN') then begin
    continue;
   end;

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
     OperandTuple:=copy(Sequence,1,j-1);
     Delete(Sequence,1,j);
     Sequence:=trim(Sequence);
    end else begin
     OperandTuple:='';
    end;
   end else begin
    OperandEncoding:='';
    OperandTuple:='';
   end;
   while length(OperandEncoding)<4 do begin
    OperandEncoding:=' '+OperandEncoding;
   end;
   while length(OperandTuple)<5 do begin
    OperandTuple:=' '+OperandTuple;
   end;
   Sequence:='['+OperandEncoding+': '+OperandTuple+': '+Sequence+']';
   Parse(Line,[#1..#32],i,true);
   Flags:=trim(Parse(Line,[#1..#32],i,true));

   while length(Opcode)<MaxOpcodeLen do begin
    Opcode:=Opcode+' ';
   end;
   while length(Operands)<MaxOperandsLen do begin
    Operands:=Operands+' ';
   end;
   delete(Sequence,length(Sequence),1);
   while length(Sequence)<(MaxSequenceLen-1) do begin
    Sequence:=Sequence+' ';
   end;
   Sequence:=Sequence+']';

   NewLines.Add(trim(Opcode+' '+Operands+' '+Sequence+' '+Flags));

  end;

  NewLines.SaveToFile('x86ins.txt');

 finally
  NewLines.Free;
  Lines.Free;
 end;
end;

procedure Formatx86Regs;
var Lines,NewLines:TStringList;
    LineIndex,i:longint;
    Line,RegisterName,RegisterClass,RegisterNumber,Flags:ansistring;
    MaxRegisterNameLen,MaxRegisterClassLen,MaxRegisterNumberLen:longint;
begin
 MaxRegisterNameLen:=0;
 MaxRegisterClassLen:=0;
 MaxRegisterNumberLen:=0;
 Lines:=TStringList.Create;
 NewLines:=TStringList.Create;
 try
  Lines.LoadFromFile('x86regs.txt');

  for LineIndex:=0 to Lines.Count-1 do begin
   Line:=StringReplace(trim(Lines[LineIndex]),#9,#32,[rfReplaceAll]);

   repeat
    i:=pos(';',Line);
    if i>0 then begin
     Line:=trim(copy(Line,1,i-1));
    end else begin
     i:=pos('#',Line);
     if i>0 then begin
      Line:=trim(copy(Line,1,i-1));
     end else begin
      break;
     end;
    end;
   until false;

   if length(Line)=0 then begin
    continue;
   end;

   i:=1;

   RegisterName:=trim(Parse(Line,[#1..#32],i,true));
   RegisterClass:=trim(Parse(Line,[#1..#32],i,true));
   //Parse(Line,[#1..#32],i,true);
   RegisterNumber:=trim(Parse(Line,[#1..#32],i,true));
   Flags:=trim(Parse(Line,[#1..#32],i,true));

   MaxRegisterNameLen:=max(MaxRegisterNameLen,length(RegisterName));
   MaxRegisterClassLen:=max(MaxRegisterClassLen,length(RegisterClass));
   MaxRegisterNumberLen:=max(MaxRegisterNumberLen,length(RegisterNumber));
  end;

  for LineIndex:=0 to Lines.Count-1 do begin
   Line:=StringReplace(trim(Lines[LineIndex]),#9,#32,[rfReplaceAll]);

   repeat
    i:=pos(';',Line);
    if i>0 then begin
     Line:=trim(copy(Line,1,i-1));
    end else begin
     i:=pos('#',Line);
     if i>0 then begin
      Line:=trim(copy(Line,1,i-1));
     end else begin
      break;
     end;
    end;
   until false;

   if length(Line)=0 then begin
    continue;
   end;

   i:=1;

   RegisterName:=trim(Parse(Line,[#1..#32],i,true));
   RegisterClass:=trim(Parse(Line,[#1..#32],i,true));
   //Parse(Line,[#1..#32],i,true);
   RegisterNumber:=trim(Parse(Line,[#1..#32],i,true));
   Flags:=trim(Parse(Line,[#1..#32],i,true));

   while length(RegisterName)<MaxRegisterNameLen do begin
    RegisterName:=RegisterName+' ';
   end;
   while length(RegisterClass)<MaxRegisterClassLen do begin
    RegisterClass:=RegisterClass+' ';
   end;
   while length(RegisterNumber)<MaxRegisterNumberLen do begin
    RegisterNumber:=RegisterNumber+' ';
   end;

   NewLines.Add(trim(RegisterName+' '+RegisterClass+' '+RegisterNumber+' '+Flags));

  end;

  NewLines.SaveToFile('x86regs.txt');

 finally
  NewLines.Free;
  Lines.Free;
 end;
end;

procedure Formatx86Keywords;
var Lines,NewLines:TStringList;
    LineIndex:longint;
    Line:ansistring;
begin
 Lines:=TStringList.Create;
 NewLines:=TStringList.Create;
 try
  Lines.LoadFromFile('x86keywords.txt');
  for LineIndex:=0 to Lines.Count-1 do begin
   Line:=Uppercase(StringReplace(trim(Lines[LineIndex]),#9,#32,[rfReplaceAll]));
   if length(Line)>0 then begin
    NewLines.Add(Line);
   end;
  end;
  NewLines.SaveToFile('x86keywords.txt');
 finally
  NewLines.Free;
  Lines.Free;
 end;
end;

begin
 Formatx86Ins;
 Formatx86Regs;
 Formatx86Keywords;
end.
