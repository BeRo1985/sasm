program sasm;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{$ifdef Win32}
 {$APPTYPE CONSOLE}
{$endif}
{$ifdef Win64}
 {$APPTYPE CONSOLE}
{$endif}

{%File 'SASMDataContent.inc'}
{%File 'BESEN\BESEN.inc'}
{%File 'SASM.inc'}

uses
  SysUtils,
  PUCU in 'PUCU.pas',
  SASMCore in 'SASMCore.pas',
  SASMData in 'SASMData.pas'{$ifdef SASMBESEN},
  BESEN in 'BESEN\BESEN.pas',
  BESENArrayUtils in 'BESEN\BESENArrayUtils.pas',
  BESENASTNodes in 'BESEN\BESENASTNodes.pas',
  BESENBaseObject in 'BESEN\BESENBaseObject.pas',
  BESENCharset in 'BESEN\BESENCharset.pas',
  BESENCode in 'BESEN\BESENCode.pas',
  BESENCodeContext in 'BESEN\BESENCodeContext.pas',
  BESENCodeGeneratorContext in 'BESEN\BESENCodeGeneratorContext.pas',
  BESENCodeJIT in 'BESEN\BESENCodeJIT.pas',
  BESENCodeJITx64 in 'BESEN\BESENCodeJITx64.pas',
  BESENCodeJITx86 in 'BESEN\BESENCodeJITx86.pas',
  BESENCodeSnapshot in 'BESEN\BESENCodeSnapshot.pas',
  BESENCollector in 'BESEN\BESENCollector.pas',
  BESENCollectorObject in 'BESEN\BESENCollectorObject.pas',
  BESENCompiler in 'BESEN\BESENCompiler.pas',
  BESENConstants in 'BESEN\BESENConstants.pas',
  BESENContext in 'BESEN\BESENContext.pas',
  BESENDateUtils in 'BESEN\BESENDateUtils.pas',
  BESENDeclarativeEnvironmentRecord in 'BESEN\BESENDeclarativeEnvironmentRecord.pas',
  BESENDecompiler in 'BESEN\BESENDecompiler.pas',
  BESENDoubleList in 'BESEN\BESENDoubleList.pas',
  BESENEnvironmentRecord in 'BESEN\BESENEnvironmentRecord.pas',
  BESENErrors in 'BESEN\BESENErrors.pas',
  BESENEvalCache in 'BESEN\BESENEvalCache.pas',
  BESENEvalCacheItem in 'BESEN\BESENEvalCacheItem.pas',
  BESENGarbageCollector in 'BESEN\BESENGarbageCollector.pas',
  BESENGlobals in 'BESEN\BESENGlobals.pas',
  BESENHashMap in 'BESEN\BESENHashMap.pas',
  BESENHashUtils in 'BESEN\BESENHashUtils.pas',
  BESENInt64SelfBalancedTree in 'BESEN\BESENInt64SelfBalancedTree.pas',
  BESENIntegerList in 'BESEN\BESENIntegerList.pas',
  BESENKeyIDManager in 'BESEN\BESENKeyIDManager.pas',
  BESENLexer in 'BESEN\BESENLexer.pas',
  BESENLexicalEnvironment in 'BESEN\BESENLexicalEnvironment.pas',
  BESENLocale in 'BESEN\BESENLocale.pas',
  BESENNativeCodeMemoryManager in 'BESEN\BESENNativeCodeMemoryManager.pas',
  BESENNativeObject in 'BESEN\BESENNativeObject.pas',
  BESENNumberUtils in 'BESEN\BESENNumberUtils.pas',
  BESENObject in 'BESEN\BESENObject.pas',
  BESENObjectArgGetterFunction in 'BESEN\BESENObjectArgGetterFunction.pas',
  BESENObjectArgSetterFunction in 'BESEN\BESENObjectArgSetterFunction.pas',
  BESENObjectArray in 'BESEN\BESENObjectArray.pas',
  BESENObjectArrayConstructor in 'BESEN\BESENObjectArrayConstructor.pas',
  BESENObjectArrayPrototype in 'BESEN\BESENObjectArrayPrototype.pas',
  BESENObjectBindingFunction in 'BESEN\BESENObjectBindingFunction.pas',
  BESENObjectBoolean in 'BESEN\BESENObjectBoolean.pas',
  BESENObjectBooleanConstructor in 'BESEN\BESENObjectBooleanConstructor.pas',
  BESENObjectBooleanPrototype in 'BESEN\BESENObjectBooleanPrototype.pas',
  BESENObjectConsole in 'BESEN\BESENObjectConsole.pas',
  BESENObjectConstructor in 'BESEN\BESENObjectConstructor.pas',
  BESENObjectDate in 'BESEN\BESENObjectDate.pas',
  BESENObjectDateConstructor in 'BESEN\BESENObjectDateConstructor.pas',
  BESENObjectDatePrototype in 'BESEN\BESENObjectDatePrototype.pas',
  BESENObjectDeclaredFunction in 'BESEN\BESENObjectDeclaredFunction.pas',
  BESENObjectEnvironmentRecord in 'BESEN\BESENObjectEnvironmentRecord.pas',
  BESENObjectError in 'BESEN\BESENObjectError.pas',
  BESENObjectErrorConstructor in 'BESEN\BESENObjectErrorConstructor.pas',
  BESENObjectErrorPrototype in 'BESEN\BESENObjectErrorPrototype.pas',
  BESENObjectFunction in 'BESEN\BESENObjectFunction.pas',
  BESENObjectFunctionArguments in 'BESEN\BESENObjectFunctionArguments.pas',
  BESENObjectFunctionConstructor in 'BESEN\BESENObjectFunctionConstructor.pas',
  BESENObjectFunctionPrototype in 'BESEN\BESENObjectFunctionPrototype.pas',
  BESENObjectGlobal in 'BESEN\BESENObjectGlobal.pas',
  BESENObjectJSON in 'BESEN\BESENObjectJSON.pas',
  BESENObjectMath in 'BESEN\BESENObjectMath.pas',
  BESENObjectNativeFunction in 'BESEN\BESENObjectNativeFunction.pas',
  BESENObjectNumber in 'BESEN\BESENObjectNumber.pas',
  BESENObjectNumberConstructor in 'BESEN\BESENObjectNumberConstructor.pas',
  BESENObjectNumberPrototype in 'BESEN\BESENObjectNumberPrototype.pas',
  BESENObjectPropertyDescriptor in 'BESEN\BESENObjectPropertyDescriptor.pas',
  BESENObjectPrototype in 'BESEN\BESENObjectPrototype.pas',
  BESENObjectRegExp in 'BESEN\BESENObjectRegExp.pas',
  BESENObjectRegExpConstructor in 'BESEN\BESENObjectRegExpConstructor.pas',
  BESENObjectRegExpPrototype in 'BESEN\BESENObjectRegExpPrototype.pas',
  BESENObjectString in 'BESEN\BESENObjectString.pas',
  BESENObjectStringConstructor in 'BESEN\BESENObjectStringConstructor.pas',
  BESENObjectStringPrototype in 'BESEN\BESENObjectStringPrototype.pas',
  BESENObjectThrowTypeErrorFunction in 'BESEN\BESENObjectThrowTypeErrorFunction.pas',
  BESENOpcodes in 'BESEN\BESENOpcodes.pas',
  BESENParser in 'BESEN\BESENParser.pas',
  BESENPointerList in 'BESEN\BESENPointerList.pas',
  BESENPointerSelfBalancedTree in 'BESEN\BESENPointerSelfBalancedTree.pas',
  BESENRandomGenerator in 'BESEN\BESENRandomGenerator.pas',
  BESENRegExp in 'BESEN\BESENRegExp.pas',
  BESENRegExpCache in 'BESEN\BESENRegExpCache.pas',
  BESENScope in 'BESEN\BESENScope.pas',
  BESENSelfBalancedTree in 'BESEN\BESENSelfBalancedTree.pas',
  BESENStringList in 'BESEN\BESENStringList.pas',
  BESENStringTree in 'BESEN\BESENStringTree.pas',
  BESENStringUtils in 'BESEN\BESENStringUtils.pas',
  BESENTypes in 'BESEN\BESENTypes.pas',
  BESENUnicodeTables in 'BESEN\BESENUnicodeTables.pas',
  BESENUtils in 'BESEN\BESENUtils.pas',
  BESENValue in 'BESEN\BESENValue.pas',
  BESENValueContainer in 'BESEN\BESENValueContainer.pas',
  BESENVersionConstants in 'BESEN\BESENVersionConstants.pas'{$endif};

var ASMx86:TAssembler;
    SrcFileName,DstFileName,Defines,LastStatus,StatusTitle:ansistring;
    StatusOldLen:longint;

procedure ParseParameter;
var i,m{,c,o}:longint;
    p:boolean;
    s,l:ansistring;
begin
 if ParamCount<>0 then begin
  m:=0;
  for i:=1 to ParamCount do begin
   s:=ParamStr(i);
   if length(s)>0 then begin
    if not (s[1] in ['-','+','/']) then begin
     case m of
      0:begin
       SrcFileName:=s;
      end;
      1:begin
       DstFileName:=s;
      end;
     end;
     inc(m);
    end else begin
     p:=true;
     case s[1] of
      '+','/':p:=true;
      '-':p:=false;
     end;
     l:=copy(s,2,length(s)-1);
     s:=UpperCase(l);
     if Pos('D',s)=1 then begin
      l:=copy(s,2,length(s)-1);
      if Pos('=',s)>0 then begin
       Defines:=Defines+l+#13;
      end else begin
       if p then begin
        Defines:=Defines+l+'=1'+#13;
       end else begin
        Defines:=Defines+l+'=0'+#13;
       end;
      end;
     end;
    end;
   end;
  end;
 end else begin
  SrcFileName:='';
  DstFileName:='';
 end;
end;

procedure StatusProc(s:ansistring);
var Counter,StatusLen:longint;
begin
 if s<>LastStatus then begin
  StatusLen:=length(StatusTitle)+length(s);
  write(#13,StatusTitle,s);
  for Counter:=1 to StatusOldLen-StatusLen do begin
   write(' ');
  end;
  StatusOldLen:=StatusLen;
  LastStatus:=s;
 end;
end;

begin

 writeln('SASM - Scriptable Assembler - Version '+SASMVersionString);
 writeln(SASMCopyrightString);

 SrcFileName:='';
 DstFileName:='';
 Defines:='';
 LastStatus:='';
 StatusOldLen:=0;

 ParseParameter;

 if length(SrcFileName)>0 then begin
  if not FileExists(SrcFileName) then begin
   SrcFileName:=ChangeFileExt(SrcFileName,'.asm');
  end;
  //SrcFileName:=GetAbsoluteFile(GetCurrentDir,SrcFileName);
  if FileExists(SrcFileName) then begin
   if length(DstFileName)=0 then begin
    DstFileName:=ChangeFileExt(SrcFileName,'.bin');
   end;
  end;
  writeln('Assembling "'+SrcFileName+'" to "'+DstFileName+'" . . .');
  ASMx86:=TAssembler.Create;
  try
   ASMx86.Status:=StatusProc;
   LastStatus:='';
   StatusTitle:='Reading . . . ';
   if length(Defines)>0 then begin
    ASMx86.ParseDefines(Defines);
   end;
   ASMx86.ParseFile(SrcFileName);
   LastStatus:='';
   StatusTitle:='Assembling . . . ';
   ASMx86.WriteFile(DstFileName);
   if ASMx86.AreErrors then begin
    StatusTitle:='Errors ! ! !';
   end else begin
    StatusTitle:='Done ! ! !';
   end;
   StatusProc('');
   writeln;
   if ASMx86.AreErrors then begin
    writeln(ASMx86.Errors);
   end;
   if ASMx86.AreWarnings then begin
    writeln(ASMx86.Warnings);
   end;
  finally
   ASMx86.Free;
  end;
 end else begin
  writeln('  Usage: '+UPPERCASE(ChangeFileExt(ExtractFileName(PARAMSTR(0)),''))+' [infile] [outfile] [-|+|/|options]');
  writeln('Options: +Dx=y          = Define a constant symbol x with value x');
  writeln('         +Dx            = Define a constant symbol x with value 1');
  writeln('         -Dx            = Define a constant symbol x with value 0');
 end;
 writeln;
//readln;
end.
