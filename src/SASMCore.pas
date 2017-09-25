unit SASMCore;
{$i SASM.inc}

interface

uses {$ifdef Windows}Windows,{$endif}{$ifdef unix}baseunix,{$endif}SysUtils,Classes,Math,SASMData,
{$ifdef SASMBESEN}
     BESEN,BESENObject,BESENValue,BESENUtils,BESENTypes,BESENConstants,BESENGlobals,
     BESENObjectPropertyDescriptor,BESENNumberUtils,BESENStringUtils,BESENCharset,BESENErrors,
     BESENNativeObject,BESENDateUtils,
{$endif}
     PUCU;

const SASMVersionString='2017.09.25.09.06.0000';

      SASMCopyrightString='Copyright (C) 2003-2017, Benjamin ''BeRo'' Rosseaux';

      MaxUserSymbolListSize=2147483647 div SizeOf(pointer);

{$ifdef HASHING}
      MaxSymbolHashes=64;
{$endif}

      MaxOperands=5;

      PPS_WAIT=0;
      PPS_REP=1;
      PPS_LOCK=2;
      PPS_SEG=3;
      PPS_OSIZE=4;
      PPS_ASIZE=5;
      PPS_VEX=6;
      MAXPREFIX=7;

      MaxVEXClasses=3;

      P_NONE=0;
      P_A16=1;
      P_A32=2;
      P_A64=3;
      P_ASP=4;
      P_LOCK=5;
      P_O16=6;
      P_O32=7;
      P_O64=8;
      P_OSP=9;
      P_REP=10;
      P_REPE=11;
      P_REPNE=12;
      P_REPNZ=13;
      P_REPZ=14;
      P_WAIT=15;
      P_XACQUIRE=16;
      P_XRELEASE=17;
      P_BND=18;
      P_NOBND=19;
      P_EVEX=20;
      P_VEX3=21;
      P_VEX2=22;

      REX_MASK=$4f; // Actual REX prefix bits
      REX_B=$01;    // ModRM r/m extension
      REX_X=$02;    // SIB index extension
      REX_R=$04;    // ModRM reg extension
      REX_W=$08;    // 64-bit operand size
      REX_L=$20;    // Use LOCK prefix instead of REX.R
      REX_P=$40;    // REX prefix present/required
      REX_H=$80;    // High register present, REX forbidden
      REX_V=$100;   // Instruction uses VEX/XOP instead of REX
      REX_NH=$200;  // Instruction which doesn't use high regs
      REX_EV=$400;  // Instruction uses EVEX instead of REX

      EVEX_P0MM=$0f;       // EVEX P[3:0] : Legacy escape
      EVEX_P0RP=$10;       // EVEX P[4] : High-16 reg
      EVEX_P0X=$40;        // EVEX P[6] : High-16 rm
      EVEX_P1PP=$03;       // EVEX P[9:8] : Legacy prefix
      EVEX_P1VVVV=$78;     // EVEX P[14:11] : NDS register
      EVEX_P1W=$80;        // EVEX P[15] : Osize extension
      EVEX_P2AAA=$07;      // EVEX P[18:16] : Embedded opmask
      EVEX_P2VP=$08;       // EVEX P[19] : High-16 NDS reg
      EVEX_P2B=$10;        // EVEX P[20] : Broadcast / RC / SAE
      EVEX_P2LL=$60;       // EVEX P[22:21] : Vector length
      EVEX_P2RC=EVEX_P2LL; // EVEX P[22:21] : Rounding control
      EVEX_P2Z=$80;        // EVEX P[23] : Zeroing/Merging

      RV_VEX=0;  // C4/C5
      RV_XOP=1;  // 8F
      RV_EVEX=2; // 62

      EAF_BYTEOFFS=1;
      EAF_WORDOFFS=2;
      EAF_TIMESTWO=4;
      EAF_REL=8;
      EAF_ABS=16;
      EAF_FSGS=32;
      EAF_MIB=64;

      EAH_NOHINT=0;
      EAH_MAKEBASE=1;
      EAH_NOTBASE=2;
      EAH_SUMMED=3;

      EA_INVALID=0;
      EA_SCALAR=1;
      EA_XMMVSIB=2;
      EA_YMMVSIB=3;
      EA_ZMMVSIB=4;

      BRC_1TO2=1;
      BRC_1TO4=2;
      BRC_1TO8=3;
      BRC_1TO16=4;
      BRC_RN=5;
      BRC_RD=6;
      BRC_RU=7;
      BRC_RZ=8;
      BRC_SAE=9;
      BRC_Z=10;

      T_FV=1;
      T_HV=2;
      T_FVM=3;
      T_T1S8=4;
      T_T1S16=5;
      T_T1S=6;
      T_T1F32=7;
      T_T1F64=8;
      T_T2=9;
      T_T4=10;
      T_T8=11;
      T_HVM=12;
      T_QVM=13;
      T_OVM=14;
      T_M128=15;
      T_DUP=16;

      VL128=0;
      VL256=1;
      VL512=2;
      VLMAX=3;

      FUEF_NONE=0;
      FUEF_SEG16=1 shl 0;
      FUEF_OFS16=1 shl 1;
      FUEF_NOBASE=1 shl 2;
      FUEF_GOT=1 shl 3;
      FUEF_GOTPC=1 shl 4;
      FUEF_GOTOFF=1 shl 5;
      FUEF_GOTTPOFF=1 shl 6;
      FUEF_PLT=1 shl 7;
      FUEF_TLSIE=1 shl 8;
      FUEF_RELOCATION=1 shl 9;

      MATCH_ERROR_INVALID_OPCODE=-10;
      MATCH_ERROR_OPCODE_SIZE_MISSING=-9;
      MATCH_ERROR_OPCODE_SIZE_MISMATCH=-8;
      MATCH_ERROR_BROADCAST_SIZE_MISMATCH=-7;
      MATCH_ERROR_BAD_CPU=-6;
      MATCH_ERROR_BAD_MODE=-5;
      MATCH_ERROR_BAD_HLE=-4;
      MATCH_ERROR_ENCODING_MISMATCH=-3;
      MATCH_ERROR_BAD_BND=-2;
      MATCH_ERROR_BAD_REPNE=-1;
      MATCH_OKAY_JUMP=0;
      MATCH_OKAY_GOOD=1;

      BAUSignature='ASMx86Unit';

      ImportByHashTableLabelSymbolName='@ASMX86$IBH_IMPORTTABLE';
      ImportByHashLoadLibraryASymbolName='@ASMX86$IBH_LOADLIBRARYA';
      ImportByHashUseImportByName='@ASMX86$IBH_USEIMPORTBYNAME';
      ImportByHashUsePEB='@ASMX86$IBH_USEPEB';
      ImportByHashUseSEH='@ASMX86$IBH_USESEH';
      ImportByHashUseTOPSTACK='@ASMX86$IBH_USETOPSTACK';
      ImportByHashSafe='@ASMX86$IBH_SAFE';

      SourceDefines=-MAXLONGINT;

      MemoryDelta=1 shl 16;
      MemoryDeltaMask=MemoryDelta-1;

      asoFromBeginning=0;
      asoFromCurrent=1;
      asoFromEnd=2;

      IMPORTED_NAME_OFFSET=$00000002;
      IMAGE_ORDINAL_FLAG32=$80000000;
      IMAGE_ORDINAL_MASK32=$0000ffff;
      IMAGE_ORDINAL_FLAG64=uint64($8000000000000000);
      IMAGE_ORDINAL_MASK64=uint64($0000ffff);

      RTL_CRITSECT_TYPE=0;
      RTL_RESOURCE_TYPE=1;

      DLL_PROCESS_ATTACH=1;
      DLL_THREAD_ATTACH=2;
      DLL_THREAD_DETACH=3;
      DLL_PROCESS_DETACH=0;

      IMAGE_SizeHeader=20;

      IMAGE_FILE_RELOCS_STRIPPED=$0001;
      IMAGE_FILE_EXECUTABLE_IMAGE=$0002;
      IMAGE_FILE_LINE_NUMS_STRIPPED=$0004;
      IMAGE_FILE_LOCAL_SYMS_STRIPPED=$0008;
      IMAGE_FILE_AGGRESIVE_WS_TRIM=$0010;
      IMAGE_FILE_BYTES_REVERSED_LO=$0080;
      IMAGE_FILE_32BIT_MACHINE=$0100;
      IMAGE_FILE_DEBUG_STRIPPED=$0200;
      IMAGE_FILE_REMOVABLE_RUN_FROM_SWAP=$0400;
      IMAGE_FILE_NET_RUN_FROM_SWAP=$0800;
      IMAGE_FILE_SYSTEM=$1000;
      IMAGE_FILE_DLL=$2000;
      IMAGE_FILE_UP_SYSTEM_ONLY=$4000;
      IMAGE_FILE_BYTES_REVERSED_HI=$8000;

      IMAGE_FILE_MACHINE_UNKNOWN=0;
      IMAGE_FILE_MACHINE_I386=$14c;
      IMAGE_FILE_MACHINE_R3000=$162;
      IMAGE_FILE_MACHINE_R4000=$166;
      IMAGE_FILE_MACHINE_R10000=$168;
      IMAGE_FILE_MACHINE_ALPHA=$184;
      IMAGE_FILE_MACHINE_POWERPC=$1f0;
      IMAGE_FILE_MACHINE_AMD64=$8664;

      IMAGE_DLLCHARACTERISTICS_DYNAMIC_BASE=$0040;
      IMAGE_DLLCHARACTERISTICS_FORCE_INTEGRITY=$0080;
      IMAGE_DLLCHARACTERISTICS_NX_COMPAT=$0100;
      IMAGE_DLLCHARACTERISTICS_NO_ISOLATION=$0200;
      IMAGE_DLLCHARACTERISTICS_NO_SEH=$0400;
      IMAGE_DLLCHARACTERISTICS_NO_BIND=$0800;
      IMAGE_DLLCHARACTERISTICS_WDM_DRIVER=$2000;
      IMAGE_DLLCHARACTERISTICS_TERMINAL_SERVER_AWARE=$8000;

      IMAGE_NUMBEROF_DIRECTORY_ENTRIES=16;

      IMAGE_SUBSYSTEM_UNKNOWN=0;
      IMAGE_SUBSYSTEM_NATIVE=1;
      IMAGE_SUBSYSTEM_WINDOWS_GUI=2;
      IMAGE_SUBSYSTEM_WINDOWS_CUI=3;
      IMAGE_SUBSYSTEM_OS2_CUI=5;
      IMAGE_SUBSYSTEM_POSIX_CUI=7;
      IMAGE_SUBSYSTEM_WINDOWS_CE_GUI=9;
      IMAGE_SUBSYSTEM_EFI_APPLICATION=10;
      IMAGE_SUBSYSTEM_EFI_BOOT_SERVICE_DRIVER=11;
      IMAGE_SUBSYSTEM_EFI_RUNTIME_DRIVER=12;
      IMAGE_SUBSYSTEM_EFI_ROM=13;
      IMAGE_SUBSYSTEM_XBOX=14;
      IMAGE_SUBSYSTEM_WINDOWS_BOOT_APPLICATION=16;

      IMAGE_DIRECTORY_ENTRY_EXPORT=0;
      IMAGE_DIRECTORY_ENTRY_IMPORT=1;
      IMAGE_DIRECTORY_ENTRY_RESOURCE=2;
      IMAGE_DIRECTORY_ENTRY_EXCEPTION=3;
      IMAGE_DIRECTORY_ENTRY_SECURITY=4;
      IMAGE_DIRECTORY_ENTRY_BASERELOC=5;
      IMAGE_DIRECTORY_ENTRY_DEBUG=6;
      IMAGE_DIRECTORY_ENTRY_COPYRIGHT=7;
      IMAGE_DIRECTORY_ENTRY_GLOBALPTR=8;
      IMAGE_DIRECTORY_ENTRY_TLS=9;
      IMAGE_DIRECTORY_ENTRY_LOAD_CONFIG=10;
      IMAGE_DIRECTORY_ENTRY_BOUND_IMPORT=11;
      IMAGE_DIRECTORY_ENTRY_IAT=12;

      IMAGE_SIZEOF_SHORT_NAME=8;
      
      IMAGE_SCN_TYIMAGE_REG=$00000000;
      IMAGE_SCN_TYIMAGE_DSECT=$00000001;
      IMAGE_SCN_TYIMAGE_NOLOAD=$00000002;
      IMAGE_SCN_TYIMAGE_GROUP=$00000004;
      IMAGE_SCN_TYIMAGE_NO_PAD=$00000008;
      IMAGE_SCN_TYIMAGE_COPY=$00000010;
      IMAGE_SCN_CNT_CODE=$00000020;
      IMAGE_SCN_CNT_INITIALIZED_DATA=$00000040;
      IMAGE_SCN_CNT_UNINITIALIZED_DATA=$00000080;
      IMAGE_SCN_LNK_OTHER=$00000100;
      IMAGE_SCN_LNK_INFO=$00000200;
      IMAGE_SCN_TYIMAGE_OVER=$0000400;
      IMAGE_SCN_LNK_REMOVE=$00000800;
      IMAGE_SCN_LNK_COMDAT=$00001000;
      IMAGE_SCN_MEM_PROTECTED=$00004000;
      IMAGE_SCN_MEM_FARDATA=$00008000;
      IMAGE_SCN_MEM_SYSHEAP=$00010000;
      IMAGE_SCN_MEM_PURGEABLE=$00020000;
      IMAGE_SCN_MEM_16BIT=$00020000;
      IMAGE_SCN_MEM_LOCKED=$00040000;
      IMAGE_SCN_MEM_PRELOAD=$00080000;
      IMAGE_SCN_ALIGN_1BYTES=$00100000;
      IMAGE_SCN_ALIGN_2BYTES=$00200000;
      IMAGE_SCN_ALIGN_4BYTES=$00300000;
      IMAGE_SCN_ALIGN_8BYTES=$00400000;
      IMAGE_SCN_ALIGN_16BYTES=$00500000;
      IMAGE_SCN_ALIGN_32BYTES=$00600000;
      IMAGE_SCN_ALIGN_64BYTES=$00700000;
      IMAGE_SCN_ALIGN_1286BYTES=$00800000;
      IMAGE_SCN_ALIGN_256BYTES=$00900000;
      IMAGE_SCN_ALIGN_512BYTES=$00a00000;
      IMAGE_SCN_ALIGN_1024BYTES=$00b00000;
      IMAGE_SCN_ALIGN_2048BYTES=$00c00000;
      IMAGE_SCN_ALIGN_4096BYTES=$00d00000;
      IMAGE_SCN_ALIGN_8192BYTES=$00e00000;
      IMAGE_SCN_LNK_NRELOC_OVFL=$01000000;
      IMAGE_SCN_MEM_DISCARDABLE=$02000000;
      IMAGE_SCN_MEM_NOT_CACHED=$04000000;
      IMAGE_SCN_MEM_NOT_PAGED=$08000000;
      IMAGE_SCN_MEM_SHARED=$10000000;
      IMAGE_SCN_MEM_EXECUTE=$20000000;
      IMAGE_SCN_MEM_READ=$40000000;
      IMAGE_SCN_MEM_WRITE=longword($80000000);
      IMAGE_SCN_CNT_RESOURCE:int64=$100000000;

      IMAGE_SCN_MAX_RELOC=$ffff;

      IMAGE_REL_BASED_ABSOLUTE=0;
      IMAGE_REL_BASED_HIGH=1;
      IMAGE_REL_BASED_LOW=2;
      IMAGE_REL_BASED_HIGHLOW=3;
      IMAGE_REL_BASED_HIGHADJ=4;
      IMAGE_REL_BASED_MIPS_JMPADDR=5;
      IMAGE_REL_BASED_ARM_MOV32A=5;
      IMAGE_REL_BASED_SECTION=6;
      IMAGE_REL_BASED_REL32=7;
      IMAGE_REL_BASED_ARM_MOV32T=7;
      IMAGE_REL_BASED_MIPS_JMPADDR16=9;
      IMAGE_REL_BASED_IA64_IMM64=9;
      IMAGE_REL_BASED_DIR64=10;
      IMAGE_REL_BASED_HIGH3ADJ=11;

      IMAGE_REL_I386_ABSOLUTE=$0000;
      IMAGE_REL_I386_DIR16=$0001;
      IMAGE_REL_I386_REL16=$0002;
      IMAGE_REL_I386_DIR32=$0006;
      IMAGE_REL_I386_DIR32NB=$0007;
      IMAGE_REL_I386_SEG12=$0009;
      IMAGE_REL_I386_SECTION=$000a;
      IMAGE_REL_I386_SECREL=$000b;
      IMAGE_REL_I386_TOKEN=$000c;
      IMAGE_REL_I386_SECREL7=$000d;
      IMAGE_REL_I386_REL32=$0014;

      IMAGE_REL_AMD64_ABSOLUTE=$0000;
      IMAGE_REL_AMD64_ADDR64=$0001;
      IMAGE_REL_AMD64_ADDR32=$0002;
      IMAGE_REL_AMD64_ADDR32NB=$0003;
      IMAGE_REL_AMD64_REL32=$0004;
      IMAGE_REL_AMD64_REL32_1=$0005;
      IMAGE_REL_AMD64_REL32_2=$0006;
      IMAGE_REL_AMD64_REL32_3=$0007;
      IMAGE_REL_AMD64_REL32_4=$0008;
      IMAGE_REL_AMD64_REL32_5=$0009;
      IMAGE_REL_AMD64_SECTION=$000a;
      IMAGE_REL_AMD64_SECREL=$000b;
      IMAGE_REL_AMD64_SECREL7=$000c;
      IMAGE_REL_AMD64_TOKEN=$000d;
      IMAGE_REL_AMD64_SREL32=$000e;
      IMAGE_REL_AMD64_PAIR=$000f;
      IMAGE_REL_AMD64_SSPAN32=$0010;

      IMAGE_SYM_CLASS_END_OF_FUNCTION=byte(-1); ///< Physical end of function
      IMAGE_SYM_CLASS_NULL=0;                   ///< No symbol
      IMAGE_SYM_CLASS_AUTOMATIC=1;              ///< Stack variable
      IMAGE_SYM_CLASS_EXTERNAL=2;               ///< External symbol
      IMAGE_SYM_CLASS_STATIC=3;                 ///< Static
      IMAGE_SYM_CLASS_REGISTER=4;               ///< Register variable
      IMAGE_SYM_CLASS_EXTERNAL_DEF=5;           ///< External definition
      IMAGE_SYM_CLASS_LABEL=6;                  ///< Label
      IMAGE_SYM_CLASS_UNDEFINED_LABEL=7;        ///< Undefined label
      IMAGE_SYM_CLASS_MEMBER_OF_STRUCT=8;       ///< Member of structure
      IMAGE_SYM_CLASS_ARGUMENT=9;               ///< Function argument
      IMAGE_SYM_CLASS_STRUCT_TAG=10;            ///< Structure tag
      IMAGE_SYM_CLASS_MEMBER_OF_UNION=11;       ///< Member of union
      IMAGE_SYM_CLASS_UNION_TAG=12;             ///< Union tag
      IMAGE_SYM_CLASS_TYPE_DEFINITION=13;       ///< Type definition
      IMAGE_SYM_CLASS_UNDEFINED_STATIC=14;      ///< Undefined static
      IMAGE_SYM_CLASS_ENUM_TAG=15;              ///< Enumeration tag
      IMAGE_SYM_CLASS_MEMBER_OF_ENUM=16;        ///< Member of enumeration
      IMAGE_SYM_CLASS_REGISTER_PARAM=17;        ///< Register parameter
      IMAGE_SYM_CLASS_BIT_FIELD=18;             ///< Bit field
      /// ".bb" or ".eb" - beginning or end of block
      IMAGE_SYM_CLASS_BLOCK=100;
      /// ".bf" or ".ef" - beginning or end of function
      IMAGE_SYM_CLASS_FUNCTION=101;
      IMAGE_SYM_CLASS_END_OF_STRUCT=102;        ///< End of structure
      IMAGE_SYM_CLASS_FILE=103;                 ///< File name
      /// Line number, reformatted as symbol
      IMAGE_SYM_CLASS_SECTION=104;
      IMAGE_SYM_CLASS_WEAK_EXTERNAL=105;        ///< Duplicate tag
      /// External symbol in dmert public lib
      IMAGE_SYM_CLASS_CLR_TOKEN=107;

      PAGE_NOACCESS=1;
      PAGE_READONLY=2;
      PAGE_READWRITE=4;
      PAGE_WRITECOPY=8;
      PAGE_EXECUTE=$10;
      PAGE_EXECUTE_READ=$20;
      PAGE_EXECUTE_READWRITE=$40;
      PAGE_EXECUTE_WRITECOPY=$80;
      PAGE_GUARD=$100;
      PAGE_NOCACHE=$200;
      MEM_COMMIT=$1000;
      MEM_RESERVE=$2000;
      MEM_DECOMMIT=$4000;
      MEM_RELEASE=$8000;
      MEM_FREE=$10000;
      MEM_PRIVATE=$20000;
      MEM_MAPPED=$40000;
      MEM_RESET=$80000;
      MEM_TOP_DOWN=$100000;
      SEC_FILE=$800000;
      SEC_IMAGE=$1000000;
      SEC_RESERVE=$4000000;
      SEC_COMMIT=$8000000;
      SEC_NOCACHE=$10000000;
      MEM_IMAGE=SEC_IMAGE;

      PE_SCN_TYPE_REG=$00000000;
      PE_SCN_TYPE_DSECT=$00000001;
      PE_SCN_TYPE_NOLOAD=$00000002;
      PE_SCN_TYPE_GROUP=$00000004;
      PE_SCN_TYPE_NO_PAD=$00000008;
      PE_SCN_TYPE_COPY=$00000010;
      PE_SCN_CNT_CODE=$00000020;
      PE_SCN_CNT_INITIALIZED_DATA=$00000040;
      PE_SCN_CNT_UNINITIALIZED_DATA=$00000080;
      PE_SCN_LNK_OTHER=$00000100;
      PE_SCN_LNK_INFO=$00000200;
      PE_SCN_TYPE_OVER=$0000400;
      PE_SCN_LNK_REMOVE=$00000800;
      PE_SCN_LNK_COMDAT=$00001000;
      PE_SCN_MEM_PROTECTED=$00004000;
      PE_SCN_MEM_FARDATA=$00008000;
      PE_SCN_MEM_SYSHEAP=$00010000;
      PE_SCN_MEM_PURGEABLE=$00020000;
      PE_SCN_MEM_16BIT=$00020000;
      PE_SCN_MEM_LOCKED=$00040000;
      PE_SCN_MEM_PRELOAD=$00080000;
      PE_SCN_ALIGN_1BYTES=$00100000;
      PE_SCN_ALIGN_2BYTES=$00200000;
      PE_SCN_ALIGN_4BYTES=$00300000;
      PE_SCN_ALIGN_8BYTES=$00400000;
      PE_SCN_ALIGN_16BYTES=$00500000;
      PE_SCN_ALIGN_32BYTES=$00600000;
      PE_SCN_ALIGN_64BYTES=$00700000;
      PE_SCN_LNK_NRELOC_OVFL=$01000000;
      PE_SCN_MEM_DISCARDABLE=$02000000;
      PE_SCN_MEM_NOT_CACHED=$04000000;
      PE_SCN_MEM_NOT_PAGED=$08000000;
      PE_SCN_MEM_SHARED=$10000000;
      PE_SCN_MEM_EXECUTE=$20000000;
      PE_SCN_MEM_READ=$40000000;
      PE_SCN_MEM_WRITE=longword($80000000);

      PECOFFSectionAlignment=$1000;
      PECOFFFileAlignment=$200;

      ustNONE=0;
      ustLABEL=1;
      ustVARIABLE=2;
      ustDEFINE=3;
      ustONELINEMACRO=4;
      ustMACRO=5;
      ustSCRIPTMACRO=6;
      ustIMPORT=7;
      ustSEGMENT=8;
      ustSTRUCT=9;
      ustUNIT=10;
      ustREPLACER=11;
      ustCONSTANTSTRUCT=12;

      tcitNone=0;
      tcitStart=1;
      tcitInstruction=2;
      tcitLabel=3;
      tcitConstant=4;
      tcitTimes=5;
      tcitData=6;
      tcitDataRawString=7;
      tcitDataEmpty=24;
      tcitENTRYPOINT=32;
      tcitOFFSET=33;
      tcitSTARTOFFSET=34;
      tcitALIGN=35;
      tcitCPU=36;
      tcitBITS=37;
      tcitSTACK=38;
      tcitHEAP=39;
      tcitCODEBASE=40;
      tcitIMAGEBASE=41;
      tcitLIBRARY=44;
      tcitIMPORT=45;
      tcitEXPORT=46;
      tcitREPEAT=47;
      tcitWHILE=48;
      tcitIF=49;
      tcitEND=50;
      tcitSMARTLINK=51;
      tcitBYTEDIFF=52;
      tcitSTRUCTRESET=53;
      tcitSTRUCTVAR=54;
      tcitUSERENTRYPOINT=55;
      tcitSECTION=56;
      tcitSEGMENT=57;
      tcitDIRECTORYENTRY=58;
      tcitWARNING=59;
      tcitERROR=60;
      tcitSCRIPT=61;
      tcitSUBSYSTEM=62;
      tcitCHARACTERISTICS=63;
      tcitDLLCHARACTERISTICS=64;
      tcitSIZEOFSTACKRESERVE=65;
      tcitSIZEOFSTACKCOMMIT=66;
      tcitSIZEOFHEAPRESERVE=67;
      tcitSIZEOFHEAPCOMMIT=68;
      tcitELFTYPE=69;

      titNAME=0;
      titORDINAL=1;
      titHASHIBN=2;
      titHASHPEB=3;
      titHASHSEH=4;
      titHASHTOPSTACK=5;

      titHASH=titHASHIBN;

      nvfNONE=0;
      nvfNORELOCATION=1 shl 0;

      mbmDefault=0;
      mbmSignedWarning=1;
      mbmSignedError=2;
      mbmByteSignedWarning=3;

      IntegerValueBits=1024; // must be divisible by 32, because a limb in this implementation is a 32-bit dword
      IntegerValueDWords=IntegerValueBits shr 5;

      AVT_NONE=0;
      AVT_INT=1;
      AVT_FLOAT=2;
      AVT_STRING=3;

      EF__NONE=0;
      EF__MACRO_COUNT_PARAMETERS__=1;
      EF__MACRO_PARAMETER__=2;
      EF__STRCOPY__=3;
      EF__STRLEN__=4;
      EF__UTF8__=5;
      EF__UTF16BE__=6;
      EF__UTF16LE__=7;
      EF__UTF32BE__=8;
      EF__UTF32LE__=9;

type PIntegerValue=^TIntegerValue;
     TIntegerValue=array[0..IntegerValueDWords-1] of longword;

     EStringToFloat=class(Exception);

     PSASMPtrUInt=^TSASMPtrUInt;
     PSASMPtrInt=^TSASMPtrInt;

{$ifdef fpc}
 {$undef OldDelphi}
     TSASMUInt64=uint64;
     TSASMPtrUInt=PtrUInt;
     TSASMPtrInt=PtrInt;
{$else}
 {$ifdef conditionalexpressions}
  {$if CompilerVersion>=23.0}
   {$undef OldDelphi}
     TSASMUInt64=uint64;
     TSASMPtrUInt=NativeUInt;
     TSASMPtrInt=NativeInt;
  {$else}
   {$define OldDelphi}
  {$ifend}
 {$else}
  {$define OldDelphi}
 {$endif}
{$endif}
{$ifdef OldDelphi}
  {$if CompilerVersion>=15.0}
     TSASMUInt64=uint64;
  {$else}
     TSASMUInt64=int64;
  {$ifend}
  {$ifdef CPU64}
     TSASMPtrUInt=uint64;
     TSASMPtrInt=int64;
  {$else}
     TSASMPtrUInt=longword;
     TSASMPtrInt=longint;
  {$endif}
{$endif}

     PIEEEFormat=^TIEEEFormat;
     TIEEEFormat=record
      Bytes:longint;
      Mantissa:longint;
      Explicit:longint;
      Exponent:longint;
     end;

     TTarget=(ttBIN,ttCOM,ttMZEXE,ttPEEXE32,ttPEEXE64,ttCOFFDOS,ttCOFF32,ttCOFF64,ttELF32,ttELFX32,ttELF64,ttOMF16,ttOMF32,ttUNIT,ttRUNTIME,ttTRI32,ttTRI64);

     TTargets=set of TTarget;

     TCharSet=set of ansichar;

     PPOINTER=^pointer;

     plongword=^longword;
     PPLONGWORD=^plongword;

     pword=^word;
     PPWORD=^pword;

     HINST=longword;
     HMODULE=HINST;

     PWordArray=^TWordArray;
     TWordArray=array[0..(2147483647 div SizeOf(word))-1] of word;

     PLongWordArray=^TLongWordArray;
     TLongWordArray=array [0..(2147483647 div SizeOf(longword))-1] of longword;

{$ifdef SASMBESEN}
     TFileObject=class(TBESENNativeObject)
      private
       fFileName:TBESENString;
       fFileStream:TFileStream;
      protected
       procedure ConstructObject(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint); override;
       procedure InitializeObject; override;
       procedure FinalizeObject; override;
      public
       constructor Create(AInstance:TObject;APrototype:TBESENObject=nil;AHasPrototypeProperty:longbool=false); override;
       destructor Destroy; override;
      published
       procedure close(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
       procedure read(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
       procedure write(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
       procedure seek(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
       procedure position(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
       procedure eof(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
       procedure flush(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
       property fileName:TBESENString read fFileName write fFileName;
     end;
{$endif}

     PAssemblerSection=^TAssemblerSection;

     PPECOFFDirectoryEntry=^TPECOFFDirectoryEntry;
     TPECOFFDirectoryEntry=record
      Section:PAssemblerSection;
      Position:uint64;
      Size:uint64;
     end;

     PPECOFFDirectoryEntries=^TPECOFFDirectoryEntries;
     TPECOFFDirectoryEntries=array[0..IMAGE_NUMBEROF_DIRECTORY_ENTRIES-1] of TPECOFFDirectoryEntry;

     TMZEXEHeader=packed record
      Signature:word; // 00
      PartPag:word;   // 02
      PageCnt:word;   // 04
      ReloCnt:word;   // 06
      HdrSize:word;   // 08
      MinMem:word;    // 0a
      MaxMem:word;    // 0c
      ReloSS:word;    // 0e
      ExeSP:word;     // 10
      ChkSum:word;    // 12
      ExeIP:word;     // 14
      ReloCS:word;    // 16
      TablOff:word;   // 18
      Overlay:word;   // 1a
     end;

     PImageDOSHeader=^TImageDOSHeader;
     TImageDOSHeader=packed record
      Signature:word; // 00
      PartPag:word;   // 02
      PageCnt:word;   // 04
      ReloCnt:word;   // 06
      HdrSize:word;   // 08
      MinMem:word;    // 0a
      MaxMem:word;    // 0c
      ReloSS:word;    // 0e
      ExeSP:word;     // 10
      ChkSum:word;    // 12
      ExeIP:word;     // 14
      ReloCS:word;    // 16
      TablOff:word;   // 18
      Overlay:word;   // 1a
      Reserved:packed array[0..3] of word;
      OEMID:word;
      OEMInfo:word;
      Reserved2:packed array[0..9] of word;
      LFAOffset:longword;
     end;

     TISHMisc=packed record
      case longint of
       0:(PhysicalAddress:longword);
       1:(VirtualSize:longword);
     end;

     PImageExportDirectory=^TImageExportDirectory;
     TImageExportDirectory=packed record
      Characteristics:longword;
      TimeDateStamp:longword;
      MajorVersion:word;
      MinorVersion:word;
      Name:longword;
      Base:longword;
      NumberOfFunctions:longword;
      NumberOfNames:longword;
      AddressOfFunctions:PPLONGWORD;
      AddressOfNames:PPLONGWORD;
      AddressOfNameOrdinals:PPWORD;
     end;

     PImageSectionHeader=^TImageSectionHeader;
     TImageSectionHeader=packed record
      Name:packed array[0..IMAGE_SIZEOF_SHORT_NAME-1] of byte;
      Misc:TISHMisc;
      VirtualAddress:longword;
      SizeOfRawData:longword;
      PointerToRawData:longword;
      PointerToRelocations:longword;
      PointerToLineNumbers:longword;
      NumberOfRelocations:word;
      NumberOfLineNumbers:word;
      Characteristics:longword;
     end;

     PImageSectionHeaders=^TImageSectionHeaders;
     TImageSectionHeaders=array[0..(2147483647 div SizeOf(TImageSectionHeader))-1] of TImageSectionHeader;

     PImageDataDirectory=^TImageDataDirectory;
     TImageDataDirectory=packed record
      VirtualAddress:longword;
      Size:longword;
     end;

     PImageFileHeader=^TImageFileHeader;
     TImageFileHeader=packed record
      Machine:word;
      NumberOfSections:word;
      TimeDateStamp:longword;
      PointerToSymbolTable:longword;
      NumberOfSymbols:longword;
      SizeOfOptionalHeader:word;
      Characteristics:word;
     end;

     PImageOptionalHeader=^TImageOptionalHeader;
     TImageOptionalHeader=packed record
      Magic:word;
      MajorLinkerVersion:byte;
      MinorLinkerVersion:byte;
      SizeOfCode:longword;
      SizeOfInitializedData:longword;
      SizeOfUninitializedData:longword;
      AddressOfEntryPoint:longword;
      BaseOfCode:longword;
      BaseOfData:longword;
      ImageBase:longword;
      SectionAlignment:longword;
      FileAlignment:longword;
      MajorOperatingSystemVersion:word;
      MinorOperatingSystemVersion:word;
      MajorImageVersion:word;
      MinorImageVersion:word;
      MajorSubsystemVersion:word;
      MinorSubsystemVersion:word;
      Win32VersionValue:longword;
      SizeOfImage:longword;
      SizeOfHeaders:longword;
      CheckSum:longword;
      Subsystem:word;
      DLLCharacteristics:word;
      SizeOfStackReserve:longword;
      SizeOfStackCommit:longword;
      SizeOfHeapReserve:longword;
      SizeOfHeapCommit:longword;
      LoaderFlags:longword;
      NumberOfRvaAndSizes:longword;
      DataDirectory:packed array[0..IMAGE_NUMBEROF_DIRECTORY_ENTRIES-1] of TImageDataDirectory;
     end;

     PImageOptionalHeader64=^TImageOptionalHeader64;
     TImageOptionalHeader64=packed record
      Magic:word;
      MajorLinkerVersion:byte;
      MinorLinkerVersion:byte;
      SizeOfCode:longword;
      SizeOfInitializedData:longword;
      SizeOfUninitializedData:longword;
      AddressOfEntryPoint:longword;
      BaseOfCode:longword;
      ImageBase:uint64;
      SectionAlignment:longword;
      FileAlignment:longword;
      MajorOperatingSystemVersion:word;
      MinorOperatingSystemVersion:word;
      MajorImageVersion:word;
      MinorImageVersion:word;
      MajorSubsystemVersion:word;
      MinorSubsystemVersion:word;
      Win32VersionValue:longword;
      SizeOfImage:longword;
      SizeOfHeaders:longword;
      CheckSum:longword;
      Subsystem:word;
      DLLCharacteristics:word;
      SizeOfStackReserve:uint64;
      SizeOfStackCommit:uint64;
      SizeOfHeapReserve:uint64;
      SizeOfHeapCommit:uint64;
      LoaderFlags:longword;
      NumberOfRvaAndSizes:longword;
      DataDirectory:packed array[0..IMAGE_NUMBEROF_DIRECTORY_ENTRIES-1] of TImageDataDirectory;
     end;

     PImageNTHeaders=^TImageNTHeaders;
     TImageNTHeaders=packed record
      Signature:longword;
      FileHeader:TImageFileHeader;
      case boolean of
       false:(
        OptionalHeader:TImageOptionalHeader;
       );
       true:(
        OptionalHeader64:TImageOptionalHeader64;
       );
     end;

     PImageImportDescriptor=^TImageImportDescriptor;
     TImageImportDescriptor=packed record
      OriginalFirstThunk:longword;
      TimeDateStamp:longword;
      ForwarderChain:longword;
      Name:longword;
      FirstThunk:longword;
     end;

     PImageBaseRelocation=^TImageBaseRelocation;
     TImageBaseRelocation=packed record
      VirtualAddress:longword;
      SizeOfBlock:longword;
     end;

     PImageThunkData=^TImageThunkData;
     TImageThunkData=packed record
      ForwarderString:longword;
      Funktion:longword;
      Ordinal:longword;
      AddressOfData:longword;
     end;

     PSection=^TSection;
     TSection=packed record
      Base:pointer;
      RVA:longword;
      Size:longword;
      Characteristics:longword;
     end;

     TSections=array of TSection;

     TDLLEntryProc=function(hinstDLL:HMODULE;dwReason:longword;lpvReserved:pointer):boolean; stdcall;

     TNameOrID=(niName,niID);

     TExternalLibrary=record
      LibraryName:ansistring;
      LibraryHandle:HINST;
     end;

     TExternalLibrarys=array of TExternalLibrary;

     PDLLFunctionImport=^TDLLFunctionImport;
     TDLLFunctionImport=record
      NameOrID:TNameOrID;
      Name:ansistring;
      ID:longint;
     end;

     PDLLImport=^TDLLImport;
     TDLLImport=record
      LibraryName:ansistring;
      LibraryHandle:HINST;
      Entries:array of TDLLFunctionImport;
     end;

     TImports=array of TDLLImport;

     PDLLFunctionExport=^TDLLFunctionExport;
     TDLLFunctionExport=record
      Name:ansistring;
      index:longint;
      FunctionPointer:pointer;
     end;

     TExports=array of TDLLFunctionExport;

     TExportTreeLink=record
      Link:pointer;
      OrdinalIndex:longint;
     end;

     PExportTreeNode=^TExportTreeNode;
     TExportTreeNode=record
      TheChar:ansichar;
      Link:TExportTreeLink;
      LinkExist:boolean;
      Prevoius,Next,Up,Down:PExportTreeNode;
     end;

     TOpcodes=OpSTART..OpEND;
     TRegister=RegSTART..RegEND;

     TName=longint;

     TOperandCount=0..MaxOperands;

     PGlobalDefault=^TGlobalDefault;
     TGlobalDefault=(GD_REL,GD_BND);

     PGlobalDefaults=^TGlobalDefaults;
     TGlobalDefaults=set of TGlobalDefault;

     TAssemblerExpression=class;

     PAssemblerSegment=^TAssemblerSegment;
     TAssemblerSegment=record
      Name:ansistring;
      Position:uint64;
      Previous,Next:PAssemblerSegment;
     end;

     TAssemblerSection=record
      Name:ansistring;
      FreezedFlags:TIntegerValue;
      FreezedAlign:TIntegerValue;
      Flags:TAssemblerExpression;
      Align:TAssemblerExpression;
      Data:TMemoryStream;
      FixUpExpressions:TList;
      RelocationFixUpExpressions:TList;
      Position:uint64;
      CompleteOffset:uint64;
      Offset:uint64;
      FileOffset:uint64;
      Index:longint;
      ObjectSectionIndex:longint;
      ObjectSectionRelocationIndex:longint;
      Previous:PAssemblerSection;
      Next:PAssemblerSection;
     end;

     PFloatValue=^TFloatValue;
     TFloatValue=record
      Bytes:array[0..63] of byte;
      Count:longint;
     end;

     PAssemblerValue=^TAssemblerValue;
     TAssemblerValue=record
      StringValue:ansistring;
      case ValueType:longint of
       AVT_INT:(IntegerValue:TIntegerValue);
       AVT_FLOAT:(FloatValue:TFloatValue);
     end;

     PValueFlags=^TValueFlags;
     TValueFlags=longword;

     PEA=^TEA;
     TEA=record
      EAType:longint;
      SIBPresent:longbool;
      Bytes:longint;
      Size:longint;
      MODRM:byte;
      SIB:byte;
      REX:byte;
      Relative:boolean;
      Displacement:shortint;
     end;

     PDecoratorFlags=^TDecoratorFlags;
     TDecoratorFlags=uint64;

     PFixUpExpressionFlags=^TFixUpExpressionFlags;
     TFixUpExpressionFlags=longword;

     POperand=^TOperand;
     TOperand=record
      Flags:TOperandFlags;
      DecoratorFlags:TDecoratorFlags;
      FixUpExpressionFlags:TFixUpExpressionFlags;
      DisplacmentSize:longint;
      BaseRegister:TRegister;
      IndexRegister:TRegister;
      RIPRegister:longbool;
      Scale:TAssemblerExpression;
      Value:TAssemblerExpression;
      HintBase:longint;
      HintType:longint;
      EAFlags:longint;
{$ifdef DEBUGGER}
      Column:longint;
{$endif}
     end;

     PInstruction=^TInstruction;
     TInstruction=record
      Flags:TInstructionFlags;
      Prefixes:array[0..MAXPREFIX-1] of longword;
      Opcode:TOpcodes;
      CountOperands:TOperandCount;
      Operand:array[1..MaxOperands] of TOperand;
      AddressSize:longint;
      REX:longint;
      REXDone:longbool;
      VEXRegister:longint;
      VEX_CM:longint;
      VEX_WLP:longint;
      evex_p:array[0..3] of byte;
      evex_tuple:longint;
      evex_rm:longint;
      evex_brerop:shortint;
     end;

     TCodeItemType=byte;

     PPCode=^PCode;
     PCode=^TCode;
     TCode=record
      CodeItemType:TCodeItemType;
{$ifdef IDE}
      OpcodeInfoIndex:longint;
{$endif}
{$ifdef DEBUGGER}
      BytePosition:longint;
{$endif}
      Instruction:TInstruction;
      Value:int64;
      SymbolIndex:longint;
      StructSymbolIndex:longint;
      ItemStructSymbolIndex:longint;
      ItemSize:longint;
      Expression:TAssemblerExpression;
      SecondExpression:TAssemblerExpression;
      StringData:ansistring;
      WideStringData:widestring;
      LineNumber:longint;
      Column:longint;
      Source:longint;
      Segment:PAssemblerSegment;
      Section:PAssemblerSection;
      Link:PCode;
      Up,Down,ElseDown:PCode;
      Previous,Next:PCode;
     end;

     TUserSymbol=class;

     PFixUpExpression=^TFixUpExpression;
     TFixUpExpression=record
      Segment:PAssemblerSegment;
      Section:PAssemblerSection;
      Position:longint;
      Flags:longword;
      Expression:TAssemblerExpression;
      Bits:longword;
      Signed:longint;
      Relative:boolean;
      Relocation:boolean;
      Symbol:TUserSymbol;
      LineNumber:longint;
      Column:longint;
      Source:longint;
      ManualBoundMode:longint;
      MinBound:uint64;
      MaxBound:uint64;
      BoundWarningOrError:ansistring;
      HereOffset:longint;
      Next:PFixUpExpression;
     end;

     PCharArray=^TCharArray;
     TCharArray=array[0..(2147483647 div SizeOf(ansichar))-1] of ansichar;

     pbyte=^TBYTE;
     TBYTE=byte;

     PBytes=^TBytes;
     TBytes=array[0..(2147483647 div SizeOf(TBYTE))-1] of TBYTE;

     TSymbolTree=class;

     TAssembler=class;

     TStringIntegerPairHashMapData=int64;

     PStringIntegerPairHashMapEntity=^TStringIntegerPairHashMapEntity;
     TStringIntegerPairHashMapEntity=record
      Key:ansistring;
      Value:TStringIntegerPairHashMapData;
     end;

     TStringIntegerPairHashMapEntities=array of TStringIntegerPairHashMapEntity;

     TStringIntegerPairHashMapEntityIndices=array of longint;

     TStringIntegerPairHashMap=class
      private
       function FindCell(const Key:ansistring):longword;
       procedure Resize;
      protected
       function GetValue(const Key:ansistring):TStringIntegerPairHashMapData;
       procedure SetValue(const Key:ansistring;const Value:TStringIntegerPairHashMapData);
      public
       RealSize:longint;
       LogSize:longint;
       Size:longint;
       Entities:TStringIntegerPairHashMapEntities;
       EntityToCellIndex:TStringIntegerPairHashMapEntityIndices;
       CellToEntityIndex:TStringIntegerPairHashMapEntityIndices;
       constructor Create;
       destructor Destroy; override;
       procedure Clear;
       function Add(const Key:ansistring;Value:TStringIntegerPairHashMapData):PStringIntegerPairHashMapEntity;
       function Get(const Key:ansistring;CreateIfNotExist:boolean=false):PStringIntegerPairHashMapEntity;
       function Delete(const Key:ansistring):boolean;
       property Values[const Key:ansistring]:TStringIntegerPairHashMapData read GetValue write SetValue; default;
     end;

     TAssemblerExpression=class
      public
       Operation:ansichar;
       Value:TAssemblerValue;
       MetaValue:longint;
       MetaFlags:longint;
       Left:TAssemblerExpression;
       Right:TAssemblerExpression;
       SecondRight:TAssemblerExpression;
       constructor Create;
       destructor Destroy; override;
       procedure Assign(From:TAssemblerExpression);
       procedure AssignParameters(const Parameters:TList);
       function Evaluate(ASMx86:TAssembler;NoErrors:boolean=false):TAssemblerValue;
       procedure Freeze(ASMx86:TAssembler;NoErrors:boolean=false);
//     procedure Generate(ASMx86:TAssembler;First:boolean;Bits:longint;Memory:boolean);
       function UseIt(ASMx86:TAssembler):boolean;
       function Optimize(ASMx86:TAssembler):boolean;
       function HasOperation(AOperationSet:TCharSet):boolean;
       function GetFixUpExpressionFlags(const ASMx86:TAssembler):TFixUpExpressionFlags;
       function HasFixUpSymbolReference(const ASMx86:TAssembler):boolean;
       function IsConstant(const ASMx86:TAssembler):boolean;
       function GetFixUpSymbol(const ASMx86:TAssembler):TUserSymbol;
       function HasValueType(const ASMx86:TAssembler;const ValueType:longint;const Level:longint=0):boolean;
       function IsInteger(const ASMx86:TAssembler):boolean;
       function Equals(const WithExpression:TAssemblerExpression):boolean; {$ifdef fpc}reintroduce;{$endif}
       function Has(const Expression:TAssemblerExpression):boolean;
       procedure MarkAsNoRelocation;
     end;

     TAssemblerImportLibraryItem=class
      public
       Name:ansistring;
       NameAddr:uint64;
       OrgImportsAddr:uint64;
       ImportsAddr:uint64;
       Handle:uint64;
       Used:boolean;
       constructor Create;
       destructor Destroy; override;
     end;

     TAssemblerImportItem=class
      public
       Name:ansistring;
       NameAddr:uint64;
       ProcAddr:uint64;
       ImportLibrary:TAssemblerImportLibraryItem;
       Symbol:TUserSymbol;
       Used:boolean;
       constructor Create;
       destructor Destroy; override;
     end;

     TAssemblerExportItem=class;

     TUserSymbolType=byte;

     TUserSymbol=class
      public
       SymbolType:TUserSymbolType;
       Name:ansistring;
       OriginalName:ansistring;
       Content:ansistring;
       MultiLine:longbool;
       VA_ARGS:longbool;
       CountParameters:longint;
       CountLocals:longint;
       Expression:TAssemblerExpression;
       Segment:PAssemblerSegment;
       Section:PAssemblerSection;
       Position:longint;
       Value:TAssemblerValue;
       HasPosition:boolean;
       ImportItem:TAssemblerImportItem;
       ExportItem:TAssemblerExportItem;
       Used:boolean;
       NeedSymbol:boolean;
       Defined:boolean;
       IsExternal:boolean;
       IsPublic:boolean;
{$ifdef SASMBESEN}
       BESENObject:TBESENObject;
{$endif}
       SymbolIndex:longint;
       ObjectSymbolIndex:longint;
       constructor Create(AName,AOriginalName:ansistring);
       destructor Destroy; override;
       procedure Calculate(ASMx86:TAssembler;AExpression:TAssemblerExpression);
       function GetValue(ASMx86:TAssembler):TAssemblerValue;
       procedure UseIt(ASMx86:TAssembler);
     end;

     TUserSymbolList=class(TList)
      private
       function GetItem(const Index:longint):TUserSymbol;
       procedure SetItem(const Index:longint;Value:TUserSymbol);
      public
       constructor Create;
       destructor Destroy; override;
       procedure Clear; override;
       function NewClass(out Index:longint;const Name,OriginalName:ansistring):TUserSymbol;
       property Item[const Index:longint]:TUserSymbol read GetItem write SetItem; default;
       property Items[const Index:longint]:TUserSymbol read GetItem write SetItem;
     end;

     TSymbolTreeLink=longint;
     TSymbolTreeLinkType=(stNONE,stPREFIX,stOPCODE,stREGISTER,stKEYWORD,stUSER,stUNIT,stFILE);

     PSymbolTreeNode=^TSymbolTreeNode;
     TSymbolTreeNode=record
      TheChar:ansichar;
      Link:TSymbolTreeLink;
      LinkType:TSymbolTreeLinkType;
      LinkExist:boolean;
      Prevoius,Next,Up,Down:PSymbolTreeNode;
     end;

{$ifdef HASHING}
     TSymbolHashes=array[0..MaxSymbolHashes-1] of longword;
     TSymbolHashNodes=array[0..MaxSymbolHashes-1] of PSymbolTreeNode;
{$endif}

     TSymbolTree=class
      private
       Root:PSymbolTreeNode;
{$ifdef HASHING}
       Hashes:TSymbolHashes;
       HashNodes:TSymbolHashNodes;
{$endif}
      public
       constructor Create;
       destructor Destroy; override;
       procedure Dump;
       function Add(Content:ansistring;LinkType:TSymbolTreeLinkType;Link:TSymbolTreeLink;Replace:boolean=false):boolean;
       function Delete(Content:ansistring):boolean;
       function Find(Content:ansistring;var LinkType:TSymbolTreeLinkType;var Link:TSymbolTreeLink):boolean;
     end;

     PData=^TData;
     TData=packed array[0..1024*1024*1024] of byte;

     PDataBuffer=^TDataBuffer;
     TDataBuffer=packed array[1..8192] of byte;

     TExportTree=class
      private
       Root:PExportTreeNode;
      public
       constructor Create;
       destructor Destroy; override;
       procedure Dump;
       function Add(FunctionName:ansistring;Link:TExportTreeLink):boolean;
       function Delete(FunctionName:ansistring):boolean;
       function Find(FunctionName:ansistring;var Link:TExportTreeLink):boolean;
     end;

     TDLLLoader=class
      private
       ImageBase:pointer;
       ImageBaseDelta:longint;
       DLLProc:TDLLEntryProc;
       ExternalLibraryArray:TExternalLibrarys;
       ImportArray:TImports;
       ExportArray:TExports;
       Sections:TSections;
       ExportTree:TExportTree;
       function FindExternalLibrary(const LibraryName:ansistring):longint;
       function LoadExternalLibrary(const LibraryName:ansistring):longint;
       function GetExternalLibraryHandle(const LibraryName:ansistring):HINST;
      public
       constructor Create;
       destructor Destroy; override;
       function Load(const Stream:TStream):boolean;
       function LoadFile(const FileName:ansistring):boolean;
       function Unload:boolean;
       function FindExport(const FunctionName:ansistring):TExportTreeLink;
       function FindExportPerIndex(const FunctionIndex:longint):pointer;
       function GetExportList:TStringList;
     end;

     TAssemblerImportLibraryList=class(TList)
      private
       function GetItem(const Index:longint):TAssemblerImportLibraryItem;
       procedure SetItem(const Index:longint;Value:TAssemblerImportLibraryItem);
      public
       constructor Create;
       destructor Destroy; override;
       procedure Clear; override;
       function NewClass:TAssemblerImportLibraryItem;
       property Item[const Index:longint]:TAssemblerImportLibraryItem read GetItem write SetItem; default;
       property Items[const Index:longint]:TAssemblerImportLibraryItem read GetItem write SetItem;
     end;

     TAssemblerImportList=class(TList)
      private
       function GetItem(const Index:longint):TAssemblerImportItem;
       procedure SetItem(const Index:longint;Value:TAssemblerImportItem);
      public
       constructor Create;
       destructor Destroy; override;
       procedure Clear; override;
       function NewClass:TAssemblerImportItem;
       property Item[const Index:longint]:TAssemblerImportItem read GetItem write SetItem; default;
       property Items[const Index:longint]:TAssemblerImportItem read GetItem write SetItem;
     end;

     TAssemblerExportItem=class
      public
       Name:ansistring;
       Symbol:TUserSymbol;
       Used:boolean;
       constructor Create;
       destructor Destroy; override;
     end;

     TAssemblerExportList=class(TList)
      private
       function GetItem(const Index:longint):TAssemblerExportItem;
       procedure SetItem(const Index:longint;Value:TAssemblerExportItem);
      public
       constructor Create;
       destructor Destroy; override;
       procedure Clear; override;
       function NewClass:TAssemblerExportItem;
       property Item[const Index:longint]:TAssemblerExportItem read GetItem write SetItem; default;
       property Items[const Index:longint]:TAssemblerExportItem read GetItem write SetItem;
     end;

     TAssemblerStatus=procedure(S:ansistring);

     TFixUpPass=(FUP_NONE,
                 FUP_RUNTIME,
                 FUP_BIN,
                 FUP_COM,
                 FUP_MZEXE,
                 FUP_PEEXE,
                 FUP_COFF,
                 FUP_ELF,
                 FUP_OMF,
                 FUP_TRI);

     TAssembler=class
      private
       CurrentFileName:ansistring;
       CurrentLineNumber:longint;
       CurrentColumn:longint;
       CurrentSource:longint;
       CurrentLocal:longint;
       LastCurrentLineNumber:longint;
       LastCurrentColumn:longint;
       FileSymbolTree:TSymbolTree;
       FileStringList:TStringList;
       UserSymbolList:TUserSymbolList;
       ImportList:TAssemblerImportList;
       ImportLibraryList:TAssemblerImportLibraryList;
       ExportList:TAssemblerExportList;
       CurrentLibrary:ansistring;
       IsStartOffsetSet:boolean;
       RuntimeCodeImage:pointer;
       RuntimeCodeImageSize:longint;
       RuntimeCodeImageEntryPoint:pointer;
       CountOutputSymbols:longint;
       OriginalNamePrefix:ansistring;
{$ifdef SASMBESEN}
       procedure ClearScript;
       procedure BESENObjectFileUtilsNativeReadFile(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
       procedure BESENObjectFileUtilsNativeWriteFile(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
       procedure BESENObjectFileUtilsNativeReadDirectory(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
       procedure BESENObjectFileUtilsNativeLoadScript(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
       procedure BESENObjectGarbageCollectorNativeRun(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
       procedure BESENObjectAssemblerNativeDefineFunction(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
       procedure BESENObjectAssemblerNativeDefineMacro(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
       procedure BESENObjectAssemblerNativeParse(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
       procedure BESENObjectAssemblerNativeError(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
       procedure BESENObjectAssemblerNativeWarning(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
       procedure BESENObjectAssemblerNativeGetCurrentBits(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
       procedure BESENObjectAssemblerNativeGetCurrentTarget(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
       procedure BESENObjectAssemblerNativeGetBasePosition(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
       procedure BESENObjectAssemblerNativeGetHerePosition(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
       procedure BESENObjectAssemblerNativeIsLastPass(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
       procedure BESENObjectAssemblerNativeRead8(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
       procedure BESENObjectAssemblerNativeRead16(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
       procedure BESENObjectAssemblerNativeRead32(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
       procedure BESENObjectAssemblerNativeWrite8(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
       procedure BESENObjectAssemblerNativeWrite16(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
       procedure BESENObjectAssemblerNativeWrite32(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
{$endif}
       procedure ResetOptions;
       procedure FreeCode(StartCode:PCode);
       function NewFixUpExpression:PFixUpExpression;
       function NewCode:PCode;
       function NewCodeEx:PCode;
       procedure AddCode(Code:PCode);
       procedure DeleteCode(CodeToDelete:PCode;NextCodeEx:PPCode=nil);
       function NewSegment:PAssemblerSegment;
       function GetSegmentPerName(Name:ansistring):PAssemblerSegment;
       procedure ResetSegments;
       function CountSegments:longint;
       function GetSegment(Number:longint):PAssemblerSegment;
       function GetSegmentNumber(ASegment:PAssemblerSegment):longint;
       function NewSection:PAssemblerSection;
       function GetSectionPerName(Name:ansistring):PAssemblerSection;
       procedure ResetSections;
       function CountSections:longint;
       function GetSection(Number:longint):PAssemblerSection;
       function GetSectionNumber(ASection:PAssemblerSection):longint;
       procedure WriteCountDummyBytes(c:longint);
       procedure WriteByte(Value:int64);
       procedure WriteByteCount(const Value:byte;const Count:longint);
       procedure WriteWord(Value:int64);
       procedure WriteDWord(Value:int64);
       procedure WriteInt64(Value:int64);
       procedure WriteQWord(Value:uint64);
       procedure AddFixUpExpression(const Expression:TAssemblerExpression;const Flags,Bits:longword;const Relative:boolean;const Signed,LineNumber,Column,Source,ManualBoundMode:longint;const MinBound,MaxBound:uint64;const BoundWarningOrError:ansistring;const HereOffset:longint);
       procedure WritePadding(Value:int64);
       procedure AddASP(var Instruction:TInstruction;AddressBits:longint);
       function REXFlags(const Value:longint;const Flags:TOperandFlags;const Mask:longint):longint;
       function OpREXFlags(const Operand:TOperand;const Mask:longint):longint;
       function EVEXFlags(const Value:longint;const DecoratorFlags:TDecoratorFlags;const Mask:longint;const b:byte):longint;
       function OpEVEXFlags(const Operand:TOperand;const Mask:longint;const b:byte):longint;
       function RegVal(const Operand:TOperand):longint;
       function RegFlags(const Operand:TOperand):TOperandFlags;
       function ProcessEA(var InputOperand:TOperand;var EAOutput:TEA;const Bits,RField:longint;const RFlags:TOperandFlags;var Instruction:TInstruction):longint;
       function CalculateInstructionSize(const Segment:PAssemblerSegment;const Section:PAssemblerSection;const Offset:int64;const Bits:longint;var Instruction:TInstruction;const InstructionTemplate:TInstructionTemplate):longint;
       procedure GenerateInstruction(const Segment:PAssemblerSegment;const Section:PAssemblerSection;const Offset:int64;const Bits:longint;var Instruction:TInstruction;const InstructionTemplate:TInstructionTemplate;HereOffset:longint);
       function InstructionMatches(const InstructionTemplate:PInstructionTemplate;const Instruction:TInstruction;const Bits:longint):longint;
       function JumpInstructionMatch(const Segment:PAssemblerSegment;const Section:PAssemblerSection;const Offset:int64;const Bits:longint;var Instruction:TInstruction;const InstructionTemplate:TInstructionTemplate):boolean;
       function FindInstructionMatch(var InstructionTemplate:PInstructionTemplate;var Instruction:TInstruction;const Segment:PAssemblerSegment;const Section:PAssemblerSection;const Offset:int64;const Bits:longint):longint;
       procedure CheckInstruction(var Instruction:TInstruction);
       procedure ProcessInstruction(Code:PCode);
       procedure ProcessLabel(SymbolIndex:longint);
       procedure ProcessConstant(Code:PCode);
       procedure ProcessOFFSET(Code:PCode);
       procedure ProcessSTARTOFFSET(Code:PCode);
       procedure ProcessALIGN(Code:PCode);
       procedure ProcessCPU(Code:PCode);
       procedure ProcessBits(Code:PCode);
       procedure ProcessTimes(Code:PCode);
       procedure ProcessData(Code:PCode);
       procedure ProcessDataRawString(Code:PCode);
       procedure ProcessDataEmpty(Code:PCode);
       procedure ProcessENTRYPOINT;
       procedure ProcessUSERENTRYPOINT;
       procedure ProcessLIBRARY(Code:PCode);
       procedure ProcessIMPORT(Code:PCode);
       procedure ProcessEXPORT(Code:PCode);
       procedure ProcessEND(Code:PCode);
       procedure ProcessSMARTLINK(Code:PCode);
       procedure ProcessBYTEDIFF(Code:PCode);
       procedure ProcessSTRUCTRESET(Code:PCode);
       procedure ProcessSTRUCTVAR(Code:PCode);
       procedure ProcessSEGMENT(Code:PCode);
       procedure ProcessSECTION(Code:PCode);
       procedure ProcessDIRECTORYENTRY(Code:PCode);
       procedure ProcessSTACK(Code:PCode);
       procedure ProcessHEAP(Code:PCode);
       procedure ProcessCODEBASE(Code:PCode);
       procedure ProcessIMAGEBASE(Code:PCode);
       procedure ProcessWARNING(Code:PCode);
       procedure ProcessERROR(Code:PCode);
{$ifdef SASMBESEN}
       procedure ProcessSCRIPT(Code:PCode);
{$endif}
       procedure ProcessSUBSYSTEM(Code:PCode);
       procedure ProcessCHARACTERISTICS(Code:PCode);
       procedure ProcessDLLCHARACTERISTICS(Code:PCode);
       procedure ProcessSIZEOFSTACKRESERVE(Code:PCode);
       procedure ProcessSIZEOFSTACKCOMMIT(Code:PCode);
       procedure ProcessSIZEOFHEAPRESERVE(Code:PCode);
       procedure ProcessSIZEOFHEAPCOMMIT(Code:PCode);
       procedure ProcessELFTYPE(Code:PCode);
       function IntSet(const v:int64):TIntegerValue; overload;
       function IntSetUnsigned(const v:uint64):TIntegerValue; overload;
       function IntAdd(const a,b:TIntegerValue):TIntegerValue; overload;
       function IntAdd(const a:TIntegerValue;const b:TAssemblerValue):TIntegerValue; overload;
       function IntAdd(const a:TIntegerValue;const b:int64):TIntegerValue; overload;
       function IntSub(const a,b:TIntegerValue):TIntegerValue; overload;
       function IntSub(const a:TIntegerValue;const b:TAssemblerValue):TIntegerValue; overload;
       function IntSub(const a:TIntegerValue;const b:int64):TIntegerValue; overload;
       function IntMul(const a,b:TIntegerValue):TIntegerValue; overload;
       function IntMul(const a:TIntegerValue;const b:TAssemblerValue):TIntegerValue; overload;
       function IntMul(const a:TIntegerValue;const b:int64):TIntegerValue; overload;
       function IntCompare(const a:TIntegerValue;const b:int64):longint; overload;
       procedure PostProcessFixUpExpressions;
       procedure PostProcessSymbols;
       procedure GeneratePass(StartCode:PCode);
       procedure GenerateCode(Code:PCode); register;
       function PrepareCode(StartCode:PCode):longint; register;
       function OptimizeCode(BeginBlock,EndBlock:PCode):boolean; register;
       procedure NewImport(SymbolIndex:longint;TheLibrary,TheName:ansistring);
       procedure NewExport(SymbolIndex:longint;TheName:ansistring);
       procedure InsertImportByHashSymbols;
       procedure ShowStatus(S:ansistring);
      public
       OpcodeSymbolTree:TSymbolTree;
       KeywordSymbolTree:TSymbolTree;
       UserSymbolTree:TSymbolTree;
       StartOffset:TSASMPtrInt;
       ImportHashTablePosition:longint;
       CPULevel:longint;
       CurrentBits:longword;
       StartFixUpExpression:PFixUpExpression;
       StartCode:PCode;
       StartSegment:PAssemblerSegment;
       StartSection:PAssemblerSection;
       LastFixUpExpression:PFixUpExpression;
       LastCode:PCode;
       LastSegment:PAssemblerSegment;
       LastSection:PAssemblerSection;
       CodeImage:TMemoryStream;
       UnitName:ansistring;
       CodeImageWriting:boolean;
       CodePosition:longint;
       CurrentSegment:PAssemblerSegment;
       CurrentSection:PAssemblerSection;
       TotalSize:longint;
       Errors:ansistring;
       AreErrors:boolean;
       Warnings:ansistring;
       AreWarnings:boolean;
       EntryPointSection:PAssemblerSection;
       EntryPoint:int64;
       UserEntryPoint:longint;
       StackSize:int64;
       HeapSize:int64;
       ImageBase:uint64;
       CodeBase:uint64;
       SubSystem:uint64;
       Characteristics:uint64;
       DLLCharacteristics:uint64;
       SizeOfStackReserve:uint64;
       SizeOfStackCommit:uint64;
       SizeOfHeapReserve:uint64;
       SizeOfHeapCommit:uint64;
       ELFType:uint64;
       CodeEnd:longint;
       FixUpPass:TFixUpPass;
       FixUpPassFlags:longword;
       FixUpPassBase:uint64;
       FixUpPassHere:uint64;
       EvaluateHereOffset:uint64;
       Target:TTarget;
       PECOFFDirectoryEntries:TPECOFFDirectoryEntries;
       WithCompleteDOSStub,CompleteMZEXEHeader,CalcCheckSum,TRIDoRelative:boolean;
       ImportType:byte;
       ImportByHashCodeInserted:boolean;
       IBHSafe:boolean;
       OptimizationLevel:longint;
       ForcePasses:longint;
       CurrentPass:longint;
       CurrentPasses:longint;
       RepeatCounter:int64;
       GlobalDefaults:TGlobalDefaults;
       Status:TAssemblerStatus;
{$ifdef SASMBESEN}
       BESENInstance:TBESEN;
       BESENObjectFunctions:TBESENObject;
       BESENObjectMacros:TBESENObject;
       BESENObjectFileUtils:TBESENObject;
       BESENObjectGarbageCollector:TBESENObject;
       BESENObjectAssembler:TBESENObject;
{$endif}
       constructor Create;
       destructor Destroy; override;
       procedure Clear;
       procedure MakeError(Error:longint;Overhead:int64=0); overload;
       procedure MakeError(const Error:ansistring); overload;
       procedure MakeWarning(Warning:longint;Overhead:int64=0); overload;
       procedure MakeWarning(const Warning:ansistring); overload;
{$ifdef DEBUGGER}
       procedure ResetDebuggerData;
{$endif}
       function Generate:boolean;
{$ifdef DEBUGGER}
       function FindCodeAtAddress(Address:longint):PCode;
       function FindCodeAtLine(Source,Line:longint):PCode;
       function FindCodeAtLineEx(Source,Line:longint):PCode;
       function FindCodeAtLineColumnEx(Source,Line,Column:longint;var Operand:POperand):PCode;
       procedure AdjustCodeLines(Source,Line,Count:longint);
{$endif}
       function WriteBIN(const Stream:TStream):boolean;
       function WriteCOM(const Stream:TStream):boolean;
       function WriteMZEXE(const Stream:TStream):boolean;
       function WritePEEXE(const Stream:TStream;const Is64Bit:boolean):boolean;
       function WriteCOFF(const Stream:TStream;const Is64Bit,IsDOS:boolean):boolean;
       function WriteELF(const Stream:TStream;const Is64Bit,IsX32:boolean):boolean;
       function WriteOMF(const Stream:TStream;const Is32Bit:boolean):boolean;
       function WriteTRI(const Stream:TStream):boolean;
       function Write(const Stream:TStream):boolean;
       function WriteFile(FileName:ansistring):boolean;
       procedure ParseString(Source:ansistring);
       procedure ParseDefines(Source:ansistring);
       procedure ParseStream(const Stream:TStream);
       procedure ParseFile(FileName:ansistring);
       procedure AddExternal(Name:ansistring;ExternalPointer:pointer);
       function GetCodePointer:pointer;
       function GetEntryPointPointer:pointer;
       function GetLabelPointer(LabelName:ansistring):pointer;
{$ifdef DEBUGGER}
      published
       property DebuggerFileStringList:TStringList read FileStringList;
       property DebuggerFileSymbolTree:TSymbolTree read FileSymbolTree;
       property DebuggerUserSymbolList:TUserSymbolList read UserSymbolList;
       property DebuggerImportList:TAssemblerImportList read ImportList;
       property DebuggerImportLibraryList:TAssemblerImportLibraryList read ImportLibraryList;
       property DebuggerExportList:TAssemblerExportList read ExportList;
{$endif}
     end;

const ObjectTargets:TTargets=[ttCOFFDOS,ttCOFF32,ttCOFF64,ttTRI32,ttTRI64];

      // exponent bits = round(4*log2(k)) - 13 
      IEEEFormat8:TIEEEFormat=(Bytes:1;Mantissa:3;Explicit:0;Exponent:4);
      IEEEFormat16:TIEEEFormat=(Bytes:2;Mantissa:10;Explicit:0;Exponent:5);
      IEEEFormat32:TIEEEFormat=(Bytes:4;Mantissa:23;Explicit:0;Exponent:8);
      IEEEFormat64:TIEEEFormat=(Bytes:8;Mantissa:52;Explicit:0;Exponent:11);
      IEEEFormat80:TIEEEFormat=(Bytes:10;Mantissa:63;Explicit:1;Exponent:15);
      IEEEFormat128:TIEEEFormat=(Bytes:16;Mantissa:112;Explicit:0;Exponent:15);
      IEEEFormat256:TIEEEFormat=(Bytes:32;Mantissa:236;Explicit:0;Exponent:19);
      IEEEFormat512:TIEEEFormat=(Bytes:64;Mantissa:488;Explicit:0;Exponent:23);

      FLOAT_ROUND_TO_NEAREST=0;
      FLOAT_ROUND_TOWARD_ZERO=1;
      FLOAT_ROUND_DOWNWARD=2;
      FLOAT_ROUND_UPWARD=3;

function GregorianToJulian(Year,Month,Day:longword):longword;
procedure JulianToGregorian(Julian:longword;var Year,Month,Day:longword);
procedure DecodeUnixTime(UnixTimeStamp:longword;var Year,Month,Day,Hour,Minute,Second:longword);
function EncodeUnixTime(Year,Month,Day,Hour,Minute,Second:longword):longword;
function DayOfWeekEx(Year,Month,Day:longword):longword;
function DayOfWeek(UnixTimeStamp:longword):longword;
function LeapYearEx(Year:longword):longbool;
function LeapYear(UnixTimeStamp:longword):longbool;
function DayLightSavings(UnixTimeStamp:longword):longbool;
function DayLightSavingsEx(Year,Month,Day,Hour,Minute,Second:longword):longbool;
function Jan_1_1970:TDateTime;
function UnixTimeToDateTime(UnixTime:int64):TDateTime;
function DateTimeToUnixTime(DT:TDateTime):int64;
function NowUnixTime:longword;
function ReadFileAsString(SourceFile:ansistring):ansistring;
function StringSearch(const Where,What:ansistring;const FromHere:longint;const OnlyCompleteWords,CaseInsensitive:boolean):longint;
function StringReplace(const Where,SearchFor,ReplaceWith:ansistring;const OnlyCompleteWords,CaseInsensitive:boolean):ansistring;
function HashString(const Str:ansistring):longword;
function GetAbsolutePath(BasePath,RelativePath:ansistring):ansistring;
function GetAbsoluteFile(BasePath,FileName:ansistring):ansistring;
function GetAbsoluteFileEx(BaseFile,FileName:ansistring):ansistring;

function StringToFloat(const FloatString:ansistring;var FloatValue;const IEEEFormat:TIEEEFormat;const RoundMode:longint=FLOAT_ROUND_TO_NEAREST;const DenormalsAreZero:boolean=false):boolean;
function FloatToRawString(const Src;const IEEEFormat:TIEEEFormat):ansistring;

implementation

const CELL_EMPTY=-1;
      CELL_DELETED=-2;

      ENT_EMPTY=-1;
      ENT_DELETED=-2;

{$ifdef SASMBESEN}
constructor TFileObject.Create(AInstance:TObject;APrototype:TBESENObject=nil;AHasPrototypeProperty:longbool=false);
begin
 inherited Create(AInstance,APrototype,AHasPrototypeProperty);
 fFileStream:=nil;
end;

destructor TFileObject.Destroy;
begin
 BesenFreeAndNil(fFileStream);
 inherited Destroy;
end;

procedure TFileObject.ConstructObject(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint);
var s:string;
    Mode:longword;
begin
 inherited ConstructObject(ThisArgument,Arguments,CountArguments);
 if CountArguments=0 then begin
  raise EBESENError.Create('FileError','Too few arguments');
 end else begin
  fFileName:=TBESEN(Instance).ToStr(Arguments^[0]^);
  if FileExists(fFileName) then begin
   Mode:=fmOpenReadWrite or fmShareExclusive;
  end else begin
   Mode:=fmCreate or fmShareDenyRead;
  end;
  if CountArguments>1 then begin
   s:=string(TBESEN(Instance).ToStr(Arguments^[1]^));
   if s='c' then begin
    Mode:=fmCreate or fmShareDenyRead;
   end else if s='r' then begin
    Mode:=fmOpenRead or fmShareDenyWrite;
   end else if s='rw' then begin
    Mode:=fmOpenReadWrite or fmShareExclusive;
   end else if s='w' then begin
    if FileExists(fFileName) then begin
     Mode:=fmOpenWrite or fmShareDenyRead;
    end else begin
     Mode:=fmCreate or fmShareDenyRead;
    end;
   end;
  end;
{$ifdef BESENSingleStringType}
  fFileStream:=TFileStream.Create(fFileName,Mode);
{$else}
  fFileStream:=TFileStream.Create(String(BESENEncodeString(BESENUTF16ToUTF8(fFileName),UTF_8,BESENLocaleCharset)),Mode);
{$endif}
 end;
 s:='';
end;

procedure TFileObject.InitializeObject;
begin
 inherited InitializeObject;
 fFileName:='';
 fFileStream:=nil;
end;

procedure TFileObject.FinalizeObject;
begin
 BesenFreeAndNil(fFileStream);
 inherited FinalizeObject;
end;

procedure TFileObject.close(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
begin
 ResultValue.ValueType:=bvtUNDEFINED;
 BesenFreeAndNil(fFileStream);
end;

procedure TFileObject.read(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
var l,ms:int64;
    s:string;
begin
 s:='';
 ResultValue.ValueType:=bvtUNDEFINED;
 if assigned(fFileStream) then begin
  ms:=fFileStream.Size-fFileStream.Position;
  if CountArguments=0 then begin
   l:=ms;
  end else begin
   if Arguments^[0]^.ValueType=bvtUNDEFINED then begin
    l:=ms;
   end else begin
    l:=TBESEN(Instance).ToInt(Arguments^[0]^);
    if l>ms then begin
     l:=ms;
    end;
   end;
  end;
  SetLength(s,l);
  if l>0 then begin
   fFileStream.Read(s[1],l);
  end;
  ResultValue.ValueType:=bvtSTRING;
  ResultValue.Str:=TBESENString(s);
  SetLength(s,0);
 end;
end;

procedure TFileObject.write(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
var l:int64;
    s:ansistring;
begin
 s:='';
 ResultValue.ValueType:=bvtUNDEFINED;
 if assigned(fFileStream) then begin
  if CountArguments>0 then begin
   ResultValue.ValueType:=bvtNUMBER;
   ResultValue.Num:=0;
   s:=ansistring(TBESEN(Instance).ToStr(Arguments^[0]^));
   l:=length(s);
   if l>0 then begin
    ResultValue.Num:=fFileStream.Write(s[1],l);
   end;
   SetLength(s,0);
  end;
 end;
end;

procedure TFileObject.seek(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
var l,ms:int64;
begin
 ResultValue.ValueType:=bvtUNDEFINED;
 if assigned(fFileStream) then begin
  ms:=fFileStream.Size;
  if CountArguments=0 then begin
   l:=fFileStream.Position;
  end else begin
   if Arguments^[0]^.ValueType=bvtUNDEFINED then begin
    l:=fFileStream.Position;
   end else begin
    l:=TBESEN(Instance).ToInt(Arguments^[0]^);
    if l>ms then begin
     l:=ms;
    end;
   end;
  end;
  ResultValue.ValueType:=bvtNUMBER;
  ResultValue.Num:=fFileStream.Seek(l,soFromBeginning);
 end;
end;

procedure TFileObject.position(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
begin
 ResultValue.ValueType:=bvtUNDEFINED;
 if assigned(fFileStream) then begin
  ResultValue.ValueType:=bvtNUMBER;
  ResultValue.Num:=fFileStream.Position;
 end;
end;

procedure TFileObject.eof(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
begin
 ResultValue.ValueType:=bvtUNDEFINED;
 if assigned(fFileStream) then begin
  ResultValue.ValueType:=bvtBOOLEAN;
  ResultValue.Bool:=fFileStream.Position<fFileStream.Size;
 end;
end;

procedure TFileObject.flush(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
begin
 ResultValue.ValueType:=bvtUNDEFINED;
 if assigned(fFileStream) then begin
{$ifdef win32}
  Windows.FlushFileBuffers(fFileStream.Handle);
{$endif}
 end;
end;
{$endif}

function Stringify(const s:ansistring):ansistring;
const hexchars:array[0..$f] of ansichar='0123456789ABCDEF';
var i:longint;
    c:TPUCUUTF32Char;
begin
 result:='';
 i:=1;
 while i<=length(s) do begin
  c:=PUCUUTF8CodeUnitGetCharAndIncFallback(s,i);
  case c of
   0:begin
    result:=result+'\0';
   end;
   7:begin
    result:=result+'\a';
   end;
   8:begin
    result:=result+'\b';
   end;
   9:begin
    result:=result+'\t';
   end;
   10:begin
    result:=result+'\n';
   end;
   11:begin
    result:=result+'\v';
   end;
   12:begin
    result:=result+'\f';
   end;
   13:begin
    result:=result+'\r';
   end;
   ord('\'):begin
    result:=result+'\\';
   end;
   ord(''''):begin
    result:=result+'\''';
   end;
   ord('"'):begin
    result:=result+'\"';
   end;
   ord('?'):begin
    result:=result+'\?';
   end;
   else begin
    if c<128 then begin
     result:=result+PUCUUTF32CharToUTF8(c);
    end else if c<=$ffff then begin
     result:=result+'\u'+hexchars[(c shr 12) and $f]+hexchars[(c shr 8) and $f]+hexchars[(c shr 4) and $f]+hexchars[c and $f];
    end else begin
     result:=result+'\U'+hexchars[(c shr 28) and $f]+hexchars[(c shr 24) and $f]+hexchars[(c shr 20) and $f]+hexchars[(c shr 16) and $f]+hexchars[(c shr 12) and $f]+hexchars[(c shr 8) and $f]+hexchars[(c shr 4) and $f]+hexchars[c and $f];
    end;
   end;
  end;
 end;
end;

type TChars=set of ansichar;

function ParseStringContent(const s:ansistring;const c:TChars;var Position:longint;const DoContinue:boolean):ansistring;
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

function GetStringFromStringList(const StringList:TStringList):ansistring;
var LineIndex:longint;
begin
 result:='';
 for LineIndex:=0 to StringList.Count-1 do begin
  if LineIndex>0 then begin
   result:=result+#10;
  end;
  result:=result+StringList[LineIndex];
 end;
end;

function FloatValueIsZero(const Source:TFloatValue):boolean;
var Index:longint;
begin
 result:=true;
 for Index:=0 to Source.Count-1 do begin
  if Source.Bytes[Index]<>0 then begin
   result:=false;
   exit;
  end;
 end;
end;

procedure IntegerValueSetInt64(out Dest:TIntegerValue;const Value:int64);
var LimbIndex:longint;
    SignValue:longword;
begin
 Dest[0]:=uint64(Value) and $ffffffff;
 Dest[1]:=uint64(Value) shr 32;
 SignValue:=-(uint64(Value) shr 63);
 for LimbIndex:=2 to IntegerValueDWords-1 do begin
  Dest[LimbIndex]:=SignValue;
 end;
end;

procedure IntegerValueSetQWord(out Dest:TIntegerValue;const Value:uint64);
var LimbIndex:longint;
begin
 Dest[0]:=uint64(Value) and $ffffffff;
 Dest[1]:=uint64(Value) shr 32;
 for LimbIndex:=2 to IntegerValueDWords-1 do begin
  Dest[LimbIndex]:=0;
 end;
end;

function IntegerValueGetInt64(const Source:TIntegerValue):int64;
begin
 result:=Source[0] or (int64(Source[1]) shl 32);
end;

function IntegerValueGetQWord(const Source:TIntegerValue):uint64;
begin
 result:=Source[0] or (uint64(Source[1]) shl 32);
end;

procedure IntegerValueAdd(out Dest:TIntegerValue;const a,b:TIntegerValue);
var LimbIndex:longint;
    Carry:longword;
    Value:uint64;
begin
 Carry:=0;
 for LimbIndex:=0 to IntegerValueDWords-1 do begin
  Value:=uint64(a[LimbIndex])+uint64(b[LimbIndex])+uint64(Carry);
  Carry:=Value shr 32;
  Dest[LimbIndex]:=Value and $ffffffff;
 end;
end;

procedure IntegerValueSub(out Dest:TIntegerValue;const a,b:TIntegerValue);
var LimbIndex:longint;
    Borrow:longword;
    Value:uint64;
begin
 Borrow:=0;
 for LimbIndex:=0 to IntegerValueDWords-1 do begin
  Value:=(uint64(a[LimbIndex])-uint64(b[LimbIndex]))-Borrow;
  Borrow:=Value shr 63;
  Dest[LimbIndex]:=Value and $ffffffff;
 end;
end;

function IntegerValueIsZero(const Source:TIntegerValue):boolean;
var LimbIndex:longint;
begin
 result:=true;
 for LimbIndex:=0 to IntegerValueDWords-1 do begin
  if Source[LimbIndex]<>0 then begin
   result:=false;
   exit;
  end;
 end;
end;

function IntegerValueIsOne(const Source:TIntegerValue):boolean;
var LimbIndex:longint;
begin
 result:=Source[0]=1;
 if result then begin
  for LimbIndex:=1 to IntegerValueDWords-1 do begin
   if Source[LimbIndex]<>0 then begin
    result:=false;
    exit;
   end;
  end;
 end;
end;

function IntegerValueIs32Bit(const Source:TIntegerValue):boolean;
var LimbIndex:longint;
begin
 result:=true;
 if (Source[IntegerValueDWords-1] and longword($80000000))<>0 then begin
  for LimbIndex:=1 to IntegerValueDWords-1 do begin
   if Source[LimbIndex]<>longword($ffffffff) then begin
    result:=false;
    exit;
   end;
  end;
 end else begin
  for LimbIndex:=1 to IntegerValueDWords-1 do begin
   if Source[LimbIndex]<>0 then begin
    result:=false;
    exit;
   end;
  end;
 end;
end;

function IntegerValueIsXBit(const Source:TIntegerValue;const Bits:longint):boolean;
var LimbIndex:longint;
begin
 if (Source[IntegerValueDWords-1] and longword($80000000))<>0 then begin
  if (Bits and 31)<>0 then begin
   result:=(Source[(Bits and not 32) shr 5] shr (Bits and 31))=(longword($ffffffff) shr (Bits and 31));
  end else begin
   result:=true;
  end;
  if result then begin
   for LimbIndex:=((Bits+31) and not 32) shr 5 to IntegerValueDWords-1 do begin
    if Source[LimbIndex]<>$ffffffff then begin
     result:=false;
     exit;
    end;
   end;
  end;
 end else begin
  if (Bits and 31)<>0 then begin
   result:=(Source[(Bits and not 32) shr 5] shr (Bits and 31))=0;
  end else begin
   result:=true;
  end;
  if result then begin
   for LimbIndex:=((Bits+31) and not 32) shr 5 to IntegerValueDWords-1 do begin
    if Source[LimbIndex]<>0 then begin
     result:=false;
     exit;
    end;
   end;
  end;
 end;
end;

function IntegerValueNegative(const Source:TIntegerValue):boolean;
begin
 result:=(Source[IntegerValueDWords-1] and longword($80000000))<>0;
end;

function IntegerValueEquals(const a,b:TIntegerValue):boolean;
var LimbIndex:longint;
begin
 result:=true;
 for LimbIndex:=0 to IntegerValueDWords-1 do begin
  if a[LimbIndex]<>b[LimbIndex] then begin
   result:=false;
   exit;
  end;
 end;
end;

function IntegerValueCompare(const a,b:TIntegerValue):longint;
var LimbIndex:longint;
    NegativeA,NegativeB:boolean;
begin
 NegativeA:=(a[IntegerValueDWords-1] and longword($80000000))<>0;
 NegativeB:=(b[IntegerValueDWords-1] and longword($80000000))<>0;
 if NegativeA=NegativeB then begin
  // Both positive or negative
  result:=0;
  for LimbIndex:=IntegerValueDWords-1 downto 0 do begin
   if a[LimbIndex]<>b[LimbIndex] then begin
    if a[LimbIndex]>b[LimbIndex] then begin
     result:=1;
    end else if a[LimbIndex]<b[LimbIndex] then begin
     result:=-1;
    end;
    exit;
   end;
  end;
 end else if NegativeA then begin
  // negative a < positive b
  result:=-1;
 end else{if NegativeB then}begin
  // positive a > negative b
  result:=1;
 end;
end;

function IntegerValueUnsignedCompare(const a,b:TIntegerValue):longint;
var LimbIndex:longint;
begin
 result:=0;
 for LimbIndex:=IntegerValueDWords-1 downto 0 do begin
  if a[LimbIndex]<>b[LimbIndex] then begin
   if a[LimbIndex]>b[LimbIndex] then begin
    result:=1;
   end else if a[LimbIndex]<b[LimbIndex] then begin
    result:=-1;
   end;
   exit;
  end;
 end;
end;

procedure IntegerValueNEG(out Dest:TIntegerValue;const Source:TIntegerValue);
var Index:longint;
    Carry:longword;
    Value:uint64;
begin
 Carry:=1;
 for Index:=0 to IntegerValueDWords-1 do begin
  Value:=uint64(longword(not Source[Index]))+uint64(Carry);
  Carry:=Value shr 32;
  Dest[Index]:=Value and $ffffffff;
 end;
end;

procedure IntegerValueABS(out Dest:TIntegerValue;const Source:TIntegerValue);
var Index:longint;
    Carry:longword;
    Value:uint64;
begin
 if (Source[IntegerValueDWords-1] and longword($80000000))<>0 then begin
  Carry:=1;
  for Index:=0 to IntegerValueDWords-1 do begin
   Value:=uint64(longword(not Source[Index]))+uint64(Carry);
   Carry:=Value shr 32;
   Dest[Index]:=Value and $ffffffff;
  end;
 end else begin
  Dest:=Source;
 end;                      
end;

procedure IntegerValueNOT(out Dest:TIntegerValue;const Source:TIntegerValue);
var Index:longint;
begin
 for Index:=0 to IntegerValueDWords-1 do begin
  Dest[Index]:=not Source[Index];
 end;
end;

procedure IntegerValueXOR(out Dest:TIntegerValue;const a,b:TIntegerValue);
var Index:longint;
begin
 for Index:=0 to IntegerValueDWords-1 do begin
  Dest[Index]:=a[Index] xor b[Index];
 end;
end;

procedure IntegerValueOR(out Dest:TIntegerValue;const a,b:TIntegerValue);
var Index:longint;
begin
 for Index:=0 to IntegerValueDWords-1 do begin
  Dest[Index]:=a[Index] or b[Index];
 end;
end;

procedure IntegerValueAND(out Dest:TIntegerValue;const a,b:TIntegerValue);
var Index:longint;
begin
 for Index:=0 to IntegerValueDWords-1 do begin
  Dest[Index]:=a[Index] and b[Index];
 end;
end;

procedure IntegerValueShiftLeftInternal(out Dest:TIntegerValue;const Source:TIntegerValue;const Shift:longint);
var Index,LowOffset,HighOffset,LowShift,HighShift,Offset:longint;
    Value:longword;
begin
 if (Shift and 31)<>0 then begin
  LowOffset:=(Shift-1) shr 5;
  HighOffset:=LowOffset+1;
  LowShift:=Shift-(LowOffset shl 5);
  HighShift:=32-LowShift;
  for Index:=0 to IntegerValueDWords-2 do begin
   Dest[Index]:=0;
  end;
  Dest[IntegerValueDWords-1]:=Source[IntegerValueDWords-HighOffset] shl LowShift;
  for Index:=(IntegerValueDWords-1)-HighOffset downto 0 do begin
   Value:=Source[Index];
   Dest[Index+LowOffset]:=Dest[Index+LowOffset] or (Value shl LowShift);
   Dest[Index+HighOffset]:=Dest[Index+HighOffset] or (Value shr HighShift);
  end;
 end else begin
  Offset:=Shift shr 5;
  for Index:=IntegerValueDWords-1 downto Offset do begin
   Dest[Index]:=Source[Index-Offset];
  end;
  for Index:=0 to Offset-1 do begin
   Dest[Index]:=0;
  end;
 end;
end;

procedure IntegerValueUnsignedShiftRightInternal(out Dest:TIntegerValue;const Source:TIntegerValue;const Shift:longint);
var Index,LowOffset,HighOffset,LowShift,HighShift,Offset:longint;
    Value:longword;
begin
 if (Shift and 31)<>0 then begin
  HighOffset:=(Shift-1) shr 5;
  LowOffset:=HighOffset+1;
  HighShift:=Shift-(HighOffset shl 5);
  LowShift:=32-HighShift;
  Dest[0]:=Source[HighOffset] shr HighShift;
  for Index:=1 to IntegerValueDWords-1 do begin
   Dest[Index]:=0;
  end;
  for Index:=LowOffset to IntegerValueDWords-1 do begin
   Value:=Source[Index];
   Dest[Index-HighOffset]:=Dest[Index-HighOffset] or (Value shr HighShift);
   Dest[Index-LowOffset]:=Dest[Index-LowOffset] or (Value shl LowShift);
  end;
 end else begin
  Offset:=Shift shr 5;
  for Index:=IntegerValueDWords-1 downto Offset do begin
   Dest[Index-Offset]:=Source[Index];
  end;
  for Index:=IntegerValueDWords-Offset to IntegerValueDWords-1 do begin
   Dest[Index]:=0;
  end;
 end;
end;

procedure IntegerValueShiftLeft(out Dest:TIntegerValue;const Source:TIntegerValue;const Shift:longint);
var Index,ShiftOffset,BitShift,InverseBitShift:longint;
    Current,Next:longword;
begin
 case Shift of
  1..IntegerValueBits-1:begin
   ShiftOffset:=Shift shr 5;
   BitShift:=Shift and 31;
   InverseBitShift:=(32-BitShift) and 31;
   if ShiftOffset=0 then begin
    if BitShift=0 then begin
     Dest:=Source;
    end else begin
     Next:=0;
     for Index:=0 to IntegerValueDWords-1 do begin
      Current:=Source[Index];
      Dest[Index]:=(Current shl BitShift) or Next;
      Next:=Current shr InverseBitShift;
     end;
    end;
   end else begin
    if BitShift=0 then begin
     for Index:=ShiftOffset to IntegerValueDWords-1 do begin
      Dest[Index]:=Source[Index-ShiftOffset];
     end;
    end else begin
     Next:=0;
     for Index:=ShiftOffset to IntegerValueDWords-1 do begin
      Current:=Source[Index-ShiftOffset];
      Dest[Index]:=(Current shl BitShift) or Next;
      Next:=Current shr InverseBitShift;
     end;
    end;
    for Index:=0 to ShiftOffset-1 do begin
     Dest[Index]:=0;
    end;
   end;
  end;
  IntegerValueBits..$7fffffff:begin
   for Index:=0 to IntegerValueDWords-1 do begin
    Dest[Index]:=0;
   end;
  end
  else begin
   Dest:=Source;
  end;
 end;
end;

procedure IntegerValueShiftRight(out Dest:TIntegerValue;const Source:TIntegerValue;const Shift:longint);
var Index,ShiftOffset,BitShift,InverseBitShift:longint;
    SignMask,Current,Next:longword;
begin
 case Shift of
  1..IntegerValueBits-1:begin
   ShiftOffset:=Shift shr 5;
   BitShift:=Shift and 31;
   InverseBitShift:=(32-BitShift) and 31;
   SignMask:=longword(-(Source[IntegerValueDWords-1] shr 31));
   if ShiftOffset=0 then begin
    if BitShift=0 then begin
     Dest:=Source;
    end else begin
     Next:=SignMask shl InverseBitShift;
     for Index:=IntegerValueDWords-1 downto 0 do begin
      Current:=Source[Index];
      Dest[Index]:=(Current shr BitShift) or Next;
      Next:=Current shl InverseBitShift;
     end;
    end;
   end else begin
    if BitShift=0 then begin
     for Index:=ShiftOffset to IntegerValueDWords-1 do begin
      Dest[Index-ShiftOffset]:=Source[Index];
     end;
    end else begin
     Next:=SignMask shl InverseBitShift;
     for Index:=IntegerValueDWords-1 downto ShiftOffset do begin
      Current:=Source[Index];
      Dest[Index-ShiftOffset]:=(Current shr BitShift) or Next;
      Next:=Current shl InverseBitShift;
     end;
    end;
    for Index:=IntegerValueDWords-ShiftOffset to IntegerValueDWords-1 do begin
     Dest[Index]:=SignMask;
    end;
   end;
  end;
  IntegerValueBits..$7fffffff:begin
   for Index:=0 to IntegerValueDWords-1 do begin
    Dest[Index]:=0;
   end;
  end
  else begin
   Dest:=Source;
  end;
 end;
end;

procedure IntegerValueUnsignedShiftRight(out Dest:TIntegerValue;const Source:TIntegerValue;const Shift:longint);
var Index,ShiftOffset,BitShift,InverseBitShift:longint;
    Current,Next:longword;
begin
 case Shift of
  1..IntegerValueBits-1:begin
   ShiftOffset:=Shift shr 5;
   BitShift:=Shift and 31;
   InverseBitShift:=(32-BitShift) and 31;
   if ShiftOffset=0 then begin
    if BitShift=0 then begin
     Dest:=Source;
    end else begin
     Next:=0;
     for Index:=IntegerValueDWords-1 downto 0 do begin
      Current:=Source[Index];
      Dest[Index]:=(Current shr BitShift) or Next;
      Next:=Current shl InverseBitShift;
     end;
    end;
   end else begin
    if BitShift=0 then begin
     for Index:=ShiftOffset to IntegerValueDWords-1 do begin
      Dest[Index-ShiftOffset]:=Source[Index];
     end;
    end else begin
     Next:=0;
     for Index:=IntegerValueDWords-1 downto ShiftOffset do begin
      Current:=Source[Index];
      Dest[Index-ShiftOffset]:=(Current shr BitShift) or Next;
      Next:=Current shl InverseBitShift;
     end;
    end;
    for Index:=IntegerValueDWords-ShiftOffset to IntegerValueDWords-1 do begin
     Dest[Index]:=0;
    end;
   end;
  end;
  IntegerValueBits..$7fffffff:begin
   for Index:=0 to IntegerValueDWords-1 do begin
    Dest[Index]:=0;
   end;
  end
  else begin
   Dest:=Source;
  end;
 end;
end;

procedure IntegerValueMulReference(out Dest:TIntegerValue;const a,b:TIntegerValue);
var i,j,k:longint;
    Value32,Carry:longword;
    Value64,Value:uint64;
    Temp:array[0..(IntegerValueDWords*2)-1] of longword;
    Negative,NegativeA,NegativeB:boolean;
    TempA,TempB:TIntegerValue;
    WorkA,WorkB:PIntegerValue;
begin
 NegativeA:=(a[IntegerValueDWords-1] and longword($80000000))<>0;
 NegativeB:=(b[IntegerValueDWords-1] and longword($80000000))<>0;
 if NegativeA then begin
  IntegerValueNeg(TempA,a);
  WorkA:=@TempA;
 end else begin
  WorkA:=@a;
 end;
 if NegativeB then begin
  IntegerValueNeg(TempB,b);
  WorkB:=@TempB;
 end else begin
  WorkB:=@b;
 end;
 Negative:=NegativeA<>NegativeB;
 for i:=0 to (IntegerValueDWords*2)-1 do begin
  Temp[i]:=0;
 end;
 for i:=0 to IntegerValueDWords-1 do begin
  Value32:=WorkA^[i];
  if Value32<>0 then begin
   Value64:=Value32;
   Carry:=0;
   for j:=0 to IntegerValueDWords-1 do begin
    k:=i+j;
    Value:=uint64(uint64(Value64*WorkB^[j])+Temp[k])+Carry;
    Temp[k]:=longword(Value and $ffffffff);
    Carry:=longword(Value shr 32);
   end;
   Temp[i+IntegerValueDWords]:=Carry;
  end;
 end;
 if Negative then begin
  for i:=0 to IntegerValueDWords-1 do begin
   TempA[i]:=Temp[i];
  end;
  IntegerValueNeg(Dest,TempA);
 end else begin
  for i:=0 to IntegerValueDWords-1 do begin
   Dest[i]:=Temp[i];
  end;
 end;
end;

procedure IntegerValueMul(out Dest:TIntegerValue;const a,b:TIntegerValue);
var LimbIndex,BitIndex,ShiftCount:longint;
    Value:longword;
    Negative,NegativeA,NegativeB:boolean;
    Temp,NewTemp,TempResult,TempB:TIntegerValue;
    Work:PIntegerValue;
begin
 NegativeA:=(a[IntegerValueDWords-1] and longword($80000000))<>0;
 NegativeB:=(b[IntegerValueDWords-1] and longword($80000000))<>0;
 if NegativeA then begin
  IntegerValueNeg(Temp,a);
 end else begin
  Temp:=a;
 end;
 if NegativeB then begin
  IntegerValueNeg(TempB,b);
  Work:=@TempB;
 end else begin
  Work:=@b;
 end;
 Negative:=NegativeA<>NegativeB;
 for LimbIndex:=0 to IntegerValueDWords-1 do begin
  TempResult[LimbIndex]:=0;
 end;
 ShiftCount:=0;
 for LimbIndex:=0 to IntegerValueDWords-1 do begin
  Value:=Work^[LimbIndex];
  if Value<>0 then begin
   for BitIndex:=0 to 31 do begin
    if (Value and (longword(1) shl BitIndex))<>0 then begin
     if ShiftCount<>0 then begin
      IntegerValueShiftLeftInternal(NewTemp,Temp,ShiftCount);
      Temp:=NewTemp;
      ShiftCount:=0;
     end;
     IntegerValueAdd(NewTemp,TempResult,Temp);
     TempResult:=NewTemp;
    end;
    inc(ShiftCount);
   end;
  end else begin
   inc(ShiftCount,32);
  end;
 end;
 if Negative then begin
  IntegerValueNeg(Dest,TempResult);
 end else begin
  Dest:=TempResult;
 end;
end;

procedure IntegerValueDiv(out Dest:TIntegerValue;const a,b:TIntegerValue;const Remainder:PIntegerValue=nil);
var Comparsion,LimbIndex:longint;
    Negative,NegativeA,NegativeB:boolean;
    Temp,Denominator,Dividend,Current,Quotient:TIntegerValue;
begin
 NegativeA:=(a[IntegerValueDWords-1] and longword($80000000))<>0;
 NegativeB:=(b[IntegerValueDWords-1] and longword($80000000))<>0;
 if NegativeA then begin
  IntegerValueNeg(Dividend,a);
 end else begin
  Dividend:=a;
 end;
 if NegativeB then begin
  IntegerValueNeg(Denominator,b);
 end else begin
  Denominator:=b;
 end;
 Negative:=NegativeA<>NegativeB;
 Comparsion:=IntegerValueUnsignedCompare(Denominator,Dividend);
 if Comparsion>0 then begin
  for LimbIndex:=0 to IntegerValueDWords-1 do begin
   Dest[LimbIndex]:=0;
  end;
  if assigned(Remainder) then begin
   Remainder^:=a;
  end;
  exit;
 end else if Comparsion=0 then begin
  if Negative then begin
   for LimbIndex:=0 to IntegerValueDWords-1 do begin
    Dest[LimbIndex]:=$ffffffff;
   end;
  end else begin
   Dest[0]:=1;
   for LimbIndex:=1 to IntegerValueDWords-1 do begin
    Dest[LimbIndex]:=0;
   end;
  end;
  if assigned(Remainder) then begin
   for LimbIndex:=0 to IntegerValueDWords-1 do begin
    Remainder^[LimbIndex]:=0;
   end;
  end;
 end else begin
  for LimbIndex:=0 to IntegerValueDWords-1 do begin
   Quotient[LimbIndex]:=0;
  end;
  Current[0]:=1;
  for LimbIndex:=1 to IntegerValueDWords-1 do begin
   Current[LimbIndex]:=0;
  end;
  while IntegerValueUnsignedCompare(Denominator,Dividend)<=0 do begin
   IntegerValueShiftLeftInternal(Temp,Denominator,1);
   Denominator:=Temp;
   IntegerValueShiftLeftInternal(Temp,Current,1);
   Current:=Temp;
  end;
  IntegerValueUnsignedShiftRightInternal(Temp,Denominator,1);
  Denominator:=Temp;
  IntegerValueUnsignedShiftRightInternal(Temp,Current,1);
  Current:=Temp;
  while not IntegerValueIsZero(Current) do begin
   if IntegerValueUnsignedCompare(Dividend,Denominator)>=0 then begin
    IntegerValueSub(Temp,Dividend,Denominator);
    Dividend:=Temp;
    for LimbIndex:=0 to IntegerValueDWords-1 do begin
     Quotient[LimbIndex]:=Quotient[LimbIndex] or Current[LimbIndex];
    end;
   end;
   IntegerValueUnsignedShiftRightInternal(Temp,Denominator,1);
   Denominator:=Temp;
   IntegerValueUnsignedShiftRightInternal(Temp,Current,1);
   Current:=Temp;
  end;
  if assigned(Remainder) then begin
   Remainder^:=Dividend;
  end;
  if Negative then begin
   IntegerValueNeg(Dest,Quotient);
  end else begin
   Dest:=Quotient;
  end;
 end;
end;

procedure IntegerValueModulo(out Dest:TIntegerValue;const a,b:TIntegerValue);
var c,d:TIntegerValue;
begin
 // a mod b = a-(floor(a/b)*b)
 IntegerValueDiv(c,a,b);
 IntegerValueMul(d,c,b);
 IntegerValueSub(Dest,a,d);
end;

procedure IntegerValueSQRT(out Dest:TIntegerValue;const Source:TIntegerValue;const Remainder:PIntegerValue=nil);
var Number,TempResult,Temp,Bit,NewTemp:TIntegerValue;
begin
 if (Source[IntegerValueDWords-1] and longword($80000000))<>0 then begin
  IntegerValueNeg(Number,Source);
 end else begin
  Number:=Source;
 end;
 IntegerValueSetQWord(TempResult,0);
 IntegerValueSetQWord(Temp,1);
 IntegerValueShiftLeftInternal(Bit,Temp,(SizeOf(TIntegerValue)*8)-2);
 while IntegerValueUnsignedCompare(Bit,Number)>0 do begin
  IntegerValueUnsignedShiftRightInternal(Temp,Bit,2);
  Bit:=Temp;
 end;
 while not IntegerValueIsZero(Bit) do begin
  IntegerValueAdd(Temp,TempResult,Bit);
  if IntegerValueUnsignedCompare(Number,Temp)>=0 then begin
   IntegerValueSub(NewTemp,Number,Temp);
   Number:=NewTemp;
   IntegerValueUnsignedShiftRightInternal(NewTemp,TempResult,1);
   IntegerValueAdd(TempResult,NewTemp,Bit);
  end else begin
   IntegerValueUnsignedShiftRightInternal(NewTemp,TempResult,1);
   TempResult:=NewTemp;
  end;
  IntegerValueUnsignedShiftRightInternal(NewTemp,Bit,2);
  Bit:=NewTemp;
 end;
 Dest:=TempResult;
end;

procedure IntegerValueParse(out Dest:TIntegerValue;const s:ansistring;const StartPosition:longint=1);
var i,j,k:longint;
    Negative:boolean;
    TempResult,Temp,Base,Digit:TIntegerValue;
begin
 IntegerValueSetQWord(TempResult,0);
 j:=StartPosition;
 k:=length(s);
 while (j<=k) and (s[j] in [#1..#32]) do begin
  inc(j);
 end;
 Negative:=false;
 if (j<=k) and (s[j]='-') then begin
  Negative:=true;
  inc(j);
 end else if (j<=k) and (s[j]='+') then begin
  inc(j);
 end;
 if s[j]='0' then begin
  inc(j);
  case s[j] of
   'x','X','h','H':begin
    for i:=j+1 to k do begin
     case s[i] of
      '0'..'9':begin
       IntegerValueSetQWord(Digit,byte(ansichar(s[i]))-byte(ansichar('0')));
       IntegerValueShiftLeftInternal(Temp,TempResult,4);
       IntegerValueAdd(TempResult,Temp,Digit);
      end;
      'a'..'f':begin
       IntegerValueSetQWord(Digit,(byte(ansichar(s[i]))-byte(ansichar('a')))+$a);
       IntegerValueShiftLeftInternal(Temp,TempResult,4);
       IntegerValueAdd(TempResult,Temp,Digit);
      end;
      'A'..'F':begin
       IntegerValueSetQWord(Digit,(byte(ansichar(s[i]))-byte(ansichar('A')))+$a);
       IntegerValueShiftLeftInternal(Temp,TempResult,4);
       IntegerValueAdd(TempResult,Temp,Digit);
      end;
      else begin
       break;
      end;
     end;
    end;
   end;
   'o','O','q','Q':begin
    for i:=j+1 to k do begin
     case s[i] of
      '0'..'7':begin
       IntegerValueSetQWord(Digit,byte(ansichar(s[i]))-byte(ansichar('0')));
       IntegerValueShiftLeftInternal(Temp,TempResult,3);
       IntegerValueAdd(TempResult,Temp,Digit);
      end;
      else begin
       break;
      end;
     end;
    end;
   end;
   'b','B','y','Y':begin
    for i:=j+1 to k do begin
     case s[i] of
      '0'..'1':begin
       IntegerValueSetQWord(Digit,byte(ansichar(s[i]))-byte(ansichar('0')));
       IntegerValueShiftLeftInternal(Temp,TempResult,1);
       IntegerValueAdd(TempResult,Temp,Digit);
      end;
      else begin
       break;
      end;
     end;
    end;
   end;
   'd','D','t','T':begin
    IntegerValueSetQWord(Base,10);
    for i:=j+1 to k do begin
     if s[i] in ['0'..'9'] then begin
      IntegerValueSetQWord(Digit,byte(ansichar(s[i]))-byte(ansichar('0')));
      IntegerValueMul(Temp,TempResult,Base);
      IntegerValueAdd(TempResult,Temp,Digit);
     end else begin
      break;
     end;
    end;
   end;
   else begin
    IntegerValueSetQWord(Base,10);
    for i:=j to k do begin
     if s[i] in ['0'..'9'] then begin
      IntegerValueSetQWord(Digit,byte(ansichar(s[i]))-byte(ansichar('0')));
      IntegerValueMul(Temp,TempResult,Base);
      IntegerValueAdd(TempResult,Temp,Digit);
     end else begin
      break;
     end;
    end;
   end;
  end;
 end else begin
  IntegerValueSetQWord(Base,10);
  for i:=j to k do begin
   if s[i] in ['0'..'9'] then begin
    IntegerValueSetQWord(Digit,byte(ansichar(s[i]))-byte(ansichar('0')));
    IntegerValueMul(Temp,TempResult,Base);
    IntegerValueAdd(TempResult,Temp,Digit);
   end else begin
    break;
   end;
  end;
 end;
 if Negative then begin
  IntegerValueNeg(Dest,TempResult);
 end else begin
  Dest:=TempResult;
 end;
end;

function IntegerValueToStr(const Source:TIntegerValue):ansistring;
var Temp,NewTemp,OtherTemp,Base,Digit:TIntegerValue;
    Negative:boolean;
begin
 result:='';
 Negative:=(Source[IntegerValueDWords-1] and longword($80000000))<>0;
 if Negative then begin
  IntegerValueNeg(Temp,Source);
 end else begin
  Temp:=Source;
 end;
 if IntegerValueIsZero(Temp) then begin
  result:='0';
 end else begin
  IntegerValueSetQWord(Base,10);
  while not IntegerValueIsZero(Temp) do begin
   IntegerValueDiv(NewTemp,Temp,Base);
   IntegerValueMul(OtherTemp,NewTemp,Base);
   IntegerValueSub(Digit,Temp,OtherTemp);
   Temp:=NewTemp;
   result:=ansichar(byte(byte(ansichar('0'))+Digit[0]))+result;
  end;
 end;
 if Negative then begin
  result:='-'+result;
 end;
end;

function IntegerValueToHex(const Source:TIntegerValue):ansistring;
var Temp,NewTemp:TIntegerValue;
    Negative:boolean;
begin
 result:='';
 Negative:=(Source[IntegerValueDWords-1] and longword($80000000))<>0;
 if Negative then begin
  IntegerValueNeg(Temp,Source);
 end else begin
  Temp:=Source;
 end;
 if IntegerValueIsZero(Temp) then begin
  result:='0';
 end else begin
  while not IntegerValueIsZero(Temp) do begin
   if (Temp[0] and $f)<10 then begin
    result:=ansichar(byte(byte(ansichar('0'))+(Temp[0] and $f)))+result;
   end else begin
    result:=ansichar(byte(byte(ansichar('a'))+((Temp[0] and $f)-$a)))+result;
   end;
   IntegerValueUnsignedShiftRightInternal(NewTemp,Temp,4);
   Temp:=NewTemp;
  end;
 end;
 result:='0x'+result;
 if Negative then begin
  result:='-'+result;
 end;
end;

{$ifdef UNIX}
const RTLD_LAZY=$001;
      RTLD_NOW=$002;
      RTLD_BINDING_MASK=$003;
      LibraryLib={$ifdef Linux}'libdl.so.2'{$else}'c'{$endif};

function LoadLibraryEx(Name:pansichar;Flags:longint):pointer; cdecl; external LibraryLib name 'dlopen';
function GetProcAddressEx(Lib:pointer;Name:pansichar):Pointer; cdecl; external LibraryLib name 'dlsym';
function FreeLibraryEx(Lib:pointer):longword; cdecl; external LibraryLib name 'dlclose';

function LoadLibrary(Name:pansichar):THandle;
begin
 result:=THandle(LoadLibraryEx(Name,RTLD_LAZY));
end;

function GetProcAddress(LibHandle:THandle;ProcName:pansichar):pointer;
begin
 result:=GetProcAddressEx(pointer(LibHandle),ProcName);
end;

function FreeLibrary(LibHandle:THandle):boolean;
begin
 if LibHandle=0 then begin
  result:=false;
 end else begin
  result:=FreeLibraryEx(Pointer(LibHandle))=0;
 end;
end;
{$endif}

const C1970=2440588;
      D0=1461;
      D1=146097;
      D2=1721119;

function GregorianToJulian(Year,Month,Day:longword):longword;
begin
 if Month<=2 then begin
  dec(Year);
  inc(Month,12);
 end;
 dec(Month,3);
 result:=longword((((Month*153)+2) div 5)+Day)+D2+(((Year div 100)*D1) shr 2)+(((Year mod 100)*D0) shr 2);
end;

procedure JulianToGregorian(Julian:longword;var Year,Month,Day:longword);
Var Temp,TempYear:longword;
begin
 Temp:=(((Julian-D2) shl 2)-1);
 Julian:=Temp div D1;
 TempYear:=(Temp mod D1) or 3;
 Year:=(TempYear div D0);
 Temp:=((((TempYear mod D0)+4) shr 2)*5)-3;
 Day:=((Temp mod 153)+5) div 5;
 Month:=Temp div 153;
 If Month>=10 then begin
  inc(Year);
  dec(Month,12);
 End;
 inc(Month,3);
 Year:=Year+(Julian*100);
end;

procedure DecodeUnixTime(UnixTimeStamp:longword;var Year,Month,Day,Hour,Minute,Second:longword);
var Temp,JulianTime:longword;
begin
 Temp:=UnixTimeStamp div 86400;
 JulianTime:={GregorianToJulian(1970,1,1)}C1970+Temp;
 JulianToGregorian(JulianTime,Year,Month,Day);
 Temp:=UnixTimeStamp mod 86400;
 Hour:=Temp div 3600;
 Minute:=(Temp mod 3600) div 60;
 Second:=Temp mod 60;
end;

function EncodeUnixTime(Year,Month,Day,Hour,Minute,Second:longword):longword;
begin
 result:=((GregorianToJulian(Year,Month,Day)-{GregorianToJulian(1970,1,1)}C1970)*86400)+(Hour*3600)+(Minute*60)+Second;
end;

function DayOfWeekEx(Year,Month,Day:longword):longword;
begin
 result:=((3*Year)-((7*(Year+(Month+9) div 12)) div 4)+((23*Month) div 9)+(Day+2)+((((Year-longword(ord(Month<3))) div 100+1)*3) div 4)-16+1) mod 7;
end;

function DayOfWeek(UnixTimeStamp:longword):longword;
var Year,Month,Day,Hour,Minute,Second:longword;
begin
 DecodeUnixTime(UnixTimeStamp,Year,Month,Day,Hour,Minute,Second);
 result:=((3*Year)-((7*(Year+(Month+9) div 12)) div 4)+((23*Month) div 9)+(Day+2)+((((Year-longword(ord(Month<3))) div 100+1)*3) div 4)-16+1) mod 7;
end;

function LeapYearEx(Year:longword):longbool;
begin
 result:=((Year mod 4)=0) and not (((Year mod 100)=0) and ((Year mod 400)<>0));
end;

function LeapYear(UnixTimeStamp:longword):longbool;
var Year,Month,Day,Hour,Minute,Second:longword;
begin
 DecodeUnixTime(UnixTimeStamp,Year,Month,Day,Hour,Minute,Second);
 result:=((Year mod 4)=0) and not (((Year mod 100)=0) and ((Year mod 400)<>0));
end;

function DayLightSavings(UnixTimeStamp:longword):longbool;
var Year,Month,Day,Hour,Minute,Second:longword;
    AprilSunday,OctoberSunday:longword;
begin
 DecodeUnixTime(UnixTimeStamp,Year,Month,Day,Hour,Minute,Second);
 Day:=DayOfWeekEx(1,4,Year);
 if Day>0 then begin
  Day:=(1+7)-Day;
 end else begin
  Day:=1;
 end;
 Month:=4;
 Hour:=2;
 Minute:=0;
 Second:=0;
 AprilSunday:=EncodeUnixTime(Year,Month,Day,Hour,Minute,Second);
 Day:=DayOfWeekEx(25,10,Year);
 if Day>0 then begin
  Day:=(25+7)-Day;
 end else begin
  Day:=25;
 end;
 Month:=10;
 OctoberSunday:=EncodeUnixTime(Year,Month,Day,Hour,Minute,Second);
 DayLightSavings:=(UnixTimeStamp>=AprilSunday) and (UnixTimeStamp<OctoberSunday);
end;

function DayLightSavingsEx(Year,Month,Day,Hour,Minute,Second:longword):longbool;
begin
 result:=DayLightSavings(EncodeUnixTime(Year,Month,Day,Hour,Minute,Second));
end;

function Jan_1_1970:TDateTime;
begin
 result:=EncodeDate(1970,1,1);
end;

function UnixTimeToDateTime(UnixTime:int64):TDateTime;
begin
 result:=25569.0+(UnixTime/SecsPerDay);
end;

function DateTimeToUnixTime(DT:TDateTime):int64;
begin
 result:=trunc(SecsPerDay*(DT-25569.0));
end;

function NowUnixTime:longword;
{var st:TSystemTime;
begin
 DateTimeToSystemTime(Now,st);
 result:=EncodeUnixTime(st.wYear,st.wMonth,st.wDay,st.wHour,st.wMinute,st.wSecond);
end;}
{begin
 result:=DateTimeToUnixTime(Now);
end;}
var wYear,wMonth,wDay,wHour,wMinute,wSecond,wMillisecond:word;
    DT:TDateTime;
begin
 DT:=Now;
//DecodeDateTime(Now,wYear,wMonth,wDay,wHour,wMinute,wSecond,wMillisecond);
 DecodeDate(DT,wYear,wMonth,wDay);
 DecodeTime(DT,wHour,wMinute,wSecond,wMillisecond);
 result:=EncodeUnixTime(wYear,wMonth,wDay,wHour,wMinute,wSecond);
end;

function CheckFile(FileName:ansistring):boolean;
var Stream:TFileStream;
begin
 try
  Stream:=TFileStream.Create(FileName,fmOpenRead or fmShareDenyWrite);
  try
   result:=Stream.Size>=0;
  finally
   Stream.Free;
  end;
 except
  result:=false;
 end;
end;

function ReadFileAsString(SourceFile:ansistring):ansistring;
var f:TFileStream;
begin
 f:=TFileStream.Create(SourceFile,fmOpenRead or fmShareDenyWrite);
 try
  SetLength(result,f.Size);
  if f.Size>0 then begin
   f.Read(result[1],f.Size);
  end;
 finally
  f.Free;
 end;
end;

function IntToStr(i:longint):ansistring;
begin
 Str(i,result);
end;

function Int64ToStr(i:int64):ansistring;
begin
 Str(i,result);
end;

function LongWordToHex(Value:longword):ansistring; register;
const HexNumbers:array[0..$f] of ansichar='0123456789ABCDEF';
begin
 result:=HexNumbers[(Value shr 28) and $f]+HexNumbers[(Value shr 24) and $f]+
         HexNumbers[(Value shr 20) and $f]+HexNumbers[(Value shr 16) and $f]+
         HexNumbers[(Value shr 12) and $f]+HexNumbers[(Value shr 8) and $f]+
         HexNumbers[(Value shr 4) and $f]+HexNumbers[(Value shr 0) and $f];
end;

{$ifdef WIN32}
const Delimiter='\';
      AntiDelimiter='/';
{$else}
const Delimiter='/';
      AntiDelimiter='\';
{$endif}

function CorrectFile(APath:ansistring):ansistring;
var i:longint;
begin
 result:=APath;
 for i:=1 to length(result) do begin
  if result[i]=AntiDelimiter then begin
   result[i]:=Delimiter;
  end;
 end;
end;

function CorrectFilePath(APath:ansistring):ansistring;
var i:longint;
begin
 result:=APath;
 for i:=1 to length(result) do begin
  if result[i]=AntiDelimiter then begin
   result[i]:=Delimiter;
  end;
 end;
 if length(result)<>0 then begin
  if result[length(result)]<>Delimiter then begin
   result:=result+Delimiter;
  end;
 end;
end;

function GetAbsolutePath(BasePath,RelativePath:ansistring):ansistring;
var index:longint;
    Directory:ansistring;
begin
 result:=CorrectFilePath(BasePath);
 while length(RelativePath)<>0 do begin
  index:=Pos(Delimiter,RelativePath);
  if index<>0 then begin
   Directory:=Copy(RelativePath,1,index-1);
   Delete(RelativePath,1,index);
  end else begin
   Directory:=RelativePath;
   RelativePath:='';
  end;
  if Directory='..' then begin
   if length(result)<>0 then begin
    if result[length(result)]=Delimiter then begin
     result:=Copy(result,1,length(result)-1);
    end;
   end;
   for index:=length(result) downto 1 do begin
    if result[index]=Delimiter then begin
     result:=Copy(result,1,index);
     break;
    end;
   end;
  end else if Directory='.' then begin
   result:=CorrectFilePath(result);
  end else begin
   result:=result+Directory+Delimiter;
  end;
 end;
end;

function GetAbsoluteFile(BasePath,FileName:ansistring):ansistring;
begin
 BasePath:=CorrectFilePath(BasePath);
 FileName:=CorrectFile(FileName);
{$ifdef WIN32}
 if Pos(':\',FileName)=2 then begin
{$else}
 if Pos(Delimiter,FileName)=1 then begin
{$endif}
  result:=FileName;
 end else begin
  result:=GetAbsolutePath(BasePath,ExtractFilePath(FileName))+ExtractFileName(FileName);
 end;
end;

function GetAbsoluteFileEx(BaseFile,FileName:ansistring):ansistring;
begin
 BaseFile:=CorrectFile(BaseFile);
 FileName:=CorrectFile(FileName);
{$ifdef WIN32}
 if Pos(':\',FileName)=2 then begin
{$else}
 if Pos(Delimiter,FileName)=1 then begin
{$endif}
  result:=FileName;
 end else begin
  result:=GetAbsolutePath(ExtractFilePath(BaseFile),ExtractFilePath(FileName))+ExtractFileName(FileName);
 end;
end;                 

function StringToFloat(const FloatString:ansistring;var FloatValue;const IEEEFormat:TIEEEFormat;const RoundMode:longint=FLOAT_ROUND_TO_NEAREST;const DenormalsAreZero:boolean=false):boolean;
const LIMB_BITS=32;
      LIMB_BYTES=4;
      LIMB_BYTES_MASK=3;
      LIMB_BYTES_SHIFT=2; // 2^2 = 4
      LIMB_SHIFT=5;
      LIMB_TOP_BIT=longword(longword(1) shl (LIMB_BITS-1));
      LIMB_MASK=longword(not 0);
      LIMB_ALL_BYTES=longword($01010101);
      MANT_LIMBS=24;//6;
      MANT_DIGITS=208;//52;
      FL_ZERO=0;
      FL_DENORMAL=1;
      FL_NORMAL=2;
      FL_INFINITY=3;
      FL_QNAN=4;
      FL_SNAN=5;
type PFPLimb=^TFPLimb;
     TFPLimb=longword;
     PFPLimbs=^TFPLimbs;
     TFPLimbs=array[0..65535] of TFPLimb;
     PFP2Limb=^TFP2Limb;
     TFP2Limb=uint64;
     PMantissa=^TMantissa;
     TMantissa=array[0..MANT_LIMBS-1] of TFPLimb;
 function MantissaMultiply(var MantissaA,MantissaB:TMantissa):longint;
 var i,j:longint;
     n:TFP2Limb;
     Temp:array[0..(MANT_DIGITS*2)] of TFP2Limb;
 begin
  for i:=low(Temp) to high(Temp) do begin
   Temp[i]:=0;
  end;
  for i:=0 to MANT_LIMBS-1 do begin
   for j:=0 to MANT_LIMBS-1 do begin
    n:=TFP2Limb(MantissaA[i])*TFP2Limb(MantissaB[j]);
    inc(Temp[i+j],n shr LIMB_BITS);
    inc(Temp[i+j+1],TFPLimb(n and LIMB_MASK));
   end;
  end;
  for i:=(MANT_LIMBS*2) downto 1 do begin
   inc(Temp[i-1],Temp[i] shr LIMB_BITS);
   Temp[i]:=Temp[i] and LIMB_MASK;
  end;
  if (Temp[0] and LIMB_TOP_BIT)<>0 then begin
   for i:=0 to MANT_LIMBS-1 do begin
    MantissaA[i]:=Temp[i] and LIMB_MASK;
   end;
   result:=0;
  end else begin
   for i:=0 to MANT_LIMBS-1 do begin
    MantissaA[i]:=(Temp[i] shl 1) or (ord((Temp[i+1] and LIMB_TOP_BIT)<>0) and 1);
   end;
   result:=-1;
  end;
 end;
 function ReadExponent(const ExponentStringValue:ansistring;const ExponentStringStartPosition,MaxValue:longint):longint;
 var ExponentStringPosition,ExponentStringLength:longint;
     Negative:boolean;
 begin
  result:=0;
  Negative:=false;
  ExponentStringPosition:=ExponentStringStartPosition;
  ExponentStringLength:=length(ExponentStringValue);
  if (ExponentStringPosition<=ExponentStringLength) and (ExponentStringValue[ExponentStringPosition]='+') then begin
   inc(ExponentStringPosition);
  end else if (ExponentStringPosition<=ExponentStringLength) and (ExponentStringValue[ExponentStringPosition]='-') then begin
   inc(ExponentStringPosition);
   Negative:=true;
  end;
  while ExponentStringPosition<=ExponentStringLength do begin
   case ExponentStringValue[ExponentStringPosition] of
    '0'..'9':begin
     if result<MaxValue then begin
      result:=(result*10)+(byte(ansichar(ExponentStringValue[ExponentStringPosition]))-byte(ansichar('0')));
      if result>MaxValue then begin
       result:=MaxValue;
      end;
     end;
    end;
    else begin
     raise EStringToFloat.Create('Invalid character in floating-point constant '+FloatString+': '''+ExponentStringValue[ExponentStringPosition]+'''');
     result:=$7fffffff;
     exit;
    end;
   end;
   inc(ExponentStringPosition);
  end;
  if Negative then begin
   result:=-result;
  end;
 end;
 function ProcessDecimal(const FloatStringValue:ansistring;const FloatStringStartPosition:longint;out Mantissa:TMantissa;var Exponent:longint):boolean;
 var FloatStringPosition,FloatStringLength,TenPower,TwoPower,ExtraTwos,ExponentValue,MantissaPosition,DigitPos,StoredDigitPos,DigitPosBackwards,
     Value:longint;
     Bit,Carry:TFPLimb;
     Started,SeenDot{,Warned}:boolean;
     //m:PFPLimb;
     Digits:array[0..MANT_DIGITS-1] of byte;
     Mult:TMantissa;
 begin
  //Warned:=false;
  TenPower:=0;
  DigitPos:=0;
  Started:=false;
  SeenDot:=false;
  FloatStringPosition:=FloatStringStartPosition;
  FloatStringLength:=length(FloatStringValue);
  while FloatStringPosition<=FloatStringLength do begin
   case FloatStringValue[FloatStringPosition] of
    '.':begin
     if SeenDot then begin
      raise EStringToFloat.Create('Too many periods in floating-point constant');
      result:=false;
      exit;
     end else begin
      SeenDot:=true;
     end;
    end;
    '0'..'9':begin
     if (FloatStringValue[FloatStringPosition]='0') and not Started then begin
      if SeenDot then begin
       dec(TenPower);
      end;
     end else begin
      Started:=true;
      if DigitPos<MANT_DIGITS then begin
       Digits[DigitPos]:=byte(ansichar(FloatStringValue[FloatStringPosition]))-byte(ansichar('0'));
       inc(DigitPos);
      end else begin
       //Warned:=true;
      end;
      if not SeenDot then begin
       inc(TenPower);
      end;
     end;
    end;
    'e','E':begin
     break;
    end;
    else begin
     raise EStringToFloat.Create('Invalid character in floating-point constant '+FloatString+': '''+FloatStringValue[FloatStringPosition]+'''');
     result:=false;
     exit;
    end;
   end;
   inc(FloatStringPosition);
  end;
  if FloatStringPosition<=FloatStringLength then begin
   if FloatStringValue[FloatStringPosition] in ['e','E'] then begin
    inc(FloatStringPosition);
    ExponentValue:=ReadExponent(FloatStringValue,FloatStringPosition,5000);
    if ExponentValue=$7fffffff then begin
     result:=false;
     exit;
    end;
    inc(TenPower,ExponentValue);
   end else begin
    raise EStringToFloat.Create('Invalid character in floating-point constant '+FloatString+': '''+FloatStringValue[FloatStringPosition]+'''');
    result:=false;
    exit;
   end;
  end;
  for MantissaPosition:=0 to MANT_LIMBS-1 do begin
   Mantissa[MantissaPosition]:=0;
  end;
  Bit:=LIMB_TOP_BIT;
  StoredDigitPos:=0;
  Started:=false;
  TwoPower:=0;
  MantissaPosition:=0;
  while MantissaPosition<MANT_LIMBS do begin
   Carry:=0;  
   while (DigitPos>StoredDigitPos) and (Digits[DigitPos-1]=0) do begin
    dec(DigitPos);
   end;
   if DigitPos<=StoredDigitPos then begin
    break;
   end;
   DigitPosBackwards:=DigitPos;
   while DigitPosBackwards>StoredDigitPos do begin
    dec(DigitPosBackwards);
    Value:=(2*Digits[DigitPosBackwards])+Carry;
    if Value>=10 then begin
     dec(Value,10);
     Carry:=1;
    end else begin
     Carry:=0;
    end;
    Digits[DigitPosBackwards]:=Value;
   end;
   if Carry<>0 then begin
    Mantissa[MantissaPosition]:=Mantissa[MantissaPosition] or Bit;
    Started:=true;
   end;
   if Started then begin
    if Bit=1 then begin
     Bit:=LIMB_TOP_BIT;
     inc(MantissaPosition);
    end else begin
     Bit:=Bit shr 1;
    end;
   end else begin
    dec(TwoPower);
   end;
  end;
  inc(TwoPower,TenPower);
  if TenPower<0 then begin
   for MantissaPosition:=0 to MANT_LIMBS-2 do begin
    Mult[MantissaPosition]:=(longword($cc)*LIMB_ALL_BYTES);
   end;
   Mult[MANT_LIMBS-1]:=(longword($cc)*LIMB_ALL_BYTES)+1;
   ExtraTwos:=-2;
   TenPower:=-TenPower;
  end else if TenPower>0 then begin
   Mult[0]:=longword(5) shl (LIMB_BITS-3);
   for MantissaPosition:=1 to MANT_LIMBS-1 do begin
    Mult[MantissaPosition]:=0;
   end;
   ExtraTwos:=3;
  end else begin
   ExtraTwos:=0;
  end;
  while TenPower<>0 do begin
   if (TenPower and 1)<>0 then begin
    inc(TwoPower,ExtraTwos+MantissaMultiply(Mantissa,Mult));
   end;
   inc(ExtraTwos,ExtraTwos+MantissaMultiply(Mult,Mult));
   TenPower:=TenPower shr 1;
  end;
  Exponent:=TwoPower;
  result:=true;
 end;
 function ProcessNonDecimal(const FloatStringValue:ansistring;const FloatStringStartPosition,Bits:longint;out Mantissa:TMantissa;var Exponent:longint):boolean;
 const Log2Table:array[0..15] of longint=(-1,0,1,1,2,2,2,2,3,3,3,3,3,3,3,3);
 var FloatStringPosition,FloatStringLength,TwoPower,ExponentValue,MantissaPosition,Value,Radix,MantissaShift,l:longint;
     SeenDigit,SeenDot:boolean;
     MantissaPointer:PFPLimb;
     Mult:array[0..MANT_LIMBS] of TFPLimb;
 begin
  for MantissaPosition:=0 to MANT_LIMBS do begin
   Mult[MantissaPosition]:=0;
  end;
  Radix:=1 shl Bits;
  TwoPower:=0;
  MantissaShift:=0;
  MantissaPointer:=@Mult[0];
  SeenDigit:=false;
  SeenDot:=false;
  FloatStringPosition:=FloatStringStartPosition;
  FloatStringLength:=length(FloatStringValue);
  while FloatStringPosition<=FloatStringLength do begin
   case FloatStringValue[FloatStringPosition] of
    '.':begin
     if SeenDot then begin
      raise EStringToFloat.Create('Too many periods in floating-point constant');
      result:=false;
      exit;
     end else begin
      SeenDot:=true;
     end;
    end;
    '0'..'9','a'..'f','A'..'F':begin
     Value:=byte(ansichar(FloatStringValue[FloatStringPosition]));
     if Value in [byte(ansichar('0'))..byte(ansichar('9'))] then begin
      dec(Value,byte(ansichar('0')));
     end else if Value in [byte(ansichar('a'))..byte(ansichar('f'))] then begin
      Value:=(Value-byte(ansichar('a')))+$a;
     end else if Value in [byte(ansichar('A'))..byte(ansichar('F'))] then begin
      Value:=(Value-byte(ansichar('A')))+$a;
     end else begin
      raise EStringToFloat.Create('Invalid character in floating-point constant '+FloatString+': '''+FloatStringValue[FloatStringPosition]+'''');
      result:=false;
      exit;
     end;
     if Value<Radix then begin
      if (Value<>0) and not SeenDigit then begin
       l:=Log2Table[Value];
       SeenDigit:=true;
       MantissaPointer:=@Mult[0];
       MantissaShift:=(LIMB_BITS-1)-l;
       if SeenDot then begin
        TwoPower:=(TwoPower-Bits)+l;
       end else begin
        TwoPower:=(l+1)-Bits;
       end;
      end;
      if SeenDigit then begin
       if MantissaShift<=0 then begin
        MantissaPointer^:=MantissaPointer^ or longword(longword(Value) shr longword(-MantissaShift));
        inc(MantissaPointer);
        if TSASMPtrUInt(MantissaPointer)>TSASMPtrUInt(pointer(@Mult[MANT_LIMBS])) then begin
         MantissaPointer:=@Mult[MANT_LIMBS];
        end;
        inc(MantissaShift,LIMB_BITS);
       end;
       MantissaPointer^:=MantissaPointer^ or longword(longword(Value) shl longword(MantissaShift));
       dec(MantissaShift,Bits);
       if not SeenDot then begin
        inc(TwoPower,Bits);
       end;
      end else begin
       if SeenDot then begin
        dec(TwoPower,Bits);
       end;
      end;
     end else begin
      raise EStringToFloat.Create('Invalid character in floating-point constant '+FloatString+': '''+FloatStringValue[FloatStringPosition]+'''');
      result:=false;
      exit;
     end;
    end;
    'p','P':begin
     break;
    end;
    else begin
     raise EStringToFloat.Create('Invalid character in floating-point constant '+FloatString+': '''+FloatStringValue[FloatStringPosition]+'''');
     result:=false;
     exit;
    end;
   end;
   inc(FloatStringPosition);
  end;
  if FloatStringPosition<=FloatStringLength then begin
   if FloatStringValue[FloatStringPosition] in ['p','P'] then begin
    inc(FloatStringPosition);
    ExponentValue:=ReadExponent(FloatStringValue,FloatStringPosition,20000);
    if ExponentValue=$7fffffff then begin
     result:=false;
     exit;
    end;
    inc(TwoPower,ExponentValue);
   end else begin
    raise EStringToFloat.Create('Invalid character in floating-point constant '+FloatString+': '''+FloatStringValue[FloatStringPosition]+'''');
    result:=false;
    exit;
   end;
  end;
  if SeenDigit then begin
   for MantissaPosition:=0 to MANT_LIMBS-1 do begin
    Mantissa[MantissaPosition]:=Mult[MantissaPosition];
   end;
   Exponent:=TwoPower;
  end else begin
   for MantissaPosition:=0 to MANT_LIMBS-1 do begin
    Mantissa[MantissaPosition]:=0;
   end;
   Exponent:=0;
  end;
  result:=true;
 end;
 procedure MantissaShiftRight(var Mantissa:TMantissa;const Shift:longint);
 var Next,Current:TFPLimb;
     Index,ShiftRight,ShiftLeft,ShiftOffset:longint;
 begin
  Index:=0;
  ShiftRight:=Shift and (LIMB_BITS-1);
  ShiftLeft:=LIMB_BITS-ShiftRight;
  ShiftOffset:=Shift shr LIMB_SHIFT;
  if ShiftRight=0 then begin
   if ShiftOffset<>0 then begin
    Index:=MANT_LIMBS-1;
    while Index>=ShiftOffset do begin
     Mantissa[Index]:=Mantissa[Index-ShiftOffset];
     dec(Index);
    end;
   end;
  end else begin
   Next:=Mantissa[(MANT_LIMBS-1)-ShiftOffset] shr ShiftRight;
   Index:=MANT_LIMBS-1;
   while Index>ShiftOffset do begin
    Current:=Mantissa[(Index-ShiftOffset)-1];
    Mantissa[Index]:=(Current shl ShiftLeft) or Next;
    Next:=Current shr ShiftRight;
    dec(Index);
   end;
   Mantissa[Index]:=Next;
   dec(Index);
  end;
  while Index>=0 do begin
   Mantissa[Index]:=0;
   dec(Index);
  end;
 end;
 procedure MantissaSetBit(var Mantissa:TMantissa;Bit:longint);
 begin
  Mantissa[Bit shr LIMB_SHIFT]:=Mantissa[Bit shr LIMB_SHIFT] or (LIMB_TOP_BIT shr (Bit and (LIMB_BITS-1)));
 end;
 function MantissaTestBit(const Mantissa:TMantissa;Bit:longint):boolean;
 begin
  result:=((Mantissa[Bit shr LIMB_SHIFT] shr ((not Bit) and (LIMB_BITS-1))) and 1)<>0;
 end;
 function MantissaIsZero(const Mantissa:TMantissa):boolean;
 var i:longint;
 begin
  result:=true;
  for i:=0 to MANT_LIMBS-1 do begin
   if Mantissa[i]<>0 then begin
    result:=false;
    exit;
   end;
  end;
 end;
 procedure MantissaRound(const Negative:boolean;var Mantissa:TMantissa;const BitPos:longint);
 var i,p:longint;
     Bit:TFPLimb;
  function RoundAbsDown:boolean;
  var j:longint;
  begin
   Mantissa[i]:=Mantissa[i] and not (Bit-1);
   for j:=i+1 to MANT_LIMBS-1 do begin
    Mantissa[j]:=0;
   end;
   result:=false;
  end;
  function RoundAbsUp:boolean;
  var j:longint;
  begin
   Mantissa[i]:=(Mantissa[i] and not (Bit-1))+Bit;
   for j:=i+1 to MANT_LIMBS-1 do begin
    Mantissa[j]:=0;
   end;
   while (i>0) and (Mantissa[i]=0) do begin
    dec(i);
    inc(Mantissa[i]);
   end;
   result:=Mantissa[0]=0;
  end;
  function RoundTowardsInfinity:boolean;
  var j:longint;
      m:TFPLimb;
  begin
   m:=Mantissa[i] and ((Bit shl 1)-1);
   for j:=i+1 to MANT_LIMBS-1 do begin
    m:=m or Mantissa[j];
   end;
   if m<>0 then begin
    result:=RoundAbsUp;
   end else begin
    result:=RoundAbsDown;
   end;
  end;
  function RoundNear:boolean;
  var j:longint;
      m:longword;
  begin
   if (Mantissa[i] and Bit)<>0 then begin
    Mantissa[i]:=Mantissa[i] and not Bit;
    m:=Mantissa[i] and ((Bit shl 1)-1);
    for j:=i+1 to MANT_LIMBS-1 do begin
     m:=m or Mantissa[j];
    end;
    Mantissa[i]:=Mantissa[i] or Bit;
    if m<>0 then begin
     result:=RoundAbsUp;
    end else begin
     if MantissaTestBit(Mantissa,BitPos-1) then begin
      result:=RoundAbsUp;
     end else begin
      result:=RoundAbsDown;
     end;
    end;
   end else begin
    result:=RoundAbsDown;
   end;
  end;
 begin
  i:=BitPos shr LIMB_SHIFT;
  p:=BitPos and (LIMB_BITS-1);
  Bit:=LIMB_TOP_BIT shr p;
  case RoundMode of
   FLOAT_ROUND_TO_NEAREST:begin
    result:=RoundNear;
   end;
   FLOAT_ROUND_TOWARD_ZERO:begin
    result:=RoundAbsDown;
   end;
   FLOAT_ROUND_UPWARD:begin
    if Negative then begin
     result:=RoundAbsDown;
    end else begin
     result:=RoundTowardsInfinity;
    end;
   end;
   FLOAT_ROUND_DOWNWARD:begin
    if Negative then begin
     result:=RoundAbsUp;
    end else begin
     result:=RoundTowardsInfinity;
    end;
   end;
   else begin
    result:=false;
   end;
  end;
 end;
 function ProcessToPackedBCD(const FloatStringValue:ansistring;const FloatStringStartPosition:longint;ResultBytes:pbyte;const Negative:boolean):boolean;
 var FloatStringPosition,FloatStringLength,Count,LoValue,Value:longint;
 begin
  result:=false;
  if IEEEFormat.Bytes<>10 then begin
   raise EStringToFloat.Create('Packed BCD requires an 80-bit format');
   exit;
  end;
  FloatStringPosition:=FloatStringStartPosition;
  FloatStringLength:=length(FloatString);
  while (FloatStringPosition<=FloatStringLength) do begin
   case FloatString[FloatStringPosition] of
    '0'..'9':begin
     inc(FloatStringPosition);
    end;
    else begin
     raise EStringToFloat.Create('Invalid character in packed BCD constant '+FloatString+': '''+FloatStringValue[FloatStringPosition]+'''');
     exit;
    end;
   end;
  end;
  LoValue:=-1;
  Count:=0;
  while FloatStringPosition>FloatStringStartPosition do begin
   dec(FloatStringPosition);
   Value:=byte(ansichar(FloatStringValue[FloatStringPosition]))-byte(ansichar('0'));
   if LoValue<0 then begin
    LoValue:=Value;
   end else begin
    if Count<9 then begin
     ResultBytes^:=LoValue or (Value shl 4);
     inc(ResultBytes);
    end;
    inc(Count);
    LoValue:=-1;
   end;
  end;
  if LoValue>=0 then begin
   if Count<9 then begin
    ResultBytes^:=LoValue;
    inc(ResultBytes);
   end;
   inc(Count);
  end;
  while Count<9 do begin
   ResultBytes^:=0;
   inc(ResultBytes);
   inc(Count);
  end;
  if Negative then begin
   ResultBytes^:=$80;
  end else begin
   ResultBytes^:=0;
  end;
  result:=true;
 end;
var OK:boolean;
    FloatStringPosition,FloatStringLength,Exponent,ExpMax,FloatType,Shift,Bits,OnePos,i:longint;
    OneMask:TFPLimb;
    Negative:boolean;
    Mantissa:TMantissa;
    b:pbyte;
begin
 result:=false;
 Bits:=IEEEFormat.Bytes shl 3;
 OneMask:=LIMB_TOP_BIT shr ((IEEEFormat.Explicit+IEEEFormat.Exponent) and (LIMB_BITS-1));
 OnePos:=(IEEEFormat.Explicit+IEEEFormat.Exponent) shr LIMB_SHIFT;
 FloatStringPosition:=1;
 FloatStringLength:=length(FloatString);
 while (FloatStringPosition<=FloatStringLength) and (FloatString[FloatStringPosition] in [#1..#32]) do begin
  inc(FloatStringPosition);
 end;
 Negative:=false;
 if (FloatStringPosition<=FloatStringLength) and (FloatString[FloatStringPosition]='+') then begin
  inc(FloatStringPosition);
 end else if (FloatStringPosition<=FloatStringLength) and (FloatString[FloatStringPosition]='-') then begin
  inc(FloatStringPosition);
  Negative:=true;
 end;
 ExpMax:=1 shl (IEEEFormat.Exponent-1);
 if ((FloatStringPosition+2)<=length(FloatString)) and ((FloatString[FloatStringPosition]='I') and (FloatString[FloatStringPosition+1]='n') and (FloatString[FloatStringPosition+2]='f')) then begin
  FloatType:=FL_INFINITY;
 end else if ((FloatStringPosition+2)<=length(FloatString)) and ((FloatString[FloatStringPosition]='N') and (FloatString[FloatStringPosition+1]='a') and (FloatString[FloatStringPosition+2]='N')) then begin
  FloatType:=FL_QNAN;
 end else if ((FloatStringPosition+3)<=length(FloatString)) and ((FloatString[FloatStringPosition]='S') and (FloatString[FloatStringPosition+1]='N') and (FloatString[FloatStringPosition+2]='a') and (FloatString[FloatStringPosition+3]='N')) then begin
  FloatType:=FL_SNAN;
 end else if ((FloatStringPosition+3)<=length(FloatString)) and ((FloatString[FloatStringPosition]='Q') and (FloatString[FloatStringPosition+1]='N') and (FloatString[FloatStringPosition+2]='a') and (FloatString[FloatStringPosition+3]='N')) then begin
  FloatType:=FL_QNAN;
 end else begin
  if ((FloatStringPosition+1)<=length(FloatString)) and ((FloatString[FloatStringPosition]='0') and (FloatString[FloatStringPosition+1] in ['h','H','x','X'])) then begin
   inc(FloatStringPosition,2);
   OK:=ProcessNonDecimal(FloatString,FloatStringPosition,4,Mantissa,Exponent);
  end else if ((FloatStringPosition+1)<=length(FloatString)) and ((FloatString[FloatStringPosition]='0') and (FloatString[FloatStringPosition+1] in ['o','O','q','Q'])) then begin
   inc(FloatStringPosition,2);
   OK:=ProcessNonDecimal(FloatString,FloatStringPosition,3,Mantissa,Exponent);
  end else if ((FloatStringPosition+1)<=length(FloatString)) and ((FloatString[FloatStringPosition]='0') and (FloatString[FloatStringPosition+1] in ['b','B','y','Y'])) then begin
   inc(FloatStringPosition,2);
   OK:=ProcessNonDecimal(FloatString,FloatStringPosition,1,Mantissa,Exponent);
  end else if ((FloatStringPosition+1)<=length(FloatString)) and ((FloatString[FloatStringPosition]='0') and (FloatString[FloatStringPosition+1] in ['d','D','t','T'])) then begin
   inc(FloatStringPosition,2);
   OK:=ProcessDecimal(FloatString,FloatStringPosition,Mantissa,Exponent);
  end else if ((FloatStringPosition+1)<=length(FloatString)) and ((FloatString[FloatStringPosition]='0') and (FloatString[FloatStringPosition+1] in ['p','P'])) then begin
   inc(FloatStringPosition,2);
   result:=ProcessToPackedBCD(FloatString,FloatStringPosition,pointer(@FloatValue),Negative);
   exit;
  end else if (FloatStringPosition<=length(FloatString)) and (FloatString[FloatStringPosition]='$') then begin
   inc(FloatStringPosition);
   OK:=ProcessNonDecimal(FloatString,FloatStringPosition,4,Mantissa,Exponent);
  end else if (FloatStringPosition<=length(FloatString)) and (FloatString[FloatStringPosition]='&') then begin
   inc(FloatStringPosition);
   OK:=ProcessNonDecimal(FloatString,FloatStringPosition,3,Mantissa,Exponent);
  end else if (FloatStringPosition<=length(FloatString)) and (FloatString[FloatStringPosition]='%') then begin
   inc(FloatStringPosition);
   OK:=ProcessNonDecimal(FloatString,FloatStringPosition,1,Mantissa,Exponent);
  end else begin
   OK:=ProcessDecimal(FloatString,FloatStringPosition,Mantissa,Exponent);
  end;
  if OK then begin
   if (Mantissa[0] and LIMB_TOP_BIT)<>0 then begin
    dec(Exponent);
    if (Exponent>=(2-ExpMax)) and (Exponent<=ExpMax) then begin
     FloatType:=FL_NORMAL;
    end else if Exponent>0 then begin
     FloatType:=FL_INFINITY;
    end else begin
     FloatType:=FL_DENORMAL;
    end;
   end else begin
    FloatType:=FL_ZERO;
   end;
  end else begin
   FloatType:=FL_QNAN;
  end;
 end;
 repeat
  case FloatType of
   FL_ZERO:begin
    FillChar(Mantissa,SizeOf(Mantissa),#0);
   end;
   FL_DENORMAL:begin
    Shift:=IEEEFormat.Explicit-((Exponent+ExpMax)-(IEEEFormat.Exponent+2));
    MantissaShiftRight(Mantissa,Shift);
    MantissaRound(Negative,Mantissa,Bits);
    if (Mantissa[OnePos] and OneMask)<>0 then begin
     Exponent:=1;
     if IEEEFormat.Explicit=0 then begin
      Mantissa[OnePos]:=Mantissa[OnePos] and not OneMask;
     end;
     Mantissa[0]:=Mantissa[0] or (longword(Exponent) shl ((LIMB_BITS-1)-IEEEFormat.Exponent));
    end else begin
     if DenormalsAreZero or MantissaIsZero(Mantissa) then begin
      FloatType:=FL_ZERO;
      continue;
     end;
    end;
   end;
   FL_NORMAL:begin
    inc(Exponent,ExpMax-1);
    MantissaShiftRight(Mantissa,IEEEFormat.Exponent+IEEEFormat.Explicit);
    MantissaRound(Negative,Mantissa,Bits);
    if MantissaTestBit(Mantissa,(IEEEFormat.Exponent+IEEEFormat.Explicit)-1) then begin
     MantissaShiftRight(Mantissa,1);
     inc(Exponent);
     if Exponent>=((ExpMax shl 1)-1) then begin
      FloatType:=FL_INFINITY;
      continue;
     end;
    end;
    if IEEEFormat.Explicit=0 then begin
     Mantissa[OnePos]:=Mantissa[OnePos] and not OneMask;
    end;
    Mantissa[0]:=Mantissa[0] or (longword(Exponent) shl ((LIMB_BITS-1)-IEEEFormat.Exponent));
   end;
   FL_INFINITY,FL_QNAN,FL_SNAN:begin
    FillChar(Mantissa,SizeOf(Mantissa),#0);
    Mantissa[0]:=((longword(1) shl IEEEFormat.Exponent)-1) shl ((LIMB_BITS-1)-IEEEFormat.Exponent);
    if IEEEFormat.Explicit<>0 then begin
     Mantissa[OnePos]:=Mantissa[OnePos] or OneMask;
    end;
    case FloatType of
     FL_QNAN:begin
      MantissaSetBit(Mantissa,IEEEFormat.Exponent+IEEEFormat.Explicit+1);
     end;
     FL_SNAN:begin
      MantissaSetBit(Mantissa,IEEEFormat.Exponent+IEEEFormat.Explicit+IEEEFormat.Mantissa);
     end;
    end;
   end;
  end;
  break;
 until false;
 if Negative then begin
  Mantissa[0]:=Mantissa[0] or LIMB_TOP_BIT;
 end;
 b:=@FloatValue;
 for i:=IEEEFormat.Bytes-1 downto 0 do begin
  b^:=Mantissa[i shr LIMB_BYTES_SHIFT] shr ((LIMB_BYTES_MASK-(i and LIMB_BYTES_MASK)) shl 3);
  inc(b);
 end;
 result:=true;
end;

function FloatToRawString(const Src;const IEEEFormat:TIEEEFormat):ansistring;
var i,ExpMax,Start,End_,WorkExponent:longint;
    Sign,Exponent,Significand,FloatIntegerValue,ExponentMask,SignificandMask,Temp,OtherTemp:TIntegerValue;
    s:ansistring;
begin
 FIllChar(FloatIntegerValue,SizeOf(FloatIntegerValue),#0);
 Move(Src,FloatIntegerValue,IEEEFormat.Bytes);

 ExpMax:=1 shl (IEEEFormat.Exponent-1);

 IntegerValueSetQWord(ExponentMask,(1 shl IEEEFormat.Exponent)-1);

 IntegerValueSetQWord(Temp,1);
 IntegerValueShiftLeftInternal(SignificandMask,Temp,IEEEFormat.Mantissa+IEEEFormat.Explicit);
 IntegerValueSub(OtherTemp,SignificandMask,Temp);
 SignificandMask:=OtherTemp;

 IntegerValueUnsignedShiftRightInternal(Sign,FloatIntegerValue,IEEEFormat.Mantissa+IEEEFormat.Explicit+IEEEFormat.Exponent);

 IntegerValueUnsignedShiftRightInternal(Exponent,FloatIntegerValue,IEEEFormat.Mantissa+IEEEFormat.Explicit);
 IntegerValueAnd(Temp,Exponent,ExponentMask);
 Exponent:=Temp;

 IntegerValueAnd(Significand,FloatIntegerValue,SignificandMask);

 Start:=0;
 End_:=IEEEFormat.Mantissa;
 if IntegerValueIsZero(Sign) then begin
  result:='';
 end else begin
  result:='-';
 end;

 if IntegerValueEquals(Exponent,ExponentMask) then begin
  if IEEEFormat.Explicit<>0 then begin
   // Remove explicit bit
   IntegerValueSetQWord(Temp,1);
   IntegerValueShiftLeftInternal(OtherTemp,Temp,IEEEFormat.Mantissa);
   IntegerValueNOT(SignificandMask,OtherTemp);
   IntegerValueAnd(Temp,Significand,SignificandMask);
   Significand:=Temp;
  end;
  if IntegerValueIsZero(Significand) then begin
   // Infinity
   result:=result+'Inf';
  end else begin
   if (Significand[(IEEEFormat.Mantissa-1) shr 5] and (1 shl ((IEEEFormat.Mantissa-1) and 31)))<>0 then begin
    // Quiet NaN
    result:=result+'QNaN';
   end else begin
    // Signalling NaN
    result:=result+'SNaN';
   end;
  end;
  exit;
 end else if IntegerValueIsZero(Exponent) then begin
  if IntegerValueIsZero(Significand) then begin
   // Zero
   result:=result+'0';
   exit;
  end else begin
   if IEEEFormat.Explicit<>0 then begin
    // Packed BCD
    result:=result+'0p';
    s:='';
    while not IntegerValueIsZero(Significand) do begin
     s:=ansichar(byte((Significand[0] and $f)+byte(ansichar('0'))))+s;
     IntegerValueUnsignedShiftRightInternal(Temp,Significand,4);
     Significand:=Temp;
    end;
    result:=result+s;
    exit;
   end else begin
    // Denormalized
    WorkExponent:=2-ExpMax;
    repeat
     IntegerValueUnsignedShiftRightInternal(Temp,Significand,IEEEFormat.Mantissa-Start);
     if (Temp[0] and 1)=0 then begin
      dec(WorkExponent);
      inc(Start);
     end else begin
      break;
     end;
    until false;
   end;
  end;
 end else begin
  if IEEEFormat.Explicit<>0 then begin
   if (Significand[IEEEFormat.Mantissa shr 5] and (1 shl (IEEEFormat.Mantissa and 31)))=0 then begin
    // Denormalized
    WorkExponent:=2-ExpMax;
    repeat
     IntegerValueUnsignedShiftRightInternal(Temp,Significand,IEEEFormat.Mantissa-Start);
     if (Temp[0] and 1)=0 then begin
      dec(WorkExponent);
      inc(Start);
     end else begin
      break;
     end;
    until false;
   end else begin
    WorkExponent:=IntegerValueGetInt64(Exponent)-(ExpMax-1);
   end;
  end else begin
   // Normalized
   IntegerValueSetQWord(Temp,1);
   IntegerValueShiftLeftInternal(OtherTemp,Temp,IEEEFormat.Mantissa);
   IntegerValueOR(Temp,Significand,OtherTemp);
   Significand:=Temp;
   WorkExponent:=IntegerValueGetInt64(Exponent)-(ExpMax-1);
  end;
 end;
 repeat
  IntegerValueUnsignedShiftRightInternal(Temp,Significand,IEEEFormat.Mantissa-End_);
  if (Temp[0] and 1)=0 then begin
   dec(End_);
  end else begin
   break;
  end;
 until false;
 result:=result+'0b';
 for i:=Start to End_ do begin
  if i=Start+1 then begin
   result:=result+'.';
  end;
  IntegerValueUnsignedShiftRightInternal(Temp,Significand,IEEEFormat.Mantissa-i);
  if (Temp[0] and 1)<>0 then begin
   result:=result+'1';
  end else begin
   result:=result+'0';
  end;
 end;
 if Start=End_ then begin
  result:=result+'.0';
 end;
 result:=result+'p'+IntToStr(WorkExponent);
end;

function StringSearch(const Where,What:ansistring;const FromHere:longint;const OnlyCompleteWords,CaseInsensitive:boolean):longint;
var Position,MaximalPosition,WhatComparePosition,WhereComparePosition,FoundLength,WhereLength,WhatLength:longint;
    FoundOkay:boolean;
    a,b:ansichar;
begin
 result:=0;
 Position:=FromHere;
 if Position<1 then begin
  Position:=1;
 end;
 WhatLength:=length(What);
 WhereLength:=length(Where);
 MaximalPosition:=WhereLength-WhatLength+1;
 while Position<=MaximalPosition do begin
  WhatComparePosition:=Position;
  WhereComparePosition:=1;
  FoundLength:=0;
  if CaseInsensitive then begin
   while (WhatComparePosition<=WhereLength) and
         (WhereComparePosition<=WhatLength) do begin
    a:=Where[WhatComparePosition];
    b:=What[WhereComparePosition];
    if a in ['A'..'Z'] then begin
     inc(a,byte(ansichar('a'))-byte(ansichar('A')));
    end;
    if b in ['A'..'Z'] then begin
     inc(b,byte(ansichar('a'))-byte(ansichar('A')));
    end;
    if a=b then begin
     inc(FoundLength);
     inc(WhatComparePosition);
     inc(WhereComparePosition);
    end else begin
     break;
    end;
   end;
  end else begin
   while (WhatComparePosition<=WhereLength) and
         (WhereComparePosition<=WhatLength) and
         (Where[WhatComparePosition]=What[WhereComparePosition]) do begin
    inc(FoundLength);
    inc(WhatComparePosition);
    inc(WhereComparePosition);
   end;
  end;
  if FoundLength=WhatLength then begin
   FoundOkay:=true;
   if OnlyCompleteWords then begin
    if Position>1 then begin
     FoundOkay:=not (Where[Position-1] in ['A'..'Z','a'..'z','0'..'9','_','@','$']);
    end;
    if (Position+FoundLength)<=WhereLength then begin
     FoundOkay:=FoundOkay and not (Where[Position+FoundLength] in ['A'..'Z','a'..'z','0'..'9','_','@','$']);
    end;
   end;
   if FoundOkay then begin
    result:=Position;
    exit;
   end;
  end;
  inc(Position);
 end;
end;

function StringReplace(const Where,SearchFor,ReplaceWith:ansistring;const OnlyCompleteWords,CaseInsensitive:boolean):ansistring;
var FoundPosition,LastPosition,SearchForLength,ReplaceWithLength:longint;
begin
 result:=Where;
 LastPosition:=1;
 SearchForLength:=length(SearchFor);
 ReplaceWithLength:=length(ReplaceWith);
 while LastPosition<=length(result) do begin
  FoundPosition:=StringSearch(result,SearchFor,LastPosition,OnlyCompleteWords,CaseInsensitive);
  if FoundPosition>0 then begin
   result:=Copy(result,1,FoundPosition-1)+
           ReplaceWith+
           Copy(result,FoundPosition+SearchForLength,(length(result)-(FoundPosition+SearchForLength))+1);
   LastPosition:=FoundPosition+ReplaceWithLength;
  end else begin
   break;
  end;
 end;
end;

function HashString(const Str:ansistring):longword;
{$ifdef cpuarm}
var b:PAnsiChar;
    len,h,i:longword;
begin
 result:=2166136261;
 len:=length(Str);
 h:=len;
 if len>0 then begin
  b:=PAnsiChar(Str);
  while len>3 do begin
   i:=longword(pointer(b)^);
   h:=(h xor i) xor $2e63823a;
   inc(h,(h shl 15) or (h shr (32-15)));
   dec(h,(h shl 9) or (h shr (32-9)));
   inc(h,(h shl 4) or (h shr (32-4)));
   dec(h,(h shl 1) or (h shr (32-1)));
   h:=h xor (h shl 2) or (h shr (32-2));
   result:=result xor i;
   inc(result,(result shl 1)+(result shl 4)+(result shl 7)+(result shl 8)+(result shl 24));
   inc(b,4);
   dec(len,4);
  end;
  if len>1 then begin
   i:=word(pointer(b)^);
   h:=(h xor i) xor $2e63823a;
   inc(h,(h shl 15) or (h shr (32-15)));
   dec(h,(h shl 9) or (h shr (32-9)));
   inc(h,(h shl 4) or (h shr (32-4)));
   dec(h,(h shl 1) or (h shr (32-1)));
   h:=h xor (h shl 2) or (h shr (32-2));
   result:=result xor i;
   inc(result,(result shl 1)+(result shl 4)+(result shl 7)+(result shl 8)+(result shl 24));
   inc(b,2);
   dec(len,2);
  end;
  if len>0 then begin
   i:=byte(b^);
   h:=(h xor i) xor $2e63823a;
   inc(h,(h shl 15) or (h shr (32-15)));
   dec(h,(h shl 9) or (h shr (32-9)));
   inc(h,(h shl 4) or (h shr (32-4)));
   dec(h,(h shl 1) or (h shr (32-1)));
   h:=h xor (h shl 2) or (h shr (32-2));
   result:=result xor i;
   inc(result,(result shl 1)+(result shl 4)+(result shl 7)+(result shl 8)+(result shl 24));
  end;
 end;
 result:=result xor h;
 if result=0 then begin
  result:=$ffffffff;
 end;
end;
{$else}
const m=longword($57559429);
      n=longword($5052acdb);
var b:PAnsiChar;
    h,k,len:longword;
    p:{$ifdef fpc}uint64{$else}int64{$endif};
begin
 len:=length(Str);
 h:=len;
 k:=h+n+1;
 if len>0 then begin
  b:=PAnsiChar(Str);
  while len>7 do begin
   begin
    p:=longword(pointer(b)^)*{$ifdef fpc}uint64{$else}int64{$endif}(n);
    h:=h xor longword(p and $ffffffff);
    k:=k xor longword(p shr 32);
    inc(b,4);
   end;
   begin
    p:=longword(pointer(b)^)*{$ifdef fpc}uint64{$else}int64{$endif}(m);
    k:=k xor longword(p and $ffffffff);
    h:=h xor longword(p shr 32);
    inc(b,4);
   end;
   dec(len,8);
  end;
  if len>3 then begin
   p:=longword(pointer(b)^)*{$ifdef fpc}uint64{$else}int64{$endif}(n);
   h:=h xor longword(p and $ffffffff);
   k:=k xor longword(p shr 32);
   inc(b,4);
   dec(len,4);
  end;
  if len>0 then begin
   if len>1 then begin
    p:=word(pointer(b)^);
    inc(b,2);
    dec(len,2);
   end else begin
    p:=0;
   end;
   if len>0 then begin
    p:=p or (byte(b^) shl 16);
   end;
   p:=p*{$ifdef fpc}uint64{$else}int64{$endif}(m);
   k:=k xor longword(p and $ffffffff);
   h:=h xor longword(p shr 32);
  end;
 end;
 begin
  p:=(h xor (k+n))*{$ifdef fpc}uint64{$else}int64{$endif}(n);
  h:=h xor longword(p and $ffffffff);
  k:=k xor longword(p shr 32);
 end;
 result:=k xor h;
 if result=0 then begin
  result:=$ffffffff;
 end;
end;
{$endif}

procedure TruncBits(var Value;Bits:longint);
type pbyte=^byte;
var p:pbyte;
    Counter,ByteBit:longint;
begin
 p:=@Value;
 ByteBit:=0;
 for Counter:=1 to Bits do begin
  p^:=p^ and not (1 shl (7-ByteBit));
  ByteBit:=(ByteBit+1) and 7;
  if ByteBit=0 then begin
   inc(p);
  end;
 end;
end;

function UTF32CharToUTF8(CharValue:longword):ansistring;
var Data:array[0..{$ifdef strictutf8}3{$else}5{$endif}] of ansichar;
    ResultLen:longint;
begin
 if CharValue=0 then begin
  result:=#0;
 end else begin
  if CharValue<=$7f then begin
   Data[0]:=ansichar(byte(CharValue));
   ResultLen:=1;
  end else if CharValue<=$7ff then begin
   Data[0]:=ansichar(byte($c0 or ((CharValue shr 6) and $1f)));
   Data[1]:=ansichar(byte($80 or (CharValue and $3f)));
   ResultLen:=2;
{$ifdef strictutf8}
  end else if CharValue<=$d7ff then begin
   Data[0]:=ansichar(byte($e0 or ((CharValue shr 12) and $0f)));
   Data[1]:=ansichar(byte($80 or ((CharValue shr 6) and $3f)));
   Data[2]:=ansichar(byte($80 or (CharValue and $3f)));
   ResultLen:=3;
  end else if CharValue<=$dfff then begin
   Data[0]:=#$ef; // $fffd
   Data[1]:=#$bf;
   Data[2]:=#$bd;
   ResultLen:=3;
{$endif}
  end else if CharValue<=$ffff then begin
   Data[0]:=ansichar(byte($e0 or ((CharValue shr 12) and $0f)));
   Data[1]:=ansichar(byte($80 or ((CharValue shr 6) and $3f)));
   Data[2]:=ansichar(byte($80 or (CharValue and $3f)));
   ResultLen:=3;
  end else if CharValue<=$1fffff then begin
   Data[0]:=ansichar(byte($f0 or ((CharValue shr 18) and $07)));
   Data[1]:=ansichar(byte($80 or ((CharValue shr 12) and $3f)));
   Data[2]:=ansichar(byte($80 or ((CharValue shr 6) and $3f)));
   Data[3]:=ansichar(byte($80 or (CharValue and $3f)));
   ResultLen:=4;
{$ifndef strictutf8}
  end else if CharValue<=$3ffffff then begin
   Data[0]:=ansichar(byte($f8 or ((CharValue shr 24) and $03)));
   Data[1]:=ansichar(byte($80 or ((CharValue shr 18) and $3f)));
   Data[2]:=ansichar(byte($80 or ((CharValue shr 12) and $3f)));
   Data[3]:=ansichar(byte($80 or ((CharValue shr 6) and $3f)));
   Data[4]:=ansichar(byte($80 or (CharValue and $3f)));
   ResultLen:=5;
  end else if CharValue<=$7fffffff then begin
   Data[0]:=ansichar(byte($fc or ((CharValue shr 30) and $01)));
   Data[1]:=ansichar(byte($80 or ((CharValue shr 24) and $3f)));
   Data[2]:=ansichar(byte($80 or ((CharValue shr 18) and $3f)));
   Data[3]:=ansichar(byte($80 or ((CharValue shr 12) and $3f)));
   Data[4]:=ansichar(byte($80 or ((CharValue shr 6) and $3f)));
   Data[5]:=ansichar(byte($80 or (CharValue and $3f)));
   ResultLen:=6;
{$endif}
  end else begin
   Data[0]:=#$ef; // $fffd
   Data[1]:=#$bf;
   Data[2]:=#$bd;
   ResultLen:=3;
  end;
  SetString(result,pansichar(@Data[0]),ResultLen);
 end;
end;

function StreamGetByte(const Stream:TStream;const Position:int64):byte;
var OldPosition:int64;
begin
 OldPosition:=Stream.Position;
 try
  if Stream.Seek(Position,soBeginning)=Position then begin
   if Stream.Read(result,SizeOf(byte))<>SizeOf(byte) then begin
    result:=0;
   end;
  end else begin
   result:=0;
  end;
 finally
  Stream.Seek(OldPosition,soBeginning);
 end;
end;

procedure StreamSetByte(const Stream:TStream;const Position:int64;const Value:byte);
var OldPosition:int64;
begin
 OldPosition:=Stream.Position;
 try
  if Stream.Seek(Position,soBeginning)=Position then begin
   Stream.Write(Value,SizeOf(byte));
  end;
 finally
  Stream.Seek(OldPosition,soBeginning);
 end;
end;

function StreamGetWord(const Stream:TStream;const Position:int64):word;
var OldPosition:int64;
begin
 OldPosition:=Stream.Position;
 try
  if Stream.Seek(Position,soBeginning)=Position then begin
   if Stream.Read(result,SizeOf(word))<>SizeOf(word) then begin
    result:=0;
   end;
  end else begin
   result:=0;
  end;
 finally
  Stream.Seek(OldPosition,soBeginning);
 end;
end;

procedure StreamSetWord(const Stream:TStream;const Position:int64;const Value:word);
var OldPosition:int64;
begin
 OldPosition:=Stream.Position;
 try
  if Stream.Seek(Position,soBeginning)=Position then begin
   Stream.Write(Value,SizeOf(word));
  end;
 finally
  Stream.Seek(OldPosition,soBeginning);
 end;
end;

function StreamGetDWord(const Stream:TStream;const Position:int64):longword;
var OldPosition:int64;
begin
 OldPosition:=Stream.Position;
 try
  if Stream.Seek(Position,soBeginning)=Position then begin
   if Stream.Read(result,SizeOf(longword))<>SizeOf(longword) then begin
    result:=0;
   end;
  end else begin
   result:=0;
  end;
 finally
  Stream.Seek(OldPosition,soBeginning);
 end;
end;

procedure StreamSetDWord(const Stream:TStream;const Position:int64;const Value:longword);
var OldPosition:int64;
begin
 OldPosition:=Stream.Position;
 try
  if Stream.Seek(Position,soBeginning)=Position then begin
   Stream.Write(Value,SizeOf(longword));
  end;
 finally
  Stream.Seek(OldPosition,soBeginning);
 end;
end;

function StreamReadByte(const Stream:TStream):byte;
begin
 if Stream.Read(result,SizeOf(byte))<>SizeOf(byte) then begin
  result:=0;
 end;
end;

function StreamReadWord(const Stream:TStream):word;
begin
 result:=StreamReadByte(Stream) or (StreamReadByte(Stream) shl 8);
end;

function StreamReadDWord(const Stream:TStream):longword;
begin
 result:=StreamReadWord(Stream) or (StreamReadWord(Stream) shl 16);
end;

function StreamReadQWord(const Stream:TStream):uint64;
begin
 result:=StreamReadDWord(Stream) or (StreamReadDWord(Stream) shl 32);
end;

function StreamReadLine(const Stream:TStream):ansistring;
var c:ansichar;
begin
 result:='';
 while Stream.Position<Stream.Size do begin
  Stream.Read(c,SizeOf(ansichar));
  if c=#10 then begin
   break;
  end else if c<>#13 then begin
   result:=result+c;
  end;
 end;
end;

function StreamReadString(const Stream:TStream):ansistring;
var l:longword;
begin
 l:=StreamReadDWord(Stream);
 SetLength(result,l);
 Stream.Read(result[1],l*SizeOf(ansichar));
end;

function StreamReadWideString(const Stream:TStream):widestring;
var l:longword;
begin
 l:=StreamReadDWord(Stream);
 SetLength(result,l);
 Stream.Read(result[1],l*SizeOf(widechar));
end;

procedure StreamWriteByteCount(const Stream:TStream;const Value:byte;const Count:longint);
var Counter:longint;
begin
 for Counter:=1 to Count do begin
  Stream.Write(Value,SizeOf(byte));
 end;
end;

procedure StreamWriteByte(const Stream:TStream;const Value:byte);
begin
 Stream.Write(Value,SizeOf(byte));
end;

procedure StreamWriteIntegerValue(const Stream:TStream;const IntegerValue:TIntegerValue;const Bytes:longint);
var i:longint;
begin
 for i:=0 to Bytes-1 do begin
  StreamWriteByte(Stream,(IntegerValue[i shr 2] shr ((i and 3) shl 3)) and $ff);
 end;
end;

procedure StreamWriteWord(const Stream:TStream;const Value:word);
begin
 StreamWriteByte(Stream,Value and $ff);
 StreamWriteByte(Stream,(Value shr 8) and $ff);
end;

procedure StreamWriteBigEndianWord(const Stream:TStream;const Value:word);
begin
 StreamWriteByte(Stream,(Value shr 8) and $ff);
 StreamWriteByte(Stream,Value and $ff);
end;

procedure StreamWriteDWord(const Stream:TStream;const Value:longword);
begin
 StreamWriteByte(Stream,Value and $ff);
 StreamWriteByte(Stream,(Value shr 8) and $ff);
 StreamWriteByte(Stream,(Value shr 16) and $ff);
 StreamWriteByte(Stream,(Value shr 24) and $ff);
end;

procedure StreamWriteShortInt(const Stream:TStream;const Value:shortint);
begin
 Stream.Write(Value,SizeOf(shortint));
end;

procedure StreamWriteSmallInt(const Stream:TStream;const Value:smallint);
begin
 StreamWriteByte(Stream,Value and $ff);
 StreamWriteByte(Stream,(Value shr 8) and $ff);
end;

procedure StreamWriteLongInt(const Stream:TStream;const Value:longint);
begin
 StreamWriteByte(Stream,Value and $ff);
 StreamWriteByte(Stream,(Value shr 8) and $ff);
 StreamWriteByte(Stream,(Value shr 16) and $ff);
 StreamWriteByte(Stream,(Value shr 24) and $ff);
end;

procedure StreamWriteInt64(const Stream:TStream;const Value:int64);
begin
 StreamWriteByte(Stream,Value and $ff);
 StreamWriteByte(Stream,(Value shr 8) and $ff);
 StreamWriteByte(Stream,(Value shr 16) and $ff);
 StreamWriteByte(Stream,(Value shr 24) and $ff);
 StreamWriteByte(Stream,(Value shr 32) and $ff);
 StreamWriteByte(Stream,(Value shr 40) and $ff);
 StreamWriteByte(Stream,(Value shr 48) and $ff);
 StreamWriteByte(Stream,(Value shr 56) and $ff);
end;

procedure StreamWriteQWord(const Stream:TStream;const Value:uint64);
begin
 StreamWriteByte(Stream,Value and $ff);
 StreamWriteByte(Stream,(Value shr 8) and $ff);
 StreamWriteByte(Stream,(Value shr 16) and $ff);
 StreamWriteByte(Stream,(Value shr 24) and $ff);
 StreamWriteByte(Stream,(Value shr 32) and $ff);
 StreamWriteByte(Stream,(Value shr 40) and $ff);
 StreamWriteByte(Stream,(Value shr 48) and $ff);
 StreamWriteByte(Stream,(Value shr 56) and $ff);
end;

procedure StreamWriteBoolean(const Stream:TStream;const Value:boolean);
begin
 if Value then begin
  StreamWriteByte(Stream,1);
 end else begin
  StreamWriteByte(Stream,0);
 end;
end;

procedure StreamWriteLine(const Stream:TStream;const Line:ansistring);
begin
 if length(Line)>0 then begin
  Stream.Write(Line[1],length(Line));
 end;
 StreamWriteByte(Stream,13);
 StreamWriteByte(Stream,10);
end;

procedure StreamWriteString(const Stream:TStream;const s:ansistring);
var l:longword;
begin
 l:=length(s);
 if l>0 then begin
  Stream.Write(s[1],l*sizeof(ansichar));
 end;
end;

procedure StreamWriteDataString(const Stream:TStream;const s:ansistring);
var l:longword;
begin
 l:=length(s);
 StreamWriteDWord(Stream,l);
 if l>0 then begin
  Stream.Write(s[1],l*sizeof(ansichar));
 end;
end;

procedure StreamWriteDataWideString(const Stream:TStream;const s:widestring);
var l:longword;
begin
 l:=length(s);
 StreamWriteDWord(Stream,l);
 if l>0 then begin
  Stream.Write(s[1],l*sizeof(widechar));
 end;
end;

function ValueGetInt64(const AssemblerInstance:TAssembler;const Value:TAssemblerValue;const DoError:boolean):int64;
var Counter:longint;
begin
 case Value.ValueType of
  AVT_INT:begin
   result:=IntegerValueGetInt64(Value.IntegerValue);
  end;
  AVT_FLOAT:begin
   case Value.FloatValue.Count of
    1:begin
     result:=byte(pointer(@Value.FloatValue.Bytes[0])^);
    end;
    2:begin
     result:=word(pointer(@Value.FloatValue.Bytes[0])^);
    end;
    else begin
     result:=int64(pointer(@Value.FloatValue.Bytes[0])^);
    end;
   end;
  end;
  AVT_STRING:begin
   result:=0;
   Counter:=length(Value.StringValue);
   while Counter>0 do begin
    result:=(result shl 8) or byte(ansichar(Value.StringValue[(length(Value.StringValue)-Counter)+1]));
    dec(Counter);
   end;
  end;
  else begin
   if DoError then begin
    AssemblerInstance.MakeError(19);
   end;
   result:=0;
  end;
 end;
end;

function ValueToRawInt(const AssemblerInstance:TAssembler;const Value:TAssemblerValue;const DoError:boolean):TIntegerValue;
var Counter:longint;
    a,b:TIntegerValue;
begin
 case Value.ValueType of
  AVT_INT:begin
   result:=Value.IntegerValue;
  end;
  AVT_FLOAT:begin
   FillChar(result,SizeOf(TIntegerValue),#0);
   Move(Value.FloatValue.Bytes[0],result[0],Value.FloatValue.Count);
  end;
  AVT_STRING:begin
   FillChar(result,SizeOf(TIntegerValue),#0);
   Counter:=length(Value.StringValue);
   while Counter>0 do begin
    IntegerValueShiftLeftInternal(a,result,8);
    IntegerValueSetQWord(b,byte(ansichar(Value.StringValue[(length(Value.StringValue)-Counter)+1])));
    IntegerValueOr(result,a,b);
    dec(Counter);
   end;
  end;
  else begin
   FillChar(result,SizeOf(TIntegerValue),#0);
  end;
 end;
end;

function ValueToString(const AssemblerInstance:TAssembler;const Value:TAssemblerValue;const DoError:boolean):ansistring;
{var Counter:longint;
    a,b:TIntegerValue;}
begin
 case Value.ValueType of
  AVT_INT:begin
   result:=IntegerValueToStr(Value.IntegerValue);
  end;
  AVT_FLOAT:begin
   result:='';
{  FillChar(result,SizeOf(TIntegerValue),#0);
   Move(Value.FloatValue.Bytes[0],result[0],Value.FloatValue.Count);}
  end;
  AVT_STRING:begin
   result:=Value.StringValue;
  end;
  else begin
   result:='';
  end;
 end;
end;

function ValueOpAdd(const AssemblerInstance:TAssembler;const LeftValue,RightValue:TAssemblerValue;const DoError:boolean):TAssemblerValue;
var s:ansistring;
begin
 result.ValueType:=AVT_NONE;
 case LeftValue.ValueType of
  AVT_INT:begin
   case RightValue.ValueType of
    AVT_INT:begin
     result.ValueType:=AVT_INT;
     IntegerValueAdd(result.IntegerValue,LeftValue.IntegerValue,RightValue.IntegerValue);
    end;
    AVT_FLOAT:begin
     case RightValue.FloatValue.Count of
{$ifdef HAS_TYPE_SINGLE}
      SizeOf(single):begin
       result.ValueType:=AVT_FLOAT;
       single(pointer(@result.FloatValue.Bytes[0])^):=IntegerValueGetInt64(LeftValue.IntegerValue)+single(pointer(@RightValue.FloatValue.Bytes[0])^);
       result.FloatValue.Count:=SizeOf(single);
      end;
{$endif}
{$ifdef HAS_TYPE_DOUBLE}
      SizeOf(double):begin
       result.ValueType:=AVT_FLOAT;
       double(pointer(@result.FloatValue.Bytes[0])^):=IntegerValueGetInt64(LeftValue.IntegerValue)+double(pointer(@RightValue.FloatValue.Bytes[0])^);
       result.FloatValue.Count:=SizeOf(double);
      end;
{$endif}
{$ifdef HAS_TYPE_EXTENDED}
      SizeOf(extended):begin
       result.ValueType:=AVT_FLOAT;
       extended(pointer(@result.FloatValue.Bytes[0])^):=IntegerValueGetInt64(LeftValue.IntegerValue)+extended(pointer(@RightValue.FloatValue.Bytes[0])^);
       result.FloatValue.Count:=SizeOf(extended);
      end;
{$endif}
      else begin
       if DoError then begin
        AssemblerInstance.MakeError(19);
       end;
      end;
     end;
    end;
    AVT_STRING:begin
     result.ValueType:=AVT_STRING;
     result.StringValue:=IntegerValueToStr(LeftValue.IntegerValue)+RightValue.StringValue;
    end;
    else begin
     if DoError then begin
      AssemblerInstance.MakeError(19);
     end;
    end;
   end;
  end;
  AVT_FLOAT:begin
   case RightValue.ValueType of
    AVT_INT:begin
     case LeftValue.FloatValue.Count of
{$ifdef HAS_TYPE_SINGLE}
      SizeOf(single):begin
       result.ValueType:=AVT_FLOAT;
       single(pointer(@result.FloatValue.Bytes[0])^):=single(pointer(@LeftValue.FloatValue.Bytes[0])^)+IntegerValueGetInt64(RightValue.IntegerValue);
       result.FloatValue.Count:=SizeOf(single);
      end;
{$endif}
{$ifdef HAS_TYPE_DOUBLE}
      SizeOf(double):begin
       result.ValueType:=AVT_FLOAT;
       double(pointer(@result.FloatValue.Bytes[0])^):=double(pointer(@LeftValue.FloatValue.Bytes[0])^)+IntegerValueGetInt64(RightValue.IntegerValue);
       result.FloatValue.Count:=SizeOf(double);
      end;
{$endif}
{$ifdef HAS_TYPE_EXTENDED}
      SizeOf(extended):begin
       result.ValueType:=AVT_FLOAT;
       extended(pointer(@result.FloatValue.Bytes[0])^):=extended(pointer(@LeftValue.FloatValue.Bytes[0])^)+IntegerValueGetInt64(RightValue.IntegerValue);
       result.FloatValue.Count:=SizeOf(extended);
      end;
{$endif}
      else begin
       if DoError then begin
        AssemblerInstance.MakeError(19);
       end;
      end;
     end;
     result.ValueType:=AVT_INT;
     IntegerValueAdd(result.IntegerValue,LeftValue.IntegerValue,RightValue.IntegerValue);
    end;
    AVT_FLOAT:begin
     case LeftValue.FloatValue.Count of
{$ifdef HAS_TYPE_SINGLE}
      SizeOf(single):begin
       case RightValue.FloatValue.Count of
{$ifdef HAS_TYPE_SINGLE}
        SizeOf(single):begin
         result.ValueType:=AVT_FLOAT;
         single(pointer(@result.FloatValue.Bytes[0])^):=single(pointer(@LeftValue.FloatValue.Bytes[0])^)+single(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(single);
        end;
{$endif}
{$ifdef HAS_TYPE_DOUBLE}
        SizeOf(double):begin
         result.ValueType:=AVT_FLOAT;
         double(pointer(@result.FloatValue.Bytes[0])^):=single(pointer(@LeftValue.FloatValue.Bytes[0])^)+double(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(double);
        end;
{$endif}
{$ifdef HAS_TYPE_EXTENDED}
        SizeOf(extended):begin
         result.ValueType:=AVT_FLOAT;
         extended(pointer(@result.FloatValue.Bytes[0])^):=single(pointer(@LeftValue.FloatValue.Bytes[0])^)+extended(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(extended);
        end;
{$endif}
        else begin
         if DoError then begin
          AssemblerInstance.MakeError(19);
         end;
        end;
       end;
      end;
{$endif}
{$ifdef HAS_TYPE_DOUBLE}
      SizeOf(double):begin
       case RightValue.FloatValue.Count of
{$ifdef HAS_TYPE_SINGLE}
        SizeOf(single):begin
         result.ValueType:=AVT_FLOAT;
         double(pointer(@result.FloatValue.Bytes[0])^):=double(pointer(@LeftValue.FloatValue.Bytes[0])^)+single(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(double);
        end;
{$endif}
{$ifdef HAS_TYPE_DOUBLE}
        SizeOf(double):begin
         result.ValueType:=AVT_FLOAT;
         double(pointer(@result.FloatValue.Bytes[0])^):=double(pointer(@LeftValue.FloatValue.Bytes[0])^)+double(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(double);
        end;
{$endif}
{$ifdef HAS_TYPE_EXTENDED}
        SizeOf(extended):begin
         result.ValueType:=AVT_FLOAT;
         extended(pointer(@result.FloatValue.Bytes[0])^):=double(pointer(@LeftValue.FloatValue.Bytes[0])^)+extended(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(extended);
        end;
{$endif}
        else begin
         if DoError then begin
          AssemblerInstance.MakeError(19);
         end;
        end;
       end;
      end;
{$endif}
{$ifdef HAS_TYPE_EXTENDED}
      SizeOf(extended):begin
       case RightValue.FloatValue.Count of
{$ifdef HAS_TYPE_SINGLE}
        SizeOf(single):begin
         result.ValueType:=AVT_FLOAT;
         extended(pointer(@result.FloatValue.Bytes[0])^):=extended(pointer(@LeftValue.FloatValue.Bytes[0])^)+single(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(extended);
        end;
{$endif}
{$ifdef HAS_TYPE_DOUBLE}
        SizeOf(double):begin
         result.ValueType:=AVT_FLOAT;
         extended(pointer(@result.FloatValue.Bytes[0])^):=extended(pointer(@LeftValue.FloatValue.Bytes[0])^)+double(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(extended);
        end;
{$endif}
{$ifdef HAS_TYPE_EXTENDED}
        SizeOf(extended):begin
         result.ValueType:=AVT_FLOAT;
         extended(pointer(@result.FloatValue.Bytes[0])^):=extended(pointer(@LeftValue.FloatValue.Bytes[0])^)+extended(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(extended);
        end;
{$endif}
        else begin
         if DoError then begin
          AssemblerInstance.MakeError(19);
         end;
        end;
       end;
      end;
{$endif}
      else begin
       if DoError then begin
        AssemblerInstance.MakeError(19);
       end;
      end;
     end;
    end;
    AVT_STRING:begin
     case LeftValue.FloatValue.Count of
{$ifdef HAS_TYPE_SINGLE}
      SizeOf(single):begin
       Str(single(pointer(@LeftValue.FloatValue.Bytes[0])^),s);
       result.ValueType:=AVT_STRING;
       result.StringValue:=s+RightValue.StringValue;
      end;
{$endif}
{$ifdef HAS_TYPE_DOUBLE}
      SizeOf(double):begin
       Str(double(pointer(@LeftValue.FloatValue.Bytes[0])^),s);
       result.ValueType:=AVT_STRING;
       result.StringValue:=s+RightValue.StringValue;
      end;
{$endif}
{$ifdef HAS_TYPE_EXTENDED}
      SizeOf(extended):begin
       Str(extended(pointer(@LeftValue.FloatValue.Bytes[0])^),s);
       result.ValueType:=AVT_STRING;
       result.StringValue:=s+RightValue.StringValue;
      end;
{$endif}
      else begin
       if DoError then begin
        AssemblerInstance.MakeError(19);
       end;
      end;
     end;
    end;
    else begin
     if DoError then begin
      AssemblerInstance.MakeError(19);
     end;
    end;
   end;
  end;
  AVT_STRING:Begin
   case RightValue.ValueType of
    AVT_INT:begin
     result.ValueType:=AVT_STRING;
     result.StringValue:=LeftValue.StringValue+IntegerValueToStr(RightValue.IntegerValue);
    end;
    AVT_FLOAT:begin
     case LeftValue.FloatValue.Count of
{$ifdef HAS_TYPE_SINGLE}
      SizeOf(single):begin
       Str(single(pointer(@RightValue.FloatValue.Bytes[0])^),s);
       result.ValueType:=AVT_STRING;
       result.StringValue:=LeftValue.StringValue+s;
      end;
{$endif}
{$ifdef HAS_TYPE_DOUBLE}
      SizeOf(double):begin
       Str(double(pointer(@RightValue.FloatValue.Bytes[0])^),s);
       result.ValueType:=AVT_STRING;
       result.StringValue:=LeftValue.StringValue+s;
      end;
{$endif}
{$ifdef HAS_TYPE_EXTENDED}
      SizeOf(extended):begin
       Str(extended(pointer(@RightValue.FloatValue.Bytes[0])^),s);
       result.ValueType:=AVT_STRING;
       result.StringValue:=LeftValue.StringValue+s;
      end;
{$endif}
      else begin
       if DoError then begin
        AssemblerInstance.MakeError(19);
       end;
      end;
     end;
    end;
    AVT_STRING:begin
     result.ValueType:=AVT_STRING;
     result.StringValue:=LeftValue.StringValue+RightValue.StringValue;
    end;
    else begin
     if DoError then begin
      AssemblerInstance.MakeError(19);
     end;
    end;
   end;
  end;
  else begin
   if DoError then begin
    AssemblerInstance.MakeError(19);
   end;
  end;
 end;
 if result.ValueType=AVT_NONE then begin
  result.ValueType:=AVT_INT;
  IntegerValueSetQWord(result.IntegerValue,0);
 end;
end;

function ValueOpSub(const AssemblerInstance:TAssembler;const LeftValue,RightValue:TAssemblerValue;const DoError:boolean):TAssemblerValue;
//var s:ansistring;
begin
 result.ValueType:=AVT_NONE;
 case LeftValue.ValueType of
  AVT_INT:begin
   case RightValue.ValueType of
    AVT_INT:begin
     result.ValueType:=AVT_INT;
     IntegerValueSub(result.IntegerValue,LeftValue.IntegerValue,RightValue.IntegerValue);
    end;
    AVT_FLOAT:begin
     case RightValue.FloatValue.Count of
{$ifdef HAS_TYPE_SINGLE}
      SizeOf(single):begin
       result.ValueType:=AVT_FLOAT;
       single(pointer(@result.FloatValue.Bytes[0])^):=IntegerValueGetInt64(LeftValue.IntegerValue)-single(pointer(@RightValue.FloatValue.Bytes[0])^);
       result.FloatValue.Count:=SizeOf(single);
      end;
{$endif}
{$ifdef HAS_TYPE_DOUBLE}
      SizeOf(double):begin
       result.ValueType:=AVT_FLOAT;
       double(pointer(@result.FloatValue.Bytes[0])^):=IntegerValueGetInt64(LeftValue.IntegerValue)-double(pointer(@RightValue.FloatValue.Bytes[0])^);
       result.FloatValue.Count:=SizeOf(double);
      end;
{$endif}
{$ifdef HAS_TYPE_EXTENDED}
      SizeOf(extended):begin
       result.ValueType:=AVT_FLOAT;
       extended(pointer(@result.FloatValue.Bytes[0])^):=IntegerValueGetInt64(LeftValue.IntegerValue)-extended(pointer(@RightValue.FloatValue.Bytes[0])^);
       result.FloatValue.Count:=SizeOf(extended);
      end;
{$endif}
      else begin
       if DoError then begin
        AssemblerInstance.MakeError(19);
       end;
      end;
     end;
    end;
    else begin
     if DoError then begin
      AssemblerInstance.MakeError(19);
     end;
    end;
   end;
  end;
  AVT_FLOAT:begin
   case RightValue.ValueType of
    AVT_INT:begin
     case LeftValue.FloatValue.Count of
{$ifdef HAS_TYPE_SINGLE}
      SizeOf(single):begin
       result.ValueType:=AVT_FLOAT;
       single(pointer(@result.FloatValue.Bytes[0])^):=single(pointer(@LeftValue.FloatValue.Bytes[0])^)-IntegerValueGetInt64(RightValue.IntegerValue);
       result.FloatValue.Count:=SizeOf(single);
      end;
{$endif}
{$ifdef HAS_TYPE_DOUBLE}
      SizeOf(double):begin
       result.ValueType:=AVT_FLOAT;
       double(pointer(@result.FloatValue.Bytes[0])^):=double(pointer(@LeftValue.FloatValue.Bytes[0])^)-IntegerValueGetInt64(RightValue.IntegerValue);
       result.FloatValue.Count:=SizeOf(double);
      end;
{$endif}
{$ifdef HAS_TYPE_EXTENDED}
      SizeOf(extended):begin
       result.ValueType:=AVT_FLOAT;
       extended(pointer(@result.FloatValue.Bytes[0])^):=extended(pointer(@LeftValue.FloatValue.Bytes[0])^)-IntegerValueGetInt64(RightValue.IntegerValue);
       result.FloatValue.Count:=SizeOf(extended);
      end;
{$endif}
      else begin
       if DoError then begin
        AssemblerInstance.MakeError(19);
       end;
      end;
     end;
     result.ValueType:=AVT_INT;
     IntegerValueAdd(result.IntegerValue,LeftValue.IntegerValue,RightValue.IntegerValue);
    end;
    AVT_FLOAT:begin
     case LeftValue.FloatValue.Count of
{$ifdef HAS_TYPE_SINGLE}
      SizeOf(single):begin
       case RightValue.FloatValue.Count of
{$ifdef HAS_TYPE_SINGLE}
        SizeOf(single):begin
         result.ValueType:=AVT_FLOAT;
         single(pointer(@result.FloatValue.Bytes[0])^):=single(pointer(@LeftValue.FloatValue.Bytes[0])^)-single(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(single);
        end;
{$endif}
{$ifdef HAS_TYPE_DOUBLE}
        SizeOf(double):begin
         result.ValueType:=AVT_FLOAT;
         double(pointer(@result.FloatValue.Bytes[0])^):=single(pointer(@LeftValue.FloatValue.Bytes[0])^)-double(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(double);
        end;
{$endif}
{$ifdef HAS_TYPE_EXTENDED}
        SizeOf(extended):begin
         result.ValueType:=AVT_FLOAT;
         extended(pointer(@result.FloatValue.Bytes[0])^):=single(pointer(@LeftValue.FloatValue.Bytes[0])^)-extended(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(extended);
        end;
{$endif}
        else begin
         if DoError then begin
          AssemblerInstance.MakeError(19);
         end;
        end;
       end;
      end;
{$endif}
{$ifdef HAS_TYPE_DOUBLE}
      SizeOf(double):begin
       case RightValue.FloatValue.Count of
{$ifdef HAS_TYPE_SINGLE}
        SizeOf(single):begin
         result.ValueType:=AVT_FLOAT;
         double(pointer(@result.FloatValue.Bytes[0])^):=double(pointer(@LeftValue.FloatValue.Bytes[0])^)-single(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(double);
        end;
{$endif}
{$ifdef HAS_TYPE_DOUBLE}
        SizeOf(double):begin
         result.ValueType:=AVT_FLOAT;
         double(pointer(@result.FloatValue.Bytes[0])^):=double(pointer(@LeftValue.FloatValue.Bytes[0])^)-double(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(double);
        end;
{$endif}
{$ifdef HAS_TYPE_EXTENDED}
        SizeOf(extended):begin
         result.ValueType:=AVT_FLOAT;
         extended(pointer(@result.FloatValue.Bytes[0])^):=double(pointer(@LeftValue.FloatValue.Bytes[0])^)-extended(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(extended);
        end;
{$endif}
        else begin
         if DoError then begin
          AssemblerInstance.MakeError(19);
         end;
        end;
       end;
      end;
{$endif}
{$ifdef HAS_TYPE_EXTENDED}
      SizeOf(extended):begin
       case RightValue.FloatValue.Count of
{$ifdef HAS_TYPE_SINGLE}
        SizeOf(single):begin
         result.ValueType:=AVT_FLOAT;
         extended(pointer(@result.FloatValue.Bytes[0])^):=extended(pointer(@LeftValue.FloatValue.Bytes[0])^)-single(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(extended);
        end;
{$endif}
{$ifdef HAS_TYPE_DOUBLE}
        SizeOf(double):begin
         result.ValueType:=AVT_FLOAT;
         extended(pointer(@result.FloatValue.Bytes[0])^):=extended(pointer(@LeftValue.FloatValue.Bytes[0])^)-double(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(extended);
        end;
{$endif}
{$ifdef HAS_TYPE_EXTENDED}
        SizeOf(extended):begin
         result.ValueType:=AVT_FLOAT;
         extended(pointer(@result.FloatValue.Bytes[0])^):=extended(pointer(@LeftValue.FloatValue.Bytes[0])^)-extended(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(extended);
        end;
{$endif}
        else begin
         if DoError then begin
          AssemblerInstance.MakeError(19);
         end;
        end;
       end;
      end;
{$endif}
      else begin
       if DoError then begin
        AssemblerInstance.MakeError(19);
       end;
      end;
     end;
    end;
    else begin
     if DoError then begin
      AssemblerInstance.MakeError(19);
     end;
    end;
   end;
  end;
  else begin
   if DoError then begin
    AssemblerInstance.MakeError(19);
   end;
  end;
 end;
 if result.ValueType=AVT_NONE then begin
  result.ValueType:=AVT_INT;
  IntegerValueSetQWord(result.IntegerValue,0);
 end;
end;

function ValueOpNeg(const AssemblerInstance:TAssembler;const Value:TAssemblerValue;const DoError:boolean):TAssemblerValue;
begin
 result.ValueType:=AVT_NONE;
 case Value.ValueType of
  AVT_INT:begin
   result.ValueType:=AVT_INT;
   IntegerValueNeg(result.IntegerValue,Value.IntegerValue);
  end;
  AVT_FLOAT:begin
   case Value.FloatValue.Count of
    1:begin
     result.ValueType:=AVT_FLOAT;
     byte(pointer(@result.FloatValue.Bytes[0])^):=byte(pointer(@Value.FloatValue.Bytes[0])^) xor word($80);
     result.FloatValue.Count:=1;
    end;
    2:begin
     result.ValueType:=AVT_FLOAT;
     word(pointer(@result.FloatValue.Bytes[0])^):=word(pointer(@Value.FloatValue.Bytes[0])^) xor word($8000);
     result.FloatValue.Count:=2;
    end;
    4:begin
     result.ValueType:=AVT_FLOAT;
     longword(pointer(@result.FloatValue.Bytes[0])^):=longword(pointer(@Value.FloatValue.Bytes[0])^) xor longword($80000000);
     result.FloatValue.Count:=4;
    end;
    8:begin
     result.ValueType:=AVT_FLOAT;
     longword(pointer(@result.FloatValue.Bytes[0])^):=longword(pointer(@Value.FloatValue.Bytes[0])^);
     longword(pointer(@result.FloatValue.Bytes[1])^):=longword(pointer(@Value.FloatValue.Bytes[1])^) xor longword($80000000);
     result.FloatValue.Count:=8;
    end;
    10:begin
     result.ValueType:=AVT_FLOAT;
     longword(pointer(@result.FloatValue.Bytes[0])^):=longword(pointer(@Value.FloatValue.Bytes[0])^);
     longword(pointer(@result.FloatValue.Bytes[1])^):=longword(pointer(@Value.FloatValue.Bytes[1])^);
     word(pointer(@result.FloatValue.Bytes[2])^):=word(pointer(@Value.FloatValue.Bytes[2])^) xor word($8000);
     result.FloatValue.Count:=10;
    end;
    16:begin
     result.ValueType:=AVT_FLOAT;
     longword(pointer(@result.FloatValue.Bytes[0])^):=longword(pointer(@Value.FloatValue.Bytes[0])^);
     longword(pointer(@result.FloatValue.Bytes[1])^):=longword(pointer(@Value.FloatValue.Bytes[1])^);
     longword(pointer(@result.FloatValue.Bytes[2])^):=longword(pointer(@Value.FloatValue.Bytes[2])^);
     longword(pointer(@result.FloatValue.Bytes[3])^):=longword(pointer(@Value.FloatValue.Bytes[3])^) xor longword($80000000);
     result.FloatValue.Count:=16;
    end;
    else begin
     if DoError then begin
      AssemblerInstance.MakeError(19);
     end;
    end;
   end;
  end;
  else begin
   if DoError then begin
    AssemblerInstance.MakeError(19);
   end;
  end;
 end;
 if result.ValueType=AVT_NONE then begin
  result.ValueType:=AVT_INT;
  IntegerValueSetQWord(result.IntegerValue,0);
 end;
end;

function ValueOpNOT(const AssemblerInstance:TAssembler;const Value:TAssemblerValue;const DoError:boolean):TAssemblerValue;
begin
 case Value.ValueType of
  AVT_INT:begin
   result.ValueType:=AVT_INT;
   IntegerValueNOT(result.IntegerValue,Value.IntegerValue);
  end;
  else begin
   result.ValueType:=AVT_NONE;
   if DoError then begin
    AssemblerInstance.MakeError(19);
   end;
  end;
 end;
 if result.ValueType=AVT_NONE then begin
  result.ValueType:=AVT_INT;
  IntegerValueSetQWord(result.IntegerValue,0);
 end;
end;

function ValueOpMul(const AssemblerInstance:TAssembler;const LeftValue,RightValue:TAssemblerValue;const DoError:boolean):TAssemblerValue;
//var s:ansistring;
begin
 result.ValueType:=AVT_NONE;
 case LeftValue.ValueType of
  AVT_INT:begin
   case RightValue.ValueType of
    AVT_INT:begin
     result.ValueType:=AVT_INT;
     IntegerValueMul(result.IntegerValue,LeftValue.IntegerValue,RightValue.IntegerValue);
    end;
    AVT_FLOAT:begin
     case RightValue.FloatValue.Count of
{$ifdef HAS_TYPE_SINGLE}
      SizeOf(single):begin
       result.ValueType:=AVT_FLOAT;
       single(pointer(@result.FloatValue.Bytes[0])^):=IntegerValueGetInt64(LeftValue.IntegerValue)*single(pointer(@RightValue.FloatValue.Bytes[0])^);
       result.FloatValue.Count:=SizeOf(single);
      end;
{$endif}
{$ifdef HAS_TYPE_DOUBLE}
      SizeOf(double):begin
       result.ValueType:=AVT_FLOAT;
       double(pointer(@result.FloatValue.Bytes[0])^):=IntegerValueGetInt64(LeftValue.IntegerValue)*double(pointer(@RightValue.FloatValue.Bytes[0])^);
       result.FloatValue.Count:=SizeOf(double);
      end;
{$endif}
{$ifdef HAS_TYPE_EXTENDED}
      SizeOf(extended):begin
       result.ValueType:=AVT_FLOAT;
       extended(pointer(@result.FloatValue.Bytes[0])^):=IntegerValueGetInt64(LeftValue.IntegerValue)*extended(pointer(@RightValue.FloatValue.Bytes[0])^);
       result.FloatValue.Count:=SizeOf(extended);
      end;
{$endif}
      else begin
       if DoError then begin
        AssemblerInstance.MakeError(19);
       end;
      end;
     end;
    end;
    else begin
     if DoError then begin
      AssemblerInstance.MakeError(19);
     end;
    end;
   end;
  end;
  AVT_FLOAT:begin
   case RightValue.ValueType of
    AVT_INT:begin
     case LeftValue.FloatValue.Count of
{$ifdef HAS_TYPE_SINGLE}
      SizeOf(single):begin
       result.ValueType:=AVT_FLOAT;
       single(pointer(@result.FloatValue.Bytes[0])^):=single(pointer(@LeftValue.FloatValue.Bytes[0])^)*IntegerValueGetInt64(RightValue.IntegerValue);
       result.FloatValue.Count:=SizeOf(single);
      end;
{$endif}
{$ifdef HAS_TYPE_DOUBLE}
      SizeOf(double):begin
       result.ValueType:=AVT_FLOAT;
       double(pointer(@result.FloatValue.Bytes[0])^):=double(pointer(@LeftValue.FloatValue.Bytes[0])^)*IntegerValueGetInt64(RightValue.IntegerValue);
       result.FloatValue.Count:=SizeOf(double);
      end;
{$endif}
{$ifdef HAS_TYPE_EXTENDED}
      SizeOf(extended):begin
       result.ValueType:=AVT_FLOAT;
       extended(pointer(@result.FloatValue.Bytes[0])^):=extended(pointer(@LeftValue.FloatValue.Bytes[0])^)*IntegerValueGetInt64(RightValue.IntegerValue);
       result.FloatValue.Count:=SizeOf(extended);
      end;
{$endif}
      else begin
       if DoError then begin
        AssemblerInstance.MakeError(19);
       end;
      end;
     end;
    end;
    AVT_FLOAT:begin
     case LeftValue.FloatValue.Count of
{$ifdef HAS_TYPE_SINGLE}
      SizeOf(single):begin
       case RightValue.FloatValue.Count of
{$ifdef HAS_TYPE_SINGLE}
        SizeOf(single):begin
         result.ValueType:=AVT_FLOAT;
         single(pointer(@result.FloatValue.Bytes[0])^):=single(pointer(@LeftValue.FloatValue.Bytes[0])^)*single(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(single);
        end;
{$endif}
{$ifdef HAS_TYPE_DOUBLE}
        SizeOf(double):begin
         result.ValueType:=AVT_FLOAT;
         double(pointer(@result.FloatValue.Bytes[0])^):=single(pointer(@LeftValue.FloatValue.Bytes[0])^)*double(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(double);
        end;
{$endif}
{$ifdef HAS_TYPE_EXTENDED}
        SizeOf(extended):begin
         result.ValueType:=AVT_FLOAT;
         extended(pointer(@result.FloatValue.Bytes[0])^):=single(pointer(@LeftValue.FloatValue.Bytes[0])^)*extended(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(extended);
        end;
{$endif}
        else begin
         if DoError then begin
          AssemblerInstance.MakeError(19);
         end;
        end;
       end;
      end;
{$endif}
{$ifdef HAS_TYPE_DOUBLE}
      SizeOf(double):begin
       case RightValue.FloatValue.Count of
{$ifdef HAS_TYPE_SINGLE}
        SizeOf(single):begin
         result.ValueType:=AVT_FLOAT;
         double(pointer(@result.FloatValue.Bytes[0])^):=double(pointer(@LeftValue.FloatValue.Bytes[0])^)*single(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(double);
        end;
{$endif}
{$ifdef HAS_TYPE_DOUBLE}
        SizeOf(double):begin
         result.ValueType:=AVT_FLOAT;
         double(pointer(@result.FloatValue.Bytes[0])^):=double(pointer(@LeftValue.FloatValue.Bytes[0])^)*double(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(double);
        end;
{$endif}
{$ifdef HAS_TYPE_EXTENDED}
        SizeOf(extended):begin
         result.ValueType:=AVT_FLOAT;
         extended(pointer(@result.FloatValue.Bytes[0])^):=double(pointer(@LeftValue.FloatValue.Bytes[0])^)*extended(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(extended);
        end;
{$endif}
        else begin
         if DoError then begin
          AssemblerInstance.MakeError(19);
         end;
        end;
       end;
      end;
{$endif}
{$ifdef HAS_TYPE_EXTENDED}
      SizeOf(extended):begin
       case RightValue.FloatValue.Count of
{$ifdef HAS_TYPE_SINGLE}
        SizeOf(single):begin
         result.ValueType:=AVT_FLOAT;
         extended(pointer(@result.FloatValue.Bytes[0])^):=extended(pointer(@LeftValue.FloatValue.Bytes[0])^)*single(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(extended);
        end;
{$endif}
{$ifdef HAS_TYPE_DOUBLE}
        SizeOf(double):begin
         result.ValueType:=AVT_FLOAT;
         extended(pointer(@result.FloatValue.Bytes[0])^):=extended(pointer(@LeftValue.FloatValue.Bytes[0])^)*double(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(extended);
        end;
{$endif}
{$ifdef HAS_TYPE_EXTENDED}
        SizeOf(extended):begin
         result.ValueType:=AVT_FLOAT;
         extended(pointer(@result.FloatValue.Bytes[0])^):=extended(pointer(@LeftValue.FloatValue.Bytes[0])^)*extended(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(extended);
        end;
{$endif}
        else begin
         if DoError then begin
          AssemblerInstance.MakeError(19);
         end;
        end;
       end;
      end;
{$endif}
      else begin
       if DoError then begin
        AssemblerInstance.MakeError(19);
       end;
      end;
     end;
    end;
    else begin
     if DoError then begin
      AssemblerInstance.MakeError(19);
     end;
    end;
   end;
  end;
  else begin
   if DoError then begin
    AssemblerInstance.MakeError(19);
   end;
  end;
 end;
 if result.ValueType=AVT_NONE then begin
  result.ValueType:=AVT_INT;
  IntegerValueSetQWord(result.IntegerValue,0);
 end;
end;

function ValueOpDiv(const AssemblerInstance:TAssembler;const LeftValue,RightValue:TAssemblerValue;const DoError:boolean):TAssemblerValue;
//var s:ansistring;
begin
 result.ValueType:=AVT_NONE;
 case LeftValue.ValueType of
  AVT_INT:begin
   case RightValue.ValueType of
    AVT_INT:begin
     result.ValueType:=AVT_INT;
     if IntegerValueIsZero(RightValue.IntegerValue) then begin
      IntegerValueSetQWord(result.IntegerValue,0);
     end else begin
      IntegerValueDiv(result.IntegerValue,LeftValue.IntegerValue,RightValue.IntegerValue);
     end;
    end;
    AVT_FLOAT:begin
     case RightValue.FloatValue.Count of
{$ifdef HAS_TYPE_SINGLE}
      SizeOf(single):begin
       result.ValueType:=AVT_FLOAT;
       single(pointer(@result.FloatValue.Bytes[0])^):=IntegerValueGetInt64(LeftValue.IntegerValue)/single(pointer(@RightValue.FloatValue.Bytes[0])^);
       result.FloatValue.Count:=SizeOf(single);
      end;
{$endif}
{$ifdef HAS_TYPE_DOUBLE}
      SizeOf(double):begin
       result.ValueType:=AVT_FLOAT;
       double(pointer(@result.FloatValue.Bytes[0])^):=IntegerValueGetInt64(LeftValue.IntegerValue)/double(pointer(@RightValue.FloatValue.Bytes[0])^);
       result.FloatValue.Count:=SizeOf(double);
      end;
{$endif}
{$ifdef HAS_TYPE_EXTENDED}
      SizeOf(extended):begin
       result.ValueType:=AVT_FLOAT;
       extended(pointer(@result.FloatValue.Bytes[0])^):=IntegerValueGetInt64(LeftValue.IntegerValue)/extended(pointer(@RightValue.FloatValue.Bytes[0])^);
       result.FloatValue.Count:=SizeOf(extended);
      end;
{$endif}
      else begin
       if DoError then begin
        AssemblerInstance.MakeError(19);
       end;
      end;
     end;
    end;
    else begin
     if DoError then begin
      AssemblerInstance.MakeError(19);
     end;
    end;
   end;
  end;
  AVT_FLOAT:begin
   case RightValue.ValueType of
    AVT_INT:begin
     case LeftValue.FloatValue.Count of
{$ifdef HAS_TYPE_SINGLE}
      SizeOf(single):begin
       result.ValueType:=AVT_FLOAT;
       single(pointer(@result.FloatValue.Bytes[0])^):=single(pointer(@LeftValue.FloatValue.Bytes[0])^)/IntegerValueGetInt64(RightValue.IntegerValue);
       result.FloatValue.Count:=SizeOf(single);
      end;
{$endif}
{$ifdef HAS_TYPE_DOUBLE}
      SizeOf(double):begin
       result.ValueType:=AVT_FLOAT;
       double(pointer(@result.FloatValue.Bytes[0])^):=double(pointer(@LeftValue.FloatValue.Bytes[0])^)/IntegerValueGetInt64(RightValue.IntegerValue);
       result.FloatValue.Count:=SizeOf(double);
      end;
{$endif}
{$ifdef HAS_TYPE_EXTENDED}
      SizeOf(extended):begin
       result.ValueType:=AVT_FLOAT;
       extended(pointer(@result.FloatValue.Bytes[0])^):=extended(pointer(@LeftValue.FloatValue.Bytes[0])^)/IntegerValueGetInt64(RightValue.IntegerValue);
       result.FloatValue.Count:=SizeOf(extended);
      end;
{$endif}
      else begin
       if DoError then begin
        AssemblerInstance.MakeError(19);
       end;
      end;
     end;
     result.ValueType:=AVT_INT;
     IntegerValueAdd(result.IntegerValue,LeftValue.IntegerValue,RightValue.IntegerValue);
    end;
    AVT_FLOAT:begin
     case LeftValue.FloatValue.Count of
{$ifdef HAS_TYPE_SINGLE}
      SizeOf(single):begin
       case RightValue.FloatValue.Count of
{$ifdef HAS_TYPE_SINGLE}
        SizeOf(single):begin
         result.ValueType:=AVT_FLOAT;
         single(pointer(@result.FloatValue.Bytes[0])^):=single(pointer(@LeftValue.FloatValue.Bytes[0])^)/single(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(single);
        end;
{$endif}
{$ifdef HAS_TYPE_DOUBLE}
        SizeOf(double):begin
         result.ValueType:=AVT_FLOAT;
         double(pointer(@result.FloatValue.Bytes[0])^):=single(pointer(@LeftValue.FloatValue.Bytes[0])^)/double(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(double);
        end;
{$endif}
{$ifdef HAS_TYPE_EXTENDED}
        SizeOf(extended):begin
         result.ValueType:=AVT_FLOAT;
         extended(pointer(@result.FloatValue.Bytes[0])^):=single(pointer(@LeftValue.FloatValue.Bytes[0])^)/extended(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(extended);
        end;
{$endif}
        else begin
         if DoError then begin
          AssemblerInstance.MakeError(19);
         end;
        end;
       end;
      end;
{$endif}
{$ifdef HAS_TYPE_DOUBLE}
      SizeOf(double):begin
       case RightValue.FloatValue.Count of
{$ifdef HAS_TYPE_SINGLE}
        SizeOf(single):begin
         result.ValueType:=AVT_FLOAT;
         double(pointer(@result.FloatValue.Bytes[0])^):=double(pointer(@LeftValue.FloatValue.Bytes[0])^)/single(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(double);
        end;
{$endif}
{$ifdef HAS_TYPE_DOUBLE}
        SizeOf(double):begin
         result.ValueType:=AVT_FLOAT;
         double(pointer(@result.FloatValue.Bytes[0])^):=double(pointer(@LeftValue.FloatValue.Bytes[0])^)/double(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(double);
        end;
{$endif}
{$ifdef HAS_TYPE_EXTENDED}
        SizeOf(extended):begin
         result.ValueType:=AVT_FLOAT;
         extended(pointer(@result.FloatValue.Bytes[0])^):=double(pointer(@LeftValue.FloatValue.Bytes[0])^)/extended(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(extended);
        end;
{$endif}
        else begin
         if DoError then begin
          AssemblerInstance.MakeError(19);
         end;
        end;
       end;
      end;
{$endif}
{$ifdef HAS_TYPE_EXTENDED}
      SizeOf(extended):begin
       case RightValue.FloatValue.Count of
{$ifdef HAS_TYPE_SINGLE}
        SizeOf(single):begin
         result.ValueType:=AVT_FLOAT;
         extended(pointer(@result.FloatValue.Bytes[0])^):=extended(pointer(@LeftValue.FloatValue.Bytes[0])^)/single(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(extended);
        end;
{$endif}
{$ifdef HAS_TYPE_DOUBLE}
        SizeOf(double):begin
         result.ValueType:=AVT_FLOAT;
         extended(pointer(@result.FloatValue.Bytes[0])^):=extended(pointer(@LeftValue.FloatValue.Bytes[0])^)/double(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(extended);
        end;
{$endif}
{$ifdef HAS_TYPE_EXTENDED}
        SizeOf(extended):begin
         result.ValueType:=AVT_FLOAT;
         extended(pointer(@result.FloatValue.Bytes[0])^):=extended(pointer(@LeftValue.FloatValue.Bytes[0])^)/extended(pointer(@RightValue.FloatValue.Bytes[0])^);
         result.FloatValue.Count:=SizeOf(extended);
        end;
{$endif}
        else begin
         if DoError then begin
          AssemblerInstance.MakeError(19);
         end;
        end;
       end;
      end;
{$endif}
      else begin
       if DoError then begin
        AssemblerInstance.MakeError(19);
       end;
      end;
     end;
    end;
    else begin
     if DoError then begin
      AssemblerInstance.MakeError(19);
     end;
    end;
   end;
  end;
  else begin
   if DoError then begin
    AssemblerInstance.MakeError(19);
   end;
  end;
 end;
 if result.ValueType=AVT_NONE then begin
  result.ValueType:=AVT_INT;
  IntegerValueSetQWord(result.IntegerValue,0);
 end;
end;

function ValueOpXOR(const AssemblerInstance:TAssembler;const LeftValue,RightValue:TAssemblerValue;const DoError:boolean):TAssemblerValue;
//var s:ansistring;
begin
 result.ValueType:=AVT_NONE;
 case LeftValue.ValueType of
  AVT_INT:begin
   case RightValue.ValueType of
    AVT_INT:begin
     result.ValueType:=AVT_INT;
     IntegerValueXOR(result.IntegerValue,LeftValue.IntegerValue,RightValue.IntegerValue);
    end;
    else begin
     if DoError then begin
      AssemblerInstance.MakeError(19);
     end;
    end;
   end;
  end;
  else begin
   if DoError then begin
    AssemblerInstance.MakeError(19);
   end;
  end;
 end;
 if result.ValueType=AVT_NONE then begin
  result.ValueType:=AVT_INT;
  IntegerValueSetQWord(result.IntegerValue,0);
 end;
end;

function ValueOpOR(const AssemblerInstance:TAssembler;const LeftValue,RightValue:TAssemblerValue;const DoError:boolean):TAssemblerValue;
//var s:ansistring;
begin
 result.ValueType:=AVT_NONE;
 case LeftValue.ValueType of
  AVT_INT:begin
   case RightValue.ValueType of
    AVT_INT:begin
     result.ValueType:=AVT_INT;
     IntegerValueOR(result.IntegerValue,LeftValue.IntegerValue,RightValue.IntegerValue);
    end;
    else begin
     if DoError then begin
      AssemblerInstance.MakeError(19);
     end;
    end;
   end;
  end;
  else begin
   if DoError then begin
    AssemblerInstance.MakeError(19);
   end;
  end;
 end;
 if result.ValueType=AVT_NONE then begin
  result.ValueType:=AVT_INT;
  IntegerValueSetQWord(result.IntegerValue,0);
 end;
end;

function ValueOpAND(const AssemblerInstance:TAssembler;const LeftValue,RightValue:TAssemblerValue;const DoError:boolean):TAssemblerValue;
//var s:ansistring;
begin
 result.ValueType:=AVT_NONE;
 case LeftValue.ValueType of
  AVT_INT:begin
   case RightValue.ValueType of
    AVT_INT:begin
     result.ValueType:=AVT_INT;
     IntegerValueAND(result.IntegerValue,LeftValue.IntegerValue,RightValue.IntegerValue);
    end;
    else begin
     if DoError then begin
      AssemblerInstance.MakeError(19);
     end;
    end;
   end;
  end;
  else begin
   if DoError then begin
    AssemblerInstance.MakeError(19);
   end;
  end;
 end;
 if result.ValueType=AVT_NONE then begin
  result.ValueType:=AVT_INT;
  IntegerValueSetQWord(result.IntegerValue,0);
 end;
end;

function ValueOpShiftLeft(const AssemblerInstance:TAssembler;const LeftValue,RightValue:TAssemblerValue;const DoError:boolean):TAssemblerValue;
//var s:ansistring;
begin
 result.ValueType:=AVT_NONE;
 case LeftValue.ValueType of
  AVT_INT:begin
   case RightValue.ValueType of
    AVT_INT:begin
     result.ValueType:=AVT_INT;
     IntegerValueShiftLeft(result.IntegerValue,LeftValue.IntegerValue,IntegerValueGetInt64(RightValue.IntegerValue));
    end;
    else begin
     if DoError then begin
      AssemblerInstance.MakeError(19);
     end;
    end;
   end;
  end;
  else begin
   if DoError then begin
    AssemblerInstance.MakeError(19);
   end;
  end;
 end;
 if result.ValueType=AVT_NONE then begin
  result.ValueType:=AVT_INT;
  IntegerValueSetQWord(result.IntegerValue,0);
 end;
end;

function ValueOpShiftRight(const AssemblerInstance:TAssembler;const LeftValue,RightValue:TAssemblerValue;const DoError:boolean):TAssemblerValue;
//var s:ansistring;
begin
 result.ValueType:=AVT_NONE;
 case LeftValue.ValueType of
  AVT_INT:begin
   case RightValue.ValueType of
    AVT_INT:begin
     result.ValueType:=AVT_INT;
     IntegerValueShiftRight(result.IntegerValue,LeftValue.IntegerValue,IntegerValueGetInt64(RightValue.IntegerValue));
    end;
    else begin
     if DoError then begin
      AssemblerInstance.MakeError(19);
     end;
    end;
   end;
  end;
  else begin
   if DoError then begin
    AssemblerInstance.MakeError(19);
   end;
  end;
 end;
 if result.ValueType=AVT_NONE then begin
  result.ValueType:=AVT_INT;
  IntegerValueSetQWord(result.IntegerValue,0);
 end;
end;

function ValueOpShiftCompare(const AssemblerInstance:TAssembler;const LeftValue,RightValue:TAssemblerValue;const DoError:boolean):longint;
var //s:ansistring;
    i64:int64;
    IntegerValue:TIntegerValue;
begin
 result:=0;
 case LeftValue.ValueType of
  AVT_INT:begin
   case RightValue.ValueType of
    AVT_INT:begin
     result:=IntegerValueCompare(LeftValue.IntegerValue,RightValue.IntegerValue);
    end;
    AVT_FLOAT:begin
     case RightValue.FloatValue.Count of
{$ifdef HAS_TYPE_SINGLE}
      SizeOf(single):begin
       i64:=IntegerValueGetInt64(LeftValue.IntegerValue);
       if i64<single(pointer(@RightValue.FloatValue.Bytes[0])^) then begin
        result:=-1;
       end else if i64>single(pointer(@RightValue.FloatValue.Bytes[0])^) then begin
        result:=1;
       end else begin
        result:=0;
       end;
      end;
{$endif}
{$ifdef HAS_TYPE_DOUBLE}
      SizeOf(double):begin
       i64:=IntegerValueGetInt64(LeftValue.IntegerValue);
       if i64<double(pointer(@RightValue.FloatValue.Bytes[0])^) then begin
        result:=-1;
       end else if i64>double(pointer(@RightValue.FloatValue.Bytes[0])^) then begin
        result:=1;
       end else begin
        result:=0;
       end;
      end;
{$endif}
{$ifdef HAS_TYPE_EXTENDED}
      SizeOf(extended):begin
       i64:=IntegerValueGetInt64(LeftValue.IntegerValue);
       if i64<extended(pointer(@RightValue.FloatValue.Bytes[0])^) then begin
        result:=-1;
       end else if i64>extended(pointer(@RightValue.FloatValue.Bytes[0])^) then begin
        result:=1;
       end else begin
        result:=0;
       end;
      end;
{$endif}
      else begin
       if DoError then begin
        AssemblerInstance.MakeError(19);
       end;
      end;
     end;
    end;
    else begin
     if DoError then begin
      AssemblerInstance.MakeError(19);
     end;
    end;
   end;
  end;
  AVT_FLOAT:begin
   case RightValue.ValueType of
    AVT_INT:begin
     case LeftValue.FloatValue.Count of
{$ifdef HAS_TYPE_SINGLE}
      SizeOf(single):begin
       i64:=IntegerValueGetInt64(RightValue.IntegerValue);
       if i64<single(pointer(@LeftValue.FloatValue.Bytes[0])^) then begin
        result:=-1;
       end else if i64>single(pointer(@LeftValue.FloatValue.Bytes[0])^) then begin
        result:=1;
       end else begin
        result:=0;
       end;
      end;
{$endif}
{$ifdef HAS_TYPE_DOUBLE}
      SizeOf(double):begin
       i64:=IntegerValueGetInt64(RightValue.IntegerValue);
       if i64<double(pointer(@LeftValue.FloatValue.Bytes[0])^) then begin
        result:=-1;
       end else if i64>double(pointer(@LeftValue.FloatValue.Bytes[0])^) then begin
        result:=1;
       end else begin
        result:=0;
       end;
      end;
{$endif}
{$ifdef HAS_TYPE_EXTENDED}
      SizeOf(extended):begin
       i64:=IntegerValueGetInt64(RightValue.IntegerValue);
       if i64<extended(pointer(@LeftValue.FloatValue.Bytes[0])^) then begin
        result:=-1;
       end else if i64>extended(pointer(@LeftValue.FloatValue.Bytes[0])^) then begin
        result:=1;
       end else begin
        result:=0;
       end;
      end;
{$endif}
      else begin
       if DoError then begin
        AssemblerInstance.MakeError(19);
       end;
      end;
     end;
    end;
    AVT_FLOAT:begin
     case LeftValue.FloatValue.Count of
{$ifdef HAS_TYPE_SINGLE}
      SizeOf(single):begin
       case RightValue.FloatValue.Count of
{$ifdef HAS_TYPE_SINGLE}
        SizeOf(single):begin
         if single(pointer(@LeftValue.FloatValue.Bytes[0])^)<single(pointer(@RightValue.FloatValue.Bytes[0])^) then begin
          result:=-1;
         end else if single(pointer(@LeftValue.FloatValue.Bytes[0])^)>single(pointer(@RightValue.FloatValue.Bytes[0])^) then begin
          result:=1;
         end else begin
          result:=0;
         end;
        end;
 {$endif}
{$ifdef HAS_TYPE_DOUBLE}
        SizeOf(double):begin
         if single(pointer(@LeftValue.FloatValue.Bytes[0])^)<double(pointer(@RightValue.FloatValue.Bytes[0])^) then begin
          result:=-1;
         end else if single(pointer(@LeftValue.FloatValue.Bytes[0])^)>double(pointer(@RightValue.FloatValue.Bytes[0])^) then begin
          result:=1;
         end else begin
          result:=0;
         end;
        end;
{$endif}
{$ifdef HAS_TYPE_EXTENDED}
        SizeOf(extended):begin
         if single(pointer(@LeftValue.FloatValue.Bytes[0])^)<extended(pointer(@RightValue.FloatValue.Bytes[0])^) then begin
          result:=-1;
         end else if single(pointer(@LeftValue.FloatValue.Bytes[0])^)>extended(pointer(@RightValue.FloatValue.Bytes[0])^) then begin
          result:=1;
         end else begin
          result:=0;
         end;
        end;
{$endif}
        else begin
         if DoError then begin
          AssemblerInstance.MakeError(19);
         end;
        end;
       end;
      end;
{$endif}
{$ifdef HAS_TYPE_DOUBLE}
      SizeOf(double):begin
       case RightValue.FloatValue.Count of
{$ifdef HAS_TYPE_SINGLE}
        SizeOf(single):begin
         if double(pointer(@LeftValue.FloatValue.Bytes[0])^)<single(pointer(@RightValue.FloatValue.Bytes[0])^) then begin
          result:=-1;
         end else if double(pointer(@LeftValue.FloatValue.Bytes[0])^)>single(pointer(@RightValue.FloatValue.Bytes[0])^) then begin
          result:=1;
         end else begin
          result:=0;
         end;
        end;
 {$endif}
{$ifdef HAS_TYPE_DOUBLE}
        SizeOf(double):begin
         if double(pointer(@LeftValue.FloatValue.Bytes[0])^)<double(pointer(@RightValue.FloatValue.Bytes[0])^) then begin
          result:=-1;
         end else if double(pointer(@LeftValue.FloatValue.Bytes[0])^)>double(pointer(@RightValue.FloatValue.Bytes[0])^) then begin
          result:=1;
         end else begin
          result:=0;
         end;
        end;
{$endif}
{$ifdef HAS_TYPE_EXTENDED}
        SizeOf(extended):begin
         if double(pointer(@LeftValue.FloatValue.Bytes[0])^)<extended(pointer(@RightValue.FloatValue.Bytes[0])^) then begin
          result:=-1;
         end else if double(pointer(@LeftValue.FloatValue.Bytes[0])^)>extended(pointer(@RightValue.FloatValue.Bytes[0])^) then begin
          result:=1;
         end else begin
          result:=0;
         end;
        end;
{$endif}
        else begin
         if DoError then begin
          AssemblerInstance.MakeError(19);
         end;
        end;
       end;
      end;
{$endif}
{$ifdef HAS_TYPE_EXTENDED}
      SizeOf(extended):begin
       case RightValue.FloatValue.Count of
{$ifdef HAS_TYPE_SINGLE}
        SizeOf(single):begin
         if extended(pointer(@LeftValue.FloatValue.Bytes[0])^)<single(pointer(@RightValue.FloatValue.Bytes[0])^) then begin
          result:=-1;
         end else if extended(pointer(@LeftValue.FloatValue.Bytes[0])^)>single(pointer(@RightValue.FloatValue.Bytes[0])^) then begin
          result:=1;
         end else begin
          result:=0;
         end;
        end;
 {$endif}
{$ifdef HAS_TYPE_DOUBLE}
        SizeOf(double):begin
         if extended(pointer(@LeftValue.FloatValue.Bytes[0])^)<double(pointer(@RightValue.FloatValue.Bytes[0])^) then begin
          result:=-1;
         end else if extended(pointer(@LeftValue.FloatValue.Bytes[0])^)>double(pointer(@RightValue.FloatValue.Bytes[0])^) then begin
          result:=1;
         end else begin
          result:=0;
         end;
        end;
{$endif}
{$ifdef HAS_TYPE_EXTENDED}
        SizeOf(extended):begin
         if extended(pointer(@LeftValue.FloatValue.Bytes[0])^)<extended(pointer(@RightValue.FloatValue.Bytes[0])^) then begin
          result:=-1;
         end else if extended(pointer(@LeftValue.FloatValue.Bytes[0])^)>extended(pointer(@RightValue.FloatValue.Bytes[0])^) then begin
          result:=1;
         end else begin
          result:=0;
         end;
        end;
{$endif}
        else begin
         if DoError then begin
          AssemblerInstance.MakeError(19);
         end;
        end;
       end;
      end;
{$endif}
      else begin
       if DoError then begin
        AssemblerInstance.MakeError(19);
       end;
      end;
     end;
    end;
    else begin
     if DoError then begin
      AssemblerInstance.MakeError(19);
     end;
    end;
   end;
  end;
  AVT_STRING:begin
   case RightValue.ValueType of
    AVT_INT:Begin
     IntegerValueParse(IntegerValue,LeftValue.StringValue);
     result:=IntegerValueCompare(IntegerValue,RightValue.IntegerValue);
    end;
    AVT_STRING:begin
     if LeftValue.StringValue<RightValue.StringValue then begin
      result:=-1;
     end else if LeftValue.StringValue>RightValue.StringValue then begin
      result:=1;
     end else begin
      result:=0;
     end;
    end;
    else begin
     if DoError then begin
      AssemblerInstance.MakeError(19);
     end;
    end;
   end;
  end;
  else begin
   if DoError then begin
    AssemblerInstance.MakeError(19);
   end;
  end;
 end;
end;

constructor TStringIntegerPairHashMap.Create;
begin
 inherited Create;
 RealSize:=0;
 LogSize:=0;
 Size:=0;
 Entities:=nil;
 EntityToCellIndex:=nil;
 CellToEntityIndex:=nil;
 Resize;
end;

destructor TStringIntegerPairHashMap.Destroy;
var Counter:longint;
begin
 Clear;
 for Counter:=0 to length(Entities)-1 do begin
  Entities[Counter].Key:='';
 end;
 SetLength(Entities,0);
 SetLength(EntityToCellIndex,0);
 SetLength(CellToEntityIndex,0);
 inherited Destroy;
end;

procedure TStringIntegerPairHashMap.Clear;
var Counter:longint;
begin
 for Counter:=0 to length(Entities)-1 do begin
  Entities[Counter].Key:='';
 end;
 RealSize:=0;
 LogSize:=0;
 Size:=0;
 SetLength(Entities,0);
 SetLength(EntityToCellIndex,0);
 SetLength(CellToEntityIndex,0);
 Resize;
end;

function TStringIntegerPairHashMap.FindCell(const Key:ansistring):longword;
var HashCode,Mask,Step:longword;
    Entity:longint;
begin
 HashCode:=HashString(Key);
 Mask:=(2 shl LogSize)-1;
 Step:=((HashCode shl 1)+1) and Mask;
 if LogSize<>0 then begin
  result:=HashCode shr (32-LogSize);
 end else begin
  result:=0;
 end;
 repeat
  Entity:=CellToEntityIndex[result];
  if (Entity=ENT_EMPTY) or ((Entity<>ENT_DELETED) and (Entities[Entity].Key=Key)) then begin
   exit;
  end;
  result:=(result+Step) and Mask;
 until false;
end;

procedure TStringIntegerPairHashMap.Resize;
var NewLogSize,NewSize,Cell,Entity,Counter:longint;
    OldEntities:TStringIntegerPairHashMapEntities;
    OldCellToEntityIndex:TStringIntegerPairHashMapEntityIndices;
    OldEntityToCellIndex:TStringIntegerPairHashMapEntityIndices;
begin
 NewLogSize:=0;
 NewSize:=RealSize;
 while NewSize<>0 do begin
  NewSize:=NewSize shr 1;
  inc(NewLogSize);
 end;
 if NewLogSize<1 then begin
  NewLogSize:=1;
 end;
 Size:=0;
 RealSize:=0;
 LogSize:=NewLogSize;
 OldEntities:=Entities;
 OldCellToEntityIndex:=CellToEntityIndex;
 OldEntityToCellIndex:=EntityToCellIndex;
 Entities:=nil;
 CellToEntityIndex:=nil;
 EntityToCellIndex:=nil;
 SetLength(Entities,2 shl LogSize);
 SetLength(CellToEntityIndex,2 shl LogSize);
 SetLength(EntityToCellIndex,2 shl LogSize);
 for Counter:=0 to length(CellToEntityIndex)-1 do begin
  CellToEntityIndex[Counter]:=ENT_EMPTY;
 end;
 for Counter:=0 to length(EntityToCellIndex)-1 do begin
  EntityToCellIndex[Counter]:=CELL_EMPTY;
 end;
 for Counter:=0 to length(OldEntityToCellIndex)-1 do begin
  Cell:=OldEntityToCellIndex[Counter];
  if Cell>=0 then begin
   Entity:=OldCellToEntityIndex[Cell];
   if Entity>=0 then begin
    Add(OldEntities[Counter].Key,OldEntities[Counter].Value);
   end;
  end;
 end;
 for Counter:=0 to length(OldEntities)-1 do begin
  OldEntities[Counter].Key:='';
 end;
 SetLength(OldEntities,0);
 SetLength(OldCellToEntityIndex,0);
 SetLength(OldEntityToCellIndex,0);
end;

function TStringIntegerPairHashMap.Add(const Key:ansistring;Value:TStringIntegerPairHashMapData):PStringIntegerPairHashMapEntity;
var Entity:longint;
    Cell:longword;
begin
 result:=nil;
 while RealSize>=(1 shl LogSize) do begin
  Resize;
 end;
 Cell:=FindCell(Key);
 Entity:=CellToEntityIndex[Cell];
 if Entity>=0 then begin
  result:=@Entities[Entity];
  result^.Key:=Key;
  result^.Value:=Value;
  exit;
 end;
 Entity:=Size;
 inc(Size);
 if Entity<(2 shl LogSize) then begin
  CellToEntityIndex[Cell]:=Entity;
  EntityToCellIndex[Entity]:=Cell;
  inc(RealSize);
  result:=@Entities[Entity];
  result^.Key:=Key;
  result^.Value:=Value;
 end;
end;

function TStringIntegerPairHashMap.Get(const Key:ansistring;CreateIfNotExist:boolean=false):PStringIntegerPairHashMapEntity;
var Entity:longint;
    Cell:longword;
begin
 result:=nil;
 Cell:=FindCell(Key);
 Entity:=CellToEntityIndex[Cell];
 if Entity>=0 then begin
  result:=@Entities[Entity];
 end else if CreateIfNotExist then begin
  result:=Add(Key,-1);
 end;
end;

function TStringIntegerPairHashMap.Delete(const Key:ansistring):boolean;
var Entity:longint;
    Cell:longword;
begin
 result:=false;
 Cell:=FindCell(Key);
 Entity:=CellToEntityIndex[Cell];
 if Entity>=0 then begin
  Entities[Entity].Key:='';
  Entities[Entity].Value:=-1;
  EntityToCellIndex[Entity]:=CELL_DELETED;
  CellToEntityIndex[Cell]:=ENT_DELETED;
  result:=true;
 end;
end;

function TStringIntegerPairHashMap.GetValue(const Key:ansistring):TStringIntegerPairHashMapData;
var Entity:longint;
    Cell:longword;
begin
 Cell:=FindCell(Key);
 Entity:=CellToEntityIndex[Cell];
 if Entity>=0 then begin
  result:=Entities[Entity].Value;
 end else begin
  result:=-1;
 end;
end;

procedure TStringIntegerPairHashMap.SetValue(const Key:ansistring;const Value:TStringIntegerPairHashMapData);
begin
 Add(Key,Value);
end;

constructor TAssemblerExpression.Create;
begin
 inherited Create;
 Operation:=#0;
 Value.ValueType:=AVT_NONE;
 FillChar(Value.IntegerValue,SizeOf(TIntegerValue),#0);
 FillChar(Value.FloatValue,SizeOf(TFloatValue),#0);
 Value.StringValue:='';
 MetaValue:=0;
 MetaFlags:=0;
 Left:=nil;
 Right:=nil;
 SecondRight:=nil;
end;

destructor TAssemblerExpression.Destroy;
begin
 Value.StringValue:='';
 FreeAndNil(Left);
 FreeAndNil(Right);
 FreeAndNil(SecondRight);
 inherited Destroy;
end;

procedure TAssemblerExpression.Assign(From:TAssemblerExpression);
begin
 if assigned(From) then begin
  Operation:=From.Operation;
  Value:=From.Value;
  MetaValue:=From.MetaValue;
  MetaFlags:=From.MetaFlags;
  FreeAndNil(Left);
  FreeAndNil(Right);
  FreeAndNil(SecondRight);
  if assigned(From.Left) then begin
   Left:=TAssemblerExpression.Create;
   Left.Assign(From.Left);
  end;
  if assigned(From.Right) then begin
   Right:=TAssemblerExpression.Create;
   Right.Assign(From.Right);
  end;
  if assigned(From.SecondRight) then begin
   SecondRight:=TAssemblerExpression.Create;
   SecondRight.Assign(From.SecondRight);
  end;
 end;
end;

procedure TAssemblerExpression.AssignParameters(const Parameters:TList);
begin
 if Operation='P' then begin
  if assigned(Parameters) and ((MetaValue>=0) and (MetaValue<Parameters.Count)) and
     assigned(Parameters[MetaValue]) then begin
   Assign(TAssemblerExpression(Parameters[MetaValue]));
  end else begin
   Operation:='x';
   Value.ValueType:=AVT_NONE;
   MetaValue:=0;
   MetaFlags:=0;
   FreeAndNil(Left);
   FreeAndNil(Right);
   FreeAndNil(SecondRight);
  end;
 end;
 if assigned(Left) then begin
  Left.AssignParameters(Parameters);
 end;
 if assigned(Right) then begin
  Right.AssignParameters(Parameters);
 end;
 if assigned(SecondRight) then begin
  SecondRight.AssignParameters(Parameters);
 end;
end;

function TAssemblerExpression.Evaluate(ASMx86:TAssembler;NoErrors:boolean=false):TAssemblerValue;
var Symbol:TUserSymbol;
    Counter:longint;
    DoTruncBits,va,vb:int64;
    v:longword;
    s,r:ansistring;
    ws:widestring;
    TempIntegerValue,OtherTempIntegerValue:PIntegerValue;
    TempValue:PAssemblerValue;
    SymbolType:TSymbolTreeLinkType;
    SymbolValue:TSymbolTreeLink;
begin
 if assigned(self) then begin
  case Operation of
   'F':begin
    case MetaValue of
     EF__STRCOPY__:begin
      s:=ValueToString(ASMx86,Left.Evaluate(ASMx86,NoErrors),not NoErrors);
      va:=ValueGetInt64(ASMx86,Right.Evaluate(ASMx86,NoErrors),not NoErrors);
      vb:=ValueGetInt64(ASMx86,SecondRight.Evaluate(ASMx86,NoErrors),not NoErrors);
      result.ValueType:=AVT_STRING;
      result.StringValue:=copy(s,va-1,vb);
     end;
     EF__STRLEN__:begin
      s:=ValueToString(ASMx86,Left.Evaluate(ASMx86,NoErrors),not NoErrors);
      result.ValueType:=AVT_INT;
      IntegerValueSetQWord(result.IntegerValue,length(s));
     end;
     EF__UTF8__:begin
      s:=ValueToString(ASMx86,Left.Evaluate(ASMx86,NoErrors),not NoErrors);
      result.ValueType:=AVT_STRING;
      result.StringValue:=s;
     end;
     EF__UTF16BE__:begin
      s:=ValueToString(ASMx86,Left.Evaluate(ASMx86,NoErrors),not NoErrors);
      result.ValueType:=AVT_STRING;
      ws:=PUCUUTF8ToUTF16(s);
      s:='';
      for Counter:=1 to length(ws) do begin
       s:=s+ansichar(byte((word(widechar(ws[Counter])) and $ff00) shr 8))+
            ansichar(byte((word(widechar(ws[Counter])) and $00ff) shl 8));
      end;
      result.StringValue:=s;
     end;
     EF__UTF16LE__:begin
      s:=ValueToString(ASMx86,Left.Evaluate(ASMx86,NoErrors),not NoErrors);
      result.ValueType:=AVT_STRING;
      ws:=PUCUUTF8ToUTF16(s);
      s:='';
      for Counter:=1 to length(ws) do begin
       s:=s+ansichar(byte((word(widechar(ws[Counter])) and $00ff) shl 8))+
            ansichar(byte((word(widechar(ws[Counter])) and $ff00) shr 8));
      end;
      result.StringValue:=s;
     end;
     EF__UTF32BE__:begin
      s:=ValueToString(ASMx86,Left.Evaluate(ASMx86,NoErrors),not NoErrors);
      result.ValueType:=AVT_STRING;
      r:='';
      Counter:=1;
      while Counter<=length(s) do begin
       v:=PUCUUTF8CodeUnitGetCharAndIncFallback(s,Counter);
       r:=r+ansichar(byte((v shr 24) and $ff))+
            ansichar(byte((v shr 16) and $ff))+
            ansichar(byte((v shr 8) and $ff))+
            ansichar(byte((v shr 0) and $ff));
      end;
      result.StringValue:=r;
     end;
     EF__UTF32LE__:begin
      s:=ValueToString(ASMx86,Left.Evaluate(ASMx86,NoErrors),not NoErrors);
      result.ValueType:=AVT_STRING;
      r:='';
      Counter:=1;
      while Counter<=length(s) do begin
       v:=PUCUUTF8CodeUnitGetCharAndIncFallback(s,Counter);
       r:=r+ansichar(byte((v shr 0) and $ff))+
            ansichar(byte((v shr 8) and $ff))+
            ansichar(byte((v shr 16) and $ff))+
            ansichar(byte((v shr 24) and $ff));
      end;
      result.StringValue:=r;
     end;
     else begin
      result:=Left.Evaluate(ASMx86,NoErrors);
     end;
    end;
   end;
   '+':begin
    result:=ValueOpAdd(ASMx86,Left.Evaluate(ASMx86,NoErrors),Right.Evaluate(ASMx86,NoErrors),not NoErrors);
   end;
   '-':begin
    result:=ValueOpSub(ASMx86,Left.Evaluate(ASMx86,NoErrors),Right.Evaluate(ASMx86,NoErrors),not NoErrors);
   end;
   '*':begin
    result:=ValueOpMul(ASMx86,Left.Evaluate(ASMx86,NoErrors),Right.Evaluate(ASMx86,NoErrors),not NoErrors);
   end;
   '/':begin
    result:=ValueOpDiv(ASMx86,Left.Evaluate(ASMx86,NoErrors),Right.Evaluate(ASMx86,NoErrors),not NoErrors);
   end;
   '^':begin
    result:=ValueOpXOR(ASMx86,Left.Evaluate(ASMx86,NoErrors),Right.Evaluate(ASMx86,NoErrors),not NoErrors);
   end;
   '&':begin
    result:=ValueOpAND(ASMx86,Left.Evaluate(ASMx86,NoErrors),Right.Evaluate(ASMx86,NoErrors),not NoErrors);
   end;
   '|':begin
    result:=ValueOpOR(ASMx86,Left.Evaluate(ASMx86,NoErrors),Right.Evaluate(ASMx86,NoErrors),not NoErrors);
   end;
   'l':begin
    result.ValueType:=AVT_INT;
    if (not IntegerValueIsZero(ValueToRawInt(ASMx86,Left.Evaluate(ASMx86,NoErrors),not NoErrors))) or
       (not IntegerValueIsZero(ValueToRawInt(ASMx86,Right.Evaluate(ASMx86,NoErrors),not NoErrors))) then begin
     IntegerValueSetQWord(result.IntegerValue,1);
    end else begin
     IntegerValueSetQWord(result.IntegerValue,0);
    end;
   end;
   'L':begin
    result.ValueType:=AVT_INT;
    if (not IntegerValueIsZero(ValueToRawInt(ASMx86,Left.Evaluate(ASMx86,NoErrors),not NoErrors))) and
       (not IntegerValueIsZero(ValueToRawInt(ASMx86,Right.Evaluate(ASMx86,NoErrors),not NoErrors))) then begin
     IntegerValueSetQWord(result.IntegerValue,1);
    end else begin
     IntegerValueSetQWord(result.IntegerValue,0);
    end;
   end;
   's':begin
    result:=ValueOpShiftLeft(ASMx86,Left.Evaluate(ASMx86,NoErrors),Right.Evaluate(ASMx86,NoErrors),not NoErrors);
   end;
   'S':begin
    result:=ValueOpShiftRight(ASMx86,Left.Evaluate(ASMx86,NoErrors),Right.Evaluate(ASMx86,NoErrors),not NoErrors);
   end;
   '=':begin
    result.ValueType:=AVT_INT;
    IntegerValueSetQWord(result.IntegerValue,ord(ValueOpShiftCompare(ASMx86,Left.Evaluate(ASMx86,NoErrors),Right.Evaluate(ASMx86,NoErrors),not NoErrors)=0));
   end;
   '>':begin
    result.ValueType:=AVT_INT;
    IntegerValueSetQWord(result.IntegerValue,ord(ValueOpShiftCompare(ASMx86,Left.Evaluate(ASMx86,NoErrors),Right.Evaluate(ASMx86,NoErrors),not NoErrors)>0));
   end;
   '<':begin
    result.ValueType:=AVT_INT;
    IntegerValueSetQWord(result.IntegerValue,ord(ValueOpShiftCompare(ASMx86,Left.Evaluate(ASMx86,NoErrors),Right.Evaluate(ASMx86,NoErrors),not NoErrors)<0));
   end;
   '}':begin
    result.ValueType:=AVT_INT;
    IntegerValueSetQWord(result.IntegerValue,ord(ValueOpShiftCompare(ASMx86,Left.Evaluate(ASMx86,NoErrors),Right.Evaluate(ASMx86,NoErrors),not NoErrors)>=0));
   end;
   '{':begin
    result.ValueType:=AVT_INT;
    IntegerValueSetQWord(result.IntegerValue,ord(ValueOpShiftCompare(ASMx86,Left.Evaluate(ASMx86,NoErrors),Right.Evaluate(ASMx86,NoErrors),not NoErrors)<=0));
   end;
   '#':begin
    result.ValueType:=AVT_INT;
    IntegerValueSetQWord(result.IntegerValue,ord(ValueOpShiftCompare(ASMx86,Left.Evaluate(ASMx86,NoErrors),Right.Evaluate(ASMx86,NoErrors),not NoErrors)<>0));
   end;
   '~':begin
    result:=ValueOpNOT(ASMx86,Left.Evaluate(ASMx86,NoErrors),not NoErrors);
   end;
   '_':begin
    result:=ValueOpNeg(ASMx86,Left.Evaluate(ASMx86,NoErrors),not NoErrors);
   end;
   '(':begin
    result:=Left.Evaluate(ASMx86,NoErrors);
   end;
   'k':begin
    result:=Left.Evaluate(ASMx86,NoErrors);
   end;
   'p':begin
    result:=Left.Evaluate(ASMx86,NoErrors);
   end;
   't':begin
    result:=Left.Evaluate(ASMx86,NoErrors);
   end;
   'm':begin
    result:=Left.Evaluate(ASMx86,NoErrors);
   end;
   'o':begin
    result:=Left.Evaluate(ASMx86,NoErrors);
   end;
   '$':begin
    result:=Left.Evaluate(ASMx86,NoErrors);
   end;
   'D':begin
    result.ValueType:=AVT_INT;
    IntegerValueSetQWord(result.IntegerValue,0);
    if Value.ValueType=AVT_STRING then begin
     if ASMX86.UserSymbolTree.Find(UpperCase(Value.StringValue),SymbolType,SymbolValue) then begin
      if SymbolType=stUSER then begin
       Symbol:=ASMx86.UserSymbolList[SymbolValue];
       if Symbol.SymbolType<>ustNONE then begin
        IntegerValueSetQWord(result.IntegerValue,1);
       end;
      end;
     end;
    end;
   end;
   'h':begin
    result.ValueType:=AVT_INT;
    if ASMx86.FixUpPass<>FUP_NONE then begin
     IntegerValueSetQWord(result.IntegerValue,ASMx86.FixUpPassHere+ASMx86.EvaluateHereOffset);
    end else begin
     if assigned(ASMx86.CurrentSection) then begin
      IntegerValueSetQWord(result.IntegerValue,ASMx86.CodePosition+ASMx86.EvaluateHereOffset);
     end else begin
      IntegerValueSetQWord(result.IntegerValue,ASMx86.CodePosition+ASMx86.StartOffset+ASMx86.EvaluateHereOffset);
     end;
    end;
   end;
   'H':begin
    result.ValueType:=AVT_INT;
    if ASMx86.FixUpPass<>FUP_NONE then begin
     IntegerValueSetQWord(result.IntegerValue,ASMx86.FixUpPassBase);
    end else begin
     if assigned(ASMx86.CurrentSection) then begin
      IntegerValueSetQWord(result.IntegerValue,0);
     end else begin
      IntegerValueSetQWord(result.IntegerValue,ASMx86.StartOffset);
     end;
    end;
   end;
   'c':begin
    result.ValueType:=AVT_INT;
    IntegerValueSetInt64(result.IntegerValue,ASMx86.RepeatCounter);
   end;
   'T':begin
    if assigned(Left) then begin
     GetMem(TempValue,SizeOf(TAssemblerValue));
     try
      FillChar(TempValue^,SizeOf(TAssemblerValue),#0);
      TempValue^:=Left.Evaluate(ASMx86,NoErrors);
      case TempValue^.ValueType of
       AVT_INT:begin
        result.ValueType:=AVT_STRING;
        result.StringValue:=IntegerValueToStr(TempValue^.IntegerValue);
       end;
       AVT_FLOAT:begin
        result.ValueType:=AVT_STRING;
        case result.FloatValue.Count of
         1:begin
          result.StringValue:=FloatToRawString(result.FloatValue.Bytes[0],IEEEFormat8);
         end;
         2:begin
          result.StringValue:=FloatToRawString(result.FloatValue.Bytes[0],IEEEFormat16);
         end;
         4:begin
          result.StringValue:=FloatToRawString(result.FloatValue.Bytes[0],IEEEFormat32);
         end;
         8:begin
          result.StringValue:=FloatToRawString(result.FloatValue.Bytes[0],IEEEFormat64);
         end;
         10:begin
          result.StringValue:=FloatToRawString(result.FloatValue.Bytes[0],IEEEFormat80);
         end;
         16:begin
          result.StringValue:=FloatToRawString(result.FloatValue.Bytes[0],IEEEFormat128);
         end;
         32:begin
          result.StringValue:=FloatToRawString(result.FloatValue.Bytes[0],IEEEFormat256);
         end;
         64:begin
          result.StringValue:=FloatToRawString(result.FloatValue.Bytes[0],IEEEFormat512);
         end;
         else begin
          ASMx86.MakeError(71);
         end;
        end;
       end;
       AVT_STRING:begin
        result:=TempValue^;
       end;
      end;
     finally
      TempValue^.StringValue:='';
      Finalize(TempValue^);
      FreeMem(TempValue);
     end;
    end;
   end;
   'i':begin
    if assigned(Left) then begin
     GetMem(TempValue,SizeOf(TAssemblerValue));
     try
      FillChar(TempValue^,SizeOf(TAssemblerValue),#0);
      TempValue^:=Left.Evaluate(ASMx86,NoErrors);
      case TempValue^.ValueType of
       AVT_INT:begin
        result:=TempValue^;
       end;
       AVT_FLOAT:begin
        case TempValue^.FloatValue.Count of
         1:begin
          s:=FloatToRawString(TempValue^.FloatValue,IEEEFormat8);
         end;
         2:begin
          s:=FloatToRawString(TempValue^.FloatValue,IEEEFormat16);
         end;
         4:begin
          s:=FloatToRawString(TempValue^.FloatValue,IEEEFormat32);
         end;
         8:begin
          s:=FloatToRawString(TempValue^.FloatValue,IEEEFormat64);
         end;
         10:begin
          s:=FloatToRawString(TempValue^.FloatValue,IEEEFormat80);
         end;
         16:begin
          s:=FloatToRawString(TempValue^.FloatValue,IEEEFormat128);
         end;
         32:begin
          s:=FloatToRawString(TempValue^.FloatValue,IEEEFormat256);
         end;
         64:begin
          s:=FloatToRawString(TempValue^.FloatValue,IEEEFormat512);
         end;
         else begin
          ASMx86.MakeError(71);
         end;
        end;
        StringToFloat(s,TempValue^.FloatValue.Bytes[0],IEEEFormat64);
        result.ValueType:=AVT_INT;
        IntegerValueSetInt64(result.IntegerValue,trunc(double(pointer(@Value.FloatValue.Bytes[0])^)));
       end;
       AVT_STRING:begin
        IntegerValueParse(result.IntegerValue,TempValue^.StringValue);
       end;
      end;
     finally
      TempValue^.StringValue:='';
      Finalize(TempValue^);
      FreeMem(TempValue);
     end;
    end;
   end;
   'I':begin
    if assigned(Left) then begin
     GetMem(TempValue,SizeOf(TAssemblerValue));
     try
      FillChar(TempValue^,SizeOf(TAssemblerValue),#0);
      TempValue^:=Left.Evaluate(ASMx86,NoErrors);
      case TempValue^.ValueType of
       AVT_INT:begin
        result:=TempValue^;
       end;
       AVT_FLOAT:begin
        result.ValueType:=AVT_INT;
        IntegerValueSetQWord(result.IntegerValue,0);
        Move(TempValue^.FloatValue.Bytes[0],result.IntegerValue[0],Left.Value.FloatValue.Count);
       end;
       AVT_STRING:begin
        GetMem(TempIntegerValue,SizeOf(TIntegerValue));
        GetMem(OtherTempIntegerValue,SizeOf(TIntegerValue));
        try
         result.ValueType:=AVT_INT;
         FillChar(result.IntegerValue,SizeOf(TIntegerValue),#0);
         Counter:=length(TempValue^.StringValue);
         while Counter>0 do begin
          IntegerValueShiftLeftInternal(TempIntegerValue^,result.IntegerValue,8);
          IntegerValueSetQWord(OtherTempIntegerValue^,byte(ansichar(TempValue^.StringValue[(length(TempValue^.StringValue)-Counter)+1])));
          IntegerValueOr(result.IntegerValue,TempIntegerValue^,OtherTempIntegerValue^);
          dec(Counter);
         end;
        finally
         FreeMem(OtherTempIntegerValue);
         FreeMem(TempIntegerValue);
        end;
       end;
      end;
     finally
      TempValue^.StringValue:='';
      Finalize(TempValue^);
      FreeMem(TempValue);
     end;
    end;
   end;
   'f':begin
    if assigned(Left) then begin
     GetMem(TempValue,SizeOf(TAssemblerValue));
     try
      FillChar(TempValue^,SizeOf(TAssemblerValue),#0);
      TempValue^:=Left.Evaluate(ASMx86,NoErrors);
      case TempValue^.ValueType of
       AVT_INT:begin
        try
         s:=IntegerValueToStr(TempValue^.IntegerValue);
         case MetaValue of
          8:begin
           result.ValueType:=AVT_FLOAT;
           StringToFloat(s,result.FloatValue.Bytes[0],IEEEFormat8);
           result.FloatValue.Count:=IEEEFormat8.Bytes;
          end;
          16:begin
           result.ValueType:=AVT_FLOAT;
           StringToFloat(s,result.FloatValue.Bytes[0],IEEEFormat16);
           result.FloatValue.Count:=IEEEFormat16.Bytes;
          end;
          32:begin
           result.ValueType:=AVT_FLOAT;
           StringToFloat(s,result.FloatValue.Bytes[0],IEEEFormat32);
           result.FloatValue.Count:=IEEEFormat32.Bytes;
          end;
          64:begin
           result.ValueType:=AVT_FLOAT;
           StringToFloat(s,result.FloatValue.Bytes[0],IEEEFormat64);
           result.FloatValue.Count:=IEEEFormat64.Bytes;
          end;
          80:begin
           result.ValueType:=AVT_FLOAT;
           StringToFloat(s,result.FloatValue.Bytes[0],IEEEFormat80);
           result.FloatValue.Count:=IEEEFormat80.Bytes;
          end;
          128:begin
           result.ValueType:=AVT_FLOAT;
           StringToFloat(s,result.FloatValue.Bytes[0],IEEEFormat128);
           result.FloatValue.Count:=IEEEFormat128.Bytes;
          end;
          256:begin
           result.ValueType:=AVT_FLOAT;
           StringToFloat(s,result.FloatValue.Bytes[0],IEEEFormat256);
           result.FloatValue.Count:=IEEEFormat256.Bytes;
          end;
          512:begin
           result.ValueType:=AVT_FLOAT;
           StringToFloat(s,result.FloatValue.Bytes[0],IEEEFormat512);
           result.FloatValue.Count:=IEEEFormat512.Bytes;
          end;
         end;
        except
         on e:Exception do begin
          ASMx86.MakeError(e.Message);
         end;
        end;
       end;
       AVT_FLOAT:begin
        case TempValue^.FloatValue.Count of
         1,2,4,8,10,16,32,64:begin
          try
           if MetaValue=(TempValue^.FloatValue.Count shl 8) then begin
            result:=TempValue^;
           end else begin
            case TempValue^.FloatValue.Count of
             1:begin
              s:=FloatToRawString(TempValue^.FloatValue,IEEEFormat8);
             end;
             2:begin
              s:=FloatToRawString(TempValue^.FloatValue,IEEEFormat16);
             end;
             4:begin
              s:=FloatToRawString(TempValue^.FloatValue,IEEEFormat32);
             end;
             8:begin
              s:=FloatToRawString(TempValue^.FloatValue,IEEEFormat64);
             end;
             10:begin
              s:=FloatToRawString(TempValue^.FloatValue,IEEEFormat80);
             end;
             16:begin
              s:=FloatToRawString(TempValue^.FloatValue,IEEEFormat128);
             end;
             32:begin
              s:=FloatToRawString(TempValue^.FloatValue,IEEEFormat256);
             end;
             64:begin
              s:=FloatToRawString(TempValue^.FloatValue,IEEEFormat512);
             end;
             else begin
              ASMx86.MakeError(71);
             end;
            end;
            case MetaValue of
             8:begin
              result.ValueType:=AVT_FLOAT;
              StringToFloat(s,result.FloatValue.Bytes[0],IEEEFormat8);
              result.FloatValue.Count:=IEEEFormat8.Bytes;
             end;
             16:begin
              result.ValueType:=AVT_FLOAT;
              StringToFloat(s,result.FloatValue.Bytes[0],IEEEFormat16);
              result.FloatValue.Count:=IEEEFormat16.Bytes;
             end;
             32:begin
              result.ValueType:=AVT_FLOAT;
              StringToFloat(s,result.FloatValue.Bytes[0],IEEEFormat32);
              result.FloatValue.Count:=IEEEFormat32.Bytes;
             end;
             64:begin
              result.ValueType:=AVT_FLOAT;
              StringToFloat(s,result.FloatValue.Bytes[0],IEEEFormat64);
              result.FloatValue.Count:=IEEEFormat64.Bytes;
             end;
             80:begin
              result.ValueType:=AVT_FLOAT;
              StringToFloat(s,result.FloatValue.Bytes[0],IEEEFormat80);
              result.FloatValue.Count:=IEEEFormat80.Bytes;
             end;
             128:begin
              result.ValueType:=AVT_FLOAT;
              StringToFloat(s,result.FloatValue.Bytes[0],IEEEFormat128);
              result.FloatValue.Count:=IEEEFormat128.Bytes;
             end;
             256:begin
              result.ValueType:=AVT_FLOAT;
              StringToFloat(s,result.FloatValue.Bytes[0],IEEEFormat256);
              result.FloatValue.Count:=IEEEFormat256.Bytes;
             end;
             512:begin
              result.ValueType:=AVT_FLOAT;
              StringToFloat(s,result.FloatValue.Bytes[0],IEEEFormat512);
              result.FloatValue.Count:=IEEEFormat512.Bytes;
             end;
             else begin
              ASMx86.MakeError(71);
             end;
            end;
           end;
          except
           on e:Exception do begin
            ASMx86.MakeError(e.Message);
           end;
          end;
         end;
         else begin
          ASMx86.MakeError(71);
         end;
        end;
       end;
       AVT_STRING:begin
        try
         s:=TempValue^.StringValue;
         case MetaValue of
          8:begin
           result.ValueType:=AVT_FLOAT;
           StringToFloat(s,result.FloatValue.Bytes[0],IEEEFormat8);
           result.FloatValue.Count:=IEEEFormat8.Bytes;
          end;
          16:begin
           result.ValueType:=AVT_FLOAT;
           StringToFloat(s,result.FloatValue.Bytes[0],IEEEFormat16);
           result.FloatValue.Count:=IEEEFormat16.Bytes;
          end;
          32:begin
           result.ValueType:=AVT_FLOAT;
           StringToFloat(s,result.FloatValue.Bytes[0],IEEEFormat32);
           result.FloatValue.Count:=IEEEFormat32.Bytes;
          end;
          64:begin
           result.ValueType:=AVT_FLOAT;
           StringToFloat(s,result.FloatValue.Bytes[0],IEEEFormat64);
           result.FloatValue.Count:=IEEEFormat64.Bytes;
          end;
          80:begin
           result.ValueType:=AVT_FLOAT;
           StringToFloat(s,result.FloatValue.Bytes[0],IEEEFormat80);
           result.FloatValue.Count:=IEEEFormat80.Bytes;
          end;
          128:begin
           result.ValueType:=AVT_FLOAT;
           StringToFloat(s,result.FloatValue.Bytes[0],IEEEFormat128);
           result.FloatValue.Count:=IEEEFormat128.Bytes;
          end;
          256:begin
           result.ValueType:=AVT_FLOAT;
           StringToFloat(s,result.FloatValue.Bytes[0],IEEEFormat256);
           result.FloatValue.Count:=IEEEFormat256.Bytes;
          end;
          512:begin
           result.ValueType:=AVT_FLOAT;
           StringToFloat(s,result.FloatValue.Bytes[0],IEEEFormat512);
           result.FloatValue.Count:=IEEEFormat512.Bytes;
          end;
          else begin
           ASMx86.MakeError(71);
          end;
         end;
        except
         on e:Exception do begin
          ASMx86.MakeError(e.Message);
         end;
        end;
       end;
      end;
     finally
      TempValue^.StringValue:='';
      Finalize(TempValue^);
      FreeMem(TempValue);
     end;
    end;
   end;
   'x':begin
    result:=Value;
   end;
   'v':begin
    if (MetaValue>=0) and (MetaValue<ASMx86.UserSymbolList.Count) then begin
     Symbol:=ASMx86.UserSymbolList[MetaValue];
     case ASMx86.FixUpPass of
      FUP_PEEXE:begin
       result:=Symbol.GetValue(ASMx86);
       if Symbol.SymbolType in [ustLABEL,ustIMPORT] then begin
        if assigned(Symbol.Section) then begin
         GetMem(TempIntegerValue,SizeOf(TIntegerValue));
         GetMem(OtherTempIntegerValue,SizeOf(TIntegerValue));
         try
          TempIntegerValue^:=result.IntegerValue;
          IntegerValueSetQWord(OtherTempIntegerValue^,Symbol.Section^.CompleteOffset);
          IntegerValueAdd(result.IntegerValue,TempIntegerValue^,OtherTempIntegerValue^);
         finally
          FreeMem(OtherTempIntegerValue);
          FreeMem(TempIntegerValue);
         end;
        end;
       end;
      end;
      else begin
       if (ASMx86.FixUpPass in [FUP_MZEXE]) and (Symbol.SymbolType in [ustLABEL,ustSEGMENT]) then begin
        result.ValueType:=AVT_INT;
        IntegerValueSetQWord(result.IntegerValue,0);
        case ASMx86.FixUpPassFlags and (FUEF_SEG16 or FUEF_OFS16) of
         FUEF_NONE:begin
          case Symbol.SymbolType of
           ustNONE:begin
            ASMx86.MakeError(9);
           end;
           ustLABEL:begin
            result.IntegerValue:=ASMx86.IntAdd(result.IntegerValue,Symbol.GetValue(ASMx86));
            if not assigned(Symbol.Section) then begin
             result.IntegerValue:=ASMx86.IntAdd(result.IntegerValue,ASMx86.StartOffset);
            end;
           end;
           ustSEGMENT:begin
            if assigned(Symbol.Segment) then begin
             result.IntegerValue:=ASMx86.IntAdd(result.IntegerValue,Symbol.Segment^.Position);
            end else begin
             ASMx86.MakeError('Invalid segment');
            end;
            if not assigned(Symbol.Section) then begin
             result.IntegerValue:=ASMx86.IntAdd(result.IntegerValue,ASMx86.StartOffset);
            end;
           end;
           ustDEFINE,ustMACRO,ustSCRIPTMACRO{,ustSTRUCT}:begin
            ASMx86.MakeError(27);
           end;
           else begin
            result.IntegerValue:=ASMx86.IntAdd(result.IntegerValue,Symbol.GetValue(ASMx86));
           end
          end;
         end;
         FUEF_SEG16:begin
          case Symbol.SymbolType of
           ustLABEL:begin
            if assigned(Symbol.Segment) then begin
             result.IntegerValue:=ASMx86.IntAdd(result.IntegerValue,Symbol.Segment^.Position shr 4);
            end else begin
             ASMx86.MakeWarning('Label without segment');
             if not assigned(Symbol.Section) then begin
              result.IntegerValue:=ASMx86.IntAdd(result.IntegerValue,ASMx86.StartOffset);
             end;
            end;
           end;
           ustSEGMENT:begin
            if assigned(Symbol.Segment) then begin
             result.IntegerValue:=ASMx86.IntAdd(result.IntegerValue,Symbol.Segment^.Position shr 4);
            end else begin
             ASMx86.MakeError('Invalid segment');
            end;
           end;
           else begin
            ASMx86.MakeError('Label or segment expected');
           end;
          end;
         end;
         FUEF_OFS16:begin
          case Symbol.SymbolType of
           ustLABEL:begin
            result.IntegerValue:=ASMx86.IntAdd(result.IntegerValue,Symbol.GetValue(ASMx86));
            if assigned(Symbol.Segment) then begin
             result.IntegerValue:=ASMx86.IntSub(result.IntegerValue,Symbol.Segment^.Position);
            end else begin
             ASMx86.MakeWarning('Label without segment');
             if not assigned(Symbol.Section) then begin
              result.IntegerValue:=ASMx86.IntAdd(result.IntegerValue,ASMx86.StartOffset);
             end;
            end;
           end;
           ustSEGMENT:begin
            if not assigned(Symbol.Segment) then begin
             ASMx86.MakeError('Invalid segment');
            end;
           end;
           else begin
            ASMx86.MakeError('Label or segment expected');
           end;
          end;
         end;
         else begin
          ASMx86.MakeError('SEG and OFS can''t be combined together');
         end;
        end;
       end else begin
        result:=Symbol.GetValue(ASMx86);
        if Symbol.SymbolType in [ustLABEL,ustSEGMENT] then begin
         if not assigned(Symbol.Section) then begin
          GetMem(TempIntegerValue,SizeOf(TIntegerValue));
          GetMem(OtherTempIntegerValue,SizeOf(TIntegerValue));
          try
           TempIntegerValue^:=result.IntegerValue;
           IntegerValueSetQWord(OtherTempIntegerValue^,ASMx86.StartOffset);
           IntegerValueAdd(result.IntegerValue,TempIntegerValue^,OtherTempIntegerValue^);
          finally
           FreeMem(OtherTempIntegerValue);
           FreeMem(TempIntegerValue);
          end;
         end;
        end;
       end;
      end;
     end;
     if ASMx86.CodeImageWriting and (Symbol.SymbolType=ustNONE) then begin
      if NoErrors then begin
       ASMx86.MakeWarning(3);
      end else begin
       ASMx86.MakeError(9);
      end;
     end;
    end else begin
     if ASMx86.CodeImageWriting then begin
      if NoErrors then begin
       ASMx86.MakeWarning(3);
      end else begin
       ASMx86.MakeError(9);
      end;
     end;
     result.ValueType:=AVT_INT;
     IntegerValueSetQWord(result.IntegerValue,0);
    end;
   end;
   'r':begin
    result.ValueType:=AVT_INT;
    IntegerValueSetQWord(result.IntegerValue,0);
   end;
   #$a7:begin
    result:=Left.Evaluate(ASMx86,NoErrors);
    GetMem(TempValue,SizeOf(TAssemblerValue));
    try
     FillChar(TempValue^,SizeOf(TAssemblerValue),#0);
     TempValue^:=Right.Evaluate(ASMx86,NoErrors);
     if TempValue^.ValueType=AVT_INT then begin
      DoTruncBits:=IntegerValueGetInt64(TempValue^.IntegerValue);
      case result.ValueType of
       AVT_INT:begin
        if (DoTruncBits>=1) and (DoTruncBits<=IntegerValueBits) then begin
         TruncBits(result.IntegerValue,DoTruncBits);
        end else begin
         ASMx86.MakeError(19);
        end;
       end;
       AVT_FLOAT:begin
        if (DoTruncBits>=1) and (DoTruncBits<=(result.FloatValue.Count shl 3)) then begin
         TruncBits(result.FloatValue,DoTruncBits);
        end else begin
         ASMx86.MakeError(19);
        end;
       end;
       else begin
        ASMx86.MakeError(19);
       end;
      end;
     end else begin
      ASMx86.MakeError(19);
     end;
    finally
     TempValue^.StringValue:='';
     Finalize(TempValue^);
     FreeMem(TempValue);
    end;
   end;
   '?':begin
    GetMem(TempValue,SizeOf(TAssemblerValue));
    try
     FillChar(TempValue^,SizeOf(TAssemblerValue),#0);
     TempValue^:=Left.Evaluate(ASMx86,NoErrors);
     case TempValue^.ValueType of
      AVT_INT:begin
       if IntegerValueIsZero(TempValue^.IntegerValue) then begin
        result:=SecondRight.Evaluate(ASMx86,NoErrors);
       end else begin
        result:=Right.Evaluate(ASMx86,NoErrors);
       end;
      end;
      AVT_FLOAT:begin
       if FloatValueIsZero(TempValue^.FloatValue) then begin
        result:=SecondRight.Evaluate(ASMx86,NoErrors);
       end else begin
        result:=Right.Evaluate(ASMx86,NoErrors);
       end;
      end;
      AVT_STRING:begin
       if length(TempValue^.StringValue)=0 then begin
        result:=SecondRight.Evaluate(ASMx86,NoErrors);
       end else begin
        result:=Right.Evaluate(ASMx86,NoErrors);
       end;
      end;
      else begin
       ASMx86.MakeError(19);
      end;
     end;
    finally
     TempValue^.StringValue:='';
     Finalize(TempValue^);
     FreeMem(TempValue);
    end;
   end;
   'R':begin
    case MetaValue of
     0:begin
      result.ValueType:=AVT_INT;
      if assigned(ASMx86.CurrentSection) then begin
       IntegerValueSetQWord(result.IntegerValue,ASMx86.CurrentSection^.Offset);
      end else begin
       IntegerValueSetQWord(result.IntegerValue,0);
      end;
     end;
     else begin
      result.ValueType:=AVT_INT;
      IntegerValueSetQWord(result.IntegerValue,0);
     end;
    end;
   end;
   else begin
    result.ValueType:=AVT_INT;
    IntegerValueSetQWord(result.IntegerValue,0);
   end;
  end;
 end else begin
  result.ValueType:=AVT_INT;
  IntegerValueSetQWord(result.IntegerValue,0);
 end;
end;

procedure TAssemblerExpression.Freeze(ASMx86:TAssembler;NoErrors:boolean=false);
var Symbol:TUserSymbol;
begin
 if assigned(self) then begin
  if assigned(Left) then begin
   Left.Freeze(ASMx86,NoErrors);
  end;
  if assigned(Right) then begin
   Right.Freeze(ASMx86,NoErrors);
  end;
  if assigned(SecondRight) then begin
   SecondRight.Freeze(ASMx86,NoErrors);
  end;
  case Operation of
   'c','h','H':begin
    Value:=Evaluate(ASMx86,NoErrors);
    Operation:='x';
    MetaValue:=0;
    MetaFlags:=0;
    FreeAndNil(Left);
    FreeAndNil(Right);
    FreeAndNil(SecondRight);
   end;
   'v':begin
    if (MetaValue>=0) and (MetaValue<ASMx86.UserSymbolList.Count) then begin
     Symbol:=ASMx86.UserSymbolList[MetaValue];
     case Symbol.SymbolType of
      ustVARIABLE:begin
       if assigned(Symbol.Expression) then begin
        Operation:='(';
        MetaValue:=0;
        MetaFlags:=0;
        FreeAndNil(Left);
        FreeAndNil(Right);
        FreeAndNil(SecondRight);
        Left:=TAssemblerExpression.Create;
        Left.Assign(Symbol.Expression);
        Left.Freeze(ASMx86,NoErrors);
       end else begin
        Value:=Evaluate(ASMx86,NoErrors);
        Operation:='x';
        MetaValue:=0;
        MetaFlags:=0;
        FreeAndNil(Left);
        FreeAndNil(Right);
        FreeAndNil(SecondRight);
       end;
      end;
      ustCONSTANTSTRUCT:begin
       Value:=Evaluate(ASMx86,NoErrors);
       Operation:='x';
       MetaValue:=0;
       MetaFlags:=0;
       FreeAndNil(Left);
       FreeAndNil(Right);
       FreeAndNil(SecondRight);
      end;
     end;
    end;
   end;
  end;
 end;
end;

function TAssemblerExpression.Optimize(ASMx86:TAssembler):boolean;
 function IsIntegerZero(const v:TAssemblerValue):boolean;
 begin
  result:=(v.ValueType=AVT_INT) and IntegerValueIsZero(v.IntegerValue);
 end;
 function IsFloatZero(const v:TAssemblerValue):boolean;
 begin
  result:=(v.ValueType=AVT_FLOAT) and FloatValueIsZero(v.FloatValue);
 end;
 function IsZero(const v:TAssemblerValue):boolean;
 begin
  result:=IsIntegerZero(v) or IsFloatZero(v);
 end;
 function IsIntegerOne(const v:TAssemblerValue):boolean;
 begin
  result:=(v.ValueType=AVT_INT) and IntegerValueIsOne(v.IntegerValue);
 end;
 function Equals(const a,b:TAssemblerValue):boolean;
 begin
  result:=(((a.ValueType=AVT_INT) and (b.ValueType=AVT_INT)) and (IntegerValueCompare(a.IntegerValue,b.IntegerValue)=0)) or
          (((a.ValueType=AVT_STRING) and (b.ValueType=AVT_STRING)) and (a.StringValue=b.StringValue)) or
          (((a.ValueType=AVT_FLOAT) and (b.ValueType=AVT_FLOAT)) and (a.FloatValue.Count=b.FloatValue.Count) and CompareMem(@a.FloatValue.Bytes[0],@b.FloatValue.Bytes[0],a.FloatValue.Count));
 end;
var TerminateIt,OK:boolean;
    TempExpression,t0,t1,t2:TAssemblerExpression;
    FloatValueA:single;
    FloatValueACasted:longword absolute FloatValueA;
    FloatValueB:single;
    FloatValueBCasted:longword absolute FloatValueB;
    //DoTruncBits:int64;
    IntegerValue,OtherIntegerValue:PIntegerValue;
    s:ansistring;
    Counter:longint;
begin
 result:=false;
 if assigned(self) then begin
  if assigned(Left) then begin
   if Left.Optimize(ASMx86) then begin
    result:=true;
   end;
  end;
  if assigned(Right) then begin
   if Right.Optimize(ASMx86) then begin
    result:=true;
   end;
  end;
  if assigned(SecondRight) then begin
   if SecondRight.Optimize(ASMx86) then begin
    result:=true;
   end;
  end;
  case Operation of
   '?':begin
    if assigned(Left) and assigned(Right) and assigned(SecondRight) then begin
     if Left.Operation in ['x'] then begin
      case Left.Value.ValueType of
       AVT_INT:begin
        if IntegerValueIsZero(Left.Value.IntegerValue) then begin
         TempExpression:=SecondRight;
         Right.Free;
        end else begin
         TempExpression:=Right;
         SecondRight.Free;
        end;
        Right:=nil;
        SecondRight:=nil;
        Assign(TempExpression);
        TempExpression.Free;
       end;
       AVT_FLOAT:begin
        if FloatValueIsZero(Left.Value.FloatValue) then begin
         TempExpression:=SecondRight;
         Right.Free;
        end else begin
         TempExpression:=Right;
         SecondRight.Free;
        end;
        Right:=nil;
        SecondRight:=nil;
        Assign(TempExpression);
        TempExpression.Free;
       end;
       AVT_STRING:begin
        if length(Left.Value.StringValue)=0 then begin
         TempExpression:=SecondRight;
         Right.Free;
        end else begin
         TempExpression:=Right;
         SecondRight.Free;
        end;
        Right:=nil;
        SecondRight:=nil;
        Assign(TempExpression);
        TempExpression.Free;
       end;
       else begin
        ASMx86.MakeError(19);
       end;
      end;
     end;
    end;
   end;
{  #$a7:begin
    if assigned(Left) and assigned(Right) then begin
     if (Left.Operation in ['x','.',':','(']) and (Right.Operation='x') then begin
      A:=Left.Value;
      DoTruncBits:=Right.Value;
      if DoTruncBits in [1..64] then begin
       TruncBits(A,DoTruncBits);
       Operation:='x';
       Value:=A;
       Left.Free;
       Right.Free;
       Left:=nil;
       Right:=nil;
      end else begin
       ASMx86.MakeError(49);
      end;
     end else begin
      ASMx86.MakeError(48);
     end;
    end;
   end;{}
   '+','-','*','/','^','&','|','s','S','=','>','<','}','{','#':begin
    if assigned(Left) and assigned(Right) then begin
     if (Operation in ['*','+','&','|','^']) and
        assigned(Left) and (Left.Operation='x') and
        assigned(Right) and (Right.Operation='r') and
        not HasValueType(ASMx86,AVT_STRING) then begin
      TempExpression:=Left;
      Left:=Right;
      Right:=TempExpression;
      result:=true;
     end else if (Operation='+') and
                 assigned(Left) and (Left.Operation<>'*') and
                 assigned(Right) and (Right.Operation='*') and
                 not HasValueType(ASMx86,AVT_STRING) then begin
      TempExpression:=Left;
      Left:=Right;
      Right:=TempExpression;
      result:=true;
     end else if (Operation='+') and
                 assigned(Left) and assigned(Right) and
                 assigned(Left.Left) and assigned(Left.Right) and
                 (Left.Operation='+') and
                 Left.Right.Has(Right) then begin
      t0:=Left.Left;
      t1:=Left.Right;
      t2:=Right;
      Right:=Left;
      Left:=t0;
      Right.Left:=t1;
      Right.Right:=t2;
      result:=true;
     end else if (Operation='*') and
                 assigned(Left) and (Left.Operation='*') and
                 assigned(Left.Left) and assigned(Left.Right) and
                 (Left.Right.Operation='x') and (Left.Right.Value.ValueType=AVT_INT) and
                 assigned(Right) and (Right.Operation='x') and (Right.Value.ValueType=AVT_INT) then begin
      Left.Right.Value.IntegerValue:=ASMx86.IntMul(Left.Right.Value.IntegerValue,Right.Value.IntegerValue);
      FreeAndNil(Right);                          
      TempExpression:=Left;
      Operation:=TempExpression.Operation;
      Value:=TempExpression.Value;
      MetaValue:=TempExpression.MetaValue;
      MetaFlags:=TempExpression.MetaFlags;
      Left:=TempExpression.Left;
      Right:=TempExpression.Right;
      TempExpression.Operation:='x';
      TempExpression.Left:=nil;
      TempExpression.Right:=nil;
      TempExpression.Free;
      result:=true;
     end else if (Operation='+') and
                 assigned(Left) and (Left.Operation='*') and
                 assigned(Left.Left) and assigned(Right) and Left.Left.Equals(Right) and
                 assigned(Left.Right) and (Left.Right.Operation='x') and (Left.Right.Value.ValueType=AVT_INT) then begin
      Left.Right.Value.IntegerValue:=ASMx86.IntAdd(Left.Right.Value.IntegerValue,ASMx86.IntSet(1));
      FreeAndNil(Right);
      TempExpression:=Left;
      Operation:=TempExpression.Operation;
      Value:=TempExpression.Value;
      MetaValue:=TempExpression.MetaValue;
      MetaFlags:=TempExpression.MetaFlags;
      Left:=TempExpression.Left;
      Right:=TempExpression.Right;
      TempExpression.Operation:='x';
      TempExpression.Left:=nil;
      TempExpression.Right:=nil;
      TempExpression.Free;
      result:=true;
     end else if (Operation='-') and
                 assigned(Left) and (Left.Operation='*') and
                 assigned(Left.Left) and assigned(Right) and Left.Left.Equals(Right) and
                 assigned(Left.Right) and (Left.Right.Operation='x') and (Left.Right.Value.ValueType=AVT_INT) then begin
      Left.Right.Value.IntegerValue:=ASMx86.IntSub(Left.Right.Value.IntegerValue,ASMx86.IntSet(1));
      FreeAndNil(Right);
      TempExpression:=Left;
      Operation:=TempExpression.Operation;
      Value:=TempExpression.Value;
      MetaValue:=TempExpression.MetaValue;
      MetaFlags:=TempExpression.MetaFlags;
      Left:=TempExpression.Left;
      Right:=TempExpression.Right;
      TempExpression.Operation:='x';
      TempExpression.Left:=nil;
      TempExpression.Right:=nil;
      TempExpression.Free;
      result:=true;
     end else if (Operation='+') and
                  assigned(Left) and assigned(Right) and
                  (Left.Operation='*') and (Right.Operation='*') and
                  assigned(Left.Left) and assigned(Right.Left) and Left.Left.Equals(Right.Left) and
                  assigned(Left.Right) and assigned(Right.Right) and
                  ((Left.Right.Operation='x') and (Left.Right.Value.ValueType=AVT_INT)) and
                  ((Right.Right.Operation='x') and (Right.Right.Value.ValueType=AVT_INT)) then begin
      Left.Right.Value.IntegerValue:=ASMx86.IntAdd(Left.Right.Value.IntegerValue,Right.Right.Value.IntegerValue);
      FreeAndNil(Right);
      TempExpression:=Left;
      Operation:=TempExpression.Operation;
      Value:=TempExpression.Value;
      MetaValue:=TempExpression.MetaValue;
      MetaFlags:=TempExpression.MetaFlags;
      Left:=TempExpression.Left;
      Right:=TempExpression.Right;
      TempExpression.Operation:='x';
      TempExpression.Left:=nil;
      TempExpression.Right:=nil;
      TempExpression.Free;
      result:=true;
     end else if (Operation='-') and
                  assigned(Left) and assigned(Right) and
                  (Left.Operation='*') and (Right.Operation='*') and
                  assigned(Left.Left) and assigned(Right.Left) and Left.Left.Equals(Right.Left) and
                  assigned(Left.Right) and assigned(Right.Right) and
                  ((Left.Right.Operation='x') and (Left.Right.Value.ValueType=AVT_INT)) and
                  ((Right.Right.Operation='x') and (Right.Right.Value.ValueType=AVT_INT)) then begin
      Left.Right.Value.IntegerValue:=ASMx86.IntSub(Left.Right.Value.IntegerValue,Right.Right.Value.IntegerValue);
      FreeAndNil(Right);
      TempExpression:=Left;
      Operation:=TempExpression.Operation;
      Value:=TempExpression.Value;
      MetaValue:=TempExpression.MetaValue;
      MetaFlags:=TempExpression.MetaFlags;
      Left:=TempExpression.Left;
      Right:=TempExpression.Right;
      TempExpression.Operation:='x';
      TempExpression.Left:=nil;
      TempExpression.Right:=nil;
      TempExpression.Free;
      result:=true;
     end else if (Operation='+') and assigned(Left) and assigned(Right) and Left.Equals(Right) then begin
      Operation:='*';
      FreeAndNil(Right);
      Right:=TAssemblerExpression.Create;
      Right.Operation:='x';
      Right.Value.ValueType:=AVT_INT;
      IntegerValueSetQWord(Right.Value.IntegerValue,2);
      result:=true;
     end else if (Operation='-') and assigned(Left) and assigned(Right) and Left.Equals(Right) then begin
      Operation:='x';
      Value.ValueType:=AVT_INT;
      IntegerValueSetQWord(Value.IntegerValue,0);
      FreeAndNil(Left);
      FreeAndNil(Right);
      result:=true;
     end else if (Operation in ['*','&']) and
                 (((Left.Operation='x') and IsIntegerZero(Left.Value)) or
                  ((Right.Operation='x') and IsIntegerZero(Right.Value))) then begin
      FreeAndNil(Left);
      FreeAndNil(Right);
      Operation:='x';
      Value.ValueType:=AVT_INT;
      IntegerValueSetQWord(Value.IntegerValue,0);
      MetaValue:=0;
      MetaFlags:=0;
      result:=true;
     end else if (Operation='+') and (Left.Operation='x') and IsIntegerZero(Left.Value) then begin
      TempExpression:=Right;
      Right:=nil;
      FreeAndNil(Left);
      Operation:=TempExpression.Operation;
      Value:=TempExpression.Value;
      MetaValue:=TempExpression.MetaValue;
      MetaFlags:=TempExpression.MetaFlags;
      Left:=TempExpression.Left;
      Right:=TempExpression.Right;
      TempExpression.Operation:='x';
      TempExpression.Left:=nil;
      TempExpression.Right:=nil;
      TempExpression.Free;
      result:=true;
     end else if ((Operation in ['+','-','^','|','s','S']) and (Right.Operation='x') and IsIntegerZero(Right.Value)) or
                 ((Operation='/') and (Right.Operation='x') and IsIntegerOne(Right.Value)) then begin
      TempExpression:=Left;
      Left:=nil;
      Right.Free;
      Right:=nil;
      Operation:=TempExpression.Operation;
      Value:=TempExpression.Value;
      MetaValue:=TempExpression.MetaValue;
      MetaFlags:=TempExpression.MetaFlags;
      Left:=TempExpression.Left;
      Right:=TempExpression.Right;
      TempExpression.Operation:='x';
      TempExpression.Left:=nil;
      TempExpression.Right:=nil;
      TempExpression.Free;
      result:=true;
     end else if (Left.Operation='x') and (Right.Operation='x') then begin
      case Operation of
       '+':begin
        TerminateIt:=false;
        if (Left.Value.ValueType=AVT_INT) and (Right.Value.ValueType=AVT_INT) then begin
         GetMem(IntegerValue,SizeOf(TIntegerValue));
         try
          IntegerValueAdd(IntegerValue^,Left.Value.IntegerValue,Right.Value.IntegerValue);
          if IntegerValueIsZero(IntegerValue^) then begin
           TerminateIt:=true;
          end;
         finally
          FreeMem(IntegerValue);
         end;
        end;
       end;
       '-':begin
        TerminateIt:=Equals(Left.Value,Right.Value);
       end;
       '*','/','&':begin
        TerminateIt:=IsIntegerZero(Left.Value) or IsIntegerZero(Right.Value);
       end;
       '^':begin
        TerminateIt:=Equals(Left.Value,Right.Value);
       end;
       's':begin
        TerminateIt:=false;
        if (Left.Value.ValueType=AVT_INT) and (Right.Value.ValueType=AVT_INT) then begin
         GetMem(IntegerValue,SizeOf(TIntegerValue));
         try
          IntegerValueShiftLeft(IntegerValue^,Left.Value.IntegerValue,IntegerValueGetInt64(Right.Value.IntegerValue));
          if IntegerValueIsZero(IntegerValue^) then begin
           TerminateIt:=true;
          end;
         finally
          FreeMem(IntegerValue);
         end;
        end;
       end;
       'S':begin
        TerminateIt:=false;
        if (Left.Value.ValueType=AVT_INT) and (Right.Value.ValueType=AVT_INT) then begin
         GetMem(IntegerValue,SizeOf(TIntegerValue));
         try
          IntegerValueShiftRight(IntegerValue^,Left.Value.IntegerValue,IntegerValueGetInt64(Right.Value.IntegerValue));
          if IntegerValueIsZero(IntegerValue^) then begin
           TerminateIt:=true;
          end;
         finally
          FreeMem(IntegerValue);
         end;
        end;
       end;
       '=':begin
        TerminateIt:=not Equals(Left.Value,Right.Value);
       end;
       '>':begin
        TerminateIt:=false;
        if (Left.Value.ValueType=AVT_INT) and (Right.Value.ValueType=AVT_INT) then begin
         if not (IntegerValueCompare(Left.Value.IntegerValue,Right.Value.IntegerValue)>0) then begin
          TerminateIt:=true;
         end;
        end;
       end;
       '<':begin
        TerminateIt:=false;
        if (Left.Value.ValueType=AVT_INT) and (Right.Value.ValueType=AVT_INT) then begin
         if not (IntegerValueCompare(Left.Value.IntegerValue,Right.Value.IntegerValue)<0) then begin
          TerminateIt:=true;
         end;
        end;
       end;
       '}':begin
        TerminateIt:=false;
        if (Left.Value.ValueType=AVT_INT) and (Right.Value.ValueType=AVT_INT) then begin
         if not (IntegerValueCompare(Left.Value.IntegerValue,Right.Value.IntegerValue)>=0) then begin
          TerminateIt:=true;
         end;
        end;
       end;
       '{':begin
        TerminateIt:=false;
        if (Left.Value.ValueType=AVT_INT) and (Right.Value.ValueType=AVT_INT) then begin
         if not (IntegerValueCompare(Left.Value.IntegerValue,Right.Value.IntegerValue)<=0) then begin
          TerminateIt:=true;
         end;
        end;
       end;
       '#':begin
        TerminateIt:=Equals(Left.Value,Right.Value);
       end;
       else begin
        TerminateIt:=false;
       end;
      end;
      if TerminateIt then begin
       Operation:='x';
       Value.ValueType:=AVT_INT;
       IntegerValueSetQWord(Value.IntegerValue,0);
       Left.Free;
       Right.Free;
       Left:=nil;
       Right:=nil;
      end else begin
       OK:=true;
       case Operation of
        '+':begin
         if (Left.Value.ValueType=AVT_INT) and (Right.Value.ValueType=AVT_INT) then begin
          Value.ValueType:=AVT_INT;
          IntegerValueAdd(Value.IntegerValue,Left.Value.IntegerValue,Right.Value.IntegerValue);
         end else if (Left.Value.ValueType=AVT_FLOAT) and (Right.Value.ValueType=AVT_INT) then begin
          Value:=ValueOpAdd(ASMx86,Left.Value,Right.Value,true);
         end else if (Left.Value.ValueType=AVT_INT) and (Right.Value.ValueType=AVT_FLOAT) then begin
          Value:=ValueOpAdd(ASMx86,Left.Value,Right.Value,true);
         end else if (Left.Value.ValueType=AVT_FLOAT) and (Right.Value.ValueType=AVT_FLOAT) then begin
          Value:=ValueOpAdd(ASMx86,Left.Value,Right.Value,true);
         end else if (Left.Value.ValueType=AVT_STRING) and (Right.Value.ValueType=AVT_STRING) then begin
          Value.ValueType:=AVT_STRING;
          Value.StringValue:=Left.Value.StringValue+Right.Value.StringValue;
         end else begin
          OK:=false;
         end;
        end;
        '-':begin
         if (Left.Value.ValueType=AVT_INT) and (Right.Value.ValueType=AVT_INT) then begin
          Value.ValueType:=AVT_INT;
          IntegerValueSub(Value.IntegerValue,Left.Value.IntegerValue,Right.Value.IntegerValue);
         end else if (Left.Value.ValueType=AVT_FLOAT) and (Right.Value.ValueType=AVT_INT) then begin
          Value:=ValueOpSub(ASMx86,Left.Value,Right.Value,true);
         end else if (Left.Value.ValueType=AVT_INT) and (Right.Value.ValueType=AVT_FLOAT) then begin
          Value:=ValueOpSub(ASMx86,Left.Value,Right.Value,true);
         end else if (Left.Value.ValueType=AVT_FLOAT) and (Right.Value.ValueType=AVT_FLOAT) then begin
          Value:=ValueOpSub(ASMx86,Left.Value,Right.Value,true);
         end else begin
          OK:=false;
         end;
        end;
        '*':begin
         if (Left.Value.ValueType=AVT_INT) and (Right.Value.ValueType=AVT_INT) then begin
          Value.ValueType:=AVT_INT;
          IntegerValueMul(Value.IntegerValue,Left.Value.IntegerValue,Right.Value.IntegerValue);
         end else if (Left.Value.ValueType=AVT_FLOAT) and (Right.Value.ValueType=AVT_INT) then begin
          Value:=ValueOpMul(ASMx86,Left.Value,Right.Value,true);
         end else if (Left.Value.ValueType=AVT_INT) and (Right.Value.ValueType=AVT_FLOAT) then begin
          Value:=ValueOpMul(ASMx86,Left.Value,Right.Value,true);
         end else if (Left.Value.ValueType=AVT_FLOAT) and (Right.Value.ValueType=AVT_FLOAT) then begin
          Value:=ValueOpMul(ASMx86,Left.Value,Right.Value,true);
         end else begin
          OK:=false;
         end;
        end;
        '/':begin
         if (Left.Value.ValueType=AVT_INT) and (Right.Value.ValueType=AVT_INT) then begin
          Value.ValueType:=AVT_INT;
          if IntegerValueIsZero(Right.Value.IntegerValue) then begin
           IntegerValueSetQWord(Value.IntegerValue,0);
          end else begin
           IntegerValueDiv(Value.IntegerValue,Left.Value.IntegerValue,Right.Value.IntegerValue);
          end;
         end else if (Left.Value.ValueType=AVT_FLOAT) and (Right.Value.ValueType=AVT_INT) then begin
          Value:=ValueOpDiv(ASMx86,Left.Value,Right.Value,true);
         end else if (Left.Value.ValueType=AVT_INT) and (Right.Value.ValueType=AVT_FLOAT) then begin
          Value:=ValueOpDiv(ASMx86,Left.Value,Right.Value,true);
         end else if (Left.Value.ValueType=AVT_FLOAT) and (Right.Value.ValueType=AVT_FLOAT) then begin
          Value:=ValueOpDiv(ASMx86,Left.Value,Right.Value,true);
         end else begin
          OK:=false;
         end;
        end;
        '^':begin
         if (Left.Value.ValueType=AVT_INT) and (Right.Value.ValueType=AVT_INT) then begin
          Value.ValueType:=AVT_INT;
          IntegerValueXOR(Value.IntegerValue,Left.Value.IntegerValue,Right.Value.IntegerValue);
         end else begin
          OK:=false;
         end;
        end;
        '&':begin
         if (Left.Value.ValueType=AVT_INT) and (Right.Value.ValueType=AVT_INT) then begin
          Value.ValueType:=AVT_INT;
          IntegerValueAND(Value.IntegerValue,Left.Value.IntegerValue,Right.Value.IntegerValue);
         end else begin
          OK:=false;
         end;
        end;
        '|':begin
         if (Left.Value.ValueType=AVT_INT) and (Right.Value.ValueType=AVT_INT) then begin
          Value.ValueType:=AVT_INT;
          IntegerValueOR(Value.IntegerValue,Left.Value.IntegerValue,Right.Value.IntegerValue);
         end else begin
          OK:=false;
         end;
        end;
        's':begin
         if (Left.Value.ValueType=AVT_INT) and (Right.Value.ValueType=AVT_INT) then begin
          Value.ValueType:=AVT_INT;
          IntegerValueShiftLeft(Value.IntegerValue,Left.Value.IntegerValue,IntegerValueGetInt64(Right.Value.IntegerValue));
         end else begin
          OK:=false;
         end;
        end;
        'S':begin
         if (Left.Value.ValueType=AVT_INT) and (Right.Value.ValueType=AVT_INT) then begin
          Value.ValueType:=AVT_INT;
          IntegerValueShiftRight(Value.IntegerValue,Left.Value.IntegerValue,IntegerValueGetInt64(Right.Value.IntegerValue));
         end else begin
          OK:=false;
         end;
        end;
        '=':begin
         if (Left.Value.ValueType=AVT_INT) and (Right.Value.ValueType=AVT_INT) then begin
          Value.ValueType:=AVT_INT;
          if IntegerValueCompare(Left.Value.IntegerValue,Right.Value.IntegerValue)=0 then begin
           IntegerValueSetQWord(Value.IntegerValue,1);
          end else begin
           IntegerValueSetQWord(Value.IntegerValue,0);
          end;
         end else begin
          OK:=false;
         end;
        end;
        '>':begin
         if (Left.Value.ValueType=AVT_INT) and (Right.Value.ValueType=AVT_INT) then begin
          Value.ValueType:=AVT_INT;
          if IntegerValueCompare(Left.Value.IntegerValue,Right.Value.IntegerValue)>0 then begin
           IntegerValueSetQWord(Value.IntegerValue,1);
          end else begin
           IntegerValueSetQWord(Value.IntegerValue,0);
          end;
         end else begin
          OK:=false;
         end;
        end;
        '<':begin
         if (Left.Value.ValueType=AVT_INT) and (Right.Value.ValueType=AVT_INT) then begin
          Value.ValueType:=AVT_INT;
          if IntegerValueCompare(Left.Value.IntegerValue,Right.Value.IntegerValue)<0 then begin
           IntegerValueSetQWord(Value.IntegerValue,1);
          end else begin
           IntegerValueSetQWord(Value.IntegerValue,0);
          end;
         end else begin
          OK:=false;
         end;
        end;
        '}':begin
         if (Left.Value.ValueType=AVT_INT) and (Right.Value.ValueType=AVT_INT) then begin
          Value.ValueType:=AVT_INT;
          if IntegerValueCompare(Left.Value.IntegerValue,Right.Value.IntegerValue)>=0 then begin
           IntegerValueSetQWord(Value.IntegerValue,1);
          end else begin
           IntegerValueSetQWord(Value.IntegerValue,0);
          end;
         end else begin
          OK:=false;
         end;
        end;
        '{':begin
         if (Left.Value.ValueType=AVT_INT) and (Right.Value.ValueType=AVT_INT) then begin
          Value.ValueType:=AVT_INT;
          if IntegerValueCompare(Left.Value.IntegerValue,Right.Value.IntegerValue)<=0 then begin
           IntegerValueSetQWord(Value.IntegerValue,1);
          end else begin
           IntegerValueSetQWord(Value.IntegerValue,0);
          end;
         end else begin
          OK:=false;
         end;
        end;
        '#':begin
         if (Left.Value.ValueType=AVT_INT) and (Right.Value.ValueType=AVT_INT) then begin
          Value.ValueType:=AVT_INT;
          if IntegerValueCompare(Left.Value.IntegerValue,Right.Value.IntegerValue)<>0 then begin
           IntegerValueSetQWord(Value.IntegerValue,1);
          end else begin
           IntegerValueSetQWord(Value.IntegerValue,0);
          end;
         end else begin
          OK:=false;
         end;
        end;
        else begin
         OK:=false;
        end;
       end;
       if OK then begin
        Operation:='x';
        FreeAndNil(Left);
        FreeAndNil(Right);
       end else begin
        result:=false;
        exit;
       end;
      end;
      result:=true;
     end else if (Left.Operation='r') and (Right.Operation='r') then begin
      case Operation of
       '-':begin
        TerminateIt:=Left.MetaValue=Right.MetaValue;
       end;
       '^':begin
        TerminateIt:=Left.MetaValue=Right.MetaValue;
       end;
       else begin
        TerminateIt:=false;
       end;
      end;
      if TerminateIt then begin
       Operation:='x';
       Value.ValueType:=AVT_INT;
       IntegerValueSetQWord(Value.IntegerValue,0);
       MetaValue:=0;
       MetaFlags:=0;
       FreeAndNil(Left);
       FreeAndNil(Right);
       result:=true;
      end;
     end;
    end;
   end;
   'o':begin
    if assigned(Left) and not assigned(Right) then begin
     TempExpression:=Left;
     Operation:=TempExpression.Operation;
     Value:=TempExpression.Value;
     MetaValue:=TempExpression.MetaValue;
     MetaFlags:=TempExpression.MetaFlags;
     Left:=TempExpression.Left;
     Right:=TempExpression.Right;
     TempExpression.Operation:='x';
     TempExpression.Left:=nil;
     TempExpression.Right:=nil;
     TempExpression.Free;
     result:=true;
    end;
   end;
   'm':begin
    if assigned(Left) and not assigned(Right) then begin
     if Left.Operation='m' then begin
      TempExpression:=Left;
      Operation:=TempExpression.Operation;
      Value:=TempExpression.Value;
      MetaValue:=TempExpression.MetaValue;
      MetaFlags:=TempExpression.MetaFlags;
      Left:=TempExpression.Left;
      Right:=TempExpression.Right;
      TempExpression.Operation:='x';
      TempExpression.Left:=nil;
      TempExpression.Right:=nil;
      TempExpression.Free;
      result:=true;
     end;
    end;
   end;
   'T':begin
    if assigned(Left) and (Left.Operation='x') and not assigned(Right) then begin
     case Left.Value.ValueType of
      AVT_INT:begin
       Operation:='x';
       Value.ValueType:=AVT_STRING;
       Value.StringValue:=IntegerValueToStr(Left.Value.IntegerValue);
       FreeAndNil(Left);
      end;
      AVT_FLOAT:begin
       Operation:='x';
       Value.ValueType:=AVT_STRING;
       case Left.Value.FloatValue.Count of
        1:begin
         Value.StringValue:=FloatToRawString(Left.Value.FloatValue.Bytes[0],IEEEFormat8);
        end;
        2:begin
         Value.StringValue:=FloatToRawString(Left.Value.FloatValue.Bytes[0],IEEEFormat16);
        end;
        4:begin
         Value.StringValue:=FloatToRawString(Left.Value.FloatValue.Bytes[0],IEEEFormat32);
        end;
        8:begin
         Value.StringValue:=FloatToRawString(Left.Value.FloatValue.Bytes[0],IEEEFormat64);
        end;
        10:begin
         Value.StringValue:=FloatToRawString(Left.Value.FloatValue.Bytes[0],IEEEFormat80);
        end;
        16:begin
         Value.StringValue:=FloatToRawString(Left.Value.FloatValue.Bytes[0],IEEEFormat128);
        end;
        32:begin
         Value.StringValue:=FloatToRawString(Left.Value.FloatValue.Bytes[0],IEEEFormat256);
        end;
        64:begin
         Value.StringValue:=FloatToRawString(Left.Value.FloatValue.Bytes[0],IEEEFormat512);
        end;
        else begin
         ASMx86.MakeError(71);
        end;
       end;
       FreeAndNil(Left);
      end;
      AVT_STRING:begin
       Operation:='x';
       Value:=Left.Value;
       FreeAndNil(Left);
      end;
     end;
    end;
   end;
   'i':begin
    if assigned(Left) and (Left.Operation='x') and not assigned(Right) then begin
     case Left.Value.ValueType of
      AVT_INT:begin
       Operation:='x';
       Value:=Left.Value;
       FreeAndNil(Left);
      end;
      AVT_FLOAT:begin
       case Left.Value.FloatValue.Count of
        1:begin
         s:=FloatToRawString(Left.Value.FloatValue,IEEEFormat8);
        end;
        2:begin
         s:=FloatToRawString(Left.Value.FloatValue,IEEEFormat16);
        end;
        4:begin
         s:=FloatToRawString(Left.Value.FloatValue,IEEEFormat32);
        end;
        8:begin
         s:=FloatToRawString(Left.Value.FloatValue,IEEEFormat64);
        end;
        10:begin
         s:=FloatToRawString(Left.Value.FloatValue,IEEEFormat80);
        end;
        16:begin
         s:=FloatToRawString(Left.Value.FloatValue,IEEEFormat128);
        end;
        32:begin
         s:=FloatToRawString(Left.Value.FloatValue,IEEEFormat256);
        end;
        64:begin
         s:=FloatToRawString(Left.Value.FloatValue,IEEEFormat512);
        end;
        else begin
         ASMx86.MakeError(71);
        end;
       end;
       StringToFloat(s,Value.FloatValue.Bytes[0],IEEEFormat64);
       Operation:='x';
       Value.ValueType:=AVT_INT;
       IntegerValueSetInt64(Value.IntegerValue,trunc(double(pointer(@Value.FloatValue.Bytes[0])^)));
       FreeAndNil(Left);
      end;
      AVT_STRING:begin
       Operation:='x';
       Value.ValueType:=AVT_INT;
       IntegerValueParse(Value.IntegerValue,Left.Value.StringValue,1);
       FreeAndNil(Left);
      end;
     end;
    end;
   end;
   'I':begin
    if assigned(Left) and (Left.Operation='x') and not assigned(Right) then begin
     case Left.Value.ValueType of
      AVT_INT:begin
       Operation:='x';
       Value:=Left.Value;
       FreeAndNil(Left);
      end;
      AVT_FLOAT:begin
       Operation:='x';
       Value.ValueType:=AVT_INT;
       IntegerValueSetQWord(Value.IntegerValue,0);
       Move(Left.Value.FloatValue.Bytes[0],Value.IntegerValue[0],Left.Value.FloatValue.Count);
       FreeAndNil(Left);
      end;
      AVT_STRING:begin
       GetMem(IntegerValue,SizeOf(TIntegerValue));
       GetMem(OtherIntegerValue,SizeOf(TIntegerValue));
       try
        Operation:='x';
        Value.ValueType:=AVT_INT;
        FillChar(Value.IntegerValue,SizeOf(TIntegerValue),#0);
        Counter:=length(Left.Value.StringValue);
        while Counter>0 do begin
         IntegerValueShiftLeftInternal(IntegerValue^,Value.IntegerValue,8);
         IntegerValueSetQWord(OtherIntegerValue^,byte(ansichar(Left.Value.StringValue[(length(Left.Value.StringValue)-Counter)+1])));
         IntegerValueOr(Value.IntegerValue,IntegerValue^,OtherIntegerValue^);
         dec(Counter);
        end;
        FreeAndNil(Left);
       finally
        FreeMem(OtherIntegerValue);
        FreeMem(IntegerValue);
       end;
      end;
     end;
    end;
   end;
   'f':begin
    if assigned(Left) and (Left.Operation='x') and not assigned(Right) then begin
     case Left.Value.ValueType of
      AVT_INT:begin
       try
        s:=IntegerValueToStr(Left.Value.IntegerValue);
        case MetaValue of
         8:begin
          Operation:='x';
          FreeAndNil(Left);
          Value.ValueType:=AVT_FLOAT;
          StringToFloat(s,Value.FloatValue.Bytes[0],IEEEFormat8);
          Value.FloatValue.Count:=IEEEFormat8.Bytes;
         end;
         16:begin
          Operation:='x';
          FreeAndNil(Left);
          Value.ValueType:=AVT_FLOAT;
          StringToFloat(s,Value.FloatValue.Bytes[0],IEEEFormat16);
          Value.FloatValue.Count:=IEEEFormat16.Bytes;
         end;
         32:begin
          Operation:='x';
          FreeAndNil(Left);
          Value.ValueType:=AVT_FLOAT;
          StringToFloat(s,Value.FloatValue.Bytes[0],IEEEFormat32);
          Value.FloatValue.Count:=IEEEFormat32.Bytes;
         end;
         64:begin
          Operation:='x';
          FreeAndNil(Left);
          Value.ValueType:=AVT_FLOAT;
          StringToFloat(s,Value.FloatValue.Bytes[0],IEEEFormat64);
          Value.FloatValue.Count:=IEEEFormat64.Bytes;
         end;
         80:begin
          Operation:='x';
          FreeAndNil(Left);
          Value.ValueType:=AVT_FLOAT;
          StringToFloat(s,Value.FloatValue.Bytes[0],IEEEFormat80);
          Value.FloatValue.Count:=IEEEFormat80.Bytes;
         end;
         128:begin
          Operation:='x';
          FreeAndNil(Left);
          Value.ValueType:=AVT_FLOAT;
          StringToFloat(s,Value.FloatValue.Bytes[0],IEEEFormat128);
          Value.FloatValue.Count:=IEEEFormat128.Bytes;
         end;
         256:begin
          Operation:='x';
          FreeAndNil(Left);
          Value.ValueType:=AVT_FLOAT;
          StringToFloat(s,Value.FloatValue.Bytes[0],IEEEFormat256);
          Value.FloatValue.Count:=IEEEFormat256.Bytes;
         end;
         512:begin
          Operation:='x';
          FreeAndNil(Left);
          Value.ValueType:=AVT_FLOAT;
          StringToFloat(s,Value.FloatValue.Bytes[0],IEEEFormat512);
          Value.FloatValue.Count:=IEEEFormat512.Bytes;
         end;
        end;
       except
        on e:Exception do begin
         ASMx86.MakeError(e.Message);
        end;
       end;
      end;
      AVT_FLOAT:begin
       case Left.Value.FloatValue.Count of
        1,2,4,8,10,16,32,64:begin
         try
          if MetaValue=(Left.Value.FloatValue.Count shl 8) then begin
           Operation:='x';
           Value:=Left.Value;
           FreeAndNil(Left);
          end else begin
           case Left.Value.FloatValue.Count of
            1:begin
             s:=FloatToRawString(Left.Value.FloatValue,IEEEFormat8);
            end;
            2:begin
             s:=FloatToRawString(Left.Value.FloatValue,IEEEFormat16);
            end;
            4:begin
             s:=FloatToRawString(Left.Value.FloatValue,IEEEFormat32);
            end;
            8:begin
             s:=FloatToRawString(Left.Value.FloatValue,IEEEFormat64);
            end;
            10:begin
             s:=FloatToRawString(Left.Value.FloatValue,IEEEFormat80);
            end;
            16:begin
             s:=FloatToRawString(Left.Value.FloatValue,IEEEFormat128);
            end;
            32:begin
             s:=FloatToRawString(Left.Value.FloatValue,IEEEFormat256);
            end;
            64:begin
             s:=FloatToRawString(Left.Value.FloatValue,IEEEFormat512);
            end;
            else begin
             ASMx86.MakeError(71);
            end;
           end;
           case MetaValue of
            8:begin
             Operation:='x';
             FreeAndNil(Left);
             Value.ValueType:=AVT_FLOAT;
             StringToFloat(s,Value.FloatValue.Bytes[0],IEEEFormat8);
             Value.FloatValue.Count:=IEEEFormat8.Bytes;
            end;
            16:begin
             Operation:='x';
             FreeAndNil(Left);
             Value.ValueType:=AVT_FLOAT;
             StringToFloat(s,Value.FloatValue.Bytes[0],IEEEFormat16);
             Value.FloatValue.Count:=IEEEFormat16.Bytes;
            end;
            32:begin
             Operation:='x';
             FreeAndNil(Left);
             Value.ValueType:=AVT_FLOAT;
             StringToFloat(s,Value.FloatValue.Bytes[0],IEEEFormat32);
             Value.FloatValue.Count:=IEEEFormat32.Bytes;
            end;
            64:begin
             Operation:='x';
             FreeAndNil(Left);
             Value.ValueType:=AVT_FLOAT;
             StringToFloat(s,Value.FloatValue.Bytes[0],IEEEFormat64);
             Value.FloatValue.Count:=IEEEFormat64.Bytes;
            end;
            80:begin
             Operation:='x';
             FreeAndNil(Left);
             Value.ValueType:=AVT_FLOAT;
             StringToFloat(s,Value.FloatValue.Bytes[0],IEEEFormat80);
             Value.FloatValue.Count:=IEEEFormat80.Bytes;
            end;
            128:begin
             Operation:='x';
             FreeAndNil(Left);
             Value.ValueType:=AVT_FLOAT;
             StringToFloat(s,Value.FloatValue.Bytes[0],IEEEFormat128);
             Value.FloatValue.Count:=IEEEFormat128.Bytes;
            end;
            256:begin
             Operation:='x';
             FreeAndNil(Left);
             Value.ValueType:=AVT_FLOAT;
             StringToFloat(s,Value.FloatValue.Bytes[0],IEEEFormat256);
             Value.FloatValue.Count:=IEEEFormat256.Bytes;
            end;
            512:begin
             Operation:='x';
             FreeAndNil(Left);
             Value.ValueType:=AVT_FLOAT;
             StringToFloat(s,Value.FloatValue.Bytes[0],IEEEFormat512);
             Value.FloatValue.Count:=IEEEFormat512.Bytes;
            end;
            else begin
             ASMx86.MakeError(71);
            end;
           end;
          end;
         except
          on e:Exception do begin
           ASMx86.MakeError(e.Message);
          end;
         end;
        end;
        else begin
         ASMx86.MakeError(71);
        end;
       end;
      end;
      AVT_STRING:begin
       try
        s:=Left.Value.StringValue;
        case MetaValue of
         8:begin
          Operation:='x';
          FreeAndNil(Left);
          Value.ValueType:=AVT_FLOAT;
          StringToFloat(s,Value.FloatValue.Bytes[0],IEEEFormat8);
          Value.FloatValue.Count:=IEEEFormat8.Bytes;
         end;
         16:begin
          Operation:='x';
          FreeAndNil(Left);
          Value.ValueType:=AVT_FLOAT;
          StringToFloat(s,Value.FloatValue.Bytes[0],IEEEFormat16);
          Value.FloatValue.Count:=IEEEFormat16.Bytes;
         end;
         32:begin
          Operation:='x';
          FreeAndNil(Left);
          Value.ValueType:=AVT_FLOAT;
          StringToFloat(s,Value.FloatValue.Bytes[0],IEEEFormat32);
          Value.FloatValue.Count:=IEEEFormat32.Bytes;
         end;
         64:begin
          Operation:='x';
          FreeAndNil(Left);
          Value.ValueType:=AVT_FLOAT;
          StringToFloat(s,Value.FloatValue.Bytes[0],IEEEFormat64);
          Value.FloatValue.Count:=IEEEFormat64.Bytes;
         end;
         80:begin
          Operation:='x';
          FreeAndNil(Left);
          Value.ValueType:=AVT_FLOAT;
          StringToFloat(s,Value.FloatValue.Bytes[0],IEEEFormat80);
          Value.FloatValue.Count:=IEEEFormat80.Bytes;
         end;
         128:begin
          Operation:='x';
          FreeAndNil(Left);
          Value.ValueType:=AVT_FLOAT;
          StringToFloat(s,Value.FloatValue.Bytes[0],IEEEFormat128);
          Value.FloatValue.Count:=IEEEFormat128.Bytes;
         end;
         256:begin
          Operation:='x';
          FreeAndNil(Left);
          Value.ValueType:=AVT_FLOAT;
          StringToFloat(s,Value.FloatValue.Bytes[0],IEEEFormat256);
          Value.FloatValue.Count:=IEEEFormat256.Bytes;
         end;
         512:begin
          Operation:='x';
          FreeAndNil(Left);
          Value.ValueType:=AVT_FLOAT;
          StringToFloat(s,Value.FloatValue.Bytes[0],IEEEFormat512);
          Value.FloatValue.Count:=IEEEFormat512.Bytes;
         end;
         else begin
          ASMx86.MakeError(71);
         end;
        end;
       except
        on e:Exception do begin
         ASMx86.MakeError(e.Message);
        end;
       end;
      end;
     end;
    end;
   end;
   '!','_','(':begin
    if assigned(Left) and not assigned(Right) then begin
     if Left.Operation='x' then begin
      Value:=Left.Value;
      case Operation of
       '!':begin
        Value:=ValueOpNOT(ASMx86,Value,true);
       end;
       '_':begin
        Value:=ValueOpNeg(ASMx86,Value,true);
       end;
      end;
      Operation:='x';
      Left.Free;
      Left:=nil;
      result:=true;
     end else if (Left.Operation in ['r','v']) and (Operation='(') then begin
      Operation:=Left.Operation;
      Value:=Left.Value;
      MetaValue:=Left.MetaValue;
      MetaFlags:=Left.MetaFlags;
      Left.Free;
      Left:=nil;
      result:=true;
     end else if (Left.Operation in ['+','-','*','/','^','|','&','l','L']) and (Operation='(') then begin
      TempExpression:=Left;
      Operation:=TempExpression.Operation;
      Value:=TempExpression.Value;
      MetaValue:=TempExpression.MetaValue;
      MetaFlags:=TempExpression.MetaFlags;
      Left:=TempExpression.Left;
      Right:=TempExpression.Right;
      TempExpression.Operation:='x';
      TempExpression.Left:=nil;
      TempExpression.Right:=nil;
      TempExpression.Free;
      result:=true;
     end else if Operation='(' then begin
      TempExpression:=Left;
      Left:=nil;
      Assign(TempExpression);
      TempExpression.Free;
      result:=true;
     end;
    end;
   end;
  end;
 end;
end;

function TAssemblerExpression.UseIt(ASMx86:TAssembler):boolean;
begin
 result:=false;
 if assigned(self) then begin
  if assigned(Left) then begin
   if Left.Optimize(ASMx86) then begin
    result:=true;
   end;
  end;
  if assigned(Right) then begin
   if Right.Optimize(ASMx86) then begin
    result:=true;
   end;
  end;
  if assigned(SecondRight) then begin
   if SecondRight.Optimize(ASMx86) then begin
    result:=true;
   end;
  end;
  if (Operation='v') and (MetaValue>=0) and (MetaValue<ASMx86.UserSymbolList.Count) then begin
   TUserSymbol(ASMx86.UserSymbolList[MetaValue]).UseIt(ASMx86);
  end;
 end;
end;

function TAssemblerExpression.HasOperation(AOperationSet:TCharSet):boolean;
begin
 result:=Operation in AOperationSet;
 if result then begin
  exit;
 end;
 if assigned(Left) then begin
  result:=Left.HasOperation(AOperationSet);
  if result then begin
   exit;
  end;
 end;
 if assigned(Right) then begin
  result:=Right.HasOperation(AOperationSet);
  if result then begin
   exit;
  end;
 end;
 if assigned(SecondRight) then begin
  result:=SecondRight.HasOperation(AOperationSet);
  if result then begin
   exit;
  end;
 end;
end;

function TAssemblerExpression.GetFixUpExpressionFlags(const ASMx86:TAssembler):TFixUpExpressionFlags;
begin
 result:=0;
 case Operation of
  'k':begin
   case MetaValue of
    KeySEG16:begin
     result:=result or FUEF_SEG16;
    end;
    KeyOFS16:begin
     result:=result or FUEF_OFS16;
    end;
    Key__NOBASE__:begin
     result:=result or FUEF_NOBASE;
    end;
    Key__GOT__:begin
     result:=result or FUEF_GOT;
    end;
    Key__GOTPC__:begin
     result:=result or FUEF_GOTPC;
    end;
    Key__GOTOFF__:begin
     result:=result or FUEF_GOTOFF;
    end;
    Key__GOTTPOFF__:begin
     result:=result or FUEF_GOTTPOFF;
    end;
    Key__PLT__:begin
     result:=result or FUEF_PLT;
    end;
    Key__TLSIE__:begin
     result:=result or FUEF_TLSIE;
    end;
    Key__RELOCATION__:begin
     result:=result or FUEF_RELOCATION;
    end;
   end;
  end;
 end;
 if assigned(Left) then begin
  result:=result or Left.GetFixUpExpressionFlags(ASMx86);
 end;
 if assigned(Right) then begin
  result:=result or Right.GetFixUpExpressionFlags(ASMx86);
 end;
 if assigned(SecondRight) then begin
  result:=result or SecondRight.GetFixUpExpressionFlags(ASMx86);
 end;
end;

function TAssemblerExpression.HasFixUpSymbolReference(const ASMx86:TAssembler):boolean;
var Symbol:TUserSymbol;
begin
 result:=false;
 case Operation of
  'v':begin
   if ((MetaFlags and nvfNORELOCATION)=0) and ((MetaValue>=0) and (MetaValue<ASMx86.UserSymbolList.Count)) then begin
    Symbol:=ASMx86.UserSymbolList[MetaValue];
    case Symbol.SymbolType of
     ustLABEL,ustIMPORT,ustSEGMENT:begin
      result:=true;
     end;
     ustVARIABLE:begin
     end;
    end;
   end;
  end;
 end;
 if result then begin
  exit;
 end;
 if assigned(Left) then begin
  result:=Left.HasFixUpSymbolReference(ASMx86);
  if result then begin
   exit;
  end;
 end;
 if assigned(Right) then begin
  result:=Right.HasFixUpSymbolReference(ASMx86);
  if result then begin
   exit;
  end;
 end;
 if assigned(SecondRight) then begin
  result:=SecondRight.HasFixUpSymbolReference(ASMx86);
  if result then begin
   exit;
  end;
 end;
end;

function TAssemblerExpression.IsConstant(const ASMx86:TAssembler):boolean;
var Symbol:TUserSymbol;
begin
 case Operation of
  'v':begin
   if (MetaValue>=0) and (MetaValue<ASMx86.UserSymbolList.Count) then begin
    Symbol:=ASMx86.UserSymbolList[MetaValue];
    case Symbol.SymbolType of
     ustLABEL,ustIMPORT,ustSEGMENT:begin
      result:=false;
     end;
     else begin
      result:=true;
     end;
    end;
   end else begin
    result:=true;
   end;
  end;
  else begin
   result:=true;
  end;
 end;
 if not result then begin
  exit;
 end;
 if assigned(Left) then begin
  result:=Left.IsConstant(ASMx86);
  if not result then begin
   exit;
  end;
 end;
 if assigned(Right) then begin
  result:=Right.IsConstant(ASMx86);
  if not result then begin
   exit;
  end;
 end;
 if assigned(SecondRight) then begin
  result:=SecondRight.IsConstant(ASMx86);
  if not result then begin
   exit;
  end;
 end;
end;

function TAssemblerExpression.GetFixUpSymbol(const ASMx86:TAssembler):TUserSymbol;
var Symbol:TUserSymbol;
begin
 result:=nil;
 case Operation of
  'v':begin
   if ((MetaFlags and nvfNORELOCATION)=0) and ((MetaValue>=0) and (MetaValue<ASMx86.UserSymbolList.Count)) then begin
    Symbol:=ASMx86.UserSymbolList[MetaValue];
    case Symbol.SymbolType of
     ustLABEL,ustIMPORT:begin
      result:=Symbol;
     end;
    end;
   end;
  end;
 end;
 if assigned(result) then begin
  exit;
 end;
 if assigned(Left) then begin
  result:=Left.GetFixUpSymbol(ASMx86);
  if assigned(result) then begin
   exit;
  end;
 end;
 if assigned(Right) then begin
  result:=Right.GetFixUpSymbol(ASMx86);
  if assigned(result) then begin
   exit;
  end;
 end;
 if assigned(SecondRight) then begin
  result:=SecondRight.GetFixUpSymbol(ASMx86);
  if assigned(result) then begin
   exit;
  end;
 end;
end;

function TAssemblerExpression.HasValueType(const ASMx86:TAssembler;const ValueType:longint;const Level:longint=0):boolean;
var Symbol:TUserSymbol;
begin
 if Level>8 then begin
  result:=false;
  exit;
 end;
 case Operation of
  'x':begin
   result:=Value.ValueType=ValueType;
  end;
  'v':begin
   if (MetaValue>=0) and (MetaValue<ASMx86.UserSymbolList.Count) then begin
    Symbol:=ASMx86.UserSymbolList[MetaValue];
    case Symbol.SymbolType of
     ustVARIABLE:begin 
      if Symbol.Value.ValueType=ValueType then begin
       result:=true;
      end else begin
       result:=false;
      end;
     end;
     ustREPLACER:begin
      if Symbol.Value.ValueType=ValueType then begin
       result:=true;
      end else if assigned(Symbol.Expression) then begin
       result:=Symbol.Expression.HasValueType(ASMx86,ValueType,Level+1);
      end else begin
       result:=false;
      end;
     end;
     else begin
      result:=false;
     end;
    end;
   end else begin
    result:=false;
   end;
  end;
  else begin
   result:=false;
  end;
 end;
 if result then begin
  exit;
 end;
 if assigned(Left) then begin
  result:=Left.HasValueType(ASMx86,ValueType,Level);
  if result then begin
   exit;
  end;
 end;
 if assigned(Right) then begin
  result:=Right.HasValueType(ASMx86,ValueType,Level);
  if result then begin
   exit;
  end;
 end;
 if assigned(SecondRight) then begin
  result:=SecondRight.HasValueType(ASMx86,ValueType,Level);
  if result then begin
   exit;
  end;
 end;
end;

function TAssemblerExpression.IsInteger(const ASMx86:TAssembler):boolean;
begin
 result:=not (HasValueType(ASMx86,AVT_FLOAT) or HasValueType(ASMx86,AVT_STRING));
end;

function TAssemblerExpression.Equals(const WithExpression:TAssemblerExpression):boolean;
var i:longint;
begin
 if assigned(WithExpression) then begin

  result:=Operation=WithExpression.Operation;
  if not result then begin
   exit;
  end;

  result:=Value.ValueType=WithExpression.Value.ValueType;
  if not result then begin
   exit;
  end;
  case Value.ValueType of
   AVT_INT:begin
    result:=IntegerValueEquals(Value.IntegerValue,WithExpression.Value.IntegerValue);
    if not result then begin
     exit;
    end;
   end;
   AVT_FLOAT:begin
    result:=Value.FloatValue.Count=WithExpression.Value.FloatValue.Count;
    if not result then begin
     exit;
    end;
    for i:=0 to Value.FloatValue.Count-1 do begin
     if Value.FloatValue.Bytes[i]<>WithExpression.Value.FloatValue.Bytes[i] then begin
      result:=false;
      exit;
     end;
    end;
   end;
   AVT_STRING:begin
    result:=Value.StringValue=WithExpression.Value.StringValue;
    if not result then begin
     exit;
    end;
   end;
  end;

  result:=MetaValue=WithExpression.MetaValue;
  if not result then begin
   exit;
  end;

  result:=MetaFlags=WithExpression.MetaFlags;
  if not result then begin
   exit;
  end;

  result:=(assigned(Left)=assigned(WithExpression.Left)) and
          (assigned(Right)=assigned(WithExpression.Right)) and
          (assigned(SecondRight)=assigned(WithExpression.SecondRight));
  if not result then begin
   exit;
  end;

  if assigned(Left) then begin
   result:=Left.Equals(WithExpression.Left);
   if not result then begin
    exit;
   end;
  end;

  if assigned(Right) then begin
   result:=Right.Equals(WithExpression.Right);
   if not result then begin
    exit;
   end;
  end;

  if assigned(SecondRight) then begin
   result:=SecondRight.Equals(WithExpression.SecondRight);
   if not result then begin
    exit;
   end;
  end;

 end else begin
  result:=false;
 end;
end;

function TAssemblerExpression.Has(const Expression:TAssemblerExpression):boolean;
begin
 if assigned(Expression) then begin
  result:=Equals(Expression) or
          (assigned(Left) and Left.Has(Expression)) or
          (assigned(Right) and Right.Has(Expression)) or
          (assigned(SecondRight) and SecondRight.Has(Expression));
 end else begin
  result:=false;
 end;
end;

procedure TAssemblerExpression.MarkAsNoRelocation;
begin
 case Operation of
  'v':begin
   MetaFlags:=MetaFlags or nvfNORELOCATION;
  end;
 end;
 if assigned(Left) then begin
  Left.MarkAsNoRelocation;
 end;
 if assigned(Right) then begin
  Right.MarkAsNoRelocation;
 end;
 if assigned(SecondRight) then begin
  SecondRight.MarkAsNoRelocation;
 end;
end;

constructor TAssemblerImportLibraryItem.Create;
begin
 inherited Create;
 Name:='';
 NameAddr:=0;
 OrgImportsAddr:=0;
 ImportsAddr:=0;
 Handle:=0;
 Used:=false;
end;

destructor TAssemblerImportLibraryItem.Destroy;
begin
 Name:='';
 if Handle<>0 then begin
{$ifdef WIN32}
  try
   FreeLibrary(Handle);
  except
  end;
  Handle:=0;
{$else}
{$ifdef UNIX}
  try
   FreeLibrary(Handle);
  except
  end;
  Handle:=0;
{$endif}
{$endif}
 end;
 inherited Destroy;
end;

constructor TAssemblerImportItem.Create;
begin
 inherited Create;
 Name:='';
 NameAddr:=0;
 ProcAddr:=0;
 ImportLibrary:=nil;
 Used:=false;
 Symbol:=nil;
end;

destructor TAssemblerImportItem.Destroy;
begin
 Name:='';
 if assigned(Symbol) then begin
  Symbol.ImportItem:=nil;
 end;
 inherited Destroy;
end;

constructor TUserSymbol.Create(AName,AOriginalName:ansistring);
begin
 inherited Create;
 SymbolType:=ustNONE;
 Name:=AName;
 OriginalName:=AOriginalName;
 Content:='';
 MultiLine:=false;
 VA_ARGS:=false;
 CountParameters:=0;
 CountLocals:=0;
 Expression:=nil;
 Segment:=nil;
 Section:=nil;
 Position:=0;
 Value.ValueType:=AVT_NONE;
 IntegerValueSetQWord(Value.IntegerValue,0);
 HasPosition:=false;
 ImportItem:=nil;
 ExportItem:=nil;
 Used:=false;
 NeedSymbol:=false;
 Defined:=false;
 IsExternal:=false;
 IsPublic:=false;
{$ifdef SASMBESEN}
 BESENObject:=nil;
{$endif}
 SymbolIndex:=-1;
 ObjectSymbolIndex:=-1;
end;

destructor TUserSymbol.Destroy;
//var Counter:longint;
begin
 Name:='';
 OriginalName:='';
 Content:='';
 Expression.Free;
{$ifdef SASMBESEN}
 BESENObject:=nil;
{$endif}
 inherited Destroy;
end;

procedure TUserSymbol.Calculate(ASMx86:TAssembler;AExpression:TAssemblerExpression);
begin
 case SymbolType of
  ustVARIABLE,ustREPLACER,ustCONSTANTSTRUCT:begin
   if assigned(AExpression) then begin
    Value:=AExpression.Evaluate(ASMx86);
   end; 
  end;
 end;
end;

function TUserSymbol.GetValue(ASMx86:TAssembler):TAssemblerValue;
begin
 UseIt(ASMx86);
 case SymbolType of
  ustNONE:begin
   result.ValueType:=AVT_INT;
   IntegerValueSetQWord(result.IntegerValue,0);
  end;
  ustLABEL:begin
   result.ValueType:=AVT_INT;
   IntegerValueSetQWord(result.IntegerValue,Position);
  end;
  ustSEGMENT:begin
   if assigned(Segment) then begin
    result.ValueType:=AVT_INT;
    IntegerValueSetQWord(result.IntegerValue,Segment^.Position);
   end else begin
    result.ValueType:=AVT_INT;
    IntegerValueSetQWord(result.IntegerValue,0);
   end;
  end;
  ustIMPORT:begin
   result.ValueType:=AVT_INT;
   IntegerValueSetQWord(result.IntegerValue,Position);
  end;
  ustVARIABLE,ustREPLACER,ustCONSTANTSTRUCT:begin
   result:=Value;
  end;
  ustSTRUCT:begin
   result:=Value;
  end;
  else begin
   result.ValueType:=AVT_INT;
   IntegerValueSetQWord(result.IntegerValue,0);
  end;
 end;
end;

procedure TUserSymbol.UseIt(ASMx86:TAssembler);
begin
 Used:=true;
 if assigned(ImportItem) then begin
  ImportItem.Used:=true;
  if assigned(ImportItem.ImportLibrary) then begin
   ImportItem.ImportLibrary.Used:=true;
  end;
  SymbolType:=ustIMPORT;
 end;
 if assigned(ExportItem) then begin
  ExportItem.Used:=true;
 end;
end;

constructor TUserSymbolList.Create;
begin
 inherited Create;
 Clear;
end;

destructor TUserSymbolList.Destroy;
begin
 Clear;
 inherited Destroy;
end;

function TUserSymbolList.NewClass(out Index:longint;const Name,OriginalName:ansistring):TUserSymbol;
begin
 result:=TUserSymbol.Create(Name,OriginalName);
 Index:=Add(result);
end;

procedure TUserSymbolList.Clear;
var Counter:longint;
begin
 for Counter:=0 to Count-1 do begin
  Items[Counter].Free;
  Items[Counter]:=nil;
 end;
 inherited Clear;
end;

function TUserSymbolList.GetItem(const Index:longint):TUserSymbol;
begin
 if (Index>=0) and (Index<Count) then begin
  result:=inherited Items[Index];
 end else begin
  result:=nil;
 end;
end;

procedure TUserSymbolList.SetItem(const Index:longint;Value:TUserSymbol);
begin
 if (Index>=0) and (Index<Count) then begin
  inherited Items[Index]:=Value;
 end;
end;

function CreateSymbolTreeNode(AChar:ansichar):PSymbolTreeNode;
begin
 GetMem(result,SizeOf(TSymbolTreeNode));
 result^.TheChar:=AChar;
 result^.Link:=0;
 result^.LinkType:=stNONE;
 result^.LinkExist:=false;
 result^.Prevoius:=nil;
 result^.Next:=nil;
 result^.Up:=nil;
 result^.Down:=nil;
end;

procedure DestroySymbolTreeNode(Node:PSymbolTreeNode);
begin
 if assigned(Node) then begin
  DestroySymbolTreeNode(Node^.Next);
  DestroySymbolTreeNode(Node^.Down);
  FreeMem(Node);
 end;
end;

constructor TSymbolTree.Create;
begin
 inherited Create;
 Root:=nil;
{$ifdef HASHING}
 FillChar(Hashes,SizeOf(TSymbolHashes),#0);
 FillChar(HashNodes,SizeOf(TSymbolHashNodes),#0);
{$endif}
end;

destructor TSymbolTree.Destroy;
begin
 DestroySymbolTreeNode(Root);
 inherited Destroy;
end;

procedure TSymbolTree.Dump;
var Ident:longint;
 procedure DumpNode(Node:PSymbolTreeNode);
 var SubNode:PSymbolTreeNode;
     IdentCounter,IdentOld:longint;
 begin
  for IdentCounter:=1 to Ident do write(' ');
  write(Node^.TheChar);
  IdentOld:=Ident;
  SubNode:=Node^.Next;
  while assigned(SubNode) do begin
   write(SubNode.TheChar);
   if not assigned(SubNode^.Next) then break;
   inc(Ident);
   SubNode:=SubNode^.Next;
  end;
  WriteLn;
  inc(Ident);
  while assigned(SubNode) and (SubNode<>Node) do begin
   if assigned(SubNode^.Down) then DumpNode(SubNode^.Down);
   SubNode:=SubNode^.Prevoius;
   dec(Ident);
  end;
  Ident:=IdentOld;
  if assigned(Node^.Down) then DumpNode(Node^.Down);
 end;
begin
 Ident:=0;
 DumpNode(Root);
end;

function TSymbolTree.Add(Content:ansistring;LinkType:TSymbolTreeLinkType;Link:TSymbolTreeLink;Replace:boolean=false):boolean;
var StringLength,Position,PositionCounter:longint;
    NewNode,LastNode,Node:PSymbolTreeNode;
    StringChar,NodeChar:ansichar;
{$ifdef HASHING}
    Hash,HashToCompare,HashCounter:longword;
{$endif}
begin
 result:=false;
 StringLength:=length(Content);
 if StringLength>0 then begin
{$ifdef HASHING}
  Hash:=HashString(Content);
  for HashCounter:=0 to MaxSymbolHashes-1 do begin
   HashToCompare:=Hashes[HashCounter];
   if HashToCompare<>0 then begin
    if HashToCompare=Hash then begin
     if assigned(HashNodes[HashCounter]) then begin
      LastNode:=HashNodes[HashCounter];
      if Replace or not LastNode^.LinkExist then begin
       LastNode^.Link:=Link;
       LastNode^.LinkType:=LinkType;
       result:=true;
      end;
      exit;
     end;
    end;
   end else begin
    break;
   end;
  end;
{$endif}
  LastNode:=nil;
  Node:=Root;
  for Position:=1 to StringLength do begin
   StringChar:=Content[Position];
   if assigned(Node) then begin
    NodeChar:=Node^.TheChar;
    if NodeChar=StringChar then begin
     LastNode:=Node;
     Node:=Node^.Next;
   end else begin
     while (NodeChar<StringChar) and assigned(Node^.Down) do begin
      Node:=Node^.Down;
      NodeChar:=Node^.TheChar;
     end;
     if NodeChar=StringChar then begin
      LastNode:=Node;
      Node:=Node^.Next;
     end else begin
      NewNode:=CreateSymbolTreeNode(StringChar);
      if NodeChar<StringChar then begin
       NewNode^.Down:=Node^.Down;
       NewNode^.Up:=Node;
       if assigned(NewNode^.Down) then begin
        NewNode^.Down^.Up:=NewNode;
       end;
       NewNode^.Prevoius:=Node^.Prevoius;
       Node^.Down:=NewNode;
      end else if NodeChar>StringChar then begin
       NewNode^.Down:=Node;
       NewNode^.Up:=Node^.Up;
       if assigned(NewNode^.Up) then begin
        NewNode^.Up^.Down:=NewNode;
       end;
       NewNode^.Prevoius:=Node^.Prevoius;
       if not assigned(NewNode^.Up) then begin
        if assigned(NewNode^.Prevoius) then begin
         NewNode^.Prevoius^.Next:=NewNode;
        end else begin
         Root:=NewNode;
        end;
       end;
       Node^.Up:=NewNode;
      end;
      LastNode:=NewNode;
      Node:=LastNode^.Next;
     end;
    end;
   end else begin
    for PositionCounter:=Position to StringLength do begin
     NewNode:=CreateSymbolTreeNode(Content[PositionCounter]);
     if assigned(LastNode) then begin
      NewNode^.Prevoius:=LastNode;
      LastNode^.Next:=NewNode;
      LastNode:=LastNode^.Next;
     end else begin
      if not assigned(Root) then begin
       Root:=NewNode;
       LastNode:=Root;
      end;
     end;
    end;
    break;
   end;
  end;
  if assigned(LastNode) then begin
   if Replace or not LastNode^.LinkExist then begin
{$ifdef HASHING}
    for HashCounter:=0 to MaxSymbolHashes-2 do begin
     Hashes[HashCounter+1]:=Hashes[HashCounter];
     HashNodes[HashCounter+1]:=HashNodes[HashCounter];
    end;
    Hashes[0]:=Hash;
    HashNodes[0]:=LastNode;
{$endif}
    LastNode^.Link:=Link;
    LastNode^.LinkType:=LinkType;
    LastNode^.LinkExist:=true;
    result:=true;
   end;
  end;
 end;
end;

function TSymbolTree.Delete(Content:ansistring):boolean;
var StringLength,Position:longint;
    Node:PSymbolTreeNode;
    StringChar,NodeChar:ansichar;
{$ifdef HASHING}
    Hash,HashToCompare,HashCounter:longword;
{$endif}
begin
 result:=false;
 StringLength:=length(Content);
 if StringLength>0 then begin
{$ifdef HASHING}
  Hash:=HashString(Content);
  for HashCounter:=0 to MaxSymbolHashes-1 do begin
   HashToCompare:=Hashes[HashCounter];
   if HashToCompare<>0 then begin
    if HashToCompare=Hash then begin
     if assigned(HashNodes[HashCounter]) then begin
      HashNodes[HashCounter]^.LinkExist:=false;
      result:=true;
      exit;
     end;
    end;
   end else begin
    break;
   end;
  end;
{$endif}
  Node:=Root;
  for Position:=1 to StringLength do begin
   StringChar:=Content[Position];
   if assigned(Node) then begin
    NodeChar:=Node^.TheChar;
    while (NodeChar<>StringChar) and assigned(Node^.Down) do begin
     Node:=Node^.Down;
     NodeChar:=Node^.TheChar;
    end;
    if NodeChar=StringChar then begin
     if (Position=StringLength) and Node^.LinkExist then begin
{$ifdef HASHING}
      for HashCounter:=0 to MaxSymbolHashes-2 do begin
       Hashes[HashCounter+1]:=Hashes[HashCounter];
       HashNodes[HashCounter+1]:=HashNodes[HashCounter];
      end;
      Hashes[0]:=Hash;
      HashNodes[0]:=Node;
{$endif}
      Node^.LinkExist:=false;
      result:=true;
      break;
     end;
     Node:=Node^.Next;
    end else begin
     break;
    end;
   end else begin
    break;
   end;
  end;
 end;
end;

function TSymbolTree.Find(Content:ansistring;var LinkType:TSymbolTreeLinkType;var Link:TSymbolTreeLink):boolean;
var StringLength,Position:longint;
    Node:PSymbolTreeNode;
    StringChar,NodeChar:ansichar;
{$ifdef HASHING}
    Hash,HashToCompare,HashCounter:longword;
{$endif}
begin
 result:=false;
 StringLength:=length(Content);
 if StringLength>0 then begin
{$ifdef HASHING}
  Hash:=HashString(Content);
  for HashCounter:=0 to MaxSymbolHashes-1 do begin
   HashToCompare:=Hashes[HashCounter];
   if HashToCompare<>0 then begin
    if HashToCompare=Hash then begin
     if assigned(HashNodes[HashCounter]) then begin
      Link:=HashNodes[HashCounter]^.Link;
      LinkType:=HashNodes[HashCounter]^.LinkType;
      result:=true;
      exit
     end;
    end;
   end else begin
    break;
   end;
  end;
{$endif}
  Node:=Root;
  for Position:=1 to StringLength do begin
   StringChar:=Content[Position];
   if assigned(Node) then begin
    NodeChar:=Node^.TheChar;
    while (NodeChar<>StringChar) and assigned(Node^.Down) do begin
     Node:=Node^.Down;
     NodeChar:=Node^.TheChar;
    end;
    if NodeChar=StringChar then begin
     if (Position=StringLength) and Node^.LinkExist then begin
{$ifdef HASHING}
      for HashCounter:=0 to MaxSymbolHashes-2 do begin
       Hashes[HashCounter+1]:=Hashes[HashCounter];
       HashNodes[HashCounter+1]:=HashNodes[HashCounter];
      end;
      Hashes[0]:=Hash;
      HashNodes[0]:=Node;
{$endif}
      Link:=Node^.Link;
      LinkType:=Node^.LinkType;
      result:=true;
      exit;
     end;
     Node:=Node^.Next;
    end else begin
     break;
    end;
   end else begin
    break;
   end;
  end;
 end;
end;

function CreateExportTreeNode(AChar:ansichar):PExportTreeNode;
begin
 GetMem(result,SizeOf(TExportTreeNode));
 result^.TheChar:=AChar;
 FillChar(result^.Link,SizeOf(TExportTreeLink),#0);
 result^.LinkExist:=false;
 result^.Prevoius:=nil;
 result^.Next:=nil;
 result^.Up:=nil;
 result^.Down:=nil;
end;

procedure DestroyExportTreeNode(Node:PExportTreeNode);
begin
 if assigned(Node) then begin
  DestroyExportTreeNode(Node^.Next);
  DestroyExportTreeNode(Node^.Down);
  FreeMem(Node);
 end;
end;

constructor TExportTree.Create;
begin
 inherited Create;
 Root:=nil;
end;

destructor TExportTree.Destroy;
begin
 DestroyExportTreeNode(Root);
 inherited Destroy;
end;

procedure TExportTree.Dump;
var Ident:longint;
 procedure DumpNode(Node:PExportTreeNode);
 var SubNode:PExportTreeNode;
     IdentCounter,IdentOld:longint;
 begin
  for IdentCounter:=1 to Ident do write(' ');
  write(Node^.TheChar);
  IdentOld:=Ident;
  SubNode:=Node^.Next;
  while assigned(SubNode) do begin
   write(SubNode.TheChar);
   if not assigned(SubNode^.Next) then break;
   inc(Ident);
   SubNode:=SubNode^.Next;
  end;
  WriteLn;
  inc(Ident);
  while assigned(SubNode) and (SubNode<>Node) do begin
   if assigned(SubNode^.Down) then DumpNode(SubNode^.Down);
   SubNode:=SubNode^.Prevoius;
   dec(Ident);
  end;
  Ident:=IdentOld;
  if assigned(Node^.Down) then DumpNode(Node^.Down);
 end;
begin
 Ident:=0;
 DumpNode(Root);
end;

function TExportTree.Add(FunctionName:ansistring;Link:TExportTreeLink):boolean;
var StringLength,Position,PositionCounter:longint;
    NewNode,LastNode,Node:PExportTreeNode;
    StringChar,NodeChar:ansichar;
begin
 result:=false;
 StringLength:=length(FunctionName);
 if StringLength>0 then begin
  LastNode:=nil;
  Node:=Root;
  for Position:=1 to StringLength do begin
   StringChar:=FunctionName[Position];
   if assigned(Node) then begin
    NodeChar:=Node^.TheChar;
    if NodeChar=StringChar then begin
     LastNode:=Node;
     Node:=Node^.Next;
   end else begin
     while (NodeChar<StringChar) and assigned(Node^.Down) do begin
      Node:=Node^.Down;
      NodeChar:=Node^.TheChar;
     end;
     if NodeChar=StringChar then begin
      LastNode:=Node;
      Node:=Node^.Next;
     end else begin
      NewNode:=CreateExportTreeNode(StringChar);
      if NodeChar<StringChar then begin
       NewNode^.Down:=Node^.Down;
       NewNode^.Up:=Node;
       if assigned(NewNode^.Down) then begin
        NewNode^.Down^.Up:=NewNode;
       end;
       NewNode^.Prevoius:=Node^.Prevoius;
       Node^.Down:=NewNode;
      end else if NodeChar>StringChar then begin
       NewNode^.Down:=Node;
       NewNode^.Up:=Node^.Up;
       if assigned(NewNode^.Up) then begin
        NewNode^.Up^.Down:=NewNode;
       end;
       NewNode^.Prevoius:=Node^.Prevoius;
       if not assigned(NewNode^.Up) then begin
        if assigned(NewNode^.Prevoius) then begin
         NewNode^.Prevoius^.Next:=NewNode;
        end else begin
         Root:=NewNode;
        end;
       end;
       Node^.Up:=NewNode;
      end;
      LastNode:=NewNode;
      Node:=LastNode^.Next;
     end;
    end;
   end else begin
    for PositionCounter:=Position to StringLength do begin
     NewNode:=CreateExportTreeNode(FunctionName[PositionCounter]);
     if assigned(LastNode) then begin
      NewNode^.Prevoius:=LastNode;
      LastNode^.Next:=NewNode;
      LastNode:=LastNode^.Next;
     end else begin
      if not assigned(Root) then begin
       Root:=NewNode;
       LastNode:=Root;
      end;
     end;
    end;
    break;
   end;
  end;
  if assigned(LastNode) then begin
   if not LastNode^.LinkExist then begin
    LastNode^.Link:=Link;
    LastNode^.LinkExist:=true;
    result:=true;
   end;
  end;
 end;
end;

function TExportTree.Delete(FunctionName:ansistring):boolean;
var StringLength,Position:longint;
    Node:PExportTreeNode;
    StringChar,NodeChar:ansichar;
begin
 result:=false;
 StringLength:=length(FunctionName);
 if StringLength>0 then begin
  Node:=Root;
  for Position:=1 to StringLength do begin
   StringChar:=FunctionName[Position];
   if assigned(Node) then begin
    NodeChar:=Node^.TheChar;
    while (NodeChar<>StringChar) and assigned(Node^.Down) do begin
     Node:=Node^.Down;
     NodeChar:=Node^.TheChar;
    end;
    if NodeChar=StringChar then begin
     if (Position=StringLength) and Node^.LinkExist then begin
      Node^.LinkExist:=false;
      result:=true;
      break;
     end;
     Node:=Node^.Next;
    end;
   end else begin
    break;
   end;
  end;
 end;
end;

function TExportTree.Find(FunctionName:ansistring;var Link:TExportTreeLink):boolean;
var StringLength,Position:longint;
    Node:PExportTreeNode;
    StringChar,NodeChar:ansichar;
begin
 result:=false;
 StringLength:=length(FunctionName);
 if StringLength>0 then begin
  Node:=Root;
  for Position:=1 to StringLength do begin
   StringChar:=FunctionName[Position];
   if assigned(Node) then begin
    NodeChar:=Node^.TheChar;
    while (NodeChar<>StringChar) and assigned(Node^.Down) do begin
     Node:=Node^.Down;
     NodeChar:=Node^.TheChar;
    end;
    if NodeChar=StringChar then begin
     if (Position=StringLength) and Node^.LinkExist then begin
      Link:=Node^.Link;
      result:=true;
      break;
     end;
     Node:=Node^.Next;
    end else begin
     break;
    end;
   end else begin
    break;
   end;
  end;
 end;
end;

function GetApplicationDir:ansistring;
begin
 result:=ExtractFilePath(PARAMSTR(0));
 if (length(result)>0) and (result[length(result)]<>Delimiter) then begin
  result:=result+Delimiter;
 end;
end;

{$ifdef Win32}
function GetCurrentDir:ansistring;
var Buffer:array[0..MAX_PATH-1] of ansichar;
begin
 setstring(result,Buffer,GetCurrentDirectoryA(SizeOf(Buffer),Buffer));
 if (length(result)>0) and (result[length(result)]<>Delimiter) then begin
  result:=result+Delimiter;
 end;
end;

function GetTempDir:ansistring;
var Buffer:array[0..MAX_PATH-1] of ansichar;
begin
 setstring(result,Buffer,GetTempPathA(SizeOf(Buffer),Buffer));
 if (length(result)>0) and (result[length(result)]<>Delimiter) then begin
  result:=result+Delimiter;
 end;
end;

function GetWinDir:ansistring;
var Buffer:array[0..MAX_PATH-1] of ansichar;
begin
 setstring(result,Buffer,GetWindowsDirectoryA(Buffer,SizeOf(Buffer)));
 if (length(result)>0) and (result[length(result)]<>Delimiter) then begin
  result:=result+Delimiter;
 end;
end;

function GetSystemDir:ansistring;
var Buffer:array[0..MAX_PATH-1] of ansichar;
begin
 setstring(result,Buffer,GetSystemDirectoryA(Buffer,SizeOf(Buffer)));
 if (length(result)>0) and (result[length(result)]<>Delimiter) then begin
  result:=result+Delimiter;
 end;
end;
{$endif}

constructor TDLLLoader.Create;
begin
 inherited Create;
 ImageBase:=nil;
 DLLProc:=nil;
 ExternalLibraryArray:=nil;
 ImportArray:=nil;
 ExportArray:=nil;
 Sections:=nil;
 ExportTree:=nil;
end;

destructor TDLLLoader.Destroy;
begin
 if @DLLProc<>nil then Unload;
 if assigned(ExportTree) then ExportTree.Destroy;
 inherited Destroy;
end;

function TDLLLoader.FindExternalLibrary(const LibraryName:ansistring):longint;
var i:longint;
begin
 result:=-1;
 for i:=0 to length(ExternalLibraryArray)-1 do begin
  if ExternalLibraryArray[i].LibraryName=LibraryName then begin
   result:=i;
   exit;
  end;
 end;
end;

function TDLLLoader.LoadExternalLibrary(const LibraryName:ansistring):longint;
begin
 result:=FindExternalLibrary(LibraryName);
 if result<0 then begin
  result:=length(ExternalLibraryArray);
  SetLength(ExternalLibraryArray,length(ExternalLibraryArray)+1);
  ExternalLibraryArray[result].LibraryName:=LibraryName;
  ExternalLibraryArray[result].LibraryHandle:=0;
 end;
end;

function TDLLLoader.GetExternalLibraryHandle(const LibraryName:ansistring):longword;
var i:longint;
begin
 result:=0;
 for i:=0 to length(ExternalLibraryArray)-1 do begin
  if ExternalLibraryArray[i].LibraryName=LibraryName then begin
   result:=ExternalLibraryArray[i].LibraryHandle;
   exit;
  end;
 end;
end;

function TDLLLoader.Load(const Stream:TStream):boolean;
var ImageDOSHeader:TImageDOSHeader;
    ImageNTHeaders:TImageNTHeaders;
    FileImageBase:longword;
    Is64Bit:longbool;
 function ConvertPointer(RVA:longword):pointer;
 var i:longint;
 begin
  result:=nil;
  for i:=0 to length(Sections)-1 do begin
   if (RVA<(Sections[i].RVA+Sections[i].Size)) and (RVA>=Sections[i].RVA) then begin
    result:=pointer(TSASMPtrUInt((RVA-longword(Sections[i].RVA))+TSASMPtrUInt(Sections[i].Base)));
    exit;
   end;
  end;
 end;
 function ReadImageHeaders:boolean;
 begin
  result:=false;
  if Stream.Size>0 then begin
   FillChar(ImageNTHeaders,SizeOf(TImageNTHeaders),#0);
   if Stream.Read(ImageDOSHeader,SizeOf(TImageDOSHeader))<>SizeOf(TImageDOSHeader) then exit;
   if ImageDOSHeader.Signature<>$5a4d then exit;
   if Stream.Seek(ImageDOSHeader.LFAOffset,soBeginning)<>longint(ImageDOSHeader.LFAOffset) then exit;
   if Stream.Read(ImageNTHeaders.Signature,SizeOf(longword))<>SizeOf(longword) then exit;
   if ImageNTHeaders.Signature<>$00004550 then exit;
   if Stream.Read(ImageNTHeaders.FileHeader,SizeOf(TImageFileHeader))<>SizeOf(TImageFileHeader) then exit;
   if (ImageNTHeaders.FileHeader.Machine<>$14c) and (ImageNTHeaders.FileHeader.Machine<>$8664) then exit;
   Is64Bit:=ImageNTHeaders.OptionalHeader64.Magic=$20b;
   if Stream.Read(ImageNTHeaders.OptionalHeader,ImageNTHeaders.FileHeader.SizeOfOptionalHeader)<>ImageNTHeaders.FileHeader.SizeOfOptionalHeader then exit;
   result:=true;
  end;
 end;
 function InitializeImage:boolean;
 var SectionBase:pointer;
     OldPosition:longint;
 begin
  result:=false;
  if ImageNTHeaders.FileHeader.NumberOfSections>0 then begin
   if Is64Bit then begin
    FileImageBase:=ImageNTHeaders.OptionalHeader64.ImageBase;
    GetMem(ImageBase,ImageNTHeaders.OptionalHeader64.SizeOfImage);
    ImageBaseDelta:=TSASMPtrUInt(ImageBase)-ImageNTHeaders.OptionalHeader64.ImageBase;
    SectionBase:=ImageBase;
    OldPosition:=Stream.Position;
    Stream.Seek(0,soBeginning);
    Stream.Read(SectionBase^,ImageNTHeaders.OptionalHeader64.SizeOfHeaders);
    Stream.Seek(OldPosition,soBeginning);
   end else begin
    FileImageBase:=ImageNTHeaders.OptionalHeader.ImageBase;
    GetMem(ImageBase,ImageNTHeaders.OptionalHeader.SizeOfImage);
    ImageBaseDelta:=TSASMPtrUInt(ImageBase)-ImageNTHeaders.OptionalHeader.ImageBase;
    SectionBase:=ImageBase;
    OldPosition:=Stream.Position;
    Stream.Seek(0,soBeginning);
    Stream.Read(SectionBase^,ImageNTHeaders.OptionalHeader.SizeOfHeaders);
    Stream.Seek(OldPosition,soBeginning);
   end;
   result:=true;
  end;
 end;
 function ReadSections:boolean;
 var i:longint;
     Section:TImageSectionHeader;
     SectionHeaders:PImageSectionHeaders;
 begin
  result:=false;
  if ImageNTHeaders.FileHeader.NumberOfSections>0 then begin
   GetMem(SectionHeaders,ImageNTHeaders.FileHeader.NumberOfSections*SizeOf(TImageSectionHeader));
   if Stream.Read(SectionHeaders^,(ImageNTHeaders.FileHeader.NumberOfSections*SizeOf(TImageSectionHeader)))<>(ImageNTHeaders.FileHeader.NumberOfSections*SizeOf(TImageSectionHeader)) then exit;
   SetLength(Sections,ImageNTHeaders.FileHeader.NumberOfSections);
   for i:=0 to ImageNTHeaders.FileHeader.NumberOfSections-1 do begin
    Section:=SectionHeaders^[i];
    Sections[i].RVA:=Section.VirtualAddress;
    Sections[i].Size:=Section.SizeOfRawData;
    if Sections[i].Size<Section.Misc.VirtualSize then begin
     Sections[i].Size:=Section.Misc.VirtualSize;
    end;
    Sections[i].Characteristics:=Section.Characteristics;
    Sections[i].Base:=pointer(TSASMPtrUInt(Sections[i].RVA+TSASMPtrUInt(ImageBase)));
    FillChar(Sections[i].Base^,Sections[i].Size,#0);
    if Section.PointerToRawData<>0 then begin
     Stream.Seek(Section.PointerToRawData,soBeginning);
     if Stream.Read(Sections[i].Base^,Section.SizeOfRawData)<>longint(Section.SizeOfRawData) then exit;
    end;
   end;
   FreeMem(SectionHeaders);
   result:=true;
  end;
 end;
 function ProcessRelocations:boolean;
 type puint64=^uint64;
 var Relocations:pansichar;
     VirtualAddress,Size,Position:longword;
     BaseRelocation:PImageBaseRelocation;
     Base:pointer;
     NumberOfRelocations:longword;
     Relocation:PWordArray;
     RelocationCounter:longint;
     RelocationPointer:pointer;
     RelocationType:longword;
     //ui64:puint64;
 begin
  if Is64Bit then begin
   VirtualAddress:=ImageNTHeaders.OptionalHeader64.DataDirectory[IMAGE_DIRECTORY_ENTRY_BASERELOC].VirtualAddress;
   Size:=ImageNTHeaders.OptionalHeader64.DataDirectory[IMAGE_DIRECTORY_ENTRY_BASERELOC].Size;
  end else begin
   VirtualAddress:=ImageNTHeaders.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_BASERELOC].VirtualAddress;
   Size:=ImageNTHeaders.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_BASERELOC].Size;
  end;
  if VirtualAddress<>0 then begin
   result:=false;
   Relocations:=ConvertPointer(VirtualAddress);
   Position:=0;
   while assigned(Relocations) and (Position<Size) do begin
    BaseRelocation:=PImageBaseRelocation(Relocations);
    Base:=ConvertPointer(BaseRelocation^.VirtualAddress);
    if not assigned(Base) then begin
     exit;
    end;
    NumberOfRelocations:=(BaseRelocation^.SizeOfBlock-SizeOf(TImageBaseRelocation)) div SizeOf(word);
    Relocation:=pointer(TSASMPtrUInt(TSASMPtrUInt(BaseRelocation)+SizeOf(TImageBaseRelocation)));
    for RelocationCounter:=0 to NumberOfRelocations-1 do begin
     RelocationPointer:=pointer(TSASMPtrUInt(TSASMPtrUInt(Base)+(Relocation^[RelocationCounter] and $fff)));
     RelocationType:=Relocation^[RelocationCounter] shr 12;
     case RelocationType of
      IMAGE_REL_BASED_ABSOLUTE:begin
      end;
      IMAGE_REL_BASED_HIGH:begin
       pword(RelocationPointer)^:=(longword(((longword((pword(RelocationPointer)^+TSASMPtrUInt(ImageBase))-FileImageBase)))) shr 16) and $ffff;
      end;
      IMAGE_REL_BASED_LOW:begin
       pword(RelocationPointer)^:=longword(((longword((pword(RelocationPointer)^+TSASMPtrUInt(ImageBase))-FileImageBase)))) and $ffff;
      end;
      IMAGE_REL_BASED_HIGHLOW:begin
       plongword(RelocationPointer)^:=(plongword(RelocationPointer)^+TSASMPtrUInt(ImageBase))-FileImageBase;
      end;
      IMAGE_REL_BASED_HIGHADJ:begin
       // ???
      end;
      IMAGE_REL_BASED_MIPS_JMPADDR:begin
       // Only for MIPS CPUs ;)
      end;
      IMAGE_REL_BASED_DIR64:begin
       puint64(RelocationPointer)^:=(puint64(RelocationPointer)^+uint64(TSASMPtrUInt(ImageBase)))-FileImageBase;
      end;
     end;
    end;
    Relocations:=pointer(TSASMPtrUInt(TSASMPtrUInt(Relocations)+BaseRelocation^.SizeOfBlock));
    inc(Position,BaseRelocation^.SizeOfBlock);
   end;
  end;
  result:=true;
 end;
 function ProcessImports:boolean;
 type puint64=^uint64; 
 var VirtualAddress:longword;
     ImportDescriptor:PImageImportDescriptor;
     ThunkData32:plongword;
     ThunkData64:puint64;
     Name:pansichar;
     DLLImport:PDLLImport;
     DLLFunctionImport:PDLLFunctionImport;
     FunctionPointer:pointer;
 begin
  if Is64Bit then begin
   VirtualAddress:=ImageNTHeaders.OptionalHeader64.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].VirtualAddress;
  end else begin
   VirtualAddress:=ImageNTHeaders.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].VirtualAddress;
  end;
  if VirtualAddress<>0 then begin
   ImportDescriptor:=ConvertPointer(VirtualAddress);
   if assigned(ImportDescriptor) then begin
    SetLength(ImportArray,0);
    while ImportDescriptor^.Name<>0 do begin
     Name:=ConvertPointer(ImportDescriptor^.Name);
     SetLength(ImportArray,length(ImportArray)+1);
     LoadExternalLibrary(Name);
     DLLImport:=@ImportArray[length(ImportArray)-1];
     DLLImport^.LibraryName:=Name;
     DLLImport^.LibraryHandle:=GetExternalLibraryHandle(Name);
     DLLImport^.Entries:=nil;
     if ImageNTHeaders.FileHeader.Machine=$8664 then begin
      if ImportDescriptor^.TimeDateStamp=0 then begin
       ThunkData64:=ConvertPointer(ImportDescriptor^.FirstThunk);
      end else begin          
       ThunkData64:=ConvertPointer(ImportDescriptor^.OriginalFirstThunk);
      end;     
      while ThunkData64^<>0 do begin
       SetLength(DLLImport^.Entries,length(DLLImport^.Entries)+1);
       DLLFunctionImport:=@DLLImport^.Entries[length(DLLImport^.Entries)-1];
       if (ThunkData64^ and IMAGE_ORDINAL_FLAG64)<>0 then begin
        DLLFunctionImport^.NameOrID:=niID;
        DLLFunctionImport^.ID:=ThunkData64^ and IMAGE_ORDINAL_MASK64;
        DLLFunctionImport^.Name:='';
        FunctionPointer:=nil;
       end else begin
        Name:=ConvertPointer(uint64(ThunkData64^)+IMPORTED_NAME_OFFSET);
        DLLFunctionImport^.NameOrID:=niName;
        DLLFunctionImport^.ID:=0;
        DLLFunctionImport^.Name:=Name;
        FunctionPointer:=nil;
       end;
       PPOINTER(ThunkData64)^:=FunctionPointer;
       inc(ThunkData64);
      end;
     end else begin
      if ImportDescriptor^.TimeDateStamp=0 then begin
       ThunkData32:=ConvertPointer(ImportDescriptor^.FirstThunk);
      end else begin
       ThunkData32:=ConvertPointer(ImportDescriptor^.OriginalFirstThunk);
      end;
      while ThunkData32^<>0 do begin
       SetLength(DLLImport^.Entries,length(DLLImport^.Entries)+1);
       DLLFunctionImport:=@DLLImport^.Entries[length(DLLImport^.Entries)-1];
       if (ThunkData32^ and IMAGE_ORDINAL_FLAG32)<>0 then begin
        DLLFunctionImport^.NameOrID:=niID;
        DLLFunctionImport^.ID:=ThunkData32^ and IMAGE_ORDINAL_MASK32;
        DLLFunctionImport^.Name:='';
        FunctionPointer:=nil;
       end else begin
        Name:=ConvertPointer(longword(ThunkData32^)+IMPORTED_NAME_OFFSET);
        DLLFunctionImport^.NameOrID:=niName;
        DLLFunctionImport^.ID:=0;
        DLLFunctionImport^.Name:=Name;
        FunctionPointer:=nil;
       end;
       PPOINTER(ThunkData32)^:=FunctionPointer;
       inc(ThunkData32);
      end;
     end;
     inc(ImportDescriptor);
    end;
   end;
  end;
  result:=true;
 end;
 function InitializeLibrary:boolean;
 begin
  if Is64Bit then begin
   @DLLProc:=ConvertPointer(ImageNTHeaders.OptionalHeader64.AddressOfEntryPoint);
  end else begin
   @DLLProc:=ConvertPointer(ImageNTHeaders.OptionalHeader.AddressOfEntryPoint);
  end;
  result:=true;
 end;
 function ProcessExports:boolean;
 var VirtualAddress,Size:longword;
     i:longint;
     ExportDirectory:PImageExportDirectory;
     ExportDirectorySize:longword;
     FunctionNamePointer:pointer;
     FunctionName:pansichar;
     FunctionIndexPointer:pointer;
     FunctionIndex:longword;
     FunctionPointer:pointer;
     ForwarderCharPointer:pansichar;
     ForwarderString:ansistring;
     ForwarderLibrary:ansistring;
     ExportTreeLink:TExportTreeLink;
  function ParseStringToNumber(AString:ansistring):longword;
  var CharCounter:longint;
  begin
   result:=0;
   for CharCounter:=0 to length(AString)-1 do begin
    if AString[CharCounter] in ['0'..'9'] then begin
     result:=(result*10)+byte(byte(AString[CharCounter])-byte('0'));
    end else begin
     exit;
    end;
   end;
  end;
 begin
  if Is64Bit then begin
   VirtualAddress:=ImageNTHeaders.OptionalHeader64.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress;
   Size:=ImageNTHeaders.OptionalHeader64.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].Size;
  end else begin
   VirtualAddress:=ImageNTHeaders.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress;
   Size:=ImageNTHeaders.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].Size;
  end;
  if VirtualAddress<>0 then begin
   ExportTree:=TExportTree.Create;
   ExportDirectory:=ConvertPointer(VirtualAddress);
   if assigned(ExportDirectory) then begin
    ExportDirectorySize:=Size;
    SetLength(ExportArray,ExportDirectory^.NumberOfNames);
    for i:=0 to ExportDirectory^.NumberOfNames-1 do begin
     FunctionNamePointer:=ConvertPointer(TSASMPtrUInt(ExportDirectory^.AddressOfNames));
     FunctionNamePointer:=ConvertPointer(PLongWordArray(FunctionNamePointer)^[i]);
     FunctionName:=FunctionNamePointer;
     FunctionIndexPointer:=ConvertPointer(TSASMPtrUInt(ExportDirectory^.AddressOfNameOrdinals));
     FunctionIndex:=PWordArray(FunctionIndexPointer)^[i];
     FunctionPointer:=ConvertPointer(TSASMPtrUInt(ExportDirectory^.AddressOfFunctions));
     FunctionPointer:=ConvertPointer(PLongWordArray(FunctionPointer)^[FunctionIndex]);
     ExportArray[i].Name:=FunctionName;
     ExportArray[i].index:=FunctionIndex+ExportDirectory^.Base;
     if (TSASMPtrUInt(ExportDirectory)<TSASMPtrUInt(FunctionPointer)) and (TSASMPtrUInt(FunctionPointer)<(TSASMPtrUInt(ExportDirectory)+ExportDirectorySize)) then begin
      ForwarderCharPointer:=FunctionPointer;
      ForwarderString:=ForwarderCharPointer;
      while ForwarderCharPointer^<>'.' do begin
       inc(ForwarderCharPointer);
      end;
      ForwarderLibrary:=Copy(ForwarderString,1,Pos('.',ForwarderString)-1);
      LoadExternalLibrary(ForwarderLibrary);
      if ForwarderCharPointer^='#' then begin
       inc(ForwarderCharPointer);
       ForwarderString:=ForwarderCharPointer;
       ForwarderCharPointer:=ConvertPointer(ParseStringToNumber(ForwarderString));
       ForwarderString:=ForwarderCharPointer;
      end else begin
       ForwarderString:=ForwarderCharPointer;
       ExportArray[i].FunctionPointer:=nil;
      end;
     end else begin
      ExportArray[i].FunctionPointer:=FunctionPointer;
     end;
     ExportTreeLink.Link:=ExportArray[i].FunctionPointer;
     ExportTreeLink.OrdinalIndex:=ExportArray[i].Index;
     ExportTree.Add(ExportArray[i].Name,ExportTreeLink);
    end
   end;
  end;
  result:=true;
 end;
begin
 result:=false;
 if assigned(Stream) then begin
  Stream.Seek(0,soBeginning);
  if Stream.Size>0 then begin
   if ReadImageHeaders then begin
    if InitializeImage then begin
     if ReadSections then begin
      if ProcessRelocations then begin
       if ProcessImports then begin
        if InitializeLibrary then begin
         if ProcessExports then begin
          result:=true;
         end;
        end;
       end;
      end;
     end;
    end;
   end;
  end;
 end;
end;

function TDLLLoader.LoadFile(const FileName:ansistring):boolean;
var Stream:TFileStream;
    FileNameWithPath:ansistring;
begin
{$ifdef Win32}
 FileNameWithPath:=GetSystemDir+FileName;
 if not CheckFile(FileNameWithPath) then begin
  FileNameWithPath:=GetWinDir+FileName;
  if not CheckFile(FileNameWithPath) then begin
   FileNameWithPath:=GetCurrentDir+FileName;
   if not CheckFile(FileNameWithPath) then begin
    FileNameWithPath:=GetApplicationDir+FileName;
    if not CheckFile(FileNameWithPath) then begin
     result:=false;
     exit;
    end;
   end;
  end;
 end;
{$else}
 FileNameWithPath:=GetApplicationDir+FileName;
 if not CheckFile(FileNameWithPath) then begin
  FileNameWithPath:=FileName;
  if not CheckFile(FileNameWithPath) then begin
   result:=false;
   exit;
  end;
 end;
{$endif}
 try
  Stream:=TFileStream.Create(FileNameWithPath,fmOpenRead or fmShareDenyWrite);
  try
   result:=Load(Stream);
  finally
   Stream.Free;
  end;
 except
  result:=false;
 end;
end;

function TDLLLoader.Unload:boolean;
var i,j:longint;
begin
 result:=false;
 if @DLLProc<>nil then begin
  DLLProc:=nil;
 end;
 SetLength(Sections,0);
 for i:=0 to length(ExternalLibraryArray)-1 do begin
  ExternalLibraryArray[i].LibraryName:='';
 end;
 SetLength(ExternalLibraryArray,0);
 for i:=0 to length(ImportArray)-1 do begin
  for j:=0 to length(ImportArray[i].Entries)-1 do begin
   ImportArray[i].Entries[j].Name:='';
  end;
  SetLength(ImportArray[i].Entries,0);
 end;
 SetLength(ImportArray,0);
 for i:=0 to length(ExportArray)-1 do begin
  ExportArray[i].Name:='';
 end;
 SetLength(ExportArray,0);
 if assigned(ImageBase) then begin
  FreeMem(ImageBase);
 end;
 ImageBase:=nil;
 if assigned(ExportTree) then begin
  ExportTree.Destroy;
  ExportTree:=nil;
 end;
end;

function TDLLLoader.FindExport(const FunctionName:ansistring):TExportTreeLink;
var i:longint;
begin
 FillChar(result,SizeOf(TExportTreeLink),#0);
 result.OrdinalIndex:=-1;
 if assigned(ExportTree) then begin
  ExportTree.Find(FunctionName,result);
 end else begin
  for i:=0 to length(ExportArray)-1 do begin
   if ExportArray[i].Name=FunctionName then begin
    result.Link:=ExportArray[i].FunctionPointer;
    result.OrdinalIndex:=ExportArray[i].index;
    exit;
   end;
  end;
 end;
end;

function TDLLLoader.FindExportPerIndex(const FunctionIndex:longint):pointer;
var i:longint;
begin
 result:=nil;
 for i:=0 to length(ExportArray)-1 do begin
  if ExportArray[i].index=FunctionIndex then begin
   result:=ExportArray[i].FunctionPointer;
   exit;
  end;
 end;
end;

function TDLLLoader.GetExportList:TStringList;
var i:longint;
begin
 result:=TStringList.Create;
 for i:=0 to length(ExportArray)-1 do begin
  result.Add(ExportArray[i].Name);
 end;
end;

constructor TAssemblerImportLibraryList.Create;
begin
 inherited Create;
 Clear;
end;

destructor TAssemblerImportLibraryList.Destroy;
begin
 Clear;
 inherited Destroy;
end;

procedure TAssemblerImportLibraryList.Clear;
var Counter:longint;
begin
 for Counter:=0 to Count-1 do begin
  Items[Counter].Free;
  Items[Counter]:=nil;
 end;
 inherited Clear;
end;

function TAssemblerImportLibraryList.NewClass:TAssemblerImportLibraryItem;
begin
 result:=TAssemblerImportLibraryItem.Create;
 Add(result);
end;

function TAssemblerImportLibraryList.GetItem(const Index:longint):TAssemblerImportLibraryItem;
begin
 if (Index>=0) and (Index<Count) then begin
  result:=inherited Items[Index];
 end else begin
  result:=nil;
 end;
end;

procedure TAssemblerImportLibraryList.SetItem(const Index:longint;Value:TAssemblerImportLibraryItem);
begin
 if (Index>=0) and (Index<Count) then begin
  inherited Items[Index]:=Value;
 end;
end;

constructor TAssemblerImportList.Create;
begin
 inherited Create;
 Clear;
end;

destructor TAssemblerImportList.Destroy;
begin
 Clear;
 inherited Destroy;
end;

procedure TAssemblerImportList.Clear;
var Counter:longint;
begin
 for Counter:=0 to Count-1 do begin
  Items[Counter].Free;
  Items[Counter]:=nil;
 end;
 inherited Clear;
end;

function TAssemblerImportList.NewClass:TAssemblerImportItem;
begin
 result:=TAssemblerImportItem.Create;
 Add(result);
end;

function TAssemblerImportList.GetItem(const Index:longint):TAssemblerImportItem;
begin
 if (Index>=0) and (Index<Count) then begin
  result:=inherited Items[Index];
 end else begin
  result:=nil;
 end;
end;

procedure TAssemblerImportList.SetItem(const Index:longint;Value:TAssemblerImportItem);
begin
 if (Index>=0) and (Index<Count) then begin
  inherited Items[Index]:=Value;
 end;
end;

constructor TAssemblerExportItem.Create;
begin
 inherited Create;
 Name:='';
 Symbol:=nil;
 Used:=false;
end;

destructor TAssemblerExportItem.Destroy;
begin
 Name:='';
 if assigned(Symbol) then begin
  Symbol.ExportItem:=nil;
 end;
 inherited Destroy;
end;

constructor TAssemblerExportList.Create;
begin
 inherited Create;
 Clear;
end;

destructor TAssemblerExportList.Destroy;
begin
 Clear;
 inherited Destroy;
end;

procedure TAssemblerExportList.Clear;
var Counter:longint;
begin
 for Counter:=0 to Count-1 do begin
  Items[Counter].Free;
  Items[Counter]:=nil;
 end;
 inherited Clear;
end;

function TAssemblerExportList.NewClass:TAssemblerExportItem;
begin
 result:=TAssemblerExportItem.Create;
 Add(result);
end;

function TAssemblerExportList.GetItem(const Index:longint):TAssemblerExportItem;
begin
 if (Index>=0) and (Index<Count) then begin
  result:=inherited Items[Index];
 end else begin
  result:=nil;
 end;
end;

procedure TAssemblerExportList.SetItem(const Index:longint;Value:TAssemblerExportItem);
begin
 if (Index>=0) and (Index<Count) then begin
  inherited Items[Index]:=Value;
 end;
end;

constructor TAssembler.Create;
var i:longint;
begin
 inherited Create;
 OpcodeSymbolTree:=TSymbolTree.Create;
 KeywordSymbolTree:=TSymbolTree.Create;
 UserSymbolTree:=TSymbolTree.Create;
 FileSymbolTree:=TSymbolTree.Create;
 UserSymbolList:=TUserSymbolList.Create;
 FileStringList:=TStringList.Create;
 StartOffset:=0;
 StartFixUpExpression:=nil;
 StartCode:=nil;
 StartSegment:=nil;
 StartSection:=nil;
 LastFixUpExpression:=nil;
 LastCode:=nil;
 LastSegment:=nil;
 LastSection:=nil;
 ImportList:=TAssemblerImportList.Create;
 ImportLibraryList:=TAssemblerImportLibraryList.Create;
 ExportList:=TAssemblerExportList.Create;
 CodeImage:=TMemoryStream.Create;
 StackSize:=65535;
 HeapSize:=0;
 ImageBase:=0;
 CodeBase:=0;
 SubSystem:=IMAGE_SUBSYSTEM_WINDOWS_GUI;
 Characteristics:=IMAGE_FILE_RELOCS_STRIPPED or IMAGE_FILE_EXECUTABLE_IMAGE or IMAGE_FILE_LINE_NUMS_STRIPPED or IMAGE_FILE_LOCAL_SYMS_STRIPPED or IMAGE_FILE_DEBUG_STRIPPED or IMAGE_FILE_32BIT_MACHINE;
 DLLCharacteristics:=0;
 SizeOfStackReserve:=$100000;
 SizeOfStackCommit:=$2000;
 SizeOfHeapReserve:=$100000;
 SizeOfHeapCommit:=$2000;
 ELFType:=1; // ET_REL
 UnitName:='';
 CodeEnd:=-1;
 Target:=ttRUNTIME;//ttBIN;
 WithCompleteDOSStub:=true;
 CompleteMZEXEHeader:=false;
 TRIDoRelative:=false;
 CalcCheckSum:=false;
 ImportType:=titNAME;
 IBHSafe:=true;
 RuntimeCodeImage:=nil;
 RuntimeCodeImageSize:=0;
 RuntimeCodeImageEntryPoint:=nil;
 OptimizationLevel:=1;
 ForcePasses:=-1;
 CurrentPass:=0;
 CurrentPasses:=4;
 Status:=nil;
 GlobalDefaults:=[];
 begin
  for i:=low(OpcodeTemplates) to high(OpcodeTemplates) do begin
   if length(OpcodeTemplates[i].Name)>0 then begin
    KeywordSymbolTree.Add(OpcodeTemplates[i].Name,stOPCODE,i);
   end;
  end;
  for i:=low(RegisterTemplates) to high(RegisterTemplates) do begin
   if length(RegisterTemplates[i].RegisterName)>0 then begin
    KeywordSymbolTree.Add(RegisterTemplates[i].RegisterName,stREGISTER,i);
   end;
  end;
  for i:=low(KeywordTemplates) to high(KeywordTemplates) do begin
   if length(KeywordTemplates[i].Name)>0 then begin
    KeywordSymbolTree.Add(KeywordTemplates[i].Name,stKEYWORD,i);
   end;
  end;
  for i:=low(PrefixTemplates) to high(PrefixTemplates) do begin
   if length(PrefixTemplates[i].Name)>0 then begin
    KeywordSymbolTree.Add(PrefixTemplates[i].Name,stPREFIX,i);
   end;
  end;
 end;
{$ifdef SASMBESEN}
 BESENInstance:=TBESEN.Create;
{$endif}
 OriginalNamePrefix:='';
 Clear;
end;

destructor TAssembler.Destroy;
begin
 Clear;
 ImportList.Destroy;
 ImportLibraryList.Destroy;
 ExportList.Destroy;
 CodeImage.Destroy;
 OpcodeSymbolTree.Destroy;
 KeywordSymbolTree.Destroy;
 UserSymbolTree.Destroy;
 FileStringList.Destroy;
 FileSymbolTree.Destroy;
 UserSymbolList.Destroy;
{$ifdef SASMBESEN}
 BESENInstance.Free;
{$endif}
 inherited Destroy;
end;

{$ifdef SASMBESEN}
procedure TAssembler.ClearScript;
begin

 BESENInstance.Free;

 BESENInstance:=TBESEN.Create;

 BESENInstance.RegisterNativeObject('File',TFileObject);

 BESENObjectFunctions:=TBESENObject.Create(BESENInstance,BESENInstance.ObjectPrototype,false);
 BESENInstance.GarbageCollector.Add(BESENObjectFunctions);
 BESENInstance.ObjectGlobal.OverwriteData('Functions',BESENObjectValue(BESENObjectFunctions),[bopaWRITABLE,bopaCONFIGURABLE]);

 BESENObjectMacros:=TBESENObject.Create(BESENInstance,BESENInstance.ObjectPrototype,false);
 BESENInstance.GarbageCollector.Add(BESENObjectMacros);
 BESENInstance.ObjectGlobal.OverwriteData('Macros',BESENObjectValue(BESENObjectMacros),[bopaWRITABLE,bopaCONFIGURABLE]);

 BESENObjectFileUtils:=TBESENObject.Create(BESENInstance,BESENInstance.ObjectPrototype,false);
 BESENInstance.GarbageCollector.Add(BESENObjectFileUtils);
 BESENInstance.ObjectGlobal.OverwriteData('FileUtils',BESENObjectValue(BESENObjectFileUtils),[bopaWRITABLE,bopaCONFIGURABLE]);
 BESENObjectFileUtils.RegisterNativeFunction('readFile',BESENObjectFileUtilsNativeReadFile,0,[]);
 BESENObjectFileUtils.RegisterNativeFunction('writeFile',BESENObjectFileUtilsNativeWriteFile,0,[]);
 BESENObjectFileUtils.RegisterNativeFunction('readDirectory',BESENObjectFileUtilsNativeReadDirectory,0,[]);
 BESENObjectFileUtils.RegisterNativeFunction('loadScript',BESENObjectFileUtilsNativeLoadScript,0,[]);

 BESENObjectGarbageCollector:=TBESENObject.Create(BESENInstance,BESENInstance.ObjectPrototype,false);
 BESENInstance.GarbageCollector.Add(BESENObjectGarbageCollector);
 BESENInstance.ObjectGlobal.OverwriteData('GarbageCollector',BESENObjectValue(BESENObjectGarbageCollector),[bopaWRITABLE,bopaCONFIGURABLE]);
 BESENObjectGarbageCollector.RegisterNativeFunction('run',BESENObjectGarbageCollectorNativeRun,0,[]);

 BESENObjectAssembler:=TBESENObject.Create(BESENInstance,BESENInstance.ObjectPrototype,false);
 BESENInstance.GarbageCollector.Add(BESENObjectAssembler);
 BESENInstance.ObjectGlobal.OverwriteData('Assembler',BESENObjectValue(BESENObjectAssembler),[bopaWRITABLE,bopaCONFIGURABLE]);
 BESENObjectAssembler.RegisterNativeFunction('defineFunction',BESENObjectAssemblerNativeDefineFunction,0,[]);
 BESENObjectAssembler.RegisterNativeFunction('defineMacro',BESENObjectAssemblerNativeDefineMacro,0,[]);
 BESENObjectAssembler.RegisterNativeFunction('parse',BESENObjectAssemblerNativeParse,0,[]);
 BESENObjectAssembler.RegisterNativeFunction('error',BESENObjectAssemblerNativeError,0,[]);
 BESENObjectAssembler.RegisterNativeFunction('warning',BESENObjectAssemblerNativeWarning,0,[]);
 BESENObjectAssembler.RegisterNativeFunction('getCurrentBits',BESENObjectAssemblerNativeGetCurrentBits,0,[]);
 BESENObjectAssembler.RegisterNativeFunction('getCurrentTarget',BESENObjectAssemblerNativeGetCurrentTarget,0,[]);
 BESENObjectAssembler.RegisterNativeFunction('getBasePosition',BESENObjectAssemblerNativeGetBasePosition,0,[]);
 BESENObjectAssembler.RegisterNativeFunction('getHerePosition',BESENObjectAssemblerNativeGetHerePosition,0,[]);
 BESENObjectAssembler.RegisterNativeFunction('isLastPass',BESENObjectAssemblerNativeIsLastPass,0,[]);
 BESENObjectAssembler.RegisterNativeFunction('read8',BESENObjectAssemblerNativeRead8,0,[]);
 BESENObjectAssembler.RegisterNativeFunction('read16',BESENObjectAssemblerNativeRead16,0,[]);
 BESENObjectAssembler.RegisterNativeFunction('read32',BESENObjectAssemblerNativeRead32,0,[]);
 BESENObjectAssembler.RegisterNativeFunction('write8',BESENObjectAssemblerNativeWrite8,0,[]);
 BESENObjectAssembler.RegisterNativeFunction('write16',BESENObjectAssemblerNativeWrite16,0,[]);
 BESENObjectAssembler.RegisterNativeFunction('write32',BESENObjectAssemblerNativeWrite32,0,[]);

end;

procedure TAssembler.BESENObjectFileUtilsNativeReadFile(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
var FileName,Content:{$ifdef BESENSingleStringType}TBESENString{$else}ansistring{$endif};
    fm:byte;
    f:file;
begin
 ResultValue.ValueType:=bvtUNDEFINED;
 try
  if CountArguments>0 then begin
{$ifdef BESENSingleStringType}
   FileName:=BESENInstance.ToStr(Arguments^[0]^));
{$else}
   FileName:=BESENEncodeString(BESENUTF16ToUTF8(BESENInstance.ToStr(Arguments^[0]^)),UTF_8,BESENLocaleCharset);
{$endif}
   Content:='';
   fm:=filemode;
   filemode:=0;
   assignfile(f,String(FileName));
   {$i-}reset(f,1);{$i+};
   if ioresult=0 then begin
    SetLength(Content,filesize(f));
    if length(Content)>0 then begin
     {$i-}blockread(f,Content[1],length(Content));{$i+}
     if ioresult<>0 then begin
      {$i-}closefile(f);{$i+}
      filemode:=fm;
      raise EBESENError.Create('FileError',TBESENString('Couldn''t read file "'+String(FileName)+'"'));
      exit;
     end;
    end;
    ResultValue.ValueType:=bvtSTRING;
    ResultValue.Str:={$ifndef BESENSingleStringType}BESENUTF8ToUTF16(BESENConvertToUTF8({$endif}Content{$ifndef BESENSingleStringType})){$endif};
    {$i-}closefile(f);{$i+}
    if ioresult=0 then begin
    end;
    filemode:=fm;
   end else begin
    {$i-}closefile(f);{$i+}
    if ioresult=0 then begin
    end;
    filemode:=fm;
    raise EBESENError.Create('FileError',TBESENString('Couldn''t read file "'+String(FileName)+'"'));
   end;
  end else begin
   raise EBESENError.Create('FileError','Too few arguments');
  end;
 finally
 end;
end;

procedure TAssembler.BESENObjectFileUtilsNativeWriteFile(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
var FileName,Content:{$ifdef BESENSingleStringType}TBESENString{$else}ansistring{$endif};
    fm:byte;
    f:file;
begin
 ResultValue.ValueType:=bvtUNDEFINED;
 try
  if CountArguments>1 then begin
{$ifdef BESENSingleStringType}
   FileName:=BESENInstance.ToStr(Arguments^[0]^));
   Content:=BESENInstance.ToStr(Arguments^[1]^);
{$else}
   FileName:=BESENEncodeString(BESENUTF16ToUTF8(BESENInstance.ToStr(Arguments^[0]^)),UTF_8,BESENLocaleCharset);
   Content:=#$ef#$bb#$bf+BESENUTF16ToUTF8(BESENInstance.ToStr(Arguments^[1]^));
{$endif}
   fm:=filemode;
   filemode:=2;
   assignfile(f,String(FileName));
   {$i-}rewrite(f,1);{$i+};
   if ioresult=0 then begin
    if length(Content)>0 then begin
     {$i-}blockwrite(f,Content[1],length(Content));{$i+}
     if ioresult<>0 then begin
      {$i-}closefile(f);{$i+}
      filemode:=fm;
      raise EBESENError.Create('FileError',TBESENString('Couldn''t write file "'+String(FileName)+'"'));
      exit;
     end;
    end;
    {$i-}closefile(f);{$i+}
    if ioresult=0 then begin
    end;
    filemode:=fm;
   end else begin
    {$i-}closefile(f);{$i+}
    if ioresult=0 then begin
    end;
    filemode:=fm;
    raise EBESENError.Create('FileError',TBESENString('Couldn''t write file "'+String(FileName)+'"'));
   end;
  end else begin
   raise EBESENError.Create('FileError','Too few arguments');
  end;
 finally
 end;
end;

{$warnings off}
procedure TAssembler.BESENObjectFileUtilsNativeReadDirectory(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
const BoolStr:array[boolean] of {$ifdef BESENSingleStringType}TBESENString{$else}ansistring{$endif}=('false','true');
var FileName,Content:{$ifdef BESENSingleStringType}TBESENString{$else}ansistring{$endif};
    SearchRec:TSearchRec;
    Count:longint;
begin
 ResultValue.ValueType:=bvtUNDEFINED;
 try
  if CountArguments>0 then begin
   Content:='[';
{$ifdef BESENSingleStringType}
   FileName:=BESENInstance.ToStr(Arguments^[0]^));
{$else}
   FileName:=BESENEncodeString(BESENUTF16ToUTF8(BESENInstance.ToStr(Arguments^[0]^)),UTF_8,BESENLocaleCharset);
{$endif}
   if FindFirst(String(FileName),faAnyFile or faDirectory,SearchRec)=0 then begin
    Count:=0;
    repeat
     if Count>0 then begin
      Content:=Content+',';
     end;
     Content:=Content+'{';
     Content:=Content+'"name":'+{$ifdef BESENSingleStringType}TBESENString{$else}ansistring{$endif}(BESENJSONStringQuote(BESENUTF8ToUTF16(BESENEncodeString(AnsiString(SearchRec.Name),BESENLocaleCharset,UTF_8))))+',';
     Content:=Content+'"size":'+{$ifdef BESENSingleStringType}TBESENString{$else}ansistring{$endif}(IntToStr(SearchRec.Size))+',';
     Content:=Content+'"time":'+{$ifdef BESENSingleStringType}TBESENString{$else}ansistring{$endif}(BESENFloatToStr(BESENDateTimeToBESENDate(FileDateToDateTime(SearchRec.Time))))+',';
     Content:=Content+'"flags":{';
     Content:=Content+'"hidden":'+BoolStr[(SearchRec.Attr and faHidden)<>0]+',';
     Content:=Content+'"systemFile":'+BoolStr[(SearchRec.Attr and faSysFile)<>0]+',';
     Content:=Content+'"volumeID":'+BoolStr[(SearchRec.Attr and faVolumeID)<>0]+',';
     Content:=Content+'"directory":'+BoolStr[(SearchRec.Attr and faDirectory)<>0]+',';
     Content:=Content+'"archive":'+BoolStr[(SearchRec.Attr and faArchive)<>0]+'';
     Content:=Content+'}}';
     inc(Count);
    until FindNext(SearchRec)<>0;
    FindClose(SearchRec);
   end;
   Content:=Content+']';
   ResultValue:=BESENInstance.JSONEval(Content);
  end else begin
   raise EBESENError.Create('DirectoryError','Too few arguments');
  end;
 finally
 end;
end;
{$warnings on}

procedure TAssembler.BESENObjectFileUtilsNativeLoadScript(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
var FileName,Content:{$ifdef BESENSingleStringType}TBESENString{$else}ansistring{$endif};
    fm:byte;
    f:file;
begin
 ResultValue.ValueType:=bvtUNDEFINED;
 try
  if CountArguments>0 then begin
{$ifdef BESENSingleStringType}
   FileName:=BESENInstance.ToStr(Arguments^[0]^));
{$else}
   FileName:=BESENEncodeString(BESENUTF16ToUTF8(BESENInstance.ToStr(Arguments^[0]^)),UTF_8,BESENLocaleCharset);
{$endif}
   Content:='';
   fm:=filemode;
   filemode:=0;
   assignfile(f,string(FileName));
   {$i-}reset(f,1);{$i+};
   if ioresult=0 then begin
    SetLength(Content,filesize(f));
    if length(Content)>0 then begin
     {$i-}blockread(f,Content[1],length(Content));{$i+}
     if ioresult<>0 then begin
      {$i-}closefile(f);{$i+}
      filemode:=fm;
      raise EBESENError.Create('FileError',TBESENString('Couldn''t load file "'+String(FileName)+'"'));
      exit;
     end;
    end;
    ResultValue:=BESENInstance.Execute({$ifndef BESENSingleStringType}BESENConvertToUTF8({$endif}Content{$ifndef BESENSingleStringType}){$endif});
    {$i-}closefile(f);{$i+}
    if ioresult=0 then begin
    end;
    filemode:=fm;
   end else begin
    {$i-}closefile(f);{$i+}
    if ioresult=0 then begin
    end;
    filemode:=fm;
    raise EBESENError.Create('FileError',TBESENString('Couldn''t load file "'+String(FileName)+'"'));
   end;
  end else begin
   raise EBESENError.Create('FileError','Too few arguments');
  end;
 finally
 end;
end;

procedure TAssembler.BESENObjectGarbageCollectorNativeRun(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
begin
 ResultValue.ValueType:=bvtUNDEFINED;
 BESENInstance.GarbageCollector.CollectAll;
end;

procedure TAssembler.BESENObjectAssemblerNativeDefineFunction(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
var //v:PBESENValue;
    Name:widestring;
    FunctionObjectValue:TBESENValue;
begin
 ResultValue.ValueType:=bvtUNDEFINED;
 if CountArguments>=2 then begin
  Name:=BESENInstance.ToStr(Arguments^[0]^);
  FunctionObjectValue:=Arguments^[1]^;
  case FunctionObjectValue.ValueType of
   bvtOBJECT:begin
    if FunctionObjectValue.Obj is TBESENObject then begin
     BESENInstance.GarbageCollector.AddProtected(TBESENObject(FunctionObjectValue.Obj));
    end;
   end;
  end;
  BESENObjectFunctions.OverwriteData(Name,FunctionObjectValue,[bopaWRITABLE,bopaCONFIGURABLE]);
 end else begin
  raise EBESENError.Create('Too few arguments');
 end;
end;

procedure TAssembler.BESENObjectAssemblerNativeDefineMacro(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
var //v:PBESENValue;
    SymbolName,UpperCaseSymbolName:widestring;
    SymbolType:TSymbolTreeLinkType;
    SymbolValue:TSymbolTreeLink;
    FunctionObjectValue:TBESENValue;
    Index:longint;
    Symbol:TUserSymbol;
begin
 ResultValue.ValueType:=bvtUNDEFINED;
 if CountArguments>=2 then begin
  SymbolName:=BESENInstance.ToStr(Arguments^[0]^);
  FunctionObjectValue:=Arguments^[1]^;
  case FunctionObjectValue.ValueType of
   bvtOBJECT:begin
    if FunctionObjectValue.Obj is TBESENObject then begin
     BESENInstance.GarbageCollector.AddProtected(TBESENObject(FunctionObjectValue.Obj));
     BESENObjectMacros.OverwriteData(SymbolName,FunctionObjectValue,[bopaWRITABLE,bopaCONFIGURABLE]);
     if not UserSymbolTree.Find(AnsiString(SymbolName),SymbolType,SymbolValue) then begin
      UpperCaseSymbolName:=UpperCase(SymbolName);
      UserSymbolList.NewClass(Index,AnsiString(UpperCaseSymbolName),AnsiString(SymbolName));
      UserSymbolTree.Add(AnsiString(UpperCaseSymbolName),stUSER,Index);
      SymbolType:=stUSER;
      SymbolValue:=Index;
      Symbol:=UserSymbolList[SymbolValue];
      Symbol.SymbolType:=ustSCRIPTMACRO;
      Symbol.BESENObject:=TBESENObject(FunctionObjectValue.Obj);
     end;
    end;
   end;
   else begin
    raise EBESENError.Create('Second argument must be a function');
   end;
  end;
 end else begin
  raise EBESENError.Create('Too few arguments');
 end;
end;

procedure TAssembler.BESENObjectAssemblerNativeParse(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
var i:longint;
    v:PBESENValue;
    fOutput:widestring;
    OldCurrentFileName:ansistring;
    OldCurrentLineNumber,OldCurrentColumn,OldCurrentSource:longint;
 procedure writeit(s:widestring);
 begin
  fOutput:=fOutput+s;
 end;
begin
 fOutput:='';
 ResultValue.ValueType:=bvtUNDEFINED;
 for i:=0 to CountArguments-1 do begin
  v:=Arguments^[i];
  case v^.ValueType of
   bvtUNDEFINED:begin
    writeit('undefined');
   end;
   bvtNULL:begin
    writeit('null');
   end;
   bvtBOOLEAN:begin
    if v^.Bool then begin
     writeit('true');
    end else begin
     writeit('false');
    end;
   end;
   bvtNUMBER:begin
    writeit(BESENFloatToStr(v^.Num));
   end;
   bvtSTRING:begin
    writeit(v^.Str);
   end;
   bvtOBJECT:begin
    writeit(BESENInstance.ToStr(v^));
   end;
   bvtREFERENCE:begin
    writeit('reference');
   end;
  end;
 end;
 OldCurrentFileName:=CurrentFileName;
 OldCurrentLineNumber:=CurrentLineNumber;
 OldCurrentColumn:=CurrentColumn;
 OldCurrentSource:=CurrentSource;
 try
  ParseString(BESENUTF16ToUTF8(fOutput));
 finally
  CurrentFileName:=OldCurrentFileName;
  CurrentLineNumber:=OldCurrentLineNumber;
  CurrentColumn:=OldCurrentColumn;
  CurrentSource:=OldCurrentSource;
 end;
end;

procedure TAssembler.BESENObjectAssemblerNativeError(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
var i:longint;
    v:PBESENValue;
    fOutput:widestring;
 procedure writeit(s:widestring);
 begin
  fOutput:=fOutput+s;
 end;
begin
 fOutput:='';
 ResultValue.ValueType:=bvtUNDEFINED;
 for i:=0 to CountArguments-1 do begin
  v:=Arguments^[i];
  case v^.ValueType of
   bvtUNDEFINED:begin
    writeit('undefined');
   end;
   bvtNULL:begin
    writeit('null');
   end;
   bvtBOOLEAN:begin
    if v^.Bool then begin
     writeit('true');
    end else begin
     writeit('false');
    end;
   end;
   bvtNUMBER:begin
    writeit(BESENFloatToStr(v^.Num));
   end;
   bvtSTRING:begin
    writeit(v^.Str);
   end;
   bvtOBJECT:begin
    writeit(BESENInstance.ToStr(v^));
   end;
   bvtREFERENCE:begin
    writeit('reference');
   end;
  end;
 end;
 MakeError(BESENUTF16ToUTF8(fOutput));
end;

procedure TAssembler.BESENObjectAssemblerNativeWarning(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
var i:longint;
    v:PBESENValue;
    fOutput:widestring;
 procedure writeit(s:widestring);
 begin
  fOutput:=fOutput+s;
 end;
begin
 fOutput:='';
 ResultValue.ValueType:=bvtUNDEFINED;
 for i:=0 to CountArguments-1 do begin
  v:=Arguments^[i];
  case v^.ValueType of
   bvtUNDEFINED:begin
    writeit('undefined');
   end;
   bvtNULL:begin
    writeit('null');
   end;
   bvtBOOLEAN:begin
    if v^.Bool then begin
     writeit('true');
    end else begin
     writeit('false');
    end;
   end;
   bvtNUMBER:begin
    writeit(BESENFloatToStr(v^.Num));
   end;
   bvtSTRING:begin
    writeit(v^.Str);
   end;
   bvtOBJECT:begin
    writeit(BESENInstance.ToStr(v^));
   end;
   bvtREFERENCE:begin
    writeit('reference');
   end;
  end;
 end;
 MakeWarning(BESENUTF16ToUTF8(fOutput));
end;

procedure TAssembler.BESENObjectAssemblerNativeGetCurrentBits(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
begin
 ResultValue:=BESENNumberValue(CurrentBits);
end;

procedure TAssembler.BESENObjectAssemblerNativeGetCurrentTarget(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
var TargetName:WideString;
begin
 case Target of
  ttBIN:begin
   TargetName:='bin';
  end;
  ttCOM:begin
   TargetName:='com';
  end;
  ttMZEXE:begin
   TargetName:='mzexe';
  end;
  ttPEEXE32:begin
   TargetName:='pe32';
  end;
  ttPEEXE64:begin
   TargetName:='pe64';
  end;
  ttCOFFDOS:begin
   TargetName:='coffdos';
  end;
  ttCOFF32:begin
   TargetName:='coff32';
  end;
  ttCOFF64:begin
   TargetName:='coff64';
  end;
  ttELF32:begin
   TargetName:='elf32';
  end;
  ttELFX32:begin
   TargetName:='elfx32';
  end;
  ttELF64:begin
   TargetName:='elf64';
  end;
  ttOMF16:begin
   TargetName:='omf16';
  end;
  ttOMF32:begin
   TargetName:='omf32';
  end;
  ttUNIT:begin
   TargetName:='unit';
  end;
  ttRUNTIME:begin
   TargetName:='runtime';
  end;
  ttTRI32:begin
   TargetName:='tri32';
  end;
  ttTRI64:begin
   TargetName:='tri64';
  end;
  else begin
   TargetName:='unknown';
  end;
 end;
 ResultValue:=BESENStringValue(TargetName);
end;                     

procedure TAssembler.BESENObjectAssemblerNativeGetBasePosition(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
begin
 if FixUpPass<>FUP_NONE then begin
  ResultValue:=BESENNumberValue(FixUpPassBase);
 end else begin
  if assigned(CurrentSection) then begin
   ResultValue:=BESENNumberValue(0);
  end else begin
   ResultValue:=BESENNumberValue(StartOffset);
  end;
 end;
end;

procedure TAssembler.BESENObjectAssemblerNativeGetHerePosition(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
begin
 if FixUpPass<>FUP_NONE then begin
  ResultValue:=BESENNumberValue(FixUpPassHere);
 end else begin
  if assigned(CurrentSection) then begin
   ResultValue:=BESENNumberValue(CodePosition);
  end else begin
   ResultValue:=BESENNumberValue(CodePosition+StartOffset);
  end;
 end;
end;

procedure TAssembler.BESENObjectAssemblerNativeIsLastPass(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
begin
 ResultValue:=BESENBooleanValue(CodeImageWriting);
end;

procedure TAssembler.BESENObjectAssemblerNativeRead8(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
 function ToInt64(const AValue:TBESENValue):int64;
 var v:TBESENValue;
 begin
  BESENInstance.ToNumberValue(AValue,v);
  if BESENIsNaN(v.Num) or BESENIsInfinite(v.Num) or BESENIsZero(v.Num) then begin
   v.Num:=0.0;
  end;
  result:=trunc(v.Num);
 end;
var Offset:int64;
begin
 if CountArguments>0 then begin
  Offset:=ToInt64(Arguments^[0]^);
  if FixUpPass<>FUP_NONE then begin
   ResultValue:=BESENNumberValue(0);
  end else begin
   if assigned(CurrentSection) then begin
    if (Offset>=0) and (Offset<CurrentSection^.Data.Size) then begin
     ResultValue:=BESENNumberValue(StreamGetByte(CurrentSection^.Data,Offset));
    end else begin
     ResultValue:=BESENNumberValue(0);
    end;
   end else begin
    dec(Offset,StartOffset);
    if (Offset>=0) and (Offset<CodeImage.Size) then begin
     ResultValue:=BESENNumberValue(StreamGetByte(CodeImage,Offset));
    end else begin
     ResultValue:=BESENNumberValue(0);
    end;
   end;
  end;
 end else begin
  raise EBESENError.Create('Too few arguments');
 end;
end;

procedure TAssembler.BESENObjectAssemblerNativeRead16(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
 function ToInt64(const AValue:TBESENValue):int64;
 var v:TBESENValue;
 begin
  BESENInstance.ToNumberValue(AValue,v);
  if BESENIsNaN(v.Num) or BESENIsInfinite(v.Num) or BESENIsZero(v.Num) then begin
   v.Num:=0.0;
  end;
  result:=trunc(v.Num);
 end;
var Offset:int64;
begin
 if CountArguments>0 then begin
  Offset:=ToInt64(Arguments^[0]^);
  if FixUpPass<>FUP_NONE then begin
   ResultValue:=BESENNumberValue(0);
  end else begin
   if assigned(CurrentSection) then begin
    if (Offset>=0) and ((Offset+1)<CurrentSection^.Data.Size) then begin
     ResultValue:=BESENNumberValue(StreamGetWord(CurrentSection^.Data,Offset));
    end else begin
     ResultValue:=BESENNumberValue(0);
    end;
   end else begin
    dec(Offset,StartOffset);
    if (Offset>=0) and ((Offset+1)<CodeImage.Size) then begin
     ResultValue:=BESENNumberValue(StreamGetWord(CodeImage,Offset));
    end else begin
     ResultValue:=BESENNumberValue(0);
    end;
   end;
  end;
 end else begin
  raise EBESENError.Create('Too few arguments');
 end;
end;

procedure TAssembler.BESENObjectAssemblerNativeRead32(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
 function ToInt64(const AValue:TBESENValue):int64;
 var v:TBESENValue;
 begin
  BESENInstance.ToNumberValue(AValue,v);
  if BESENIsNaN(v.Num) or BESENIsInfinite(v.Num) or BESENIsZero(v.Num) then begin
   v.Num:=0.0;
  end;
  result:=trunc(v.Num);
 end;
var Offset:int64;
begin
 if CountArguments>0 then begin
  Offset:=ToInt64(Arguments^[0]^);
  if FixUpPass<>FUP_NONE then begin
   ResultValue:=BESENNumberValue(0);
  end else begin
   if assigned(CurrentSection) then begin
    if (Offset>=0) and ((Offset+3)<CurrentSection^.Data.Size) then begin
     ResultValue:=BESENNumberValue(StreamGetDWord(CurrentSection^.Data,Offset));
    end else begin
     ResultValue:=BESENNumberValue(0);
    end;
   end else begin
    dec(Offset,StartOffset);
    if (Offset>=0) and ((Offset+3)<CodeImage.Size) then begin
     ResultValue:=BESENNumberValue(StreamGetDWord(CodeImage,Offset));
    end else begin
     ResultValue:=BESENNumberValue(0);
    end;
   end;
  end;
 end else begin
  raise EBESENError.Create('Too few arguments');
 end;
end;

procedure TAssembler.BESENObjectAssemblerNativeWrite8(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
 function ToUInt8(const AValue:TBESENValue):byte;
 var v:TBESENValue;
     Sign:longword;
 begin
  BESENInstance.ToNumberValue(AValue,v);
  if BESENIsNaN(v.Num) or BESENIsInfinite(v.Num) or BESENIsZero(v.Num) then begin
   v.Num:=0.0;
  end else begin
   Sign:=PBESENDoubleHiLo(@v.Num)^.Hi and $80000000;
   PBESENDoubleHiLo(@v.Num)^.Hi:=PBESENDoubleHiLo(@v.Num)^.Hi and $7fffffff;
   v.Num:=BESENFloor(v.Num);
   PBESENDoubleHiLo(@v.Num)^.Hi:=PBESENDoubleHiLo(@v.Num)^.Hi or Sign;
   v.Num:=BESENModulo(System.int(v.Num),256.0);
   if (PBESENDoubleHiLo(@v.Num)^.Hi and $80000000)<>0 then begin
    v.Num:=v.Num+256.0;
   end;
  end;
  result:=trunc(v.Num);
 end;
var i:longint;
begin
 ResultValue.ValueType:=bvtUNDEFINED;
 for i:=0 to CountArguments-1 do begin
  WriteByte(ToUInt8(Arguments^[i]^));
 end;
end;

procedure TAssembler.BESENObjectAssemblerNativeWrite16(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
 function ToUInt16(const AValue:TBESENValue):TBESENUINT16;
 var v:TBESENValue;
     Sign:longword;
 begin
  BESENInstance.ToNumberValue(AValue,v);
  if BESENIsNaN(v.Num) or BESENIsInfinite(v.Num) or BESENIsZero(v.Num) then begin
   v.Num:=0.0;
  end else begin
   Sign:=PBESENDoubleHiLo(@v.Num)^.Hi and $80000000;
   PBESENDoubleHiLo(@v.Num)^.Hi:=PBESENDoubleHiLo(@v.Num)^.Hi and $7fffffff;
   v.Num:=BESENFloor(v.Num);
   PBESENDoubleHiLo(@v.Num)^.Hi:=PBESENDoubleHiLo(@v.Num)^.Hi or Sign;
   v.Num:=BESENModulo(System.int(v.Num),65536.0);
   if (PBESENDoubleHiLo(@v.Num)^.Hi and $80000000)<>0 then begin
    v.Num:=v.Num+65536.0;
   end;
  end;
  result:=trunc(v.Num);
 end;
var i:longint;
begin
 ResultValue.ValueType:=bvtUNDEFINED;
 for i:=0 to CountArguments-1 do begin
  WriteWord(ToUInt16(Arguments^[i]^));
 end;
end;

procedure TAssembler.BESENObjectAssemblerNativeWrite32(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:longint;var ResultValue:TBESENValue);
 function ToUInt32(const AValue:TBESENValue):TBESENUINT32;
 var v:TBESENValue;
     Sign:longword;
 begin
  BESENInstance.ToNumberValue(AValue,v);
  if BESENIsNaN(v.Num) or BESENIsInfinite(v.Num) or BESENIsZero(v.Num) then begin
   v.Num:=0.0;
  end else begin
   Sign:=PBESENDoubleHiLo(@v.Num)^.Hi and $80000000;
   PBESENDoubleHiLo(@v.Num)^.Hi:=PBESENDoubleHiLo(@v.Num)^.Hi and $7fffffff;
   v.Num:=BESENFloor(v.Num);
   PBESENDoubleHiLo(@v.Num)^.Hi:=PBESENDoubleHiLo(@v.Num)^.Hi or Sign;
   v.Num:=BESENModulo(System.int(v.Num),4294967296.0);
   if (PBESENDoubleHiLo(@v.Num)^.Hi and $80000000)<>0 then begin
    v.Num:=v.Num+4294967296.0;
   end;
  end;
  result:=trunc(v.Num);
 end;
var i:longint;
begin
 ResultValue.ValueType:=bvtUNDEFINED;
 for i:=0 to CountArguments-1 do begin
  WriteDWord(ToUInt32(Arguments^[i]^));
 end;
end;
{$endif}

procedure TAssembler.Clear;
var FixUpExpression,NextFixUpExpression:PFixUpExpression;
    Segment,NextSegment:PAssemblerSegment;
    Section,NextSection:PAssemblerSection;
    //i:longint;
begin
 EvaluateHereOffset:=0;
{$ifdef SASMBESEN}
 ClearScript;
{$endif}
 ImportByHashCodeInserted:=false;
 UnitName:='';
 FileStringList.Clear;
 FileSymbolTree.Destroy;
 UserSymbolTree.Destroy;
 UserSymbolTree:=TSymbolTree.Create;
 FileSymbolTree:=TSymbolTree.Create;
 FixUpExpression:=StartFixUpExpression;
 while assigned(FixUpExpression) do begin
  NextFixUpExpression:=FixUpExpression^.Next;
  FreeAndNil(FixUpExpression^.Expression);
  FixUpExpression^.BoundWarningOrError:='';
  FreeMem(FixUpExpression);
  FixUpExpression:=NextFixUpExpression;
 end;
 Segment:=StartSegment;
 while assigned(Segment) do begin
  NextSegment:=Segment^.Next;
  FreeMem(Segment);
  Segment:=NextSegment;
 end;
 Section:=StartSection;
 while assigned(Section) do begin
  NextSection:=Section^.Next;
  FreeAndNil(Section^.Flags);
  FreeAndNil(Section^.Align);
  FreeAndNil(Section^.Data);
  FreeAndNil(Section^.FixUpExpressions);
  FreeAndNil(Section^.RelocationFixUpExpressions);
  FreeMem(Section);
  Section:=NextSection;
 end;
 StartFixUpExpression:=nil;
 FreeCode(StartCode);
 StartCode:=nil;
 LastFixUpExpression:=nil;
 LastCode:=nil;
 StartSegment:=nil;
 LastSegment:=nil;
 StartSection:=nil;
 LastSection:=nil;
 CodeImage.Clear;
 CodeImageWriting:=false;
 CodePosition:=0;
 CurrentSegment:=nil;
 CurrentSection:=nil;
 TotalSize:=0;
 CurrentFileName:='';
 CurrentLineNumber:=1;
 CurrentColumn:=0;
 LastCurrentLineNumber:=1;
 LastCurrentColumn:=0;
 CurrentSource:=0;
 CurrentLocal:=0;
 Errors:='';
 AreErrors:=false;
 Warnings:='';
 AreWarnings:=false;
 RepeatCounter:=0;
 EntryPointSection:=nil;
 EntryPoint:=0;
 UserEntryPoint:=0;
 ImportHashTablePosition:=0;
 ImportList.Clear;
 ImportLibraryList.Clear;
 ExportList.Clear;
 if assigned(RuntimeCodeImage) then begin
{$ifdef WIN32}
  VirtualFree(RuntimeCodeImage,0,MEM_RELEASE);
{$else}
{$ifdef UNIX}
  fpmunmap(RuntimeCodeImage,RuntimeCodeImageSize);
{$else}
  FreeMem(RuntimeCodeImage);
{$endif}
{$endif}
  RuntimeCodeImage:=nil;
 end;
 RuntimeCodeImageSize:=0;
 RuntimeCodeImageEntryPoint:=nil;
 CurrentLibrary:='';
{$ifdef DEBUGGER}
 ResetDebuggerData;
{$endif}
 ResetOptions;
end;

{$ifdef DEBUGGER}
procedure TAssembler.ResetDebuggerData;
begin
end;
{$endif}

procedure TAssembler.ResetOptions;
begin
 IsStartOffsetSet:=false;
 EntryPointSection:=nil;
 EntryPoint:=0;
 UserEntryPoint:=0;
 CPULevel:=IF_IA64;
 CurrentBits:=32;
 CurrentLocal:=0;
 CodeEnd:=-1;
end;

procedure TAssembler.FreeCode(StartCode:PCode);
var OldCode,Code:PCode;
    Counter:longint;
begin
 if assigned(StartCode) then begin
  Code:=StartCode;
  while assigned(Code) do begin
   FreeCode(Code^.Down);
   FreeCode(Code^.ElseDown);
   OldCode:=Code;
   Code:=Code^.Next;
   OldCode^.StringData:='';
   OldCode^.WideStringData:='';
   FreeAndNil(OldCode^.Expression);
   FreeAndNil(OldCode^.SecondExpression);
   for Counter:=1 to MaxOperands do begin
    OldCode^.Instruction.Operand[Counter].Scale.Free;
    OldCode^.Instruction.Operand[Counter].Value.Free;
   end;
   FreeMem(OldCode);
  end;
 end;
end;

function TAssembler.NewFixUpExpression:PFixUpExpression;
begin
 GetMem(result,SizeOf(TFixUpExpression));
 FillChar(result^,SizeOf(TFixUpExpression),#0);
 result^.Next:=nil;
 if assigned(LastFixUpExpression) then begin
  LastFixUpExpression^.Next:=result;
 end else begin
  StartFixUpExpression:=result;
 end;
 LastFixUpExpression:=result;
end;

function TAssembler.NewCode:PCode;
begin
 GetMem(result,SizeOf(TCode));
 FillChar(result^,SizeOf(TCode),#0);
 result^.Value:=0;
 result^.SymbolIndex:=-1;
 result^.StructSymbolIndex:=-1;
 result^.ItemStructSymbolIndex:=-1;
 result^.ItemSize:=0;
 result^.Expression:=nil;
 result^.Link:=nil;
 result^.Up:=nil;
 result^.Down:=nil;
 result^.ElseDown:=nil;
 result^.Next:=nil;
 if assigned(LastCode) then begin
  result^.Previous:=LastCode;
  LastCode^.Next:=result;
 end else begin
  result^.Previous:=nil;
  StartCode:=result;
 end;
 LastCode:=result;
end;

function TAssembler.NewCodeEx:PCode;
begin
 GetMem(result,SizeOf(TCode));
 FillChar(result^,SizeOf(TCode),#0);
 result^.Value:=0;
 result^.SymbolIndex:=-1;
 result^.StructSymbolIndex:=-1;
 result^.ItemStructSymbolIndex:=-1;
 result^.ItemSize:=0;
 result^.Expression:=nil;
 result^.Link:=nil;
 result^.Up:=nil;
 result^.Down:=nil;
 result^.ElseDown:=nil;
 result^.Next:=nil;
 result^.Previous:=nil;
end;

procedure TAssembler.AddCode(Code:PCode);
begin
 if assigned(LastCode) then begin
  Code^.Previous:=LastCode;
  LastCode^.Next:=Code;
 end else begin
  Code^.Previous:=nil;
  StartCode:=Code;
 end;
 LastCode:=Code;
end;

procedure TAssembler.DeleteCode(CodeToDelete:PCode;NextCodeEx:PPCode=nil);
var Code,NextCode:PCode;
begin
 Code:=StartCode;
 while assigned(Code) do begin
  NextCode:=Code^.Next;
  if Code=CodeToDelete then begin
   if assigned(NextCodeEx) and (NextCodeEx^=CodeToDelete) then begin
    NextCodeEx^:=CodeToDelete^.Next;
   end;
   if Code^.Previous<>nil then begin
    Code^.Previous^.Next:=Code^.Next;
   end;
   if Code^.Next<>nil then begin
    Code^.Next^.Previous:=Code^.Previous;
   end;
   if LastCode=Code then begin
    LastCode:=Code^.Previous;
   end;
   FreeCode(Code^.Down);
   FreeCode(Code^.ElseDown);
   Code^.StringData:='';
   Code^.WideStringData:='';
   Code^.Expression.Free;
   Code^.SecondExpression.Free;
   FreeMem(Code);
   break;
  end;
  Code:=NextCode;
 end;
end;

function TAssembler.NewSegment:PAssemblerSegment;
begin
 GetMem(result,SizeOf(TAssemblerSegment));
 FillChar(result^,SizeOf(TAssemblerSegment),#0);
 result^.Position:=0;
 if assigned(LastSegment) then begin
  result^.Previous:=LastSegment;
  LastSegment^.Next:=result;
 end else begin
  result^.Previous:=nil;
  StartSegment:=result;
 end;
 LastSegment:=result;
end;

function TAssembler.GetSegmentPerName(Name:ansistring):PAssemblerSegment;
var Segment,FoundSegment:PAssemblerSegment;
begin
 FoundSegment:=nil;
 Segment:=StartSegment;
 while assigned(Segment) do begin
  if Segment^.Name=Name then begin
   FoundSegment:=Segment;
   break;
  end;
  Segment:=Segment^.Next;
 end;
 if assigned(FoundSegment) then begin
  result:=FoundSegment;
 end else begin
  result:=NewSegment;
  result^.Name:=name;
 end;
end;

procedure TAssembler.ResetSegments;
var Segment:PAssemblerSegment;
begin
 Segment:=StartSegment;
 while assigned(Segment) do begin
//Segment^.Data.Clear;
  Segment^.Position:=0;
  Segment:=Segment^.Next;
 end;
end;

function TAssembler.CountSegments:longint;
var Segment:PAssemblerSegment;
begin
 result:=0;
 Segment:=StartSegment;
 while assigned(Segment) do begin
  inc(result);
  Segment:=Segment^.Next;
 end;
end;

function TAssembler.GetSegment(Number:longint):PAssemblerSegment;
var Segment:PAssemblerSegment;
    Counter:longint;
begin
 result:=nil;
 Counter:=0;
 Segment:=StartSegment;
 while assigned(Segment) do begin
  if Counter=Number then begin
   result:=Segment;
   exit;
  end;
  inc(Counter);
  Segment:=Segment^.Next;
 end;
end;

function TAssembler.GetSegmentNumber(ASegment:PAssemblerSegment):longint;
var Segment:PAssemblerSegment;
begin
 result:=0;
 Segment:=StartSegment;
 while assigned(Segment) do begin
  if ASegment=Segment then exit;
  inc(result);
  Segment:=Segment^.Next;
 end;
end;

function TAssembler.NewSection:PAssemblerSection;
begin
 GetMem(result,SizeOf(TAssemblerSection));
 FillChar(result^,SizeOf(TAssemblerSection),#0);
 result^.Flags:=nil;
 result^.Align:=nil;
 result^.Data:=TMemoryStream.Create;
 result^.FixUpExpressions:=TList.Create;
 result^.RelocationFixUpExpressions:=TList.Create;
 result^.Position:=0;
 if assigned(LastSection) then begin
  result^.Previous:=LastSection;
  LastSection^.Next:=result;
 end else begin
  result^.Previous:=nil;
  StartSection:=result;
 end;
 LastSection:=result;
end;

function TAssembler.GetSectionPerName(Name:ansistring):PAssemblerSection;
var Section,FoundSection:PAssemblerSection;
begin
 FoundSection:=nil;
 Section:=StartSection;
 while assigned(Section) do begin
  if Section^.Name=Name then begin
   FoundSection:=Section;
   break;
  end;
  Section:=Section^.Next;
 end;
 if assigned(FoundSection) then begin
  result:=FoundSection;
 end else begin
  result:=NewSection;
  result^.Name:=name;
 end;
end;

procedure TAssembler.ResetSections;
var Section:PAssemblerSection;
begin
 Section:=StartSection;
 while assigned(Section) do begin
  Section^.Data.Clear;
  Section^.FixUpExpressions.Clear;
  Section^.RelocationFixUpExpressions.Clear;
  Section^.Position:=0;
  Section:=Section^.Next;
 end;
end;

function TAssembler.CountSections:longint;
var Section:PAssemblerSection;
begin
 result:=0;
 Section:=StartSection;
 while assigned(Section) do begin
  inc(result);
  Section:=Section^.Next;
 end;
end;

function TAssembler.GetSection(Number:longint):PAssemblerSection;
var Section:PAssemblerSection;
    Counter:longint;
begin
 result:=nil;
 Counter:=0;
 Section:=StartSection;
 while assigned(Section) do begin
  if Counter=Number then begin
   result:=Section;
   exit;
  end;
  inc(Counter);
  Section:=Section^.Next;
 end;
end;

function TAssembler.GetSectionNumber(ASection:PAssemblerSection):longint;
var Section:PAssemblerSection;
begin
 result:=0;
 Section:=StartSection;
 while assigned(Section) do begin
  if ASection=Section then begin
   exit;
  end;
  inc(result);
  Section:=Section^.Next;
 end;
end;

procedure TAssembler.WriteCountDummyBytes(c:longint);
begin
 while c>0 do begin
  dec(c);
  WriteByte(0);
 end;
end;

procedure TAssembler.WriteByte(Value:int64);
begin
 if (Value<0) and (Value>=-$80) then begin
  Value:=$ff+(Value+1);
 end;
 if CodeImageWriting then begin
  if (Value<0) or (Value>$ff) then begin
   if Value<0 then begin
    MakeWarning(0,-Value);
   end else if Value>$ff then begin
    MakeWarning(0,Value-$ff);
   end;
  end;
  if assigned(CurrentSection) then begin
   StreamWriteByte(CurrentSection^.Data,Value);
  end else if (CodeEnd<0) or (CodePosition<CodeEnd) then begin
   StreamWriteByte(CodeImage,Value);
  end;
 end;
 inc(CodePosition);
end;

procedure TAssembler.WriteByteCount(const Value:byte;const Count:longint);
var i:longint;
begin
 for i:=1 to Count do begin
  WriteByte(Value);
 end;
end;

procedure TAssembler.WriteWord(Value:int64);
begin
 if (Value<0) and (Value>=-$8000) then begin
  Value:=$ffff+(Value+1);
 end;
 if CodeImageWriting then begin
  if (Value<0) or (Value>$ffff) then begin
   if Value<0 then begin
    MakeWarning(1,-Value);
   end else if Value>$ffff then begin
    MakeWarning(1,Value-$ffff);
   end;
  end;
 end;
 WriteByte(Value and $ff);
 WriteByte((Value and $ff00) shr 8);
end;

procedure TAssembler.WriteDWord(Value:int64);
var Max:int64;
begin
 Max:=-2147483647;
 dec(Max);
 if (Value<0) and (Value>=Max) then begin
  Value:=$ffffffff+(Value+1);
 end;
 if CodeImageWriting then begin
  if (Value<0) or (Value>$ffffffff) then begin
   if Value<0 then begin
    MakeWarning(2,-Value);
   end else if Value>$ffffffff then begin
    MakeWarning(2,Value-$ffffffff);
   end;
  end;
 end;
 WriteWord(Value and $ffff);
 WriteWord((Value and $ffff0000) shr 16);
end;

procedure TAssembler.WriteInt64(Value:int64);
begin
 if CodeImageWriting then begin
  if assigned(CurrentSection) then begin
   StreamWriteInt64(CurrentSection^.Data,Value);
  end else begin
   StreamWriteInt64(CodeImage,Value);
  end;
 end;
 inc(CodePosition,SizeOf(int64));
end;

procedure TAssembler.WriteQWord(Value:uint64);
begin
 if CodeImageWriting then begin
  if assigned(CurrentSection) then begin
   StreamWriteQWord(CurrentSection^.Data,Value);
  end else begin
   StreamWriteQWord(CodeImage,Value);
  end;
 end;
 inc(CodePosition,SizeOf(uint64));
end;

procedure TAssembler.ShowStatus(S:ansistring);
begin
 if assigned(Status) then Status(S);
end;

procedure TAssembler.MakeError(Error:longint;Overhead:int64=0);
var ErrorString:ansistring;
begin
 if not AreErrors then begin
  case Error of
   0:ErrorString:='Invalid operands';
   1:ErrorString:='Invalid opcode';
   2:ErrorString:='Invalid mod/rm';
   3:ErrorString:='Invalid prefix';
   4:ErrorString:='Invalid cpu keyword parameter';
   5:ErrorString:='Invalid cpu';
   6:ErrorString:='Invalid bits';
   7:ErrorString:='Invalid keyword';
   8:ErrorString:='Invalid control keyword';
   9:ErrorString:='Symbol not found';
   10:ErrorString:='Symbol too long';
   11:ErrorString:='String parse error';
   12:ErrorString:='Unknown symbol';
   13:ErrorString:='Symbol not allowed here';
   14:ErrorString:='User defined symbol expected';
   15:ErrorString:='Constant expression error';
   16:ErrorString:='Macro syntax error';
   17:ErrorString:='Symbol already defined';
   18:ErrorString:='Macro parameter count doesn''t match';
   19:ErrorString:='Expression syntax error';
   20:ErrorString:='Optimize syntax error';
   21:ErrorString:='Group syntax error';
   22:ErrorString:='Group expected';
   23:ErrorString:='File not found';
   24:ErrorString:='Struct syntax error';
   25:ErrorString:='Only allowed in struct';
   26:ErrorString:='Struct symbol-define syntax error';
   27:ErrorString:='User-defined label or constant symbol expected';
   28:ErrorString:='Smartlink syntax error';
   29:ErrorString:='New symbol expected';
   30:ErrorString:='Unit already linked';
   31:ErrorString:='No unit Name defined';
   32:ErrorString:='Couldn''t link unit';
   33:ErrorString:='Invalid unit';
   34:ErrorString:='BYTEDIFF syntax error';
   35:ErrorString:='Invalid segment register';
   36:ErrorString:='Too many segment registers';
   37:ErrorString:='Too many registers';
   38:ErrorString:='Comment syntax error';
   39:ErrorString:='Segment register prefix syntax error';
   40:ErrorString:='Invoke syntax error';
   41:ErrorString:='Invalid byte value range (Overhead: '+INT64TOSTR(Overhead)+')';
   42:ErrorString:='Invalid word value range (Overhead: '+INT64TOSTR(Overhead)+')';
   43:ErrorString:='Invalid dword value range (Overhead: '+INT64TOSTR(Overhead)+')';
   44:ErrorString:='Section syntax error';
   45:ErrorString:='External syntax error';
   46:ErrorString:='Public syntax error';
   47:ErrorString:='User-defined label symbol expected';
   48:ErrorString:='Syntax error';
   49:ErrorString:='Out of truncate bit range';
   50:ErrorString:='Ordinal value expected';
   51:ErrorString:='Short IF syntax error';
   52:ErrorString:='No sections';
   53:ErrorString:='Non 32-bit relative jump into another section is impossible';
   54:ErrorString:='This jump into another section is impossible';
   55:ErrorString:='Runtime code image size is smaller than the temporary code image size. Increase the count of passes, please!';
   56:ErrorString:='Invalid size specifier';
   57:ErrorString:='Conflicting address size specifications';
   58:ErrorString:='Conflicting opcode size specifications';
   59:ErrorString:='Prefixes at non-opcode not allowed';
   60:ErrorString:='Conflicting lock prefix';
   61:ErrorString:='Conflicting wait prefix';
   62:ErrorString:='Conflicting rep/repe/repz/repne/repnz/xacquire/xrelease prefix';
   63:ErrorString:='Invalid operand passed for rex processing';
   64:ErrorString:='segr6 and segr7 cannot be used as prefixes';
   65:ErrorString:='16-bit addressing is not supported in 64-bit mode';
   66:ErrorString:='64-bit addressing is only supported in 64-bit mode';
   67:ErrorString:='Segment syntax error';
   68:ErrorString:='Keyword or symbol expected';
   69:ErrorString:='Floating point constant must be outside a expression';
   70:ErrorString:='Unknown character';
   71:ErrorString:='Internal error';
   72:ErrorString:='Duplicate local';
   73:ErrorString:='Directory entry syntax error';
   74:ErrorString:='User symbol expected';
   else ErrorString:='';
  end;
  Errors:=Errors+'Error';
  if CurrentSource=SourceDefines then begin
   Errors:=Errors+'(defines)';
  end else if CurrentSource>0 then begin
   Errors:=Errors+'(file)['+FileStringList[CurrentSource-1]+']';
  end else if CurrentSource<0 then begin
   Errors:=Errors+'(macro)['+UserSymbolList[-(CurrentSource+1)].Name+']';
  end else begin
   Errors:=Errors+'(unknown)[?]';
  end;
  Errors:=Errors+'('+INTTOSTR(CurrentLineNumber)+','+INTTOSTR(CurrentColumn)+'): '+ErrorString+#13#10;
  AreErrors:=true;
 end;
end;

procedure TAssembler.MakeError(const Error:ansistring);
var ErrorString:ansistring;
begin
 if not AreErrors then begin
  ErrorString:=Error;
  Errors:=Errors+'Error';
  if CurrentSource=SourceDefines then begin
   Errors:=Errors+'(defines)';
  end else if CurrentSource>0 then begin
   Errors:=Errors+'(file)['+FileStringList[CurrentSource-1]+']';
  end else if CurrentSource<0 then begin
   Errors:=Errors+'(macro)['+UserSymbolList[-(CurrentSource+1)].Name+']';
  end else begin
   Errors:=Errors+'(unknown)[?]';
  end;
  Errors:=Errors+'('+INTTOSTR(CurrentLineNumber)+','+INTTOSTR(CurrentColumn)+'): '+ErrorString+#13#10;
  AreErrors:=true;
 end;
end;

procedure TAssembler.MakeWarning(Warning:longint;Overhead:int64=0);
var WarningString:ansistring;
begin
 case Warning of
  0:WarningString:='Invalid byte value range (Overhead: '+INT64TOSTR(Overhead)+')';
  1:WarningString:='Invalid word value range (Overhead: '+INT64TOSTR(Overhead)+')';
  2:WarningString:='Invalid dword value range (Overhead: '+INT64TOSTR(Overhead)+')';
  3:WarningString:='Symbol not found';
  4:WarningString:='Fix up in BSS range';
 end;
 Warnings:=Warnings+'Warning';
 if CurrentSource=SourceDefines then begin
  Warnings:=Warnings+'(defines)';
 end else if CurrentSource>0 then begin
  Warnings:=Warnings+'(file)['+FileStringList[CurrentSource-1]+']';
 end else if CurrentSource<0 then begin
  Warnings:=Warnings+'(macro)['+UserSymbolList[-(CurrentSource+1)].Name+']';
 end else begin
  Warnings:=Warnings+'(unknown)[?]';
 end;
 Warnings:=Warnings+'('+INTTOSTR(CurrentLineNumber)+','+INTTOSTR(CurrentColumn)+'): '+WarningString+#13#10;
 AreWarnings:=true;
end;

procedure TAssembler.MakeWarning(const Warning:ansistring);
var WarningString:ansistring;
begin
 WarningString:=Warning;
 Warnings:=Warnings+'Warning';
 if CurrentSource=SourceDefines then begin
  Warnings:=Warnings+'(defines)';
 end else if CurrentSource>0 then begin
  Warnings:=Warnings+'(file)['+FileStringList[CurrentSource-1]+']';
 end else if CurrentSource<0 then begin
  Warnings:=Warnings+'(macro)['+UserSymbolList[-(CurrentSource+1)].Name+']';
 end else begin
  Warnings:=Warnings+'(unknown)[?]';
 end;
 Warnings:=Warnings+'('+INTTOSTR(CurrentLineNumber)+','+INTTOSTR(CurrentColumn)+'): '+WarningString+#13#10;
 AreWarnings:=true;
end;

procedure TAssembler.AddFixUpExpression(const Expression:TAssemblerExpression;const Flags,Bits:longword;const Relative:boolean;const Signed,LineNumber,Column,Source,ManualBoundMode:longint;const MinBound,MaxBound:uint64;const BoundWarningOrError:ansistring;const HereOffset:longint);
var FixUpExpression:PFixUpExpression;
    //MustAddSymbol:boolean;
    //OldExpression:TAssemblerExpression;
begin
 if assigned(Expression) then begin
  Expression.UseIt(self);
 end;
 if CodeImageWriting then begin
  FixUpExpression:=NewFixUpExpression;
  FixUpExpression^.Segment:=CurrentSegment;
  FixUpExpression^.Section:=CurrentSection;
  FixUpExpression^.Position:=CodePosition;
  FixUpExpression^.Flags:=Flags;
  if assigned(Expression) then begin
   EvaluateHereOffset:=HereOffset;
   FixUpExpression^.Expression:=TAssemblerExpression.Create;
   FixUpExpression^.Expression.Assign(Expression);
   FixUpExpression^.Expression.Freeze(self,false);
   while FixUpExpression^.Expression.Optimize(self) do begin
   end;
   EvaluateHereOffset:=0;
  end else begin
   FixUpExpression^.Expression:=nil;
  end;
  FixUpExpression^.Bits:=Bits;
  FixUpExpression^.Signed:=Signed;
  FixUpExpression^.Relative:=Relative;
  FixUpExpression^.Relocation:=false;
  FixUpExpression^.Symbol:=nil;
  FixUpExpression^.LineNumber:=LineNumber;
  FixUpExpression^.Column:=Column;
  FixUpExpression^.Source:=Source;
  FixUpExpression^.ManualBoundMode:=ManualBoundMode;
  FixUpExpression^.MinBound:=MinBound;
  FixUpExpression^.MaxBound:=MaxBound;
  FixUpExpression^.BoundWarningOrError:=BoundWarningOrError;
  FixUpExpression^.HereOffset:=HereOffset;
 end;
end;

procedure TAssembler.WritePadding(Value:int64);
var PartCount:int64;
begin
 case CurrentBits of
  16:begin
   while Value>0 do begin
    if Value<16 then begin
     PartCount:=Value;
    end else begin
     PartCount:=15;
    end;
    case PartCount of
     1:begin
      // nop
      WriteByte($90);
      dec(Value);
     end;
     2:begin
      // mov si,si
      WriteByte($89);
      WriteByte($f6);
      dec(Value,2);
     end;
     3:begin
      // lea si,[si+byte 0]
      WriteByte($8d);
      WriteByte($74);
      WriteByte($00);
      dec(Value,3);
     end;
     4:begin
      // lea si,[si+word 0]
      WriteByte($8d);
      WriteByte($b4);
      WriteByte($00);
      WriteByte($00);
      dec(Value,4);
     end;
     5:begin
      // nop
      WriteByte($90);
      // lea si,[si+word 0]
      WriteByte($8d);
      WriteByte($b4);
      WriteByte($00);
      WriteByte($00);
      dec(Value,5);
     end;
     6:begin
      // mov si,si
      WriteByte($89);
      WriteByte($f6);
      // lea si,[si+word 0]
      WriteByte($8d);
      WriteByte($b4);
      WriteByte($00);
      WriteByte($00);
      dec(Value,6);
     end;
     7:begin
      // lea si,[si+byte 0]
      WriteByte($8d);
      WriteByte($74);
      WriteByte($00);
      // lea si,[si+word 0]
      WriteByte($8d);
      WriteByte($b4);
      WriteByte($00);
      WriteByte($00);
      dec(Value,7);
     end;
     8:begin
      // lea si,[si+word 0]
      WriteByte($8d);
      WriteByte($b4);
      WriteByte($00);
      WriteByte($00);
      // lea si,[si+word 0]
      WriteByte($8d);
      WriteByte($b4);
      WriteByte($00);
      WriteByte($00);
      dec(Value,8);
     end;
     9..15:begin
      // jmp $+9; nop fill .. jmp $+15; nop fill ..
      WriteByte($eb);
      WriteByte(PartCount-2);
      WriteByteCount($90,PartCount-2);
      dec(Value,PartCount);
     end;
    end;
   end;
  end;
  32:begin
   while Value>0 do begin
    if Value<16 then begin
     PartCount:=Value;
    end else begin
     PartCount:=15;
    end;
    case PartCount of
     1:begin
      // nop
      WriteByte($90);
      dec(Value);
     end;
     2:begin
      // xchg ax, ax (o16 nop)
      WriteByte($66);
      WriteByte($90);
      dec(Value,2);
     end;
     3:begin
      // lea esi,[esi+byte 0]
      WriteByte($8d);
      WriteByte($76);
      WriteByte($00);
      dec(Value,3);
     end;
     4:begin
      // lea esi,[esi*1+byte 0]
      WriteByte($8d);
      WriteByte($74);
      WriteByte($26);
      WriteByte($00);
      dec(Value,4);
     end;
     5:begin
      // nop
      WriteByte($90);
      // lea esi,[esi*1+byte 0]
      WriteByte($8d);
      WriteByte($74);
      WriteByte($26);
      WriteByte($00);
      dec(Value,5);
     end;
     6:begin
      // lea esi,[esi+dword 0]
      WriteByte($8d);
      WriteByte($b6);
      WriteByte($00);
      WriteByte($00);
      WriteByte($00);
      WriteByte($00);
      dec(Value,6);
     end;
     7:begin
      // lea esi,[esi*1+dword 0]
      WriteByte($8d);
      WriteByte($b4);
      WriteByte($26);
      WriteByte($00);
      WriteByte($00);
      WriteByte($00);
      WriteByte($00);
      dec(Value,7);
     end;
     8:begin
      // nop
      WriteByte($90);
      // lea esi,[esi*1+dword 0]
      WriteByte($8d);
      WriteByte($b4);
      WriteByte($26);
      WriteByte($00);
      WriteByte($00);
      WriteByte($00);
      WriteByte($00);
      dec(Value,8);
     end;
     9..15:begin
      // jmp $+9; nop fill .. jmp $+15; nop fill ..
      WriteByte($eb);
      WriteByte(PartCount-2);
      WriteByteCount($90,PartCount-2);
      dec(Value,PartCount);
     end;
    end;
   end;
  end;
  64:begin
   while Value>0 do begin
    if Value<16 then begin
     PartCount:=Value;
    end else begin
     PartCount:=15;
    end;
    case PartCount of
     1:begin
      // nop
      WriteByte($90);
      dec(Value);
     end;
     2:begin
      // xchg ax, ax (o16 nop)
      WriteByte($66);
      WriteByte($90);
      dec(Value,2);
     end;
     3:begin
      // nop(3)
      WriteByte($0f);
      WriteByte($1f);
      WriteByte($00);
      dec(Value,3);
     end;
     4:begin
      // nop(4)
      WriteByte($0f);
      WriteByte($1f);
      WriteByte($40);
      WriteByte($00);
      dec(Value,4);
     end;
     5:begin
      // nop(5)
      WriteByte($0f);
      WriteByte($1f);
      WriteByte($44);
      WriteByte($00);
      WriteByte($00);
      dec(Value,5);
     end;
     6:begin
      // nop(6)
      WriteByte($66);
      WriteByte($0f);
      WriteByte($1f);
      WriteByte($44);
      WriteByte($00);
      WriteByte($00);
      dec(Value,6);
     end;
     7:begin
      // nop(7)
      WriteByte($0f);
      WriteByte($1f);
      WriteByte($80);
      WriteByte($00);
      WriteByte($00);
      WriteByte($00);
      WriteByte($00);
      dec(Value,7);
     end;
     8:begin
      // nop(8)
      WriteByte($0f);
      WriteByte($1f);
      WriteByte($84);
      WriteByte($00);
      WriteByte($00);
      WriteByte($00);
      WriteByte($00);
      WriteByte($00);
      dec(Value,8);
     end;
     9:begin
      // nop(9)
      WriteByte($66);
      WriteByte($0f);
      WriteByte($1f);
      WriteByte($84);
      WriteByte($00);
      WriteByte($00);
      WriteByte($00);
      WriteByte($00);
      WriteByte($00);
      dec(Value,9);
     end;
     10..15:begin
      // repeated-o16 cs: nop(10..15)
      WriteByteCount($66,PartCount-9);
      WriteByte($2e);
      WriteByte($0f);
      WriteByte($1f);
      WriteByte($84);
      WriteByte($00);
      WriteByte($00);
      WriteByte($00);
      WriteByte($00);
      WriteByte($00);
      dec(Value,PartCount);
     end;
    end;
   end;
  end;
 end;
end;

procedure TAssembler.AddASP(var Instruction:TInstruction;AddressBits:longint);
var j,Valid,DefaultDisplacementSize,DisplacementSize:longint;
    i,b:TOperandFlags;
    Scale:longword;
begin
 if AddressBits=64 then begin
  Valid:=32 or 64;
 end else begin
  Valid:=16 or 32;
 end;
 case Instruction.Prefixes[PPS_ASIZE] of
  P_A16:begin
   Valid:=Valid and 16;
  end;
  P_A32:begin
   Valid:=Valid and 32;
  end;
  P_A64:begin
   Valid:=Valid and 64;
  end;
  P_ASP:begin
   if AddressBits=32 then begin
    Valid:=Valid and 16;
   end else begin
    Valid:=Valid and 32;
   end;
  end;
 end;
 for j:=1 to Instruction.CountOperands do begin
  if ((not Instruction.Operand[j].Flags) and OF_MEMORY)=0 then begin
   if Instruction.Operand[j].IndexRegister<>RegNONE then begin
    i:=RegisterTemplates[Instruction.Operand[j].IndexRegister].RegisterClass;
   end else begin
    i:=0;
   end;
   if Instruction.Operand[j].BaseRegister<>RegNONE then begin
    b:=RegisterTemplates[Instruction.Operand[j].BaseRegister].RegisterClass;
   end else begin
    b:=0;
   end;
   if assigned(Instruction.Operand[j].Scale) then begin
    Scale:=ValueGetInt64(self,Instruction.Operand[j].Scale.Evaluate(self),false);
   end else begin
    Scale:=0;
   end;
   if Scale=0 then begin
    i:=0;
   end;
   if (i=0) and (b=0) then begin
    DisplacementSize:=Instruction.Operand[j].DisplacmentSize;
    if ((AddressBits<>64) and (DisplacementSize>8)) or ((AddressBits=64) and (DisplacementSize=16)) then begin
     Valid:=Valid and DisplacementSize;
    end;
   end else begin
    if ((not b) and OF_REG16)=0 then begin
     Valid:=Valid and 16;
    end;
    if ((not b) and OF_REG32)=0 then begin
     Valid:=Valid and 32;
    end;
    if ((not b) and OF_REG64)=0 then begin
     Valid:=Valid and 64;
    end;
    if ((not i) and OF_REG16)=0 then begin
     Valid:=Valid and 16;
    end;
    if ((not i) and OF_REG32)=0 then begin
     Valid:=Valid and 32;
    end;
    if ((not i) and OF_REG64)=0 then begin
     Valid:=Valid and 64;
    end;
   end;
  end;
 end;
 if (Valid and AddressBits)<>0 then begin
  Instruction.AddressSize:=AddressBits;
 end else if (AddressBits=32) and ((Valid and 16)<>0) then begin
  Instruction.Prefixes[PPS_ASIZE]:=P_A16;
  Instruction.AddressSize:=16;
 end else if (AddressBits<>32) and ((Valid and 32)<>0) then begin
  Instruction.Prefixes[PPS_ASIZE]:=P_A32;
  Instruction.AddressSize:=32;
 end else begin
  Instruction.AddressSize:=AddressBits;
  MakeError('Impossible combination of address sizes');
 end;
 if Instruction.AddressSize=16 then begin
  DefaultDisplacementSize:=16;
 end else begin
  DefaultDisplacementSize:=32;
 end;
 for j:=1 to Instruction.CountOperands do begin
  if (((not Instruction.Operand[j].Flags) and OF_MEM_OFFS)=0) and
     (((Instruction.Operand[j].DisplacmentSize=0) and (DefaultDisplacementSize<>Instruction.AddressSize)) or
      ((Instruction.Operand[j].DisplacmentSize<>0) and (Instruction.Operand[j].DisplacmentSize<>Instruction.AddressSize))) then begin
   Instruction.Operand[j].Flags:=Instruction.Operand[j].Flags and not (OF_MEM_OFFS and not OF_MEMORY);
  end;
 end;
end;

function TAssembler.InstructionMatches(const InstructionTemplate:PInstructionTemplate;const Instruction:TInstruction;const Bits:longint):longint;
 function GetBroadcastNum(const opflags:TOperandFlags;const brsize:TDecoratorFlags):byte;
 var OpSize:TOperandFlags;
 begin
  OpSize:=opflags and SIZE_MASK;
  if brsize>OF_BITS64 then begin
   MakeError('Size of broadcasting element is greater than 64 bits');
  end;
  if OpSize=OF_BITS64 then begin
   result:=OF_BITS64 div brsize;
  end else begin
   result:=((OpSize div OF_BITS128)*(OF_BITS64 div brsize))*2;
  end;
 end;
var i,k,Operands:longint;
    brcast_num:byte;
    j,ASize,Flags,template_opsize,insn_opsize:TOperandFlags;
    DecoratorFlags,deco_brsize:TDecoratorFlags;
    Size:array[0..MaxOperands-1] of TOperandFlags;
    OpSizeMissing,IsBroadCast:boolean;
begin

 OpSizeMissing:=false;

 if InstructionTemplate^.Opcode<>Instruction.Opcode then begin
  result:=MATCH_ERROR_INVALID_OPCODE;
  exit;
 end;

 if InstructionTemplate^.CountOperands<>Instruction.CountOperands then begin
  result:=MATCH_ERROR_INVALID_OPCODE;
  exit;
 end;

 if (IF_OPT in InstructionTemplate^.Flags) and not (OptimizationLevel>0) then begin
  result:=MATCH_ERROR_INVALID_OPCODE;
  exit;
 end;

 case Instruction.Prefixes[PPS_VEX] of
  P_EVEX:begin
   if not (IF_EVEX in InstructionTemplate^.Flags) then begin
    result:=MATCH_ERROR_ENCODING_MISMATCH;
    exit;
   end;
  end;
  P_VEX3,P_VEX2:begin
   if not (IF_VEX in InstructionTemplate^.Flags) then begin
    result:=MATCH_ERROR_ENCODING_MISMATCH;
    exit;
   end;
  end;
 end;

 for i:=0 to InstructionTemplate^.CountOperands-1 do begin
  if ((Instruction.Operand[i+1].Flags and not InstructionTemplate^.Operands[i]) and (OF_COLON or OF_TO))<>0 then begin
   result:=MATCH_ERROR_INVALID_OPCODE;
   exit;
  end;
 end;

 if IF_SB in InstructionTemplate^.Flags then begin
  ASize:=OF_BITS8;
 end else if IF_SW in InstructionTemplate^.Flags then begin
  ASize:=OF_BITS16;
 end else if IF_SD in InstructionTemplate^.Flags then begin
  ASize:=OF_BITS32;
 end else if IF_SQ in InstructionTemplate^.Flags then begin
  ASize:=OF_BITS64;
 end else if IF_SO in InstructionTemplate^.Flags then begin
  ASize:=OF_BITS128;
 end else if IF_SY in InstructionTemplate^.Flags then begin
  ASize:=OF_BITS256;
 end else if IF_SZ in InstructionTemplate^.Flags then begin
  ASize:=OF_BITS512;
 end else if IF_SIZE in InstructionTemplate^.Flags then begin
  case Bits of
   16:begin
    ASize:=OF_BITS16;
   end;
   32:begin
    ASize:=OF_BITS32;
   end;
   64:begin
    ASize:=OF_BITS64;
   end;
   else begin
    ASize:=0;
   end;
  end;
 end else begin
  ASize:=0;
 end;

 if ([IF_AR0..IF_AR4]*InstructionTemplate^.Flags)<>[] then begin
  i:=0;
  if IF_AR0 in InstructionTemplate^.Flags then begin
   i:=i or 1;
  end;
  if IF_AR1 in InstructionTemplate^.Flags then begin
   i:=i or 2;
  end;
  if IF_AR2 in InstructionTemplate^.Flags then begin
   i:=i or 4;
  end;
  if IF_AR3 in InstructionTemplate^.Flags then begin
   i:=i or 8;
  end;
  if IF_AR4 in InstructionTemplate^.Flags then begin
   i:=i or 16;
  end;
  dec(i);
  FillChar(Size,SizeOf(Size),AnsiChar(#$00));
  Size[i]:=ASize;
 end else begin
  for i:=0 to MaxOperands-1 do begin
   Size[i]:=ASize;
  end;
 end;

 for i:=0 to InstructionTemplate^.CountOperands-1 do begin
  Flags:=Instruction.Operand[i+1].Flags;
  DecoratorFlags:=Instruction.Operand[i+1].DecoratorFlags;
  IsBroadCast:=(DecoratorFlags and BRDCAST_MASK)<>0;
  brcast_num:=0;
  if (Flags and SIZE_MASK)=0 then begin
   Flags:=Flags or Size[i];
  end;
  insn_opsize:=Flags and SIZE_MASK;
  if IsBroadCast then begin
   deco_brsize:=DecoratorFlags and BRSIZE_MASK;
   if deco_brsize<>0 then begin
    if deco_brsize=BR_BITS32 then begin
     template_opsize:=OF_BITS32;
    end else begin
     template_opsize:=OF_BITS64;
    end;
    brcast_num:=GetBroadcastNum(InstructionTemplate^.Operands[i],template_opsize);
   end else begin
    template_opsize:=0;
   end;
  end else begin
   template_opsize:=InstructionTemplate^.Operands[i] and SIZE_MASK;
  end;
  if (((InstructionTemplate^.Operands[i] and not Flags) and not SIZE_MASK)<>0) or
     (((DecoratorFlags and not InstructionTemplate^.Decorators[i]) and not not BRNUM_MASK)<>0) then begin
   if (((InstructionTemplate^.Operands[i] and not Flags) and not SIZE_MASK)<>0) or
      (((DecoratorFlags and not InstructionTemplate^.Decorators[i]) and not not BRNUM_MASK)<>0) then begin
    result:=MATCH_ERROR_INVALID_OPCODE;                   
    exit;
   end;
   result:=MATCH_ERROR_INVALID_OPCODE;
   exit;
  end else if template_opsize<>0 then begin
   if template_opsize<>insn_opsize then begin
    if insn_opsize<>0 then begin
     result:=MATCH_ERROR_INVALID_OPCODE;
     exit;
    end else if ((not Flags) and OF_REGISTER)<>0 then begin
     OpSizeMissing:=true;
    end else if IsBroadcast and (brcast_num<>(uint64(2) shl ((DecoratorFlags and BRNUM_MASK) shr BRNUM_SHIFT))) then begin
     result:=MATCH_ERROR_BROADCAST_SIZE_MISMATCH;
     exit;
    end;
   end;
  end;
 end;

 if OpSizeMissing then begin
  result:=MATCH_ERROR_OPCODE_SIZE_MISSING;
  exit;
 end;

 if ([IF_SM,IF_SM2]*InstructionTemplate^.Flags)<>[] then begin
  if IF_SM2 in InstructionTemplate^.Flags then begin
   Operands:=2;
  end else begin
   Operands:=InstructionTemplate^.CountOperands;
  end;
  for i:=0 to Operands-1 do begin
   ASize:=InstructionTemplate^.Operands[i] and SIZE_MASK;
   if ASize<>0 then begin
    for k:=0 to Operands-1 do begin
     Size[k]:=ASize;
    end;
    break;
   end;
  end;
 end else begin
  Operands:=InstructionTemplate^.CountOperands;
  if Operands>0 then begin
  end;
 end;

 for i:=0 to InstructionTemplate^.CountOperands-1 do begin
  if ((InstructionTemplate^.Operands[i] and SIZE_MASK)=0) and
     (((Instruction.Operand[i+1].Flags and SIZE_MASK) and not Size[i])<>0) then begin
   result:=MATCH_ERROR_OPCODE_SIZE_MISMATCH;
   exit;
  end;
 end;

 j:=IF_8086;
 for i:=IF_IA64 downto IF_8086 do begin
  if i in InstructionTemplate^.Flags then begin
   j:=i;
   break;
  end;
 end;
 if j>CPULevel then begin
  result:=MATCH_ERROR_BAD_CPU;
  exit;
 end;

 if ((Bits=64) and (IF_NOLONG in InstructionTemplate^.Flags)) or
    ((Bits<>64) and (IF_LONG in InstructionTemplate^.Flags)) then begin
  result:=MATCH_ERROR_BAD_MODE;
  exit;
 end;

 if (IF_HLE in InstructionTemplate^.Flags) and (Instruction.Prefixes[PPS_REP] in [P_XACQUIRE,P_XRELEASE]) then begin
  result:=MATCH_ERROR_BAD_HLE;
  exit;
 end;

 if (not (IF_BND in InstructionTemplate^.Flags)) and (Instruction.Prefixes[PPS_REP] in [P_BND,P_NOBND]) then begin
  result:=MATCH_ERROR_BAD_BND;
  exit;
 end else if (IF_BND in InstructionTemplate^.Flags) and (Instruction.Prefixes[PPS_REP] in [P_REPNE,P_REPNZ]) then begin
  result:=MATCH_ERROR_BAD_REPNE;
  exit;
 end;

 if (InstructionTemplate^.SequenceLength>0) and
    ((InstructionTemplate^.Sequence[0] and $fe)=$f8) then begin
  result:=MATCH_OKAY_JUMP;
 end else begin
  result:=MATCH_OKAY_GOOD;
 end;

end;

function TAssembler.REXFlags(const Value:longint;const Flags:TOperandFlags;const Mask:longint):longint;
begin
 result:=0;
 if (Value>=0) and ((Value and 8)<>0) then begin
  result:=result or REX_B or REX_X or REX_R;
 end;
 if (Flags and OF_BITS64)<>0 then begin
  result:=result or REX_W;
 end;
 if ((not Flags) and OF_REG_HIGH)=0 then begin
  // AH, CH, DH, BH
  result:=result or REX_H;
 end else if (Value>=4) and (((not Flags) and OF_REG8)=0) then begin
  // SPL, BPL, SIL, DIL
  result:=result or REX_P;
 end;
 result:=result and Mask;
end;

function TAssembler.OpREXFlags(const Operand:TOperand;const Mask:longint):longint;
begin
 if Operand.BaseRegister=RegNONE then begin
  MakeError(63);
  result:=0;
 end else begin
  result:=REXFlags(RegisterTemplates[Operand.BaseRegister].RegisterNumber,RegisterTemplates[Operand.BaseRegister].RegisterClass,Mask);
 end;
end;

function TAssembler.EVEXFlags(const Value:longint;const DecoratorFlags:TDecoratorFlags;const Mask:longint;const b:byte):longint;
begin
 result:=0;
 case b of
  0:begin
   if (Value>=0) and ((Value and 16)<>0) then begin
    result:=result or (EVEX_P0RP or EVEX_P0X);
   end;
  end;
  2:begin
   if (Value>=0) and ((Value and 16)<>0) then begin
    result:=result or EVEX_P2VP;
   end;
   if (DecoratorFlags and ODF_Z)<>0 then begin
    result:=result or EVEX_P2Z;
   end;
   if (DecoratorFlags and ODF_MASK)<>0 then begin
    result:=result or (DecoratorFlags and EVEX_P2AAA);
   end;
  end;
 end;
 result:=result and Mask;
end;

function TAssembler.OpEVEXFlags(const Operand:TOperand;const Mask:longint;const b:byte):longint;
begin
 if Operand.BaseRegister=RegNONE then begin
  MakeError(63);
  result:=0;
 end else begin
  result:=EVEXFlags(RegisterTemplates[Operand.BaseRegister].RegisterNumber,Operand.DecoratorFlags,Mask,b);
 end;
end;

function TAssembler.RegVal(const Operand:TOperand):longint;
begin
 if Operand.BaseRegister=RegNONE then begin
  MakeError(0);
  result:=0;
 end else begin
  result:=RegisterTemplates[Operand.BaseRegister].RegisterNumber;
 end;
end;

function TAssembler.RegFlags(const Operand:TOperand):TOperandFlags;
begin
 if Operand.BaseRegister=RegNONE then begin
  MakeError(0);
  result:=0;
 end else begin
  result:=RegisterTemplates[Operand.BaseRegister].RegisterClass;
 end;
end;

function TAssembler.ProcessEA(var InputOperand:TOperand;var EAOutput:TEA;const Bits,RField:longint;const RFlags:TOperandFlags;var Instruction:TInstruction):longint;
 function GetDisp8n:byte;
 const fv_n:array[boolean,boolean,0..VLMAX-1] of byte=(((16,32,64),(4,4,4)),((16,32,64),(8,8,8)));
       hv_n:array[boolean,0..VLMAX-1] of byte=((8,16,32),(4,4,4));
       dup_n:array[0..VLMAX-1] of byte=(8,32,64);
 var evex_b,evex_w:boolean;
     tuple,vectlen:longint;
 begin
  evex_b:=((Instruction.evex_p[2] and EVEX_P2B) shr 4)<>0;
  tuple:=Instruction.evex_tuple;
  vectlen:=(Instruction.evex_p[2] and EVEX_P2LL) shr 5;
  evex_w:=((Instruction.evex_p[1] and EVEX_P1W) shr 7)<>0;
  case tuple of
   T_FV:begin
    result:=fv_n[evex_w,evex_b,vectlen];
   end;
   T_HV:begin
    result:=hv_n[evex_b,vectlen];
   end;
   T_FVM:begin
    result:=1 shl (vectlen+4);
   end;
   T_T1S8,T_T1S16:begin
    result:=(tuple-T_T1S8)+1;
   end;
   T_T1S:begin
    if evex_w then begin
     result:=8;
    end else begin
     result:=4;
    end;
   end;
   T_T1F32,T_T1F64:begin
    if tuple=T_T1F32 then begin
     result:=4;
    end else begin
     result:=8;
    end;
   end;
   T_T2,T_T4,T_T8:begin
    if (vectlen+7)<=(((ord(evex_w) and 1)+5)+((tuple-T_T2)+1)) then begin
     result:=0;
    end else begin
     result:=1 shl (((tuple-T_T2)+(ord(evex_w) and 1))+3);
    end;
   end;
   T_HVM,T_QVM,T_OVM:begin
    result:=1 shl (((T_OVM-tuple)+vectlen)+1);
   end;
   T_M128:begin
    result:=16;
   end;
   T_DUP:begin
    result:=dup_n[vectlen];
   end;
   else begin
    result:=0;
   end;
  end;
 end;        
 function IsDisp8N(var CompDisp:shortint):boolean;
 var o:int64;
     n,Disp8:longint;
 begin
  if assigned(InputOperand.Value) then begin
   o:=ValueGetInt64(self,InputOperand.Value.Evaluate(self),false);
  end else begin
   o:=0;
  end;
  n:=GetDisp8n;
  if (n<>0) and ((o and (n-1))=0) then begin
   Disp8:=o div n;
   if (Disp8>=(-128)) and (Disp8<=127) then begin
    CompDisp:=Disp8;
    result:=true;
    exit;
   end;
  end;
  CompDisp:=0;
  result:=false;
 end;
 function GenMODRM(Mod_,Reg,RM:byte):byte;
 begin
  result:=(Mod_ shl 6) or ((Reg and 7) shl 3) or (RM and 7);
 end;
 function GenSIB(Scale,Index,Base:byte):byte;
 begin
  result:=(Scale shl 6) or (Index shl 3) or Base;
 end;
const REG_NUM_EBP=5;
      REG_NUM_ESP=4;
var AddressBits,EAFlags,i,b,it,bt,t,Mod_,RM,Scale,Index,Base,hb,ht:longint;
    s:int64;
    {f,}ix,bx,x,sok:TOperandFlags;
 function SelectMOD(const BaseRM,CompareWithRegNum:longint):longint;
 var OperandValue:TIntegerValue;
     OperandHasFixUpSymbolReference,OperandIsZero,OperandInSignedByteValueRange:boolean;
 begin
  if assigned(InputOperand.Value) then begin
   OperandValue:=ValueToRawInt(self,InputOperand.Value.Evaluate(self,true),false);
   OperandHasFixUpSymbolReference:=InputOperand.Value.HasFixUpSymbolReference(self);
   OperandIsZero:=IntegerValueIsZero(OperandValue);
   OperandInSignedByteValueRange:=(IntCompare(OperandValue,-128)>=0) and (IntCompare(OperandValue,127)<=0);
  end else begin
   IntegerValueSetQWord(OperandValue,0);
   OperandHasFixUpSymbolReference:=false;
   OperandIsZero:=true;
   OperandInSignedByteValueRange:=false;
  end;
  if (BaseRM<>CompareWithRegNum) and ((EAFlags and (EAF_BYTEOFFS or EAF_WORDOFFS))=0) and
     OperandIsZero and not OperandHasFixUpSymbolReference then begin
   result:=0;
  end else if ((Instruction.REX and REX_EV)<>0) and IsDisp8N(EAOutput.Displacement) then begin
   result:=1;
  end else if (EAFlags and EAF_BYTEOFFS)<>0 then begin
   result:=1;
  end else if ((EAFlags and EAF_WORDOFFS)=0) and
              OperandInSignedByteValueRange and not OperandHasFixUpSymbolReference then begin
   result:=1;
  end else begin
   result:=2;
  end;
 end;
begin
 AddressBits:=Instruction.AddressSize;
 EAFlags:=InputOperand.EAFlags;
 EAOutput.EAType:=EA_SCALAR;
 EAOutput.Relative:=false;
 EAOutput.Displacement:=0;
 EAOutput.REX:=EAOutput.REX or REXFlags(RField,RFlags,REX_R or REX_P or REX_W or REX_H);
 Instruction.evex_p[0]:=Instruction.evex_p[0] or EVEXFlags(RField,0,EVEX_P0RP,0);
 if ((not InputOperand.Flags) and OF_REGISTER)=0 then begin
  // Direct register
  if InputOperand.BaseRegister=RegNONE then begin
   EAOutput.EAType:=EA_INVALID;
   result:=EAOutput.EAType;
   exit;
  end;
  if ((not RegFlags(InputOperand)) and OF_REG_EA)<>0 then begin
   EAOutput.EAType:=EA_INVALID;
   result:=EAOutput.EAType;
   exit;
  end;
  if (InputOperand.DecoratorFlags and BRDCAST_MASK)<>0 then begin
   MakeError('Broadcasting not allowed from a register');
   EAOutput.EAType:=EA_INVALID;
   result:=EAOutput.EAType;
   exit;
  end;
  EAOutput.REX:=EAOutput.REX or OpREXFlags(InputOperand,REX_B or REX_P or REX_W or REX_H);
  Instruction.evex_p[0]:=Instruction.evex_p[0] or OpEVEXFlags(InputOperand,EVEX_P0X,0);
  EAOutput.SIBPresent:=false;
  EAOutput.Bytes:=0;
  EAOutput.MODRM:=GenMODRM(3,RField,RegisterTemplates[InputOperand.BaseRegister].RegisterNumber);
 end else begin
  // Memory reference
  if (InputOperand.DecoratorFlags and (ODF_ER or ODF_SAE))<>0 then begin
   MakeError('Embedded rounding is available only with reg-reg op');
   EAOutput.EAType:=EA_INVALID;
   result:=EAOutput.EAType;
   exit;
  end;
  if (InputOperand.BaseRegister=RegNONE) and (InputOperand.IndexRegister=RegNONE) then begin
   // Pure offset
{  if (Bits=64) and ((InputOperand.Flags and OF_IP_REL)=OF_IP_REL) and
      not (assigned(InputOperand.Value) and (InputOperand.Value.HasFixUpSymbolReference(self) or InputOperand.Value.HasOperation(['h']))) then begin
    if not InputOperand.RIPRegister then begin
     if CurrentPass=1 then begin
      MakeWarning('Absolute address can''t be RIP-relative, dropped RIP-relative flag');
     end;
     InputOperand.Flags:=(InputOperand.Flags and not OF_IP_REL) or OF_MEMORY;
    end;
   end;{}
   if (Bits=64) and ((InputOperand.Flags and OF_IP_REL)=0) and ((EAFlags and EAF_MIB)<>0) then begin
    MakeError('RIP-relative addressing is prohibited for MIB');
    EAOutput.EAType:=EA_INVALID;
    result:=EAOutput.EAType;
    exit;
   end;
   if ((EAFlags and EAF_BYTEOFFS)<>0) or
      (((EAFlags and EAF_WORDOFFS)<>0) and
       (((AddressBits<>16) and (InputOperand.DisplacmentSize<>32)) or
        ((AddressBits=16) and (InputOperand.DisplacmentSize<>16)))) then begin
    if CurrentPass=1 then begin
     MakeWarning('Displacement size ignored on absolute address');
    end;
   end;
   if (Bits=64) and (((not InputOperand.Flags) and OF_IP_REL)<>0) then begin
    EAOutput.SIBPresent:=true;
    EAOutput.SIB:=GenSIB(0,4,5);
    EAOutput.Bytes:=4;
    EAOutput.MODRM:=GenMODRM(0,RField,4);
    EAOutput.Relative:=false;
   end else begin
    EAOutput.SIBPresent:=false;
    if AddressBits<>16 then begin
     EAOutput.Bytes:=4;
     EAOutput.MODRM:=GenMODRM(0,RField,5);
    end else begin
     EAOutput.Bytes:=2;
     EAOutput.MODRM:=GenMODRM(0,RField,6);
    end;
    if Bits=64 then begin
     if InputOperand.RIPRegister then begin
      // [rip+...]
      EAOutput.Relative:=false;
     end else begin
      // [rel ...]
      EAOutput.Relative:=true;
     end;
    end else begin
     // [abs ...]
     EAOutput.Relative:=false;
    end;
   end;
  end else begin
   // Indirection

   hb:=InputOperand.HintBase;
   ht:=InputOperand.HintType;

   i:=InputOperand.IndexRegister;

   b:=InputOperand.BaseRegister;

   if assigned(InputOperand.Scale) then begin
    s:=ValueGetInt64(self,InputOperand.Scale.Evaluate(self),false);
   end else begin
    s:=0;
   end;

   if s=0 then begin
    i:=RegNONE;
   end;

   if i<>RegNONE then begin
    it:=RegisterTemplates[i].RegisterNumber;
    ix:=RegisterTemplates[i].RegisterClass;
   end else begin
    it:=-1;
    ix:=0;
   end;
                                                  
   if b<>RegNONE then begin
    bt:=RegisterTemplates[b].RegisterNumber;
    bx:=RegisterTemplates[b].RegisterClass;
   end else begin
    bt:=-1;
    bx:=0;
   end;

   if (((ix or bx) and (OF_XMMREG or OF_YMMREG or OF_ZMMREG)) and not OF_REG_EA)<>0 then begin

    // Vector SIB

    sok:=OF_BITS32 or OF_BITS64;

    if (it<0) or (((bx and (OF_XMMREG or OF_YMMREG)) and not OF_REG_EA)<>0) then begin
     if s=0 then begin
      s:=1;
     end else if s<>1 then begin
      EAOutput.EAType:=EA_INVALID;
      result:=EAOutput.EAType;
      exit;
     end;
     t:=bt;
     bt:=it;
     it:=t;
     x:=bx;
     bx:=ix;
     ix:=x;
    end;

    if bt>=0 then begin
     if ((not bx) and OF_REG_GPR)<>0 then begin
      EAOutput.EAType:=EA_INVALID;
      result:=EAOutput.EAType;
      exit;
     end;
     if (((not bx) and OF_REG64)=0) or (((not bx) and OF_REG32)=0) then begin
      sok:=sok and bx;
     end else begin
      EAOutput.EAType:=EA_INVALID;
      result:=EAOutput.EAType;
      exit;
     end;
    end;

    if InputOperand.DisplacmentSize in [16,64] then begin
     EAOutput.EAType:=EA_INVALID;
     result:=EAOutput.EAType;
     exit;
    end;

    if (AddressBits=16) or
       ((AddressBits=32) and ((sok and OF_BITS32)=0)) or
       ((AddressBits=64) and ((sok and OF_BITS64)=0)) then begin
     EAOutput.EAType:=EA_INVALID;
     result:=EAOutput.EAType;
     exit;
    end;

    if ((ix and OF_ZMMREG) and not OF_REG_EA)<>0 then begin
     EAOutput.EAType:=EA_ZMMVSIB;
    end else if ((ix and OF_YMMREG) and not OF_REG_EA)<>0 then begin
     EAOutput.EAType:=EA_YMMVSIB;
    end else begin
     EAOutput.EAType:=EA_XMMVSIB;
    end;

    EAOutput.REX:=EAOutput.REX or (REXFlags(it,ix,REX_X) or REXFlags(bt,bx,REX_B));
    Instruction.evex_p[2]:=Instruction.evex_p[2] or EVEXFlags(it,0,EVEX_P2VP,2);

    Index:=it and 7;

    case s of
     1:begin
      Scale:=0;
     end;
     2:begin
      Scale:=1;
     end;
     4:begin
      Scale:=2;
     end;
     8:begin
      Scale:=3;
     end;
     else begin
      EAOutput.EAType:=EA_INVALID;
      result:=EAOutput.EAType;
      exit;
     end;
    end;

    if bt<0 then begin
     Base:=5;
     Mod_:=0;
    end else begin
     Base:=bt and 7;
     Mod_:=SelectMOD(Base,REG_NUM_EBP);
    end;

    EAOutput.SIBPresent:=true;
    if (bt<0) or (Mod_=2) then begin
     EAOutput.Bytes:=4;
    end else begin
     EAOutput.Bytes:=Mod_;
    end;
    EAOutput.MODRM:=GenMODRM(Mod_,RField,4);
    EAOutput.SIB:=GenSIB(Scale,Index,Base);

   end else if ((ix or bx) and (OF_BITS32 or OF_BITS64))<>0 then begin

    // 32/64-bit memory reference

    sok:=OF_BITS32 or OF_BITS64;

    if it>=0 then begin
     if (((not ix) and OF_REG64)=0) or (((not ix) and OF_REG32)=0) then begin
      sok:=sok and ix;
     end else begin
      EAOutput.EAType:=EA_INVALID;
      result:=EAOutput.EAType;
      exit;
     end;
    end;

    if bt>=0 then begin
     if ((not bx) and OF_REG_GPR)<>0 then begin
      EAOutput.EAType:=EA_INVALID;
      result:=EAOutput.EAType;
      exit;
     end;
     if (((not sok) and bx) and SIZE_MASK)<>0 then begin
      EAOutput.EAType:=EA_INVALID;
      result:=EAOutput.EAType;
      exit;
     end;
     sok:=sok and bx;
    end;

    if InputOperand.DisplacmentSize in [16,64] then begin
     EAOutput.EAType:=EA_INVALID;
     result:=EAOutput.EAType;
     exit;
    end;

    if (AddressBits=16) or
       ((AddressBits=32) and ((sok and OF_BITS32)=0)) or
       ((AddressBits=64) and ((sok and OF_BITS64)=0)) then begin
     EAOutput.EAType:=EA_INVALID;
     result:=EAOutput.EAType;
     exit;
    end;

    if (s=1) and ((bt<>it) and (bt>=0) and (it>=0) and (((hb=b) and (ht=EAH_NOTBASE)) or ((hb=i) and (ht=EAH_MAKEBASE)))) then begin
     t:=bt;
     bt:=it;
     it:=t;
     x:=bx;
     bx:=ix;
     ix:=x;
    end;

{   if bt=it then begin
     bt:=-1;
     bx:=0;
     inc(s);
    end;{}

    if (EAFlags and EAF_MIB)<>0 then begin
     if (it<0) and (hb=b) and (ht=EAH_NOTBASE) then begin
      it:=bt;
      ix:=bx;
      bt:=-1;
      bx:=0;
      s:=1;
     end;
     if (ht=EAH_SUMMED) and (bt<0) then begin
      bt:=it;
      bx:=ix;
      dec(s);
     end;
    end else begin
     if (((s=2) and (it<>REG_NUM_ESP) and (((EAFlags and EAF_TIMESTWO)=0) or (ht=EAH_SUMMED))) or ((s=3) or (s=5) or (s=9))) and (bt<0) then begin
      bt:=it;
      bx:=ix;
      dec(s);
     end;
     if (it<0) and ((bt and 7)<>REG_NUM_ESP) and ((EAFlags and EAF_TIMESTWO)<>0) and ((hb=b) and (ht=EAH_NOTBASE)) then begin
      it:=bt;
      ix:=bx;
      bt:=-1;
      bx:=0;
      s:=1;
     end;
    end;

    if (s=1) and (it=REG_NUM_ESP) then begin
     t:=bt;
     bt:=it;
     it:=t;
     x:=bx;
     bx:=ix;
     ix:=x;
    end;

    if (it=REG_NUM_ESP) or ((s<>1) and (s<>2) and (s<>4) and (s<>8) and (it>=0)) then begin
     EAOutput.EAType:=EA_INVALID;
     result:=EAOutput.EAType;
     exit;
    end;

    EAOutput.REX:=EAOutput.REX or (REXFlags(it,ix,REX_X) or REXFlags(bt,bx,REX_B));

    if (it<0) and ((bt and 7)<>REG_NUM_ESP) then begin
     // No SIB needed
     if bt<0 then begin
      RM:=5;
      Mod_:=0;
     end else begin
      RM:=bt and 7;
      Mod_:=SelectMOD(RM,REG_NUM_EBP);
     end;
     EAOutput.SIBPresent:=false;
     if (bt<0) or (Mod_=2) then begin
      EAOutput.Bytes:=4;
     end else begin
      EAOutput.Bytes:=Mod_;
     end;
     EAOutput.MODRM:=GenMODRM(Mod_,RField,RM);

    end else begin

     // SIB needed

     if it<0 then begin
      Index:=4;
      s:=1;
     end else begin
      Index:=it and 7;
     end;

     case s of
      1:begin
       Scale:=0;
      end;
      2:begin
       Scale:=1;
      end;
      4:begin
       Scale:=2;
      end;
      8:begin
       Scale:=3;
      end;
      else begin
       EAOutput.EAType:=EA_INVALID;
       result:=EAOutput.EAType;
       exit;
      end;
     end;

     if bt<0 then begin
      Base:=5;
      Mod_:=0;
     end else begin
      Base:=bt and 7;
      Mod_:=SelectMOD(Base,REG_NUM_EBP);
     end;
     EAOutput.SIBPresent:=true;
     if (bt<0) or (Mod_=2) then begin
      EAOutput.Bytes:=4;
     end else begin
      EAOutput.Bytes:=Mod_;
     end;
     EAOutput.MODRM:=GenMODRM(Mod_,RField,4);
     EAOutput.SIB:=GenSIB(Scale,Index,Base);
    end;

   end else begin

    // 16-bit

    if AddressBits=64 then begin
     EAOutput.EAType:=EA_INVALID;
     result:=EAOutput.EAType;
     exit;
    end;

    if ((b<>RegNONE) and (b<>RegBP) and (b<>RegBX) and (b<>RegSI) and (b<>RegDI)) or
       ((i<>RegNONE) and (i<>RegBP) and (i<>RegBX) and (i<>RegSI) and (i<>RegDI)) then begin
     EAOutput.EAType:=EA_INVALID;
     result:=EAOutput.EAType;
     exit;
    end;

    if InputOperand.DisplacmentSize in [32,64] then begin
     EAOutput.EAType:=EA_INVALID;
     result:=EAOutput.EAType;
     exit;
    end;

    if (s<>1) and (i<>RegNONE) then begin
     EAOutput.EAType:=EA_INVALID;
     result:=EAOutput.EAType;
     exit;
    end;

    if (b=RegNONE) and (i<>RegNONE) then begin
     t:=i;
     i:=b;
     b:=t;
    end;

    if ((b=RegSI) or (b=RegDI)) and (i<>RegNONE) then begin
     t:=i;
     i:=b;
     b:=t;
    end;

    if b=i then begin
     EAOutput.EAType:=EA_INVALID;
     result:=EAOutput.EAType;
     exit;
    end;

    if (i<>RegNONE) and (b<>RegNONE) and (((i=RegBP) or (i=RegBX)) or ((b=RegSI) or (b=RegDI))) then begin
     EAOutput.EAType:=EA_INVALID;
     result:=EAOutput.EAType;
     exit;
    end;

    if b=RegNONE then begin
     EAOutput.EAType:=EA_INVALID;
     result:=EAOutput.EAType;
     exit;
    end;

    RM:=-1;
    if i<>RegNONE then begin
     case b of
      RegBX:begin
       case i of
        RegSI:begin
         RM:=0;
        end;
        RegDI:begin
         RM:=1;
        end;
       end;
      end;
      RegBP:begin
       case i of
        RegSI:begin
         RM:=2;
        end;
        RegDI:begin
         RM:=3;
        end;
       end;
      end;
     end;
    end else begin
     case b of
      RegSI:begin
       RM:=4;
      end;
      RegDI:begin
       RM:=5;
      end;
      RegBP:begin
       RM:=6;
      end;
      RegBX:begin
       RM:=7;
      end;
     end;
    end;
    if RM<0 then begin
     EAOutput.EAType:=EA_INVALID;
     result:=EAOutput.EAType;
     exit;
    end;

    Mod_:=SelectMOD(RM,6);

    EAOutput.SIBPresent:=false;
    EAOutput.Bytes:=Mod_;
    EAOutput.MODRM:=GenMODRM(Mod_,RField,RM);

   end;
  end;
 end;
 if EAOutput.SIBPresent then begin
  EAOutput.Size:=2+EAOutput.Bytes;
 end else begin
  EAOutput.Size:=1+EAOutput.Bytes;
 end;
 result:=EAOutput.EAType;
end;

function TAssembler.CalculateInstructionSize(const Segment:PAssemblerSegment;const Section:PAssemblerSection;const Offset:int64;const Bits:longint;var Instruction:TInstruction;const InstructionTemplate:TInstructionTemplate):longint;
const w_none=0;
      w_lock=1;
      w_inval=2;
      warn:array[0..1,0..3] of longint=((w_inval,w_inval,w_none,w_lock),(w_inval,w_none,w_none,w_lock));
var c,opex,hleok:byte;
    REXMask,op1,op2,eat,SequencePosition,RField,Bad32,rep_pfx,ww,n,MIBIndex:longint;
    RFlags:TOperandFlags;
    lockcheck:boolean;
    Operand,OtherOperand,OperandERSAE:POperand;
    EAData:TEA;
begin
 result:=0;
 REXMask:=not 0;
 opex:=0;
 hleok:=0;
 lockcheck:=true;

 Instruction.REX:=0;
 eat:=EA_SCALAR;
 Instruction.evex_p[0]:=0;
 Instruction.evex_p[1]:=0;
 Instruction.evex_p[2]:=0;
 Instruction.evex_p[3]:=0;
 MIBIndex:=RegNONE;

{if Instruction.Operand[2].Value.Value=$4c then begin
  if Instruction.Operand[2].Value.Value=$4c then begin
  end;
 end;{}

 if Instruction.Prefixes[PPS_OSIZE]=P_O64 then begin
  Instruction.REX:=Instruction.REX or REX_W;
 end;

 SequencePosition:=0;
 while SequencePosition<InstructionTemplate.SequenceLength do begin
  c:=InstructionTemplate.Sequence[SequencePosition];
  inc(SequencePosition);
  op1:=(c and 3)+((opex and 1) shl 2);
  op2:=((c shr 3) and 3)+((opex and 2) shl 1);
  Operand:=@Instruction.Operand[op1+1];
  opex:=0;
  case c of
   $01{01}..$04{04}:begin
    inc(result,c);
    inc(SequencePosition,c);
   end;
   $05{05}..$07{07}:begin
    opex:=c;
   end;
   $08{010}..$0b{013}:begin
    Instruction.REX:=OpREXFlags(Operand^,REX_B or REX_H or REX_P or REX_W);
    inc(result);
    inc(SequencePosition);
   end;
   $0c{014}..$0f{017}:begin
    MIBIndex:=Operand.BaseRegister;
   end;
   $10{020}..$13{023},
   $14{024}..$17{027}:begin
    inc(result);
   end;
   $18{030}..$1b{033}:begin
    inc(result,2);
   end;
   $1c{034}..$1f{037}:begin
    if (Operand.Flags and (OF_BITS16 or OF_BITS32 or OF_BITS64))<>0 then begin
     if (Operand.Flags and OF_BITS16)<>0 then begin
      inc(result,2);
     end else begin
      inc(result,4);
     end;
    end else begin
     if Bits=16 then begin
      inc(result,2);
     end else begin
      inc(result,4);
     end;
    end;
   end;
   $20{040}..$23{043}:begin
    inc(result,4);
   end;
   $24{044}..$27{047}:begin
    inc(result,Instruction.AddressSize shr 3);
   end;
   $28{050}..$2b{053}:begin
    inc(result);
   end;
   $2c{054}..$2f{057}:begin
    // MOV reg64/imm
    inc(result,8);
   end;
   $30{060}..$33{063}:begin
    inc(result,2);
   end;
   $34{064}..$37{067}:begin
    if (Operand.Flags and (OF_BITS16 or OF_BITS32 or OF_BITS64))<>0 then begin
     if (Operand.Flags and OF_BITS16)<>0 then begin
      inc(result,2);
     end else begin
      inc(result,4);
     end;
    end else begin
     if Bits=16 then begin
      inc(result,2);
     end else begin
      inc(result,4);
     end;
    end;
   end;
   $38{070}..$3b{073}:begin
    inc(result,4);
   end;
   $3c{074}..$3f{077}:begin
    inc(result,2);
   end;
   $7a{0172}..$7b{0173}:begin
    inc(result);
    inc(SequencePosition);
   end;
   $7c{0174}..$7f{0177}:begin
    inc(result);
   end;
   $a0{0240}..$a3{0243}:begin
    Instruction.REX:=Instruction.REX or REX_EV;
    Instruction.VEXRegister:=RegVal(Operand^);
    Instruction.evex_p[2]:=Instruction.evex_p[2] or OpEVEXFlags(Operand^,EVEX_P2VP,2);
    Instruction.VEX_CM:=InstructionTemplate.Sequence[SequencePosition];
    Instruction.VEX_WLP:=InstructionTemplate.Sequence[SequencePosition+1];
    Instruction.evex_tuple:=InstructionTemplate.Sequence[SequencePosition+2]-$c0{0300};
    inc(SequencePosition,3);
   end;
   $a8{0250}..$ab{0253}:begin
    Instruction.REX:=Instruction.REX or REX_EV;
    Instruction.VEXRegister:=0;
    Instruction.VEX_CM:=InstructionTemplate.Sequence[SequencePosition];
    Instruction.VEX_WLP:=InstructionTemplate.Sequence[SequencePosition+1];
    Instruction.evex_tuple:=InstructionTemplate.Sequence[SequencePosition+2]-$c0{0300};
    inc(SequencePosition,3);
   end;
   $ac{0254}..$af{0257}:begin
    inc(result,4);
   end;
   $b0{0260}..$b3{0263}:begin
    Instruction.REX:=Instruction.REX or REX_V;
    Instruction.VEXRegister:=RegVal(Operand^);
    Instruction.VEX_CM:=InstructionTemplate.Sequence[SequencePosition];
    Instruction.VEX_WLP:=InstructionTemplate.Sequence[SequencePosition+1];
    inc(SequencePosition,2);
   end;
   $b8{0270}:begin
    Instruction.REX:=Instruction.REX or REX_V;
    Instruction.VEXRegister:=0;
    Instruction.VEX_CM:=InstructionTemplate.Sequence[SequencePosition];
    Instruction.VEX_WLP:=InstructionTemplate.Sequence[SequencePosition+1];
    inc(SequencePosition,2);
   end;
   $b9{0271}..$bb{0273}:begin
    hleok:=c and 3;
   end;
   $bc{0274}..$bf{0277}:begin
    inc(result);
   end;
   $c0{0300}..$c3{0303}:begin
   end;
   $c8{0310}:begin
    if Bits=64 then begin
     result:=-1;
     exit;
    end;
    if (Bits<>16) and (Instruction.Prefixes[PPS_ASIZE]<>P_A16) then begin
     inc(result);
    end;
   end;
   $c9{0311}:begin
    if (Bits<>32) and (Instruction.Prefixes[PPS_ASIZE]<>P_A32) then begin
     inc(result);
    end;
   end;
   $ca{0312}:begin
   end;
   $cb{0313}:begin
    if (Bits<>64) or (Instruction.Prefixes[PPS_ASIZE] in [P_A16,P_A32]) then begin
     result:=-1;
     exit;
    end;
   end;
   $cc{0314}..$cf{0317}:begin
   end;
   $d0{0320}:begin
    case Instruction.Prefixes[PPS_OSIZE] of
     P_NONE:begin
      Instruction.Prefixes[PPS_OSIZE]:=P_O16;
     end;
     P_O16:begin
     end;
     else begin
      if CurrentPass>1 then begin
       MakeError('Invalid operand size prefix');
      end;
     end;
    end;
   end;
   $d1{0321}:begin
    case Instruction.Prefixes[PPS_OSIZE] of
     P_NONE:begin
      Instruction.Prefixes[PPS_OSIZE]:=P_O32;
     end;
     P_O32:begin
     end;
     else begin
      if CurrentPass>1 then begin
       MakeError('Invalid operand size prefix');
      end;
     end;
    end;
   end;
   $d2{0322}:begin
   end;
   $d3{0323}:begin
    REXMask:=REXMask and not REX_W;
   end;
   $d4{0324}:begin
    Instruction.REX:=Instruction.REX or REX_W;
   end;
   $d5{0325}:begin
    Instruction.REX:=Instruction.REX or REX_NH;
   end;
   $d6{0326}:begin
   end;
   $d8{0330}:begin
    inc(result);
    inc(SequencePosition);
   end;
   $d9{0331}:begin
   end;
   $da{0332}..$db{0333}:begin
    inc(result);
   end;
   $dc{0334}:begin
    Instruction.REX:=Instruction.REX or REX_L;
   end;
   $dd{0335}:begin
   end;
   $de{0336}:begin
    if Instruction.Prefixes[PPS_REP]=P_NONE then begin
     Instruction.Prefixes[PPS_REP]:=P_REP;
    end;
   end;
   $df{0337}:begin
    if Instruction.Prefixes[PPS_REP]=P_NONE then begin
     Instruction.Prefixes[PPS_REP]:=P_REPNE;
    end;
   end;
   $e0{0340}:begin
    if assigned(Operand.Value) and Operand.Value.HasFixUpSymbolReference(self) then begin
     MakeWarning('Attempt to reserve non-constant quantity of BSS space');
    end else begin
     inc(result,ValueGetInt64(self,Operand.Value.Evaluate(self,true),false));
    end;
   end;
   $e1{0341}:begin
    if Instruction.Prefixes[PPS_WAIT]=P_NONE then begin
     Instruction.Prefixes[PPS_WAIT]:=P_WAIT;
    end;
   end;
   $f0{0360}:begin
   end;
   $f1{0361}:begin
    inc(result);
   end;
   $f4{0364}..$f5{0365}:begin
   end;
   $f6{0366}..$f7{0367}:begin
    inc(result);
   end;
   $f8{0370}..$f9{0371}:begin
   end;
   $fb{0373}:begin
    inc(result);
   end;
   $fc{0374}:begin
    eat:=EA_XMMVSIB;
   end;
   $fd{0375}:begin
    eat:=EA_YMMVSIB;
   end;
   $fe{0376}:begin
    eat:=EA_ZMMVSIB;
   end;
   $40{0100}..$43{0103},
   $48{0110}..$4b{0113},
   $50{0120}..$53{0123},
   $58{0130}..$5b{0133},
   $80{0200}..$83{0203},
   $84{0204}..$87{0207},
   $88{0210}..$8b{0213},
   $8c{0214}..$8f{0217},
   $90{0220}..$93{0223},
   $94{0224}..$97{0227},
   $98{0230}..$9b{0233},
   $9c{0234}..$9f{0237}:begin
    FillChar(EAData,SizeOf(TEA),AnsiChar(#0));
    EAData.REX:=0;
    OtherOperand:=@Instruction.Operand[op2+1];
    if c<$80 then begin
     RFlags:=RegFlags(Operand^);
     RField:=RegisterTemplates[Operand^.BaseRegister].RegisterNumber;
    end else begin
     RFlags:=0;
     RField:=c and 7;
    end;
    if Instruction.evex_brerop>=0 then begin
     OperandERSAE:=@Instruction.Operand[Instruction.evex_brerop+1];
    end else begin
     OperandERSAE:=nil;
    end;
    if assigned(OperandERSAE) and ((OperandERSAE^.DecoratorFlags and (ODF_ER or ODF_SAE))<>0) then begin
     Instruction.evex_p[2]:=Instruction.evex_p[2] or EVEX_P2B;
     if (OperandERSAE^.DecoratorFlags and ODF_ER)<>0 then begin
      Instruction.evex_p[2]:=Instruction.evex_p[2] or (((Instruction.evex_rm-BRC_RN) shl 5) and EVEX_P2RC);
     end;
    end else begin
     Instruction.evex_p[2]:=Instruction.evex_p[2] or ((Instruction.vex_wlp shl (5-2)) and EVEX_P2LL);
     Instruction.evex_p[1]:=Instruction.evex_p[1] or ((Instruction.vex_wlp shl (7-4)) and EVEX_P1W);
     if (OtherOperand^.DecoratorFlags and BRDCAST_MASK)<>0 then begin
      Instruction.evex_p[2]:=Instruction.evex_p[2] or EVEX_P2B;
     end;
    end;
    if IF_MIB in Instruction.Flags then begin
     OtherOperand^.EAFlags:=OtherOperand^.EAFlags or EAF_MIB;
     if MIBIndex<>RegNONE then begin
      OtherOperand^.IndexRegister:=MIBIndex;
      OtherOperand^.Scale.Free;
      OtherOperand^.Scale:=TAssemblerExpression.Create;
      OtherOperand^.Scale.Operation:='x';
      OtherOperand^.Scale.Value.ValueType:=AVT_INT;
      IntegerValueSetQWord(OtherOperand^.Scale.Value.IntegerValue,1);
      OtherOperand^.HintBase:=MIBIndex;
      OtherOperand^.HintType:=EAH_NOTBASE;
     end;
    end;
    if ProcessEA(OtherOperand^,EAData,Bits,RField,RFlags,Instruction)<>eat then begin
     MakeError('Invalid effective address');
     result:=-1;
     exit;
    end else begin
     Instruction.REX:=Instruction.REX or EAData.REX;
     inc(result,EAData.Size);
    end;
   end;
   else begin
    break;
   end;
  end;
 end;

 Instruction.REX:=Instruction.REX and REXMask;

 if (Instruction.REX and REX_NH)<>0 then begin
  if (Instruction.REX and REX_H)<>0 then begin
   MakeWarning('Instruction can''t use high register');
   result:=-1;
   exit;
  end;
  Instruction.REX:=Instruction.REX and not REX_P;
 end;

 case Instruction.Prefixes[PPS_VEX] of
  P_EVEX:begin
   if (Instruction.REX and REX_EV)=0 then begin
    result:=-1;
    exit;
   end;
  end;
  P_VEX3,P_VEX2:begin
   if (Instruction.REX and REX_V)=0 then begin
    result:=-1;
    exit;
   end;
  end;
 end;

 if (Instruction.REX and (REX_V or REX_EV))<>0 then begin

  if (Instruction.REX and REX_H)<>0 then begin
   MakeError('Cannot use high register in AVX instruction');
   result:=-1;
   exit;
  end;

  Bad32:=REX_R or REX_W or REX_X or REX_B;

  case Instruction.VEX_WLP and $30{060} of
   $00{000},$20{040}:begin
    Instruction.REX:=Instruction.REX and not REX_W;
   end;
   $10{020}:begin
    Instruction.REX:=Instruction.REX or REX_W;
    Bad32:=Bad32 and not REX_W;
   end;
   $30{060}:begin
   end;
  end;

  if (Bits<>64) and (((Instruction.REX and Bad32)<>0) or (Instruction.VEXRegister>7)) then begin
   MakeError('Invalid operands in non-64-bit mode');
   result:=-1;
   exit;
  end else if ((Instruction.REX and REX_EV)=0) and ((Instruction.VEXRegister>15) or ((Instruction.evex_p[0] and $f0)<>0)) then begin
   MakeError('Invalid high-16 register in non-AVX-512');
   result:=-1;
   exit;
  end;
  if (Instruction.REX and REX_EV)<>0 then begin
   inc(result,4);
  end else if (Instruction.VEX_CM<>1) or ((Instruction.REX and (REX_W or REX_X or REX_B))<>0) then begin
   inc(result,3);
  end else begin
   inc(result,2);
  end;

 end else if (Instruction.REX and REX_MASK)<>0 then begin

  if (Instruction.REX and REX_H)<>0 then begin
   MakeError('Can''t use high register in rex instruction');
   result:=-1;
   exit;
  end else if Bits=64 then begin
   inc(result);
  end else if ((Instruction.REX and REX_L)<>0) and ((Instruction.REX and (REX_P or REX_W or REX_X or REX_B))=0) and (CPULevel>=IF_X86_64) then begin
   LockCheck:=false;
   inc(result);
  end else begin
   MakeError('Invalid operands in non-64-bit mode');
   result:=-1;
   exit;
  end;

 end;

 if (Instruction.Prefixes[PPS_LOCK]=P_LOCK) and LockCheck and ((not (IF_LOCK in InstructionTemplate.Flags)) or (((not Instruction.Operand[1].Flags) and OF_MEMORY)<>0)) then begin
  if CurrentPass=2 then begin
   MakeWarning('Instruction is not lockable');
  end;
 end;

 if CurrentPass=2 then begin
  rep_pfx:=Instruction.Prefixes[PPS_REP];
  n:=rep_pfx-P_XACQUIRE;
  if (n>=0) and (n<=1) then begin
   ww:=warn[n,hleok];
   if ((not Instruction.Operand[1].Flags) and OF_MEMORY)<>0 then begin
    ww:=w_inval;
   end;
   case ww of
    w_none:begin
    end;
    w_lock:begin
     if Instruction.Prefixes[PPS_LOCK]<>P_LOCK then begin
      if n=0 then begin
       MakeWarning('XACQUIRE with this instruction requires lock');
      end else begin
       MakeWarning('XRELEASE with this instruction requires lock');
      end;
     end;
    end;
    w_inval:begin
     if n=0 then begin
      MakeWarning('XACQUIRE invalid with this instruction');
     end else begin
      MakeWarning('XRELEASE invalid with this instruction');
     end;
    end;
   end;
  end;
 end;

 if (GD_BND in GlobalDefaults) and (IF_BND in InstructionTemplate.Flags) and (Instruction.Prefixes[PPS_REP]<>P_NOBND) then begin
  Instruction.Prefixes[PPS_REP]:=P_BND;
 end;

end;

procedure TAssembler.GenerateInstruction(const Segment:PAssemblerSegment;const Section:PAssemblerSection;const Offset:int64;const Bits:longint;var Instruction:TInstruction;const InstructionTemplate:TInstructionTemplate;HereOffset:longint);
 procedure EmitREX;
 begin
  if (Bits=64) and (((Instruction.REX and REX_MASK)<>0) and ((Instruction.REX and (REX_V or REX_EV)=0)) and not Instruction.REXDone) then begin
   Instruction.REXDone:=true;
   WriteByte((Instruction.REX and REX_MASK) or REX_P);
   inc(HereOffset);
  end;
 end;
var c,b,opex:byte;
    op1,op2,eat,SequencePosition,RField,ValueBits:longint;
    RFlags:TOperandFlags;
    Operand,OtherOperand:POperand;
    EAData:TEA;
    Value:int64;
    ValueMask:uint64;
begin

 opex:=0;

 eat:=EA_SCALAR;

 Instruction.REXDone:=false;

 SequencePosition:=0;
 while SequencePosition<InstructionTemplate.SequenceLength do begin
  c:=InstructionTemplate.Sequence[SequencePosition];
  inc(SequencePosition);
  op1:=(c and 3)+((opex and 1) shl 2);
  op2:=((c shr 3) and 3)+((opex and 2) shl 1);
  Operand:=@Instruction.Operand[op1+1];
  opex:=0;
  case c of
   $01{01}..$04{04}:begin
    EmitREX;
    WriteByte(InstructionTemplate.Sequence[SequencePosition]);
    inc(SequencePosition);
    inc(HereOffset);
    if c>=$02 then begin
     WriteByte(InstructionTemplate.Sequence[SequencePosition]);
     inc(SequencePosition);
     inc(HereOffset);
     if c>=$03 then begin
      WriteByte(InstructionTemplate.Sequence[SequencePosition]);
      inc(SequencePosition);
      inc(HereOffset);
      if c>=$04 then begin
       WriteByte(InstructionTemplate.Sequence[SequencePosition]);
       inc(SequencePosition);
       inc(HereOffset);
      end;
     end;
    end;
   end;
   $05{05}..$07{07}:begin
    opex:=c;
   end;
   $08{010}..$0b{013}:begin
    EmitREX;
    WriteByte(InstructionTemplate.Sequence[SequencePosition]+(RegVal(Operand^) and 7));
    inc(SequencePosition);
    inc(HereOffset);
   end;
   $0c{014}..$0f{017}:begin
   end;
   $10{020}..$13{023}:begin
    AddFixUpExpression(Operand^.Value,Operand^.FixUpExpressionFlags,8,false,0,CurrentLineNumber,CurrentColumn,CurrentSource,mbmSignedWarning,uint64(int64(-256)),255,'Byte value is out of bounds',-HereOffset);
    WriteByte(0);
    inc(HereOffset);
   end;
   $14{024}..$17{027}:begin
    AddFixUpExpression(Operand^.Value,Operand^.FixUpExpressionFlags,8,false,1,CurrentLineNumber,CurrentColumn,CurrentSource,mbmSignedWarning,0,255,'Unsigned byte value is out of bounds',-HereOffset);
    WriteByte(0);
    inc(HereOffset);
   end;
   $18{030}..$1b{033}:begin
    AddFixUpExpression(Operand^.Value,Operand^.FixUpExpressionFlags,16,false,0,CurrentLineNumber,CurrentColumn,CurrentSource,mbmDefault,0,0,'',-HereOffset);
    WriteWord(0);
    inc(HereOffset,2);
   end;
   $1c{034}..$1f{037}:begin
    if (Operand.Flags and (OF_BITS16 or OF_BITS32 or OF_BITS64))<>0 then begin
     if (Operand.Flags and OF_BITS16)<>0 then begin
      AddFixUpExpression(Operand^.Value,Operand^.FixUpExpressionFlags,16,false,0,CurrentLineNumber,CurrentColumn,CurrentSource,mbmDefault,0,0,'',-HereOffset);
      WriteWord(0);
      inc(HereOffset,2);
     end else begin
      AddFixUpExpression(Operand^.Value,Operand^.FixUpExpressionFlags,32,false,0,CurrentLineNumber,CurrentColumn,CurrentSource,mbmDefault,0,0,'',-HereOffset);
      WriteDWord(0);
      inc(HereOffset,4);
     end;
    end else begin
     if Bits=16 then begin
      AddFixUpExpression(Operand^.Value,Operand^.FixUpExpressionFlags,16,false,0,CurrentLineNumber,CurrentColumn,CurrentSource,mbmDefault,0,0,'',-HereOffset);
      WriteWord(0);
      inc(HereOffset,2);
     end else begin
      AddFixUpExpression(Operand^.Value,Operand^.FixUpExpressionFlags,32,false,0,CurrentLineNumber,CurrentColumn,CurrentSource,mbmDefault,0,0,'',-HereOffset);
      WriteDWord(0);
      inc(HereOffset,4);
     end;
    end;
   end;
   $20{040}..$23{043}:begin
    AddFixUpExpression(Operand^.Value,Operand^.FixUpExpressionFlags,32,false,0,CurrentLineNumber,CurrentColumn,CurrentSource,mbmDefault,0,0,'',-HereOffset);
    WriteDWord(0);
    inc(HereOffset,4);
   end;
   $24{044}..$27{047}:begin
    case Instruction.AddressSize of
     8:begin
      AddFixUpExpression(Operand^.Value,Operand^.FixUpExpressionFlags,8,false,0,CurrentLineNumber,CurrentColumn,CurrentSource,mbmDefault,0,0,'',-HereOffset);
      WriteByte(0);
      inc(HereOffset);
     end;
     16:begin
      AddFixUpExpression(Operand^.Value,Operand^.FixUpExpressionFlags,16,false,0,CurrentLineNumber,CurrentColumn,CurrentSource,mbmDefault,0,0,'',-HereOffset);
      WriteWord(0);
      inc(HereOffset,2);
     end;
     32:begin
      AddFixUpExpression(Operand^.Value,Operand^.FixUpExpressionFlags,32,false,0,CurrentLineNumber,CurrentColumn,CurrentSource,mbmDefault,0,0,'',-HereOffset);
      WriteDWord(0);
      inc(HereOffset,4);
     end;
     64:begin
      AddFixUpExpression(Operand^.Value,Operand^.FixUpExpressionFlags,64,false,0,CurrentLineNumber,CurrentColumn,CurrentSource,mbmDefault,0,0,'',-HereOffset);
      WriteQWord(0);
      inc(HereOffset,8);
     end;
    end;
   end;
   $28{050}..$2b{053}:begin
    AddFixUpExpression(Operand^.Value,Operand^.FixUpExpressionFlags,8,true,-1,CurrentLineNumber,CurrentColumn,CurrentSource,mbmSignedError,uint64(int64(-128)),127,'Short jump is out of range',-HereOffset);
    WriteByte(0);
    inc(HereOffset);
   end;
   $2c{054}..$2f{057}:begin
    // MOV reg64/imm
    AddFixUpExpression(Operand^.Value,Operand^.FixUpExpressionFlags,64,false,0,CurrentLineNumber,CurrentColumn,CurrentSource,mbmDefault,0,0,'',-HereOffset);
    WriteQWord(0);
    inc(HereOffset,8);
   end;
   $30{060}..$33{063}:begin
    AddFixUpExpression(Operand^.Value,Operand^.FixUpExpressionFlags,16,true,0,CurrentLineNumber,CurrentColumn,CurrentSource,mbmDefault,0,0,'',-HereOffset);
    WriteWord(0);
    inc(HereOffset,2);
   end;
   $34{064}..$37{067}:begin
    if (Operand.Flags and (OF_BITS16 or OF_BITS32 or OF_BITS64))<>0 then begin
     if (Operand.Flags and OF_BITS16)<>0 then begin
      AddFixUpExpression(Operand^.Value,Operand^.FixUpExpressionFlags,16,true,0,CurrentLineNumber,CurrentColumn,CurrentSource,mbmDefault,0,0,'',-HereOffset);
      WriteWord(0);
      inc(HereOffset,2);
     end else begin
      AddFixUpExpression(Operand^.Value,Operand^.FixUpExpressionFlags,32,true,0,CurrentLineNumber,CurrentColumn,CurrentSource,mbmDefault,0,0,'',-HereOffset);
      WriteDWord(0);
      inc(HereOffset,4);
     end;
    end else begin
     if Bits=16 then begin
      AddFixUpExpression(Operand^.Value,Operand^.FixUpExpressionFlags,16,true,0,CurrentLineNumber,CurrentColumn,CurrentSource,mbmDefault,0,0,'',-HereOffset);
      WriteWord(0);
      inc(HereOffset,2);
     end else begin
      AddFixUpExpression(Operand^.Value,Operand^.FixUpExpressionFlags,32,true,0,CurrentLineNumber,CurrentColumn,CurrentSource,mbmDefault,0,0,'',-HereOffset);
      WriteDWord(0);
      inc(HereOffset,4);
     end;
    end;
   end;
   $38{070}..$3b{073}:begin
    AddFixUpExpression(Operand^.Value,Operand^.FixUpExpressionFlags,32,true,0,CurrentLineNumber,CurrentColumn,CurrentSource,mbmDefault,0,0,'',-HereOffset);
    WriteDWord(0);
    inc(HereOffset,4);
   end;
   $3c{074}..$3f{077}:begin
    // Segment part //!!!
    AddFixUpExpression(Operand^.Value,Operand^.FixUpExpressionFlags,16,false,0,CurrentLineNumber,CurrentColumn,CurrentSource,mbmDefault,0,0,'',-HereOffset);
    WriteWord(0);
    inc(HereOffset,2);
   end;
   $7a{0172}:begin
    c:=InstructionTemplate.Sequence[SequencePosition];
    inc(SequencePosition);
    Operand:=@Instruction.Operand[(c shr 3)+1];
    b:=RegisterTemplates[Operand^.BaseRegister].RegisterNumber shl 4;
    Operand:=@Instruction.Operand[(c and 7)+1];
    if assigned(Operand^.Value) and not Operand^.Value.IsConstant(self) then begin
     MakeError('Non-absolute expression not permitted as argument '+IntToStr(c and 7));
    end else begin
     Value:=ValueGetInt64(self,Operand^.Value.Evaluate(self,true),false);
     if (Value and not 15)<>0 then begin
      MakeWarning('Four-bit argument exceeds bounds');
     end;
     b:=b or Value;
    end;
    WriteByte(b);
    inc(HereOffset);
   end;
   $7b{0173}:begin
    c:=InstructionTemplate.Sequence[SequencePosition];
    inc(SequencePosition);
    Operand:=@Instruction.Operand[(c shr 4)+1];
    b:=(RegisterTemplates[Operand^.BaseRegister].RegisterNumber shl 4) or (c and 15);
    WriteByte(b);
    inc(HereOffset);
   end;
   $7c{0174}..$7f{0177}:begin
    b:=RegisterTemplates[Operand^.BaseRegister].RegisterNumber shl 4;
    WriteByte(b);
    inc(HereOffset);
   end;
   $a0{0240}..$a3{0243},
   $a8{0250}..$ab{0253}:begin
    inc(SequencePosition,3);
    Instruction.evex_p[2]:=(Instruction.evex_p[2] or OpEVEXFlags(Instruction.Operand[1],EVEX_P2Z or EVEX_P2AAA,2)) xor EVEX_P2VP;
    WriteByte($62);
    WriteByte(((((Instruction.REX and 7) shl 5) or (Instruction.evex_p[0] and (EVEX_P0X or EVEX_P0RP))) xor $f0) or (Instruction.vex_cm and EVEX_P0MM));
    WriteByte(((Instruction.REX and REX_W) shl (7-3)) or (((not Instruction.VEXRegister) and 15) shl 3) or (1 shl 2) or (Instruction.vex_wlp and 3));
    WriteByte(Instruction.evex_p[2]);
    inc(HereOffset,4);
   end;
   $ac{0254}..$af{0257}:begin
    AddFixUpExpression(Operand^.Value,Operand^.FixUpExpressionFlags,32,false,-1,CurrentLineNumber,CurrentColumn,CurrentSource,mbmSignedWarning,uint64(int64(longint(longword($80000000)))),uint64(int64(longint(longword($7fffffff)))),'Signed dword value is ouf of bounds',-HereOffset);
    WriteDWord(0);
    inc(HereOffset,4);
   end;
   $b0{0260}..$b3{0263},$b8{0270}:begin
    inc(SequencePosition,2);
    if (Instruction.VEX_CM<>1) or ((Instruction.REX and (REX_W or REX_X or REX_B))<>0) or (Instruction.Prefixes[PPS_VEX]=P_VEX3) then begin
     if (Instruction.VEX_CM shr 6)<>0 then begin
      WriteByte($8f);
     end else begin
      WriteByte($c4);
     end;
     WriteByte((Instruction.VEX_CM and 31) or (((not Instruction.REX) and 7) shl 5));
     WriteByte(((Instruction.REX and REX_W) shl (7-3)) or (((not Instruction.VEXRegister) and 15) shl 3) or (Instruction.vex_wlp and 7));
     inc(HereOffset,3);
    end else begin
     WriteByte($c5);
     WriteByte((((not Instruction.REX) and REX_R) shl (7-2)) or (((not Instruction.VEXRegister) and 15) shl 3) or (Instruction.vex_wlp and 7));
     inc(HereOffset,2);
    end;
   end;
   $b9{0271}..$bb{0273}:begin
   end;
   $bc{0274}..$bf{0277}:begin
    if (Instruction.REX and REX_W)<>0 then begin
     ValueBits:=64;
    end else if Instruction.Prefixes[PPS_OSIZE]=P_O16 then begin
     ValueBits:=16;
    end else if Instruction.Prefixes[PPS_OSIZE]=P_O32 then begin
     ValueBits:=32;
    end else begin
     ValueBits:=CurrentBits;
    end;
    ValueMask:=uint64(2) shl (ValueBits-1);
    AddFixUpExpression(Operand^.Value,Operand^.FixUpExpressionFlags,8,false,-1,CurrentLineNumber,CurrentColumn,CurrentSource,mbmByteSignedWarning,ValueMask-128,ValueMask-1,'Byte value is out of bounds',-HereOffset);
    WriteByte(0);
    inc(HereOffset);
   end;
   $c0{0300}..$c3{0303}:begin
   end;
   $c8{0310}:begin
    if (Bits=32) and (Instruction.Prefixes[PPS_ASIZE]<>P_A16) then begin
     WriteByte($67);
     inc(HereOffset);
    end;
   end;
   $c9{0311}:begin
    if (Bits<>32) and (Instruction.Prefixes[PPS_ASIZE]<>P_A32) then begin
     WriteByte($67);
     inc(HereOffset);
    end;
   end;
   $ca{0312}:begin
   end;
   $cb{0313}:begin
    Instruction.REX:=0;
   end;
   $cc{0314}..$cf{0317}:begin
   end;
   $d0{0320},
   $d1{0321}:begin
   end;
   $d2{0322},
   $d3{0323}:begin
   end;
   $d4{0324}:begin
    Instruction.REX:=Instruction.REX or REX_W;
   end;
   $d5{0325}:begin
   end;
   $d6{0326}:begin
   end;
   $d8{0330}:begin
    WriteByte(InstructionTemplate.Sequence[SequencePosition] {or ConditionCode});
    inc(SequencePosition);
    inc(HereOffset);
   end;
   $d9{0331}:begin
   end;
   $da{0332}..$db{0333}:begin
    WriteByte((c-$da{0332})+$f2);
    inc(HereOffset);
   end;
   $dc{0334}:begin
    if (Instruction.REX and REX_R)<>0 then begin
     WriteByte($f0);
     inc(HereOffset);
    end;
    Instruction.REX:=Instruction.REX and not (REX_R or REX_L);
   end;
   $dd{0335}:begin
   end;
   $de{0336},
   $df{0337}:begin
   end;
   $e0{0340}:begin
    if assigned(Operand.Value) and not Operand.Value.IsConstant(self) then begin
     MakeError('Non-constant BSS size in pass '+IntToStr(CurrentPass));
    end else begin
     Value:=ValueGetInt64(self,Operand.Value.Evaluate(self,true),false);
     WriteCountDummyBytes(Value);
     inc(HereOffset,Value);
    end;
   end;
   $e1{0341}:begin
   end;
   $f0{0360}:begin
   end;
   $f1{0361}:begin
    WriteByte($66);
    inc(HereOffset);
   end;
   $f4{0364}..$f5{0365}:begin
   end;
   $f6{0366}..$f7{0367}:begin
    WriteByte($66+(c-$f6{0366}));
    inc(HereOffset);
   end;
   $f8{0370}..$f9{0371}:begin
   end;
   $fb{0373}:begin
    if Bits=16 then begin
     WriteByte(3);
    end else begin
     WriteByte(5);
    end;
    inc(HereOffset);
   end;
   $fc{0374}:begin
    eat:=EA_XMMVSIB;
   end;
   $fd{0375}:begin
    eat:=EA_YMMVSIB;
   end;
   $fe{0376}:begin
    eat:=EA_ZMMVSIB;
   end;
   $40{0100}..$43{0103},
   $48{0110}..$4b{0113},
   $50{0120}..$53{0123},
   $58{0130}..$5b{0133},
   $80{0200}..$83{0203},
   $84{0204}..$87{0207},
   $88{0210}..$8b{0213},
   $8c{0214}..$8f{0217},
   $90{0220}..$93{0223},
   $94{0224}..$97{0227},            
   $98{0230}..$9b{0233},
   $9c{0234}..$9f{0237}:begin
    FillChar(EAData,SizeOf(TEA),AnsiChar(#0));
    EAData.REX:=0;
    OtherOperand:=@Instruction.Operand[op2+1];
    if c<$80 then begin
     RFlags:=RegFlags(Operand^);
     RField:=RegisterTemplates[Operand^.BaseRegister].RegisterNumber;
    end else begin
     RFlags:=0;
     RField:=c and 7;
    end;
    if ProcessEA(OtherOperand^,EAData,Bits,RField,RFlags,Instruction)<>eat then begin
     MakeError('Invalid effective address');
    end;
    WriteByte(EAData.MODRM);
    inc(HereOffset);
    if EAData.SIBPresent then begin
     WriteByte(EAData.SIB);
     inc(HereOffset);
    end;
    if EAData.Bytes<>0 then begin
     if EAData.Displacement<>0 then begin
      FreeAndNil(OtherOperand^.Value);
      OtherOperand^.Value:=TAssemblerExpression.Create;
      OtherOperand^.Value.Operation:='x';
      OtherOperand^.Value.Value.ValueType:=AVT_INT;
      IntegerValueSetInt64(OtherOperand^.Value.Value.IntegerValue,EAData.Displacement);
     end;
     AddFixUpExpression(OtherOperand^.Value,Operand^.FixUpExpressionFlags,EAData.Bytes shl 3,EAData.Relative,0,CurrentLineNumber,CurrentColumn,CurrentSource,mbmDefault,0,0,'',-HereOffset);
     WriteByteCount(0,EAData.Bytes);
     inc(HereOffset,EAData.Bytes);
    end;
   end;
   else begin
    break;
   end;
  end;
 end;

end;

function TAssembler.JumpInstructionMatch(const Segment:PAssemblerSegment;const Section:PAssemblerSection;const Offset:int64;const Bits:longint;var Instruction:TInstruction;const InstructionTemplate:TInstructionTemplate):boolean;
var Size:longint;
    IntegerValue:TIntegerValue;
    Symbol:TUserSymbol;
begin
 result:=false;
 if (InstructionTemplate.SequenceLength=0) or
    ((InstructionTemplate.Sequence[0] and $fe)<>$f8) or
    ((Instruction.Operand[1].Flags and OF_STRICT)<>0) then begin
  exit;
 end;
 if OptimizationLevel=0 then begin
  exit;
 end;
 if (OptimizationLevel<0) and (InstructionTemplate.Sequence[0]=$f9) then begin
  exit;
 end;
{if Target in ObjectTargets then begin
  exit;
 end;{}
 Size:=CalculateInstructionSize(Segment,Section,Offset,Bits,Instruction,InstructionTemplate);
 if assigned(Instruction.Operand[1].Value) then begin
  Symbol:=Instruction.Operand[1].Value.GetFixUpSymbol(self);
  if assigned(Symbol) and (Symbol.Section=Section) and not Symbol.IsExternal then begin
   if Symbol.HasPosition then begin
    IntegerValue:=ValueToRawInt(self,Instruction.Operand[1].Value.Evaluate(self,true),false);
    IntegerValue:=IntSub(IntegerValue,IntSet(Size));
    IntegerValue:=IntSub(IntegerValue,IntSet(CodePosition));
    if not (assigned(Symbol) and assigned(Symbol.Section)) then begin
     IntegerValue:=IntSub(IntegerValue,IntSet(StartOffset));
    end;
    if (IntCompare(IntegerValue,-128)>=0) and (IntCompare(IntegerValue,127)<=0) then begin
     result:=true;
     if (Instruction.Prefixes[PPS_REP]=P_BND) and (InstructionTemplate.Sequence[0]=$f9) then begin
      Instruction.Prefixes[PPS_REP]:=P_NONE;
      if CurrentPass=2 then begin
       MakeWarning('jmp short does not init bnd regs - bnd prefix dropped');
      end;
     end;
    end;
   end else begin
    // Be optimistic yet
    result:=true;
   end;
  end;
 end;
end;

function TAssembler.FindInstructionMatch(var InstructionTemplate:PInstructionTemplate;var Instruction:TInstruction;const Segment:PAssemblerSegment;const Section:PAssemblerSection;const Offset:int64;const Bits:longint):longint;
var i,m,InstructionTemplateIndex:longint;
    OpcodeTemplate:POpcodeTemplate;
    t:PInstructionTemplate;
    OpSizeMissing:boolean;
    xSizeFlags:array[0..MaxOperands-1] of TOperandFlags;
    broadcast:shortint;
begin
 OpSizeMissing:=false;

 broadcast:=Instruction.evex_brerop;

 for i:=0 to Instruction.CountOperands-1 do begin
  if i=broadcast then begin
   xSizeFlags[i]:=Instruction.Operand[i+1].DecoratorFlags and BRSIZE_MASK;
  end else begin
   xSizeFlags[i]:=Instruction.Operand[i+1].Flags and SIZE_MASK;
  end;
 end;

 result:=MATCH_ERROR_INVALID_OPCODE;

 OpcodeTemplate:=@OpcodeTemplates[Instruction.Opcode];

 for InstructionTemplateIndex:=OpcodeTemplate^.FromTemplateIndex to OpcodeTemplate^.ToTemplateIndex do begin
  t:=@InstructionTemplates[InstructionTemplateIndex];
  m:=InstructionMatches(t,Instruction,Bits);
  if m=MATCH_OKAY_JUMP then begin
   if JumpInstructionMatch(Segment,Section,Offset,Bits,Instruction,t^) then begin
    m:=MATCH_OKAY_GOOD;
   end else begin
    m:=MATCH_ERROR_INVALID_OPCODE;
   end;
  end else if (m=MATCH_ERROR_OPCODE_SIZE_MISSING) and not (IF_SX in t^.Flags) then begin
   for i:=0 to t^.CountOperands-1 do begin
    if i=broadcast then begin
     xSizeFlags[i]:=xSizeFlags[i] or (t^.Decorators[i] and BRSIZE_MASK);
    end else begin
     xSizeFlags[i]:=xSizeFlags[i] or (t^.Operands[i] and SIZE_MASK);
    end;
   end;
   OpSizeMissing:=true;
  end;
  if result<m then begin
   result:=m;
  end;
  if result=MATCH_OKAY_GOOD then begin
   InstructionTemplate:=t;
   exit;
  end;
 end;

 if not OpSizeMissing then begin
  InstructionTemplate:=t;
  exit;
 end;

 for i:=0 to Instruction.CountOperands-1 do begin
  if ((not Instruction.Operand[i+1].Flags) and OF_REGISTER)=0 then begin
   continue;
  end;
  if (xSizeFlags[i] and (xSizeFlags[i]-1))<>0 then begin
   InstructionTemplate:=t;
   exit;
  end;
  if i=broadcast then begin
   Instruction.Operand[i+1].DecoratorFlags:=Instruction.Operand[i+1].DecoratorFlags or xSizeFlags[i];
   if xSizeFlags[i]=BR_BITS32 then begin
    Instruction.Operand[i+1].Flags:=Instruction.Operand[i+1].Flags or OF_BITS32;
   end else begin
    Instruction.Operand[i+1].Flags:=Instruction.Operand[i+1].Flags or OF_BITS64;
   end;
  end else begin
   Instruction.Operand[i+1].Flags:=Instruction.Operand[i+1].Flags or xSizeFlags[i];
  end;
 end;

 for InstructionTemplateIndex:=OpcodeTemplate^.FromTemplateIndex to OpcodeTemplate^.ToTemplateIndex do begin
  t:=@InstructionTemplates[InstructionTemplateIndex];
  m:=InstructionMatches(t,Instruction,Bits);
  if m=MATCH_OKAY_JUMP then begin
   if JumpInstructionMatch(Segment,Section,Offset,Bits,Instruction,t^) then begin
    m:=MATCH_OKAY_GOOD;
   end else begin
    m:=MATCH_ERROR_INVALID_OPCODE;
   end;
  end;
  if result<m then begin
   result:=m;
  end;
  if result=MATCH_OKAY_GOOD then begin
   InstructionTemplate:=t;
   exit;
  end;
 end;

 InstructionTemplate:=t;

end;

procedure TAssembler.CheckInstruction(var Instruction:TInstruction);
(*var Value:int64;
    SymbolIndex:longint;
    Symbol:TUserSymbol;
    IsShort:boolean;
begin
 if Opcode.Symbol<=OpEnd then begin
  case Opcode.Symbol of
   OpINT:begin
    if (Opcode.CountOperands=1) and ((Opcode.Operand[1].IsImmediate and not (Opcode.Operand[1].IsMemory or Opcode.Operand[1].IsMemoryOffset))) and (Opcode.Operand[1].Value.SymbolIndex<0) and (not assigned(Opcode.Operand[1].Value.Expression)) and (CPU>=86) then begin
     case Opcode.Operand[1].Value.Value of
      1:begin
       Opcode.Symbol:=OpINT1;
       Opcode.CountOperands:=0;
      end;
      3:begin
       Opcode.Symbol:=OpINT3;
       Opcode.CountOperands:=0;
      end;
     end;
    end;
   end;
   OpJA,OpJAE,OpJB,OpJBE,OpJC,OpJCXZ,OpJE,OpJECXZ,OpJG,OpJGE,OpJL,OpJLE,OpJMP,
   OpJNA,OpJNAE,OpJNB,OpJNBE,OpJNC,OpJNE,OpJNG,OpJNGE,OpJNL,OpJNLE,OpJNO,OpJNP,
   OpJNS,OpJNZ,OpJO,OpJP,OpJPE,OpJPO,OpJS,OpJZ:begin
    if (Opcode.CountOperands=1) and (((Opcode.Operand[1].IsImmediate and Opcode.Operand[1].IsNearShortAuto) and not (Opcode.Operand[1].IsMemory or Opcode.Operand[1].IsFar or Opcode.Operand[1].IsMemoryOffset or Opcode.Operand[1].IsRegister))) and (CPU>=86) then begin
     if OptimizeJumps then begin
      if not assigned(Opcode.Operand[1].Value.Expression) then begin
       Value:=Opcode.Operand[1].Value.Value;
       if assigned(Opcode.Operand[1].Value.Expression) then begin
        inc(Value,Opcode.Operand[1].Value.Expression.Evaluate(SymbolTree,self));
       end;
       SymbolIndex:=Opcode.Operand[1].Value.SymbolIndex;
       if (SymbolIndex>=0) and (SymbolIndex<UserSymbolList.Count) then begin
        Symbol:=UserSymbolList[SymbolIndex];
        if Symbol.IsExternal or (CurrentSection<>Symbol.Section) then begin
         Opcode.Operand[1].IsShort:=false;
         Opcode.Operand[1].IsNear:=true;
        end else if Symbol.HasPosition then begin
         inc(Value,Symbol.GetValue(SymbolTree,self));
         case Symbol.SymbolType of
          ustNONE:MakeError(9);
          ustLABEL:if not assigned(Symbol.Section) then inc(Value,StartOffset);
          ustDEFINE,ustMACRO,ustSCRIPTMACRO{,ustSTRUCT}:MakeError(27);
         end;
         if ((CurrentPass>1) and (CurrentPass<CurrentPasses) and (CurrentPasses>=4)) and not CodeImageWriting then begin
          case Opcode.PrefixRegister of
           RegCS,RegDS,RegES,RegSS,RegFS,RegGS:dec(Value);
          end;
          dec(Value,CodePosition);
          if not assigned(Symbol.Section) then dec(Value,StartOffset);
          dec(Value);                              // Opcode
          dec(Value,Opcode.Bits div 8);            // Operand
          IsShort:=(Value>=-128) and (Value<=127) and (CurrentSection=Symbol.Section) and not (Target in ObjectTargets);
          Opcode.Operand[1].IsShort:=IsShort;
          Opcode.Operand[1].IsNear:=not IsShort;
         end;
        end;
       end else begin
        Opcode.Operand[1].IsShort:=false;
        Opcode.Operand[1].IsNear:=true;
       end;
      end else begin
       Opcode.Operand[1].IsShort:=false;
       Opcode.Operand[1].IsNear:=true;
      end;
     end else begin
      Opcode.Operand[1].IsShort:=false;
      Opcode.Operand[1].IsNear:=true;
     end;
    end else if (Target in ObjectTargets) and ((Opcode.CountOperands=1) and (((Opcode.Operand[1].IsImmediate and Opcode.Operand[1].IsShort) and not (Opcode.Operand[1].IsMemory or Opcode.Operand[1].IsFar or Opcode.Operand[1].IsMemoryOffset or Opcode.Operand[1].IsRegister))) and (CPU>=86)) then begin
     SymbolIndex:=Opcode.Operand[1].Value.SymbolIndex;
     if (SymbolIndex>=0) and (SymbolIndex<UserSymbolList.Count) then begin
      Symbol:=UserSymbolList[SymbolIndex];
      if Symbol.IsExternal or (CurrentSection<>Symbol.Section) then begin
       Opcode.Operand[1].IsShort:=false;
       Opcode.Operand[1].IsNear:=true;
      end;
     end else begin
      Opcode.Operand[1].IsShort:=false;
      Opcode.Operand[1].IsNear:=true;
     end;
    end;
   end;
  end;
 end;
end;(**)
begin
end;

procedure TAssembler.ProcessInstruction(Code:PCode);
var InstructionSize,HereOffset:longint;
    InstructionTemplate:PInstructionTemplate;
begin
 Code^.Segment:=CurrentSegment;
 Code^.Section:=CurrentSection;
 if longint(Code^.Instruction.Opcode)<=longint(OpEnd) then begin
{ if Code^.Instruction.Operand[2].Value.Value=$4c then begin
   if Code^.Instruction.Operand[2].Value.Value=$4c then begin
   end;
  end;{}
  AddASP(Code^.Instruction,CurrentBits);
  case FindInstructionMatch(InstructionTemplate,Code^.Instruction,CurrentSegment,CurrentSection,CodePosition,CurrentBits) of
   MATCH_ERROR_INVALID_OPCODE:begin
    MakeError('Invalid combination of opcode and operands');
   end;
   MATCH_ERROR_OPCODE_SIZE_MISSING:begin
    MakeError('Operation size not specified');
   end;
   MATCH_ERROR_OPCODE_SIZE_MISMATCH:begin
    MakeError('Mismatch in operand sizes');
   end;
   MATCH_ERROR_BROADCAST_SIZE_MISMATCH:begin
    MakeError('Mismatch in the number of broadcasting elements');
   end;
   MATCH_ERROR_BAD_CPU:begin
    MakeError('No instruction for this CPU level');
   end;
   MATCH_ERROR_BAD_MODE:begin
    MakeError('Instruction not supported in '+IntToStr(CurrentBits)+'-bit mode');
   end;
   MATCH_ERROR_BAD_HLE:begin
    MakeError('Invalid combination of opcode and operands');
   end;
   MATCH_ERROR_ENCODING_MISMATCH:begin
    MakeError('Specific encoding scheme not available');
   end;
   MATCH_ERROR_BAD_BND:begin
    MakeError('BND prefix isn''t allowed');
   end;
   MATCH_ERROR_BAD_REPNE:begin
    if Code^.Instruction.Prefixes[PPS_REP]=P_REPNE then begin
     MakeError('REPNE prefix isn''t allowed');
    end else begin
     MakeError('REPNZ prefix isn''t allowed');
    end;
   end;
   MATCH_OKAY_JUMP:begin
    MakeError('Internal error');
   end;
   MATCH_OKAY_GOOD:begin
    HereOffset:=0;
    InstructionSize:=CalculateInstructionSize(CurrentSegment,CurrentSection,CodePosition,CurrentBits,Code^.Instruction,InstructionTemplate^);
    if InstructionSize>=0 then begin
     case Code^.Instruction.Prefixes[PPS_WAIT] of
      P_WAIT:begin
       WriteByte($9b);
       inc(HereOffset);
      end;
     end;
     case Code^.Instruction.Prefixes[PPS_REP] of
      P_REPNE,P_REPNZ,P_XACQUIRE,P_BND:begin
       WriteByte($f2);
       inc(HereOffset);
      end;
      P_REPE,P_REPZ,P_REP,P_XRELEASE:begin
       WriteByte($f3);
       inc(HereOffset);
      end;
     end;
     case Code^.Instruction.Prefixes[PPS_LOCK] of
      P_LOCK:begin
       WriteByte($f0);
       inc(HereOffset);
      end;
     end;
     case Code^.Instruction.Prefixes[PPS_SEG] of
      RegCS:begin
       if (CurrentBits=64) and (CurrentPass=2) then begin
        MakeWarning('cs segment base generated, but will be ignored in 64-bit mode');
       end;
       WriteByte($2e);
       inc(HereOffset);
      end;
      RegDS:begin
       if (CurrentBits=64) and (CurrentPass=2) then begin
        MakeWarning('ds segment base generated, but will be ignored in 64-bit mode');
       end;
       WriteByte($3e);
       inc(HereOffset);
      end;
      RegES:begin
       if (CurrentBits=64) and (CurrentPass=2) then begin
        MakeWarning('es segment base generated, but will be ignored in 64-bit mode');
       end;
       WriteByte($26);
       inc(HereOffset);
      end;
      RegFS:begin
       WriteByte($64);
       inc(HereOffset);
      end;
      RegGS:begin
       WriteByte($65);
       inc(HereOffset);
      end;
      RegSS:begin
       if (CurrentBits=64) and (CurrentPass=2) then begin
        MakeWarning('ss segment base generated, but will be ignored in 64-bit mode');
       end;
       WriteByte($36);
       inc(HereOffset);
      end;
      RegSEGR6,RegSEGR7:begin
       MakeError(64);
      end;   
     end;
     case Code^.Instruction.Prefixes[PPS_OSIZE] of
      P_O16:begin
       if CurrentBits<>16 then begin
        WriteByte($66);
        inc(HereOffset);
       end;
      end;
      P_O32:begin
       if CurrentBits=16 then begin
        WriteByte($66);
        inc(HereOffset);
       end;
      end;
      P_OSP:begin
       WriteByte($66);
       inc(HereOffset);
      end;
     end;
     case Code^.Instruction.Prefixes[PPS_ASIZE] of
      P_A16:begin
       if CurrentBits=64 then begin
        MakeError(65);
       end else if CurrentBits<>16 then begin
        WriteByte($67);
        inc(HereOffset);
       end;
      end;
      P_A32:begin
       if CurrentBits<>32 then begin
        WriteByte($67);
        inc(HereOffset);
       end;
      end;
      P_A64:begin
       if CurrentBits<>64 then begin
        MakeError(66);
       end;
      end;
      P_ASP:begin
       WriteByte($67);
       inc(HereOffset);
      end;
     end;
     if CurrentPass=1 then begin
      WriteCountDummyBytes(InstructionSize);
     end else begin
      GenerateInstruction(CurrentSegment,CurrentSection,CodePosition,CurrentBits,Code^.Instruction,InstructionTemplate^,HereOffset);
     end;
    end else begin
     MakeError(0);
    end;
   end;
   else begin
    MakeError(1);
   end;
  end;
 end else begin
  MakeError(1);
 end;
end;
(*CheckInstruction(Code^.Instruction);
{$ifdef IDE}
 Code^.InstructionInfoIndex:=GenerateInstruction(Code^.Instruction);
{$else}
 GenerateInstruction(Code^.Instruction);
{$endif}
end;*)

procedure TAssembler.ProcessLabel(SymbolIndex:longint);
var Symbol:TUserSymbol;
begin
 if (SymbolIndex>=0) and (SymbolIndex<UserSymbolList.Count) then begin
  Symbol:=UserSymbolList[SymbolIndex];
  Symbol.Segment:=CurrentSegment;
  Symbol.Section:=CurrentSection;
  Symbol.Position:=CodePosition;
  Symbol.HasPosition:=true;
  Symbol.UseIt(self);
 end;
end;

procedure TAssembler.ProcessConstant(Code:PCode);
var Symbol:TUserSymbol;
begin
 if (Code^.SymbolIndex>=0) and (Code^.SymbolIndex<UserSymbolList.Count) then begin
  Symbol:=UserSymbolList[Code^.SymbolIndex];
  Symbol.Calculate(self,Code^.Expression);
 end;
end;

procedure TAssembler.ProcessTimes(Code:PCode);
var Value:int64;
begin
 Value:=ValueGetInt64(self,Code^.Expression.Evaluate(self),false);
 while Value>0 do begin
  GeneratePass(Code^.Down);
  dec(Value);
 end;
end;

procedure TAssembler.ProcessData(Code:PCode);
 procedure DoFloat;
 var FloatValue:TFloatValue;
     IntValue:int64;
     Value:TAssemblerValue;
     Size:longint;
 begin
  if assigned(Code^.Expression) then begin
   Value:=Code^.Expression.Evaluate(self,true);
  end else begin
   Value.ValueType:=AVT_FLOAT;
   FillChar(Value.FloatValue,SizeOf(TFloatValue),#0);
  end;
  if Value.ValueType=AVT_FLOAT then begin
   FloatValue:=Value.FloatValue;
  end else begin
   MakeError('Internal error');
   exit;
  end;
  if FloatValue.Count<>Code^.Value then begin
   MakeError('Internal error');
   exit;
  end;
  Size:=Code^.Value;
  if assigned(Code^.SecondExpression) then begin
   IntValue:=ValueGetInt64(self,Code^.SecondExpression.Evaluate(self),false);
   if (IntValue>=1) and (IntValue<=(Code^.Value shl 3)) then begin
    TruncBits(FloatValue,IntValue);
   end else if CodeImageWriting then begin
    MakeError(49);
   end;
  end;
  if CodeImageWriting then begin
   if assigned(CurrentSection) then begin
    CurrentSection^.Data.Write(FloatValue.Bytes[0],SizeOf(byte)*Size);
   end else if (CodeEnd<0) or (CodePosition<CodeEnd) then begin
    CodeImage.Write(FloatValue.Bytes[0],SizeOf(byte)*Size);
   end;
  end;
  inc(CodePosition,SizeOf(byte)*Size);
 end;
 procedure DoString;
 var Len:longint;
     //Symbol:TUserSymbol;
     Value:TAssemblerValue;
     StringData:ansistring;
 begin
  if assigned(Code^.Expression) then begin
   Value:=Code^.Expression.Evaluate(self,true);
  end else begin
   Value.ValueType:=AVT_STRING;
   Value.StringValue:='';
  end;
  StringData:=ValueToString(self,Value,true);
  Len:=length(StringData);
  if Code^.Value>1 then begin
   while (Len mod Code^.Value)<>0 do begin
    StringData:=StringData+#0;
    Len:=length(StringData);
   end;
  end;
  if Len>0 then begin
   if CodeImageWriting then begin
    if assigned(CurrentSection) then begin
     CurrentSection^.Data.Write(StringData[1],Len);
    end else if (CodeEnd<0) or (CodePosition<CodeEnd) then begin
     CodeImage.Write(StringData[1],Len);
    end;
   end;
   inc(CodePosition,Len);
  end;
 end;
 procedure DoInteger;
 var Size:longint;
 begin
  Size:=Code^.Value;
  case Size of
   1,2,4,8,10,16,32,64:begin
    AddFixUpExpression(Code^.Expression,Code^.Expression.GetFixUpExpressionFlags(self),Size shl 3,false,0,CurrentLineNumber,CurrentColumn,CurrentSource,mbmDefault,0,0,'',0);
    WriteCountDummyBytes(Size);
   end;
   else begin
    MakeError('Internal error');
   end;
  end;
 end;
var Value:TAssemblerValue;
begin
 if assigned(Code^.Expression) then begin
  Value:=Code^.Expression.Evaluate(self,true);
  case Value.ValueType of
   AVT_INT:begin
    DoInteger;
   end;
   AVT_FLOAT:begin
    DoFloat;
   end;
   AVT_STRING:begin
    DoString;
   end;
   else begin
    MakeError('Internal error');
   end;
  end;
 end else begin
  MakeError('Internal error');
 end;
end;

procedure TAssembler.ProcessDataRawString(Code:PCode);
var Len,Skip,Count:int64;
begin
 Len:=length(Code^.StringData);
 if assigned(Code^.Expression) then begin
  Skip:=ValueGetInt64(self,Code^.Expression.Evaluate(self,false),true);
  if Skip<0 then begin
   Skip:=0;
  end else if Skip>Len then begin
   Skip:=Len;
  end;
 end else begin
  Skip:=0;
 end;
 if assigned(Code^.SecondExpression) then begin
  Count:=ValueGetInt64(self,Code^.SecondExpression.Evaluate(self,false),true);
  if Count<0 then begin
   Count:=0;
  end else if Count>Len then begin
   Count:=Len;
  end;
 end else begin
  Count:=Len;
 end;
 if Skip>=Len then begin
  Count:=0;
 end else if (Skip+Count)>Len then begin
  Count:=Len-Skip;
  if Count<0 then begin
   Count:=0;
  end else if Count>Len then begin
   Count:=Len;
  end;
 end;
 if Count>0 then begin
  if CodeImageWriting then begin
   if assigned(CurrentSection) then begin
    CurrentSection^.Data.Write(Code^.StringData[1+Skip],Count);
   end else if (CodeEnd<0) or (CodePosition<CodeEnd) then begin
    CodeImage.Write(Code^.StringData[1+Skip],Count);
   end;
  end;
  inc(CodePosition,Count);
 end;
end;

procedure TAssembler.ProcessDataEmpty(Code:PCode);
var Size:longint;
    Value:int64;
begin
 Size:=Code^.Value;
 Value:=ValueGetInt64(self,Code^.Expression.Evaluate(self),false);
 if CodeImageWriting then begin
  if assigned(CurrentSection) or ((CodeEnd<0) or (CodePosition<CodeEnd)) then begin
   if assigned(CurrentSection) then begin
    CurrentSection^.Data.SetSize(CurrentSection^.Data.Position+(Value*Size));
   end else if (CodeEnd<0) or (CodePosition<CodeEnd) then begin
    CodeImage.SetSize(CodeImage.Position+(Value*Size));
   end;
   while Value>0 do begin
    WriteCountDummyBytes(Size);
    dec(Value);
   end;
  end else begin
   inc(CodePosition,Value*Size);
// CodeImage.SeekFast(CodePosition);
  end;
 end else begin
  inc(CodePosition,Value*Size);
 end;
end;

procedure TAssembler.ProcessENTRYPOINT;
begin
 EntryPointSection:=CurrentSection;
 EntryPoint:=CodePosition;
end;

procedure TAssembler.ProcessUSERENTRYPOINT;
begin
 UserEntryPoint:=CodePosition;
end;

procedure TAssembler.ProcessOFFSET(Code:PCode);
var Value:int64;
begin
 if assigned(CurrentSection) then begin
  Value:=ValueGetInt64(self,Code^.Expression.Evaluate(self),true);
  dec(Value,CodePosition);
  WritePadding(Value);
 end else if Target=ttBIN then begin
  ProcessSTARTOFFSET(Code);
 end else begin
  Value:=ValueGetInt64(self,Code^.Expression.Evaluate(self),true);
  dec(Value,StartOffset+CodePosition);
  WritePadding(Value);
  IsStartOffsetSet:=true;
 end;
end;

procedure TAssembler.ProcessSTARTOFFSET(Code:PCode);
var Value:int64;
begin
 if assigned(CurrentSection) then begin
  ProcessOFFSET(Code);
 end else begin
  Value:=ValueGetInt64(self,Code^.Expression.Evaluate(self),true);
  if IsStartOffsetSet then begin
   dec(Value,StartOffset+CodePosition);
   WritePadding(Value);
  end else begin
   IsStartOffsetSet:=true;
   StartOffset:=Value;
  end;
 end;
end;

procedure TAssembler.ProcessALIGN(Code:PCode);
var Value:int64;
begin
 Value:=ValueGetInt64(self,Code^.Expression.Evaluate(self),true);
 if Value<>0 then begin
  if assigned(CurrentSection) then begin
   if (CodePosition mod Value)<>0 then begin
    Value:=Value-(CodePosition mod Value);
    WritePadding(Value);
   end;
  end else begin
   if ((StartOffset+CodePosition) mod Value)<>0 then begin
    Value:=Value-((StartOffset+CodePosition) mod Value);
    WritePadding(Value);
   end;
  end;
 end;
end;

procedure TAssembler.ProcessCPU(Code:PCode);
begin
 CPULevel:=Code^.Value;
end;

procedure TAssembler.ProcessBits(Code:PCode);
var Value:int64;
begin
 Value:=Code^.Value;
 if assigned(Code^.Expression) then begin
  inc(Value,ValueGetInt64(self,Code^.Expression.Evaluate(self),true));
 end;
 case Value of
  16,32,64:begin
   CurrentBits:=Value;
  end;
  else begin
   MakeError(6);
  end;
 end;
end;

procedure TAssembler.ProcessLIBRARY(Code:PCode);
begin
 CurrentLibrary:=Code^.StringData;
end;

procedure TAssembler.ProcessIMPORT(Code:PCode);
begin
 NewImport(Code^.SymbolIndex,CurrentLibrary,Code^.StringData);
end;

procedure TAssembler.ProcessEXPORT(Code:PCode);
begin
 NewExport(Code^.SymbolIndex,Code^.StringData);
end;

procedure TAssembler.ProcessEND(Code:PCode);
begin
 CodeEnd:=CodePosition;
end;

procedure TAssembler.ProcessSMARTLINK(Code:PCode);
begin
 if UserSymbolList[Code^.SymbolIndex].Used then begin
  GeneratePass(Code^.Down);
 end;
end;

procedure TAssembler.ProcessBYTEDIFF(Code:PCode);
var Counter:longint;
    p0,p1:int64;
    Old,New,Temp:byte;
begin
 if CodeImageWriting then begin
  if assigned(CurrentSection) then begin
   p0:=CurrentSection^.Data.Position;
   GeneratePass(Code^.Down);
   p1:=CurrentSection^.Data.Position;
   CurrentSection^.Data.Seek(p0,soBeginning);
   Old:=0;
   for Counter:=p0 to p1-1 do begin
    CurrentSection^.Data.Seek(Counter,soBeginning);
    CurrentSection^.Data.Read(New,SizeOf(byte));
    Temp:=New-Old;
    CurrentSection^.Data.Seek(Counter,soBeginning);
    CurrentSection^.Data.Write(Temp,SizeOf(byte));
    Old:=New;
   end;
   CurrentSection^.Data.Seek(p1,soBeginning);
  end else begin
   p0:=CodeImage.Position;
   GeneratePass(Code^.Down);
   p1:=CodeImage.Position;
   CodeImage.Seek(p0,soBeginning);
   Old:=0;
   for Counter:=p0 to p1-1 do begin
    CodeImage.Seek(Counter,soBeginning);
    CodeImage.Read(New,SizeOf(byte));
    Temp:=New-Old;
    CodeImage.Seek(Counter,soBeginning);
    CodeImage.Write(Temp,SizeOf(byte));
    Old:=New;
   end;                     
   CodeImage.Seek(p1,soBeginning);
  end;
 end else begin
  GeneratePass(Code^.Down);
 end;
end;

procedure TAssembler.ProcessSTRUCTRESET(Code:PCode);
begin
 if (Code^.SymbolIndex>=0) and (Code^.SymbolIndex<UserSymbolList.Count) then begin
  UserSymbolList[Code^.SymbolIndex].Value.ValueType:=AVT_INT;
  IntegerValueSetQWord(UserSymbolList[Code^.SymbolIndex].Value.IntegerValue,0);
 end;
end;

procedure TAssembler.ProcessSTRUCTVAR(Code:PCode);
var ItemSize,Count:TAssemblerValue;
begin
 if (Code^.SymbolIndex>=0) and (Code^.SymbolIndex<UserSymbolList.Count) then begin
  ItemSize.ValueType:=AVT_INT;
  IntegerValueSetInt64(ItemSize.IntegerValue,Code^.ItemSize);
  if (Code^.ItemStructSymbolIndex>=0) and (Code^.ItemStructSymbolIndex<UserSymbolList.Count) then begin
   ItemSize:=ValueOpAdd(self,ItemSize,UserSymbolList[Code^.ItemStructSymbolIndex].Value,true);
  end;
  if (Code^.StructSymbolIndex>=0) and (Code^.StructSymbolIndex<UserSymbolList.Count) then begin
   UserSymbolList[Code^.SymbolIndex].SymbolType:=ustCONSTANTSTRUCT;
   UserSymbolList[Code^.SymbolIndex].Value:=UserSymbolList[Code^.StructSymbolIndex].Value;
   Count.ValueType:=AVT_INT;
   IntegerValueSetInt64(Count.IntegerValue,Code^.Value);
   if assigned(Code^.Expression) then begin
    Count:=ValueOpAdd(self,Count,Code^.Expression.Evaluate(self),true);
   end;
   UserSymbolList[Code^.StructSymbolIndex].Value:=ValueOpAdd(self,UserSymbolList[Code^.StructSymbolIndex].Value,ValueOpMul(self,ItemSize,Count,true),true);
  end;
 end;
end;

procedure TAssembler.ProcessSEGMENT(Code:PCode);
var Value:int64;
begin
 if assigned(Code^.Segment) then begin
  if assigned(CurrentSection) then begin
   MakeError('Segments inside sections not allowed');
   exit;
  end;
  case Target of
   ttMZEXE:begin
    Value:=16;
   end;
{  ttELF32,ttELFX32,ttELF64:begin
    Value:=4096;
   end;{}
   else begin
    MakeError('Segments in this target format not allowed');
    exit;
   end;
  end;
  if Value<>0 then begin
   if assigned(CurrentSection) then begin
    if (CodePosition mod Value)<>0 then begin
     Value:=Value-(CodePosition mod Value);
     WritePadding(Value);
    end;
   end else begin
    if ((StartOffset+CodePosition) mod Value)<>0 then begin
     Value:=Value-((StartOffset+CodePosition) mod Value);
     WritePadding(Value);
    end;
   end;
  end;
  CurrentSegment:=Code^.Segment;
  CurrentSegment^.Position:=CodePosition;
  GeneratePass(Code^.Down);
  CurrentSegment:=nil;
 end;
end;

procedure TAssembler.ProcessSECTION(Code:PCode);
var OldSection:PAssemblerSection;
    OldCodePosition:longint;
begin
 if assigned(Code^.Section) then begin
  if assigned(CurrentSegment) then begin
   MakeError('Sections inside segments not allowed');
   exit;
  end;
  if assigned(CurrentSection) then begin
   MakeError('Nested sections not allowed');
   exit;
  end;
  case Target of
   ttPEEXE32,ttPEEXE64:begin
   end;
   ttCOFFDOS,ttCOFF32,ttCOFF64:begin
   end;
   ttELF32,ttELFX32,ttELF64:begin
   end;
   ttOMF16,ttOMF32:begin
   end;
   else begin
    MakeError('Sections in this target format not allowed');
    exit;
   end;
  end;
  if assigned(Code^.Section^.Flags) then begin
   Code^.Section^.FreezedFlags:=ValueToRawInt(self,Code^.Section^.Flags.Evaluate(self,true),false);
  end else begin
   IntegerValueSetQWord(Code^.Section^.FreezedFlags,0);
  end;
  if assigned(Code^.Section^.Align) then begin
   Code^.Section^.FreezedAlign:=ValueToRawInt(self,Code^.Section^.Align.Evaluate(self,true),false);
  end else begin
   IntegerValueSetQWord(Code^.Section^.FreezedAlign,0);
  end;
  OldSection:=CurrentSection;
  OldCodePosition:=CodePosition;
  CurrentSection:=Code^.Section;
  CodePosition:=CurrentSection^.Position;
  GeneratePass(Code^.Down);
  CurrentSection^.Position:=CodePosition;
  CurrentSection:=OldSection;
  CodePosition:=OldCodePosition;
 end;
end;

procedure TAssembler.ProcessDIRECTORYENTRY(Code:PCode);
var StartPosition,EndPosition:int64;
    Value:TAssemblerValue;
    PECOFFDirectoryEntry:PPECOFFDirectoryEntry;
begin
 if assigned(CurrentSection) then begin
  if assigned(Code^.Expression) then begin
   Value:=Code^.Expression.Evaluate(self,false);
   if Value.ValueType=AVT_INT then begin
    if (IntCompare(Value.IntegerValue,0)>=0) and (IntCompare(Value.IntegerValue,IMAGE_NUMBEROF_DIRECTORY_ENTRIES)<0) then begin
     StartPosition:=CodePosition;
     GeneratePass(Code^.Down);
     EndPosition:=CodePosition;
     PECOFFDirectoryEntry:=@PECOFFDirectoryEntries[Value.IntegerValue[0] and 15];
     PECOFFDirectoryEntry^.Section:=CurrentSection;
     PECOFFDirectoryEntry^.Position:=StartPosition;
     PECOFFDirectoryEntry^.Size:=EndPosition-StartPosition;
    end else begin
     MakeError('Result longint constant value of directory entry expression is out of bound');
    end;
   end else begin
    MakeError('Result of directory entry expression must be a longint content');
   end;
  end else begin
   MakeError('Directory entry expression error');
  end;
 end else begin
  MakeError('Directory entries are allowed inside sections only');
 end;
end;

procedure TAssembler.ProcessSTACK(Code:PCode);
begin
 if assigned(Code^.Expression) then begin
  StackSize:=ValueGetInt64(self,Code^.Expression.Evaluate(self),true);
 end;
end;

procedure TAssembler.ProcessHEAP(Code:PCode);
begin
 if assigned(Code^.Expression) then begin
  HeapSize:=ValueGetInt64(self,Code^.Expression.Evaluate(self),true);
 end;
end;

procedure TAssembler.ProcessCODEBASE(Code:PCode);
begin
 if assigned(Code^.Expression) then begin
  CodeBase:=ValueGetInt64(self,Code^.Expression.Evaluate(self),true);
 end;
end;

procedure TAssembler.ProcessIMAGEBASE(Code:PCode);
begin
 if assigned(Code^.Expression) then begin
  ImageBase:=ValueGetInt64(self,Code^.Expression.Evaluate(self),true);
 end;
end;

procedure TAssembler.ProcessWARNING(Code:PCode);
begin
 if assigned(Code^.Expression) then begin
  MakeWarning(ValueToString(self,Code^.Expression.Evaluate(self),true));
 end;
end;

procedure TAssembler.ProcessERROR(Code:PCode);
begin
 if assigned(Code^.Expression) then begin
  MakeError(ValueToString(self,Code^.Expression.Evaluate(self),true));
 end;
end;

{$ifdef SASMBESEN}
procedure TAssembler.ProcessSCRIPT(Code:PCode);
begin
 try
  BESENInstance.Eval(Code^.StringData);
 except
  on e:Exception do begin
   MakeError(e.Message);
  end;
 end;
end;
{$endif}

procedure TAssembler.ProcessSUBSYSTEM(Code:PCode);
begin
 if assigned(Code^.Expression) then begin
  SubSystem:=ValueGetInt64(self,Code^.Expression.Evaluate(self),true);
 end;
end;

procedure TAssembler.ProcessCHARACTERISTICS(Code:PCode);
begin
 if assigned(Code^.Expression) then begin
  Characteristics:=ValueGetInt64(self,Code^.Expression.Evaluate(self),true);
 end;
end;

procedure TAssembler.ProcessDLLCHARACTERISTICS(Code:PCode);
begin
 if assigned(Code^.Expression) then begin
  DLLCharacteristics:=ValueGetInt64(self,Code^.Expression.Evaluate(self),true);
 end;
end;

procedure TAssembler.ProcessSIZEOFSTACKRESERVE(Code:PCode);
begin
 if assigned(Code^.Expression) then begin
  SizeOfStackReserve:=ValueGetInt64(self,Code^.Expression.Evaluate(self),true);
 end;
end;

procedure TAssembler.ProcessSIZEOFSTACKCOMMIT(Code:PCode);
begin
 if assigned(Code^.Expression) then begin
  SizeOfStackCommit:=ValueGetInt64(self,Code^.Expression.Evaluate(self),true);
 end;
end;

procedure TAssembler.ProcessSIZEOFHEAPRESERVE(Code:PCode);
begin
 if assigned(Code^.Expression) then begin
  SizeOfHeapReserve:=ValueGetInt64(self,Code^.Expression.Evaluate(self),true);
 end;
end;

procedure TAssembler.ProcessSIZEOFHEAPCOMMIT(Code:PCode);
begin
 if assigned(Code^.Expression) then begin
  SizeOfHeapCommit:=ValueGetInt64(self,Code^.Expression.Evaluate(self),true);
 end;
end;

procedure TAssembler.ProcessELFTYPE(Code:PCode);
begin
 if assigned(Code^.Expression) then begin
  ELFType:=ValueGetInt64(self,Code^.Expression.Evaluate(self),true);
 end;
end;

function TAssembler.IntSet(const v:int64):TIntegerValue;
begin
 IntegerValueSetInt64(result,v);
end;

function TAssembler.IntSetUnsigned(const v:uint64):TIntegerValue;
begin
 IntegerValueSetQWord(result,v);
end;

function TAssembler.IntAdd(const a,b:TIntegerValue):TIntegerValue;
begin
 IntegerValueAdd(result,a,b);
end;

function TAssembler.IntAdd(const a:TIntegerValue;const b:TAssemblerValue):TIntegerValue;
begin
 IntegerValueAdd(result,a,ValueToRawInt(self,b,false));
end;

function TAssembler.IntAdd(const a:TIntegerValue;const b:int64):TIntegerValue;
var t:TIntegerValue;
begin
 IntegerValueSetInt64(t,b);
 IntegerValueAdd(result,a,t);
end;

function TAssembler.IntSub(const a,b:TIntegerValue):TIntegerValue;
begin
 IntegerValueSub(result,a,b);
end;

function TAssembler.IntSub(const a:TIntegerValue;const b:TAssemblerValue):TIntegerValue;
begin
 IntegerValueSub(result,a,ValueToRawInt(self,b,false));
end;

function TAssembler.IntSub(const a:TIntegerValue;const b:int64):TIntegerValue;
var t:TIntegerValue;
begin
 IntegerValueSetInt64(t,b);
 IntegerValueSub(result,a,t);
end;

function TAssembler.IntMul(const a,b:TIntegerValue):TIntegerValue;
begin
 IntegerValueMul(result,a,b);
end;

function TAssembler.IntMul(const a:TIntegerValue;const b:TAssemblerValue):TIntegerValue;
begin
 IntegerValueMul(result,a,ValueToRawInt(self,b,false));
end;

function TAssembler.IntMul(const a:TIntegerValue;const b:int64):TIntegerValue;
var t:TIntegerValue;
begin
 IntegerValueSetInt64(t,b);
 IntegerValueMul(result,a,t);
end;

function TAssembler.IntCompare(const a:TIntegerValue;const b:int64):longint;
var t:TIntegerValue;
begin
 IntegerValueSetInt64(t,b);
 result:=IntegerValueCompare(a,t);
end;

procedure TAssembler.PostProcessFixUpExpressions;
var FixUpExpression:PFixUpExpression;
    Value,SubValue{,TempValue}:TIntegerValue;
    Value64:int64;
    Symbol:TUserSymbol;
    Section:PAssemblerSection;
    NeedRelocation:boolean;
begin
 Section:=StartSection;
 while assigned(Section) do begin
  Section^.FixUpExpressions.Clear;
  Section^.RelocationFixUpExpressions.Clear;
  Section:=Section^.Next;
 end;
 FixUpPassBase:=0;
 FixUpPassHere:=0;
 EvaluateHereOffset:=0;
 FixUpExpression:=StartFixUpExpression;
 while assigned(FixUpExpression) do begin
  if (assigned(FixUpExpression^.Section) and (FixUpPass in [FUP_PEEXE,FUP_COFF,FUP_ELF,FUP_OMF])) or
     ((not assigned(FixUpExpression^.Section)) and (FixUpPass in [FUP_BIN,FUP_COM,FUP_MZEXE,FUP_ELF,FUP_TRI])) then begin
   CurrentSection:=FixUpExpression^.Section;
   CurrentLineNumber:=FixUpExpression^.LineNumber;
   CurrentColumn:=FixUpExpression^.Column;
   CurrentSource:=FixUpExpression^.Source;
   if assigned(CurrentSection) then begin
    CurrentSection^.FixUpExpressions.Add(FixUpExpression);
   end;
   if assigned(CurrentSection) or ((CodeEnd<0) or (FixUpExpression^.Position<CodeEnd)) then begin
    if assigned(CurrentSection) then begin
     CurrentSection^.Data.Seek(FixUpExpression^.Position,soBeginning);
     FixUpPassBase:=0;
     FixUpPassHere:=FixUpExpression^.Position+FixUpExpression^.HereOffset;
    end else begin
     CodeImage.Seek(FixUpExpression^.Position,soBeginning);
     FixUpPassBase:=StartOffset;
     FixUpPassHere:=FixUpExpression^.Position+FixUpExpression^.HereOffset+StartOffset;
    end;
    if assigned(FixUpExpression^.Expression) then begin
     FixUpExpression^.Flags:=FixUpExpression^.Flags or FixUpExpression^.Expression.GetFixUpExpressionFlags(self);
    end;
    FixUpPassFlags:=FixUpExpression^.Flags;
    if (FixUpPassFlags and FUEF_RELOCATION)<>0 then begin
     FixUpExpression^.Relocation:=true;
    end;
    NeedRelocation:=false;
    FixUpExpression^.Symbol:=nil;
    if assigned(FixUpExpression^.Expression) then begin
     FillChar(SubValue,SizeOf(TIntegerValue),#0);
     if Target in [ttCOFFDOS,ttCOFF32,ttCOFF64,ttELF32,ttELFX32,ttELF64,ttOMF16,ttOMF32,ttTRI32,ttTRI64] then begin
      Symbol:=FixUpExpression^.Expression.GetFixUpSymbol(self);
      if assigned(Symbol) then begin
       if (Symbol.SymbolType=ustIMPORT) or Symbol.IsPublic or (Symbol.IsExternal and Symbol.Used) then begin
        FixUpExpression^.Symbol:=Symbol;
        Symbol.NeedSymbol:=true;
        NeedRelocation:=true;
       end else if Symbol.SymbolType=ustLABEL then begin
        if (FixUpExpression^.Section<>Symbol.Section) {or (Target in [ttELF32,ttELFX32,ttELF64])} then begin
         FixUpExpression^.Symbol:=Symbol;
         Symbol.NeedSymbol:=true;
         NeedRelocation:=true;
        end else if not FixUpExpression^.Relative then begin
         NeedRelocation:=true;
        end;
       end;
       if (FixUpPassFlags and (FUEF_GOT or FUEF_GOTPC or FUEF_GOTOFF or FUEF_GOTTPOFF or FUEF_PLT or FUEF_TLSIE))<>0 then begin
        FixUpExpression^.Symbol:=Symbol;
        Symbol.NeedSymbol:=true;
        NeedRelocation:=true;
       end;
       if NeedRelocation then begin
        if assigned(FixUpExpression^.Symbol) and not (Target in [ttTRI32,ttTRI64]) then begin
         SubValue:=ValueToRawInt(self,FixUpExpression^.Symbol.GetValue(self),false);
        end;
        FixUpExpression^.Relocation:=true;
       end;
      end;
     end;
     Value:=IntSub(ValueToRawInt(self,FixUpExpression^.Expression.Evaluate(self),false),SubValue);
    end else begin
     IntegerValueSetQWord(Value,0);
    end;
    if FixUpExpression^.Relocation and assigned(CurrentSection) then begin
     CurrentSection^.RelocationFixUpExpressions.Add(FixUpExpression);
    end;
    if FixUpExpression^.Relative then begin
     if FixUpExpression^.Relocation then begin
      case Target of
       ttTRI32,ttTRI64:begin
        Value:=IntSub(Value,FixUpExpression^.Position);
        Value:=IntSub(Value,StartOffset);
        Value:=IntSub(Value,FixUpExpression^.Bits div 8);
       end;
       ttCOFFDOS,ttELF32,ttELFX32,ttELF64,ttOMF16,ttOMF32:begin
        Value:=IntSub(Value,FixUpExpression^.Bits div 8);
       end;
      end;
     end else begin
      Value:=IntSub(Value,FixUpExpression^.Position);
      if assigned(FixUpExpression^.Section) then begin
       Value:=IntSub(Value,FixUpExpression^.Section^.CompleteOffset);
      end else begin
       Value:=IntSub(Value,StartOffset);
      end;
      Value:=IntSub(Value,FixUpExpression^.Bits div 8);
     end;
     Value64:=IntegerValueGetInt64(Value);
     case FixUpExpression^.ManualBoundMode of
      mbmSignedWarning:begin
       if (IntCompare(Value,int64(uint64(FixUpExpression^.MinBound)))<0) or
          (IntCompare(Value,int64(uint64(FixUpExpression^.MaxBound)))>0) then begin
        MakeError(FixUpExpression^.BoundWarningOrError);
       end;
      end;
      mbmSignedError:begin
       if (IntCompare(Value,int64(uint64(FixUpExpression^.MinBound)))<0) or
          (IntCompare(Value,int64(uint64(FixUpExpression^.MaxBound)))>0) then begin
        MakeError(FixUpExpression^.BoundWarningOrError);
       end;
      end;
      mbmByteSignedWarning:begin
       if ((IntegerValueCompare(Value,IntSetUnsigned(uint64(int64(127))))>0) and
           (IntegerValueCompare(Value,IntSetUnsigned(uint64(int64(-128))))<0)) and
          ((IntegerValueCompare(Value,IntSetUnsigned(FixUpExpression^.MinBound))<0) or
           (IntegerValueCompare(Value,IntSetUnsigned(FixUpExpression^.MaxBound))>0)) then begin
        MakeWarning(FixUpExpression^.BoundWarningOrError);
       end;
      end;
      else begin
       case FixUpExpression^.Bits of
        8:begin
         if IntegerValueIs32Bit(Value) then begin
          if (Value64<-128) or (Value64>127) then begin
           if Value64<-128 then begin
            MakeError(41,abs(Value64-(-128)));
           end else if Value64>127 then begin
            MakeError(41,Value64-127);
           end;
          end;
         end else begin
          MakeError('Invalid byte value range');
         end;
        end;
        16:begin
         if IntegerValueIs32Bit(Value) then begin
          if (Value64<-32768) or (Value64>32767) then begin
           if Value64<-32768 then begin
            MakeError(42,abs(Value64-(-32768)));
           end else if Value64>32767 then begin
            MakeError(42,Value64-32767);
           end;
          end;
         end else begin
          MakeError('Invalid word value range');
         end;
        end;
        32:begin
         if IntegerValueIs32Bit(Value) then begin
          if (Value64<(int64(-2147483647)-1)) or (Value64>2147483647) then begin
           if Value64<(int64(-2147483647)-1) then begin
            MakeError(43,abs(Value64-((int64(-2147483647)-1))));
           end else if Value64>32767 then begin
            MakeError(43,Value64-2147483647);
           end;
          end;
         end else begin
          MakeError('Invalid dword value range');
         end;
        end;
        64:begin
         if not IntegerValueIsXBit(Value,64) then begin
          MakeError('Invalid qword value range');
         end;
        end;
        80:begin
         if not IntegerValueIsXBit(Value,80) then begin
          MakeError('Invalid tword value range');
         end;
        end;
        128:begin
         if not IntegerValueIsXBit(Value,128) then begin
          MakeError('Invalid dqword value range');
         end;
        end;
        256:begin
         if not IntegerValueIsXBit(Value,256) then begin
          MakeError('Invalid yword value range');
         end;
        end;
        512:begin
         if not IntegerValueIsXBit(Value,512) then begin
          MakeError('Invalid zword value range');
         end;
        end;
       end;
      end;
     end;
     if assigned(CurrentSection) then begin
      case FixUpExpression^.Bits of
       8:begin
        StreamWriteIntegerValue(CurrentSection^.Data,Value,1);
       end;
       16:begin
        StreamWriteIntegerValue(CurrentSection^.Data,Value,2);
       end;
       32:begin
        StreamWriteIntegerValue(CurrentSection^.Data,Value,4);
       end;
       64:begin
        StreamWriteIntegerValue(CurrentSection^.Data,Value,8);
       end;
       80:begin
        StreamWriteIntegerValue(CurrentSection^.Data,Value,10);
       end;
       128:begin
        StreamWriteIntegerValue(CurrentSection^.Data,Value,16);
       end;
       256:begin
        StreamWriteIntegerValue(CurrentSection^.Data,Value,32);
       end;
       512:begin
        StreamWriteIntegerValue(CurrentSection^.Data,Value,64);
       end;
      end;
     end else begin
      case FixUpExpression^.Bits of
       8:begin
        StreamWriteIntegerValue(CodeImage,Value,1);
       end;
       16:begin
        StreamWriteIntegerValue(CodeImage,Value,2);
       end;
       32:begin
        StreamWriteIntegerValue(CodeImage,Value,4);
       end;
       64:begin
        StreamWriteIntegerValue(CodeImage,Value,8);
       end;
       80:begin
        StreamWriteIntegerValue(CodeImage,Value,10);
       end;
       128:begin
        StreamWriteIntegerValue(CodeImage,Value,16);
       end;
       256:begin
        StreamWriteIntegerValue(CodeImage,Value,32);
       end;
       512:begin
        StreamWriteIntegerValue(CodeImage,Value,64);
       end;
      end;
     end;
    end else begin
     Value64:=IntegerValueGetInt64(Value);
     case FixUpExpression^.ManualBoundMode of
      mbmSignedWarning:begin
       if (IntCompare(Value,int64(uint64(FixUpExpression^.MinBound)))<0) or
          (IntCompare(Value,int64(uint64(FixUpExpression^.MaxBound)))>0) then begin
        MakeError(FixUpExpression^.BoundWarningOrError);
       end;
      end;
      mbmSignedError:begin
       if (IntCompare(Value,int64(uint64(FixUpExpression^.MinBound)))<0) or
          (IntCompare(Value,int64(uint64(FixUpExpression^.MaxBound)))>0) then begin
        MakeError(FixUpExpression^.BoundWarningOrError);
       end;
      end;
      mbmByteSignedWarning:begin
       if ((IntegerValueCompare(Value,IntSetUnsigned(uint64(int64(127))))>0) and
           (IntegerValueCompare(Value,IntSetUnsigned(uint64(int64(-128))))<0)) and
          ((IntegerValueCompare(Value,IntSetUnsigned(FixUpExpression^.MinBound))<0) or
           (IntegerValueCompare(Value,IntSetUnsigned(FixUpExpression^.MaxBound))>0)) then begin
        MakeWarning(FixUpExpression^.BoundWarningOrError);
       end;
      end;
      else begin
       case FixUpExpression^.Bits of
        8:begin
         if IntegerValueIs32Bit(Value) then begin
          if FixUpExpression.Signed<0 then begin
           if Value64<(-$80) then begin
            MakeWarning(0,(-$80)-Value64);
           end else if Value64>$7f then begin
            MakeWarning(0,Value64-$7f);
           end;
          end else if FixUpExpression.Signed>0 then begin
           if Value64<0 then begin
            MakeWarning(0,-Value64);
           end else if Value64>$ff then begin
            MakeWarning(0,Value64-$ff);
           end;
          end else begin
           if (Value64<0) and (Value64>=-$80) then begin
            Value64:=$ff+(Value64+1);
           end;
           if (Value64<0) or (Value64>$ff) then begin
            if Value64<0 then begin
             MakeWarning(0,-Value64);
            end else if Value64>$ff then begin
             MakeWarning(0,Value64-$ff);
            end;
           end;
          end;
         end else begin
          MakeWarning('Invalid byte value range');
         end;
        end;
        16:begin
         if IntegerValueIs32Bit(Value) then begin
          if FixUpExpression.Signed<0 then begin
           if Value64<(-$8000) then begin
            MakeWarning(1,(-$8000)-Value64);
           end else if Value64>$7fff then begin
            MakeWarning(1,Value64-$7fff);
           end;
          end else if FixUpExpression.Signed>0 then begin
           if Value64<0 then begin
            MakeWarning(1,-Value64);
           end else if Value64>$ffff then begin
            MakeWarning(1,Value64-$ffff);
           end;
          end else begin
           if (Value64<0) and (Value64>=-$8000) then begin
            Value64:=$ffff+(Value64+1);
           end;
           if (Value64<0) or (Value64>$ffff) then begin
            if Value64<0 then begin
             MakeWarning(1,-Value64);
            end else if Value64>$ffff then begin
             MakeWarning(1,Value64-$ffff);
            end;
           end;
          end;
         end else begin
          MakeWarning('Invalid word value range');
         end;
        end;
        32:begin
         if IntegerValueIs32Bit(Value) then begin
          if FixUpExpression.Signed<0 then begin
           if Value64<(-int64($80000000)) then begin
            MakeWarning(2,(-int64($80000000))-Value64);
           end else if Value64>int64($7fffffff) then begin
            MakeWarning(2,Value64-int64($7fffffff));
           end;
          end else if FixUpExpression.Signed>0 then begin
           if Value64<0 then begin
            MakeWarning(2,-Value64);
           end else if Value64>int64($ffffffff) then begin
            MakeWarning(2,Value64-int64($ffffffff));
           end;
          end else begin
           if (Value64<0) and (Value64>=-(int64($7fffffff)+1)) then begin
            Value64:=$ffffffff+(Value64+1);
           end;
           if (Value64<0) or (Value64>$ffffffff) then begin
            if Value64<0 then begin
             MakeWarning(2,-Value64);
            end else if Value64>$ffffffff then begin
             MakeWarning(2,Value64-$ffffffff);
            end;
           end;
          end;
         end else begin
          MakeWarning('Invalid dword value range');
         end;
        end;
        64:begin
         if not IntegerValueIsXBit(Value,64) then begin
          MakeWarning('Invalid qword value range');
         end;
        end;
        80:begin
         if not IntegerValueIsXBit(Value,80) then begin
          MakeWarning('Invalid tword value range');
         end;
        end;
        128:begin
         if not IntegerValueIsXBit(Value,128) then begin
          MakeWarning('Invalid dqword value range');
         end;
        end;
        256:begin
         if not IntegerValueIsXBit(Value,256) then begin
          MakeWarning('Invalid yword value range');
         end;
        end;
        512:begin
         if not IntegerValueIsXBit(Value,512) then begin
          MakeWarning('Invalid zword value range');
         end;
        end;
       end;
      end;
     end;
     if assigned(CurrentSection) then begin
      case FixUpExpression^.Bits of
       8:begin
        StreamWriteIntegerValue(CurrentSection^.Data,Value,1);
       end;
       16:begin
        StreamWriteIntegerValue(CurrentSection^.Data,Value,2);
       end;
       32:begin
        StreamWriteIntegerValue(CurrentSection^.Data,Value,4);
       end;
       64:begin
        StreamWriteIntegerValue(CurrentSection^.Data,Value,8);
       end;
       80:begin
        StreamWriteIntegerValue(CurrentSection^.Data,Value,10);
       end;
       128:begin
        StreamWriteIntegerValue(CurrentSection^.Data,Value,16);
       end;
       256:begin
        StreamWriteIntegerValue(CurrentSection^.Data,Value,32);
       end;
       512:begin
        StreamWriteIntegerValue(CurrentSection^.Data,Value,64);
       end;
      end;
     end else begin
      case FixUpExpression^.Bits of
       8:begin
        StreamWriteIntegerValue(CodeImage,Value,1);
       end;
       16:begin
        StreamWriteIntegerValue(CodeImage,Value,2);
       end;
       32:begin
        StreamWriteIntegerValue(CodeImage,Value,4);
       end;
       64:begin
        StreamWriteIntegerValue(CodeImage,Value,8);
       end;
       80:begin
        StreamWriteIntegerValue(CodeImage,Value,10);
       end;
       128:begin
        StreamWriteIntegerValue(CodeImage,Value,16);
       end;
       256:begin
        StreamWriteIntegerValue(CodeImage,Value,32);
       end;
       512:begin
        StreamWriteIntegerValue(CodeImage,Value,64);
       end;
      end;
     end;
    end;
   end else begin
    MakeWarning(4);
   end;
  end;
  FixUpExpression:=FixUpExpression^.Next;
 end;
 CodeImage.Seek(CodeImage.Size,soBeginning);
end;

procedure TAssembler.PostProcessSymbols;
var Counter:longint;
    Symbol:TUserSymbol;
begin
 CountOutputSymbols:=0;
 for Counter:=0 to UserSymbolList.Count-1 do begin
  Symbol:=UserSymbolList[Counter];
  if Symbol.IsPublic or (Symbol.IsExternal and Symbol.Used) then begin
   Symbol.NeedSymbol:=true;
  end;
  if Symbol.NeedSymbol then begin
   Symbol.SymbolIndex:=CountOutputSymbols;
   inc(CountOutputSymbols);
  end else begin
   Symbol.SymbolIndex:=-1;
  end;
 end;
end;

procedure TAssembler.GeneratePass(StartCode:PCode);
var Code:PCode;
    Count,OldRepeatCounter:int64;
begin
 Code:=StartCode;
 while assigned(Code) do begin
{$ifdef DEBUGGER}
  Code^.BytePosition:=CodePosition;
{$endif}
  case Code^.CodeItemType of
   tcitREPEAT:begin
    if assigned(Code^.Expression) then begin
     OldRepeatCounter:=RepeatCounter;
     RepeatCounter:=0;
     Count:=ValueGetInt64(self,Code^.Expression.Evaluate(self),false);
     while (Count>0) and not AreErrors do begin
      GeneratePass(Code^.Down);
      inc(RepeatCounter);
      dec(Count);
     end;
     RepeatCounter:=OldRepeatCounter;
    end;
   end;
   tcitWHILE:begin
    if assigned(Code^.Expression) then begin
     OldRepeatCounter:=RepeatCounter;
     RepeatCounter:=0;
     while (ValueGetInt64(self,Code^.Expression.Evaluate(self),false)<>0) and not AreErrors do begin
      GeneratePass(Code^.Down);
      inc(RepeatCounter);
     end;
     RepeatCounter:=OldRepeatCounter;
    end;
   end;
   tcitIF:begin
    if assigned(Code^.Expression) then begin
     if ValueGetInt64(self,Code^.Expression.Evaluate(self,true),false)<>0 then begin
      GeneratePass(Code^.Down);
     end else begin
      GeneratePass(Code^.ElseDown);
     end;
    end;
   end;
   else begin
    GenerateCode(Code);
   end;
  end;
  Code:=Code^.Next;
 end;
end;

procedure TAssembler.GenerateCode(Code:PCode); register;
begin
 CurrentLineNumber:=Code^.LineNumber;
 CurrentColumn:=Code^.Column;
 CurrentSource:=Code^.Source;
 case Code^.CodeItemType of
  tcitInstruction:ProcessInstruction(Code);
  tcitLabel:ProcessLabel(Code^.SymbolIndex);
  tcitConstant:ProcessConstant(Code);
  tcitTimes:ProcessTimes(Code);
  tcitData:ProcessData(Code);
  tcitDataRawString:ProcessDataRawString(Code);
  tcitDataEmpty:ProcessDataEmpty(Code);
  tcitENTRYPOINT:ProcessENTRYPOINT;
  tcitOFFSET:ProcessOFFSET(Code);
  tcitSTARTOFFSET:ProcessSTARTOFFSET(Code);
  tcitALIGN:ProcessALIGN(Code);
  tcitCPU:ProcessCPU(Code);
  tcitBITS:ProcessBits(Code);
  tcitLIBRARY:ProcessLIBRARY(Code);
  tcitIMPORT:ProcessIMPORT(Code);
  tcitEXPORT:ProcessEXPORT(Code);
  tcitEND:ProcessEND(Code);
  tcitSMARTLINK:ProcessSMARTLINK(Code);
  tcitBYTEDIFF:ProcessBYTEDIFF(Code);
  tcitSTRUCTRESET:ProcessSTRUCTRESET(Code);
  tcitSTRUCTVAR:ProcessSTRUCTVAR(Code);
  tcitUSERENTRYPOINT:ProcessUSERENTRYPOINT;
  tcitSEGMENT:ProcessSEGMENT(Code);
  tcitSECTION:ProcessSECTION(Code);
  tcitDIRECTORYENTRY:ProcessDIRECTORYENTRY(Code);
  tcitSTACK:ProcessSTACK(Code);
  tcitHEAP:ProcessHEAP(Code);
  tcitCODEBASE:ProcessCODEBASE(Code);
  tcitIMAGEBASE:ProcessIMAGEBASE(Code);
  tcitWARNING:ProcessWARNING(Code);
  tcitERROR:ProcessERROR(Code);
{$ifdef SASMBESEN}
  tcitSCRIPT:ProcessSCRIPT(Code);
{$endif}
  tcitSUBSYSTEM:ProcessSUBSYSTEM(Code);
  tcitCHARACTERISTICS:ProcessCHARACTERISTICS(Code);
  tcitDLLCHARACTERISTICS:ProcessDLLCHARACTERISTICS(Code);
  tcitSIZEOFSTACKRESERVE:ProcessSIZEOFSTACKRESERVE(Code);
  tcitSIZEOFSTACKCOMMIT:ProcessSIZEOFSTACKCOMMIT(Code);
  tcitSIZEOFHEAPRESERVE:ProcessSIZEOFHEAPRESERVE(Code);
  tcitSIZEOFHEAPCOMMIT:ProcessSIZEOFHEAPCOMMIT(Code);
  tcitELFTYPE:ProcessELFType(Code);
 end;
end;

function TAssembler.PrepareCode(StartCode:PCode):longint; register;
var Code:PCode;
    OperandCounter,SymbolIndex:longint;
    Symbol:TUserSymbol;
 procedure CheckPasses(var Passes:longint;RequirePasses:longint);
 begin
  if Passes<RequirePasses then Passes:=RequirePasses;
 end;
begin
 result:=4;
 Code:=StartCode;
 while assigned(Code) do begin
  case Code^.CodeItemType of
   tcitInstruction:begin
    case Code^.Instruction.Opcode of
     OpJA,OpJAE,OpJB,OpJBE,OpJC,OpJCXZ,OpJE,OpJECXZ,OpJG,OpJGE,OpJL,OpJLE,OpJMP,
     OpJNA,OpJNAE,OpJNB,OpJNBE,OpJNC,OpJNE,OpJNG,OpJNGE,OpJNL,OpJNLE,OpJNO,OpJNP,
     OpJNS,OpJNZ,OpJO,OpJP,OpJPE,OpJPO,OpJS,OpJZ:begin
      if OptimizationLevel>0 then begin
       CheckPasses(result,8);
      end else begin
       CheckPasses(result,4);
      end;
     end;
    end;
    for OperandCounter:=1 to Code^.Instruction.CountOperands do begin
     if assigned(Code^.Instruction.Operand[OperandCounter].Value) and
        Code^.Instruction.Operand[OperandCounter].Value.HasFixUpSymbolReference(self) then begin
      CheckPasses(result,8);
     end;
    end;
   end;
   tcitTimes,tcitData,tcitDataRawString,tcitDataEmpty:begin
    SymbolIndex:=Code^.SymbolIndex;
    if (SymbolIndex>=0) and (SymbolIndex<UserSymbolList.Count) then begin
     Symbol:=UserSymbolList[SymbolIndex];
     Symbol.UseIt(self);
     CheckPasses(result,4);
    end;
    if assigned(Code^.Expression) then begin
     Code^.Expression.UseIt(self);
     if Code^.Expression.HasOperation(['v']) then begin
      CheckPasses(result,4);
     end;
    end;
   end;
   tcitConstant,tcitIF,tcitWHILE,tcitREPEAT:begin
    CheckPasses(result,8);
   end;
   tcitSMARTLINK:begin
    CheckPasses(result,8);
   enD;
   tcitLIBRARY,tcitIMPORT,tcitEXPORT:begin
    CheckPasses(result,4);
   end;
   tcitBYTEDIFF:begin
    CheckPasses(result,4);
   end;
   tcitSTRUCTRESET,tcitSTRUCTVAR:begin
    CheckPasses(result,4);
   end;
  end;
  if assigned(Code^.Expression) then begin
   CheckPasses(result,8);
  end;
  CheckPasses(result,PrepareCode(Code^.Down));
  CheckPasses(result,PrepareCode(Code^.ElseDown));
  Code:=Code^.Next;
 end;
 if Target<>ttBIN then begin
  CheckPasses(result,4);
 end;
end;

function TAssembler.OptimizeCode(BeginBlock,EndBlock:PCode):boolean; register;
begin
 result:=false;
end;

procedure TAssembler.InsertImportByHashSymbols;
var SymbolName:ansistring;
    SymbolType:TSymbolTreeLinkType;
    SymbolValue:TSymbolTreeLink;
    Index:longint;
begin
 SymbolName:=ImportByHashTableLabelSymbolName;
 if not UserSymbolTree.Find(SymbolName,SymbolType,SymbolValue) then begin
  UserSymbolList.NewClass(Index,SymbolName,SymbolName);
  UserSymbolTree.Add(SymbolName,stUSER,index);
  SymbolType:=stUSER;
  SymbolValue:=Index;
  UserSymbolList[SymbolValue].SymbolType:=ustLABEL;
 end;
 SymbolName:=ImportByHashLoadLibraryASymbolName;
 if not UserSymbolTree.Find(SymbolName,SymbolType,SymbolValue) then begin
  UserSymbolList.NewClass(index,SymbolName,SymbolName);
  UserSymbolTree.Add(SymbolName,stUSER,index);
  SymbolType:=stUSER;
  SymbolValue:=index;
  UserSymbolList[SymbolValue].SymbolType:=ustIMPORT;
 end;
 SymbolName:=ImportByHashUseImportByName;
 if not UserSymbolTree.Find(SymbolName,SymbolType,SymbolValue) then begin
  UserSymbolList.NewClass(index,SymbolName,SymbolName);
  UserSymbolTree.Add(SymbolName,stUSER,index);
  SymbolType:=stUSER;
  SymbolValue:=index;
  UserSymbolList[SymbolValue].SymbolType:=ustVARIABLE;
  UserSymbolList[SymbolValue].Value.ValueType:=AVT_INT;
  IntegerValueSetQWOrd(UserSymbolList[SymbolValue].Value.IntegerValue,ord((Target in [ttPEEXE32]) and (ImportType=titHASHIBN)));
 end;
 SymbolName:=ImportByHashUsePEB;
 if not UserSymbolTree.Find(SymbolName,SymbolType,SymbolValue) then begin
  UserSymbolList.NewClass(index,SymbolName,SymbolName);
  UserSymbolTree.Add(SymbolName,stUSER,index);
  SymbolType:=stUSER;
  SymbolValue:=index;
  UserSymbolList[SymbolValue].SymbolType:=ustVARIABLE;
  UserSymbolList[SymbolValue].Value.ValueType:=AVT_INT;
  IntegerValueSetQWOrd(UserSymbolList[SymbolValue].Value.IntegerValue,ord((Target in [ttPEEXE32]) and (ImportType=titHASHPEB)));
 end;
 SymbolName:=ImportByHashUseSEH;
 if not UserSymbolTree.Find(SymbolName,SymbolType,SymbolValue) then begin
  UserSymbolList.NewClass(index,SymbolName,SymbolName);
  UserSymbolTree.Add(SymbolName,stUSER,index);
  SymbolType:=stUSER;
  SymbolValue:=index;
  UserSymbolList[SymbolValue].SymbolType:=ustVARIABLE;
  UserSymbolList[SymbolValue].Value.ValueType:=AVT_INT;
  IntegerValueSetQWOrd(UserSymbolList[SymbolValue].Value.IntegerValue,ord((Target in [ttPEEXE32]) and (ImportType=titHASHSEH)));
 end;
 SymbolName:=ImportByHashUseTOPSTACK;
 if not UserSymbolTree.Find(SymbolName,SymbolType,SymbolValue) then begin
  UserSymbolList.NewClass(index,SymbolName,SymbolName);
  UserSymbolTree.Add(SymbolName,stUSER,index);
  SymbolType:=stUSER;
  SymbolValue:=index;
  UserSymbolList[SymbolValue].SymbolType:=ustVARIABLE;
  UserSymbolList[SymbolValue].Value.ValueType:=AVT_INT;
  IntegerValueSetQWOrd(UserSymbolList[SymbolValue].Value.IntegerValue,ord((Target in [ttPEEXE32]) and (ImportType=titHASHTOPSTACK)));
 end;
 SymbolName:=ImportByHashSafe;
 if not UserSymbolTree.Find(SymbolName,SymbolType,SymbolValue) then begin
  UserSymbolList.NewClass(index,SymbolName,SymbolName);
  UserSymbolTree.Add(SymbolName,stUSER,index);
  SymbolType:=stUSER;
  SymbolValue:=index;
  UserSymbolList[SymbolValue].SymbolType:=ustVARIABLE;
  UserSymbolList[SymbolValue].Value.ValueType:=AVT_INT;
  IntegerValueSetQWOrd(UserSymbolList[SymbolValue].Value.IntegerValue,ord(IBHSafe));
 end;
end;

function TAssembler.Generate:boolean;
var Pass,Passes:longint;
 procedure WriteImports;
 var i:longint;
     ImportItem:TAssemblerImportItem;
     ImportLibraryItem:TAssemblerImportLibraryItem;
{$undef HasGetProcAddress}
{$if defined(Win32) or defined(Win64)}
 {$define HasGetProcAddress}
{$ifend}
{$ifdef UNIX}
 {$define HasGetProcAddress}
{$endif}
{$ifdef HasGetProcAddress}
     Address:pointer;
{$endif}
 begin
  for i:=0 to ImportList.Count-1 do begin
   ImportItem:=ImportList.Items[i];
   if not assigned(ImportItem.ImportLibrary) then begin
    continue;
   end;
   ImportLibraryItem:=ImportItem.ImportLibrary;
   if CodeImageWriting and (ImportLibraryItem.Handle=0) then begin
{$if defined(Win32) or defined(Win64)}
    ImportLibraryItem.Handle:=GetModuleHandleA(pansichar(ImportLibraryItem.Name));
    if ImportLibraryItem.Handle=0 then begin
     ImportLibraryItem.Handle:=LoadLibraryA(pansichar(ImportLibraryItem.Name));
    end;
{$else}
{$ifdef UNIX}
    ImportLibraryItem.Handle:=LoadLibrary(pansichar(ImportLibraryItem.Name));
{$else}
    continue;
{$endif}
{$ifend}
   end;
{$ifdef HasGetProcAddress}
   if CodeImageWriting then begin
    Address:=GetProcAddress(ImportLibraryItem.Handle,pansichar(ImportItem.Name));
   end else begin
    Address:=nil;
   end;
   ImportItem.ProcAddr:=TSASMPtrUInt(TSASMPtrUInt(RuntimeCodeImage)+TSASMPtrUInt(CodePosition));
   if CodeImageWriting then begin
    CodeImage.Write(Address,SizeOf(pointer));
   end;
   inc(CodePosition,SizeOf(pointer));
   if assigned(ImportItem.Symbol) then begin
    ImportItem.Symbol.Section:=CurrentSection;
    ImportItem.Symbol.Position:=ImportItem.ProcAddr;
    ImportItem.Symbol.HasPosition:=true;
   end;
{$else}
   Address:=nil;
{$endif}
{$undef HasGetProcAddress}
  end;
 end;
 procedure WritePECOFFImportTable;
 var Pass,Counter,SubCounter,Used:longint;
     Stream:TMemoryStream;
     ImportItem:TAssemblerImportItem;
     ImportLibraryItem:TAssemblerImportLibraryItem;
     DLLLoader:TDLLLoader;
     ExportTreeLink:TExportTreeLink;
     First:boolean;
     FixUpExpression:PFixUpExpression;
     OldStartOffset:int64;
 begin
  for SubCounter:=0 to ImportList.Count-1 do begin
   ImportItem:=ImportList.Items[SubCounter];
   if assigned(ImportItem.Symbol) then begin
    if ImportItem.Symbol.Used then begin
     ImportItem.Used:=true;
     ImportLibraryItem:=ImportItem.ImportLibrary;
     if assigned(ImportLibraryItem) then begin
      ImportLibraryItem.Used:=true;
     end;
    end;
   end;
  end;
  OldStartOffset:=StartOffset;
  if assigned(CurrentSection) then begin
   StartOffset:=0;
  end;
  begin
   DLLLoader:=nil;
   Stream:=TMemoryStream.Create;
   for Pass:=1 to 2 do begin
    Stream.Clear;
    Used:=0;
    for Counter:=0 to ImportLibraryList.Count-1 do begin
     ImportLibraryItem:=ImportLibraryList.Items[Counter];
     if ImportLibraryItem.Used then begin
      begin
       if (Pass>1) and CodeImageWriting then begin
        FixUpExpression:=NewFixUpExpression;
        FixUpExpression^.Section:=CurrentSection;
        FixUpExpression^.Position:=CodePosition+Stream.Position;
        FixUpExpression^.Expression:=TAssemblerExpression.Create;
        FixUpExpression^.Expression.Operation:='+';
        FixUpExpression^.Expression.Left:=TAssemblerExpression.Create;
        FixUpExpression^.Expression.Left.Operation:='R';
        FixUpExpression^.Expression.Left.MetaValue:=0;
        FixUpExpression^.Expression.Left.MetaFlags:=0;
        FixUpExpression^.Expression.Right:=TAssemblerExpression.Create;
        FixUpExpression^.Expression.Right.Operation:='x';
        FixUpExpression^.Expression.Right.Value.ValueType:=AVT_INT;
        IntegerValueSetQWord(FixUpExpression^.Expression.Right.Value.IntegerValue,ImportLibraryItem.OrgImportsAddr);
        FixUpExpression^.Bits:=32;
        FixUpExpression^.Relative:=false;
        FixUpExpression^.Relocation:=true;
        FixUpExpression^.LineNumber:=0;
        FixUpExpression^.Column:=0;
        FixUpExpression^.Source:=0;
       end;
       StreamWriteDWord(Stream,0);
      end;{}
//    StreamWriteDWord(Stream,0);
      StreamWriteDWord(Stream,0);
      StreamWriteDWord(Stream,$ffffffff); //StreamWriteDWord(Stream,0);     
      if (Pass>1) and CodeImageWriting then begin

       FixUpExpression:=NewFixUpExpression;
       FixUpExpression^.Section:=CurrentSection;
       FixUpExpression^.Position:=CodePosition+Stream.Position;
       FixUpExpression^.Expression:=TAssemblerExpression.Create;
       FixUpExpression^.Expression.Operation:='+';
       FixUpExpression^.Expression.Left:=TAssemblerExpression.Create;
       FixUpExpression^.Expression.Left.Operation:='R';
       FixUpExpression^.Expression.Left.MetaValue:=0;
       FixUpExpression^.Expression.Left.MetaFlags:=0;
       FixUpExpression^.Expression.Right:=TAssemblerExpression.Create;
       FixUpExpression^.Expression.Right.Operation:='x';
       FixUpExpression^.Expression.Right.Value.ValueType:=AVT_INT;
       IntegerValueSetQWord(FixUpExpression^.Expression.Right.Value.IntegerValue,ImportLibraryItem.NameAddr);
       FixUpExpression^.Bits:=32;
       FixUpExpression^.Relative:=false;
       FixUpExpression^.Relocation:=true;
       FixUpExpression^.LineNumber:=0;
       FixUpExpression^.Column:=0;
       FixUpExpression^.Source:=0;
       StreamWriteDWord(Stream,0);

       FixUpExpression:=NewFixUpExpression;
       FixUpExpression^.Section:=CurrentSection;
       FixUpExpression^.Position:=CodePosition+Stream.Position;
       FixUpExpression^.Expression:=TAssemblerExpression.Create;
       FixUpExpression^.Expression.Operation:='+';
       FixUpExpression^.Expression.Left:=TAssemblerExpression.Create;
       FixUpExpression^.Expression.Left.Operation:='R';
       FixUpExpression^.Expression.Left.MetaValue:=0;
       FixUpExpression^.Expression.Left.MetaFlags:=0;
       FixUpExpression^.Expression.Right:=TAssemblerExpression.Create;
       FixUpExpression^.Expression.Right.Operation:='x';
       FixUpExpression^.Expression.Right.Value.ValueType:=AVT_INT;
       IntegerValueSetQWord(FixUpExpression^.Expression.Right.Value.IntegerValue,ImportLibraryItem.ImportsAddr);
       FixUpExpression^.Bits:=32;
       FixUpExpression^.Relative:=false;
       FixUpExpression^.Relocation:=true;
       FixUpExpression^.LineNumber:=0;
       FixUpExpression^.Column:=0;
       FixUpExpression^.Source:=0;
       StreamWriteDWord(Stream,0);

      end else begin
       StreamWriteDWord(Stream,ImportLibraryItem.NameAddr);
       StreamWriteDWord(Stream,ImportLibraryItem.ImportsAddr);
      end;
      inc(Used);
     end;
    end;
    if Used>0 then begin
     for Counter:=1 to 5 do begin
      StreamWriteDWord(Stream,0);
     end;
    end;
    for Counter:=0 to ImportLibraryList.Count-1 do begin
     ImportLibraryItem:=ImportLibraryList.Item[Counter];
     if ImportLibraryItem.Used then begin
      ImportLibraryItem.NameAddr:=CodePosition+Stream.Position;
      StreamWriteString(Stream,ImportLibraryItem.Name+#0);

      if ImportType=titORDINAL then begin
       DLLLoader:=TDLLLoader.Create;
       DLLLoader.LoadFile(ImportLibraryItem.Name);
      end;

{}    begin
       ImportLibraryItem.OrgImportsAddr:=CodePosition+Stream.Position;
       for SubCounter:=0 to ImportList.Count-1 do begin
        ImportItem:=ImportList.Items[SubCounter];
        if (ImportItem.ImportLibrary=ImportLibraryItem) and ImportItem.Used then begin
         if Target in ObjectTargets then begin
          ImportItem.ProcAddr:=CodePosition+Stream.Position;
         end else begin
          ImportItem.ProcAddr:=StartOffset+CodePosition+Stream.Position;
         end;
         if assigned(ImportItem.Symbol) then begin
          ImportItem.Symbol.Section:=CurrentSection;
          ImportItem.Symbol.Position:=ImportItem.ProcAddr;
          ImportItem.Symbol.HasPosition:=true;
         end;
         if (Pass>1) and CodeImageWriting then begin
          FixUpExpression:=NewFixUpExpression;
          FixUpExpression^.Section:=CurrentSection;
          FixUpExpression^.Position:=CodePosition+Stream.Position;
          FixUpExpression^.Expression:=TAssemblerExpression.Create;
          FixUpExpression^.Expression.Operation:='+';
          FixUpExpression^.Expression.Left:=TAssemblerExpression.Create;
          FixUpExpression^.Expression.Left.Operation:='R';
          FixUpExpression^.Expression.Left.MetaValue:=0;
          FixUpExpression^.Expression.Left.MetaFlags:=0;
          FixUpExpression^.Expression.Right:=TAssemblerExpression.Create;
          FixUpExpression^.Expression.Right.Operation:='x';
          FixUpExpression^.Expression.Right.Value.ValueType:=AVT_INT;
          IntegerValueSetQWord(FixUpExpression^.Expression.Right.Value.IntegerValue,ImportItem.NameAddr);
          if Target=ttPEEXE64 then begin
           FixUpExpression^.Bits:=64;
          end else begin
           FixUpExpression^.Bits:=32;
          end;
          FixUpExpression^.Relative:=false;
          FixUpExpression^.Relocation:=true;
          FixUpExpression^.LineNumber:=0;
          FixUpExpression^.Column:=0;
          FixUpExpression^.Source:=0;
          if Target=ttPEEXE64 then begin
           StreamWriteQWord(Stream,0);
          end else begin
           StreamWriteDWord(Stream,0);
          end;
         end else begin
          if Target=ttPEEXE64 then begin
           StreamWriteQWord(Stream,ImportItem.NameAddr);
          end else begin
           StreamWriteDWord(Stream,ImportItem.NameAddr);
          end;
         end;
        end;
       end;
       if Target=ttPEEXE64 then begin
        StreamWriteQWord(Stream,0);
       end else begin
        StreamWriteDWord(Stream,0);
       end;
(*    end else{}begin
       ImportLibraryItem.OrgImportsAddr:=0;(**)
      end;

      ImportLibraryItem.ImportsAddr:=CodePosition+Stream.Position;
      for SubCounter:=0 to ImportList.Count-1 do begin
       ImportItem:=ImportList.Items[SubCounter];
       if (ImportItem.ImportLibrary=ImportLibraryItem) and ImportItem.Used then begin
        if Target in ObjectTargets then begin
         ImportItem.ProcAddr:=CodePosition+Stream.Position;
        end else begin
         ImportItem.ProcAddr:=StartOffset+CodePosition+Stream.Position;
        end;
        if assigned(ImportItem.Symbol) then begin
         ImportItem.Symbol.Section:=CurrentSection;
         ImportItem.Symbol.Position:=ImportItem.ProcAddr;
         ImportItem.Symbol.HasPosition:=true;
        end;
        if (Pass>1) and CodeImageWriting then begin
         FixUpExpression:=NewFixUpExpression;
         FixUpExpression^.Section:=CurrentSection;
         FixUpExpression^.Position:=CodePosition+Stream.Position;
         FixUpExpression^.Expression:=TAssemblerExpression.Create;
         FixUpExpression^.Expression.Operation:='+';
         FixUpExpression^.Expression.Left:=TAssemblerExpression.Create;
         FixUpExpression^.Expression.Left.Operation:='R';
         FixUpExpression^.Expression.Left.MetaValue:=0;
         FixUpExpression^.Expression.Left.MetaFlags:=0;
         FixUpExpression^.Expression.Right:=TAssemblerExpression.Create;
         FixUpExpression^.Expression.Right.Operation:='x';
         FixUpExpression^.Expression.Right.Value.ValueType:=AVT_INT;
         IntegerValueSetQWord(FixUpExpression^.Expression.Right.Value.IntegerValue,ImportItem.NameAddr);
         if Target=ttPEEXE64 then begin
          FixUpExpression^.Bits:=64;
         end else begin
          FixUpExpression^.Bits:=32;
         end;
         FixUpExpression^.Relative:=false;
         FixUpExpression^.Relocation:=true;
         FixUpExpression^.LineNumber:=0;
         FixUpExpression^.Column:=0;
         FixUpExpression^.Source:=0;
         if Target=ttPEEXE64 then begin
          StreamWriteQWord(Stream,0);
         end else begin
          StreamWriteDWord(Stream,0);
         end;
        end else begin
         if Target=ttPEEXE64 then begin
          StreamWriteQWord(Stream,ImportItem.NameAddr);
         end else begin
          StreamWriteDWord(Stream,ImportItem.NameAddr);
         end;
        end;
       end;
      end;
      if Target=ttPEEXE64 then begin
       StreamWriteQWord(Stream,0);
      end else begin
       StreamWriteDWord(Stream,0);
      end;

      First:=true;
      for SubCounter:=0 to ImportList.Count-1 do begin
       ImportItem:=ImportList.Items[SubCounter];
       if (ImportItem.ImportLibrary=ImportLibraryItem) and ImportItem.Used then begin
        ImportItem.NameAddr:=CodePosition+Stream.Position;
        if ImportType=titORDINAL then begin
         ExportTreeLink:=DLLLoader.FindExport(ImportItem.Name);
         if ExportTreeLink.OrdinalIndex>=0 then begin
          if Target=ttPEEXE64 then begin
           ImportItem.NameAddr:=uint64(ExportTreeLink.OrdinalIndex) or IMAGE_ORDINAL_FLAG64;
          end else begin
           ImportItem.NameAddr:=longword(ExportTreeLink.OrdinalIndex) or IMAGE_ORDINAL_FLAG32;
          end;
         end else begin
          if First then begin
           dec(ImportItem.NameAddr,SizeOf(word));
          end else begin
           StreamWriteWord(Stream,0);
          end;
          StreamWriteString(Stream,ImportItem.Name+#0);
         end;
        end else begin
         if First then begin
          dec(ImportItem.NameAddr,SizeOf(word));
         end else begin
          StreamWriteWord(Stream,0);
         end;
         StreamWriteString(Stream,ImportItem.Name+#0);
        end;
        First:=false;
       end;
      end;
      if ImportType=titORDINAL then begin
       DLLLoader.Destroy;
      end;
     end;
    end;
   end;
   if CodeImageWriting then begin
    if assigned(CurrentSection) then begin
     CurrentSection^.Data.Seek(CurrentSection^.Data.Size,soBeginning);
     Stream.Seek(0,soBeginning);
     CurrentSection^.Data.CopyFrom(Stream,Stream.Size);
     Stream.Seek(Stream.Size,soBeginning);
    end else begin
     CodeImage.Seek(CodeImage.Size,soBeginning);
     Stream.Seek(0,soBeginning);
     CodeImage.CopyFrom(Stream,Stream.Size);
     Stream.Seek(Stream.Size,soBeginning);
    end;
   end;
   inc(CodePosition,Stream.Size);
   Stream.Free;
  end;
  if assigned(CurrentSection) then begin
   StartOffset:=OldStartOffset;
  end;
 end;
 procedure WritePECOFFExportTable;
 var Stream:TMemoryStream;
     Counter,Pass,Value,AddressOfName,AddressOfFunctions,AddressOfNames,
     AddressOfOrdinals,Count:longint;
     OldStartOffset:int64;
     Symbol:TUserSymbol;
 begin
  if ExportList.Count>0 then begin
   OldStartOffset:=StartOffset;
   if assigned(CurrentSection) then begin
    StartOffset:=0;
   end;
   Count:=0;
   for Counter:=0 to ExportList.Count-1 do begin
    Symbol:=ExportList[Counter].Symbol;
    if assigned(Symbol) and assigned(Symbol.Section) then begin
     inc(Count);
    end;
   end;
   Stream:=TMemoryStream.Create;
   try
    AddressOfName:=0;
    AddressOfFunctions:=0;
    AddressOfNames:=0;
    AddressOfOrdinals:=0;
    for Pass:=1 to 2 do begin
     Stream.Clear;
     StreamWriteDWord(Stream,0);
     StreamWriteDWord(Stream,0);
     StreamWriteWord(Stream,0);
     StreamWriteWord(Stream,0);
     StreamWriteDWord(Stream,AddressOfName);
     StreamWriteDWord(Stream,1);
     StreamWriteDWord(Stream,Count);
     StreamWriteDWord(Stream,Count);
     StreamWriteDWord(Stream,AddressOfFunctions);
     StreamWriteDWord(Stream,AddressOfNames);
     StreamWriteDWord(Stream,AddressOfOrdinals);
     AddressOfFunctions:=CodePosition+Stream.Position;
     for Counter:=0 to ExportList.Count-1 do begin
      Symbol:=ExportList[Counter].Symbol;
      if assigned(Symbol) and assigned(Symbol.Section) then begin
       StreamWriteDWord(Stream,Symbol.Section^.Offset+Symbol.Position);//ValueGetInt64(self,ExportList[Counter].Symbol.GetValue(self),false)+(StartOffset-ImageBase));
       Symbol.UseIt(self);
      end;
     end;
     AddressOfNames:=CodePosition+Stream.Position;
     Value:=CodePosition+Stream.Position+(Count*SizeOf(longword));
     for Counter:=0 to ExportList.Count-1 do begin
      StreamWriteDWord(Stream,Value);
      inc(Value,length(ExportList[Counter].Name)+1);
     end;
     for Counter:=0 to ExportList.Count-1 do begin
      StreamWriteString(Stream,ExportList[Counter].Name+#0);
     end;
     AddressOfOrdinals:=CodePosition+Stream.Position;
     for Counter:=0 to ExportList.Count-1 do begin
      StreamWriteWord(Stream,Counter);
     end;
     AddressOfName:=CodePosition+Stream.Position;
     StreamWriteString(Stream,#0);
    end;
    if CodeImageWriting then begin
     Stream.Seek(0,soBeginning);
     if assigned(CurrentSection) then begin
      CurrentSection^.Data.Seek(CurrentSection^.Data.Size,soBeginning);
      CurrentSection^.Data.CopyFrom(Stream,Stream.Size);
     end else begin
      CodeImage.Seek(CodeImage.Size,soBeginning);
      CodeImage.CopyFrom(Stream,Stream.Size);
     end;
    end;
    inc(CodePosition,Stream.Size);
   finally
    Stream.Free;
   end;
   if assigned(CurrentSection) then begin
    StartOffset:=OldStartOffset;
   end;
  end;
 end;
 procedure DoPass(Writing,ClearImportsExports:boolean);
 var OldCodePosition,OldCodeImageSize:longint;
     OldSection,Section:PAssemblerSection;
     PECOFFDirectoryEntry:PPECOFFDirectoryEntry;
 begin
  ResetOptions;
  ResetSegments;
  ResetSections;
  OldCodeImageSize:=CodePosition;
  CodeImage.Clear;
  CodeImageWriting:=Writing;
  EvaluateHereOffset:=0;
  CodePosition:=0;
  RepeatCounter:=0;
  CurrentSegment:=nil;
  CurrentSection:=nil;
  case Target of
   ttPEEXE32,ttPEEXE64,ttCOFF32,ttCOFF64:begin
    begin
     PECOFFDirectoryEntry:=@PECOFFDirectoryEntries[IMAGE_DIRECTORY_ENTRY_IMPORT];
     if not assigned(PECOFFDirectoryEntry^.Section) then begin
      Section:=GetSectionPerName('.idata');
      IntegerValueSetQWord(Section^.FreezedFlags,IMAGE_SCN_CNT_INITIALIZED_DATA or IMAGE_SCN_MEM_READ);
      OldSection:=CurrentSection;
      OldCodePosition:=CodePosition;
      CurrentSection:=Section;
      CodePosition:=CurrentSection^.Position;
      PECOFFDirectoryEntry^.Section:=CurrentSection;
      PECOFFDirectoryEntry^.Position:=CodePosition;
      if not (ImportType in [titNAME,titORDINAL]) then begin
       ImportType:=titNAME;
      end;
      WritePECOFFImportTable;
      PECOFFDirectoryEntry^.Size:=CodePosition-PECOFFDirectoryEntry^.Position;
      CurrentSection^.Position:=CodePosition;
      CurrentSection:=OldSection;
      CodePosition:=OldCodePosition;
      if Section^.Data.Size=0 then begin
       PECOFFDirectoryEntry^.Section:=nil;
       PECOFFDirectoryEntry^.Position:=0;
       PECOFFDirectoryEntry^.Size:=0;
       if assigned(Section^.Previous) then begin
        Section^.Previous^.Next:=Section^.Next;
       end else if StartSection=Section then begin
        StartSection:=Section^.Next;
       end;
       if assigned(Section^.Next) then begin
        Section^.Next^.Previous:=Section^.Previous;
       end else if LastSection=Section then begin
        LastSection:=Section^.Previous;
       end;
       Section^.Name:='';
       FreeAndNil(Section^.Flags);
       FreeAndNil(Section^.Align);
       FreeAndNil(Section^.Data);
       FreeMem(Section);
       Section:=nil;
      end;
     end;
    end;
   end;
   ttRUNTIME:begin
    if (RuntimeCodeImageSize<OldCodeImageSize) or not assigned(RuntimeCodeImage) then begin
     if assigned(RuntimeCodeImage) then begin
{$ifdef WIN32}
      VirtualFree(RuntimeCodeImage,0,MEM_RELEASE);
{$else}
{$ifdef UNIX}
      fpmunmap(RuntimeCodeImage,RuntimeCodeImageSize);
{$else}
      FreeMem(RuntimeCodeImage);
{$endif}
{$endif}
      RuntimeCodeImage:=nil;
     end;
     RuntimeCodeImageSize:=OldCodeImageSize;
{$ifdef WIN32}
     RuntimeCodeImage:=VirtualAlloc(nil,RuntimeCodeImageSize,MEM_COMMIT,PAGE_EXECUTE_READWRITE);
{$else}
{$ifdef UNIX}
     RuntimeCodeImage:=fpmmap(nil,RuntimeCodeImageSize,PROT_READ or PROT_WRITE or PROT_EXEC,MAP_PRIVATE or MAP_ANONYMOUS,-1,0);
{$else}
     GetMem(RuntimeCodeImage,RuntimeCodeImageSize);
{$endif}
{$endif}
    end;
    RuntimeCodeImageEntryPoint:=nil;
    StartOffset:=TSASMPtrUInt(RuntimeCodeImage);
    WriteImports;
   end;
  end;
  EntryPointSection:=CurrentSection;
  EntryPoint:=CodePosition;
  UserEntryPoint:=CodePosition;
  if ClearImportsExports then begin
   ImportList.Clear;
   ImportLibraryList.Clear;
   ExportList.Clear;
  end;
  CurrentLibrary:='';
  GeneratePass(StartCode);
  case Target of
   ttPEEXE32,ttPEEXE64:begin
    if ExportList.Count>0 then begin
     PECOFFDirectoryEntry:=@PECOFFDirectoryEntries[IMAGE_DIRECTORY_ENTRY_EXPORT];
     if not assigned(PECOFFDirectoryEntry^.Section) then begin
      Section:=GetSectionPerName('.edata');
      IntegerValueSetQWord(Section^.FreezedFlags,IMAGE_SCN_CNT_INITIALIZED_DATA or IMAGE_SCN_MEM_READ);
      OldSection:=CurrentSection;
      OldCodePosition:=CodePosition;
      CurrentSection:=Section;
      CodePosition:=CurrentSection^.Position;
      PECOFFDirectoryEntry^.Section:=CurrentSection;
      PECOFFDirectoryEntry^.Position:=CodePosition;
      WritePECOFFExportTable;
      PECOFFDirectoryEntry^.Size:=CodePosition-PECOFFDirectoryEntry^.Position;
      CurrentSection^.Position:=CodePosition;
      CurrentSection:=OldSection;
      CodePosition:=OldCodePosition;
      if Section^.Data.Size=0 then begin
       PECOFFDirectoryEntry^.Section:=nil;
       PECOFFDirectoryEntry^.Position:=0;
       PECOFFDirectoryEntry^.Size:=0;
       if assigned(Section^.Previous) then begin
        Section^.Previous^.Next:=Section^.Next;
       end else if StartSection=Section then begin
        StartSection:=Section^.Next;
       end;
       if assigned(Section^.Next) then begin
        Section^.Next^.Previous:=Section^.Previous;
       end else if LastSection=Section then begin
        LastSection:=Section^.Previous;
       end;
       Section^.Name:='';
       FreeAndNil(Section^.Flags);
       FreeAndNil(Section^.Align);
       FreeAndNil(Section^.Data);
       FreeMem(Section);
       Section:=nil;
      end;
     end;
    end;
   end;
  end;
 end;
begin
 FixUpPass:=FUP_NONE;
 CodeEnd:=-1;
 FillChar(PECOFFDirectoryEntries,SizeOf(TPECOFFDirectoryEntries),#0);
{$ifdef DEBUGGER}
 ResetDebuggerData;
{$endif}
 Passes:=PrepareCode(StartCode);
 if ForcePasses>0 then begin
  Passes:=ForcePasses;
 end;
 if AreErrors then begin
  ResetOptions;
  ResetSegments;
  ResetSections;
  CodeImage.Clear;
  EvaluateHereOffset:=0;
  CodePosition:=0;
  RepeatCounter:=0;
  CurrentSegment:=nil;
  CurrentSection:=nil;
 end else begin
  CodeImage.Clear;
  EvaluateHereOffset:=0;
  CodePosition:=0;
  RepeatCounter:=0;
  CurrentPasses:=Passes;
  if CurrentPasses<1 then begin
   CurrentPasses:=1;
  end;
  for Pass:=1 to CurrentPasses do begin
   CurrentPass:=Pass;
   ShowStatus('Processing Presizing/Prechecking Pass '+INTTOSTR(Pass)+'/'+INTTOSTR(Passes));
   DoPass(false,Pass<=(Passes div 2));
   if AreErrors then begin
    break;
   end;
  end;
  if AreErrors then begin
   ResetOptions;
   ResetSegments;
   ResetSections;
   CodeImage.Clear;
   EvaluateHereOffset:=0;
   CodePosition:=0;
   RepeatCounter:=0;
   CurrentSegment:=nil;
   CurrentSection:=nil;
  end else begin
   ShowStatus('Write Pass');
   DoPass(true,false);
   if CodeEnd>=0 then begin
    CodeImage.SetSize(CodeEnd);
   end;
   if Target=ttRUNTIME then begin
    FixUpPass:=FUP_RUNTIME;
    PostProcessFixUpExpressions;
    PostProcessSymbols;
    FixUpPass:=FUP_NONE;
    if assigned(RuntimeCodeImage) and (CodeImage.Size<=RuntimeCodeImageSize) then begin
     CodeImage.Seek(0,soBeginning);
     if CodeImage.Read(RuntimeCodeImage^,RuntimeCodeImageSize)<=RuntimeCodeImageSize then begin
      RuntimeCodeImageEntryPoint:=pointer(TSASMPtrUInt(TSASMPtrUInt(RuntimeCodeImage)+TSASMPtrUInt(EntryPoint)));
     end else begin
      MakeError(55);
     end;
    end else if CodeImage.Size>RuntimeCodeImageSize then begin
     MakeError(55);
    end;
   end;
  end;
 end;
 TotalSize:=CodePosition;
 result:=not AreErrors;
end;

{$ifdef DEBUGGER}
function TAssembler.FindCodeAtAddress(Address:longint):PCode;
var Best:PCode;
 procedure ScanCode(StartCode:PCode); register;
 var Code:PCode;
 begin
  Code:=StartCode;
  while assigned(Code) do begin
   if assigned(Best) then begin
    if Best^.BytePosition=Address then begin
     break;
    end;
   end;
   if Code^.CodeItemType in [tcitInstruction,tcitTimes,tcitDI8,tcitDI16,tcitDI32,
                             tcitDI64,tcitDI80,tcitDI128,tcitDI256,tcitDI512,tcitDSF,tcitDDF,
                             tcitDEF,tcitDataString,tcitDataRawString,tcitRES8,tcitRES16,tcitRES32,
                             tcitRES64,tcitRES80,tcitRES128,tcitRES256,tcitRES512,tcitRESSF,
                             tcitRES32F,tcitRESEF] then begin
    if Code^.BytePosition<=Address then begin
     if not assigned(Best) then begin
      Best:=Code;
     end else if (Code^.BytePosition>=Best^.BytePosition) and not
                 (Best^.BytePosition=Address) then begin
      Best:=Code;
     end;
    end else begin
     break;
    end;
   end;
   ScanCode(Code^.Down);
   ScanCode(Code^.ElseDown);
   Code:=Code^.Next;
  end;
 end;
begin
 Best:=nil;
 ScanCode(StartCode);
 result:=Best;
end;

function TAssembler.FindCodeAtLine(Source,Line:longint):PCode;
var Best:PCode;
 procedure ScanCode(StartCode:PCode); register;
 var Code:PCode;
 begin
  Code:=StartCode;
  while assigned(Code) do begin
   if Code^.CodeItemType in [tcitInstruction,tcitTimes,tcitDI8,tcitDI16,tcitDI32,
                             tcitDI64,tcitDSF,tcitDDF,tcitDEF,tcitDataString,tcitDataRawString,
                             tcitRES8,tcitRES16,tcitRES32,tcitRES64,
                             tcitRESSF,tcitRES32F,tcitRESEF,tcitENTRYPOINT] then begin
    if Source=Code^.Source then begin
     if Code^.LineNumber<=Line then begin
      if not assigned(Best) then begin
       Best:=Code;
      end else if Code^.LineNumber>=Best^.LineNumber then begin
       Best:=Code;
      end;
     end else begin
      break;
     end;
    end;
   end;
   ScanCode(Code^.Down);
   ScanCode(Code^.ElseDown);
   Code:=Code^.Next;
  end;
 end;
begin
 Best:=nil;
 ScanCode(StartCode);
 result:=Best;
end;

function TAssembler.FindCodeAtLineEx(Source,Line:longint):PCode;
var Best:PCode;
 procedure ScanCode(StartCode:PCode); register;
 var Code:PCode;
 begin
  Code:=StartCode;
  while assigned(Code) and not assigned(Best) do begin
   if Code^.CodeItemType in [tcitInstruction,tcitTimes,tcitDI8,tcitDI16,tcitDI32,
                             tcitDI64,tcitDI80,tcitDI128,tcitDI256,tcitDI512,tcitDSF,
                             tcitDDF,tcitDEF,tcitDataString,tcitDataRawString,tcitRES8,
                             tcitRES16,tcitRES32,tcitRES64,tcitRES80,tcitRES128,
                             tcitRES256,tcitRES512,tcitRESSF,tcitRES32F,
                             tcitRESEF] then begin
    if Source=Code^.Source then begin
     if Code^.LineNumber=Line then begin
      Best:=Code;
     end;
    end;
   end;
   ScanCode(Code^.Down);
   ScanCode(Code^.ElseDown);
   Code:=Code^.Next;
  end;
 end;
begin
 Best:=nil;
 ScanCode(StartCode);
 result:=Best;
end;

function TAssembler.FindCodeAtLineColumnEx(Source,Line,Column:longint;var Operand:POperand):PCode;
var Best:PCode;
    Counter:longint;
 procedure ScanCode(StartCode:PCode); register;
 var Code:PCode;
 begin
  Code:=StartCode;
  while assigned(Code) do begin
   if Code^.CodeItemType<>tcitNone then begin
    if Source=Code^.Source then begin
     if Code^.LineNumber=Line then begin
      if not assigned(Best) then begin
       Best:=Code;
      end else if (Code^.Column<=Column) and (Code^.Column>=Best^.Column) then begin
       Best:=Code;
      end;
     end;
    end;
   end;
   ScanCode(Code^.Down);
   ScanCode(Code^.ElseDown);
   Code:=Code^.Next;
  end;
 end;
begin
 Best:=nil;
 Operand:=nil;
 ScanCode(StartCode);
 if assigned(Best) then begin
  case Best^.CodeItemType of
   tcitInstruction:begin
    for Counter:=1 to Best^.Opcode.CountOperands do begin
     if Best^.Opcode.Operand[Counter].Column<=Column then begin
      Operand:=@Best^.Opcode.Operand[Counter];
     end;
    end;
   end;
  end;
 end;
 result:=Best;
end;

procedure TAssembler.AdjustCodeLines(Source,Line,Count:longint);
 procedure ScanCode(StartCode:PCode); register;
 var Code:PCode;
 begin
  Code:=StartCode;
  while assigned(Code) do begin
   if Source=Code^.Source then begin
    if Code^.LineNumber>=Line then begin
     inc(Code^.LineNumber,Count);
    end;
   end;
   ScanCode(Code^.Down);
   ScanCode(Code^.ElseDown);
   Code:=Code^.Next;
  end;
 end;
begin
 ScanCode(StartCode);
end;
{$endif}

function TAssembler.WriteBIN(const Stream:TStream):boolean;
begin
 result:=false;
 if assigned(Stream) then begin
  StartOffset:=0;
  Generate;

  ShowStatus('Process fix ups');
  FixUpPass:=FUP_BIN;
  PostProcessFixUpExpressions;
  PostProcessSymbols;
  FixUpPass:=FUP_NONE;

  ShowStatus('Write image');
  if Stream is TMemoryStream then begin
   TMemoryStream(Stream).Clear;
  end;
  Stream.Size:=0;
  Stream.Seek(0,soBeginning);
  CodeImage.Seek(0,soBeginning);
  Stream.CopyFrom(CodeImage,CodeImage.Size);
  Stream.Seek(Stream.Size,soBeginning);
  CodeImage.Seek(CodeImage.Size,soBeginning);
  result:=((Stream.Size<>0) or (TotalSize=0)) and not AreErrors;
 end;
end;

function TAssembler.WriteCOM(const Stream:TStream):boolean;
begin
 result:=false;
 if assigned(Stream) then begin
  StartOffset:=$100;
  Generate;

  ShowStatus('Process fix ups');
  FixUpPass:=FUP_COM;
  PostProcessFixUpExpressions;
  PostProcessSymbols;
  FixUpPass:=FUP_NONE;

  ShowStatus('Write image');
  if Stream is TMemoryStream then begin
   TMemoryStream(Stream).Clear;
  end;
  Stream.Size:=0;
  Stream.Seek(0,soBeginning);
  CodeImage.Seek(0,soBeginning);
  Stream.CopyFrom(CodeImage,CodeImage.Size);
  Stream.Seek(Stream.Size,soBeginning);
  CodeImage.Seek(CodeImage.Size,soBeginning);

  result:=((Stream.Size<>0) or (TotalSize=0)) and not AreErrors;
 end;
end;

function TAssembler.WriteMZEXE(const Stream:TStream):boolean;
var CountRelocations,Count:longint;
    Header:TMZEXEHeader;
    ImageSize,Value,RealHeaderSize,HeaderSize:longword;
    FixUpExpression:PFixUpExpression;
begin
 result:=false;
 if assigned(Stream) then begin

  StartOffset:=$100;
  Generate;

  ShowStatus('Process fix ups');
  FixUpPass:=FUP_MZEXE;
  PostProcessFixUpExpressions;
  PostProcessSymbols;
  FixUpPass:=FUP_NONE;

  ShowStatus('Write image');

  CountRelocations:=0;
  FixUpExpression:=StartFixUpExpression;
  while assigned(FixUpExpression) do begin
   if (FixUpExpression^.Flags and FUEF_SEG16)<>0 then begin
    inc(CountRelocations);
    if CountRelocations>65535 then begin
     MakeError('Too many relocations');
     exit;
    end;
   end;
   FixUpExpression:=FixUpExpression^.Next;
  end;

  RealHeaderSize:=SizeOf(TMZEXEHeader)+(CountRelocations shl 2);
  if CompleteMZEXEHeader then begin
   inc(RealHeaderSize,SizeOf(TImageDOSHeader)-SizeOf(TMZEXEHeader));
  end;

  HeaderSize:=(RealHeaderSize+$f) and not $f;

  FillChar(Header,SizeOf(TMZEXEHeader),#0);
  Header.HdrSize:=HeaderSize shr 4;
  ImageSize:=longword(CodeImage.Size)+longword(Header.HdrSize shl 4);
  Header.Signature:=$5a4d;
  Header.PartPag:=ImageSize and $1ff;
  Header.PageCnt:=ImageSize shr 9;
  if Header.PartPag<>0 then begin
   inc(Header.PageCnt);
  end;
  Header.ReloCnt:=CountRelocations;
  Header.HdrSize:=Header.HdrSize;
  if CodeEnd<0 then begin
   Header.MinMem:=0;
  end else begin
   Count:=((CodePosition-CodeEnd)+$f) and not $f;
   if Count<0 then begin
    Count:=0;
   end else if Count>$fffff then begin
    Count:=$fffff;
   end;
   Header.MinMem:=Count shr 4;
  end;
  Header.MaxMem:=$ffff;
  Value:=(((ImageSize+$f) and not $f) shr 4)+Header.MinMem+1;
  if Value>$ffff then begin
   Value:=$ffff;
  end;
  Header.ReloSS:=Value;
  Header.ExeSP:=$ffff;
  Header.ChkSum:=0;
  Header.ExeIP:=StartOffset+EntryPoint;
  Header.ReloCS:=($ffff-(StartOffset shr 4))+1;
  if CompleteMZEXEHeader then begin
   Header.TablOff:=SizeOf(TImageDOSHeader);
  end else begin
   Header.TablOff:=SizeOf(TMZEXEHeader);
  end;
  Header.Overlay:=0;

  if Stream is TMemoryStream then begin
   TMemoryStream(Stream).Clear;
  end;
  Stream.Size:=0;
  Stream.Seek(0,soBeginning);
  Stream.Write(Header,SizeOf(TMZEXEHeader));
  if CompleteMZEXEHeader then begin
   StreamWriteByteCount(Stream,0,SizeOf(TImageDOSHeader)-SizeOf(TMZEXEHeader));
  end;

  FixUpExpression:=StartFixUpExpression;
  while assigned(FixUpExpression) do begin
   if (FixUpExpression^.Flags and FUEF_SEG16)<>0 then begin
    Value:=FixUpExpression^.Position;
    StreamWriteWord(Stream,Value and $f);
    StreamWriteWord(Stream,Value shr 4);
   end;
   FixUpExpression:=FixUpExpression^.Next;
  end;

  Count:=HeaderSize-RealHeaderSize;
  if Count>0 then begin
   StreamWriteByteCount(Stream,0,Count);
  end;

  Stream.Seek(Stream.Size,soBeginning);
  CodeImage.Seek(0,soBeginning);
  Stream.CopyFrom(CodeImage,CodeImage.Size);
  CodeImage.Seek(CodeImage.Size,soBeginning);

  result:=(Stream.Size<>0) and not AreErrors;
 end;
end;

function TAssembler.WritePEEXE(const Stream:TStream;const Is64Bit:boolean):boolean;
const MZEXEHeaderSize=128;
      MZEXEHeaderBytes:array[0..MZEXEHeaderSize-1] of byte=
       ($4d,$5a,$80,$00,$01,$00,$00,$00,$04,$00,$10,$00,$ff,$ff,$00,$00,
        $40,$01,$00,$00,$00,$00,$00,$00,$40,$00,$00,$00,$00,$00,$00,$00,
        $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
        $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$00,$00,$00,
        $0e,$1f,$ba,$0e,$00,$b4,$09,$cd,$21,$b8,$01,$4c,$cd,$21,$54,$68,
        $69,$73,$20,$70,$72,$6f,$67,$72,$61,$6d,$20,$63,$61,$6e,$6e,$6f,
        $74,$20,$62,$65,$20,$72,$75,$6e,$20,$69,$6e,$20,$44,$4f,$53,$20,
        $6d,$6f,$64,$65,$2e,$0d,$0a,$24,$00,$00,$00,$00,$00,$00,$00,$00);
var i,NumberOfSections{,OldCodePosition,OldCodeImageSize},Pass:longint;
    {CheckSumPosition,}Offset,FileOffset,TotalImageSize,TotalFileOffset,
    HeaderSize,CountBytes{,Value64}:int64;
    //Value:TIntegerValue;
    PECOFFDirectoryEntry:PPECOFFDirectoryEntry;
    {OldSection,}Section:PAssemblerSection;
    ImageNTHeaders:TImageNTHeaders;
    ImageSectionHeader:TImageSectionHeader;
    HasRelocations:boolean;
 function SectionSizeAlign(Size:int64):int64;
 begin
  result:=Size;
  if (result and (PECOFFSectionAlignment-1))<>0 then begin
   result:=(result+(PECOFFSectionAlignment-1)) and not (PECOFFSectionAlignment-1);
  end;
 end;
 function FileSizeAlign(Size:int64):int64;
 begin
  result:=Size;
  if (result and (PECOFFFileAlignment-1))<>0 then begin
   result:=(result+(PECOFFFileAlignment-1)) and not (PECOFFFileAlignment-1);
  end;
 end;
 procedure DoAlign;
 var p:int64;
 begin
  p:=Stream.Position;
  if (p and (PECOFFFileAlignment-1))<>0 then begin
   StreamWriteByteCount(Stream,0,((p+(PECOFFFileAlignment-1)) and not (PECOFFFileAlignment-1))-p);
  end;
 end;
 function WriteRelocations:boolean;
 type PRelocationNode=^TRelocationNode;
      TRelocationNode=packed record
       Next:PRelocationNode;
       Previous:PRelocationNode;
       VirtualAddress:longword;
       RelocationType:longword;
      end;
      PRelocations=^TRelocations;
      TRelocations=packed record
       RootNode,LastNode:PRelocationNode;
      end;
  procedure RelocationsInit(var Instance:TRelocations);
  begin
   FillChar(Instance,SizeOf(TRelocations),#0);
  end;
  procedure RelocationsDone(var Instance:TRelocations);
  var CurrentNode,NextNode:PRelocationNode;
  begin
   CurrentNode:=Instance.RootNode;
   Instance.RootNode:=nil;
   Instance.LastNode:=nil;
   while assigned(CurrentNode) do begin
    NextNode:=CurrentNode^.Next;
    FreeMem(CurrentNode);
    CurrentNode:=NextNode;
   end;
  end;
  procedure RelocationsAdd(var Instance:TRelocations;const VirtualAddress,RelocationType:longword);
  var NewNode:PRelocationNode;
  begin
   GetMem(NewNode,SizeOf(TRelocationNode));
   FillChar(NewNode^,SizeOf(TRelocationNode),#0);
   NewNode^.VirtualAddress:=VirtualAddress;
   NewNode^.RelocationType:=RelocationType;
   if assigned(Instance.LastNode) then begin
    Instance.LastNode^.Next:=NewNode;
    NewNode^.Previous:=Instance.LastNode;
   end else begin
    Instance.RootNode:=NewNode;
   end;
   Instance.LastNode:=NewNode;
  end;
  procedure RelocationsSort(var Instance:TRelocations);
  var PartA,PartB,Node:PRelocationNode;
      InSize,PartASize,PartBSize,Merges:longint;
  begin
   if assigned(Instance.RootNode) then begin
    InSize:=1;
    while true do begin
     PartA:=Instance.RootNode;
     Instance.RootNode:=nil;
     Instance.LastNode:=nil;
     Merges:=0;
     while assigned(PartA) do begin
      inc(Merges);
      PartB:=PartA;
      PartASize:=0;
      while PartASize<InSize do begin
       inc(PartASize);
       PartB:=PartB^.Next;
       if not assigned(PartB) then begin
        break;
       end;
      end;
      PartBSize:=InSize;
      while (PartASize>0) or ((PartBSize>0) and assigned(PartB)) do begin
       if PartASize=0 then begin
        Node:=PartB;
        PartB:=PartB^.Next;
        dec(PartBSize);
       end else if (PartBSize=0) or not assigned(PartB) then begin
        Node:=PartA;
        PartA:=PartA^.Next;
        dec(PartASize);
       end else if PartA^.VirtualAddress<=PartB^.VirtualAddress then begin
        Node:=PartA;
        PartA:=PartA^.Next;
        dec(PartASize);
       end else begin
        Node:=PartB;
        PartB:=PartB^.Next;
        dec(PartBSize);
       end;
       if assigned(Instance.LastNode) then begin
        Instance.LastNode^.Next:=Node;
       end else begin
        Instance.RootNode:=Node;
       end;
       Node^.Previous:=Instance.LastNode;
       Instance.LastNode:=Node;
      end;
      PartA:=PartB;
     end;
     Instance.LastNode^.Next:=nil;
     if Merges<=1 then begin
      break;
     end;
     inc(InSize,InSize);
    end;
   end;
  end;
  function RelocationsSize(var Instance:TRelocations):longword;
  var CurrentNode,OldNode:PRelocationNode;
  begin
   RelocationsSort(Instance);
   result:=0;
   CurrentNode:=Instance.RootNode;
   OldNode:=CurrentNode;
   while assigned(CurrentNode) do begin
    if (CurrentNode=OldNode) or ((CurrentNode^.VirtualAddress-OldNode^.VirtualAddress)>=$1000) then begin
     inc(result,sizeof(TImageBaseRelocation));
    end;
    inc(result,sizeof(word));
    OldNode:=CurrentNode;
    CurrentNode:=CurrentNode^.Next;
   end;
   inc(result,sizeof(TImageBaseRelocation));
  end;
  procedure RelocationsBuild(var Instance:TRelocations;NewBase:pointer;VirtualAddress:longword);
  var CurrentNode,OldNode:PRelocationNode;
      CurrentPointer:pchar;
      BaseRelocation:PImageBaseRelocation;
  begin
   RelocationsSort(Instance);
   CurrentPointer:=NewBase;
   BaseRelocation:=pointer(CurrentPointer);
   CurrentNode:=Instance.RootNode;
   OldNode:=CurrentNode;
   while assigned(CurrentNode) do begin
    if (CurrentNode=OldNode) or ((CurrentNode^.VirtualAddress-OldNode^.VirtualAddress)>=$1000) then begin
     BaseRelocation:=pointer(CurrentPointer);
     inc(CurrentPointer,sizeof(TImageBaseRelocation));
     BaseRelocation^.VirtualAddress:=CurrentNode^.VirtualAddress;
     BaseRelocation^.SizeOfBlock:=sizeof(TImageBaseRelocation);
    end;
    pword(CurrentPointer)^:=(CurrentNode^.RelocationType shl 12) or ((CurrentNode^.VirtualAddress-BaseRelocation^.VirtualAddress) and $fff);
    inc(CurrentPointer,sizeof(word));
    inc(BaseRelocation^.SizeOfBlock,sizeof(word));
    OldNode:=CurrentNode;
    CurrentNode:=CurrentNode^.Next;
   end;
   BaseRelocation:=pointer(CurrentPointer);
   inc(CurrentPointer,sizeof(TImageBaseRelocation));
   BaseRelocation^.VirtualAddress:=0;
   BaseRelocation^.SizeOfBlock:=0;
  end;
  procedure RelocationsDump(var Instance:TRelocations);
  var CurrentNode:PRelocationNode;
  begin
   CurrentNode:=Instance.RootNode;
   while assigned(CurrentNode) do begin
    writeln(CurrentNode^.VirtualAddress);
    CurrentNode:=CurrentNode^.Next;
   end;
  end;
 var Relocations:TRelocations;
     FixUpExpression:PFixUpExpression;
     Symbol:TUserSymbol;
     Section:PAssemblerSection;
     Size:longword;
     Data:pointer;
 begin
  result:=false;
  if UserSymbolList.Count>0 then begin
   RelocationsInit(Relocations);
   try
    FixUpExpression:=StartFixUpExpression;
    while assigned(FixUpExpression) do begin
     if assigned(FixUpExpression^.Expression) and not FixUpExpression^.Relative then begin
      Symbol:=FixUpExpression^.Expression.GetFixUpSymbol(self);
      if assigned(Symbol) and ((Symbol.SymbolType in [ustLABEL,ustIMPORT]) and Symbol.Used) then begin
       if assigned(FixUpExpression^.Section) then begin
        case FixUpExpression^.Bits of
         16:begin                                                                                               
          RelocationsAdd(Relocations,FixUpExpression^.Position+FixUpExpression^.Section^.Offset,IMAGE_REL_BASED_LOW);
         end;
         32:begin
          RelocationsAdd(Relocations,FixUpExpression^.Position+FixUpExpression^.Section^.Offset,IMAGE_REL_BASED_HIGHLOW);
         end;
         64:begin
          RelocationsAdd(Relocations,FixUpExpression^.Position+FixUpExpression^.Section^.Offset,IMAGE_REL_BASED_DIR64);
         end;
        end;
       end;
      end;
     end;
     FixUpExpression:=FixUpExpression^.Next;
    end;
    if assigned(Relocations.RootNode) then begin
     RelocationsSort(Relocations);
     Size:=RelocationsSize(Relocations);
     Section:=GetSectionPerName('.reloc');
     Section^.Position:=0;
     Section^.Data.Clear;
     Section^.Data.Seek(0,soBeginning);
     IntegerValueSetQWord(Section^.FreezedFlags,IMAGE_SCN_CNT_INITIALIZED_DATA or IMAGE_SCN_MEM_READ);
     GetMem(Data,Size);
     try
      RelocationsBuild(Relocations,Data,0);
      Section^.Data.Seek(Section^.Data.Size,soBeginning);
      Section^.Data.Write(Data^,Size);
     finally
      FreeMem(Data);
     end;
     inc(Section^.Position,Size);            
     PECOFFDirectoryEntry:=@PECOFFDirectoryEntries[IMAGE_DIRECTORY_ENTRY_BASERELOC];
     PECOFFDirectoryEntry^.Section:=Section;
     PECOFFDirectoryEntry^.Position:=0;
     PECOFFDirectoryEntry^.Size:=Size;
     result:=true;
    end;
   finally
    RelocationsDone(Relocations);
   end;
  end;
 end;
begin
 result:=false;
 if assigned(Stream) then begin

  StartOffset:=ImageBase+CodeBase;
  EntryPointSection:=nil;
  EntryPoint:=0;
  UserEntryPoint:=0;
  Generate;

  if not assigned(EntryPointSection) then begin
   MakeError('Invalid entry point');
   exit;
  end;

  if not assigned(StartSection) then begin
   CurrentSection:=nil;
   CurrentLineNumber:=0;
   CurrentColumn:=0;
   CurrentSource:=0;
   MakeError(52);
   exit;
  end;

  HasRelocations:=false;

  if (Characteristics and IMAGE_FILE_RELOCS_STRIPPED)=0 then begin
   PECOFFDirectoryEntry:=@PECOFFDirectoryEntries[IMAGE_DIRECTORY_ENTRY_BASERELOC];
   if not assigned(PECOFFDirectoryEntry^.Section) then begin
    HasRelocations:=WriteRelocations;
   end;
  end;

  for Pass:=0 to 3 do begin

   Offset:=CodeBase;
   NumberOfSections:=0;
   Section:=StartSection;
   while assigned(Section) do begin
    Section^.CompleteOffset:=Offset+ImageBase;
    Section^.Offset:=Offset;
    inc(Offset,Section^.Data.Size);
    if (Offset and (PECOFFSectionAlignment-1))<>0 then begin
     Offset:=(Offset+(PECOFFSectionAlignment-1)) and not (PECOFFSectionAlignment-1);
    end;
    inc(NumberOfSections);
    Section:=Section^.Next;
   end;
   if (Offset and (PECOFFSectionAlignment-1))<>0 then begin
    Offset:=(Offset+(PECOFFSectionAlignment-1)) and not (PECOFFSectionAlignment-1);
   end;
   TotalImageSize:=Offset;

   if HasRelocations then begin
    WriteRelocations;
   end else begin
    break;
   end;

  end;

  ShowStatus('Write image');
  if Stream is TMemoryStream then begin
   TMemoryStream(Stream).Clear;
  end;
  Stream.Size:=0;
  Stream.Seek(0,soBeginning);

  HeaderSize:=MZEXEHeaderSize+SizeOf(longword)+SizeOf(TImageFileHeader);
  if Is64Bit then begin
   inc(HeaderSize,SizeOf(TImageOptionalHeader64));
  end else begin
   inc(HeaderSize,SizeOf(TImageOptionalHeader));
  end;
  inc(HeaderSize,SizeOf(TImageSectionHeader)*NumberOfSections);
  if (HeaderSize and (PECOFFFileAlignment-1))<>0 then begin
   HeaderSize:=(HeaderSize+(PECOFFFileAlignment-1)) and not (PECOFFFileAlignment-1);
  end;

  Stream.Write(MZEXEHeaderBytes[0],MZEXEHeaderSize);

  ImageNTHeaders.Signature:=$00004550;
  if Is64Bit then begin
   ImageNTHeaders.FileHeader.Machine:=$8664;
  end else begin
   ImageNTHeaders.FileHeader.Machine:=$014c;
  end;
  ImageNTHeaders.FileHeader.NumberOfSections:=NumberOfSections;
  ImageNTHeaders.FileHeader.TimeDateStamp:=0;
  ImageNTHeaders.FileHeader.PointerToSymbolTable:=0;
  ImageNTHeaders.FileHeader.NumberOfSymbols:=0;
  if Is64Bit then begin
   ImageNTHeaders.FileHeader.SizeOfOptionalHeader:=SizeOf(TImageOptionalHeader64);
  end else begin
   ImageNTHeaders.FileHeader.SizeOfOptionalHeader:=SizeOf(TImageOptionalHeader);
  end;
  ImageNTHeaders.FileHeader.Characteristics:=Characteristics;

  Stream.Write(ImageNTHeaders.Signature,SizeOf(longword));
  Stream.Write(ImageNTHeaders.FileHeader,SizeOf(TImageFileHeader));

  if Is64Bit then begin
   ImageNTHeaders.OptionalHeader64.Magic:=$020b;
   ImageNTHeaders.OptionalHeader64.MajorLinkerVersion:=2;
   ImageNTHeaders.OptionalHeader64.MinorLinkerVersion:=50;
   ImageNTHeaders.OptionalHeader64.SizeOfCode:=TotalImageSize;
   ImageNTHeaders.OptionalHeader64.SizeOfInitializedData:=0;
   ImageNTHeaders.OptionalHeader64.SizeOfUninitializedData:=0;
   if assigned(EntryPointSection) then begin
    ImageNTHeaders.OptionalHeader64.AddressOfEntryPoint:=EntryPointSection^.Offset+EntryPoint;
   end else begin
    ImageNTHeaders.OptionalHeader64.AddressOfEntryPoint:=0;
   end;
   ImageNTHeaders.OptionalHeader64.BaseOfCode:=CodeBase;
   ImageNTHeaders.OptionalHeader64.ImageBase:=ImageBase;
   ImageNTHeaders.OptionalHeader64.SectionAlignment:=PECOFFSectionAlignment;
   ImageNTHeaders.OptionalHeader64.FileAlignment:=PECOFFFileAlignment;
   ImageNTHeaders.OptionalHeader64.MajorOperatingSystemVersion:=1;
   ImageNTHeaders.OptionalHeader64.MinorOperatingSystemVersion:=0;
   ImageNTHeaders.OptionalHeader64.MajorImageVersion:=0;
   ImageNTHeaders.OptionalHeader64.MinorImageVersion:=0;
   ImageNTHeaders.OptionalHeader64.MajorSubsystemVersion:=4;
   ImageNTHeaders.OptionalHeader64.MinorSubsystemVersion:=0;
   ImageNTHeaders.OptionalHeader64.Win32VersionValue:=0;
   ImageNTHeaders.OptionalHeader64.SizeOfImage:=SectionSizeAlign(TotalImageSize);
   ImageNTHeaders.OptionalHeader64.SizeOfHeaders:=HeaderSize;
   ImageNTHeaders.OptionalHeader64.CheckSum:=0;
   ImageNTHeaders.OptionalHeader64.Subsystem:=SubSystem;
   ImageNTHeaders.OptionalHeader64.DLLCharacteristics:=DLLCharacteristics;
   ImageNTHeaders.OptionalHeader64.SizeOfStackReserve:=SizeOfStackReserve;
   ImageNTHeaders.OptionalHeader64.SizeOfStackCommit:=SizeOfStackCommit;
   ImageNTHeaders.OptionalHeader64.SizeOfHeapReserve:=SizeOfHeapReserve;
   ImageNTHeaders.OptionalHeader64.SizeOfHeapCommit:=SizeOfHeapCommit;
   ImageNTHeaders.OptionalHeader64.LoaderFlags:=0;
   ImageNTHeaders.OptionalHeader64.NumberOfRvaAndSizes:=IMAGE_NUMBEROF_DIRECTORY_ENTRIES;
   for i:=0 to IMAGE_NUMBEROF_DIRECTORY_ENTRIES-1 do begin
    PECOFFDirectoryEntry:=@PECOFFDirectoryEntries[i];
    if assigned(PECOFFDirectoryEntry^.Section) and (PECOFFDirectoryEntry^.Size>0) then begin
     ImageNTHeaders.OptionalHeader64.DataDirectory[i].VirtualAddress:=PECOFFDirectoryEntry^.Section^.Offset+PECOFFDirectoryEntry^.Position;
     ImageNTHeaders.OptionalHeader64.DataDirectory[i].Size:=PECOFFDirectoryEntry^.Size;
    end else begin
     ImageNTHeaders.OptionalHeader64.DataDirectory[i].VirtualAddress:=0;
     ImageNTHeaders.OptionalHeader64.DataDirectory[i].Size:=0;
    end;
   end;
   Stream.Write(ImageNTHeaders.OptionalHeader64,SizeOf(TImageOptionalHeader64));
  end else begin
   ImageNTHeaders.OptionalHeader.Magic:=$010b;
   ImageNTHeaders.OptionalHeader.MajorLinkerVersion:=2;
   ImageNTHeaders.OptionalHeader.MinorLinkerVersion:=50;
   ImageNTHeaders.OptionalHeader.SizeOfCode:=TotalImageSize;
   ImageNTHeaders.OptionalHeader.SizeOfInitializedData:=0;
   ImageNTHeaders.OptionalHeader.SizeOfUninitializedData:=0;
   if assigned(EntryPointSection) then begin                                              
    ImageNTHeaders.OptionalHeader.AddressOfEntryPoint:=EntryPointSection^.Offset+EntryPoint;
   end else begin
    ImageNTHeaders.OptionalHeader.AddressOfEntryPoint:=0;
   end;
   ImageNTHeaders.OptionalHeader.BaseOfCode:=CodeBase;
   ImageNTHeaders.OptionalHeader.BaseOfData:=0;
   ImageNTHeaders.OptionalHeader.ImageBase:=ImageBase;
   ImageNTHeaders.OptionalHeader.SectionAlignment:=PECOFFSectionAlignment;
   ImageNTHeaders.OptionalHeader.FileAlignment:=PECOFFFileAlignment;
   ImageNTHeaders.OptionalHeader.MajorOperatingSystemVersion:=1;
   ImageNTHeaders.OptionalHeader.MinorOperatingSystemVersion:=0;
   ImageNTHeaders.OptionalHeader.MajorImageVersion:=0;
   ImageNTHeaders.OptionalHeader.MinorImageVersion:=0;
   ImageNTHeaders.OptionalHeader.MajorSubsystemVersion:=4;
   ImageNTHeaders.OptionalHeader.MinorSubsystemVersion:=0;
   ImageNTHeaders.OptionalHeader.Win32VersionValue:=0;
   ImageNTHeaders.OptionalHeader.SizeOfImage:=SectionSizeAlign(TotalImageSize);
   ImageNTHeaders.OptionalHeader.SizeOfHeaders:=HeaderSize;
   ImageNTHeaders.OptionalHeader.CheckSum:=0;
   ImageNTHeaders.OptionalHeader.Subsystem:=SubSystem;
   ImageNTHeaders.OptionalHeader.DLLCharacteristics:=DLLCharacteristics;
   ImageNTHeaders.OptionalHeader.SizeOfStackReserve:=SizeOfStackReserve;
   ImageNTHeaders.OptionalHeader.SizeOfStackCommit:=SizeOfStackCommit;
   ImageNTHeaders.OptionalHeader.SizeOfHeapReserve:=SizeOfHeapReserve;
   ImageNTHeaders.OptionalHeader.SizeOfHeapCommit:=SizeOfHeapCommit;
   ImageNTHeaders.OptionalHeader.LoaderFlags:=0;
   ImageNTHeaders.OptionalHeader.NumberOfRvaAndSizes:=IMAGE_NUMBEROF_DIRECTORY_ENTRIES;
   for i:=0 to IMAGE_NUMBEROF_DIRECTORY_ENTRIES-1 do begin
    PECOFFDirectoryEntry:=@PECOFFDirectoryEntries[i];
    if assigned(PECOFFDirectoryEntry^.Section) and (PECOFFDirectoryEntry^.Size>0) then begin
     ImageNTHeaders.OptionalHeader.DataDirectory[i].VirtualAddress:=PECOFFDirectoryEntry^.Section^.Offset+PECOFFDirectoryEntry^.Position;
     ImageNTHeaders.OptionalHeader.DataDirectory[i].Size:=PECOFFDirectoryEntry^.Size;
    end else begin
     ImageNTHeaders.OptionalHeader.DataDirectory[i].VirtualAddress:=0;
     ImageNTHeaders.OptionalHeader.DataDirectory[i].Size:=0;
    end;
   end;
   Stream.Write(ImageNTHeaders.OptionalHeader,SizeOf(TImageOptionalHeader));
  end;

  FileOffset:=HeaderSize;
  Section:=StartSection;
  while assigned(Section) do begin
   Section^.FileOffset:=FileOffset;
   if (IntegerValueGetInt64(Section^.FreezedFlags) and IMAGE_SCN_CNT_UNINITIALIZED_DATA)=0 then begin
    inc(FileOffset,Section^.Data.Size);
    if (FileOffset and (PECOFFFileAlignment-1))<>0 then begin
     FileOffset:=(FileOffset+(PECOFFFileAlignment-1)) and not (PECOFFFileAlignment-1);
    end;
   end;
   Section:=Section^.Next;
  end;
  if (FileOffset and (PECOFFFileAlignment-1))<>0 then begin
   FileOffset:=(FileOffset+(PECOFFFileAlignment-1)) and not (PECOFFFileAlignment-1);
  end;
  TotalFileOffset:=FileOffset;

  Section:=StartSection;
  while assigned(Section) do begin
   FillChar(ImageSectionHeader,SizeOf(TImageSectionHeader),#0);
   i:=length(Section.Name);
   if i>0 then begin
    if i>8 then begin
     i:=8;
    end;
    Move(Section.Name[1],ImageSectionHeader.Name[0],i);
   end;
   ImageSectionHeader.Misc.VirtualSize:=Section^.Data.Size;
   ImageSectionHeader.VirtualAddress:=Section^.Offset;
   if (IntegerValueGetInt64(Section^.FreezedFlags) and IMAGE_SCN_CNT_UNINITIALIZED_DATA)<>0 then begin
    ImageSectionHeader.SizeOfRawData:=0;
    ImageSectionHeader.PointerToRawData:=0;
   end else begin
    ImageSectionHeader.SizeOfRawData:=FileSizeAlign(Section^.Data.Size);
    ImageSectionHeader.PointerToRawData:=Section^.FileOffset;
   end;
   ImageSectionHeader.PointerToRelocations:=0;
   ImageSectionHeader.PointerToLineNumbers:=0;
   ImageSectionHeader.NumberOfRelocations:=0;
   ImageSectionHeader.NumberOfLineNumbers:=0;
   ImageSectionHeader.Characteristics:=IntegerValueGetInt64(Section^.FreezedFlags);
   Stream.Write(ImageSectionHeader,SizeOf(TImageSectionHeader));
   Section:=Section^.Next;
  end;

  CountBytes:=HeaderSize-Stream.Position;
  if CountBytes>0 then begin
   StreamWriteByteCount(Stream,0,CountBytes);
  end;

  FixUpPass:=FUP_PEEXE;
  PostProcessFixUpExpressions;
  PostProcessSymbols;
  FixUpPass:=FUP_NONE;

  Section:=StartSection;
  while assigned(Section) do begin
   if (IntegerValueGetInt64(Section^.FreezedFlags) and IMAGE_SCN_CNT_UNINITIALIZED_DATA)=0 then begin
    CountBytes:=Section^.FileOffset-Stream.Position;
    if CountBytes>0 then begin
     StreamWriteByteCount(Stream,0,CountBytes);
    end;
    Section^.Data.Seek(0,soBeginning);
    Stream.CopyFrom(Section^.Data,Section^.Data.Size);
   end;
   Section:=Section^.Next;
  end;

  CountBytes:=TotalFileOffset-Stream.Position;
  if CountBytes>0 then begin
   StreamWriteByteCount(Stream,0,CountBytes);
  end;

  result:=true;
 end;
end;

function TAssembler.WriteCOFF(const Stream:TStream;const Is64Bit,IsDOS:boolean):boolean;
const COFF_SIZEOF_SHORT_NAME=8;
type PCOFFFileHeader=^TCOFFFileHeader;
     TCOFFFileHeader=packed record
      Machine:word;
      NumberOfSections:word;
      TimeDateStamp:longword;
      PointerToSymbolTable:longword;
      NumberOfSymbols:longword;
      SizeOfOptionalHeader:word;
      Characteristics:word;
     end;
     PCOFFSectionHeader=^TCOFFSectionHeader;
     TCOFFSectionHeader=packed record
      Name:packed array[0..COFF_SIZEOF_SHORT_NAME-1] of ansichar;
      VirtualSize:longword;
      VirtualAddress:longword;
      SizeOfRawData:longword;
      PointerToRawData:longword;
      PointerToRelocations:longword;
      PointerToLineNumbers:longword;
      NumberOfRelocations:word;
      NumberOfLineNumbers:word;
      Characteristics:longword;
     end;
     PCOFFSymbolName=^TCOFFSymbolName;
     TCOFFSymbolName=packed record
      case longint of
       0:(
        Name:packed array[0..7] of ansichar
       );
       1:(
        Zero:longword;
        PointerToString:longword;
       );
     end;
     PCOFFSymbol=^TCOFFSymbol;
     TCOFFSymbol=packed record
      Name:TCOFFSymbolName;
      Value:longword;
      Section:word;
      SymbolType:word;
      SymbolClass:byte;
      Aux:byte;
     end;
     PCOFFRelocation=^TCOFFRelocation;
     TCOFFRelocation=packed record
      VirtualAddress:longword;
      Symbol:longword;
      RelocationType:word;
     end;
var CountCOFFSections,SymbolPosition,InitialSymbolCount,Counter,Len,RelocationIndex,Index:longint;
    VirtualSize,SymbolNamePosition:int64;
    Symbol:TUserSymbol;
    Section:PAssemblerSection;
    FixUpExpression:PFixUpExpression;
    COFFFileHeader:TCOFFFileHeader;
    COFFSectionHeaders:array of TCOFFSectionHeader;
    COFFRelocation:TCOFFRelocation;
    COFFSymbol:TCOFFSymbol;
    Buf1:array[1..18] of ansichar;
    FileName,StringData,PrivatePrefix:ansistring;
    MustAddFeat00:boolean;
    //SymbolType:TSymbolTreeLinkType;
    SymbolValue:TSymbolTreeLink;
    UpperCaseSymbolName:ansistring;
    Feat00Symbol:TUserSymbol;
    FixUpExpressionFlags:TFixUpExpressionFlags;
begin
 result:=false;
 if assigned(Stream) then begin

  StartOffset:=0;
  Generate;

  Feat00Symbol:=nil;

  if not (Is64Bit or IsDOS) then begin
   // For to allow "link /safeseh"
   MustAddFeat00:=true;
   for Counter:=0 to UserSymbolList.Count-1 do begin
    Symbol:=UserSymbolList[Counter];
    if (Symbol.SymbolType<>ustNONE) and (Symbol.OriginalName='@feat.00') then begin
     MustAddFeat00:=false;
     break;
    end;
   end;
   if MustAddFeat00 then begin
    UpperCaseSymbolName:=UpperCase('@feat.00');
    UserSymbolList.NewClass(Index,UpperCaseSymbolName,'@feat.00');
    UserSymbolTree.Add(UpperCaseSymbolName,stUSER,Index);
    //SymbolType:=stUSER;
    SymbolValue:=Index;
    Symbol:=UserSymbolList[SymbolValue];
    Symbol.SymbolType:=ustLABEL;
    Symbol.Section:=nil;
    Symbol.Position:=0;
    Symbol.HasPosition:=true;
    Symbol.IsPublic:=true;
    Feat00Symbol:=Symbol;
   end;
  end;

  ShowStatus('Write image');
  if Stream is TMemoryStream then begin
   TMemoryStream(Stream).Clear;
  end;
  Stream.Size:=0;
  Stream.Seek(0,soBeginning);

  CountCOFFSections:=CountSections;
  if CountCOFFSections=0 then begin
   CurrentSection:=nil;
   CurrentLineNumber:=0;
   CurrentColumn:=0;
   CurrentSource:=0;
   MakeError(52);
   exit;
  end;

  PrivatePrefix:='';//'LOCAL@'+LongWordToHex(Checksum)+LongWordToHex(Checksum2 xor SizeChecksum)+'$';

  ShowStatus('Process fix ups');
  FixUpPass:=FUP_COFF;
  PostProcessFixUpExpressions;
  PostProcessSymbols;
  FixUpPass:=FUP_NONE;

  ShowStatus('Write image');
  
  COFFSectionHeaders:=nil;
  try
   SetLength(COFFSectionHeaders,CountCOFFSections);

   SymbolPosition:=SizeOf(TCOFFFileHeader)+(SizeOf(TCOFFSectionHeader)*CountCOFFSections);

   InitialSymbolCount:=3+(2*CountSections);

   Counter:=0;
   VirtualSize:=0;
   Section:=StartSection;
   while assigned(Section) do begin
    FillChar(COFFSectionHeaders[Counter],SizeOf(TCOFFSectionHeader),#0);
    Len:=length(Section^.Name);
    if Len>COFF_SIZEOF_SHORT_NAME then begin
     Len:=COFF_SIZEOF_SHORT_NAME;
    end;
    if Len>0 then begin
     Move(Section^.Name[1],COFFSectionHeaders[Counter].Name[0],Len);
    end;
    COFFSectionHeaders[Counter].Characteristics:=IntegerValueGetQWord(Section^.FreezedFlags);
    case IntegerValueGetInt64(Section^.FreezedAlign) of
     1:begin
      COFFSectionHeaders[Counter].Characteristics:=COFFSectionHeaders[Counter].Characteristics or IMAGE_SCN_ALIGN_1BYTES;
     end;
     2:begin
      COFFSectionHeaders[Counter].Characteristics:=COFFSectionHeaders[Counter].Characteristics or IMAGE_SCN_ALIGN_2BYTES;
     end;
     4:begin
      COFFSectionHeaders[Counter].Characteristics:=COFFSectionHeaders[Counter].Characteristics or IMAGE_SCN_ALIGN_4BYTES;
     end;
     8:begin
      COFFSectionHeaders[Counter].Characteristics:=COFFSectionHeaders[Counter].Characteristics or IMAGE_SCN_ALIGN_8BYTES;
     end;
     16:begin
      COFFSectionHeaders[Counter].Characteristics:=COFFSectionHeaders[Counter].Characteristics or IMAGE_SCN_ALIGN_16BYTES;
     end;
     32:begin
      COFFSectionHeaders[Counter].Characteristics:=COFFSectionHeaders[Counter].Characteristics or IMAGE_SCN_ALIGN_32BYTES;
     end;
     64:begin
      COFFSectionHeaders[Counter].Characteristics:=COFFSectionHeaders[Counter].Characteristics or IMAGE_SCN_ALIGN_64BYTES;
     end;
    end;
    if Section^.Position>0 then begin
     COFFSectionHeaders[Counter].VirtualSize:=0;//VirtualSize;
     if (COFFSectionHeaders[Counter].Characteristics and IMAGE_SCN_CNT_UNINITIALIZED_DATA)<>0 then begin
      COFFSectionHeaders[Counter].SizeOfRawData:=Section^.Data.Size;
 //   COFFSectionHeaders[Counter].SizeOfRawData:=0;
      COFFSectionHeaders[Counter].PointerToRawData:=0;
     end else begin
      COFFSectionHeaders[Counter].SizeOfRawData:=Section^.Data.Size;
      COFFSectionHeaders[Counter].PointerToRawData:=SymbolPosition;
      inc(SymbolPosition,Section^.Data.Size);
     end;
     inc(VirtualSize,Section^.Data.Size);
     if Section^.RelocationFixUpExpressions.Count>0 then begin
      COFFSectionHeaders[Counter].PointerToRelocations:=SymbolPosition;
      inc(SymbolPosition,Section^.RelocationFixUpExpressions.Count*SizeOf(TCOFFRelocation));
      if Section^.RelocationFixUpExpressions.Count<IMAGE_SCN_MAX_RELOC then begin
       COFFSectionHeaders[Counter].NumberOfRelocations:=Section^.RelocationFixUpExpressions.Count;
      end else begin
       COFFSectionHeaders[Counter].NumberOfRelocations:=IMAGE_SCN_MAX_RELOC;
       COFFSectionHeaders[Counter].Characteristics:=COFFSectionHeaders[Counter].Characteristics or IMAGE_SCN_LNK_NRELOC_OVFL;
       inc(SymbolPosition,SizeOf(TCOFFRelocation));
      end;
     end else begin
      COFFSectionHeaders[Counter].NumberOfRelocations:=0;
      COFFSectionHeaders[Counter].PointerToRelocations:=0;
     end;
    end else begin
     COFFSectionHeaders[Counter].VirtualSize:=0;
     COFFSectionHeaders[Counter].SizeOfRawData:=0;
     COFFSectionHeaders[Counter].PointerToRawData:=0;
     COFFSectionHeaders[Counter].NumberOfRelocations:=0;
     COFFSectionHeaders[Counter].PointerToRelocations:=0;
    end;                                                     
    COFFSectionHeaders[Counter].PointerToLineNumbers:=0;
    COFFSectionHeaders[Counter].NumberOfLineNumbers:=0;
    Section^.Index:=Counter;
    inc(Counter);
    Section:=Section^.Next;
   end;

   if Is64Bit then begin
    COFFFileHeader.Machine:=IMAGE_FILE_MACHINE_AMD64;
   end else begin
    COFFFileHeader.Machine:=IMAGE_FILE_MACHINE_I386;
   end;
   COFFFileHeader.NumberOfSections:=CountCOFFSections;
   COFFFileHeader.TimeDateStamp:=NowUnixTime;
   COFFFileHeader.PointerToSymbolTable:=SymbolPosition;
   COFFFileHeader.NumberOfSymbols:=InitialSymbolCount+CountOutputSymbols;
   COFFFileHeader.SizeOfOptionalHeader:=0;
   if Is64Bit then begin
    COFFFileHeader.Characteristics:=IMAGE_FILE_LINE_NUMS_STRIPPED;
   end else begin
    COFFFileHeader.Characteristics:=IMAGE_FILE_32BIT_MACHINE or IMAGE_FILE_LINE_NUMS_STRIPPED;
   end;

   if Stream.Write(COFFFileHeader,SizeOf(TCOFFFileHeader))<>SizeOf(TCOFFFileHeader) then begin
    SetLength(COFFSectionHeaders,0);
    exit;
   end;

   for Counter:=0 to length(COFFSectionHeaders)-1 do begin
    if Stream.Write(COFFSectionHeaders[Counter],SizeOf(TCOFFSectionHeader))<>SizeOf(TCOFFSectionHeader) then begin
     SetLength(COFFSectionHeaders,0);
     exit;
    end;
   end;

   Section:=StartSection;
   while assigned(Section) do begin
    if (Section^.Position>0) or (Section^.Data.Size>0) then begin

     Section^.Data.Seek(0,soBeginning);
     if (IntegerValueGetQWord(Section^.FreezedFlags) and IMAGE_SCN_CNT_UNINITIALIZED_DATA)=0 then begin
      Stream.Seek(Stream.Size,soBeginning);
      Section^.Data.Seek(0,soBeginning);
      Stream.CopyFrom(Section^.Data,Section^.Data.Size);
      Section^.Data.Seek(Section^.Data.Size,soBeginning);
      Stream.Seek(Stream.Size,soBeginning);
     end;

     if Section^.RelocationFixUpExpressions.Count>=IMAGE_SCN_MAX_RELOC then begin
      FillChar(COFFRelocation,SizeOf(TCOFFRelocation),#0);
      COFFRelocation.VirtualAddress:=Section^.RelocationFixUpExpressions.Count;
      COFFRelocation.Symbol:=0;
      COFFRelocation.RelocationType:=0;
      Stream.Write(COFFRelocation,SizeOf(TCOFFRelocation));
     end;

     for RelocationIndex:=0 to Section^.RelocationFixUpExpressions.Count-1 do begin
      FixUpExpression:=Section^.RelocationFixUpExpressions[RelocationIndex];
      CurrentSection:=FixUpExpression^.Section;
      CurrentLineNumber:=FixUpExpression^.LineNumber;
      CurrentColumn:=FixUpExpression^.Column;
      CurrentSource:=FixUpExpression^.Source;
      FixUpExpressionFlags:=FixUpExpression^.Flags;
      Symbol:=FixUpExpression^.Symbol;
      FillChar(COFFRelocation,SizeOf(TCOFFRelocation),#0);
      if assigned(FixUpExpression^.Symbol) then begin
       COFFRelocation.Symbol:=InitialSymbolCount+FixUpExpression^.Symbol.SymbolIndex;
      end else begin
       if assigned(CurrentSection) then begin
        COFFRelocation.Symbol:=2+(CurrentSection^.Index*2);
       end else begin
        COFFRelocation.Symbol:=InitialSymbolCount-1;
       end;
      end;
      COFFRelocation.VirtualAddress:=FixUpExpression^.Position;
      if FixUpExpression^.Relative then begin
       // Relative
       if Is64Bit then begin
        case FixUpExpression^.Bits of                  
         32:begin
          if (FixUpExpressionFlags and (FUEF_GOT or FUEF_GOTPC or FUEF_GOTOFF or FUEF_GOTTPOFF or FUEF_PLT or FUEF_TLSIE))<>0 then begin
           MakeError('Unsupported relocation type for COFF');
          end else begin
           COFFRelocation.RelocationType:=IMAGE_REL_AMD64_REL32;
          end;
         end;
         else begin
          MakeError('Unsupported relocation type for COFF');
         end;
        end;
       end else begin
        case FixUpExpression^.Bits of
         32:begin
          if (FixUpExpressionFlags and (FUEF_GOT or FUEF_GOTPC or FUEF_GOTOFF or FUEF_GOTTPOFF or FUEF_PLT or FUEF_TLSIE))<>0 then begin
           MakeError('Unsupported relocation type for COFF');
          end else begin
           COFFRelocation.RelocationType:=IMAGE_REL_I386_REL32;
          end;
         end;
         else begin
          MakeError('Unsupported relocation type for COFF');
         end;
        end;
       end;
      end else begin
       // Absolute
       if Is64Bit then begin
        case FixUpExpression^.Bits of
         32:begin
          if (FixUpExpressionFlags and (FUEF_GOT or FUEF_GOTPC or FUEF_GOTOFF or FUEF_GOTTPOFF or FUEF_PLT or FUEF_TLSIE))<>0 then begin
           MakeError('Unsupported relocation type for COFF');
          end else if (FixUpExpressionFlags and FUEF_NOBASE)<>0 then begin
           COFFRelocation.RelocationType:=IMAGE_REL_AMD64_ADDR32NB;
          end else begin
           COFFRelocation.RelocationType:=IMAGE_REL_AMD64_ADDR32;
          end;
         end;
         64:begin
          if (FixUpExpressionFlags and (FUEF_GOT or FUEF_GOTPC or FUEF_GOTOFF or FUEF_GOTTPOFF or FUEF_PLT or FUEF_TLSIE or FUEF_NOBASE))<>0 then begin
           MakeError('Unsupported relocation type for COFF');
          end else begin
           COFFRelocation.RelocationType:=IMAGE_REL_AMD64_ADDR64;
          end;
         end;
         else begin
          MakeError('Unsupported relocation type for COFF');
         end;
        end;
       end else begin
        case FixUpExpression^.Bits of
         32,64:begin
          if (FixUpExpressionFlags and (FUEF_GOT or FUEF_GOTPC or FUEF_GOTOFF or FUEF_GOTTPOFF or FUEF_PLT or FUEF_TLSIE))<>0 then begin
           MakeError('Unsupported relocation type for COFF');
          end else if (FixUpExpressionFlags and FUEF_NOBASE)<>0 then begin
           COFFRelocation.RelocationType:=IMAGE_REL_I386_DIR32NB;
          end else begin
           COFFRelocation.RelocationType:=IMAGE_REL_I386_DIR32;
          end;
         end;
         else begin
          MakeError('Unsupported relocation type for COFF');
         end;
        end;
       end;
      end;
      Stream.Write(COFFRelocation,SizeOf(TCOFFRelocation));
     end;

    end;

    Section:=Section^.Next;
   end;

   FillChar(COFFSymbol,SizeOf(TCOFFSymbol),#0);
   COFFSymbol.Name.Name:='.file';
   COFFSymbol.Value:=0;
   COFFSymbol.Section:=$fffe;
   COFFSymbol.SymbolType:=0;
   COFFSymbol.SymbolClass:=IMAGE_SYM_CLASS_FILE;
   COFFSymbol.Aux:=1;
   Stream.Write(COFFSymbol,SizeOf(TCOFFSymbol));
   FillChar(Buf1,SizeOf(Buf1),#0);
   if FileStringList.Count>0 then begin
    FileName:=FileStringList[0];
   end else begin
    FileName:=CurrentFileName;
   end;
   Len:=length(FileName);
   if Len>0 then begin
    if Len>18 then begin
     Len:=18;
    end;
    Move(FileName[1],Buf1,Len);
   end;
   Stream.Write(Buf1,SizeOf(Buf1));

   Counter:=0;
   Section:=StartSection;
   while assigned(Section) do begin
    FillChar(COFFSymbol,SizeOf(TCOFFSymbol),#0);
    Len:=length(Section^.Name);
    if Len>0 then begin
     if Len>8 then begin
      Len:=8;
     end;
     Move(Section^.Name[1],COFFSymbol.Name.Name,Len);
    end;
    COFFSymbol.Value:=0;
    COFFSymbol.Section:=Counter+1;
    COFFSymbol.SymbolType:=0;
    COFFSymbol.SymbolClass:=IMAGE_SYM_CLASS_STATIC;
    COFFSymbol.Aux:=1;
    Stream.Write(COFFSymbol,SizeOf(TCOFFSymbol));
    StreamWriteLongInt(Stream,Section^.Position);
    StreamWriteWord(Stream,COFFSectionHeaders[Counter].NumberOfRelocations);
    StreamWriteByteCount(Stream,0,12);
    inc(Counter);
    Section:=Section^.Next;
   end;

   FillChar(COFFSymbol,SizeOf(TCOFFSymbol),#0);
   COFFSymbol.Name.Name:='.absolut';
   COFFSymbol.Value:=0;
   COFFSymbol.Section:=$ffff;
   COFFSymbol.SymbolType:=0;
   COFFSymbol.SymbolClass:=IMAGE_SYM_CLASS_STATIC;
   COFFSymbol.Aux:=0;
   Stream.Write(COFFSymbol,SizeOf(TCOFFSymbol));

   SymbolNamePosition:=4;//Stream.Position+(CountOutputSymbols*SizeOf(TCOFFSymbol));

   for Counter:=0 to UserSymbolList.Count-1 do begin
    Symbol:=UserSymbolList[Counter];
    if Symbol.NeedSymbol then begin
     FillChar(COFFSymbol,SizeOf(TCOFFSymbol),#0);
     if Symbol.IsPublic or Symbol.IsExternal then begin
      StringData:=Symbol.OriginalName;
     end else begin
      StringData:=PrivatePrefix+Symbol.Name;
     end;
     Len:=length(StringData);
     if Len>0 then begin
      if Len<=8 then begin
       FillChar(COFFSymbol.Name.Name,SizeOf(COFFSymbol.Name.Name),AnsiChar(#0));
       Move(StringData[1],COFFSymbol.Name.Name[0],Len);
      end else begin
       COFFSymbol.Name.Zero:=0;
       COFFSymbol.Name.PointerToString:=SymbolNamePosition;
       inc(SymbolNamePosition,Len+1);
      end;
     end;
     COFFSymbol.Value:=Symbol.Position;
     if Symbol.IsExternal then begin
      COFFSymbol.Section:=0;
     end else if assigned(Symbol.Section) then begin
      COFFSymbol.Section:=GetSectionNumber(Symbol.Section)+1;
     end else if assigned(Feat00Symbol) and (Symbol=Feat00Symbol) then begin
      COFFSymbol.Section:=1;
     end else begin
      COFFSymbol.Section:=0;
     end;
     COFFSymbol.SymbolType:=0;
     if Symbol.IsPublic or Symbol.IsExternal then begin
      COFFSymbol.SymbolClass:=IMAGE_SYM_CLASS_EXTERNAL;
     end else begin
      COFFSymbol.SymbolClass:=IMAGE_SYM_CLASS_STATIC;
     end;
     Stream.Write(COFFSymbol,SizeOf(TCOFFSymbol));
    end;
   end;

   StreamWriteLongInt(Stream,SymbolNamePosition);

   for Counter:=0 to UserSymbolList.Count-1 do begin
    Symbol:=UserSymbolList[Counter];
    if Symbol.NeedSymbol then begin
     if Symbol.IsPublic or Symbol.IsExternal then begin
      Len:=length(Symbol.OriginalName);
     end else begin
      Len:=length(PrivatePrefix+Symbol.Name);
     end;
     if Len>8 then begin
      if Symbol.IsPublic or Symbol.IsExternal then begin
       if Stream.Write(Symbol.OriginalName[1],Len)<>Len then begin
        SetLength(COFFSectionHeaders,0);
        exit;
       end;
      end else begin
       StringData:=PrivatePrefix+Symbol.Name;
       if Stream.Write(StringData[1],Len)<>Len then begin
        SetLength(COFFSectionHeaders,0);
        exit;
       end;
      end;
      StreamWriteByte(Stream,0);
     end;
    end;
   end;

   CurrentSection:=nil;
   CurrentLineNumber:=0;
   CurrentColumn:=0;
   CurrentSource:=0;

   result:=((Stream.Size<>0) or (TotalSize=0)) and not AreErrors;

  finally
   SetLength(COFFSectionHeaders,0);
  end;

 end;
end;

function TAssembler.WriteELF(const Stream:TStream;const Is64Bit,IsX32:boolean):boolean;
const EI_MAG0=0;
      ELFMAG0=$7f;
      EI_MAG1=1;
      ELFMAG1=ord('E');
      EI_MAG2=2;
      ELFMAG2=ord('L');
      EI_MAG3=3;
      ELFMAG3=ord('F');
      EI_CLASS=4;
      ELFCLASSNONE=0;
      ELFCLASS32=1;
      ELFCLASS64=2;
      EI_DATA=5;
      ELFDATANONE=0;
      ELFDATA2LSB=1;
      ELFDATA2MSB=2;
      EI_VERSION=6;
      EI_OSABI=7;
      EI_ABIVERSION=8;
      EI_PAD=9;
      EI_NIDENT=16;

      EV_NONE=0;
      EV_CURRENT=1;

      ELFOSABI_SYSV=0;
      ELFOSABI_HPUX=1;
      ELFOSABI_NETBSD=2;
      ELFOSABI_LINUX=3;
      ELFOSABI_HURD=4;
      ELFOSABI_SOLARIS=6;
      ELFOSABI_AIX=7;
      ELFOSABI_IRIX=8;
      ELFOSABI_FREEBSD=9;
      ELFOSABI_TRU64=10;
      ELFOSABI_MODESTO=11;
      ELFOSABI_OPENBSD=12;
      ELFOSABI_OPENVMS=13;
      ELFOSABI_NSK=14;
      ELFOSABI_AROS=15;
      ELFOSABI_FENIXOS=16;
      ELFOSABI_C6000_ELFABI=64;
      ELFOSABI_C6000_LINUX=65;
      ELFOSABI_ARM=97;
      ELFOSABI_STANDALONE=255;

      ET_NONE=0;
      ET_REL=1;
      ET_EXEC=2;
      ET_DYN=3;
      ET_CORE=4;
      ET_LOPROC=$ff00;
      ET_HIPROC=$ffff;

      EM_SPARC=2;
      EM_386=3;
      EM_M68K=4;
      EM_MIPS=8;
      EM_PPC=20;
      EM_ARM=40;
      EM_X86_64=62;

      SHN_UNDEF=0;
      SHN_LORESERVE=$ff00;
      SHN_ABS=$fff1;
      SHN_COMMON=$fff2;

      SHT_OTHER=-1;
      SHT_NULL=0;
      SHT_PROGBITS=1;
      SHT_SYMTAB=2;
      SHT_STRTAB=3;
      SHT_RELA=4;
      SHT_HASH=5;
      SHT_DYNAMIC=6;
      SHT_NOTE=7;
      SHT_NOBITS=8;
      SHT_REL=9;
      SHT_SHLIB=10;
      SHT_DYNSYM=11;
      SHT_INIT_ARRAY=14;
      SHT_FINI_ARRAY=15;
      SHT_PREINIT_ARRAY=16;
      SHT_GROUP=17;
      SHT_SYMTAB_SHNDX=18;
      SHT_GNU_ATTRIBUTES=$6ffffff5;
      SHT_GNU_HASH=$6ffffff6;
      SHT_GNU_LIBLIST=$6ffffff7;
      SHT_GNU_verdef=$6ffffffd;
      SHT_GNU_verneed=$6ffffffe;
      SHT_GNU_versym=$6fffffff;

      SHF_WRITE=1;
      SHF_ALLOC=2;
      SHF_EXECINSTR=4;
      SHF_MERGE=16;
      SHF_STRINGS=32;
      SHF_INFO_LINK=64;
      SHF_LINK_ORDER=128;
      SHF_OS_NONCONFORMING=256;
      SHF_GROUP=512;
      SHF_TLS=1024;

      STB_LOCAL=0;
      STB_GLOBAL=1;
      STB_WEAK=2;

      STT_NOTYPE=0;
      STT_OBJECT=1;
      STT_FUNC=2;
      STT_SECTION=3;
      STT_FILE=4;
      STT_COMMON=5;
      STT_TLS=6;
      STT_GNU_IFUNC=10;

      STV_DEFAULT=0;
      STV_INTERNAL=1;
      STV_HIDDEN=2;
      STV_PROTECTED=3;

      PT_NULL=0;
      PT_LOAD=1;

      PT_DYNAMIC=2;
      PT_INTERP=3;
      PT_NOTE=4;
      PT_SHLIB=5;
      PT_PHDR=6;
      PT_TLS=7;
      PT_LOOS=$60000000;
      PT_HIOS=$6fffffff;
      PT_LOPROC=$70000000;
      PT_HIPROC=$7fffffff;
      PT_GNU_EH_FRAME=PT_LOOS+$474e550;
      PT_GNU_STACK=PT_LOOS+$474e551;
      PT_GNU_RELRO=PT_LOOS+$474e552;

      PF_X=1;
      PF_W=2;
      PF_R=4;
      PF_MASKOS=$0ff00000;
      PF_MASKPROC=$f0000000;

      DT_NULL=0;
      DT_NEEDED=1;
      DT_PLTRELSZ=2;
      DT_PLTGOT=3;
      DT_HASH=4;
      DT_STRTAB=5;
      DT_SYMTAB=6;
      DT_RELA=7;
      DT_RELASZ=8;
      DT_RELAENT=9;
      DT_STRSZ=10;
      DT_SYMENT=11;
      DT_INIT=12;
      DT_FINI=13;
      DT_SONAME=14;
      DT_RPATH=15;
      DT_SYMBOLIC=16;
      DT_REL=17;
      DT_RELSZ=18;
      DT_RELENT=19;
      DT_PLTREL=20;
      DT_DEBUG=21;
      DT_TEXTREL=22;
      DT_JMPREL=23;
      DT_BIND_NOW=24;
      DT_INIT_ARRAY=25;
      DT_FINI_ARRAY=26;
      DT_INIT_ARRAYSZ=27;
      DT_FINI_ARRAYSZ=28;
      DT_RUNPATH=29;
      DT_FLAGS=30;
      DT_ENCODING=32;
      DT_PREINIT_ARRAY=32;
      DT_PREINIT_ARRAYSZ=33;
      DT_NUM=34;
      DT_LOOS=$6000000d;
      DT_HIOS=$6ffff000;
      DT_LOPROC=$70000000;
      DT_HIPROC=$7fffffff;
      DT_RELACOUNT=$6ffffff9;
      DT_RELCOUNT=$6ffffffa;
      DT_FLAGS_1=$6ffffffb;
      DT_VERDEF=$6ffffffc;
      DT_VERDEFNUM=$6ffffffd;
      DT_VERNEED=$6ffffffe;
      DT_VERNEEDNUM=$6fffffff;
      DT_VERSYM=$6ffffff0;

      GRP_COMDAT=1;

      DF_ORIGIN=1;
      DF_SYMBOLIC=2;
      DF_TEXTREL=4;
      DF_BIND_NOW=8;
      DF_STATIC_TLS=16;
      DF_1_NOW=$01;
      DF_1_GLOBAL=$02;
      DF_1_GROUP=$04;
      DF_1_NODELETE=$08;
      DF_1_LOADFLTR=$10;
      DF_1_INITFIRST=$20;
      DF_1_NOOPEN=$40;
      DF_1_ORIGIN=$80;
      DF_1_DIRECT=$100;
      DF_1_TRANS=$200;
      DF_1_INTERPOSE=$400;
      DF_1_NODEFLIB=$800;
      DF_1_NODUMP=$1000;
      DF_1_CONFALT=$2000;

      VERSYM_VERSION=$7fff;
      VERSYM_HIDDEN=$8000;

      VER_NDX_LOCAL=0;
      VER_NDX_GLOBAL=1;

      VER_DEF_CURRENT=1;

      VER_NEED_CURRENT=1;

      VER_FLG_BASE=1;
      VER_FLG_WEAK=2;
      VER_FLG_INFO=4;

      R_386_NONE=0;
      R_386_32=1;
      R_386_PC32=2;
      R_386_GOT32=3;
      R_386_PLT32=4;
      R_386_COPY=5;
      R_386_GLOB_DAT=6;
      R_386_JMP_SLOT=7;
      R_386_RELATIVE=8;
      R_386_GOTOFF=9;
      R_386_GOTPC=10;
      R_386_TLS_TPOFF=14;
      R_386_TLS_IE=15;
      R_386_TLS_GOTIE=16;
      R_386_TLS_LE=17;
      R_386_TLS_GD=18;
      R_386_TLS_LDM=19;
      R_386_16=20;
      R_386_PC16=21;
      R_386_8=22;
      R_386_PC8=23;
      R_386_TLS_GD_32=24;
      R_386_TLS_GD_PUSH=25;
      R_386_TLS_GD_CALL=26;
      R_386_TLS_GD_POP=27;
      R_386_TLS_LDM_32=28;
      R_386_TLS_LDM_PUSH=29;
      R_386_TLS_LDM_CALL=30;
      R_386_TLS_LDM_POP=31;
      R_386_TLS_LDO_32=32;
      R_386_TLS_IE_32=33;
      R_386_TLS_LE_32=34;
      R_386_TLS_DTPMOD32=35;
      R_386_TLS_DTPOFF32=36;
      R_386_TLS_TPOFF32=37;
      R_386_TLS_GOTDESC=39;
      R_386_TLS_DESC_CALL=40;
      R_386_TLS_DESC=41;

      R_X86_64_NONE=0;
      R_X86_64_64=1;
      R_X86_64_PC32=2;
      R_X86_64_GOT32=3;
      R_X86_64_PLT32=4;
      R_X86_64_COPY=5;
      R_X86_64_GLOB_DAT=6;
      R_X86_64_JMP_SLOT=7;
      R_X86_64_RELATIVE=8;
      R_X86_64_GOTPCREL=9;
      R_X86_64_32=10;
      R_X86_64_32S=11;
      R_X86_64_16=12;
      R_X86_64_PC16=13;
      R_X86_64_8=14;
      R_X86_64_PC8=15;
      R_X86_64_DPTMOD64=16;
      R_X86_64_DTPOFF64=17;
      R_X86_64_TPOFF64=18;
      R_X86_64_TLSGD=19;
      R_X86_64_TLSLD=20;
      R_X86_64_DTPOFF32=21;
      R_X86_64_GOTTPOFF=22;
      R_X86_64_TPOFF32=23;
      R_X86_64_PC64=24;
      R_X86_64_GOTOFF64=25;
      R_X86_64_GOTPC32=26;
      R_X86_64_GOT64=27;
      R_X86_64_GOTPCREL64=28;
      R_X86_64_GOTPC64=29;
      R_X86_64_GOTPLT64=30;
      R_X86_64_PLTOFF64=31;
      R_X86_64_GOTPC32_TLSDESC=34;
      R_X86_64_TLSDESC_CALL=35;
      R_X86_64_TLSDESC=36;

      EHDR32_SIZE=52;
      EHDR64_SIZE=64;
      EHDR_MAXSIZE=64;

      SHDR32_SIZE=40;
      SHDR64_SIZE=64;
      SHDR_MAXSIZE=64;

      SYMTAB32_SIZE=16;
      SYMTAB64_SIZE=24;
      SYMTAB_MAXSIZE=24;

      SYMTAB32_ALIGN=4;
      SYMTAB64_ALIGN=8;

      RELOC32_SIZE=8;
      RELOC32A_SIZE=12;
      RELOC64_SIZE=16;
      RELOC64A_SIZE=24;
      RELOC_MAXSIZE=24;

      RELOC32_ALIGN=4;
      RELOC64_ALIGN=8;

type PELFIdent=^TELFIdent;
     TELFIdent=packed array[0..15] of byte;

     PELFWord=^TELFWord;
     TELFWord=longword;

     PELFWords=^TELFWords;
     TELFWords=array[0..65535] of longword;

     PELFSWord=^TELFSWord;
     TELFSWord=longint;

     PELFSection=^TELFSection;
     TELFSection=record
      ToSymbolTable:boolean;
      Name:ansistring;
      SymbolIndex:longint;
      Data:TMemoryStream;
      sh_name:longword;
      sh_type:longword;
      sh_flags:uint64;
      sh_addr:uint64;
      sh_offset:uint64;
      sh_size:uint64;
      sh_link:longword;
      sh_info:longword;
      sh_addralign:uint64;
      sh_entsize:uint64;
     end;

     TELFSections=array of TELFSection;

var {CountELFRealSegments,CountELFRealSections,}CountELFSections,SymbolIndex,
    LocalGlobalSymbolPassIndex,FirstNonLocalSymbolIndex,
    Index,SHStrTabIndex,StrTabIndex,SymTabIndex,Counter:longint;
    ELFSections:TELFSections;
    SHStrTabStream,StrTabStream,SymTabStream,RelocationStream:TMemoryStream;
    SectionFlags,SectionHeaderOffset,SectionHeaderCount,Address,Info:uint64;
    AddEnd:int64;
    StrTabStringIntegerPairHashMap:TStringIntegerPairHashMap;
    ELF64:longbool;
    //Segment:PAssemblerSegment;
    Section:PAssemblerSection;
    Symbol:TUserSymbol;
    ELFSection:PELFSection;
    Flags:longword;
    FixUpExpression:PFixUpExpression;
    FixUpExpressionFlags:TFixUpExpressionFlags;
    FileName:ansistring;

 function AddELFSection(const ToSymbolTable:boolean;
                        const Name:ansistring;
                        const sh_type:longword;
                        const sh_flags:uint64;
                        const sh_addr:uint64;
                        const sh_link:longword;
                        const sh_info:longword;
                        const sh_addralign:uint64;
                        const sh_entsize:uint64;
                        const Data:TStream):longint;
 var ELFSection:PELFSection;
 begin
  result:=CountELFSections;
  inc(CountELFSections);
  if CountELFSections>length(ELFSections) then begin
   SetLength(ELFSections,CountELFSections*2);
  end;
  ELFSection:=@ELFSections[result];
  ELFSection^.ToSymbolTable:=ToSymbolTable;
  ELFSection^.Name:=Name;
  ELFSection^.SymbolIndex:=-1;
  ELFSection^.sh_name:=SHStrTabStream.Position;
  if length(Name)>0 then begin
   SHStrTabStream.Write(Name[1],length(Name)*SizeOf(AnsiChar));
  end;
  StreamWriteByte(SHStrTabStream,0);
  ELFSection^.sh_type:=sh_type;
  ELFSection^.sh_flags:=sh_flags;
  ELFSection^.sh_addr:=sh_addr;
  ELFSection^.sh_offset:=0;
  ELFSection^.sh_size:=0;
  ELFSection^.sh_link:=sh_link;
  ELFSection^.sh_info:=sh_info;
  ELFSection^.sh_addralign:=sh_addralign;
  ELFSection^.sh_entsize:=sh_entsize;
  ELFSection^.Data:=TMemoryStream.Create;
  if assigned(Data) then begin
   Data.Seek(0,soBeginning);
   ELFSection^.Data.CopyFrom(Data,Data.Size);
   Data.Seek(Data.Size,soBeginning);
  end;
 end;

 procedure WriteHeader(const DestStream:TStream);
 begin
  StreamWriteByte(DestStream,$7f);
  StreamWriteByte(DestStream,ord('E'));
  StreamWriteByte(DestStream,ord('L'));
  StreamWriteByte(DestStream,ord('F'));
  if ELF64 then begin
   StreamWriteByte(DestStream,ELFCLASS64);               // elf class
   StreamWriteByte(DestStream,ELFDATA2LSB);              // data encoding
   StreamWriteByte(DestStream,EV_CURRENT);               // elf version
   StreamWriteByte(DestStream,ELFOSABI_SYSV);            // os/abi
   StreamWriteByte(DestStream,0);                        // SYSV v3 ABI=0
   StreamWriteByteCount(DestStream,0,EI_NIDENT-9);       // e_ident padding
   StreamWriteWord(DestStream,ET_REL);                   // e_type - object file
   StreamWriteWord(DestStream,EM_X86_64);                // e_machine - or others
   StreamWriteDWord(DestStream,EV_CURRENT);              // elf version
   StreamWriteQWord(DestStream,0);                       // e_entry
   StreamWriteQWord(DestStream,0);                       // e_phoff
   StreamWriteQWord(DestStream,SectionHeaderOffset);     // e_shoff secthead off
   StreamWriteDWord(DestStream,0);                       // e_flags
   StreamWriteWord(DestStream,EHDR64_SIZE);              // e_ehsize
   StreamWriteWord(DestStream,0);                        // e_phentsize
   StreamWriteWord(DestStream,0);                        // e_phnum
   StreamWriteWord(DestStream,SHDR64_SIZE);              // e_shentsize
  end else begin
   StreamWriteByte(DestStream,ELFCLASS32);               // elf class
   StreamWriteByte(DestStream,ELFDATA2LSB);              // data encoding
   StreamWriteByte(DestStream,EV_CURRENT);               // elf version
   if Is64Bit then begin
    StreamWriteByte(DestStream,ELFOSABI_SYSV);           // os/abi
    StreamWriteByte(DestStream,0);                       // SYSV v3 ABI=0
    StreamWriteByteCount(DestStream,0,EI_NIDENT-9);      // e_ident padding
   end else begin
    StreamWriteByteCount(DestStream,0,EI_NIDENT-7);      // e_ident padding
   end;
   StreamWriteWord(DestStream,ET_REL);                   // e_type - object file
   if Is64Bit then begin
    StreamWriteWord(DestStream,EM_X86_64);               // e_machine - or others
   end else begin
    StreamWriteWord(DestStream,EM_386);                  // e_machine - or others
   end;
   StreamWriteDWord(DestStream,EV_CURRENT);              // elf version
   StreamWriteDWord(DestStream,0);                       // e_entry
   StreamWriteDWord(DestStream,0);                       // e_phoff
   StreamWriteDWord(DestStream,SectionHeaderOffset);     // e_shoff secthead off
   StreamWriteDWord(DestStream,0);                       // e_flags
   StreamWriteWord(DestStream,EHDR32_SIZE);              // e_ehsize
   StreamWriteWord(DestStream,0);                        // e_phentsize
   StreamWriteWord(DestStream,0);                        // e_phnum
   StreamWriteWord(DestStream,SHDR32_SIZE);              // e_shentsize
  end;
  StreamWriteWord(DestStream,SectionHeaderCount);        // e_shnum
  StreamWriteWord(DestStream,SHStrTabIndex);             // e_shstrndx
 end;

 procedure WriteAlignment(const DestStream:TStream;const Alignment:int64);
 var p:int64;
 begin
  p:=DestStream.Position;
  if (p and (Alignment-1))<>0 then begin
   StreamWriteByteCount(DestStream,0,Alignment-(p and (Alignment-1)));
  end;
 end;

 function GetStrTabName(const Name:ansistring):longint;
 begin
  if length(Name)>0 then begin
   result:=StrTabStringIntegerPairHashMap.GetValue(Name);
   if result<0 then begin
    result:=StrTabStream.Position;
    if length(Name)>0 then begin
     StrTabStream.Write(Name[1],length(Name)*SizeOf(AnsiChar));
    end;
    StreamWriteByte(StrTabStream,0);
    StrTabStringIntegerPairHashMap.SetValue(Name,result);
   end;
  end else begin
   result:=0;
  end;
 end;

begin
 result:=false;
 if assigned(Stream) then begin

  StartOffset:=0;
  Generate;

  FixUpPass:=FUP_ELF;
  PostProcessFixUpExpressions;
  PostProcessSymbols;
  FixUpPass:=FUP_NONE;

  ELF64:=Is64Bit and not IsX32;

{ CountELFRealSegments:=CountSegments;
  CountELFRealSections:=CountSections;}

  ShowStatus('Write image');
  if Stream is TMemoryStream then begin
   TMemoryStream(Stream).Clear;
  end;
  Stream.Size:=0;
  Stream.Seek(0,soBeginning);

  ELFSections:=nil;
  CountELFSections:=0;
  try
                                       
   SHStrTabStream:=TMemoryStream.Create;
   try

    StrTabStringIntegerPairHashMap:=TStringIntegerPairHashMap.Create;
    try

     StreamWriteByte(SHStrTabStream,0);

     AddELFSection(false,'',SHT_NULL,0,0,0,0,0,0,nil);

     Counter:=0;
     Section:=StartSection;
     while assigned(Section) do begin
      Section^.ObjectSectionIndex:=AddELFSection(true,Section^.Name,SHT_PROGBITS,IntegerValueGetQWord(Section^.FreezedFlags),0,0,0,16,0,Section^.Data);
      Section^.Index:=Counter;
      inc(Counter);
      Section:=Section^.Next;
     end;

     SHStrTabIndex:=AddELFSection(false,'.shstrtab',SHT_STRTAB,0,0,0,0,1,0,nil);

     StrTabIndex:=CountELFSections+1;

     if ELF64 then begin
      SymTabIndex:=AddELFSection(false,'.symtab',SHT_SYMTAB,0,0,StrTabIndex,0,SYMTAB64_ALIGN,SYMTAB64_SIZE,nil);
     end else begin
      SymTabIndex:=AddELFSection(false,'.symtab',SHT_SYMTAB,0,0,StrTabIndex,0,SYMTAB32_ALIGN,SYMTAB32_SIZE,nil);
     end;

     StrTabIndex:=AddELFSection(false,'.strtab',SHT_STRTAB,0,0,0,0,1,0,nil);

     Counter:=0;
     Section:=StartSection;
     while assigned(Section) do begin
      if Section^.RelocationFixUpExpressions.Count>0 then begin
       if Is64Bit then begin
        if IsX32 then begin
         Section^.ObjectSectionRelocationIndex:=AddELFSection(false,'.rela'+Section^.Name,SHT_RELA,0,0,SymTabIndex,Section^.ObjectSectionIndex,RELOC32_ALIGN,RELOC32A_SIZE,nil);
        end else begin
         Section^.ObjectSectionRelocationIndex:=AddELFSection(false,'.rela'+Section^.Name,SHT_RELA,0,0,SymTabIndex,Section^.ObjectSectionIndex,RELOC64_ALIGN,RELOC64A_SIZE,nil);
        end;
       end else begin
        Section^.ObjectSectionRelocationIndex:=AddELFSection(false,'.rel'+Section^.Name,SHT_REL,0,0,SymTabIndex,Section^.ObjectSectionIndex,RELOC32_ALIGN,RELOC32_SIZE,nil);
       end;
      end else begin
       Section^.ObjectSectionRelocationIndex:=-1;
      end;
      Section^.Index:=Counter;
      inc(Counter);
      Section:=Section^.Next;
     end;

     ELFSection:=@ELFSections[SHStrTabIndex];
     ELFSection^.Data.Seek(0,soBeginning);
     ELFSection^.Data.LoadFromStream(SHStrTabStream);
     ELFSection^.Data.Seek(ELFSection^.Data.Size,soBeginning);
     FreeAndNil(SHStrTabStream);

     begin

      StrTabStream:=ELFSections[StrTabIndex].Data;

      StreamWriteByte(StrTabStream,0);

      SymTabStream:=ELFSections[SymTabIndex].Data;

      SymbolIndex:=0;

      FirstNonLocalSymbolIndex:=-1;

      if ELF64 then begin
       StreamWriteByteCount(SymTabStream,0,SYMTAB64_SIZE);
      end else begin
       StreamWriteByteCount(SymTabStream,0,SYMTAB32_SIZE);
      end;

      inc(SymbolIndex);

      begin
       if FileStringList.Count>0 then begin
        FileName:=FileStringList[0];
       end else begin
        FileName:=CurrentFileName;
       end;
       StreamWriteDWord(SymTabStream,GetStrTabName(FileName)); // st_name
       if not ELF64 then begin
        StreamWriteDWord(SymTabStream,0); // st_value
        StreamWriteDWord(SymTabStream,0); // st_size
       end;
       StreamWriteByte(SymTabStream,(STB_LOCAL shl 4) or STT_FILE); // st_info
       StreamWriteByte(SymTabStream,0); // st_other
       StreamWriteWord(SymTabStream,SHN_ABS); // st_shndx
       if ELF64 then begin
        StreamWriteQWord(SymTabStream,0); // st_value
        StreamWriteQWord(SymTabStream,0); // st_size
       end;
      end;

      inc(SymbolIndex);

      for Index:=1 to CountELFSections-1 do begin
       ELFSection:=@ELFSections[Index];
       if ELFSection^.ToSymbolTable then begin
        ELFSection^.SymbolIndex:=SymbolIndex;
        StreamWriteDWord(SymTabStream,0{GetStrTabName(ELFSection^.Name)}); // st_name
        if not ELF64 then begin
         StreamWriteDWord(SymTabStream,0); // st_value
         StreamWriteDWord(SymTabStream,0); // st_size
        end;
        StreamWriteByte(SymTabStream,(STB_LOCAL shl 4) or STT_SECTION); // st_info
        StreamWriteByte(SymTabStream,0); // st_other
        StreamWriteWord(SymTabStream,Index); // st_shndx
        if ELF64 then begin
         StreamWriteQWord(SymTabStream,0); // st_value
         StreamWriteQWord(SymTabStream,0); // st_size
        end;
        inc(SymbolIndex);
       end;
      end;

      // First all local symbols, then all global symbols
      for LocalGlobalSymbolPassIndex:=0 to 1 do begin
       for Index:=0 to UserSymbolList.Count-1 do begin
        Symbol:=UserSymbolList[Index];
        if Symbol.NeedSymbol then begin
         if (LocalGlobalSymbolPassIndex<>0) xor (Symbol.IsExternal or Symbol.IsPublic) then begin
          continue;
         end;
         if Symbol.IsExternal or Symbol.IsPublic then begin
          if FirstNonLocalSymbolIndex<0 then begin
           FirstNonLocalSymbolIndex:=SymbolIndex;
          end;
         end;
         Symbol.ObjectSymbolIndex:=SymbolIndex;
         inc(SymbolIndex);
         StreamWriteDWord(SymTabStream,GetStrTabName(Symbol.OriginalName)); // st_name
         if not ELF64 then begin
          if Symbol.IsExternal then begin
           StreamWriteDWord(SymTabStream,0); // st_value
           StreamWriteDWord(SymTabStream,0); // st_size
          end else begin
           StreamWriteDWord(SymTabStream,Symbol.Position); // st_value
           StreamWriteDWord(SymTabStream,0); // st_size
          end;
         end;
         if Symbol.IsExternal then begin
 //       Flags:=(STB_WEAK shl 4) or STT_NOTYPE;
          Flags:=(STB_GLOBAL shl 4) or STT_NOTYPE;
         end else if Symbol.IsPublic then begin
          Flags:=(STB_GLOBAL shl 4) or STT_NOTYPE;
         end else begin
          Flags:=(STB_LOCAL shl 4) or STT_NOTYPE;
         end;
         if assigned(Symbol.Section) then begin
          SectionFlags:=IntegerValueGetQWord(Symbol.Section^.FreezedFlags);
          if (SectionFlags and SHF_TLS)<>0 then begin
           Flags:=(Flags and $f0) or STT_TLS;
 {        end else if (SectionFlags and SHF_EXECINSTR)<>0 then begin
           Flags:=(Flags and $f0) or STT_FUNC;
          end else if (SectionFlags and SHF_WRITE)<>0 then begin
           Flags:=(Flags and $f0) or STT_OBJECT; {}
          end;
         end;
         StreamWriteByte(SymTabStream,Flags); // st_info
         StreamWriteByte(SymTabStream,STV_DEFAULT); // st_other
         if assigned(Symbol.Section) then begin
          StreamWriteWord(SymTabStream,Symbol.Section.ObjectSectionIndex); // st_shndx
         end else begin
          StreamWriteWord(SymTabStream,0); // st_shndx
         end;
         if ELF64 then begin
          if Symbol.IsExternal then begin
           StreamWriteQWord(SymTabStream,0); // st_value
           StreamWriteQWord(SymTabStream,0); // st_size
          end else begin
           StreamWriteQWord(SymTabStream,Symbol.Position); // st_value
           StreamWriteQWord(SymTabStream,0); // st_size
          end;
         end;
        end;
       end;
      end;

      // Symbol table section's sh_info section header member holds the symbol table index for the first non-local symbol
      ELFSections[SymTabIndex].sh_info:=FirstNonLocalSymbolIndex;

     end;

     Section:=StartSection;
     while assigned(Section) do begin
      if Section^.ObjectSectionRelocationIndex>=0 then begin
       ELFSection:=@ELFSections[Section^.ObjectSectionRelocationIndex];
       RelocationStream:=ELFSection^.Data;
       for Index:=0 to Section^.RelocationFixUpExpressions.Count-1 do begin
        FixUpExpression:=Section^.RelocationFixUpExpressions[Index];
        FixUpExpressionFlags:=FixUpExpression^.Flags;
        Symbol:=FixUpExpression^.Symbol;
        Address:=FixUpExpression^.Position;
        Info:=0;
        AddEnd:=0;
        if FixUpExpression^.Relative then begin
         // Relative
         if Is64Bit then begin
          // 64-bit
          case FixUpExpression^.Bits of
           8:begin
            if (FixUpExpressionFlags and (FUEF_SEG16 or FUEF_OFS16 or FUEF_GOT or FUEF_GOTPC or FUEF_GOTOFF or FUEF_GOTTPOFF or FUEF_PLT or FUEF_TLSIE or FUEF_NOBASE))<>0 then begin
             MakeError('Unsupported relocation type for ELF');
            end else begin
             Info:=R_X86_64_PC8;
             AddEnd:=0;
            end;
           end;
           16:begin
            if (FixUpExpressionFlags and (FUEF_SEG16 or FUEF_OFS16 or FUEF_GOT or FUEF_GOTPC or FUEF_GOTOFF or FUEF_GOTTPOFF or FUEF_PLT or FUEF_TLSIE or FUEF_NOBASE))<>0 then begin
             MakeError('Unsupported relocation type for ELF');
            end else begin
             Info:=R_X86_64_PC16;
             AddEnd:=0;
            end;
           end;
           32:begin
            if (FixUpExpressionFlags and (FUEF_GOTPC or FUEF_GOT))<>0 then begin
             Info:=R_X86_64_GOTPCREL;
             AddEnd:=0;
            end else if (FixUpExpressionFlags and FUEF_PLT)<>0 then begin
             Info:=R_X86_64_PLT32;
             AddEnd:=0;
            end else if (FixUpExpressionFlags and FUEF_GOTTPOFF)<>0 then begin
             Info:=R_X86_64_GOTTPOFF;
             AddEnd:=0;
            end else if (FixUpExpressionFlags and (FUEF_SEG16 or FUEF_OFS16 or FUEF_GOT or FUEF_GOTPC or FUEF_GOTOFF or FUEF_GOTTPOFF or FUEF_PLT or FUEF_TLSIE or FUEF_NOBASE))<>0 then begin
             MakeError('Unsupported relocation type for ELF');
            end else begin
             Info:=R_X86_64_PC32;
             AddEnd:=0;
            end;
           end;
           64:begin
            if (FixUpExpressionFlags and (FUEF_GOTPC or FUEF_GOT))<>0 then begin
             Info:=R_X86_64_GOTPCREL64;
             AddEnd:=0;
            end else  if (FixUpExpressionFlags and (FUEF_SEG16 or FUEF_OFS16 or FUEF_GOT or FUEF_GOTPC or FUEF_GOTOFF or FUEF_GOTTPOFF or FUEF_PLT or FUEF_TLSIE or FUEF_NOBASE))<>0 then begin
             MakeError('Unsupported relocation type for ELF');
            end else begin
             Info:=R_X86_64_PC64;
             AddEnd:=0;
            end;
           end;
           else begin
            MakeError('Unsupported relocation type for ELF');
           end;
          end;
         end else begin
          // 32-bit
          case FixUpExpression^.Bits of
           8:begin
            if (FixUpExpressionFlags and (FUEF_SEG16 or FUEF_OFS16 or FUEF_GOT or FUEF_GOTPC or FUEF_GOTOFF or FUEF_GOTTPOFF or FUEF_PLT or FUEF_TLSIE or FUEF_NOBASE))<>0 then begin
             MakeError('Unsupported relocation type for ELF');
            end else begin
             MakeWarning('8-bit relocations in ELF32 are a GNU extension');
             Info:=R_386_PC8;
             AddEnd:=0;
            end;
           end;
           16:begin
            if (FixUpExpressionFlags and (FUEF_SEG16 or FUEF_OFS16 or FUEF_GOT or FUEF_GOTPC or FUEF_GOTOFF or FUEF_GOTTPOFF or FUEF_PLT or FUEF_TLSIE or FUEF_NOBASE))<>0 then begin
             MakeError('Unsupported relocation type for ELF');
            end else begin
             MakeWarning('16-bit relocations in ELF32 are a GNU extension');
             Info:=R_386_PC16;
             AddEnd:=0;
            end;
           end;
           32:begin
            if (FixUpExpressionFlags and FUEF_PLT)<>0 then begin
             Info:=R_386_PLT32;
             AddEnd:=0;
            end else if (FixUpExpressionFlags and (FUEF_SEG16 or FUEF_OFS16 or FUEF_GOT or FUEF_GOTPC or FUEF_GOTOFF or FUEF_GOTTPOFF or FUEF_PLT or FUEF_TLSIE or FUEF_NOBASE))<>0 then begin
             MakeError('Unsupported relocation type for ELF');
            end else begin
             Info:=R_386_PC32;
             AddEnd:=0;
            end;
           end;
           64:begin
            MakeError('ELF32 doesn''t support 64-bit relocations');
           end;
           else begin
            MakeError('Unsupported relocation type for ELF');
           end;
          end;
         end;
        end else begin
         // Absolute
         if Is64Bit then begin
          // 64-bit
          case FixUpExpression^.Bits of
           8:begin
            if (FixUpExpressionFlags and (FUEF_SEG16 or FUEF_OFS16 or FUEF_GOT or FUEF_GOTPC or FUEF_GOTOFF or FUEF_GOTTPOFF or FUEF_PLT or FUEF_TLSIE or FUEF_NOBASE))<>0 then begin
             MakeError('Unsupported relocation type for ELF');
            end else begin
             Info:=R_X86_64_8;
             AddEnd:=0;
            end;
           end;
           16:begin
            if (FixUpExpressionFlags and (FUEF_SEG16 or FUEF_OFS16 or FUEF_GOT or FUEF_GOTPC or FUEF_GOTOFF or FUEF_GOTTPOFF or FUEF_PLT or FUEF_TLSIE or FUEF_NOBASE))<>0 then begin
             MakeError('Unsupported relocation type for ELF');
            end else begin
             Info:=R_X86_64_16;
             AddEnd:=0;
            end;
           end;
           32:begin
            if (FixUpExpressionFlags and FUEF_GOT)<>0 then begin
             Info:=R_X86_64_GOT32;
             AddEnd:=0;
            end else if (FixUpExpressionFlags and FUEF_GOTPC)<>0 then begin
             Info:=R_X86_64_GOTPC32;
             AddEnd:=0;
            end else if (FixUpExpressionFlags and (FUEF_SEG16 or FUEF_OFS16 or FUEF_GOT or FUEF_GOTPC or FUEF_GOTOFF or FUEF_GOTTPOFF or FUEF_PLT or FUEF_TLSIE or FUEF_NOBASE))<>0 then begin
             MakeError('Unsupported relocation type for ELF');
            end else begin
             Info:=R_X86_64_32;
             AddEnd:=0;
            end;
           end;
           64:begin
            if (FixUpExpressionFlags and FUEF_GOT)<>0 then begin
             Info:=R_X86_64_GOT64;
             AddEnd:=0;
            end else if (FixUpExpressionFlags and FUEF_GOTPC)<>0 then begin
             Info:=R_X86_64_GOTPC64;
             AddEnd:=0;
            end else if (FixUpExpressionFlags and FUEF_GOTOFF)<>0 then begin
             Info:=R_X86_64_GOTOFF64;
             AddEnd:=0;
            end else if (FixUpExpressionFlags and (FUEF_SEG16 or FUEF_OFS16 or FUEF_GOT or FUEF_GOTPC or FUEF_GOTOFF or FUEF_GOTTPOFF or FUEF_PLT or FUEF_TLSIE or FUEF_NOBASE))<>0 then begin
             MakeError('Unsupported relocation type for ELF');
            end else begin
             Info:=R_X86_64_64;
             AddEnd:=0;
            end;
           end;
           else begin
            MakeError('Unsupported relocation type for ELF');
           end;
          end;
         end else begin
          // 32-bit
          case FixUpExpression^.Bits of
           8:begin
            if (FixUpExpressionFlags and (FUEF_SEG16 or FUEF_OFS16 or FUEF_GOT or FUEF_GOTPC or FUEF_GOTOFF or FUEF_GOTTPOFF or FUEF_PLT or FUEF_TLSIE or FUEF_NOBASE))<>0 then begin
             MakeError('Unsupported relocation type for ELF');
            end else begin
             MakeWarning('8-bit relocations in ELF32 are a GNU extension');
             Info:=R_386_8;
             AddEnd:=0;
            end;
           end;
           16:begin
            if (FixUpExpressionFlags and (FUEF_SEG16 or FUEF_OFS16 or FUEF_GOT or FUEF_GOTPC or FUEF_GOTOFF or FUEF_GOTTPOFF or FUEF_PLT or FUEF_TLSIE or FUEF_NOBASE))<>0 then begin
             MakeError('Unsupported relocation type for ELF');
            end else begin
             MakeWarning('16-bit relocations in ELF32 are a GNU extension');
             Info:=R_386_16;
             AddEnd:=0;
            end;
           end;
           32:begin
            if (FixUpExpressionFlags and FUEF_GOT)<>0 then begin
             Info:=R_386_GOT32;
             AddEnd:=0;
            end else if (FixUpExpressionFlags and FUEF_GOTPC)<>0 then begin
             Info:=R_386_GOTPC;
             AddEnd:=0;
            end else if (FixUpExpressionFlags and FUEF_GOTOFF)<>0 then begin
             Info:=R_386_GOTOFF;
             AddEnd:=0;
            end else if (FixUpExpressionFlags and FUEF_TLSIE)<>0 then begin
             Info:=R_386_TLS_IE;
             AddEnd:=0;
            end else if (FixUpExpressionFlags and (FUEF_SEG16 or FUEF_OFS16 or FUEF_GOT or FUEF_GOTPC or FUEF_GOTOFF or FUEF_GOTTPOFF or FUEF_PLT or FUEF_TLSIE or FUEF_NOBASE))<>0 then begin
             MakeError('Unsupported relocation type for ELF');
            end else begin
             Info:=R_386_32;
             AddEnd:=0;
            end;
           end;
           64:begin
            MakeError('ELF32 doesn''t support 64-bit relocations');
           end;
           else begin
            MakeError('Unsupported relocation type for ELF');
           end;
          end;
         end;
        end;
        if assigned(FixUpExpression^.Symbol) then begin
         Info:=Info or (uint64(FixUpExpression^.Symbol.ObjectSymbolIndex) shl 32);
        end else if assigned(Section) then begin
         if ELFSections[Section^.ObjectSectionIndex].SymbolIndex>=0 then begin
          Info:=Info or (uint64(ELFSections[Section^.ObjectSectionIndex].SymbolIndex) shl 32);
         end else begin
          MakeError('Unsupported relocation type for ELF');
         end;
        end;
        if ELF64 then begin
         StreamWriteQWord(RelocationStream,Address);
         StreamWriteQWord(RelocationStream,Info);
         StreamWriteInt64(RelocationStream,AddEnd);
        end else begin
         StreamWriteDWord(RelocationStream,Address);
         StreamWriteDWord(RelocationStream,(Info and $ff) or ((Info shr 24) and longword($ffffff00))); // from (bit 0-31: type, 32-63: symbol) to (bit 0-7: type, 8-31: symbol)
         if Is64Bit then begin
          StreamWriteLongInt(RelocationStream,AddEnd);
         end;
        end;
       end;
      end;
      Section:=Section^.Next;
     end;

     // Write dummy header
     if ELF64 then begin
      StreamWriteByteCount(Stream,0,EHDR64_SIZE);
     end else begin
      StreamWriteByteCount(Stream,0,EHDR32_SIZE);
     end;
     WriteAlignment(Stream,16);

     SectionHeaderOffset:=Stream.Position;
     SectionHeaderCount:=CountELFSections;

     // Write dummy section headers
     for Index:=0 to CountELFSections-1 do begin
      if ELF64 then begin
       StreamWriteByteCount(Stream,0,SHDR64_SIZE);
      end else begin
       StreamWriteByteCount(Stream,0,SHDR32_SIZE);
      end;
     end;

     // Write real sections
     for Index:=0 to CountELFSections-1 do begin
      ELFSection:=@ELFSections[Index];
      WriteAlignment(Stream,16);
      if assigned(ELFSection^.Data) and (ELFSection^.Data.Size>0) then begin
       ELFSection^.sh_offset:=Stream.Position;
       ELFSection^.sh_size:=ELFSection^.Data.Size;
       ELFSection^.Data.Seek(0,soBeginning);
       Stream.CopyFrom(ELFSection^.Data,ELFSection^.Data.Size);
      end else begin
       ELFSection^.sh_offset:=0;
       ELFSection^.sh_size:=0;
      end;
     end;

     // Write real section headers
     Stream.Seek(SectionHeaderOffset,soBeginning);
     for Index:=0 to CountELFSections-1 do begin
      ELFSection:=@ELFSections[Index];
      StreamWriteDWord(Stream,ELFSection^.sh_name);
      StreamWriteDWord(Stream,ELFSection^.sh_type);
      if ELF64 then begin
       StreamWriteQWord(Stream,ELFSection^.sh_flags);
       StreamWriteQWord(Stream,ELFSection^.sh_addr);
       StreamWriteQWord(Stream,ELFSection^.sh_offset);
       StreamWriteQWord(Stream,ELFSection^.sh_size);
      end else begin
       StreamWriteDWord(Stream,ELFSection^.sh_flags);
       StreamWriteDWord(Stream,ELFSection^.sh_addr);
       StreamWriteDWord(Stream,ELFSection^.sh_offset);
       StreamWriteDWord(Stream,ELFSection^.sh_size); 
      end;
      StreamWriteDWord(Stream,ELFSection^.sh_link);
      StreamWriteDWord(Stream,ELFSection^.sh_info);
      if ELF64 then begin
       StreamWriteQWord(Stream,ELFSection^.sh_addralign);
       StreamWriteQWord(Stream,ELFSection^.sh_entsize);
      end else begin
       StreamWriteDWord(Stream,ELFSection^.sh_addralign);
       StreamWriteDWord(Stream,ELFSection^.sh_entsize);
      end;
     end;

     // Write real header
     Stream.Seek(0,soBeginning);
     WriteHeader(Stream);
     Stream.Seek(Stream.Size,soBeginning);

    finally
     StrTabStringIntegerPairHashMap.Free;
    end;

   finally
    SHStrTabStream.Free;
   end;

  finally
   for Index:=0 to CountELFSections-1 do begin
    ELFSections[Index].Data.Free;
   end;
   SetLength(ELFSections,0);
  end;

  result:=((Stream.Size<>0) or (TotalSize=0)) and not AreErrors;
 end;
end;

function TAssembler.WriteOMF(const Stream:TStream;const Is32Bit:boolean):boolean;
const RECORD_MAX=1024-3;
      OBJ_PARMS=3;

      FIX_08_LOW=$8000;
      FIX_16_OFFSET=$400;
      FIX_16_SELECTOR=$8800;
      FIX_32_POINTER=$8c00;
      FIX_08_HIGH=$9000;
      FIX_32_OFFSET=$a400;
      FIX_48_POINTER=$ac00;

      THEADR=$80;
      COMENT=$88;
      LINNUM=$94;
      LNAMES=$96;
      SEGDEF=$98;
      GRPDEF=$9a;
      EXTDEF=$8c;
      PUBDEF=$90;
      COMDEF=$b0;
      LEDATA=$a0;
      FIXUPP=$9c;
      FIXU32=$9d;
      MODEND=$8a;
      MODE32=$8b;

      dEXTENDED=$a1;
      dLINKPASS=$a2;
      dTYPEDEF=$e3;
      dSYM=$e6;
      dFILNAME=$e8;
      dCOMPDEF=$ea;

type POMFRecord=^TOMFRecord;
     TOMFRecord=record
      RecordType:byte;
      RecordData:TMemoryStream;
     end;

var OMFRecords:TList;

 procedure WriteRecord(const DestStream:TStream;const OMFRecord:POMFRecord);
 var Position,Size:longint;
     CheckSum:byte;
 begin
  StreamWriteByte(DestStream,OMFRecord^.RecordType);
  Size:=OMFRecord^.RecordData.Size;
  StreamWriteWord(DestStream,Size+1);
  OMFRecord^.RecordData.Seek(0,soBeginning);
  DestStream.CopyFrom(OMFRecord^.RecordData,Size);
  OMFRecord^.RecordData.Seek(Size,soBeginning);
  CheckSum:=OMFRecord^.RecordType+(Size and $ff)+((Size shr 8) and $ff);
  for Position:=0 to Size-1 do begin
   inc(CheckSum,byte(ansichar(PAnsiChar(OMFRecord^.RecordData.Memory)[Position])));
  end;
  StreamWriteByte(DestStream,-CheckSum);
 end;

 function NewRecord(const RecordType:byte):POMFRecord;
 begin
  GetMem(result,SizeOf(TOMFRecord));
  result^.RecordType:=RecordType;
  result^.RecordData:=TMemoryStream.Create;
  OMFRecords.Add(result);
 end;

 procedure CreateTHEADR;
 var OMFRecord:POMFRecord;
     FileName:ansistring;
     Size:longint;
 begin
  if FileStringList.Count>0 then begin
   FileName:=FileStringList[0];
  end else begin
   FileName:=CurrentFileName;
  end;
  Size:=Min(length(FileName),255);
  OMFRecord:=NewRecord(THEADR);
  StreamWriteByte(OMFRecord^.RecordData,Size);
  if Size>0 then begin
   OMFRecord^.RecordData.Write(FileName[1],Size);
  end;
 end;

 procedure CreateCOMENTString(const Data:ansistring);
 var OMFRecord:POMFRecord;
     Size:longint;
 begin
  Size:=Min(length(Data),255);
  OMFRecord:=NewRecord(COMENT);
  StreamWriteByte(OMFRecord^.RecordData,$00);
  StreamWriteByte(OMFRecord^.RecordData,$00);
  if Size>0 then begin
   OMFRecord^.RecordData.Write(Data[1],Size);
  end;
 end;

 procedure WriteString(const OMFRecord:POMFRecord;const Data:ansistring);
 var Size:longint;
 begin
  Size:=length(Data);
  if Size>0 then begin
   OMFRecord^.RecordData.Write(Data[1],Size);
  end;
 end;

var Index:longint;
    OMFRecord:POMFRecord;
    //Symbol:TUserSymbol;
    ImportItem:TAssemblerImportItem;
    //ImportLibraryItem:TAssemblerImportLibraryItem;
    ExportItem:TAssemblerExportItem;
begin
 result:=false;
 if assigned(Stream) then begin

  StartOffset:=0;
  Generate;

  FixUpPass:=FUP_OMF;
  PostProcessFixUpExpressions;
  PostProcessSymbols;
  FixUpPass:=FUP_NONE;

  ShowStatus('Write image');
  if Stream is TMemoryStream then begin
   TMemoryStream(Stream).Clear;
  end;
  Stream.Size:=0;
  Stream.Seek(0,soBeginning);

  OMFRecords:=TList.Create;
  try

   CreateTHEADR;

   CreateCOMENTString('SASM'#0);

   for Index:=0 to ImportList.Count-1 do begin
    ImportItem:=ImportList.Items[Index];
    if assigned(ImportItem.ImportLibrary) then begin
     //ImportLibraryItem:=ImportItem.ImportLibrary;
     OMFRecord:=NewRecord(COMENT);
     StreamWriteByte(OMFRecord^.RecordData,$00);
     StreamWriteByte(OMFRecord^.RecordData,$a0); // comment class A0
     StreamWriteByte(OMFRecord^.RecordData,$01); // subfunction 1: IMPDEF
     StreamWriteByte(OMFRecord^.RecordData,$00); // import by name
     WriteString(OMFRecord,ImportItem.Name+#0);
     WriteString(OMFRecord,ImportItem.ImportLibrary.Name+#0);
     if assigned(ImportItem.Symbol) then begin
      WriteString(OMFRecord,ImportItem.Symbol.Name+#0);
     end else begin
      WriteString(OMFRecord,#0);
     end;
    end;
   end;

   for Index:=0 to ExportList.Count-1 do begin
    ExportItem:=ExportList.Items[Index];
    OMFRecord:=NewRecord(COMENT);
    StreamWriteByte(OMFRecord^.RecordData,$00);
    StreamWriteByte(OMFRecord^.RecordData,$a0); // comment class A0
    StreamWriteByte(OMFRecord^.RecordData,$02); // subfunction 1: EXPDEF
    StreamWriteByte(OMFRecord^.RecordData,$00); // flags
    WriteString(OMFRecord,ExportItem.Name+#0);
    if assigned(ExportItem.Symbol) then begin
     WriteString(OMFRecord,ExportItem.Symbol.Name+#0);
    end else begin
     WriteString(OMFRecord,#0);
    end;
   end;

   for Index:=0 to OMFRecords.Count-1 do begin
    WriteRecord(Stream,OMFRecords[Index]);
   end;

  finally
   for Index:=0 to OMFRecords.Count-1 do begin
    OMFRecord:=OMFRecords[Index];
    OMFRecord^.RecordData.Free;
    FreeMem(OMFRecord);
   end;
   OMFRecords.Free;
  end;

  result:=((Stream.Size<>0) or (TotalSize=0)) and not AreErrors;
 end;
end;

function TAssembler.WriteTRI(const Stream:TStream):boolean;
var i:longint;
 function CountRelocations:longint;
 var FixUpExpression:PFixUpExpression;
     //SymbolIndex:longint;
     Symbol:TUserSymbol;
 begin
  result:=0;
  FixUpExpression:=StartFixUpExpression;
  while assigned(FixUpExpression) do begin
   if FixUpExpression^.Bits=32 then begin
    Symbol:=FixUpExpression^.Expression.GetFixUpSymbol(self);
    if assigned(Symbol) and ((Symbol.SymbolType in [ustLABEL,ustIMPORT]) or (Symbol.IsExternal and Symbol.Used)) then begin
     if FixUpExpression^.Relative and (Symbol.SymbolType=ustLABEL) and (not Symbol.IsExternal) and not TRIDoRelative then begin
      FixUpExpression:=FixUpExpression^.Next;
      continue;
     end;
     inc(result);
    end;
   end;
   FixUpExpression:=FixUpExpression^.Next;
  end;
 end;
 procedure WriteRelocations;
 var FixUpExpression:PFixUpExpression;
     {SymbolIndex,}i:longint;
     Symbol:TUserSymbol;
 begin
  FixUpExpression:=StartFixUpExpression;
  while assigned(FixUpExpression) do begin
   if FixUpExpression^.Bits=32 then begin
    Symbol:=FixUpExpression^.Expression.GetFixUpSymbol(self);
    if assigned(Symbol) and ((Symbol.SymbolType in [ustLABEL,ustIMPORT]) or (Symbol.IsExternal and Symbol.Used)) then begin
     if FixUpExpression^.Relative and (Symbol.SymbolType=ustLABEL) and (not Symbol.IsExternal) and not TRIDoRelative then begin
      FixUpExpression:=FixUpExpression^.Next;
      continue;
     end;
     case Symbol.SymbolType of
      ustLABEL:begin
       if Symbol.IsExternal then begin
        StreamWriteByte(Stream,2);
       end else begin
        StreamWriteByte(Stream,1);
       end;
       StreamWriteByte(Stream,FixUpExpression^.Bits);
       StreamWriteByte(Stream,ord(FixUpExpression^.Relative));
       Stream.Write(FixUpExpression^.Position,SizeOf(longint));
       if Symbol.IsExternal then begin
        i:=length(Symbol.OriginalName)+1;
        Stream.Write(i,SizeOf(longint));
        dec(i);
        if i>0 then begin
         Stream.Write(Symbol.OriginalName[1],i);
        end;
        StreamWriteByte(Stream,0);
       end;
      end;
      ustIMPORT:begin
       StreamWriteByte(Stream,3);
       StreamWriteByte(Stream,FixUpExpression^.Bits);
       StreamWriteByte(Stream,ord(FixUpExpression^.Relative));
       Stream.Write(FixUpExpression^.Position,SizeOf(longint));
       if assigned(Symbol.ImportItem) and assigned(Symbol.ImportItem.ImportLibrary) then begin
        i:=length(Symbol.ImportItem.ImportLibrary.Name)+1;
        Stream.Write(i,SizeOf(longint));
        dec(i);
        if i>0 then begin
         Stream.Write(Symbol.ImportItem.ImportLibrary.Name[1],i);
        end;
        StreamWriteByte(Stream,0);
        i:=length(Symbol.ImportItem.Name)+1;
        Stream.Write(i,SizeOf(longint));
        dec(i);
        if i>0 then begin
         Stream.Write(Symbol.ImportItem.Name[1],i);
        end;
        StreamWriteByte(Stream,0);
       end else begin
        i:=1;
        Stream.Write(i,SizeOf(longint));
        StreamWriteByte(Stream,0);
        Stream.Write(i,SizeOf(longint));
        StreamWriteByte(Stream,0);
       end;
      end;
      else begin
       StreamWriteByte(Stream,0);
      end;
     end;
    end;
   end;
   FixUpExpression:=FixUpExpression^.Next;
  end;
 end;
 function CountPublic:longint;
 var i:longint;
     Symbol:TUserSymbol;
 begin
  result:=0;
  for i:=0 to UserSymbolList.Count-1 do begin
   Symbol:=UserSymbolList.Item[i];
   if assigned(Symbol) and Symbol.IsPublic then begin
    inc(result);
   end;
  end;
 end;
 procedure WritePublic;
 var i,j:longint;
     Symbol:TUserSymbol;
 begin
  for i:=0 to UserSymbolList.Count-1 do begin
   Symbol:=UserSymbolList.Item[i];
   if assigned(Symbol) and Symbol.IsPublic then begin
    j:=length(Symbol.OriginalName)+1;
    Stream.Write(j,SizeOf(longint));
    dec(j);
    if j>0 then begin
     Stream.Write(Symbol.OriginalName[1],j);
    end;
    StreamWriteByte(Stream,0);
    j:=Symbol.Position;
    Stream.Write(j,SizeOf(longint));
   end;
  end;
 end;
var j1,j2,j3:longint;
begin
 result:=false;
 if assigned(Stream) then begin
  StartOffset:=0;
  Generate;
  if not AreErrors then begin
   FixUpPass:=FUP_TRI;
   PostProcessFixUpExpressions;
   PostProcessSymbols;
   FixUpPass:=FUP_NONE;
   if not AreErrors then begin
    ShowStatus('Write image');
    if Stream is TMemoryStream then begin
     TMemoryStream(Stream).Clear;
    end;
    Stream.Size:=0;
    Stream.Seek(0,soBeginning);
    StreamWriteByte(Stream,ord('T'));
    StreamWriteByte(Stream,ord('R'));
    StreamWriteByte(Stream,ord('I'));
    StreamWriteByte(Stream,$00);
    i:=CodeImage.Size;
    Stream.Write(i,SizeOf(longint));
    i:=TotalSize;
    Stream.Write(i,SizeOf(longint));
    i:=CountRelocations;
    Stream.Write(i,SizeOf(longint));
    i:=CountPublic;
    Stream.Write(i,SizeOf(longint));
    j1:=Stream.Position;
    i:=0;
    Stream.Write(i,SizeOf(longint));
    j2:=Stream.Position;
    i:=0;
    Stream.Write(i,SizeOf(longint));
    Stream.Seek(Stream.Size,soBeginning);
    CodeImage.Seek(0,soBeginning);
    Stream.CopyFrom(CodeImage,CodeImage.Size);
    CodeImage.Seek(CodeImage.Size,soBeginning);
    j3:=Stream.Position;
    Stream.Seek(j1,soBeginning);
    Stream.Write(j3,SizeOf(longint));
    Stream.Seek(j3,soBeginning);
    WriteRelocations;
    j3:=Stream.Position;
    Stream.Seek(j2,soBeginning);
    Stream.Write(j3,SizeOf(longint));
    Stream.Seek(j3,soBeginning);
    WritePublic;
   end;
  end;
  result:=((Stream.Size<>0) or (TotalSize=0)) and not AreErrors;
 end;
end;

function TAssembler.Write(const Stream:TStream):boolean;
begin
 case Target of
  ttBIN:begin
   result:=WriteBIN(Stream);
  end;
  ttCOM:begin
   result:=WriteCOM(Stream);
  end;
  ttMZEXE:begin
   result:=WriteMZEXE(Stream);
  end;
  ttPEEXE32,ttPEEXE64:begin
   result:=WritePEEXE(Stream,Target=ttPEEXE64);
  end;
  ttCOFFDOS,ttCOFF32,ttCOFF64:begin
   result:=WriteCOFF(Stream,Target=ttCOFF64,Target=ttCOFFDOS);
  end;
  ttELF32,ttELFX32,ttELF64:begin
   result:=WriteELF(Stream,Target in [ttELFX32,ttELF64],Target=ttELFX32);
  end;
  ttOMF16,ttOMF32:begin
   result:=WriteOMF(Stream,Target=ttOMF32);
  end;
  ttTRI32,ttTRI64:begin
   result:=WriteTRI(Stream);
  end;
  else begin
   result:=false;
  end;
 end;
end;

function TAssembler.WriteFile(FileName:ansistring):boolean;
var FileStream:TFileStream;
    Stream:TStream;
begin
 Stream:=TMemoryStream.Create;
 try
  result:=Write(Stream);
  if result then begin
   FileStream:=TFileStream.Create(FileName,fmCreate);
   try
    FileStream.Seek(0,soBeginning);
    Stream.Seek(0,soBeginning);
    FileStream.CopyFrom(Stream,Stream.Size);
    FileStream.Seek(FileStream.Size,soBeginning);
    Stream.Seek(Stream.Size,soBeginning);
   finally
    FileStream.Free;
   end;
  end;
 finally
  Stream.Free;
 end;
end;

procedure TAssembler.NewImport(SymbolIndex:longint;TheLibrary,TheName:ansistring);
var Counter:longint;
    ImportLibrary:TAssemblerImportLibraryItem;
    Import:TAssemblerImportItem;
    NewImportLibrary:TAssemblerImportLibraryItem;
    NewImport:TAssemblerImportItem;
    Found:boolean;
    Symbol:TUserSymbol;
begin
 Found:=false;
 for Counter:=0 to ImportList.Count-1 do begin
  Import:=ImportList.Items[Counter];
  if Import.Name=TheName then begin
   Found:=true;
   break;
  end;
 end;
 if not Found then begin
  NewImport:=TAssemblerImportItem.Create;
  NewImport.Name:=TheName;
  NewImport.NameAddr:=0;
  NewImport.ProcAddr:=0;
  NewImport.ImportLibrary:=nil;
  NewImport.Symbol:=nil;
  NewImport.Used:=false;
  Found:=false;
  for Counter:=0 to ImportLibraryList.Count-1 do begin
   ImportLibrary:=ImportLibraryList.Items[Counter];
   if ImportLibrary.Name=TheLibrary then begin
    NewImport.ImportLibrary:=ImportLibrary;
    Found:=true;
    break;
   end;
  end;
  if not Found then begin
   NewImportLibrary:=TAssemblerImportLibraryItem.Create;
   NewImportLibrary.Name:=TheLibrary;
   NewImportLibrary.NameAddr:=0;
   NewImportLibrary.ImportsAddr:=0;
   NewImportLibrary.Used:=false;
   ImportLibraryList.Add(NewImportLibrary);
   for Counter:=0 to ImportLibraryList.Count-1 do begin
    ImportLibrary:=ImportLibraryList.Items[Counter];
    if ImportLibrary.Name=TheLibrary then begin
     NewImport.ImportLibrary:=ImportLibrary;
     break;
    end;
   end;
  end;
  if (SymbolIndex>=0) and (SymbolIndex<UserSymbolList.Count) then begin
   Symbol:=UserSymbolList[SymbolIndex];
   NewImport.Symbol:=Symbol;
   if Symbol.Used then begin
    NewImport.Used:=true;
    if assigned(NewImport.ImportLibrary) then begin
     NewImport.ImportLibrary.Used:=true;
    end;
   end;
   ImportList.Add(NewImport);
   Symbol.ImportItem:=NewImport;
   Symbol.SymbolType:=ustIMPORT;
  end else begin
   ImportList.Add(NewImport);
  end;
 end;
end;

procedure TAssembler.NewExport(SymbolIndex:longint;TheName:ansistring);
var ExportItem:TAssemblerExportItem;
    Counter:longint;
    Symbol:TUserSymbol;
begin
 if (SymbolIndex>=0) and (SymbolIndex<UserSymbolList.Count) then begin
  Symbol:=UserSymbolList[SymbolIndex];
  for Counter:=0 to ExportList.Count-1 do begin
   if (ExportList[Counter].Symbol=Symbol) or (ExportList[Counter].Name=TheName) then begin
    exit;
   end;
  end;
  ExportItem:=ExportList.NewClass;
  ExportItem.Symbol:=Symbol;
  ExportItem.Name:=TheName;
  ExportItem.Used:=false;
  Symbol.ExportItem:=ExportItem;
 end;
end;

{$ifdef FPC}
 {$notes off}
{$endif}                             
procedure TAssembler.ParseString(Source:ansistring);
var InputSourceCode:ansistring;
    InputSourceCodeLines:TStringList;
    InputSourceCodeLineIndex:longint;
    InputSourceCodeCountLines:longint;
    InputSourceCodeLinePosition:longint;
    InputSourceCodeLineLength:longint;
    InputSourceCodeLine:ansistring;
    InputSourceCodeHistoryRingBuffer:array[0..63] of ansichar;
    InputSourceCodeHistoryRingBufferPosition:longint;
    ParsedChars:int64;
    LastChar:ansichar;
    SymbolName:ansistring;
    OriginalSymbolName:ansistring;
    IsSymbolPrefixed:longbool;
    StringData:ansistring;
    WideStringData:widestring;
    SymbolType:TSymbolTreeLinkType;
    SymbolValue:TSymbolTreeLink;
    DataSymbolValue:TSymbolTreeLink;
    OpcodeIndex:TOpcodes;
    PrefixIndex:longint;
    Code,OtherCode:PCode;
    NumberIntegerValue:TIntegerValue;
    NumberFloatValue:TFloatValue;
    OpcodeOperandCount:longint;
    IsFloat:boolean;
    SymbolNew:boolean;
    LastStruct:longint;
    StructName:ansistring;
    StructSize:longint;
    CurrentIEEEFormat:PIEEEFormat;
    DataBytes:longint;
    OpcodePrefixWait:longint;
    OpcodePrefixSegment:longint;                 
    OpcodePrefixLock:longint;
    OpcodePrefixRep:longint;
    OpcodePrefixAddressSize:longint;
    OpcodePrefixOpcodeSize:longint;
    OpcodePrefixVEX:longint;
    OpcodePrefixCount:longint;
    AllowedKeywordKinds:TKeywordKinds;
 procedure PreprocessLine(var Line:ansistring);
  procedure Pass(var Line:ansistring;const HideSet:ansistring='');
  var LineLength,LinePosition,StartPosition,EndPosition,FoundStartPosition,FoundEndPosition,Level:longint;
      TerminateChar:ansichar;
      Identifier,Subject:ansistring;
      SymbolType:TSymbolTreeLinkType;
      SymbolValue:TSymbolTreeLink;
      Symbol:TUserSymbol;
      Parameters:TStringList;
   procedure ParseMacroParameters(MacroParameters:TStringList);
   var CurrentMacroParameter:ansistring;
       LastChar:ansichar;
    function GetChar:ansichar;
    begin
     if LinePosition<=LineLength then begin
      result:=Line[LinePosition];
      inc(LinePosition);
     end else begin
      result:=#0;
     end;
     LastChar:=result;
    end;
    procedure SkipWhiteSpaceOnSameLine;
    begin
     while byte(LastChar) in [1..9,11..32] do begin
      GetChar;
     end;
    end;
    procedure ParseMacroParameterString;
    var TerminateChar:ansichar;
    begin
     TerminateChar:=LastChar;
     CurrentMacroParameter:=CurrentMacroParameter+LastChar;
     GetChar;
     while not AreErrors do begin
      case LastChar of
       #0,#10:begin
        MakeError('Unterminated string');
        break;
       end;
       '''','"':begin
        if LastChar=TerminateChar then begin
         CurrentMacroParameter:=CurrentMacroParameter+LastChar;
         GetChar;
         break;
        end else begin
         CurrentMacroParameter:=CurrentMacroParameter+LastChar;
         GetChar;
        end;
       end;
       '\':begin
        CurrentMacroParameter:=CurrentMacroParameter+LastChar;
        GetChar;
        CurrentMacroParameter:=CurrentMacroParameter+LastChar;
        GetChar;
       end;
       else begin
        CurrentMacroParameter:=CurrentMacroParameter+LastChar;
        GetChar;
       end;
      end;
     end;
    end;
    procedure ParseMacroParameterGroup(const TerminateChar:ansichar;TrimIt:boolean);
    begin
     if not TrimIt then begin
      CurrentMacroParameter:=CurrentMacroParameter+LastChar;
     end;
     GetChar;
     while not AreErrors do begin
      case LastChar of
       #0:begin
        break;
       end;
       '{':begin
        ParseMacroParameterGroup('}',false);
       end;
       '[':begin
        ParseMacroParameterGroup(']',false);
       end;
       '(':begin
        ParseMacroParameterGroup(')',false);
       end;
       '}',']',')':begin
        if LastChar=TerminateChar then begin
         if not TrimIt then begin
          CurrentMacroParameter:=CurrentMacroParameter+LastChar;
         end;
         GetChar;
         break;
        end else begin
         MakeError('Misplaced closed bracket or parenthesis');
        end;
       end;
       '''','"':begin
        ParseMacroParameterString;
       end;
       else begin
        CurrentMacroParameter:=CurrentMacroParameter+LastChar;
        GetChar;
       end;
      end;
     end;
    end;
   var HasCurrentMacroParameter,LastWasComma,NewParameter:boolean;
   begin
    MacroParameters.Clear;
    SkipWhiteSpaceOnSameLine;
    CurrentMacroParameter:='';
    HasCurrentMacroParameter:=false;
    LastWasComma:=false;
    NewParameter:=true;
    GetChar;
    while not AreErrors do begin
     case LastChar of
      #0:begin
       break;
      end;
      #10,';':begin
       if LastWasComma then begin
        GetChar;
        SkipWhiteSpaceOnSameLine;
       end else begin
        break;
       end;
      end;
      ',':begin
       MacroParameters.Add(CurrentMacroParameter);
       CurrentMacroParameter:='';
       HasCurrentMacroParameter:=true;
       GetChar;
       SkipWhiteSpaceOnSameLine;
       LastWasComma:=true;
       NewParameter:=true;
      end;
      '{':begin
       ParseMacroParameterGroup('}',false);
       HasCurrentMacroParameter:=true;
       LastWasComma:=false;
       NewParameter:=false;
      end;
      '[':begin
       ParseMacroParameterGroup(']',false);
       HasCurrentMacroParameter:=true;
       LastWasComma:=false;
       NewParameter:=false;
      end;
      '(':begin
       ParseMacroParameterGroup(')',false);
       HasCurrentMacroParameter:=true;
       LastWasComma:=false;
       NewParameter:=false;
      end;
      '}',']':begin
       MakeError('Misplaced closed bracket or parenthesis');
       break;
      end;
      ')':begin
       dec(LinePosition);
       break;
      end;
      '''','"':begin
       ParseMacroParameterString;
       HasCurrentMacroParameter:=true;
       LastWasComma:=false;
       NewParameter:=false;
      end;
      #1..#9,#11..#12,#14..#32:begin
       CurrentMacroParameter:=CurrentMacroParameter+LastChar;
       GetChar;
      end;
      else begin
       CurrentMacroParameter:=CurrentMacroParameter+LastChar;
       GetChar;
       HasCurrentMacroParameter:=true;
       LastWasComma:=false;
       NewParameter:=false;
      end;
     end;
    end;
    if HasCurrentMacroParameter then begin
     MacroParameters.Add(CurrentMacroParameter);
    end;
   end;
  var StringPosition,StringLength,Index:longint;
      MacroStringValue,SubjectResult,Temp:ansistring;
      MacroValueIndex:int64;
  begin
   LineLength:=length(Line);
   repeat
    LinePosition:=1;
    while LinePosition<=LineLength do begin
     case Line[LinePosition] of
      'A'..'Z','a'..'z','@','_','$':begin
       FoundStartPosition:=LinePosition;
       StartPosition:=LinePosition;
       while (LinePosition<=LineLength) and (Line[LinePosition] in ['A'..'Z','a'..'z','@','_','$','0'..'9']) do begin
        inc(LinePosition);
       end;
       EndPosition:=LinePosition;
       Identifier:=UpperCase(copy(Line,StartPosition,EndPosition-StartPosition));
       if UserSymbolTree.Find(Identifier,SymbolType,SymbolValue) and (pos(Identifier,HideSet)=0) then begin
        if SymbolType=stUSER then begin
         Symbol:=UserSymbolList[SymbolValue];
         if Symbol.SymbolType=ustONELINEMACRO then begin
          Parameters:=TStringList.Create;
          try
           FoundEndPosition:=LinePosition;
           while (LinePosition<=LineLength) and (Line[LinePosition] in [#1..#32]) do begin
            inc(LinePosition);
           end;
           if (LinePosition<=LineLength) and (Line[LinePosition]='(') then begin
            inc(LinePosition);
            ParseMacroParameters(Parameters);
            if (LinePosition<=LineLength) and (Line[LinePosition]=')') then begin
             FoundEndPosition:=LinePosition+1;
             inc(LinePosition);
            end else begin
             Parameters.Clear;
            end;
           end;
           Subject:=copy(Line,FoundStartPosition,FoundEndPosition-FoundStartPosition);
           MacroStringValue:=Symbol.Content;
           if Parameters.Count<Symbol.CountParameters then begin
            MakeError(18);
           end else begin
            SubjectResult:='';
            StringPosition:=1;
            StringLength:=length(MacroStringValue);
            while StringPosition<=StringLength do begin
             case MacroStringValue[StringPosition] of
              #0:begin
               inc(StringPosition);
               if StringPosition<=StringLength then begin
                case MacroStringValue[StringPosition] of
                 #1:begin
                  // Parameter
                  inc(StringPosition);
                  if ((StringPosition+4)<=StringLength) and (MacroStringValue[StringPosition+4]=#0) then begin
                   MacroValueIndex:=(longword(byte(ansichar(MacroStringValue[StringPosition+0]))) shl 0) or
                                    (longword(byte(ansichar(MacroStringValue[StringPosition+1]))) shl 8) or
                                    (longword(byte(ansichar(MacroStringValue[StringPosition+2]))) shl 16) or
                                    (longword(byte(ansichar(MacroStringValue[StringPosition+3]))) shl 24);
                   inc(StringPosition,5);
                   if (MacroValueIndex>=0) and (MacroValueIndex<Parameters.Count) then begin
                    SubjectResult:=SubjectResult+Parameters[MacroValueIndex];
                   end;
                  end else begin
                   MakeError(16);
                  end;
                 end;
                 #3:begin
                  // Parameter check
                  inc(StringPosition);
                  if ((StringPosition+4)<=StringLength) and (MacroStringValue[StringPosition+4]=#0) then begin
                   MacroValueIndex:=(longword(byte(ansichar(MacroStringValue[StringPosition+0]))) shl 0) or
                                    (longword(byte(ansichar(MacroStringValue[StringPosition+1]))) shl 8) or
                                    (longword(byte(ansichar(MacroStringValue[StringPosition+2]))) shl 16) or
                                    (longword(byte(ansichar(MacroStringValue[StringPosition+3]))) shl 24);
                   inc(StringPosition,5);
                   if ((MacroValueIndex>=0) and (MacroValueIndex<Parameters.Count)) and (length(trim(Parameters[MacroValueIndex]))>0) then begin
                    SubjectResult:=SubjectResult+'1';
                   end else begin
                    SubjectResult:=SubjectResult+'0';
                   end;
                  end else begin
                   MakeError(16);
                  end;
                 end;
                 #4:begin
                  // Stringify Parameter
                  inc(StringPosition);
                  if ((StringPosition+4)<=StringLength) and (MacroStringValue[StringPosition+4]=#0) then begin
                   MacroValueIndex:=(longword(byte(ansichar(MacroStringValue[StringPosition+0]))) shl 0) or
                                    (longword(byte(ansichar(MacroStringValue[StringPosition+1]))) shl 8) or
                                    (longword(byte(ansichar(MacroStringValue[StringPosition+2]))) shl 16) or
                                    (longword(byte(ansichar(MacroStringValue[StringPosition+3]))) shl 24);
                   inc(StringPosition,5);
                   if (MacroValueIndex>=0) and (MacroValueIndex<Parameters.Count) then begin
                    SubjectResult:=SubjectResult+'"'+Stringify(Parameters[MacroValueIndex])+'"';
                   end;
                  end else begin
                   MakeError(16);
                  end;
                 end;
                 #5:begin
                  // __VA_ARGS__ parameter
                  inc(StringPosition);
                  if ((StringPosition+4)<=StringLength) and (MacroStringValue[StringPosition+4]=#0) then begin
                   MacroValueIndex:=(longword(byte(ansichar(MacroStringValue[StringPosition+0]))) shl 0) or
                                    (longword(byte(ansichar(MacroStringValue[StringPosition+1]))) shl 8) or
                                    (longword(byte(ansichar(MacroStringValue[StringPosition+2]))) shl 16) or
                                    (longword(byte(ansichar(MacroStringValue[StringPosition+3]))) shl 24);
                   inc(StringPosition,5);
                   for Index:=MacroValueIndex to Parameters.Count-1 do begin
                    if Index>MacroValueIndex then begin
                     SubjectResult:=SubjectResult+', ';
                    end else begin
                     SubjectResult:=SubjectResult+Parameters[MacroValueIndex];
                    end;
                   end;
                  end else begin
                   MakeError(16);
                  end;
                 end;
                 #6:begin
                  // Stringify __VA_ARGS__ parameter
                  inc(StringPosition);
                  if ((StringPosition+4)<=StringLength) and (MacroStringValue[StringPosition+4]=#0) then begin
                   MacroValueIndex:=(longword(byte(ansichar(MacroStringValue[StringPosition+0]))) shl 0) or
                                    (longword(byte(ansichar(MacroStringValue[StringPosition+1]))) shl 8) or
                                    (longword(byte(ansichar(MacroStringValue[StringPosition+2]))) shl 16) or
                                    (longword(byte(ansichar(MacroStringValue[StringPosition+3]))) shl 24);
                   inc(StringPosition,5);
                   Temp:='';
                   for Index:=MacroValueIndex to Parameters.Count-1 do begin
                    if Index>MacroValueIndex then begin
                     Temp:=Temp+', ';
                    end;
                    Temp:=Temp+Parameters[Index];
                   end;
                   SubjectResult:=SubjectResult+'"'+Stringify(Temp)+'"';
                  end else begin
                   MakeError(16);
                  end;
                 end;
                 #7:begin
                  // __VA_ARGS__ char
                  inc(StringPosition);
                  if ((StringPosition+5)<=StringLength) and (MacroStringValue[StringPosition+5]=#0) then begin
                   MacroValueIndex:=(longword(byte(ansichar(MacroStringValue[StringPosition+0]))) shl 0) or
                                    (longword(byte(ansichar(MacroStringValue[StringPosition+1]))) shl 8) or
                                    (longword(byte(ansichar(MacroStringValue[StringPosition+2]))) shl 16) or
                                    (longword(byte(ansichar(MacroStringValue[StringPosition+3]))) shl 24);
                   inc(StringPosition,6);
                   if MacroValueIndex<Parameters.Count then begin
                    SubjectResult:=SubjectResult+MacroStringValue[StringPosition+4];
                   end;
                  end else begin
                   MakeError(16);
                  end;
                 end;
                 else begin
                  MakeError(16);
                 end;
                end;
               end else begin
                MakeError(16);
               end;
              end;
              else begin
               SubjectResult:=SubjectResult+MacroStringValue[StringPosition];
               inc(StringPosition);
              end;
             end;
            end;
            Pass(SubjectResult,HideSet+','+Identifier);
            Delete(Line,FoundStartPosition,FoundEndPosition-FoundStartPosition);
            Insert(SubjectResult,Line,FoundStartPosition);
            LinePosition:=FoundStartPosition+length(SubjectResult);
            LineLength:=length(Line);
           end;
          finally
           Parameters.Free;
          end;
         end;
        end;
       end;
      end;
      '''','"':begin
       TerminateChar:=Line[LinePosition];
       inc(LinePosition);
       while LinePosition<=LineLength do begin
        case Line[LinePosition] of
         '''','"':begin
          if Line[LinePosition]=TerminateChar then begin
           inc(LinePosition);
           break;
          end else begin
           inc(LinePosition);
          end;
         end;
         '\':begin
          inc(LinePosition);
          if LinePosition<=LineLength then begin
           inc(LinePosition);
          end;
         end;
         else begin
          inc(LinePosition);
         end;
        end;
       end;
      end;
      else begin
       inc(LinePosition);
      end;
     end;
    end;
    break;
   until false;
  end;
 var LineLength,LinePosition:longint;
 begin
  LinePosition:=1;
  LineLength:=length(Line);
  while (LinePosition<=LineLength) and (Line[LinePosition] in [#1..#32]) do begin
   inc(LinePosition);
  end;
  if ((LinePosition+8)<=LineLength) and (Line[LinePosition]='.') and (LowerCase(copy(Line,LinePosition+1,7))='unmacro') then begin
   exit;
  end;
  Pass(Line,'');
 end;
 function GetChar:ansichar;
 begin
  if InputSourceCodeLineIndex>=InputSourceCodeCountLines then begin
   result:=#0;
  end else if (InputSourceCodeLinePosition>=1) and (InputSourceCodeLinePosition<=InputSourceCodeLineLength) then begin
   result:=InputSourceCodeLine[InputSourceCodeLinePosition];
   inc(InputSourceCodeLinePosition);
   inc(CurrentColumn);
  end else begin
   result:=#10;
   inc(InputSourceCodeLineIndex);
   if InputSourceCodeLineIndex<InputSourceCodeCountLines then begin
    InputSourceCodeLine:=InputSourceCodeLines[InputSourceCodeLineIndex];
   end else begin
    InputSourceCodeLine:='';
   end;
   PreprocessLine(InputSourceCodeLine);
   InputSourceCodeLineLength:=length(InputSourceCodeLine);
   InputSourceCodeLinePosition:=1;
   inc(CurrentLineNumber);
   CurrentColumn:=0;
  end;
  InputSourceCodeHistoryRingBufferPosition:=(InputSourceCodeHistoryRingBufferPosition+1) and high(InputSourceCodeHistoryRingBuffer);
  InputSourceCodeHistoryRingBuffer[InputSourceCodeHistoryRingBufferPosition]:=result;
  LastChar:=result;
  inc(ParsedChars);
 end;
 function PeekChar:ansichar;
 begin
  if InputSourceCodeLineIndex>=InputSourceCodeCountLines then begin
   result:=#0;
  end else if (InputSourceCodeLinePosition>=1) and (InputSourceCodeLinePosition<=InputSourceCodeLineLength) then begin
   result:=InputSourceCodeLine[InputSourceCodeLinePosition];
  end else begin
   result:=#10;
  end;
 end;
 function GetPreviousChar(Offset:longint):ansichar;
 begin
  if (Offset>=(-high(InputSourceCodeHistoryRingBuffer))) and (Offset<0) then begin
   result:=InputSourceCodeHistoryRingBuffer[(InputSourceCodeHistoryRingBufferPosition+Offset) and high(InputSourceCodeHistoryRingBuffer)];
  end else begin
   result:=#0;
  end;
 end;
 function IsLineEnd:boolean;
 begin
  result:=LastChar in [#0,#10,';'];
 end;
 procedure SkipWhiteSpaceOnSameLine;
 begin
  while byte(LastChar) in [1..9,11..32] do begin
   GetChar;
  end;
 end;
 procedure SkipWhiteSpaceAndNewLines;
 begin
  while (LastChar<>#0) and not AreErrors do begin
   SkipWhiteSpaceOnSameLine;
   if IsLineEnd then begin
    GetChar;
   end else begin
    break;
   end;
  end;
 end;
 procedure SkipWhiteSpaceAndNewLinesExceptArtificialNewLines;
 begin
  while (LastChar<>#0) and not AreErrors do begin
   SkipWhiteSpaceOnSameLine;
   if LastChar=#10 then begin
    GetChar;
   end else begin
    break;
   end;
  end;
 end;
 function CheckComma:boolean;
 begin
  SkipWhiteSpaceOnSameLine;
  result:=LastChar=',';
  if result then begin
   GetChar;
  end;
 end;
 function CheckDoublePoint:boolean;
 begin
  SkipWhiteSpaceOnSameLine;
  result:=LastChar=':';
  if result then begin
   GetChar;
  end;
 end;
 function CheckPoint:boolean;
 begin
  SkipWhiteSpaceOnSameLine;
  result:=LastChar='.';
  if result then begin
   GetChar;
  end;
 end;
 function CheckExclamationMark:boolean;
 begin
  SkipWhiteSpaceOnSameLine;
  result:=LastChar='!';
  if result then begin
   GetChar;
  end;
 end;
 function CheckPlus:boolean;
 begin
  SkipWhiteSpaceOnSameLine;
  result:=LastChar='+';
  if result then begin
   GetChar;
  end;
 end;
 function CheckMul:boolean;
 begin
  SkipWhiteSpaceOnSameLine;
  result:=LastChar='*';
  if result then begin
   GetChar;
  end;
 end;
 function CheckAlpha:boolean;
 begin
  SkipWhiteSpaceOnSameLine;
  result:=LastChar in ['A'..'Z','a'..'z','@','_','$'];
 end;
 function CheckNumber:boolean;
 begin
  SkipWhiteSpaceOnSameLine;
  result:=LastChar in ['+','-','0'..'9','"',''''];
 end;
 function CheckNumberFull:boolean;
 begin
  SkipWhiteSpaceOnSameLine;
  result:=LastChar in ['+','-','0'..'9','"','''','(','!','~','['];
 end;
 function CheckNumberEx:boolean;
 begin
  SkipWhiteSpaceOnSameLine;
  result:=LastChar in ['+','-','0'..'9'];
 end;
 function CheckKeyword(Value:TSymbolTreeLink):boolean;
 begin
  result:=(SymbolType=stKEYWORD) and (SymbolValue=Value);
 end;
 function CheckPrefix(Value:TSymbolTreeLink):boolean;
 begin
  result:=(SymbolType=stPREFIX) and (SymbolValue=Value);
 end;
 function CheckStruct:boolean;
 begin
  if (SymbolType=stUSER) and (SymbolValue>=0) then begin
   result:=UserSymbolList[SymbolValue].SymbolType=ustSTRUCT;
  end else begin
   result:=false;
  end;
 end;
 procedure ReadAlpha;
 var OriginalName:ansistring;
 begin
  if CheckAlpha then begin
   OriginalName:='';
   while LastChar in ['A'..'Z','a'..'z','0'..'9','@','_','.','$'] do begin
    OriginalName:=OriginalName+LastChar;
    GetChar;
   end;
   OriginalSymbolName:=OriginalName;
   SymbolName:=UpperCase(OriginalName);
  end else begin
   MakeError(68);
  end;
 end;
 procedure ReadAlphaOrNumber;
 var OriginalName:ansistring;
 begin
  if CheckAlpha or (LastChar in ['0'..'9']) then begin
   OriginalName:='';
   while LastChar in ['A'..'Z','a'..'z','0'..'9','@','_','.','$'] do begin
    OriginalName:=OriginalName+LastChar;
    GetChar;
   end;
   OriginalSymbolName:=OriginalName;
   SymbolName:=UpperCase(OriginalName);
  end else begin
   MakeError(68);
  end;
 end;
 procedure ReadSymbol(Mode:longint=0);
 var Index:longint;
     Dot,Found:boolean;
     OriginalName:ansistring;
     TempSymbolType:TSymbolTreeLinkType;
     TempSymbolValue:TSymbolTreeLink;
 begin
  SymbolNew:=false;
  if CheckAlpha then begin
   OriginalName:='';
   Dot:=false;
   while LastChar in ['A'..'Z','a'..'z','0'..'9','@','_','.','$'] do begin
    Dot:=Dot or (LastChar='.');
    if length(SymbolName)>=255 then begin
     MakeError(10);
     break;
    end;
    OriginalName:=OriginalName+LastChar;
    GetChar;
   end;
   if (length(OriginalName)>0) and (OriginalName[1]='@') then begin
    OriginalName:=OriginalNamePrefix+OriginalName;
    IsSymbolPrefixed:=true;
   end else begin
    IsSymbolPrefixed:=false;
   end;
   OriginalSymbolName:=OriginalName;
   SymbolName:=UpperCase(OriginalName);
   Found:=false;
   if kkOPCODE in AllowedKeywordKinds then begin
    if OpcodeSymbolTree.Find(SymbolName,SymbolType,SymbolValue) then begin
     Found:=true;
    end;
   end;
   if not Found then begin
    if KeywordSymbolTree.Find(SymbolName,TempSymbolType,TempSymbolValue) then begin
     case TempSymbolType of
      stPREFIX:begin
       Found:=kkPREFIX in AllowedKeywordKinds;
      end;
      stOPCODE:begin
       Found:=kkOPCODE in AllowedKeywordKinds;
      end;
      stREGISTER:begin
       Found:=kkREGISTER in AllowedKeywordKinds;
      end;
      stKEYWORD:begin
       Found:=(KeywordTemplates[TempSymbolValue].Kind*AllowedKeywordKinds)<>[];
      end;
     end;
     if Found then begin
      SymbolType:=TempSymbolType;
      SymbolValue:=TempSymbolValue;
     end;
    end;
   end;
   if not Found then begin
    if UserSymbolTree.Find(SymbolName,SymbolType,SymbolValue) then begin
     if (length(StructName)>0) and (SymbolType in [stNONE,stUSER,stUNIT]) then begin
      if assigned(UserSymbolList[SymbolValue]) and (UserSymbolList[SymbolValue].SymbolType in [ustMACRO,ustSCRIPTMACRO,ustSTRUCT,ustVARIABLE,ustUNIT,ustREPLACER]) then begin
       Found:=true;
      end else if UserSymbolTree.Find(StructName+SymbolName,SymbolType,SymbolValue) then begin
       Found:=true;
      end;
     end else begin
      Found:=true;
     end;
    end;
   end;                 
   if not Found then begin
    SymbolName:=StructName+SymbolName;
    if (length(StructName)<>0) or not DOT then begin
     UserSymbolList.NewClass(Index,SymbolName,OriginalName);
     UserSymbolTree.Add(SymbolName,stUSER,Index);
     SymbolType:=stUSER;
     SymbolValue:=Index;
     SymbolNew:=true;
    end else begin
     SymbolType:=stNONE;
     SymbolValue:=0;
     MakeError(14);
    end;
   end;
  end else begin
   SymbolType:=stNONE;
   SymbolValue:=0;
  end;
 end;
 procedure ReadString;
 var TerminateChar:ansichar;
     Index:longint;
     Value:longword;
 begin
  StringData:='';
  SkipWhiteSpaceOnSameLine;
  if LastChar in ['"',''''] then begin
   TerminateChar:=LastChar;
   GetChar;
   while (LastChar<>TerminateChar) and (LastChar<>#0) do begin
    if LastChar='\' then begin 
     GetChar;
     case LastChar of
      'a':begin
       GetChar;
       StringData:=StringData+#7;
      end;
      'b':begin
       GetChar;
       StringData:=StringData+#8;
      end;
      't':begin
       GetChar;
       StringData:=StringData+#9;
      end;
      'n':begin
       GetChar;
       StringData:=StringData+#10;
      end;
      'v':begin
       GetChar;
       StringData:=StringData+#11;
      end;
      'f':begin
       GetChar;
       StringData:=StringData+#12;
      end;
      'r':begin
       GetChar;
       StringData:=StringData+#13;
      end;
      'e':begin
       GetChar;
       StringData:=StringData+#27;
      end;
      '0'..'7':begin
       Value:=0;
       Index:=0;
       repeat
        if LastChar in ['0'..'7'] then begin
         if Index>2 then begin
          MakeError(48);
          break;
         end;
         Value:=(Value shl 3) or longword(byte(LastChar)-byte('0'));
         GetChar;
         inc(Index);
        end else begin
         break;
        end;
       until false;
       StringData:=StringData+ansichar(byte(Value));
      end;
      'x':begin
       GetChar;
       Value:=0;
       for Index:=0 to 1 do begin
        if LastChar in ['0'..'9'] then begin
         Value:=(Value shl 4) or longword(byte(LastChar)-byte('0'));
        end else if LastChar in ['A'..'F'] then begin
         Value:=(Value shl 4) or longword((byte(LastChar)-byte('A'))+$a);
        end else if LastChar in ['a'..'f'] then begin
         Value:=(Value shl 4) or longword((byte(LastChar)-byte('a'))+$a);
        end else begin
         MakeError(48);
         break;
        end;
        GetChar;
       end;
       StringData:=StringData+ansichar(byte(Value));
      end;
      'u':begin
       GetChar;
       Value:=0;
       for Index:=0 to 3 do begin
        if LastChar in ['0'..'9'] then begin
         Value:=(Value shl 4) or longword(byte(LastChar)-byte('0'));
        end else if LastChar in ['A'..'F'] then begin
         Value:=(Value shl 4) or longword((byte(LastChar)-byte('A'))+$a);
        end else if LastChar in ['a'..'f'] then begin
         Value:=(Value shl 4) or longword((byte(LastChar)-byte('a'))+$a);
        end else begin
         MakeError(48);
         break;
        end;
        GetChar;
       end;
       StringData:=StringData+UTF32CharToUTF8(Value);
      end;
      'U':begin
       GetChar;
       Value:=0;
       for Index:=0 to 7 do begin
        if LastChar in ['0'..'9'] then begin
         Value:=(Value shl 4) or longword(byte(LastChar)-byte('0'));
        end else if LastChar in ['A'..'F'] then begin
         Value:=(Value shl 4) or longword((byte(LastChar)-byte('A'))+$a);
        end else if LastChar in ['a'..'f'] then begin
         Value:=(Value shl 4) or longword((byte(LastChar)-byte('a'))+$a);
        end else begin
         MakeError(48);
         break;
        end;
        GetChar;
       end;
       StringData:=StringData+UTF32CharToUTF8(Value);
      end;
      else begin
       StringData:=StringData+LastChar;
       GetChar;
      end;
     end;
    end else begin
     StringData:=StringData+LastChar;
     GetChar;
    end;
   end;
   GetChar;
  end else begin
   MakeError(11);
  end;
 end;
 procedure ReadWideString;
 var TerminateChar:ansichar;
     Value:array[0..3] of byte;
     C:widechar;
     i:longint;
 begin
  WideStringData:='';
  SkipWhiteSpaceOnSameLine;
  if LastChar in ['"',''''] then begin
   TerminateChar:=LastChar;
   GetChar;
   while (LastChar<>TerminateChar) and (LastChar<>#0) do begin
    if LastChar='\' then begin
     GetChar;
     case LastChar of
      '"','''','\':C:=widechar(byte(LastChar));
      'r','R':C:=#13;
      'n','N':C:=#10;
      'b','B':C:=#7;
      'u','U':C:=#8;
      't','T':C:=#9;
      '0':C:=#0;
      'x','X':begin
       for i:=0 to 3 do begin
        GetChar;
        if LastChar=#0 then LastChar:='0';
        if LastChar in ['0'..'9'] then begin
         Value[i]:=byte(LastChar)-byte('0');
        end else if LastChar in ['A'..'F'] then begin
         Value[i]:=byte(LastChar)-byte('A')+10;
        end else if LastChar in ['a'..'f'] then begin
         Value[i]:=byte(LastChar)-byte('a')+10;
        end else begin
         Value[i]:=0;
         MakeError(48);
         exit;
        end;
       end;
       C:=widechar((Value[0] shl 12) or (Value[1] shl 8) or (Value[2] shl 4) or Value[3]);
      end;
      else C:=#0;
     end;
     WideStringData:=WideStringData+C;
     GetChar;
    end else begin
     WideStringData:=WideStringData+WideChar(LastChar);
     GetChar;
    end;
   end;
   GetChar;
  end else begin
   MakeError(11);
  end;
 end;
 procedure ReadFloatValue(var FloatValue:TFloatValue;const IEEEFormat:TIEEEFormat);
 var NumberString:ansistring;
 begin
  NumberString:='';
  if LastChar in ['-','+'] then begin
   NumberString:=NumberString+LastChar;
   GetChar;
  end;
  if LastChar='0' then begin
   NumberString:=NumberString+LastChar;
   GetChar;
   case LastChar of
    'h','H','x','X':begin
     NumberString:=NumberString+LastChar;
     GetChar;
     while LastChar in ['0'..'9','A'..'F','a'..'f'] do begin
      NumberString:=NumberString+LastChar;
      GetChar;
     end;
     if LastChar in ['.'] then begin
      NumberString:=NumberString+LastChar;
      GetChar;
      while LastChar in ['0'..'9','A'..'F','a'..'f'] do begin
       NumberString:=NumberString+LastChar;
       GetChar;
      end;
      if LastChar in ['p','P'] then begin
       NumberString:=NumberString+LastChar;
       GetChar;
       if LastChar in ['-','+'] then begin
        NumberString:=NumberString+LastChar;
        GetChar;
       end;
       while LastChar in ['0'..'9'] do begin
        NumberString:=NumberString+LastChar;
        GetChar;
       end;
      end;
     end;
    end;
    'o','O','q','Q':begin
     NumberString:=NumberString+LastChar;
     GetChar;
     while LastChar in ['0'..'7'] do begin
      NumberString:=NumberString+LastChar;
      GetChar;
     end;
     if LastChar in ['.'] then begin
      NumberString:=NumberString+LastChar;
      GetChar;
      while LastChar in ['0'..'7'] do begin
       NumberString:=NumberString+LastChar;
       GetChar;
      end;
      if LastChar in ['p','P'] then begin
       NumberString:=NumberString+LastChar;
       GetChar;
       if LastChar in ['-','+'] then begin
        NumberString:=NumberString+LastChar;
        GetChar;
       end;
       while LastChar in ['0'..'9'] do begin
        NumberString:=NumberString+LastChar;
        GetChar;
       end;
      end;
     end;
    end;
    'd','D','t','T':begin
     NumberString:=NumberString+LastChar;
     GetChar;
     while LastChar in ['0'..'9'] do begin
      NumberString:=NumberString+LastChar;
      GetChar;
     end;
     if LastChar in ['.'] then begin
      NumberString:=NumberString+LastChar;
      GetChar;
      while LastChar in ['0'..'9'] do begin
       NumberString:=NumberString+LastChar;
       GetChar;
      end;
      if LastChar in ['e','E'] then begin
       NumberString:=NumberString+LastChar;
       GetChar;
       if LastChar in ['-','+'] then begin
        NumberString:=NumberString+LastChar;
        GetChar;
       end;
       while LastChar in ['0'..'9'] do begin
        NumberString:=NumberString+LastChar;
        GetChar;
       end;
      end;
     end;
    end;
    'b','B','y','Y':begin
     NumberString:=NumberString+LastChar;
     GetChar;
     while LastChar in ['0'..'1'] do begin
      NumberString:=NumberString+LastChar;
      GetChar;
     end;
     if LastChar in ['.'] then begin
      NumberString:=NumberString+LastChar;
      GetChar;
      while LastChar in ['0'..'1'] do begin
       NumberString:=NumberString+LastChar;
       GetChar;
      end;
      if LastChar in ['p','P'] then begin
       NumberString:=NumberString+LastChar;
       GetChar;
       if LastChar in ['-','+'] then begin
        NumberString:=NumberString+LastChar;
        GetChar;
       end;
       while LastChar in ['0'..'9'] do begin
        NumberString:=NumberString+LastChar;
        GetChar;
       end;
      end;
     end;
    end;
    'p','P':begin
     NumberString:=NumberString+LastChar;
     GetChar;
     while LastChar in ['0'..'9'] do begin
      NumberString:=NumberString+LastChar;
      GetChar;
     end;
    end;
    else begin
     while LastChar in ['0'..'9'] do begin
      NumberString:=NumberString+LastChar;
      GetChar;
     end;
     if LastChar in ['.'] then begin
      NumberString:=NumberString+LastChar;
      GetChar;
      while LastChar in ['0'..'9'] do begin
       NumberString:=NumberString+LastChar;
       GetChar;
      end;
      if LastChar in ['e','E'] then begin
       NumberString:=NumberString+LastChar;
       GetChar;
       if LastChar in ['-','+'] then begin
        NumberString:=NumberString+LastChar;
        GetChar;
       end;
       while LastChar in ['0'..'9'] do begin
        NumberString:=NumberString+LastChar;
        GetChar;
       end;
      end;
     end;
    end;
   end;
  end else if LastChar in ['0'..'9'] then begin
   NumberString:=NumberString+LastChar;
   GetChar;
   while LastChar in ['0'..'9'] do begin
    NumberString:=NumberString+LastChar;
    GetChar;
   end;
   if LastChar in ['.'] then begin
    NumberString:=NumberString+LastChar;
    GetChar;
    while LastChar in ['0'..'9'] do begin
     NumberString:=NumberString+LastChar;
     GetChar;
    end;
    if LastChar in ['e','E'] then begin
     NumberString:=NumberString+LastChar;
     GetChar;
     if LastChar in ['-','+'] then begin
      NumberString:=NumberString+LastChar;
      GetChar;
     end;
     while LastChar in ['0'..'9'] do begin
      NumberString:=NumberString+LastChar;
      GetChar;
     end;
    end;
   end;
  end else begin
   MakeError('Syntax error');
   exit;
  end;
  try
   if not StringToFloat(NumberString,FloatValue.Bytes[0],IEEEFormat) then begin
    MakeError('Syntax error');
   end;
  except
   on e:Exception do begin
    MakeError(e.Message);
   end;
  end;
 end;
 function ReadNumber:boolean;
 const mNONE=0;
       mHEXIMAL=1;
       mDECIMAL=2;
       mOCTAL=3;
       mBINARY=4;
       mPACKEDBCD=5;
 type plongword=^longword;
 var Value:int64;
     AfterDigits:longint;
     Negative:boolean;
     NumberString:ansistring;
     Counter,Code,Mode:longint;
     c:ansichar;
     va,vb,vc:TIntegerValue;
  procedure ParseFloat;
  begin
   try
    NumberFloatValue.Count:=0;
    if assigned(CurrentIEEEFormat) then begin
     if StringToFloat(NumberString,NumberFloatValue.Bytes[0],CurrentIEEEFormat^) then begin
      NumberFloatValue.Count:=CurrentIEEEFormat^.Bytes;
     end else begin
      MakeError('Syntax error');
     end;
    end else begin
     MakeError('Syntax error');
    end;
   except
    on e:Exception do begin
     MakeError(e.Message);
    end;
   end;
   if CurrentIEEEFormat^.Bytes>0 then begin
    IsFloat:=true;
   end else begin
    MakeError('Syntax error');
   end;
  end;
 begin
  result:=false;
  NumberFloatValue.Count:=0;
  IsFloat:=false;
  NumberString:='';
  SkipWhiteSpaceOnSameLine;
  Negative:=false;
  case LastChar of
   '-':begin
    Negative:=true;
    GetChar;
   end;
   '+':begin
    GetChar;
   end;
  end;
  if LastChar in [''''] then begin
   ReadString;
   Value:=0;
   IntegerValueSetQWord(NumberIntegerValue,0);
   Counter:=length(StringData);
   while Counter>0 do begin
    IntegerValueShiftLeftInternal(va,NumberIntegerValue,8);
    IntegerValueSetQWord(vb,byte(ansichar(StringData[(length(StringData)-Counter)+1])));
    IntegerValueOr(NumberIntegerValue,va,vb);
    Value:=(Value shl 8) or byte(ansichar(StringData[(length(StringData)-Counter)+1]));
    dec(Counter);
   end;
  end else if LastChar in ['0'..'9'] then begin
   Mode:=mNONE;
   Value:=0;           
   IntegerValueSetQWord(NumberIntegerValue,0);
   if LastChar='0' then begin
    GetChar;
    case LastChar of
     'h','H','x','X':begin
      Mode:=mHEXIMAL;
      GetChar;
     end;
     'o','O','q','Q':begin
      Mode:=mOCTAL;
      GetChar;
     end;
     'b','B','y','Y':begin
      Mode:=mBINARY;
      GetChar;
     end;
     'd','D','t','T':begin
      Mode:=mDECIMAL;
      GetChar;
     end;
     'p','P':begin
      Mode:=mPACKEDBCD;
      GetChar;
     end;
    end;
   end;
   case Mode of
    mHEXIMAL:begin
     while LastChar in ['0'..'9','A'..'F','a'..'f','_'] do begin
      if LastChar<>'_' then begin
       NumberString:=NumberString+LastChar;
      end;
      GetChar;
     end;
    end;
    mOCTAL:begin
     while LastChar in ['0'..'7','_'] do begin
      if LastChar<>'_' then begin
       NumberString:=NumberString+LastChar;
      end;
      GetChar;
     end;
    end;
    mBINARY:begin
     while LastChar in ['0'..'1','_'] do begin
      if LastChar<>'_' then begin
       NumberString:=NumberString+LastChar;
      end;
      GetChar;
     end;
    end;
    mDECIMAL:begin
     while LastChar in ['0'..'9','_'] do begin
      if LastChar<>'_' then begin
       NumberString:=NumberString+LastChar;
      end;
      GetChar;
     end;
    end;
    mPACKEDBCD:begin
     while LastChar in ['0'..'9','_'] do begin
      if LastChar<>'_' then begin
       NumberString:=NumberString+LastChar;
      end;
      GetChar;
     end;
    end;
    else begin
     while LastChar in ['0'..'9','A'..'F','a'..'f','_'] do begin
      if LastChar<>'_' then begin
       NumberString:=NumberString+LastChar;
      end;
      GetChar;
     end;
    end;
   end;
   if (Mode in [mHEXIMAL,mOCTAL,mBINARY,mNONE]) and (LastChar in ['p','P']) then begin
    NumberString:=NumberString+LastChar;
    case Mode of
     mHEXIMAL:begin
      NumberString:='0x'+NumberString;
     end;
     mOCTAL:begin
      NumberString:='0o'+NumberString;
     end;
     mBINARY:begin
      NumberString:='0b'+NumberString;
     end;
     mNONE:begin
      NumberString:='0p'+NumberString;
     end;
    end;
    if Mode in [mHEXIMAL,mOCTAL,mBINARY] then begin
     GetChar;
     if LastChar in ['-','+'] then begin
      NumberString:=NumberString+LastChar;
      GetChar;
     end;
     while LastChar in ['0'..'9'] do begin
      if LastChar<>'_' then begin
       NumberString:=NumberString+LastChar;
      end;
      GetChar;
     end;
    end;
    ParseFloat;
   end else if LastChar='.' then begin
    NumberString:=NumberString+LastChar;
    GetChar;
    case Mode of
     mHEXIMAL:begin
      NumberString:='0x'+NumberString;
      while LastChar in ['0'..'9','A'..'F','a'..'f','_'] do begin
       if LastChar<>'_' then begin
        NumberString:=NumberString+LastChar;
       end;
       GetChar;
      end;
      if LastChar in ['p','P'] then begin
       NumberString:=NumberString+LastChar;
       GetChar;
       if LastChar in ['-','+'] then begin
        NumberString:=NumberString+LastChar;
        GetChar;
       end;
       while LastChar in ['0'..'9'] do begin
        if LastChar<>'_' then begin
         NumberString:=NumberString+LastChar;
        end;
        GetChar;
       end;
      end;
     end;
     mOCTAL:begin
      NumberString:='0o'+NumberString;
      while LastChar in ['0'..'7','_'] do begin
       if LastChar<>'_' then begin
        NumberString:=NumberString+LastChar;
       end;
       GetChar;
      end;
      if LastChar in ['p','P'] then begin
       NumberString:=NumberString+LastChar;
       GetChar;
       if LastChar in ['-','+'] then begin
        NumberString:=NumberString+LastChar;
        GetChar;
       end;
       while LastChar in ['0'..'7'] do begin
        if LastChar<>'_' then begin
         NumberString:=NumberString+LastChar;
        end;
        GetChar;
       end;
      end;
     end;
     mBINARY:begin
      NumberString:='0b'+NumberString;
      while LastChar in ['0'..'1','_'] do begin
       if LastChar<>'_' then begin
        NumberString:=NumberString+LastChar;
       end;
       GetChar;
      end;
      if LastChar in ['p','P'] then begin
       NumberString:=NumberString+LastChar;
       GetChar;
       if LastChar in ['-','+'] then begin
        NumberString:=NumberString+LastChar;
        GetChar;
       end;
       while LastChar in ['0'..'1'] do begin
        if LastChar<>'_' then begin
         NumberString:=NumberString+LastChar;
        end;
        GetChar;
       end;
      end;
     end;
     mPACKEDBCD:begin
      NumberString:='0p'+NumberString;
      while LastChar in ['0'..'9','_'] do begin
       if LastChar<>'_' then begin
        NumberString:=NumberString+LastChar;
       end;
       GetChar;
      end;
     end;
     mNONE,mDECIMAL:begin
      NumberString:='0d'+NumberString;
      while LastChar in ['0'..'9','_'] do begin
       if LastChar<>'_' then begin
        NumberString:=NumberString+LastChar;
       end;
       GetChar;
      end;
      if LastChar in ['e','E'] then begin
       NumberString:=NumberString+LastChar;
       GetChar;
       if LastChar in ['-','+'] then begin
        NumberString:=NumberString+LastChar;
        GetChar;
       end;
       while LastChar in ['0'..'9'] do begin
        if LastChar<>'_' then begin
         NumberString:=NumberString+LastChar;
        end;
        GetChar;
       end;
      end;
     end;
    end;
    ParseFloat;
   end else begin
    if Mode=mNONE then begin
     case LastChar of
      'h','H','x','X':begin
       Mode:=mHEXIMAL;
       GetChar;
      end;
      'o','O','q','Q':begin
       Mode:=mOCTAL;
       GetChar;
      end;
      'y','Y':begin
       Mode:=mBINARY;
       GetChar;
      end;
      't','T':begin
       Mode:=mDECIMAL;
       GetChar;
      end;
      else begin
       if length(NumberString)>0 then begin
        case NumberString[length(NumberString)] of
         'b','B':begin
          Mode:=mBINARY;
          NumberString:=Copy(NumberString,1,length(NumberString)-1);
         end;
         'd','D':begin
          Mode:=mDECIMAL;
          NumberString:=Copy(NumberString,1,length(NumberString)-1);
         end;
        end;
       end;
      end;
     end;
    end;
    case Mode of
     mHEXIMAL:begin
      Value:=0;
      IntegerValueSetQWord(NumberIntegerValue,0);
      for Counter:=1 to length(NumberString) do begin
       c:=NumberString[Counter];
       case c of
        '0'..'9':begin
         IntegerValueShiftLeftInternal(va,NumberIntegerValue,4);
         IntegerValueSetQWord(vb,byte(ansichar(c))-byte(ansichar('0')));
         IntegerValueOr(NumberIntegerValue,va,vb);
         Value:=(Value shl 4) or (byte(ansichar(c))-byte(ansichar('0')));
        end;
        'a'..'f':begin
         IntegerValueShiftLeftInternal(va,NumberIntegerValue,4);
         IntegerValueSetQWord(vb,(byte(ansichar(c))-byte(ansichar('a')))+$a);
         IntegerValueOr(NumberIntegerValue,va,vb);
         Value:=(Value shl 4) or ((byte(ansichar(c))-byte(ansichar('a')))+$a);
        end;
        'A'..'F':begin
         IntegerValueShiftLeftInternal(va,NumberIntegerValue,4);
         IntegerValueSetQWord(vb,(byte(ansichar(c))-byte(ansichar('A')))+$a);
         IntegerValueOr(NumberIntegerValue,va,vb);
         Value:=(Value shl 4) or ((byte(ansichar(c))-byte(ansichar('A')))+$a);
        end;
       end;
      end;
     end;
     mOCTAL:begin
      Value:=0;
      IntegerValueSetQWord(NumberIntegerValue,0);
      for Counter:=1 to length(NumberString) do begin
       c:=NumberString[Counter];
       case c of
        '0'..'7':begin
         IntegerValueShiftLeftInternal(va,NumberIntegerValue,3);
         IntegerValueSetQWord(vb,byte(ansichar(c))-byte(ansichar('0')));
         IntegerValueOr(NumberIntegerValue,va,vb);
         Value:=(Value shl 3) or (byte(ansichar(c))-byte(ansichar('0')));
        end;
       end;
      end;
     end;
     mBINARY:begin
      Value:=0;
      IntegerValueSetQWord(NumberIntegerValue,0);
      for Counter:=1 to length(NumberString) do begin
       c:=NumberString[Counter];
       case c of
        '0'..'1':begin
         IntegerValueShiftLeftInternal(va,NumberIntegerValue,1);
         IntegerValueSetQWord(vb,byte(ansichar(c))-byte(ansichar('0')));
         IntegerValueOr(NumberIntegerValue,va,vb);
         Value:=(Value shl 1) or (byte(ansichar(c))-byte(ansichar('0')));
        end;
       end;
      end;
     end;
     mPACKEDBCD:begin
      if assigned(CurrentIEEEFormat) and (CurrentIEEEFormat^.Bytes=10) then begin
       ParseFloat;
      end else begin
       MakeError('Packed BCD isn''t allowed in this case');
      end;
     end;
     else {mNONE,mDECIMAL:}begin
      Value:=0;
      IntegerValueSetQWord(NumberIntegerValue,0);
      IntegerValueSetQWord(vc,10);
      for Counter:=1 to length(NumberString) do begin
       c:=NumberString[Counter];
       case c of
        '0'..'9':begin
         IntegerValueMul(va,NumberIntegerValue,vc);
         IntegerValueSetQWord(vb,byte(ansichar(c))-byte(ansichar('0')));
         IntegerValueAdd(NumberIntegerValue,va,vb);
         Value:=(Value*10)+(byte(ansichar(c))-byte(ansichar('0')));
        end;
       end;
      end;
     end;
    end;
    if Negative then begin
     IntegerValueNeg(va,NumberIntegerValue);
     NumberIntegerValue:=va;
    end;
   end;
  end;
  NumberString:='';
 end;
 function ReadExpression:TAssemblerExpression;
 var First:boolean;
  function NewNode(Operation:ansichar;Left,Right:TAssemblerExpression;SecondRight:TAssemblerExpression=nil):TAssemblerExpression;
  begin
   result:=TAssemblerExpression.Create;
   result.Operation:=Operation;
   result.Value.ValueType:=AVT_NONE;
   IntegerValueSetQWord(result.Value.IntegerValue,0);
   result.MetaValue:=0;
   result.MetaFlags:=0;
   result.Left:=Left;
   result.Right:=Right;
   result.SecondRight:=SecondRight;
  end;
  function Expression:TAssemblerExpression; forward;
  function Factor:TAssemblerExpression;
  var Node:TAssemblerExpression;
      Operation:ansichar;
      OldValue:int64;
      i,v:longint;
      LastIEEEFormat:PIEEEFormat;
      Parameters:TList;
  begin
   result:=nil;
   if not AreErrors then begin
    SkipWhiteSpaceOnSameLine;
    Operation:=LastChar;
    case Operation of
     '$':begin
      GetChar;
      if LastChar='$' then begin
       GetChar;
       SkipWhiteSpaceOnSameLine;
       Node:=NewNode('H',nil,nil);
       Node.Value.ValueType:=AVT_INT;
       IntegerValueSetQWord(Node.Value.IntegerValue,0);
       Node.MetaValue:=0;
       Node.MetaFlags:=0;
       result:=Node;
      end else begin
       SkipWhiteSpaceOnSameLine;
       Node:=NewNode('h',nil,nil);
       Node.Value.ValueType:=AVT_INT;
       IntegerValueSetQWord(Node.Value.IntegerValue,0);
       Node.MetaValue:=0;
       Node.MetaFlags:=0;
       result:=Node;
      end;
     end;
     '!','~':begin
      GetChar;
      SkipWhiteSpaceOnSameLine;
      Node:=NewNode(Operation,Factor,nil);
      result:=Node;
     end;
     '-':begin
      GetChar;
      SkipWhiteSpaceOnSameLine;
      Node:=NewNode('_',Factor,nil);
      result:=Node;
     end;
     '(':begin
      GetChar;
      SkipWhiteSpaceOnSameLine;
      Node:=NewNode(Operation,Expression,nil);
      result:=Node;
      SkipWhiteSpaceOnSameLine;
      if LastChar=')' then begin
       GetChar;
       SkipWhiteSpaceOnSameLine;
      end else begin
       MakeError(19);
      end;
     end;
     '[':begin
      GetChar;
      Node:=NewNode('m',Expression,nil);
      Node.MetaValue:=1;
      Node.MetaFlags:=0;
      result:=Node;
      SkipWhiteSpaceOnSameLine;
      while LastChar=',' do begin
       GetChar;
       SkipWhiteSpaceOnSameLine;
       Node:=NewNode('+',Node,Expression);
       SkipWhiteSpaceOnSameLine;
      end;
      if LastChar=']' then begin
       GetChar;
       SkipWhiteSpaceOnSameLine;
      end else begin
       MakeError(19);
      end;
     end;
     else begin
      if CheckAlpha then begin
       ReadSymbol;
       SkipWhiteSpaceOnSameLine;
{      if CheckKeyword(KeyCNT_CODE) then begin
        Node:=NewNode('x',nil,nil);
        Node.Value.ValueType:=AVT_INT;
        IntegerValueSetQWord(Node.Value.IntegerValue,IMAGE_SCN_CNT_CODE);
        result:=Node;
       end else if CheckKeyword(KeyCNT_DATA) then begin
        Node:=NewNode('x',nil,nil);
        Node.Value.ValueType:=AVT_INT;
        IntegerValueSetQWord(Node.Value.IntegerValue,IMAGE_SCN_CNT_INITIALIZED_DATA);
        result:=Node;
       end else if CheckKeyword(KeyCNT_BSS) then begin
        Node:=NewNode('x',nil,nil);
        Node.Value.ValueType:=AVT_INT;
        IntegerValueSetQWord(Node.Value.IntegerValue,IMAGE_SCN_CNT_UNINITIALIZED_DATA);
        result:=Node;
       end else if CheckKeyword(KeyCNT_RESOURCE) then begin
        Node:=NewNode('x',nil,nil);
        Node.Value.ValueType:=AVT_INT;
        IntegerValueSetQWord(Node.Value.IntegerValue,IMAGE_SCN_CNT_RESOURCE);
        result:=Node;
       end else if CheckKeyword(KeyMEM_DISCARDABLE) then begin
        Node:=NewNode('x',nil,nil);
        Node.Value.ValueType:=AVT_INT;
        IntegerValueSetQWord(Node.Value.IntegerValue,IMAGE_SCN_MEM_DISCARDABLE);
        result:=Node;
       end else if CheckKeyword(KeyMEM_NOT_CACHED) then begin
        Node:=NewNode('x',nil,nil);
        Node.Value.ValueType:=AVT_INT;
        IntegerValueSetQWord(Node.Value.IntegerValue,IMAGE_SCN_MEM_NOT_CACHED);
        result:=Node;
       end else if CheckKeyword(KeyMEM_NOT_PAGED) then begin
        Node:=NewNode('x',nil,nil);
        Node.Value.ValueType:=AVT_INT;
        IntegerValueSetQWord(Node.Value.IntegerValue,IMAGE_SCN_MEM_NOT_PAGED);
        result:=Node;
       end else if CheckKeyword(KeyMEM_SHARED) then begin
        Node:=NewNode('x',nil,nil);
        Node.Value.ValueType:=AVT_INT;
        IntegerValueSetQWord(Node.Value.IntegerValue,IMAGE_SCN_MEM_SHARED);
        result:=Node;
       end else if CheckKeyword(KeyMEM_EXECUTE) then begin
        Node:=NewNode('x',nil,nil);
        Node.Value.ValueType:=AVT_INT;
        IntegerValueSetQWord(Node.Value.IntegerValue,IMAGE_SCN_MEM_EXECUTE);
        result:=Node;
       end else if CheckKeyword(KeyMEM_READ) then begin
        Node:=NewNode('x',nil,nil);
        Node.Value.ValueType:=AVT_INT;
        IntegerValueSetQWord(Node.Value.IntegerValue,IMAGE_SCN_MEM_READ);
        result:=Node;
       end else if CheckKeyword(KeyMEM_WRITE) then begin
        Node:=NewNode('x',nil,nil);
        Node.Value.ValueType:=AVT_INT;
        IntegerValueSetQWord(Node.Value.IntegerValue,IMAGE_SCN_MEM_WRITE);
        result:=Node;
       end else}if CheckKeyword(Key__HERE__) then begin
        Node:=NewNode('h',nil,nil);
        Node.Value.ValueType:=AVT_INT;
        IntegerValueSetQWord(Node.Value.IntegerValue,0);
        Node.MetaValue:=0;
        Node.MetaFlags:=0;
        result:=Node;
       end else if CheckKeyword(Key__BASE__) then begin
        Node:=NewNode('H',nil,nil);
        Node.Value.ValueType:=AVT_INT;
        IntegerValueSetQWord(Node.Value.IntegerValue,0);
        Node.MetaValue:=0;
        Node.MetaFlags:=0;
        result:=Node;
       end else if CheckKeyword(KeyADDRESS) then begin
        Node:=NewNode('k',Expression,nil);
        Node.MetaValue:=KeyADDRESS;
        Node.MetaFlags:=0;
        result:=Node;
       end else if CheckKeyword(KeyDISPLACEMENT) then begin
        Node:=NewNode('k',Expression,nil);
        Node.MetaValue:=KeyDISPLACEMENT;
        Node.MetaFlags:=0;
        result:=Node;
       end else if CheckKeyword(KeySHORT) then begin
        Node:=NewNode('k',Expression,nil);
        Node.MetaValue:=KeySHORT;
        Node.MetaFlags:=0;
        result:=Node;
       end else if CheckKeyword(KeyNEAR) then begin
        Node:=NewNode('k',Expression,nil);
        Node.MetaValue:=KeyNEAR;
        Node.MetaFlags:=0;
        result:=Node;
       end else if CheckKeyword(KeyFAR) then begin
        Node:=NewNode('k',Expression,nil);
        Node.MetaValue:=KeyFAR;
        Node.MetaFlags:=0;
        result:=Node;
       end else if CheckKeyword(KeyTO) then begin
        Node:=NewNode('k',Expression,nil);
        Node.MetaValue:=KeyTO;
        Node.MetaFlags:=0;
        result:=Node;
       end else if CheckKeyword(KeySTRICT) then begin
        Node:=NewNode('k',Expression,nil);
        Node.MetaValue:=KeySTRICT;
        Node.MetaFlags:=0;
        result:=Node;
       end else if CheckKeyword(KeyNOSPLIT) then begin
        Node:=NewNode('k',Expression,nil);
        Node.MetaValue:=KeyNOSPLIT;
        Node.MetaFlags:=0;
        result:=Node;
       end else if CheckKeyword(KeyREL) then begin
        Node:=NewNode('k',Expression,nil);
        Node.MetaValue:=KeyREL;
        Node.MetaFlags:=0;
        result:=Node;
       end else if CheckKeyword(KeyABS) then begin
        Node:=NewNode('k',Expression,nil);
        Node.MetaValue:=KeyABS;
        Node.MetaFlags:=0;
        result:=Node;
       end else if CheckKeyword(KeySEG16) then begin
        Node:=NewNode('k',Expression,nil);
        Node.MetaValue:=KeySEG16;
        Node.MetaFlags:=0;
        result:=Node;
       end else if CheckKeyword(KeyOFS16) then begin
        Node:=NewNode('k',Expression,nil);
        Node.MetaValue:=KeyOFS16;
        Node.MetaFlags:=0;
        result:=Node;
       end else if CheckKeyword(Key__NOBASE__) then begin
        SkipWhiteSpaceOnSameLine;
        if LastChar='(' then begin
         GetChar;
         SkipWhiteSpaceOnSameLine;
         Node:=NewNode('k',Expression,nil);
         Node.MetaValue:=Key__NOBASE__;
         Node.MetaFlags:=0;
         result:=Node;
         SkipWhiteSpaceOnSameLine;
         if LastChar=')' then begin
          GetChar;
          SkipWhiteSpaceOnSameLine;
         end else begin
          MakeError(19);
         end;
        end else begin
         MakeError(19);
        end;
       end else if CheckKeyword(Key__GOT__) then begin
        SkipWhiteSpaceOnSameLine;
        if LastChar='(' then begin
         GetChar;
         SkipWhiteSpaceOnSameLine;
         Node:=NewNode('k',Expression,nil);
         Node.MetaValue:=Key__GOT__;
         Node.MetaFlags:=0;
         result:=Node;
         SkipWhiteSpaceOnSameLine;
         if LastChar=')' then begin
          GetChar;
          SkipWhiteSpaceOnSameLine;
         end else begin
          MakeError(19);
         end;
        end else begin
         MakeError(19);
        end;
       end else if CheckKeyword(Key__GOTPC__) then begin
        SkipWhiteSpaceOnSameLine;
        if LastChar='(' then begin
         GetChar;
         SkipWhiteSpaceOnSameLine;
         Node:=NewNode('k',Expression,nil);
         Node.MetaValue:=Key__GOTPC__;
         Node.MetaFlags:=0;
         result:=Node;
         SkipWhiteSpaceOnSameLine;
         if LastChar=')' then begin
          GetChar;
          SkipWhiteSpaceOnSameLine;
         end else begin
          MakeError(19);
         end;
        end else begin
         MakeError(19);
        end;
       end else if CheckKeyword(Key__GOTOFF__) then begin
        SkipWhiteSpaceOnSameLine;
        if LastChar='(' then begin
         GetChar;
         SkipWhiteSpaceOnSameLine;
         Node:=NewNode('k',Expression,nil);
         Node.MetaValue:=Key__GOTOFF__;
         Node.MetaFlags:=0;
         result:=Node;
         SkipWhiteSpaceOnSameLine;
         if LastChar=')' then begin
          GetChar;
          SkipWhiteSpaceOnSameLine;
         end else begin
          MakeError(19);
         end;
        end else begin
         MakeError(19);
        end;
       end else if CheckKeyword(Key__GOTTPOFF__) then begin
        SkipWhiteSpaceOnSameLine;
        if LastChar='(' then begin
         GetChar;
         SkipWhiteSpaceOnSameLine;
         Node:=NewNode('k',Expression,nil);
         Node.MetaValue:=Key__GOTTPOFF__;
         Node.MetaFlags:=0;
         result:=Node;
         SkipWhiteSpaceOnSameLine;
         if LastChar=')' then begin
          GetChar;
          SkipWhiteSpaceOnSameLine;
         end else begin
          MakeError(19);
         end;
        end else begin
         MakeError(19);
        end;
       end else if CheckKeyword(Key__PLT__) then begin
        SkipWhiteSpaceOnSameLine;
        if LastChar='(' then begin
         GetChar;
         SkipWhiteSpaceOnSameLine;
         Node:=NewNode('k',Expression,nil);
         Node.MetaValue:=Key__PLT__;
         Node.MetaFlags:=0;
         result:=Node;
         SkipWhiteSpaceOnSameLine;
         if LastChar=')' then begin
          GetChar;
          SkipWhiteSpaceOnSameLine;
         end else begin
          MakeError(19);
         end;
        end else begin
         MakeError(19);
        end;
       end else if CheckKeyword(Key__TLSIE__) then begin
        SkipWhiteSpaceOnSameLine;
        if LastChar='(' then begin
         GetChar;
         SkipWhiteSpaceOnSameLine;
         Node:=NewNode('k',Expression,nil);
         Node.MetaValue:=Key__TLSIE__;
         Node.MetaFlags:=0;
         result:=Node;
         SkipWhiteSpaceOnSameLine;
         if LastChar=')' then begin
          GetChar;
          SkipWhiteSpaceOnSameLine;
         end else begin
          MakeError(19);
         end;
        end else begin
         MakeError(19);
        end;
       end else if CheckKeyword(Key__RELOCATION__) then begin
        SkipWhiteSpaceOnSameLine;
        if LastChar='(' then begin
         GetChar;
         SkipWhiteSpaceOnSameLine;
         Node:=NewNode('k',Expression,nil);
         Node.MetaValue:=Key__RELOCATION__;
         Node.MetaFlags:=0;
         result:=Node;
         SkipWhiteSpaceOnSameLine;
         if LastChar=')' then begin
          GetChar;
          SkipWhiteSpaceOnSameLine;
         end else begin
          MakeError(19);
         end;
        end else begin
         MakeError(19);
        end;
       end else if CheckKeyword(Key__NO_RELOCATION__) then begin
        SkipWhiteSpaceOnSameLine;
        if LastChar='(' then begin
         GetChar;
         SkipWhiteSpaceOnSameLine;
         Node:=NewNode('k',Expression,nil);
         Node.MetaValue:=Key__NO_RELOCATION__;
         Node.MetaFlags:=0;
         Node.MarkAsNoRelocation;
         result:=Node;
         SkipWhiteSpaceOnSameLine;
         if LastChar=')' then begin
          GetChar;
          SkipWhiteSpaceOnSameLine;
         end else begin
          MakeError(19);
         end;
        end else begin
         MakeError(19);
        end;
       end else if CheckPrefix(PrefixA16) then begin
        Node:=NewNode('p',Expression,nil);
        Node.MetaValue:=PrefixA16;
        Node.MetaFlags:=0;
        result:=Node;
       end else if CheckPrefix(PrefixA32) then begin
        Node:=NewNode('p',Expression,nil);
        Node.MetaValue:=PrefixA32;
        Node.MetaFlags:=0;
        result:=Node;
       end else if CheckPrefix(PrefixA64) then begin
        Node:=NewNode('p',Expression,nil);
        Node.MetaValue:=PrefixA64;
        Node.MetaFlags:=0;
        result:=Node;
       end else if CheckPrefix(PrefixASP) then begin
        Node:=NewNode('p',Expression,nil);
        Node.MetaValue:=PrefixASP;
        Node.MetaFlags:=0;
        result:=Node;
       end else if CheckPrefix(PrefixO16) then begin
        Node:=NewNode('p',Expression,nil);
        Node.MetaValue:=PrefixO16;
        Node.MetaFlags:=0;
        result:=Node;
       end else if CheckPrefix(PrefixO32) then begin
        Node:=NewNode('p',Expression,nil);
        Node.MetaValue:=PrefixO32;
        Node.MetaFlags:=0;
        result:=Node;
       end else if CheckPrefix(PrefixO64) then begin
        Node:=NewNode('p',Expression,nil);
        Node.MetaValue:=PrefixO64;
        Node.MetaFlags:=0;
        result:=Node;
       end else if CheckPrefix(PrefixOSP) then begin
        Node:=NewNode('p',Expression,nil);
        Node.MetaValue:=PrefixOSP;
        Node.MetaFlags:=0;
        result:=Node;
       end else if CheckKeyword(KeyBYTE) then begin
        Node:=NewNode('t',Expression,nil);
        Node.MetaValue:=8;
        Node.MetaFlags:=0;
        result:=Node;
       end else if CheckKeyword(KeyWORD) then begin
        Node:=NewNode('t',Expression,nil);
        Node.MetaValue:=16;
        Node.MetaFlags:=0;
        result:=Node;
       end else if CheckKeyword(KeyDWORD) or CheckKeyword(KeyFLOAT) then begin
        Node:=NewNode('t',Expression,nil);
        Node.MetaValue:=32;
        Node.MetaFlags:=0;
        result:=Node;
       end else if CheckKeyword(KeyQWORD) or CheckKeyword(KeyDOUBLE) then begin
        Node:=NewNode('t',Expression,nil);
        Node.MetaValue:=64;
        Node.MetaFlags:=0;
        result:=Node;
       end else if CheckKeyword(KeyTWORD) or CheckKeyword(KeyEXTENDED) then begin
        Node:=NewNode('t',Expression,nil);
        Node.MetaValue:=80;
        Node.MetaFlags:=0;
        result:=Node;
       end else if CheckKeyword(KeyDQWORD) or CheckKeyword(KeyOWORD) or CheckKeyword(KeyXMMWORD) then begin
        Node:=NewNode('t',Expression,nil);
        Node.MetaValue:=128;
        Node.MetaFlags:=0;
        result:=Node;
       end else if CheckKeyword(KeyYWORD) or CheckKeyword(KeyYMMWORD) then begin
        Node:=NewNode('t',Expression,nil);
        Node.MetaValue:=256;
        Node.MetaFlags:=0;
        result:=Node;
       end else if CheckKeyword(KeyZWORD) or CheckKeyword(KeyZMMWORD) then begin
        Node:=NewNode('t',Expression,nil);
        Node.MetaValue:=512;
        Node.MetaFlags:=0;
        result:=Node;
       end else if CheckKeyword(KeyPTR) then begin
        Node:=NewNode('m',Expression,nil);
        Node.MetaValue:=0;
        Node.MetaFlags:=0;
        result:=Node;
       end else if CheckKeyword(KeyOFFSET) then begin
        Node:=NewNode('o',Expression,nil);
        Node.MetaFlags:=0;
        result:=Node;
       end else if (SymbolType=stKEYWORD) and
                   (SymbolValue=Key__COUNTER__) then begin
        Node:=NewNode('c',nil,nil);
        result:=Node;
       end else if (SymbolType=stKEYWORD) and
                   (SymbolValue=Key__INTEGER__) then begin
        SkipWhiteSpaceOnSameLine;
        if LastChar='(' then begin
         GetChar;
         SkipWhiteSpaceOnSameLine;
         Node:=NewNode('i',Expression,nil);
         result:=Node;
         SkipWhiteSpaceOnSameLine;
         if LastChar=')' then begin
          GetChar;
          SkipWhiteSpaceOnSameLine;
         end else begin
          MakeError(19);
         end;
        end else begin
         MakeError(19);
        end;
       end else if (SymbolType=stKEYWORD) and
                   (SymbolValue=Key__PARAMETER__) then begin
        SkipWhiteSpaceOnSameLine;
        if LastChar='(' then begin
         GetChar;
         SkipWhiteSpaceOnSameLine;
         Node:=Expression;
         while Node.Optimize(self) do begin
         end;
         if (Node.Operation='x') and (Node.Value.ValueType=AVT_INT) then begin
          result:=NewNode('P',nil,nil);
          result.MetaValue:=IntegerValueGetInt64(ValueToRawInt(self,Node.Value,true));
          result.MetaFlags:=0;
          SkipWhiteSpaceOnSameLine;
          if LastChar=')' then begin
           GetChar;
           SkipWhiteSpaceOnSameLine;
          end else begin
           MakeError(19);
          end;
         end else begin
          MakeError('longint constant expected');
         end;
        end else begin
         MakeError(19);
        end;
       end else if (SymbolType=stKEYWORD) and
                   (SymbolValue=Key__RAWINT__) then begin
        SkipWhiteSpaceOnSameLine;
        if LastChar='(' then begin
         GetChar;
         SkipWhiteSpaceOnSameLine;
         Node:=NewNode('I',Expression,nil);
         result:=Node;
         SkipWhiteSpaceOnSameLine;
         if LastChar=')' then begin
          GetChar;
          SkipWhiteSpaceOnSameLine;
         end else begin
          MakeError(19);
         end;
        end else begin
         MakeError(19);
        end;
       end else if (SymbolType=stKEYWORD) and
                   (SymbolValue=Key__STRING__) then begin
        SkipWhiteSpaceOnSameLine;
        if LastChar='(' then begin
         GetChar;
         SkipWhiteSpaceOnSameLine;
         Node:=NewNode('T',Expression,nil);
         result:=Node;
         SkipWhiteSpaceOnSameLine;
         if LastChar=')' then begin
          GetChar;
          SkipWhiteSpaceOnSameLine;
         end else begin
          MakeError(19);
         end;
        end else begin
         MakeError(19);
        end;
       end else if (SymbolType=stKEYWORD) and
                   (SymbolValue=Key__DEFINED__) then begin
        SkipWhiteSpaceOnSameLine;
        if LastChar='(' then begin
         GetChar;
         SkipWhiteSpaceOnSameLine;
         if CheckAlpha then begin
          ReadAlpha;
          result:=NewNode('D',nil,nil);
          result.Value.ValueType:=AVT_STRING;
          result.Value.StringValue:=OriginalSymbolName;
          SkipWhiteSpaceOnSameLine;
          if LastChar=')' then begin
           GetChar;
           SkipWhiteSpaceOnSameLine;
          end else begin
           MakeError(19);
          end;
         end else if LastChar in ['''','"'] then begin
          ReadString;
          result:=NewNode('D',nil,nil);
          result.Value.ValueType:=AVT_STRING;
          result.Value.StringValue:=StringData;
          SkipWhiteSpaceOnSameLine;
          if LastChar=')' then begin
           GetChar;
           SkipWhiteSpaceOnSameLine;
          end else begin
           MakeError(19);
          end;
         end else begin
          MakeError('Identifier expeced');
         end;
        end else begin
         MakeError(19);
        end;
       end else if (SymbolType=stKEYWORD) and
                   (SymbolValue=Key__STRCOPY__) then begin
        SkipWhiteSpaceOnSameLine;
        if LastChar='(' then begin
         GetChar;
         SkipWhiteSpaceOnSameLine;
         Node:=NewNode('F',Expression,nil);
         SkipWhiteSpaceOnSameLine;
         if LastChar=',' then begin
          SkipWhiteSpaceOnSameLine;
          GetChar;
         end else begin
          MakeError(19);
         end;
         Node.Right:=Expression;
         if LastChar=',' then begin
          SkipWhiteSpaceOnSameLine;
          GetChar;
         end else begin
          MakeError(19);
         end;
         Node.SecondRight:=Expression;
         Node.MetaValue:=EF__STRCOPY__;
         Node.MetaFlags:=0;
         result:=Node;
         SkipWhiteSpaceOnSameLine;
         if LastChar=')' then begin
          GetChar;
          SkipWhiteSpaceOnSameLine;
         end else begin
          MakeError(19);
         end;
        end else begin
         MakeError(19);
        end;
       end else if (SymbolType=stKEYWORD) and
                   (SymbolValue=Key__STRLEN__) then begin
        SkipWhiteSpaceOnSameLine;
        if LastChar='(' then begin
         GetChar;
         SkipWhiteSpaceOnSameLine;
         Node:=NewNode('F',Expression,nil);
         Node.MetaValue:=EF__STRLEN__;
         Node.MetaFlags:=0;
         result:=Node;
         SkipWhiteSpaceOnSameLine;
         if LastChar=')' then begin
          GetChar;
          SkipWhiteSpaceOnSameLine;
         end else begin
          MakeError(19);
         end;
        end else begin
         MakeError(19);
        end;
       end else if (SymbolType=stKEYWORD) and
                   (SymbolValue=Key__UTF8__) then begin
        SkipWhiteSpaceOnSameLine;
        if LastChar='(' then begin
         GetChar;
         SkipWhiteSpaceOnSameLine;
         Node:=NewNode('F',Expression,nil);
         Node.MetaValue:=EF__UTF8__;
         Node.MetaFlags:=0;
         result:=Node;
         SkipWhiteSpaceOnSameLine;
         if LastChar=')' then begin
          GetChar;
          SkipWhiteSpaceOnSameLine;
         end else begin
          MakeError(19);
         end;
        end else begin
         MakeError(19);
        end;
       end else if (SymbolType=stKEYWORD) and
                   ((SymbolValue=Key__UTF16__) or (SymbolValue=Key__UTF16LE__)) then begin
        SkipWhiteSpaceOnSameLine;
        if LastChar='(' then begin
         GetChar;
         SkipWhiteSpaceOnSameLine;
         Node:=NewNode('F',Expression,nil);
         Node.MetaValue:=EF__UTF16LE__;
         Node.MetaFlags:=0;
         result:=Node;
         SkipWhiteSpaceOnSameLine;
         if LastChar=')' then begin
          GetChar;
          SkipWhiteSpaceOnSameLine;
         end else begin
          MakeError(19);
         end;
        end else begin
         MakeError(19);
        end;
       end else if (SymbolType=stKEYWORD) and
                   (SymbolValue=Key__UTF16BE__) then begin
        SkipWhiteSpaceOnSameLine;
        if LastChar='(' then begin
         GetChar;
         SkipWhiteSpaceOnSameLine;
         Node:=NewNode('F',Expression,nil);
         Node.MetaValue:=EF__UTF16BE__;
         Node.MetaFlags:=0;
         result:=Node;
         SkipWhiteSpaceOnSameLine;
         if LastChar=')' then begin
          GetChar;
          SkipWhiteSpaceOnSameLine;
         end else begin
          MakeError(19);
         end;
        end else begin
         MakeError(19);
        end;
       end else if (SymbolType=stKEYWORD) and
                   ((SymbolValue=Key__UTF32__) or (SymbolValue=Key__UTF32LE__)) then begin
        SkipWhiteSpaceOnSameLine;
        if LastChar='(' then begin
         GetChar;
         SkipWhiteSpaceOnSameLine;
         Node:=NewNode('F',Expression,nil);
         Node.MetaValue:=EF__UTF32LE__;
         Node.MetaFlags:=0;
         result:=Node;
         SkipWhiteSpaceOnSameLine;
         if LastChar=')' then begin
          GetChar;
          SkipWhiteSpaceOnSameLine;
         end else begin
          MakeError(19);
         end;
        end else begin
         MakeError(19);
        end;
       end else if (SymbolType=stKEYWORD) and
                   (SymbolValue=Key__UTF32BE__) then begin
        SkipWhiteSpaceOnSameLine;
        if LastChar='(' then begin
         GetChar;
         SkipWhiteSpaceOnSameLine;
         Node:=NewNode('F',Expression,nil);
         Node.MetaValue:=EF__UTF32BE__;
         Node.MetaFlags:=0;
         result:=Node;
         SkipWhiteSpaceOnSameLine;
         if LastChar=')' then begin
          GetChar;
          SkipWhiteSpaceOnSameLine;
         end else begin
          MakeError(19);
         end;
        end else begin
         MakeError(19);
        end;
       end else if (SymbolType=stKEYWORD) and
                   ((SymbolValue=Key__FLOAT8__) or
                    (SymbolValue=Key__FLOAT16__) or
                    (SymbolValue=Key__FLOAT32__) or
                    (SymbolValue=Key__FLOAT64__) or
                    (SymbolValue=Key__FLOAT80__) or
                    (SymbolValue=Key__FLOAT128__) or
                    (SymbolValue=Key__FLOAT256__) or
                    (SymbolValue=Key__FLOAT512__)) then begin
        LastIEEEFormat:=CurrentIEEEFormat;
        try
         case SymbolValue of
          Key__FLOAT8__:begin
           v:=8;
           CurrentIEEEFormat:=@IEEEFormat8;
          end;
          Key__FLOAT16__:begin
           v:=16;
           CurrentIEEEFormat:=@IEEEFormat16;
          end;
          Key__FLOAT32__:begin
           v:=32;
           CurrentIEEEFormat:=@IEEEFormat32;
          end;
          Key__FLOAT64__:begin
           v:=64;
           CurrentIEEEFormat:=@IEEEFormat64;
          end;
          Key__FLOAT80__:begin
           v:=80;
           CurrentIEEEFormat:=@IEEEFormat80;
          end;
          Key__FLOAT128__:begin
           v:=128;
           CurrentIEEEFormat:=@IEEEFormat128;
          end;
          Key__FLOAT256__:begin
           v:=256;
           CurrentIEEEFormat:=@IEEEFormat256;
          end;
          else {Key__FLOAT512__:}begin
           v:=512;
           CurrentIEEEFormat:=@IEEEFormat512;
          end;
         end;
         SkipWhiteSpaceOnSameLine;
         if LastChar='(' then begin
          GetChar;
          SkipWhiteSpaceOnSameLine;
          Node:=NewNode('f',Expression,nil);
          Node.MetaValue:=v;
          Node.MetaFlags:=0;
          result:=Node;
          SkipWhiteSpaceOnSameLine;
          if LastChar=')' then begin
           GetChar;
           SkipWhiteSpaceOnSameLine;
          end else begin
           MakeError(19);
          end;
         end else begin
          MakeError(19);
         end;
        finally
         CurrentIEEEFormat:=LastIEEEFormat;
        end;
       end else if SymbolType=stREGISTER then begin
        if LastChar=':' then begin
         GetChar;
         if SymbolValue in [RegES,RegCS,RegSS,RegDS,RegFS,RegGS,RegSEGR6,RegSEGR7] then begin
          OldValue:=SymbolValue;
          Node:=NewNode('$',Expression,nil);
          Node.MetaValue:=OldValue;
          Node.MetaFlags:=0;
          result:=Node;
         end else begin
          MakeError(35);
          result:=Expression;
         end;
        end else begin
         Node:=NewNode('r',nil,nil);
         Node.MetaValue:=SymbolValue;
         Node.MetaFlags:=0;
         result:=Node;
        end;
       end else if SymbolType=stUSER then begin
        if UserSymbolList[SymbolValue].SymbolType in [ustDEFINE,ustMACRO,ustSCRIPTMACRO{,ustSTRUCT}] then begin
         MakeError(27);
        end else begin
         if UserSymbolList[SymbolValue].SymbolType=ustREPLACER then begin
          Parameters:=TList.Create;
          try
           SkipWhiteSpaceOnSameLine;
           if LastChar='(' then begin
            GetChar;
            SkipWhiteSpaceOnSameLine;
            while not ((LastChar in [#10,#0]) or AreErrors) do begin
             Parameters.Add(Expression);
             SkipWhiteSpaceOnSameLine;
             if LastChar=',' then begin
              GetChar;
              SkipWhiteSpaceOnSameLine;
             end else begin
              break;
             end;
            end;
            if LastChar=')' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
            end else begin
             MakeError('")" expected');
            end;
           end;
           Node:=TAssemblerExpression.Create;
           Node.Assign(UserSymbolList[SymbolValue].Expression);
           Node.AssignParameters(Parameters);
          finally
           for i:=0 to Parameters.Count-1 do begin
            if assigned(Parameters[i]) then begin
             TObject(Parameters[i]).Free;
             Parameters[i]:=nil;
            end;
           end;
           Parameters.Free;
          end;
         end else begin
          Node:=NewNode('v',nil,nil);
          Node.MetaValue:=SymbolValue;
          Node.MetaFlags:=0;
         end;
         result:=Node;
        end;
       end else begin
        MakeError(14);
       end;
      end else begin
       if LastChar in ['"'] then begin
        ReadString;
        Node:=NewNode('x',nil,nil);
        Node.Value.ValueType:=AVT_STRING;
        Node.Value.StringValue:=StringData;
        result:=Node;
       end else begin
        ReadNumber;
        SkipWhiteSpaceOnSameLine;
        if IsFloat then begin
         Node:=NewNode('x',nil,nil); //!!f
         Node.Value.ValueType:=AVT_FLOAT;
         Node.Value.FloatValue:=NumberFloatValue;
         result:=Node;
        end else begin
         Node:=NewNode('x',nil,nil);
         Node.Value.ValueType:=AVT_INT;
         Node.Value.IntegerValue:=NumberIntegerValue;
         result:=Node;
        end;
       end;
      end;
     end;
    end;
   end;
   First:=false;
  end;
(*
 function BitTruncateOperationExpression:TAssemblerExpression;
  var Node:TAssemblerExpression;
      Operation:ansichar;
  begin
   result:=nil;
   if not AreErrors then begin
    Node:=ShortIFOperationExpression;
    Operation:=LastChar;
    while (Operation=#$a7) and not AreErrors do begin
     First:=false;
     GetChar;
     SkipWhiteSpaceOnSameLine;
     Node:=NewNode(Operation,Node,ShortIFOperationExpression);
     Operation:=LastChar;
    end;
    result:=Node;
   end;
  end;*)
  function MulDivExpression:TAssemblerExpression;
  var Node:TAssemblerExpression;
      Operation:ansichar;
  begin
   result:=nil;
   if not AreErrors then begin
    Node:=Factor;
    SkipWhiteSpaceOnSameLine;
    Operation:=LastChar;
    while (Operation in ['*','/']) and not AreErrors do begin
     First:=false;
     GetChar;
     SkipWhiteSpaceOnSameLine;
     Node:=NewNode(Operation,Node,Factor);
     Operation:=LastChar;
    end;
    result:=Node;
   end;
  end;
  function AdditionalExpression:TAssemblerExpression;
  var Node:TAssemblerExpression;
      Operation:ansichar;
  begin
   result:=nil;
   if not AreErrors then begin
    Node:=MulDivExpression;
    Operation:=LastChar;
    while (Operation in ['+','-']) and not AreErrors do begin
     First:=false;
     GetChar;
     SkipWhiteSpaceOnSameLine;
     Node:=NewNode(Operation,Node,MulDivExpression);
     Operation:=LastChar;
    end;
    result:=Node;
   end;
  end;
  function ShiftExpression:TAssemblerExpression;
  var Node:TAssemblerExpression;
      Operation:ansistring;
  begin
   result:=nil;
   if not AreErrors then begin
    Node:=AdditionalExpression;
    SkipWhiteSpaceOnSameLine;
    Operation:=LastChar;
    if (LastChar in ['<','>']) and (PeekChar=LastChar) then begin
     GetChar;
     Operation:=Operation+LastChar;
    end;
    while ((Operation='<<') or (Operation='>>')) and not AreErrors do begin
     First:=false;
     GetChar;
     SkipWhiteSpaceOnSameLine;
     if Operation='<<' then begin
      Node:=NewNode('s',Node,AdditionalExpression);
     end else if Operation='>>' then begin
      Node:=NewNode('S',Node,AdditionalExpression);
     end else begin
      MakeError('Internal error');
      break;
     end;
     Operation:=LastChar;
     if (LastChar in ['<','>']) and (PeekChar=LastChar) then begin
      GetChar;
      Operation:=Operation+LastChar;
     end;
    end;
    result:=Node;
   end;
  end;
  function CompareExpression:TAssemblerExpression;
  var Node:TAssemblerExpression;
      Operation:ansistring;
  begin
   result:=nil;
   if not AreErrors then begin
    Node:=ShiftExpression;
    SkipWhiteSpaceOnSameLine;
    Operation:=LastChar;
    if (LastChar in ['<','>']) and (PeekChar='=') then begin
     GetChar;
     Operation:=Operation+LastChar;
    end;
    while ((Operation='<') or (Operation='>') or (Operation='<=') or (Operation='>=')) and not AreErrors do begin
     First:=false;
     GetChar;
     SkipWhiteSpaceOnSameLine;
     if Operation='<' then begin
      Node:=NewNode('<',Node,ShiftExpression);
     end else if Operation='>' then begin
      Node:=NewNode('>',Node,ShiftExpression);
     end else if Operation='<=' then begin
      Node:=NewNode('{',Node,ShiftExpression);
     end else if Operation='>=' then begin
      Node:=NewNode('}',Node,ShiftExpression);
     end else begin
      MakeError('Internal error');
      break;
     end;
     Operation:=LastChar;
     if (LastChar in ['<','>']) and (PeekChar='=') then begin
      GetChar;
      Operation:=Operation+LastChar;
     end;
    end;
    result:=Node;
   end;
  end;
  function EqualityExpression:TAssemblerExpression;
  var Node:TAssemblerExpression;
      Operation:ansistring;
  begin
   result:=nil;
   if not AreErrors then begin
    Node:=CompareExpression;
    SkipWhiteSpaceOnSameLine;
    Operation:=LastChar;
    if (LastChar in ['=','!']) and (PeekChar='=') then begin
     GetChar;
     Operation:=Operation+LastChar;
    end;
    while ((Operation='==') or (Operation='!=')) and not AreErrors do begin
     First:=false;
     GetChar;
     SkipWhiteSpaceOnSameLine;
     if Operation='==' then begin
      Node:=NewNode('=',Node,CompareExpression);
     end else if Operation='!=' then begin
      Node:=NewNode('#',Node,CompareExpression);
     end else begin
      MakeError('Internal error');
      break;
     end;
     Operation:=LastChar;
     if (LastChar in ['=','!']) and (PeekChar='=') then begin
      GetChar;
      Operation:=Operation+LastChar;
     end;
    end;
    result:=Node;
   end;
  end;
  function BitwiseANDExpression:TAssemblerExpression;
  var Node:TAssemblerExpression;
      Operation:ansistring;
  begin
   result:=nil;
   if not AreErrors then begin
    Node:=EqualityExpression;
    SkipWhiteSpaceOnSameLine;
    Operation:=LastChar;
    if (LastChar='&') and (PeekChar='&') then begin
     Operation:=Operation+LastChar;
    end;
    while (Operation='&') and not AreErrors do begin
     First:=false;
     GetChar;
     SkipWhiteSpaceOnSameLine;
     Node:=NewNode('&',Node,EqualityExpression);
     Operation:=LastChar;
     if (LastChar='&') and (PeekChar='&') then begin
      Operation:=Operation+LastChar;
     end;
    end;
    result:=Node;
   end;
  end;
  function BitwiseXORExpression:TAssemblerExpression;
  var Node:TAssemblerExpression;
      Operation:ansichar;
  begin
   result:=nil;
   if not AreErrors then begin
    Node:=BitwiseANDExpression;
    SkipWhiteSpaceOnSameLine;
    Operation:=LastChar;
    while (Operation='^') and not AreErrors do begin
     First:=false;
     GetChar;
     SkipWhiteSpaceOnSameLine;
     Node:=NewNode('^',Node,BitwiseANDExpression);
     Operation:=LastChar;
    end;
    result:=Node;
   end;
  end;
  function BitwiseORExpression:TAssemblerExpression;
  var Node:TAssemblerExpression;
      Operation:ansistring;
  begin
   result:=nil;
   if not AreErrors then begin
    Node:=BitwiseXORExpression;
    SkipWhiteSpaceOnSameLine;
    Operation:=LastChar;
    if (LastChar='|') and (PeekChar='|') then begin
     Operation:=Operation+LastChar;
    end;
    while (Operation='|') and not AreErrors do begin
     First:=false;
     GetChar;
     SkipWhiteSpaceOnSameLine;
     Node:=NewNode('|',Node,BitwiseXORExpression);
     Operation:=LastChar;
     if (LastChar='|') and (PeekChar='|') then begin
      Operation:=Operation+LastChar;
     end;
    end;
    result:=Node;
   end;
  end;
  function LogicalANDOperationExpression:TAssemblerExpression;
  var Node:TAssemblerExpression;
      Operation:ansistring;
      Right,SecondRight:TAssemblerExpression;
  begin
   result:=nil;
   if not AreErrors then begin
    Node:=BitwiseORExpression;
    SkipWhiteSpaceOnSameLine;
    Operation:=LastChar;
     if (LastChar='&') and (PeekChar='&') then begin
     GetChar;
     Operation:=Operation+LastChar;
    end;
    while (Operation='&&') and not AreErrors do begin
     First:=false;
     GetChar;
     SkipWhiteSpaceOnSameLine;
     if Operation='||' then begin
      Node:=NewNode('l',Node,BitwiseORExpression);
     end else begin
      MakeError('Internal error');
      break;
     end;
     Operation:=LastChar;
     if (LastChar='&') and (PeekChar='&') then begin
      GetChar;
      Operation:=Operation+LastChar;
     end;
    end;
    result:=Node;
   end;
  end;
  function LogicalOROperationExpression:TAssemblerExpression;
  var Node:TAssemblerExpression;
      Operation:ansistring;
      Right,SecondRight:TAssemblerExpression;
  begin
   result:=nil;
   if not AreErrors then begin
    Node:=LogicalANDOperationExpression;
    SkipWhiteSpaceOnSameLine;
    Operation:=LastChar;
    if (LastChar='|') and (PeekChar='|') then begin
     GetChar;
     Operation:=Operation+LastChar;
    end;
    while (Operation='||') and not AreErrors do begin
     First:=false;
     GetChar;
     SkipWhiteSpaceOnSameLine;
     if Operation='||' then begin
      Node:=NewNode('l',Node,LogicalANDOperationExpression);
     end else begin
      MakeError('Internal error');
      break;
     end;
     Operation:=LastChar;
     if (LastChar='|') and (PeekChar='|') then begin
      GetChar;
      Operation:=Operation+LastChar;
     end;
    end;
    result:=Node;
   end;
  end;
  function ShortIFOperationExpression:TAssemblerExpression;
  var Node:TAssemblerExpression;
      Operation:ansichar;
      Right,SecondRight:TAssemblerExpression;
  begin
   result:=nil;
   if not AreErrors then begin
    Node:=LogicalOROperationExpression;
    SkipWhiteSpaceOnSameLine;
    Operation:=LastChar;
    while (Operation='?') and not AreErrors do begin
     First:=false;
     GetChar;
     SkipWhiteSpaceOnSameLine;
     Right:=Expression;
     SkipWhiteSpaceOnSameLine;
     if LastChar=':' then begin
      GetChar;
      SkipWhiteSpaceOnSameLine;
     end else begin
      MakeError(51);
      break;
     end;
     SecondRight:=Expression;
     Node:=NewNode(Operation,Node,Right,SecondRight);
     Operation:=LastChar;
    end;
    result:=Node;
   end;
  end;
  function Expression:TAssemblerExpression;
  begin
   if AreErrors then begin
    result:=nil;
   end else begin
    result:=ShortIFOperationExpression;
   end;
  end;
var LastAllowedKeywordKinds:TKeywordKinds;
 begin
  First:=true;
  LastAllowedKeywordKinds:=AllowedKeywordKinds;
  try
   AllowedKeywordKinds:=[kkEXPRESSION,kkREGISTER];
   result:=Expression;
   while assigned(result) and result.Optimize(self) and not AreErrors do begin
   end;
  finally
   AllowedKeywordKinds:=LastAllowedKeywordKinds;
  end;
 end;
 function IsOpcode:boolean;
 begin
  result:=SymbolType=stOPCODE;
  if result then begin
   OpcodeIndex:=SymbolValue;
  end else begin
   OpcodeIndex:=OpNONE;
  end;
 end;
 function IsPrefix:boolean;
 begin
  result:=SymbolType=stPrefix;
  if result then begin
   PrefixIndex:=SymbolValue;
  end else begin
   PrefixIndex:=PrefixNONE;
  end;
 end;
 function GetRegister:TRegister;
 begin
  if SymbolType=stRegister then begin
   result:=SymbolValue;
  end else begin
   result:=RegNONE;
  end;
 end;
 procedure ParseOperand(var Operand:TOperand;const IsOpcode:boolean);
 type PRegisterCount=^TRegisterCount;
      TRegisterCount=record
       WhichRegister:TRegister;
       Expression:TAssemblerExpression;
      end;
      TRegisterCounts=array of TRegisterCount;
 var ForceBits,ForceDisplacmentSize:longword;
     IsMemory:boolean;
     RegisterCounts:TRegisterCounts;
     CountRegisterCounts:longint;
  procedure AddRegister(const WhichRegister:TRegister;const Expression:TAssemblerExpression;const Negative:boolean);
  var i:longint;
      OldExpression:TAssemblerExpression;
  begin
   for i:=0 to CountRegisterCounts-1 do begin
    if RegisterCounts[i].WhichRegister=WhichRegister then begin
     OldExpression:=RegisterCounts[i].Expression;
     RegisterCounts[i].Expression:=TAssemblerExpression.Create;
     if Negative then begin
      RegisterCounts[i].Expression.Operation:='-';
     end else begin
      RegisterCounts[i].Expression.Operation:='+';
     end;
     RegisterCounts[i].Expression.Left:=OldExpression;
     if assigned(Expression) then begin
      RegisterCounts[i].Expression.Right:=Expression;
     end else begin
      RegisterCounts[i].Expression.Right:=TAssemblerExpression.Create;
      RegisterCounts[i].Expression.Right.Operation:='x';
      RegisterCounts[i].Expression.Right.Value.ValueType:=AVT_INT;
      RegisterCounts[i].Expression.Right.Value.IntegerValue:=IntSet(1);
     end;
     while RegisterCounts[i].Expression.Optimize(self) do begin
     end;
     exit;
    end;
   end;
   i:=CountRegisterCounts;
   inc(CountRegisterCounts);
   if CountRegisterCounts>length(RegisterCounts) then begin
    SetLength(RegisterCounts,CountRegisterCounts*2);
   end;
   RegisterCounts[i].WhichRegister:=WhichRegister;
   if assigned(Expression) then begin
    if Negative then begin
     RegisterCounts[i].Expression:=TAssemblerExpression.Create;
     RegisterCounts[i].Expression.Operation:='-';
     RegisterCounts[i].Expression.Left:=TAssemblerExpression.Create;
     RegisterCounts[i].Expression.Left.Operation:='x';
     RegisterCounts[i].Expression.Left.Value.ValueType:=AVT_INT;
     RegisterCounts[i].Expression.Left.Value.IntegerValue:=IntSet(0);
     RegisterCounts[i].Expression.Right:=Expression;
    end else begin
     RegisterCounts[i].Expression:=Expression;
    end;
    while RegisterCounts[i].Expression.Optimize(self) do begin
    end;
   end else begin
    RegisterCounts[i].Expression:=TAssemblerExpression.Create;
    RegisterCounts[i].Expression.Operation:='x';
    RegisterCounts[i].Expression.Value.ValueType:=AVT_INT;
    if Negative then begin
     RegisterCounts[i].Expression.Value.IntegerValue:=IntSet(-1);
    end else begin
     RegisterCounts[i].Expression.Value.IntegerValue:=IntSet(1);
    end;
   end;
  end;
  procedure ParseExpression;
  begin
   SkipWhiteSpaceOnSameLine;
   if CheckNumberFull or CheckAlpha then begin
    Operand.Value:=ReadExpression;
   end;               
  end;
  procedure ScanTermForSize;
  var Expression:TAssemblerExpression;
  begin
   if assigned(Operand.Value) and (Operand.Value.Operation='t') then begin
    if assigned(Operand.Value.Left) then begin
     ForceBits:=Operand.Value.MetaValue;
     Expression:=Operand.Value.Left;
     Operand.Value.Left:=nil;
     Operand.Value.Free;
     Operand.Value:=Expression;
    end;
   end;
  end;
  procedure OptimizeTerm;
  begin
   while assigned(Operand.Value) and Operand.Value.Optimize(self) and not AreErrors do begin
   end;
  end;
  procedure ProcessTerm(AExpression:TAssemblerExpression;LastOperation:ansichar;InBrackets:boolean);
  begin
   if assigned(AExpression) then begin
    case AExpression.Operation of
     'k':begin
      case AExpression.MetaValue of
       KeyADDRESS:begin
       end;
       KeyDISPLACEMENT:begin
       end;
       KeySHORT:begin
        Operand.Flags:=Operand.Flags or OF_SHORT;
       end;
       KeyNEAR:begin
        Operand.Flags:=Operand.Flags or OF_NEAR;
       end;
       KeyFAR:begin
        Operand.Flags:=Operand.Flags or OF_FAR;
       end;
       KeyTO:begin
        Operand.Flags:=Operand.Flags or OF_TO;
       end;
       KeySTRICT:begin
        Operand.Flags:=Operand.Flags or OF_STRICT;
       end;
       KeyNOSPLIT:begin
        Operand.EAFlags:=Operand.EAFlags or EAF_TIMESTWO;
       end;
       KeyREL:begin
        Operand.EAFlags:=Operand.EAFlags or EAF_REL;
       end;
       KeyABS:begin
        Operand.EAFlags:=Operand.EAFlags or EAF_ABS;
       end;
       KeySEG16:begin
        if (LastOperation<>'-') and assigned(AExpression.Left) and (AExpression.Left.Operation='v') then begin
         Operand.FixUpExpressionFlags:=Operand.FixUpExpressionFlags or FUEF_SEG16;
        end else begin
         MakeError(19);
        end;
       end;
       KeyOFS16:begin
        if (LastOperation<>'-') and assigned(AExpression.Left) and (AExpression.Left.Operation='v') then begin
         Operand.FixUpExpressionFlags:=Operand.FixUpExpressionFlags or FUEF_OFS16;
        end else begin
         MakeError(19);
        end;
       end;
       Key__NOBASE__:begin
        Operand.FixUpExpressionFlags:=Operand.FixUpExpressionFlags or FUEF_NOBASE;
       end;
       Key__GOT__:begin
        Operand.FixUpExpressionFlags:=Operand.FixUpExpressionFlags or FUEF_GOT;
       end;
       Key__GOTPC__:begin
        Operand.FixUpExpressionFlags:=Operand.FixUpExpressionFlags or FUEF_GOTPC;
       end;
       Key__GOTOFF__:begin
        Operand.FixUpExpressionFlags:=Operand.FixUpExpressionFlags or FUEF_GOTOFF;
       end;
       Key__GOTTPOFF__:begin
        Operand.FixUpExpressionFlags:=Operand.FixUpExpressionFlags or FUEF_GOTTPOFF;
       end;
       Key__PLT__:begin
        Operand.FixUpExpressionFlags:=Operand.FixUpExpressionFlags or FUEF_PLT;
       end;
       Key__TLSIE__:begin
        Operand.FixUpExpressionFlags:=Operand.FixUpExpressionFlags or FUEF_TLSIE;
       end;
       Key__RELOCATION__:begin
        Operand.FixUpExpressionFlags:=Operand.FixUpExpressionFlags or FUEF_RELOCATION;
       end;
      end;
      ProcessTerm(AExpression.Left,LastOperation,InBrackets);
     end;
     'p':begin
      case AExpression.MetaValue of
       PrefixA16,PrefixA32,PrefixA64,PrefixASP:begin
        if (OpcodePrefixAddressSize<>0) and (OpcodePrefixAddressSize<>AExpression.MetaValue) then begin
         MakeError(57);
        end else begin
         OpcodePrefixAddressSize:=AExpression.MetaValue;
        end;
       end;
       PrefixO16,PrefixO32,PrefixO64,PrefixOSP:begin
        if (OpcodePrefixOpcodeSize<>0) and (OpcodePrefixOpcodeSize<>AExpression.MetaValue) then begin
         MakeError(58);
        end else begin
         OpcodePrefixOpcodeSize:=AExpression.MetaValue;
        end;
       end;
      end;
      ProcessTerm(AExpression.Left,LastOperation,InBrackets);
     end;
     't':begin
      if InBrackets then begin
       ForceDisplacmentSize:=AExpression.MetaValue;
      end else begin
       ForceBits:=AExpression.MetaValue;
      end;
      ProcessTerm(AExpression.Left,LastOperation,InBrackets);
     end;
     'm':begin
      IsMemory:=true;
      ProcessTerm(AExpression.Left,LastOperation,InBrackets or (AExpression.MetaValue<>0));
     end;
     'o':begin
      ProcessTerm(AExpression.Left,LastOperation,InBrackets);
     end;
     '.':begin
      ProcessTerm(AExpression.Left,LastOperation,InBrackets);
     end;
     ':':begin
      ProcessTerm(AExpression.Left,LastOperation,InBrackets);
     end;
     '$':begin
      if AExpression.MetaValue in [RegES,RegCS,RegSS,RegDS,RegFS,RegGS,RegSEGR6,RegSEGR7] then begin
       if (OpcodePrefixSegment<>0) and (OpcodePrefixSegment<>AExpression.MetaValue) then begin
        MakeError(36);
       end else begin
        OpcodePrefixSegment:=AExpression.MetaValue;
       end;
      end else begin
       MakeError(35);
      end;
      ProcessTerm(AExpression.Left,LastOperation,InBrackets);
     end;
     '-','+':begin
      ProcessTerm(AExpression.Left,LastOperation,InBrackets);
      if (LastOperation='-') and (AExpression.Operation='-') then begin
       ProcessTerm(AExpression.Right,'+',InBrackets);
      end else begin
       ProcessTerm(AExpression.Right,AExpression.Operation,InBrackets);
      end;
     end;
     '*':begin
      if assigned(AExpression.Left) and assigned(AExpression.Right) then begin
       if (AExpression.Left.Operation='r') and (AExpression.Right.Operation<>'r') then begin
        AddRegister(AExpression.Left.MetaValue,AExpression.Right,LastOperation='-');
        FreeAndNil(AExpression.Left);
        AExpression.Right:=nil;
        AExpression.Operation:='x';
        AExpression.Value.ValueType:=AVT_INT;
        IntegerValueSetQWord(AExpression.Value.IntegerValue,0);
       end else if (AExpression.Left.Operation<>'r') and (AExpression.Right.Operation='r') then begin
        AddRegister(AExpression.Right.MetaValue,AExpression.Left,LastOperation='-');
        AExpression.Left:=nil;
        FreeAndNil(AExpression.Right);
        AExpression.Operation:='x';
        AExpression.Value.ValueType:=AVT_INT;
        IntegerValueSetQWord(AExpression.Value.IntegerValue,0);
       end else if (AExpression.Left.Operation='r') and (AExpression.Right.Operation='r') then begin
        MakeError(2);
       end;
      end;
     end;
     'r':begin
      AddRegister(AExpression.MetaValue,nil,LastOperation='-');
      AExpression.Operation:='x';
      AExpression.Value.ValueType:=AVT_INT;
      IntegerValueSetQWord(AExpression.Value.IntegerValue,0);
     end;
    end;
   end;
  end;
  function TrimTerm(AExpression:TAssemblerExpression):boolean;
  var TempExpression:TAssemblerExpression;
  begin
   result:=false;
   if assigned(AExpression) then begin
    case AExpression.Operation of
     'k','p','t','m','o','$':begin
      TempExpression:=AExpression.Left;
      if assigned(TempExpression) then begin
       AExpression.Operation:=TempExpression.Operation;
       AExpression.Value:=TempExpression.Value;
       AExpression.MetaValue:=TempExpression.MetaValue;
       AExpression.MetaFlags:=TempExpression.MetaFlags;
       AExpression.Left:=TempExpression.Left;
       AExpression.Right:=TempExpression.Right;
       TempExpression.Operation:='x';
       TempExpression.Left:=nil;
       TempExpression.Right:=nil;
       TempExpression.Destroy;
       TrimTerm(AExpression);
       result:=true;
      end;
     end;
     else begin
      if assigned(AExpression.Left) then begin
       result:=result or TrimTerm(AExpression.Left);
      end;
      if assigned(AExpression.Right) then begin
       result:=result or TrimTerm(AExpression.Right);
      end;
     end;
    end;
   end;
  end;
  procedure CheckTerm(AExpression:TAssemblerExpression);
  begin
   if assigned(AExpression) then begin
    case AExpression.Operation of
     'r':begin
      MakeError(37);
     end;
     else begin
      if assigned(AExpression.Left) then begin
       CheckTerm(AExpression.Left);
      end;
      if assigned(AExpression.Right) then begin
       CheckTerm(AExpression.Right);
      end;
     end;
    end;
   end;
  end;
 var v:int64;
     rs:TOperandFlags;
     IsConstant:boolean;
     i:longint;
     RegisterCount:PRegisterCount;
     IntegerValue:TIntegerValue;
     DecoratorString,DecoratorContentString:ansistring;
 begin
  RegisterCounts:=nil;
  CountRegisterCounts:=0;
  try
   IsMemory:=false;
   Operand.Flags:=0;
   Operand.DecoratorFlags:=0;
   Operand.FixUpExpressionFlags:=0;
   Operand.DisplacmentSize:=0;
   Operand.BaseRegister:=RegNONE;
   Operand.IndexRegister:=RegNONE;
   Operand.RIPRegister:=false;
   Operand.Scale:=nil;
   Operand.Value:=nil;
   Operand.HintBase:=0;
   Operand.HintType:=EAH_NOHINT;
   Operand.EAFlags:=0;
 {$ifdef DEBUGGER}
   Operand.Column:=CurrentColumn;
 {$endif}
   ForceBits:=0;
   ForceDisplacmentSize:=0;
   ParseExpression;
   SkipWhiteSpaceOnSameLine;
   while (LastChar='{') and not AreErrors do begin
    GetChar;
    SkipWhiteSpaceOnSameLine;
    DecoratorString:='';
    while (LastChar<>'}') and not ((LastChar=#0) or AreErrors) do begin
     DecoratorString:=DecoratorString+LastChar;
     GetChar;
    end;
    DecoratorString:=LowerCase(trim(DecoratorString));
    SkipWhiteSpaceOnSameLine;
    if LastChar='}' then begin
     GetChar;
     SkipWhiteSpaceOnSameLine;
     if length(DecoratorString)>0 then begin
      i:=1;
      while i<=length(DecoratorString) do begin
       DecoratorContentString:=trim(ParseStringContent(DecoratorString,[','],i,true));
       if length(DecoratorContentString)>0 then begin
        if DecoratorContentString='z' then begin
         Operand.DecoratorFlags:=Operand.DecoratorFlags or Z_VAL0;
        end else if DecoratorContentString='1to2' then begin
         Operand.DecoratorFlags:=Operand.DecoratorFlags or (BRDCAST_VAL0 or BR_1TO2);
        end else if DecoratorContentString='1to4' then begin
         Operand.DecoratorFlags:=Operand.DecoratorFlags or (BRDCAST_VAL0 or BR_1TO4);
        end else if DecoratorContentString='1to8' then begin
         Operand.DecoratorFlags:=Operand.DecoratorFlags or (BRDCAST_VAL0 or BR_1TO8);
        end else if DecoratorContentString='1to16' then begin
         Operand.DecoratorFlags:=Operand.DecoratorFlags or (BRDCAST_VAL0 or BR_1TO16);
        end else if DecoratorContentString='rn-sae' then begin
         Operand.DecoratorFlags:=Operand.DecoratorFlags or (ODF_ER or ODF_SAE);
         Code^.Instruction.evex_rm:=BRC_RN;
        end else if DecoratorContentString='rd-sae' then begin
         Operand.DecoratorFlags:=Operand.DecoratorFlags or (ODF_ER or ODF_SAE);
         Code^.Instruction.evex_rm:=BRC_RD;
        end else if DecoratorContentString='ru-sae' then begin
         Operand.DecoratorFlags:=Operand.DecoratorFlags or (ODF_ER or ODF_SAE);
         Code^.Instruction.evex_rm:=BRC_RU;
        end else if DecoratorContentString='rz-sae' then begin
         Operand.DecoratorFlags:=Operand.DecoratorFlags or (ODF_ER or ODF_SAE);
         Code^.Instruction.evex_rm:=BRC_RZ;
        end else if DecoratorContentString='sae' then begin
         Operand.DecoratorFlags:=Operand.DecoratorFlags or ODF_SAE;
         Code^.Instruction.evex_rm:=BRC_SAE;
        end else if DecoratorContentString='k0' then begin
         Operand.DecoratorFlags:=Operand.DecoratorFlags or OPMASK_K0;
        end else if DecoratorContentString='k1' then begin
         Operand.DecoratorFlags:=Operand.DecoratorFlags or OPMASK_K1;
        end else if DecoratorContentString='k2' then begin
         Operand.DecoratorFlags:=Operand.DecoratorFlags or OPMASK_K2;
        end else if DecoratorContentString='k3' then begin
         Operand.DecoratorFlags:=Operand.DecoratorFlags or OPMASK_K3;
        end else if DecoratorContentString='k4' then begin
         Operand.DecoratorFlags:=Operand.DecoratorFlags or OPMASK_K4;
        end else if DecoratorContentString='k5' then begin
         Operand.DecoratorFlags:=Operand.DecoratorFlags or OPMASK_K5;
        end else if DecoratorContentString='k6' then begin
         Operand.DecoratorFlags:=Operand.DecoratorFlags or OPMASK_K6;
        end else if DecoratorContentString='k7' then begin
         Operand.DecoratorFlags:=Operand.DecoratorFlags or OPMASK_K7;
        end else begin
         writeln(DecoratorContentString);
        end;
       end;
      end;
     end else begin
      MakeError('Decorator is empty');
     end;
    end else begin
     MakeError('Decorator syntax error');
    end;
   end;
   if assigned(Operand.Value) then begin
    ScanTermForSize;
    OptimizeTerm;
    ProcessTerm(Operand.Value,'+',false);
    OptimizeTerm;
    while (assigned(Operand.Value) and TrimTerm(Operand.Value)) and not AreErrors do begin
     OptimizeTerm;
    end;
    ScanTermForSize;
    OptimizeTerm;
    CheckTerm(Operand.Value);
    OptimizeTerm;
    for i:=0 to CountRegisterCounts-1 do begin
     RegisterCount:=@RegisterCounts[i];
     if assigned(RegisterCount^.Expression) then begin
      if (RegisterCount^.Expression.Operation='x') and
        (RegisterCount^.Expression.Value.ValueType=AVT_INT) and
        IntegerValueIsZero(RegisterCount^.Expression.Value.IntegerValue) then begin
       // Ignore
      end else if (RegisterCount^.Expression.Operation='x') and
                  (RegisterCount^.Expression.Value.ValueType=AVT_INT) and
                  IntegerValueIsOne(RegisterCount^.Expression.Value.IntegerValue) then begin
       if RegisterCount^.WhichRegister=RegRIP then begin
        Operand.RIPRegister:=true;
        Operand.Flags:=Operand.Flags or OF_IP_REL;
       end else if Operand.BaseRegister=RegNONE then begin
        Operand.BaseRegister:=RegisterCount^.WhichRegister;
       end else if Operand.IndexRegister=RegNONE then begin
        Operand.IndexRegister:=RegisterCount^.WhichRegister;
        FreeAndNil(Operand.Scale);
        Operand.Scale:=TAssemblerExpression.Create;
        Operand.Scale.Operation:='x';
        Operand.Scale.Value.ValueType:=AVT_INT;
        IntegerValueSetQWord(Operand.Scale.Value.IntegerValue,1);
       end else begin
        MakeError(37);
       end;
      end else begin
       if not assigned(Operand.Scale) then begin
        Operand.Scale:=RegisterCount^.Expression;
        RegisterCount^.Expression:=nil;
       end else begin
        MakeError(19);
       end;
       if Operand.IndexRegister=RegNONE then begin
        Operand.IndexRegister:=RegisterCount^.WhichRegister;
       end else begin
        MakeError(19);
       end;
      end;
     end else begin
      MakeError(71);
     end;
    end;
    if Operand.RIPRegister then begin
     if (Operand.BaseRegister<>RegNONE) or (Operand.IndexRegister<>RegNONE) then begin
      MakeError('RIP register can''t combined with other registers');
     end;
    end;
   end;
{  case Operand.BaseRegister of
    RegK0:begin
     Operand.DecoratorFlags:=Operand.DecoratorFlags or OPMASK_K0;
     Operand.BaseRegister:=RegNONE;
    end;
    RegK1:begin
     Operand.DecoratorFlags:=Operand.DecoratorFlags or OPMASK_K1;
     Operand.BaseRegister:=RegNONE;
    end;
    RegK2:begin
     Operand.DecoratorFlags:=Operand.DecoratorFlags or OPMASK_K2;
     Operand.BaseRegister:=RegNONE;
    end;
    RegK3:begin
     Operand.DecoratorFlags:=Operand.DecoratorFlags or OPMASK_K3;
     Operand.BaseRegister:=RegNONE;
    end;
    RegK4:begin
     Operand.DecoratorFlags:=Operand.DecoratorFlags or OPMASK_K4;
     Operand.BaseRegister:=RegNONE;
    end;
    RegK5:begin
     Operand.DecoratorFlags:=Operand.DecoratorFlags or OPMASK_K5;
     Operand.BaseRegister:=RegNONE;
    end;
    RegK6:begin
     Operand.DecoratorFlags:=Operand.DecoratorFlags or OPMASK_K6;
     Operand.BaseRegister:=RegNONE;
    end;
    RegK7:begin
     Operand.DecoratorFlags:=Operand.DecoratorFlags or OPMASK_K7;
     Operand.BaseRegister:=RegNONE;
    end;
   end;{}
   if not assigned(Operand.Scale) then begin
    Operand.Scale:=TAssemblerExpression.Create;
    Operand.Scale.Operation:='x';
    Operand.Scale.Value.ValueType:=AVT_INT;
    IntegerValueSetQWord(Operand.Scale.Value.IntegerValue,1);
   end;
   if IsOpcode then begin
    if IsMemory then begin
     // Memory
     Operand.Flags:=Operand.Flags or OF_MEMORY_ANY;
     if (Operand.IndexRegister=RegNONE) and (Operand.BaseRegister=RegNONE) then begin
      if ((CurrentBits=64) and ((Operand.EAFlags and EAF_ABS)=0)) and
         (((GD_REL in GlobalDefaults) and ((Operand.EAFlags and EAF_FSGS)=0)) or
          ((Operand.EAFlags and EAF_REL)<>0)) then begin
       Operand.Flags:=Operand.Flags or OF_IP_REL;
      end else begin
       Operand.Flags:=Operand.Flags or OF_MEM_OFFS;
      end;
     end;
     if Operand.IndexRegister<>RegNONE then begin
      if ((not RegisterTemplates[Operand.IndexRegister].RegisterClass) and OF_XMMREG)=0 then begin
       Operand.Flags:=Operand.Flags or OF_XMEM;
      end else if ((not RegisterTemplates[Operand.IndexRegister].RegisterClass) and OF_YMMREG)=0 then begin
       Operand.Flags:=Operand.Flags or OF_YMEM;
      end else if ((not RegisterTemplates[Operand.IndexRegister].RegisterClass) and OF_ZMMREG)=0 then begin
       Operand.Flags:=Operand.Flags or OF_ZMEM;
      end;
     end;
     if Operand.HintType=EAH_NOHINT then begin
      if (Operand.BaseRegister<>RegNONE) and (Operand.BaseRegister=Operand.IndexRegister) then begin
       Operand.HintType:=EAH_SUMMED;
      end else if Operand.BaseRegister<>RegNONE then begin
       Operand.HintBase:=Operand.BaseRegister;
       Operand.HintType:=EAH_MAKEBASE;
      end else if Operand.IndexRegister<>RegNONE then begin
       Operand.HintBase:=Operand.IndexRegister;
       Operand.HintType:=EAH_NOTBASE;
      end;
     end;
    end else if (Operand.BaseRegister=RegNONE) and (Operand.IndexRegister=RegNONE) then begin
     // Immediate
     Operand.Flags:=Operand.Flags or OF_IMMEDIATE;
     if ForceBits=0 then begin
      IsConstant:=(not assigned(Operand.Value)) or (Operand.Value.IsConstant(self) and not Operand.Value.HasOperation(['v']));
      if IsConstant then begin
       if assigned(Operand.Value) then begin
        IntegerValue:=ValueToRawInt(self,Operand.Value.Evaluate(self,true),false);
       end else begin
        IntegerValueSetQWord(IntegerValue,0);
       end;
       if IntegerValueIs32Bit(IntegerValue) then begin
        v:=IntegerValueGetInt64(IntegerValue);
        if v=1 then begin
         Operand.Flags:=Operand.Flags or OF_UNITY;
        end;
        if (OptimizationLevel>=0) and ((Operand.Flags and OF_STRICT)=0) then begin
         if (longword(v+128)<=255) then begin
          Operand.Flags:=Operand.Flags or OF_SBYTEDWORD;
         end;
         if (word(v+128)<=255) then begin
          Operand.Flags:=Operand.Flags or OF_SBYTEWORD;
         end;
         if v<=$ffffffff then begin
          Operand.Flags:=Operand.Flags or OF_UDWORD;
         end;
         if (v+$80000000)<=$ffffffff then begin
          Operand.Flags:=Operand.Flags or OF_SDWORD;
         end;
        end;
       end;
      end;
     end;
     if Operand.IndexRegister<>RegNONE then begin
      MakeError(37);
     end;
    end else begin
     // Register
     if (Operand.Flags and not OF_TO)<>0 then begin
      rs:=Operand.Flags and SIZE_MASK;
     end else begin
      rs:=0;
     end;
     Operand.Flags:=(Operand.Flags and OF_TO) or (OF_REGISTER or RegisterTemplates[Operand.BaseRegister].RegisterClass);
     if (rs and (Operand.Flags and SIZE_MASK))<>rs then begin
      MakeWarning('Register size specification ignored');
     end;
     if Operand.IndexRegister<>RegNONE then begin
      MakeError(37);
     end;
    end;
    if ForceBits<>0 then begin
     Operand.Flags:=Operand.Flags and not (OF_BITS8 or OF_BITS16 or OF_BITS32 or OF_BITS64 or OF_BITS80 or OF_BITS128 or OF_BITS256 or OF_BITS512);
     case ForceBits of
      8:begin
       Operand.Flags:=Operand.Flags or OF_BITS8;
      end;
      16:begin
       Operand.Flags:=Operand.Flags or OF_BITS16;
      end;
      32:begin
       Operand.Flags:=Operand.Flags or OF_BITS32;
      end;
      64:begin
       Operand.Flags:=Operand.Flags or OF_BITS64;
      end;
      80:begin
       Operand.Flags:=Operand.Flags or OF_BITS80;
      end;
      128:begin
       Operand.Flags:=Operand.Flags or OF_BITS128;
      end;
      256:begin
       Operand.Flags:=Operand.Flags or OF_BITS256;
      end;
      512:begin
       Operand.Flags:=Operand.Flags or OF_BITS512;
      end;
      else begin
       MakeError('Invalid operand size specification');
      end;
     end;
    end;
    if ForceDisplacmentSize<>0 then begin
     Operand.EAFlags:=Operand.EAFlags and not (EAF_BYTEOFFS or EAF_WORDOFFS);
     case ForceDisplacmentSize of
      8:begin
       Operand.DisplacmentSize:=8;      
       Operand.EAFlags:=Operand.EAFlags or EAF_BYTEOFFS;
      end;
      16:begin
       Operand.DisplacmentSize:=16;
       Operand.EAFlags:=Operand.EAFlags or EAF_WORDOFFS;
      end;
      32:begin
       Operand.DisplacmentSize:=32;
       Operand.EAFlags:=Operand.EAFlags or EAF_WORDOFFS;
      end;
      64:begin
       Operand.DisplacmentSize:=64;
       Operand.EAFlags:=Operand.EAFlags or EAF_WORDOFFS;
      end;
      else begin
       MakeError('Invalid size specification in effective address');
      end;
     end;
    end;
   end;
  finally
   for i:=0 to CountRegisterCounts-1 do begin
    FreeAndNil(RegisterCounts[i].Expression);
   end;
   SetLength(RegisterCounts,0);
  end;
 end;
 procedure DoOptimize(LastCode:PCode);
 begin
  if assigned(LastCode) then begin
   OptimizeCode(LastCode,nil);
  end else begin
   OptimizeCode(StartCode,nil);
  end;
 end;
 procedure ParserPass(OneInstruction,IsGroup:boolean);
 var Counter,CodeSymbolIndex,StructSymbolIndex,CountArguments,ArgumentIndex,Index,NestedLevel:longint;
     OldLastCode,OldPreLastCode,DownCode:PCode;
     CodeList:array of PCode;
     CodeListCount:longint;
     OldCurrentFileName:ansistring;
     OldCurrentLineNumber,OldCurrentColumn,OldCurrentSource:longint;
     LastCurrentLineNumber:longint;
     Symbol:TUserSymbol;
     Expression:TAssemblerExpression;
     MacroParameter,MacroContent,ScriptContent,TempString:ansistring;
     NestedBrackets:ansistring;
     Level:longint;
     MultiLine,IsNewLine,VA_ARGS:boolean;
     Segment:PAssemblerSegment;
     Section:PAssemblerSection;
     IntValue:int64;
     TempOperand:TOperand;
     Lines,Parameters,Locals:TStringList;
     StringLineIndex,LocalPosition:longint;
     MacroSymbol:TUserSymbol;
     MacroValueIndex:int64;
     StringLine,StringLineStringValue,ParameterName,ParameterStringValue,LocalName,LocalStringValue,MacroStringValue:ansistring;
     StringLinePosition,StringLineLength,StringPosition,StringLength:longint;
     ParameterIndex,LocalIndex:longint;
     IntegerValue,OtherIntegerValue:TIntegerValue;
{$ifdef SASMBESEN}
     BESENPArguments:array of PBESENValue;
     BESENArguments:array of TBESENValue;
     BESENResultValue:TBESENValue;
{$endif}
     TerminateChar:ansichar;
  procedure ShowParsingStatus;
  var S:ansistring;
  begin
  if assigned(Status) then begin
    if CurrentSource=SourceDefines then begin
     S:='(defines)';
    end else if CurrentSource>0 then begin
     S:='(file)['+FileStringList[CurrentSource-1]+']';
    end else if CurrentSource<0 then begin
     S:='(macro)['+UserSymbolList[-(CurrentSource+1)].Name+']';
    end else begin
     S:='(unknown)[?]';
    end;
    ShowStatus('Parsing '+S+'('+INTTOSTR(CurrentLineNumber)+','+INTTOSTR(CurrentColumn)+')');
   end;
  end;
  procedure ParseGroup(Error:longint=22);
  begin
   SkipWhiteSpaceOnSameLine;
   if LastChar='{' then begin
    GetChar;
    SkipWhiteSpaceOnSameLine;
    if LastChar='}' then begin
     GetChar;
    end else begin
     ParserPass(false,true);
     SkipWhiteSpaceOnSameLine;
     if LastChar='}' then begin
      GetChar;
     end else begin
      MakeError(Error);
     end;
    end;
   end else begin
    MakeError(Error);
   end;
   SkipWhiteSpaceOnSameLine;
  end;
  procedure ParseGroupToSkip(Error:longint=22);
  var Level:longint;
      TerminateChar:ansichar;
  begin
   SkipWhiteSpaceOnSameLine;
   if LastChar='{' then begin
    GetChar;
    Level:=1;
    while not AreErrors do begin
     case LastChar of
      #0:begin
       break;
      end;
      '{':begin
       inc(Level);
       GetChar;
      end;
      '}':begin
       dec(Level);
       if Level<=0 then begin
        break;
       end else begin
        GetChar;
       end;
      end;
      '''','"':begin
       TerminateChar:=LastChar;
       GetChar;
       while not AreErrors do begin
        case LastChar of
         #0:begin
          break;
         end;
         '''','"':begin
          if LastChar=TerminateChar then begin
           break;
          end else begin
           GetChar;
          end;
         end;
         '\':begin
          GetChar;
          GetChar;
         end;
         else begin
          GetChar;
         end;
        end;
       end;
       if LastChar=TerminateChar then begin
        GetChar;
       end else begin
        MakeError('Unterminated string');
       end;
      end;
      else begin
       GetChar;
      end;
     end;
    end;
    if LastChar='}' then begin
     GetChar;
     SkipWhiteSpaceOnSameLine;
    end else begin
     MakeError(Error);
    end;
   end else begin
    MakeError(Error);
   end;
  end;
  function ParseGroupToString(Error:longint=22):ansistring;
  var Level:longint;
      TerminateChar:ansichar;
  begin
   result:='';
   SkipWhiteSpaceOnSameLine;
   if LastChar='{' then begin
    GetChar;
    Level:=1;
    while not AreErrors do begin
     case LastChar of
      #0:begin
       break;
      end;
      '{':begin
       result:=result+'{';
       inc(Level);
       GetChar;
      end;
      '}':begin
       dec(Level);
       if Level<=0 then begin
        break;
       end else begin
        result:=result+'}';
        GetChar;
       end;
      end;
      '''','"':begin
       TerminateChar:=LastChar;
       result:=result+LastChar;
       GetChar;
       while not AreErrors do begin
        case LastChar of
         #0:begin
          break;
         end;
         '''','"':begin
          if LastChar=TerminateChar then begin
           break;
          end else begin
           result:=result+LastChar;
           GetChar;
          end;
         end;
         '\':begin
          result:=result+LastChar;
          GetChar;
          result:=result+LastChar;
          GetChar;
         end;
         else begin
          result:=result+LastChar;
          GetChar;
         end;
        end;
       end;
       if LastChar=TerminateChar then begin
        result:=result+LastChar;
        GetChar;
       end else begin
        MakeError('Unterminated string');
       end;
      end;
      else begin
       result:=result+LastChar;
       GetChar;
      end;
     end;
    end;
    if LastChar='}' then begin
     GetChar;
     SkipWhiteSpaceOnSameLine;
    end else begin
     MakeError(Error);
    end;
   end else begin
    MakeError(Error);
   end;
  end;
  procedure ParseStruct;
  begin
   SkipWhiteSpaceOnSameLine;
   if LastChar='{' then begin
    GetChar;
    SkipWhiteSpaceOnSameLine;
    ParserPass(false,true);
    SkipWhiteSpaceOnSameLine;
    if LastChar='}' then begin
     GetChar;
    end else begin
     MakeError(24);
    end;
   end else begin
    MakeError(24);
   end;
   SkipWhiteSpaceOnSameLine;
  end;
  function ParseScriptCodeString:ansistring;
  var Level:longint;
      IsNewLine,IsRegExp,DoAbort:boolean;
      TerminateChar:ansichar;
  begin
   result:='';
   SkipWhiteSpaceOnSameLine;
   if LastChar='{' then begin
    GetChar;
    SkipWhiteSpaceOnSameLine;
    if LastChar<>'}' then begin
     Level:=1;
     while ((Level>0) and (LastChar<>#0)) and not AreErrors do begin
      case LastChar of
       #13:begin
        GetChar;
       end;
       '{':begin
        result:=result+LastChar;
        GetChar;
        inc(Level);
       end;
       '}':begin
        dec(Level);
        if Level=0 then begin
         break;
        end else begin
         result:=result+LastChar;
         GetChar;
        end;
       end;
       '''','"':begin
        // String
        TerminateChar:=LastChar;
        result:=result+LastChar;
        GetChar;
        while not AreErrors do begin
         case LastChar of
          #0,#10:begin
           MakeError('Unterminated string');
           break;
          end;
          '''','"':begin
           if LastChar=TerminateChar then begin
            result:=result+LastChar;
            GetChar;
            break;
           end else begin
            result:=result+LastChar;
            GetChar;
           end;
          end;
          '\':begin
           result:=result+LastChar;
           GetChar;
           result:=result+LastChar;
           GetChar;
          end;
          else begin
           result:=result+LastChar;
           GetChar;
          end;
         end;
        end;
       end;
       '/':begin
        // Regular expression literal
        IsRegExp:=false;
        begin
         StringPosition:=0;
         while GetPreviousChar(StringPosition-1) in [#1..#32] do begin
          dec(StringPosition);
         end;
         if GetPreviousChar(StringPosition-1) in ['(',',','=',':','[','!','&','|','?','+','-','~','*','{',';'] then begin
          IsRegExp:=true;
         end else begin
          if (GetPreviousChar(StringPosition-7) in [#0..#32]) and
             (((GetPreviousChar(StringPosition-6)='r') and (GetPreviousChar(StringPosition-5)='e') and (GetPreviousChar(StringPosition-4)='t') and (GetPreviousChar(StringPosition-3)='u') and (GetPreviousChar(StringPosition-2)='r') and (GetPreviousChar(StringPosition-1)='n')) or
              ((GetPreviousChar(StringPosition-6)='t') and (GetPreviousChar(StringPosition-5)='y') and (GetPreviousChar(StringPosition-4)='p') and (GetPreviousChar(StringPosition-3)='e') and (GetPreviousChar(StringPosition-2)='o') and (GetPreviousChar(StringPosition-1)='f'))) then begin
           IsRegExp:=true;
          end else if (GetPreviousChar(StringPosition-5) in [#0..#32]) and
                      (((GetPreviousChar(StringPosition-4)='c') and (GetPreviousChar(StringPosition-3)='a') and (GetPreviousChar(StringPosition-2)='s') and (GetPreviousChar(StringPosition-1)='e')) or
                       ((GetPreviousChar(StringPosition-4)='e') and (GetPreviousChar(StringPosition-3)='l') and (GetPreviousChar(StringPosition-2)='s') and (GetPreviousChar(StringPosition-1)='e'))) then begin
           IsRegExp:=true;
          end else if (GetPreviousChar(StringPosition-3) in [#0..#32]) and
                      ((GetPreviousChar(StringPosition-2)='i') and (GetPreviousChar(StringPosition-1)='n')) then begin
           IsRegExp:=true;
          end;
         end;
        end;
        result:=result+LastChar;
        GetChar;
        if IsRegExp then begin
         DoAbort:=false;
         while not (AreErrors or DoAbort) do begin
          DoAbort:=false;
          case LastChar of
           #0:begin
            break;
           end;
           #10:begin
            result:=result+LastChar;
            GetChar;
           end;
           '/':begin
            result:=result+LastChar;
            GetChar;
            break;
           end;
           '\':begin
            result:=result+LastChar;
            GetChar;
            result:=result+LastChar;
            GetChar;
           end;
           '[':begin
            result:=result+LastChar;
            GetChar;
            while not AreErrors do begin
             case LastChar of
              #0:begin
               DoAbort:=true;
               break;
              end;
              #10:begin
               result:=result+LastChar;
               GetChar;
               DoAbort:=true;
               break;
              end;
              ']':begin
               result:=result+LastChar;
               GetChar;
               break;
              end;
              '\':begin
               result:=result+LastChar;
               GetChar;
               result:=result+LastChar;
               GetChar;
              end;
              else begin
               result:=result+LastChar;
               GetChar;
              end;
             end;
            end;
           end;
           else begin
            result:=result+LastChar;
            GetChar;
           end;
          end;
         end;
        end;
       end;
       else begin
        result:=result+LastChar;
        GetChar;
       end;
      end;
     end;
    end;
    if LastChar='}' then begin
     GetChar;
     SkipWhiteSpaceOnSameLine;
    end else begin
     MakeError('Script group syntax error');
    end;
   end else begin
    MakeError('Script group syntax error');
   end;
  end;
  function PreparseCodeString(const CodeString:ansistring):ansistring;
  var StringLineIndex,StringLinePosition,StringLineLength,LocalIndex,NestedLevel:longint;
      StringLine,LocalName,LocalStringValue:ansistring;
      Lines,Locals:TStringList;
  begin
   Lines:=TStringList.Create;
   try
    ParseStringIntoStringList(Lines,CodeString);
    result:='';
    Locals:=TStringList.Create;
    try
     for StringLineIndex:=0 to Lines.Count-1 do begin
      StringLine:=Lines[StringLineIndex];
      StringLinePosition:=1;
      StringLineLength:=length(StringLine);
      while (StringLinePosition<=StringLineLength) and (StringLine[StringLinePosition] in [#1..#32]) do begin
       inc(StringLinePosition);
      end;
      if ((StringLinePosition+1)<=StringLineLength) and
         ((StringLine[StringLinePosition] in ['.','!']) and
         (StringLine[StringLinePosition+1] in ['A'..'Z','a'..'z','@','_','$'])) then begin
       inc(StringLinePosition);
       StringLineStringValue:='';
       repeat
        StringLineStringValue:=StringLineStringValue+StringLine[StringLinePosition];
        inc(StringLinePosition);
       until (StringLinePosition>StringLineLength) or not (StringLine[StringLinePosition] in ['A'..'Z','a'..'z','0'..'9','_','@','$']);
       StringLineStringValue:=UpperCase(StringLineStringValue);
       if StringLineStringValue='LOCAL' then begin
        result:=result+#10;
        while (StringLinePosition<=StringLineLength) and (StringLine[StringLinePosition] in [#1..#32]) do begin
         inc(StringLinePosition);
        end;
        while StringLinePosition<=StringLineLength do begin
         if (StringLinePosition<=StringLineLength) and (StringLine[StringLinePosition] in ['A'..'Z','a'..'z','@','_','$']) then begin
          StringLineStringValue:='';
          repeat
           StringLineStringValue:=StringLineStringValue+StringLine[StringLinePosition];
           inc(StringLinePosition);
          until (StringLinePosition>StringLineLength) or not (StringLine[StringLinePosition] in ['A'..'Z','a'..'z','0'..'9','_','@','$']);
          StringLineStringValue:=UpperCase(StringLineStringValue);
          if Locals.IndexOf(StringLineStringValue)<0 then begin
           Locals.Add(StringLineStringValue);
          end else begin
           MakeError(72);
          end;
          while (StringLinePosition<=StringLineLength) and (StringLine[StringLinePosition] in [#1..#32]) do begin
           inc(StringLinePosition);
          end;
          if (StringLinePosition<=StringLineLength) and (StringLine[StringLinePosition]=',') then begin
           inc(StringLinePosition);
           while (StringLinePosition<=StringLineLength) and (StringLine[StringLinePosition] in [#1..#32]) do begin
            inc(StringLinePosition);
           end;
           continue;
          end else begin
           if StringLinePosition<=StringLineLength then begin
            MakeError(16);
           end;
           break;
          end;
         end else begin
          MakeError(16);
          break;
         end;
        end;
        continue;
       end;
      end;
      for LocalIndex:=Locals.Count-1 downto 0 do begin
       LocalName:=Locals[LocalIndex];
       LocalStringValue:=#0+
                         #2+
                         ansichar(byte(LocalIndex and $ff))+
                         ansichar(byte((LocalIndex shr 8) and $ff))+
                         ansichar(byte((LocalIndex shr 16) and $ff))+
                         ansichar(byte((LocalIndex shr 24) and $ff))+
                         #0;
       StringLine:=StringReplace(StringLine,LocalName,LocalStringValue,true,true);
      end;
      StringPosition:=1;
      StringLength:=length(StringLine);
      while (StringPosition<=StringLength) and not AreErrors do begin
       case StringLine[StringPosition] of
        '''','"':begin
         TerminateChar:=StringLine[StringPosition];
         inc(StringPosition);
         while (StringPosition<=StringLength) and not AreErrors do begin
          case StringLine[StringPosition] of
           '''','"':begin
            if StringLine[StringPosition]=TerminateChar then begin
             inc(StringPosition);
             break;
            end else begin
             inc(StringPosition);
            end;
           end;
           '\':begin
            inc(StringPosition);
            if StringPosition<=StringLength then begin
             inc(StringPosition);
            end;
           end;
           else begin
            inc(StringPosition);
           end;
          end;
         end;
        end;
        '\':begin
         Delete(StringLine,StringPosition,1);
         inc(StringPosition);
        end;
        else begin
         inc(StringPosition);
        end;
       end;
      end;
      result:=result+StringLine+#10;
     end;
    finally
     Locals.Free;
    end;
   finally
    Lines.Free;
   end;
  end;
  function EvalCodeString(const CodeString:ansistring):ansistring;
  var StringPosition,StringLength,LocalIndex:longint;
      StringLine,LocalName,LocalStringValue:ansistring;
      ValueIndex,MaxLocal:int64;
  begin
   result:='';
   MaxLocal:=-1;
   StringPosition:=1;
   StringLength:=length(CodeString);
   while StringPosition<=StringLength do begin
    case CodeString[StringPosition] of
     #0:begin
      inc(StringPosition);
      if StringPosition<=StringLength then begin
       case CodeString[StringPosition] of
        #2:begin
         // Local
         inc(StringPosition);
         if ((StringPosition+4)<=StringLength) and (CodeString[StringPosition+4]=#0) then begin
          ValueIndex:=(longword(byte(ansichar(CodeString[StringPosition+0]))) shl 0) or
                      (longword(byte(ansichar(CodeString[StringPosition+1]))) shl 8) or
                      (longword(byte(ansichar(CodeString[StringPosition+2]))) shl 16) or
                      (longword(byte(ansichar(CodeString[StringPosition+3]))) shl 24);
          inc(StringPosition,5);
          result:=result+'@ASMx86$MARCO_LOCAL@'+IntToStr(int64(CurrentLocal+int64(ValueIndex)));
          if MaxLocal<ValueIndex then begin
           MaxLocal:=ValueIndex;
          end;
         end else begin
          MakeError(16);
         end;
        end;
        else begin
         MakeError(16);
        end;
       end;
      end else begin
       MakeError(16);
      end;
     end;
     else begin
      result:=result+CodeString[StringPosition];
      inc(StringPosition);
     end;
    end;
   end;
   inc(CurrentLocal,MaxLocal+1);
  end;
  procedure ParseInstantIF(Skip:boolean);
  var OldLastCode,OldPreLastCode,DownCode{,PreviousCode,NextCode{},Code:PCode;
      DoIF,DoELSE,OK:boolean;
  begin
   OldPreLastCode:=LastCode;
   SkipWhiteSpaceOnSameLine;
   Code:=NewCode;
   Code^.LineNumber:=LastCurrentLineNumber;
   Code^.Column:=LastCurrentColumn;
   Code^.Source:=CurrentSource;
   Code^.CodeItemType:=tcitIF;
   if LastChar='(' then begin
    GetChar;
    SkipWhiteSpaceOnSameLine;
   end else begin
    MakeError('"(" expected');
    exit;
   end;
   Code^.Expression:=ReadExpression;
   SkipWhiteSpaceOnSameLine;
   if LastChar=')' then begin
    GetChar;
    SkipWhiteSpaceOnSameLine;
   end else begin
    MakeError('")" expected');
    exit;
   end;
   if Skip then begin
    DoIF:=false;
    DoELSE:=false;
   end else begin
    if assigned(Code^.Expression) then begin
     DoIF:=ValueGetInt64(self,Code^.Expression.Evaluate(self,false),true)<>0;
     DoELSE:=not DoIF;
    end else begin
     DoIF:=false;
     DoELSE:=true;
    end;
   end;
   OldLastCode:=LastCode;
   Code^.Expression.Free;
   Code^.Expression:=TAssemblerExpression.Create;
   Code^.Expression.Operation:='x';
   Code^.Expression.Value.ValueType:=AVT_INT;
   if DoIF then begin
    IntegerValueSetQWord(Code^.Expression.Value.IntegerValue,1);
    ParseGroup;
   end else begin
    IntegerValueSetQWord(Code^.Expression.Value.IntegerValue,0);
    ParseGroupToSkip;
   end;
   OldLastCode^.Down:=OldLastCode^.Next;
   LastCode:=OldLastCode;
   LastCode^.Next:=nil;
   SymbolValue:=0;
   if not IsLineEnd then begin
    if CheckAlpha then begin
     AllowedKeywordKinds:=[kkDIRECTIVE];
     ReadSymbol;
     if (SymbolType=stKEYWORD) and (SymbolValue=KeyELSE) then begin
      OK:=false;
      if CheckAlpha and (LastChar in ['i','I']) then begin
       AllowedKeywordKinds:=[kkIFELSE];
       ReadSymbol;
       if SymbolValue=KeyIF then begin
        ParseInstantIF(not DoELSE);
        OK:=true;
       end;
      end;
      if not OK then begin
       if DoELSE then begin
        ParseGroup;
       end else begin
        ParseGroupToSkip;
       end;
      end;
      OldLastCode^.ElseDown:=OldLastCode^.Next;
      LastCode:=OldLastCode;
      LastCode^.Next:=nil;
     end else begin
      MakeError('Syntax error');
     end;
    end else begin
     MakeError('Syntax error');
    end;
   end;
  end;
  procedure ParseIF(Skip:boolean);
  var OldLastCode,OldPreLastCode,DownCode{,PreviousCode,NextCode{},Code:PCode;
      DoIF,DoELSE,OK:boolean;
  begin
   OldPreLastCode:=LastCode;
   SkipWhiteSpaceOnSameLine;
   Code:=NewCode;
   Code^.LineNumber:=LastCurrentLineNumber;
   Code^.Column:=LastCurrentColumn;
   Code^.Source:=CurrentSource;
   Code^.CodeItemType:=tcitIF;
   if LastChar='(' then begin
    GetChar;
    SkipWhiteSpaceOnSameLine;
   end else begin
    MakeError('"(" expected');
    exit;
   end;
   Code^.Expression:=ReadExpression;
   SkipWhiteSpaceOnSameLine;
   if LastChar=')' then begin
    GetChar;
    SkipWhiteSpaceOnSameLine;
   end else begin
    MakeError('")" expected');
    exit;
   end;
   if Skip then begin
    DoIF:=false;
    DoELSE:=false;
   end else begin
    DoIF:=true;
    DoELSE:=true;
    if assigned(Code^.Expression) then begin
     if (Code^.Expression.Operation='x') and not (assigned(Code^.Expression.Left) or assigned(Code^.Expression.Right)) then begin
      DoIF:=ValueGetInt64(self,Code^.Expression.Value,false)<>0;
      DoELSE:=not DoIF;
     end;
    end;
   end;
   OldLastCode:=LastCode;
   if DoIF then begin
    ParseGroup;
   end else begin
    ParseGroupToSkip;
   end;
   OldLastCode^.Down:=OldLastCode^.Next;
   LastCode:=OldLastCode;
   LastCode^.Next:=nil;
   SymbolValue:=0;
   if not IsLineEnd then begin
    if CheckAlpha then begin
     AllowedKeywordKinds:=[kkDIRECTIVE];
     ReadSymbol;
     if (SymbolType=stKEYWORD) and (SymbolValue=KeyELSE) then begin
      OK:=false;
      if CheckAlpha and (LastChar in ['i','I']) then begin
       AllowedKeywordKinds:=[kkIFELSE];
       ReadSymbol;
       if SymbolValue=KeyIF then begin
        ParseIF(not DoELSE);
        OK:=true;
       end;
      end;
      if not OK then begin
       if DoELSE then begin
        ParseGroup;
       end else begin
        ParseGroupToSkip;
       end;
      end;
      OldLastCode^.ElseDown:=OldLastCode^.Next;
      LastCode:=OldLastCode;
      LastCode^.Next:=nil;
     end else begin
      MakeError('Syntax error');
     end;
    end else begin
     MakeError('Syntax error');
    end;
   end;
  end;
  procedure ParseInstantREPEAT;
  var OldCurrentFileName:ansistring;
      OldSourcePosition,OldCurrentLineNumber,OldCurrentColumn,OldCurrentSource:longint;
      GroupCurrentLineNumber,GroupCurrentColumn,GroupCurrentSource:longint;
      Expression:TAssemblerExpression;
      GroupCodeString:ansistring;
      Count:TIntegerValue;
      OldRepeatCounter:int64;
  begin
   OldRepeatCounter:=RepeatCounter;
   SkipWhiteSpaceOnSameLine;
   if LastChar='(' then begin
    GetChar;
    SkipWhiteSpaceOnSameLine;
   end else begin
    MakeError('"(" expected');
    exit;
   end;
   Expression:=ReadExpression;
   SkipWhiteSpaceOnSameLine;
   if LastChar=')' then begin
    GetChar;
    SkipWhiteSpaceOnSameLine;
   end else begin
    MakeError('")" expected');
    exit;
   end;
   GroupCurrentLineNumber:=CurrentLineNumber;
   GroupCurrentColumn:=CurrentColumn;
   GroupCurrentSource:=CurrentSource;
   GroupCodeString:=PreparseCodeString(ParseGroupToString);
   if assigned(Expression) then begin
    OldCurrentFileName:=CurrentFileName;
    OldCurrentLineNumber:=CurrentLineNumber;
    OldCurrentColumn:=CurrentColumn;
    OldCurrentSource:=CurrentSource;
    RepeatCounter:=0;
    Count:=ValueToRawInt(self,Expression.Evaluate(self,false),true);
    while (IntCompare(Count,0)>0) and not AreErrors do begin
     CurrentFileName:=OldCurrentFileName;
     CurrentLineNumber:=GroupCurrentLineNumber;
     CurrentColumn:=GroupCurrentColumn;
     CurrentSource:=GroupCurrentSource;
     ParseString(EvalCodeString(GroupCodeString));
     inc(RepeatCounter);
     Count:=IntSub(Count,1);
    end;
    CurrentFileName:=OldCurrentFileName;
    CurrentLineNumber:=OldCurrentLineNumber;
    CurrentColumn:=OldCurrentColumn;
    CurrentSource:=OldCurrentSource;
   end;
   RepeatCounter:=OldRepeatCounter;
  end;
  procedure ParseREPEAT;
  var OldLastCode,Code:PCode;
  begin
   SkipWhiteSpaceOnSameLine;
   if LastChar='(' then begin
    GetChar;
    SkipWhiteSpaceOnSameLine;
   end else begin
    MakeError('"(" expected');
    exit;
   end;
   Code:=NewCode;
   Code^.LineNumber:=LastCurrentLineNumber;
   Code^.Column:=LastCurrentColumn;
   Code^.Source:=CurrentSource;
   Code^.CodeItemType:=tcitREPEAT;
   Code^.Expression:=ReadExpression;
   SkipWhiteSpaceOnSameLine;
   if LastChar=')' then begin
    GetChar;
    SkipWhiteSpaceOnSameLine;
   end else begin
    MakeError('")" expected');
    exit;
   end;
   OldLastCode:=LastCode;
   ParseGroup;
   OldLastCode^.Down:=OldLastCode^.Next;
   LastCode:=OldLastCode;
   LastCode^.Next:=nil;
  end;
  procedure ParseInstantWHILE;
  var OldCurrentFileName:ansistring;
      OldSourcePosition,OldCurrentLineNumber,OldCurrentColumn,OldCurrentSource:longint;
      GroupCurrentLineNumber,GroupCurrentColumn,GroupCurrentSource:longint;
      Expression:TAssemblerExpression;
      GroupCodeString:ansistring;
      OldRepeatCounter:int64;
  begin
   OldRepeatCounter:=RepeatCounter;
   SkipWhiteSpaceOnSameLine;
   if LastChar='(' then begin
    GetChar;
    SkipWhiteSpaceOnSameLine;
   end else begin
    MakeError('"(" expected');
    exit;
   end;
   Expression:=ReadExpression;
   SkipWhiteSpaceOnSameLine;
   if LastChar=')' then begin
    GetChar;
    SkipWhiteSpaceOnSameLine;
   end else begin
    MakeError('")" expected');
    exit;
   end;
   GroupCurrentLineNumber:=CurrentLineNumber;
   GroupCurrentColumn:=CurrentColumn;
   GroupCurrentSource:=CurrentSource;
   GroupCodeString:=PreparseCodeString(ParseGroupToString);
   if assigned(Expression) then begin
    OldCurrentFileName:=CurrentFileName;
    OldCurrentLineNumber:=CurrentLineNumber;
    OldCurrentColumn:=CurrentColumn;
    OldCurrentSource:=CurrentSource;
    RepeatCounter:=0;
    while not (IntegerValueIsZero(ValueToRawInt(self,Expression.Evaluate(self,false),true)) or AreErrors) do begin
     CurrentFileName:=OldCurrentFileName;
     CurrentLineNumber:=GroupCurrentLineNumber;
     CurrentColumn:=GroupCurrentColumn;
     CurrentSource:=GroupCurrentSource;
     ParseString(EvalCodeString(GroupCodeString));
     inc(RepeatCounter);
    end;
    CurrentFileName:=OldCurrentFileName;
    CurrentLineNumber:=OldCurrentLineNumber;
    CurrentColumn:=OldCurrentColumn;
    CurrentSource:=OldCurrentSource;
   end;
   RepeatCounter:=OldRepeatCounter;
  end;
  procedure ParseWHILE;
  var OldLastCode,Code:PCode;
  begin
   SkipWhiteSpaceOnSameLine;
   if LastChar='(' then begin
    GetChar;
    SkipWhiteSpaceOnSameLine;
   end else begin
    MakeError('"(" expected');
    exit;
   end;
   Code:=NewCode;
   Code^.LineNumber:=LastCurrentLineNumber;
   Code^.Column:=LastCurrentColumn;
   Code^.Source:=CurrentSource;
   Code^.CodeItemType:=tcitWHILE;
   Code^.Expression:=ReadExpression;
   SkipWhiteSpaceOnSameLine;
   if LastChar=')' then begin
    GetChar;
    SkipWhiteSpaceOnSameLine;
   end else begin
    MakeError('")" expected');
    exit;
   end;
   OldLastCode:=LastCode;
   ParseGroup;
   OldLastCode^.Down:=OldLastCode^.Next;
   LastCode:=OldLastCode;
   LastCode^.Next:=nil;
  end;
  procedure ParseMacroParameters(MacroParameters:TStringList);
  var CurrentMacroParameter:ansistring;
   procedure ParseMacroParameterString;
   var TerminateChar:ansichar;
   begin
    TerminateChar:=LastChar;
    CurrentMacroParameter:=CurrentMacroParameter+LastChar;
    GetChar;
    while not AreErrors do begin
     case LastChar of
      #0,#10:begin
       MakeError('Unterminated string');
       break;
      end;
      '''','"':begin
       if LastChar=TerminateChar then begin
        CurrentMacroParameter:=CurrentMacroParameter+LastChar;
        GetChar;
        break;
       end else begin
        CurrentMacroParameter:=CurrentMacroParameter+LastChar;
        GetChar;
       end;
      end;
      '\':begin
       CurrentMacroParameter:=CurrentMacroParameter+LastChar;
       GetChar;
       CurrentMacroParameter:=CurrentMacroParameter+LastChar;
       GetChar;
      end;
      else begin
       CurrentMacroParameter:=CurrentMacroParameter+LastChar;
       GetChar;
      end;
     end;
    end;
   end;
   procedure ParseMacroParameterGroup(const TerminateChar:ansichar;TrimIt:boolean);
   begin
    if not TrimIt then begin
     CurrentMacroParameter:=CurrentMacroParameter+LastChar;
    end;
    GetChar;
    while not AreErrors do begin
     case LastChar of
      #0:begin
       break;
      end;
      '{':begin
       ParseMacroParameterGroup('}',false);
      end;
      '[':begin
       ParseMacroParameterGroup(']',false);
      end;
      '(':begin
       ParseMacroParameterGroup(')',false);
      end;
      '}',']',')':begin
       if LastChar=TerminateChar then begin
        if not TrimIt then begin
         CurrentMacroParameter:=CurrentMacroParameter+LastChar;
        end;
        GetChar;
        break;
       end else begin
        MakeError('Misplaced closed bracket or parenthesis');
       end;
      end;
      '''','"':begin
       ParseMacroParameterString;
      end;
      else begin
       CurrentMacroParameter:=CurrentMacroParameter+LastChar;
       GetChar;
      end;
     end;
    end;
   end;
  var HasCurrentMacroParameter,LastWasComma,NewParameter:boolean;
  begin
   MacroParameters.Clear;
   SkipWhiteSpaceOnSameLine;
   CurrentMacroParameter:='';
   HasCurrentMacroParameter:=false;
   LastWasComma:=false;
   NewParameter:=true;
   while not AreErrors do begin
    case LastChar of
     #0:begin
      break;
     end;
     #10,';':begin
      if LastWasComma then begin
       GetChar;
       SkipWhiteSpaceOnSameLine;
      end else begin
       break;
      end;
     end;
     ',':begin
      MacroParameters.Add(CurrentMacroParameter);
      CurrentMacroParameter:='';
      HasCurrentMacroParameter:=true;
      GetChar;
      SkipWhiteSpaceOnSameLine;
      LastWasComma:=true;
      NewParameter:=true;
     end;
     '{':begin
      if NewParameter then begin
       CurrentMacroParameter:='';
       ParseMacroParameterGroup('}',true);
       SkipWhiteSpaceOnSameLine;
      end else begin
       ParseMacroParameterGroup('}',false);
      end;
      HasCurrentMacroParameter:=true;
      LastWasComma:=false;
      NewParameter:=false;
     end;
     '[':begin
      ParseMacroParameterGroup(']',false);
      HasCurrentMacroParameter:=true;
      LastWasComma:=false;
      NewParameter:=false;
     end;
     '(':begin
      ParseMacroParameterGroup(')',false);
      HasCurrentMacroParameter:=true;
      LastWasComma:=false;
      NewParameter:=false;
     end;
     '}',']',')':begin
      MakeError('Misplaced closed bracket or parenthesis');
      break;
     end;
     '''','"':begin
      ParseMacroParameterString;
      HasCurrentMacroParameter:=true;
      LastWasComma:=false;
      NewParameter:=false;
     end;
     #1..#9,#11..#12,#14..#32:begin
      CurrentMacroParameter:=CurrentMacroParameter+LastChar;
      GetChar;
     end;
     else begin
      CurrentMacroParameter:=CurrentMacroParameter+LastChar;
      GetChar;
      HasCurrentMacroParameter:=true;
      LastWasComma:=false;
      NewParameter:=false;
     end;
    end;
   end;
   if HasCurrentMacroParameter then begin
    MacroParameters.Add(CurrentMacroParameter);
   end;
  end;
 var InstructionTemplate:PInstructionTemplate;
     DoAbort:boolean;
 begin
{$ifdef SASMBESEN}
  BESENPArguments:=nil;
  BESENArguments:=nil;
{$endif}
  Symbol:=nil;
  try
   AllowedKeywordKinds:=[];
   if assigned(Status) then begin
    ShowParsingStatus;
   end;
 //WriteLn(Source);
   while not AreErrors do begin
    if assigned(Status) and ((ParsedChars and 4095)=0) then begin
     ShowParsingStatus;
    end;
    CurrentIEEEFormat:=@IEEEFormat32;
    SkipWhiteSpaceOnSameLine;
    case LastChar of
     #0:begin
      // EOF
      break;
     end;
     #10,      // New line
     ';':begin // New statement
      GetChar;
     end;
     '}':begin
      if IsGroup then begin
       break;
      end else begin
       MakeError('"}" outside group');
      end;
     end;
     else begin
      LastCurrentLineNumber:=CurrentLineNumber;
      LastCurrentColumn:=CurrentColumn;
      AllowedKeywordKinds:=[kkOPCODE,kkPREFIX,kkREGISTER,kkPSEUDOOP];
      if CheckAlpha then begin
       ReadSymbol;
       OpcodePrefixWait:=0;
       OpcodePrefixSegment:=0;
       OpcodePrefixLock:=0;
       OpcodePrefixRep:=0;
       OpcodePrefixAddressSize:=0;
       OpcodePrefixOpcodeSize:=0;
       OpcodePrefixVEX:=0;
       OpcodePrefixCount:=0;
       repeat
        if IsPrefix then begin
         case PrefixIndex of
          PrefixA16,PrefixA32,PrefixA64,PrefixASP:begin
           if (OpcodePrefixAddressSize<>0) and (OpcodePrefixAddressSize<>PrefixIndex) then begin
            MakeError(57);
           end else begin
            inc(OpcodePrefixCount);
            OpcodePrefixAddressSize:=PrefixIndex;
           end;
           ReadSymbol;
          end;
          PrefixLOCK:begin
           if (OpcodePrefixLock<>0) and (OpcodePrefixLock<>PrefixIndex) then begin
            MakeError(60);
           end else begin
            inc(OpcodePrefixCount);
            OpcodePrefixLock:=PrefixIndex;
           end;
           ReadSymbol;
          end;
          PrefixO16,PrefixO32,PrefixO64,PrefixOSP:begin
           if (OpcodePrefixOpcodeSize<>0) and (OpcodePrefixOpcodeSize<>PrefixIndex) then begin
            MakeError(58);
           end else begin
            inc(OpcodePrefixCount);
            OpcodePrefixOpcodeSize:=PrefixIndex;
           end;
           ReadSymbol;
          end;
          PrefixREP,PrefixREPE,PrefixREPNE,PrefixREPNZ,PrefixREPZ,PrefixXACQUIRE,PrefixXRELEASE,PrefixBND,PrefixNOBND:begin
           if (OpcodePrefixRep<>0) and (OpcodePrefixRep<>PrefixIndex) then begin
            MakeError(62);
           end else begin
            inc(OpcodePrefixCount);
            OpcodePrefixRep:=PrefixIndex;
           end;
           ReadSymbol;
          end;
          PrefixWAIT:begin
           if (OpcodePrefixWait<>0) and (OpcodePrefixWait<>PrefixIndex) then begin
            MakeError(61);
           end else begin
            inc(OpcodePrefixCount);
            OpcodePrefixWait:=PrefixIndex;
           end;
           ReadSymbol;
          end;
          PrefixEVEX,PrefixVEX2,PrefixVEX3:begin
           if (OpcodePrefixVEX<>0) and (OpcodePrefixVEX<>PrefixIndex) then begin
            MakeError(61);
           end else begin
            inc(OpcodePrefixCount);
            OpcodePrefixVEX:=PrefixIndex;
           end;
           ReadSymbol;
          end;
          else begin
           break;
          end;
         end;
        end else if SymbolType=stREGISTER then begin
         case SymbolValue of
          RegES,RegCS,RegSS,RegDS,RegFS,RegGS,RegSEGR6,RegSEGR7:begin
           if LastChar=':' then begin
            GetChar;
            if (OpcodePrefixSegment<>0) and (OpcodePrefixSegment<>SymbolValue) then begin
             MakeError(36);
             break;
            end else begin
             OpcodePrefixSegment:=SymbolValue;
             inc(OpcodePrefixCount);
            end;
            ReadSymbol;
           end else begin
            MakeError(39);
            break;
           end;
          end;
          else begin
           break;
          end;
         end;
        end else begin
         break;
        end;
       until false;
       if (OpcodePrefixCount>0) and not IsOpcode then begin
        MakeError(59);
       end;
       if IsOpcode then begin
  //    AllowedKeywordKinds:=[kkEXPRESSION];
        SkipWhiteSpaceOnSameLine;
        Code:=NewCode;
        Code^.LineNumber:=LastCurrentLineNumber;
        Code^.Column:=LastCurrentColumn;
        Code^.Source:=CurrentSource;
        Code^.CodeItemType:=tcitInstruction;
        Code^.Instruction.Opcode:=OpcodeIndex;
        Code^.Instruction.CountOperands:=0;
        Code^.Instruction.AddressSize:=0;
        Code^.Instruction.REX:=0;
        Code^.Instruction.REXDone:=false;
        Code^.Instruction.VEXRegister:=0;
        Code^.Instruction.VEX_CM:=0;
        Code^.Instruction.VEX_WLP:=0;
        Code^.Instruction.evex_p[0]:=0;
        Code^.Instruction.evex_p[1]:=0;
        Code^.Instruction.evex_p[2]:=0;
        Code^.Instruction.evex_p[3]:=0;
        Code^.Instruction.evex_rm:=-1;
        Code^.Instruction.evex_brerop:=-1;
        for Counter:=0 to MAXPREFIX-1 do begin
         Code^.Instruction.Prefixes[Counter]:=P_NONE;
        end;
        OpcodeOperandCount:=OpcodeTemplates[OpcodeIndex].MaximalCountOperands;
        for Counter:=1 to MaxOperands do begin
         SkipWhiteSpaceOnSameLine;
         if not (IsLineEnd or AreErrors) then begin
          if Counter<=OpcodeOperandCount then begin
           inc(Code^.Instruction.CountOperands);
           ParseOperand(Code^.Instruction.Operand[Counter],true);
           if (Code^.Instruction.Operand[Counter].DecoratorFlags and (BRDCAST_MASK or ODF_ER or ODF_SAE))<>0 then begin
            Code^.Instruction.evex_brerop:=Counter-1;
           end;
           if CheckDoublePoint then begin
            Code^.Instruction.Operand[Counter].Flags:=Code^.Instruction.Operand[Counter].Flags or OF_COLON;
           end else if not CheckComma then begin
            break;
           end;
          end else begin
           MakeError('Invalid combination of opcode and operands');
           break;
          end;
         end else begin
          break;
         end;
        end;
        begin
         if OpcodePrefixWait<>0 then begin
          case OpcodePrefixWait of
           PrefixWAIT:begin
            Code^.Instruction.Prefixes[PPS_WAIT]:=P_WAIT;
           end;
          end;
         end;
         if OpcodePrefixSegment<>0 then begin
          Code^.Instruction.Prefixes[PPS_SEG]:=OpcodePrefixSegment;
         end;
         if OpcodePrefixLock<>0 then begin
          case OpcodePrefixLock of
           PrefixLOCK:begin
            Code^.Instruction.Prefixes[PPS_LOCK]:=P_LOCK;
           end;
          end;
         end;
         if OpcodePrefixRep<>0 then begin
          case OpcodePrefixRep of
           PrefixREP:begin
            Code^.Instruction.Prefixes[PPS_REP]:=P_REP;
           end;
           PrefixREPE:begin
            Code^.Instruction.Prefixes[PPS_REP]:=P_REPE;
           end;
           PrefixREPNE:begin
            Code^.Instruction.Prefixes[PPS_REP]:=P_REPNE;
           end;
           PrefixREPNZ:begin
            Code^.Instruction.Prefixes[PPS_REP]:=P_REPNZ;
           end;
           PrefixREPZ:begin
            Code^.Instruction.Prefixes[PPS_REP]:=P_REPZ;
           end;
           PrefixXACQUIRE:begin
            Code^.Instruction.Prefixes[PPS_REP]:=P_XACQUIRE;
           end;
           PrefixXRELEASE:begin
            Code^.Instruction.Prefixes[PPS_REP]:=P_XRELEASE;
           end;
           PrefixBND:begin
            Code^.Instruction.Prefixes[PPS_REP]:=P_BND;
           end;
           PrefixNOBND:begin
            Code^.Instruction.Prefixes[PPS_REP]:=P_NOBND;
           end;
          end;
         end;
         if OpcodePrefixAddressSize<>0 then begin
          case OpcodePrefixAddressSize of
           PrefixA16:begin
            Code^.Instruction.Prefixes[PPS_ASIZE]:=P_A16;
           end;
           PrefixA32:begin
            Code^.Instruction.Prefixes[PPS_ASIZE]:=P_A32;
           end;
           PrefixA64:begin
            Code^.Instruction.Prefixes[PPS_ASIZE]:=P_A64;
           end;
           PrefixASP:begin
            Code^.Instruction.Prefixes[PPS_ASIZE]:=P_ASP;
           end;
          end;
         end;
         if OpcodePrefixOpcodeSize<>0 then begin
          case OpcodePrefixAddressSize of
           PrefixO16:begin
            Code^.Instruction.Prefixes[PPS_OSIZE]:=P_O16;
           end;
           PrefixO32:begin
            Code^.Instruction.Prefixes[PPS_OSIZE]:=P_O32;
           end;
           PrefixO64:begin
            Code^.Instruction.Prefixes[PPS_OSIZE]:=P_O64;
           end;
           PrefixOSP:begin
            Code^.Instruction.Prefixes[PPS_OSIZE]:=P_OSP;
           end;
          end;
         end;
         if OpcodePrefixVEX<>0 then begin
          case OpcodePrefixVEX of
           PrefixEVEX:begin
            Code^.Instruction.Prefixes[PPS_VEX]:=P_EVEX;
           end;
           PrefixVEX3:begin
            Code^.Instruction.Prefixes[PPS_VEX]:=P_VEX3;
           end;
           PrefixVEX2:begin
            Code^.Instruction.Prefixes[PPS_VEX]:=P_VEX2;
           end;
          end;
         end;
        end;
   //  end else if SymbolType=stREGISTER then begin
       end else if SymbolType=stKEYWORD then begin
        SkipWhiteSpaceOnSameLine;
        case SymbolValue of
         KeyTIMES:begin
          Expression:=ReadExpression;
          OldLastCode:=LastCode;
          ParserPass(true,false);
          DownCode:=OldLastCode^.Next;
          LastCode:=OldLastCode;
          LastCode^.Next:=nil;
          Code:=NewCode;
          Code^.LineNumber:=LastCurrentLineNumber;
          Code^.Column:=LastCurrentColumn;
          Code^.Source:=CurrentSource;
          Code^.CodeItemType:=tcitTimes;
          Code^.Down:=DownCode;
          Code^.Expression:=Expression;
          if DownCode<>nil then begin
           DownCode^.Previous:=nil;
           DownCode^.Up:=Code;
          end;
         end;
         KeyDB,KeyDW,KeyDD,KeyDQ,KeyDT,KeyDDQ,KeyDO,KeyDY,KeyDZ:begin
          LastCurrentLineNumber:=CurrentLineNumber;
          LastCurrentColumn:=CurrentColumn;
          DataSymbolValue:=SymbolValue;
          case DataSymbolValue of
           KeyDB:begin
            CurrentIEEEFormat:=@IEEEFormat8;
            DataBytes:=1;
           end;
           KeyDW:begin
            CurrentIEEEFormat:=@IEEEFormat16;
            DataBytes:=2;
           end;
           KeyDD:begin
            CurrentIEEEFormat:=@IEEEFormat32;
            DataBytes:=4;
           end;
           KeyDQ:begin
            CurrentIEEEFormat:=@IEEEFormat64;
            DataBytes:=8;
           end;
           KeyDT:begin
            CurrentIEEEFormat:=@IEEEFormat80;
            DataBytes:=10;
           end;
           KeyDDQ,KeyDO:begin
            CurrentIEEEFormat:=@IEEEFormat128;
            DataBytes:=16;
           end;
           KeyDY:begin
            CurrentIEEEFormat:=@IEEEFormat256;
            DataBytes:=32;
           end;
           KeyDZ:begin
            CurrentIEEEFormat:=@IEEEFormat512;
            DataBytes:=64;
           end;
           else begin
            DataBytes:=0;
            MakeError('Internal error');
           end;
          end;
          while not AreErrors do begin
           SkipWhiteSpaceOnSameLine;
           LastCurrentLineNumber:=CurrentLineNumber;
           LastCurrentColumn:=CurrentColumn;
           Code:=NewCode;
           Code^.CodeItemType:=tcitData;
           Code^.LineNumber:=LastCurrentLineNumber;
           Code^.Column:=LastCurrentColumn;
           Code^.Source:=CurrentSource;
           Code^.Value:=DataBytes;
           Code^.Expression:=ReadExpression;
           Code^.SecondExpression:=nil;
           if LastChar='[' then begin
            GetChar;
            Code^.SecondExpression:=ReadExpression;
            if AreErrors then begin
             break;
            end;
            if LastChar=']' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
            end else begin
             MakeError(48);
            end;
           end else if CheckAlpha then begin
            AllowedKeywordKinds:=[kkDATAPSEUDOOP];
            ReadSymbol;
            SkipWhiteSpaceOnSameLine;
            if (SymbolType=stKEYWORD) and (SymbolValue=KeyDUP) then begin
             if LastChar='(' then begin
              GetChar;
              SkipWhiteSpaceOnSameLine;
              if LastChar='?' then begin
               GetChar;
               SkipWhiteSpaceOnSameLine;
               Code^.CodeItemType:=tcitDataEmpty;
              end else begin
               SkipWhiteSpaceOnSameLine;
               OtherCode:=Code;
               OldLastCode:=LastCode;
               Code:=NewCode;
               Code^.CodeItemType:=tcitData;
               Code^.LineNumber:=LastCurrentLineNumber;
               Code^.Column:=LastCurrentColumn;
               Code^.Source:=CurrentSource;
               Code^.Value:=DataBytes;
               Code^.Expression:=ReadExpression;
               Code^.SecondExpression:=nil;
               if LastChar='[' then begin
                GetChar;
                Code^.SecondExpression:=ReadExpression;
                if AreErrors then begin
                 break;
                end;
                if LastChar=']' then begin
                 GetChar;
                 SkipWhiteSpaceOnSameLine;
                end else begin
                 MakeError(48);
                end;
               end;
               DownCode:=OldLastCode^.Next;
               LastCode:=OldLastCode;
               LastCode^.Next:=nil;
               OtherCode^.CodeItemType:=tcitTimes;
               OtherCode^.Down:=DownCode;
               if DownCode<>nil then begin
                DownCode^.Previous:=nil;
                DownCode^.Up:=OtherCode;
               end;
              end;
              if LastChar=')' then begin
               GetChar;
               SkipWhiteSpaceOnSameLine;
              end else begin
               MakeError(48);
              end;
             end else begin
              MakeError(48);
             end;
            end else begin
             MakeError(48);
            end;
           end;
           if not CheckComma then begin
            break;
           end;
          end;
         end;
         KeyDSTR:begin
          while not AreErrors do begin
           LastCurrentLineNumber:=CurrentLineNumber;
           LastCurrentColumn:=CurrentColumn;
           ReadString;
           Code:=NewCode;
           Code^.LineNumber:=LastCurrentLineNumber;
           Code^.Column:=LastCurrentColumn;
           Code^.Source:=CurrentSource;
           Code^.CodeItemType:=tcitDataRawString;
           Code^.StringData:=StringData;
           if not CheckComma then begin
            break;
           end;
          end;
         end;
         KeyDWSTR:begin
          while not AreErrors do begin
           LastCurrentLineNumber:=CurrentLineNumber;
           LastCurrentColumn:=CurrentColumn;
           ReadWideString;
           Code:=NewCode;
           Code^.LineNumber:=LastCurrentLineNumber;
           Code^.Column:=LastCurrentColumn;
           Code^.Source:=CurrentSource;
           Code^.CodeItemType:=tcitDataRawString;
           SetLength(Code^.StringData,length(WideStringData)*SizeOf(widechar));
           if length(WideStringData)>0 then begin
            Move(WideStringData[1],Code^.StringData[1],length(WideStringData)*SizeOf(widechar));
           end;
           if not CheckComma then begin
            break;
           end;
          end;
         end;
         KeyRESB,KeyRESW,KeyRESD,KeyRESQ,KeyREST,KeyRESDQ,KeyRESO,KeyRESY,KeyRESZ:begin
          DataSymbolValue:=SymbolValue;
          Code:=NewCode;
          Code^.CodeItemType:=tcitDataEmpty;
          Code^.LineNumber:=LastCurrentLineNumber;
          Code^.Column:=LastCurrentColumn;
          Code^.Source:=CurrentSource;
          case DataSymbolValue of
           KeyRESB:begin
            Code^.Value:=1;
           end;
           KeyRESW:begin
            Code^.Value:=2;
           end;
           KeyRESD:begin
            Code^.Value:=4;
           end;
           KeyRESQ:begin
            Code^.Value:=8;
           end;
           KeyREST:begin
            Code^.Value:=12;
           end;
           KeyRESDQ,KeyRESO:begin
            Code^.Value:=16;
           end;
           KeyRESY:begin
            Code^.Value:=32;
           end;
           KeyRESZ:begin
            Code^.Value:=64;
           end;
           else begin
            MakeError('Internal error');
           end;
          end;
          Code^.Expression:=ReadExpression;
         end;
        end;
       end else if SymbolType=stUSER then begin
        CodeSymbolIndex:=SymbolValue;
        MacroSymbol:=UserSymbolList[SymbolValue];
        if MacroSymbol.SymbolType in [ustMACRO,ustSCRIPTMACRO] then begin
         Parameters:=TStringList.Create;
         try
          ParseMacroParameters(Parameters);
{$ifdef SASMBESEN}
          if MacroSymbol.SymbolType=ustSCRIPTMACRO then begin
           OldCurrentLineNumber:=CurrentLineNumber;
           OldCurrentColumn:=CurrentColumn;
           OldCurrentSource:=CurrentSource;
           try
            CurrentLineNumber:=1;
            CurrentColumn:=0;
            CurrentSource:=-SymbolValue-1;
            try
             CountArguments:=Parameters.Count;
             SetLength(BESENPArguments,CountArguments);
             SetLength(BESENArguments,CountArguments);
             for ArgumentIndex:=0 to CountArguments-1 do begin
              BESENPArguments[ArgumentIndex]:=@BESENArguments[ArgumentIndex];
              BESENArguments[ArgumentIndex]:=BESENStringValue(BESENUTF8ToUTF16(Parameters[ArgumentIndex]));
             end;
             BESENResultValue:=BESENUndefinedValue;
             MacroSymbol.BESENObject.Call(BESENUndefinedValue,@BESENPArguments[0],CountArguments,BESENResultValue);
            except
             on e:Exception do begin
              MakeError(e.Message);
             end;
            end;
           finally
            CurrentLineNumber:=OldCurrentLineNumber;
            CurrentColumn:=OldCurrentColumn;
            CurrentSource:=OldCurrentSource;
           end;
          end else{$endif}begin
           MacroStringValue:=MacroSymbol.Content;
           if Parameters.Count<MacroSymbol.CountParameters then begin
            MakeError(18);
           end;
           MacroContent:='';
           StringPosition:=1;
           StringLength:=length(MacroStringValue);
           while StringPosition<=StringLength do begin
            case MacroStringValue[StringPosition] of
             #0:begin
              inc(StringPosition);
              if StringPosition<=StringLength then begin
               case MacroStringValue[StringPosition] of
                #1:begin
                 // Parameter
                 inc(StringPosition);
                 if ((StringPosition+4)<=StringLength) and (MacroStringValue[StringPosition+4]=#0) then begin
                  MacroValueIndex:=(longword(byte(ansichar(MacroStringValue[StringPosition+0]))) shl 0) or
                                   (longword(byte(ansichar(MacroStringValue[StringPosition+1]))) shl 8) or
                                   (longword(byte(ansichar(MacroStringValue[StringPosition+2]))) shl 16) or
                                   (longword(byte(ansichar(MacroStringValue[StringPosition+3]))) shl 24);
                  inc(StringPosition,5);
                  if (MacroValueIndex>=0) and (MacroValueIndex<Parameters.Count) then begin
                   MacroContent:=MacroContent+Parameters[MacroValueIndex];
                  end;
                 end else begin
                  MakeError(16);
                 end;
                end;
                #2:begin
                 // Local
                 inc(StringPosition);
                 if ((StringPosition+4)<=StringLength) and (MacroStringValue[StringPosition+4]=#0) then begin
                  MacroValueIndex:=(longword(byte(ansichar(MacroStringValue[StringPosition+0]))) shl 0) or
                                   (longword(byte(ansichar(MacroStringValue[StringPosition+1]))) shl 8) or
                                   (longword(byte(ansichar(MacroStringValue[StringPosition+2]))) shl 16) or
                                   (longword(byte(ansichar(MacroStringValue[StringPosition+3]))) shl 24);
                  inc(StringPosition,5);
                  MacroContent:=MacroContent+'@ASMx86$MARCO_LOCAL@'+IntToStr(int64(CurrentLocal+int64(MacroValueIndex)));
                 end else begin
                  MakeError(16);
                 end;
                end;
                #3:begin
                 // Parameter check
                 inc(StringPosition);
                 if ((StringPosition+4)<=StringLength) and (MacroStringValue[StringPosition+4]=#0) then begin
                  MacroValueIndex:=(longword(byte(ansichar(MacroStringValue[StringPosition+0]))) shl 0) or
                                   (longword(byte(ansichar(MacroStringValue[StringPosition+1]))) shl 8) or
                                   (longword(byte(ansichar(MacroStringValue[StringPosition+2]))) shl 16) or
                                   (longword(byte(ansichar(MacroStringValue[StringPosition+3]))) shl 24);
                  inc(StringPosition,5);
                  if ((MacroValueIndex>=0) and (MacroValueIndex<Parameters.Count)) and (length(trim(Parameters[MacroValueIndex]))>0) then begin
                   MacroContent:=MacroContent+'1';
                  end else begin
                   MacroContent:=MacroContent+'0';
                  end;
                 end else begin
                  MakeError(16);
                 end;
                end;
                #4:begin
                 // Stringify parameter
                 inc(StringPosition);
                 if ((StringPosition+4)<=StringLength) and (MacroStringValue[StringPosition+4]=#0) then begin
                  MacroValueIndex:=(longword(byte(ansichar(MacroStringValue[StringPosition+0]))) shl 0) or
                                   (longword(byte(ansichar(MacroStringValue[StringPosition+1]))) shl 8) or
                                   (longword(byte(ansichar(MacroStringValue[StringPosition+2]))) shl 16) or
                                   (longword(byte(ansichar(MacroStringValue[StringPosition+3]))) shl 24);
                  inc(StringPosition,5);
                  if (MacroValueIndex>=0) and (MacroValueIndex<Parameters.Count) then begin
                   MacroContent:=MacroContent+'"'+Stringify(Parameters[MacroValueIndex])+'"';
                  end;
                 end else begin
                  MakeError(16);
                 end;
                end;
                #5:begin
                 // __VA_ARGS__ parameter
                 inc(StringPosition);
                 if ((StringPosition+4)<=StringLength) and (MacroStringValue[StringPosition+4]=#0) then begin
                  MacroValueIndex:=(longword(byte(ansichar(MacroStringValue[StringPosition+0]))) shl 0) or
                                   (longword(byte(ansichar(MacroStringValue[StringPosition+1]))) shl 8) or
                                   (longword(byte(ansichar(MacroStringValue[StringPosition+2]))) shl 16) or
                                   (longword(byte(ansichar(MacroStringValue[StringPosition+3]))) shl 24);
                  inc(StringPosition,5);
                  for Index:=MacroValueIndex to Parameters.Count-1 do begin
                   if Index>MacroValueIndex then begin
                    MacroContent:=MacroContent+', ';
                   end else begin
                    MacroContent:=MacroContent+Parameters[MacroValueIndex];
                   end;
                  end;
                 end else begin
                  MakeError(16);
                 end;
                end;
                #6:begin
                 // Stringify __VA_ARGS__ parameter
                 inc(StringPosition);
                 if ((StringPosition+4)<=StringLength) and (MacroStringValue[StringPosition+4]=#0) then begin
                  MacroValueIndex:=(longword(byte(ansichar(MacroStringValue[StringPosition+0]))) shl 0) or
                                   (longword(byte(ansichar(MacroStringValue[StringPosition+1]))) shl 8) or
                                   (longword(byte(ansichar(MacroStringValue[StringPosition+2]))) shl 16) or
                                   (longword(byte(ansichar(MacroStringValue[StringPosition+3]))) shl 24);
                  inc(StringPosition,5);
                  TempString:='';
                  for Index:=MacroValueIndex to Parameters.Count-1 do begin
                   if Index>MacroValueIndex then begin
                    TempString:=TempString+', ';
                   end;
                   TempString:=TempString+Parameters[Index];
                  end;
                  MacroContent:=MacroContent+'"'+Stringify(TempString)+'"';
                 end else begin
                  MakeError(16);
                 end;
                end;
                #7:begin
                 // __VA_ARGS__ char
                 inc(StringPosition);
                 if ((StringPosition+5)<=StringLength) and (MacroStringValue[StringPosition+5]=#0) then begin
                  MacroValueIndex:=(longword(byte(ansichar(MacroStringValue[StringPosition+0]))) shl 0) or
                                   (longword(byte(ansichar(MacroStringValue[StringPosition+1]))) shl 8) or
                                   (longword(byte(ansichar(MacroStringValue[StringPosition+2]))) shl 16) or
                                   (longword(byte(ansichar(MacroStringValue[StringPosition+3]))) shl 24);
                  inc(StringPosition,6);
                  if MacroValueIndex<Parameters.Count then begin
                   MacroContent:=MacroContent+MacroStringValue[StringPosition+4];
                  end;
                 end else begin
                  MakeError(16);
                 end;
                end;
                else begin
                 MakeError(16);
                end;
               end;
              end else begin
               MakeError(16);
              end;
             end;
             else begin
              MacroContent:=MacroContent+MacroStringValue[StringPosition];
              inc(StringPosition);
             end;
            end;
           end;
           inc(CurrentLocal,MacroSymbol.CountLocals);
           if not AreErrors then begin
            OldCurrentLineNumber:=CurrentLineNumber;
            OldCurrentColumn:=CurrentColumn;
            OldCurrentSource:=CurrentSource;
            CurrentLineNumber:=1;
            CurrentColumn:=0;
            CurrentSource:=-SymbolValue-1;
            ParseString(MacroContent);
            CurrentLineNumber:=OldCurrentLineNumber;
            CurrentColumn:=OldCurrentColumn;
            CurrentSource:=OldCurrentSource;
           end;
          end;
         finally
          Parameters.Free;
         end;
        end else if LastChar=':' then begin
         GetChar;
         Symbol:=UserSymbolList[SymbolValue];
         if assigned(Symbol) then begin
          if Symbol.SymbolType=ustNONE then begin
           if not IsSymbolPrefixed then begin
            OriginalNamePrefix:=Symbol.OriginalName;
           end;
           Symbol.SymbolType:=ustLABEL;
           Code:=NewCode;
           Code^.LineNumber:=LastCurrentLineNumber;
           Code^.Column:=LastCurrentColumn;
           Code^.Source:=CurrentSource;
           Code^.CodeItemType:=tcitLabel;
           Code^.SymbolIndex:=SymbolValue;
           SkipWhiteSpaceOnSameLine;
           continue;
          end else begin
           MakeError(17);
          end;
         end else begin
         end;
        end else begin
         SkipWhiteSpaceOnSameLine;
         if LastChar='=' then begin
          GetChar;
          SkipWhiteSpaceOnSameLine;
          if SymbolType=stUSER then begin
           Symbol:=UserSymbolList.Items[SymbolValue];
           if Symbol.SymbolType in [ustNONE,ustVARIABLE] then begin
            Symbol.SymbolType:=ustVARIABLE;
            Code:=NewCode;
            Code^.LineNumber:=LastCurrentLineNumber;
            Code^.Column:=LastCurrentColumn;
            Code^.Source:=CurrentSource;
            Code^.CodeItemType:=tcitConstant;
            Code^.SymbolIndex:=SymbolValue;
            Code^.Expression:=ReadExpression;
            ProcessConstant(Code);
           end else begin
            MakeError(74);
           end;
          end else begin
           MakeError(74);
          end;
         end else if CheckAlpha then begin
          CodeSymbolIndex:=SymbolValue;
          OldCurrentLineNumber:=CurrentLineNumber;
          OldCurrentColumn:=CurrentColumn;
          OldCurrentSource:=CurrentSource;
          AllowedKeywordKinds:=[kkSTRUCT,kkEQU];
          ReadSymbol;
          SkipWhiteSpaceOnSameLine;
          if (SymbolType=stKEYWORD) and (SymbolValue=KeyEQU) then begin
           if (LastStruct<0) and (length(StructName)=0) then begin
            Symbol:=UserSymbolList.Items[CodeSymbolIndex];
            Symbol.SymbolType:=ustREPLACER;
            Code:=NewCode;
            Code^.LineNumber:=LastCurrentLineNumber;
            Code^.Column:=LastCurrentColumn;
            Code^.Source:=CurrentSource;
            Code^.CodeItemType:=tcitConstant;
            Code^.SymbolIndex:=CodeSymbolIndex;
            Code^.Expression:=ReadExpression;
            UserSymbolList.Items[CodeSymbolIndex].Expression:=TAssemblerExpression.Create;
            UserSymbolList.Items[CodeSymbolIndex].Expression.Assign(Code^.Expression);
           end else begin
            MakeError(12);
            GetChar;
           end;
          end else if CheckStruct then begin
           StructSymbolIndex:=SymbolValue;
           if (LastStruct>=0) and (length(StructName)<>0) then begin
            Code:=NewCode;
            Code^.LineNumber:=LastCurrentLineNumber;
            Code^.Column:=LastCurrentColumn;
            Code^.Source:=CurrentSource;
            Code^.CodeItemType:=tcitSTRUCTVAR;
            Code^.SymbolIndex:=CodeSymbolIndex;
            Code^.StructSymbolIndex:=LastStruct;
            Code^.ItemStructSymbolIndex:=StructSymbolIndex;
            Code^.Expression:=nil;
            Code^.Value:=0;
            Code^.ItemSize:=0;
            if LastChar='(' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
             if LastChar<>')' then begin
              Expression:=ReadExpression;
              Expression.Optimize(self);
              Code^.Expression:=Expression;
              SkipWhiteSpaceOnSameLine;
             end else begin
              Code^.Value:=1;
             end;
             if LastChar=')' then begin
              GetChar;
              SkipWhiteSpaceOnSameLine;
             end else begin
              MakeError(26);
             end;
            end else begin
             Code^.Value:=1;
            end;
            Symbol:=UserSymbolList.Items[CodeSymbolIndex];
            Symbol.SymbolType:=ustCONSTANTSTRUCT;
            Symbol.Value.ValueType:=AVT_INT;
            IntegerValueSetQWord(Symbol.Value.IntegerValue,StructSize);
            inc(StructSize,Code^.Value);
            Symbol.Expression:=nil;
           end else begin
            MakeError(25);
           end;
          end else if CheckKeyWord(KeyBYTE) then begin
           if (LastStruct>=0) and (length(StructName)<>0) then begin
            Code:=NewCode;
            Code^.LineNumber:=LastCurrentLineNumber;
            Code^.Column:=LastCurrentColumn;
            Code^.Source:=CurrentSource;
            Code^.CodeItemType:=tcitSTRUCTVAR;
            Code^.SymbolIndex:=CodeSymbolIndex;
            Code^.StructSymbolIndex:=LastStruct;
            Code^.Expression:=nil;
            Code^.Value:=0;
            Code^.ItemSize:=1;
            if LastChar='(' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
             if LastChar<>')' then begin
              Expression:=ReadExpression;
              Expression.Optimize(self);
              Code^.Expression:=Expression;
              SkipWhiteSpaceOnSameLine;
             end else begin
              Code^.Value:=1;
             end;
             if LastChar=')' then begin
              GetChar;
              SkipWhiteSpaceOnSameLine;
             end else begin
              MakeError(26);
             end;
            end else begin
             Code^.Value:=1;
            end;
            Symbol:=UserSymbolList.Items[CodeSymbolIndex];
            Symbol.SymbolType:=ustCONSTANTSTRUCT;
            Symbol.Value.ValueType:=AVT_INT;
            IntegerValueSetQWord(Symbol.Value.IntegerValue,StructSize);
            inc(StructSize,Code^.Value);
            Symbol.Expression:=nil;
           end else begin
            MakeError(25);
           end;
          end else if CheckKeyWord(KeyWORD) then begin
           if (LastStruct>=0) and (length(StructName)<>0) then begin
            Code:=NewCode;
            Code^.LineNumber:=LastCurrentLineNumber;
            Code^.Column:=LastCurrentColumn;
            Code^.Source:=CurrentSource;
            Code^.CodeItemType:=tcitSTRUCTVAR;
            Code^.SymbolIndex:=CodeSymbolIndex;
            Code^.StructSymbolIndex:=LastStruct;
            Code^.Expression:=nil;
            Code^.Value:=0;
            Code^.ItemSize:=2;
            if LastChar='(' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
             if LastChar<>')' then begin
              Expression:=ReadExpression;
              Expression.Optimize(self);
              Code^.Expression:=Expression;
              SkipWhiteSpaceOnSameLine;
             end else begin
              Code^.Value:=1;
             end;
             if LastChar=')' then begin
              GetChar;
              SkipWhiteSpaceOnSameLine;
             end else begin
              MakeError(26);
             end;
            end else begin
             Code^.Value:=1;
            end;
            Symbol:=UserSymbolList.Items[CodeSymbolIndex];
            Symbol.SymbolType:=ustCONSTANTSTRUCT;
            Symbol.Value.ValueType:=AVT_INT;
            IntegerValueSetQWord(Symbol.Value.IntegerValue,StructSize);
            inc(StructSize,Code^.Value);
            Symbol.Expression:=nil;
           end else begin
            MakeError(25);
           end;
          end else if CheckKeyWord(KeyDWORD) or CheckKeyWord(KeyFLOAT) then begin
           if (LastStruct>=0) and (length(StructName)<>0) then begin
            Code:=NewCode;
            Code^.LineNumber:=LastCurrentLineNumber;
            Code^.Column:=LastCurrentColumn;
            Code^.Source:=CurrentSource;
            Code^.CodeItemType:=tcitSTRUCTVAR;
            Code^.SymbolIndex:=CodeSymbolIndex;
            Code^.StructSymbolIndex:=LastStruct;
            Code^.Expression:=nil;
            Code^.Value:=0;
            Code^.ItemSize:=4;
            if LastChar='(' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
             if LastChar<>')' then begin
              Expression:=ReadExpression;
              Expression.Optimize(self);
              Code^.Expression:=Expression;
              SkipWhiteSpaceOnSameLine;
             end else begin
              Code^.Value:=1;
             end;
             if LastChar=')' then begin
              GetChar;
              SkipWhiteSpaceOnSameLine;
             end else begin
              MakeError(26);
             end;
            end else begin
             Code^.Value:=1;
            end;
            Symbol:=UserSymbolList.Items[CodeSymbolIndex];
            Symbol.SymbolType:=ustCONSTANTSTRUCT;
            Symbol.Value.ValueType:=AVT_INT;
            IntegerValueSetQWord(Symbol.Value.IntegerValue,StructSize);
            inc(StructSize,Code^.Value);
            Symbol.Expression:=nil;
           end else begin
            MakeError(25);
           end;                          
          end else if CheckKeyWord(KeyQWORD) or CheckKeyWord(KeyDOUBLE) then begin
           if (LastStruct>=0) and (length(StructName)<>0) then begin
            Code:=NewCode;
            Code^.LineNumber:=LastCurrentLineNumber;
            Code^.Column:=LastCurrentColumn;
            Code^.Source:=CurrentSource;
            Code^.CodeItemType:=tcitSTRUCTVAR;
            Code^.SymbolIndex:=CodeSymbolIndex;
            Code^.StructSymbolIndex:=LastStruct;
            Code^.Expression:=nil;
            Code^.Value:=0;
            Code^.ItemSize:=8;
            if LastChar='(' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
             if LastChar<>')' then begin
              Expression:=ReadExpression;
              Expression.Optimize(self);
              Code^.Expression:=Expression;
              SkipWhiteSpaceOnSameLine;
             end else begin
              Code^.Value:=1;
             end;
             if LastChar=')' then begin
              GetChar;
              SkipWhiteSpaceOnSameLine;
             end else begin
              MakeError(26);
             end;
            end else begin
             Code^.Value:=1;
            end;
            Symbol:=UserSymbolList.Items[CodeSymbolIndex];
            Symbol.SymbolType:=ustCONSTANTSTRUCT;
            Symbol.Value.ValueType:=AVT_INT;
            IntegerValueSetQWord(Symbol.Value.IntegerValue,StructSize);
            inc(StructSize,Code^.Value);
            Symbol.Expression:=nil;
           end else begin
            MakeError(25);
           end;
          end else if CheckKeyWord(KeyTWORD) or CheckKeyWord(KeyEXTENDED) then begin
           if (LastStruct>=0) and (length(StructName)<>0) then begin
            Code:=NewCode;
            Code^.LineNumber:=LastCurrentLineNumber;
            Code^.Column:=LastCurrentColumn;
            Code^.Source:=CurrentSource;
            Code^.CodeItemType:=tcitSTRUCTVAR;
            Code^.SymbolIndex:=CodeSymbolIndex;
            Code^.StructSymbolIndex:=LastStruct;
            Code^.Expression:=nil;
            Code^.Value:=0;
            Code^.ItemSize:=10;
            if LastChar='(' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
             if LastChar<>')' then begin
              Expression:=ReadExpression;
              Expression.Optimize(self);
              Code^.Expression:=Expression;
              SkipWhiteSpaceOnSameLine;
             end else begin
              Code^.Value:=1;
             end;
             if LastChar=')' then begin
              GetChar;
              SkipWhiteSpaceOnSameLine;
             end else begin
              MakeError(26);
             end;
            end else begin
             Code^.Value:=1;
            end;
            Symbol:=UserSymbolList.Items[CodeSymbolIndex];
            Symbol.SymbolType:=ustCONSTANTSTRUCT;
            Symbol.Value.ValueType:=AVT_INT;
            IntegerValueSetQWord(Symbol.Value.IntegerValue,StructSize);
            inc(StructSize,Code^.Value);
            Symbol.Expression:=nil;
           end else begin
            MakeError(25);
           end;
          end else if CheckKeyWord(KeyOWORD) or CheckKeyWord(KeyDQWORD) or CheckKeyWord(KeyXMMWORD) then begin
           if (LastStruct>=0) and (length(StructName)<>0) then begin
            Code:=NewCode;
            Code^.LineNumber:=LastCurrentLineNumber;
            Code^.Column:=LastCurrentColumn;
            Code^.Source:=CurrentSource;
            Code^.CodeItemType:=tcitSTRUCTVAR;
            Code^.SymbolIndex:=CodeSymbolIndex;
            Code^.StructSymbolIndex:=LastStruct;
            Code^.Expression:=nil;
            Code^.Value:=0;
            Code^.ItemSize:=16;
            if LastChar='(' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
             if LastChar<>')' then begin
              Expression:=ReadExpression;
              Expression.Optimize(self);
              Code^.Expression:=Expression;
              SkipWhiteSpaceOnSameLine;
             end else begin
              Code^.Value:=1;
             end;
             if LastChar=')' then begin
              GetChar;
              SkipWhiteSpaceOnSameLine;
             end else begin
              MakeError(26);
             end;
            end else begin
             Code^.Value:=1;
            end;
            Symbol:=UserSymbolList.Items[CodeSymbolIndex];
            Symbol.SymbolType:=ustCONSTANTSTRUCT;
            Symbol.Value.ValueType:=AVT_INT;
            IntegerValueSetQWord(Symbol.Value.IntegerValue,StructSize);
            inc(StructSize,Code^.Value);
            Symbol.Expression:=nil;
           end else begin
            MakeError(25);
           end;
          end else if CheckKeyWord(KeyYWORD) or CheckKeyword(KeyYMMWORD) then begin
           if (LastStruct>=0) and (length(StructName)<>0) then begin
            Code:=NewCode;
            Code^.LineNumber:=LastCurrentLineNumber;
            Code^.Column:=LastCurrentColumn;
            Code^.Source:=CurrentSource;
            Code^.CodeItemType:=tcitSTRUCTVAR;
            Code^.SymbolIndex:=CodeSymbolIndex;
            Code^.StructSymbolIndex:=LastStruct;
            Code^.Expression:=nil;
            Code^.Value:=0;
            Code^.ItemSize:=32;
            if LastChar='(' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
             if LastChar<>')' then begin
              Expression:=ReadExpression;
              Expression.Optimize(self);
              Code^.Expression:=Expression;
              SkipWhiteSpaceOnSameLine;
             end else begin
              Code^.Value:=1;
             end;
             if LastChar=')' then begin
              GetChar;
              SkipWhiteSpaceOnSameLine;
             end else begin
              MakeError(26);
             end;
            end else begin
             Code^.Value:=1;
            end;
            Symbol:=UserSymbolList.Items[CodeSymbolIndex];
            Symbol.SymbolType:=ustCONSTANTSTRUCT;
            Symbol.Value.ValueType:=AVT_INT;
            IntegerValueSetQWord(Symbol.Value.IntegerValue,StructSize);
            inc(StructSize,Code^.Value);
            Symbol.Expression:=nil;
           end else begin
            MakeError(25);
           end;
          end else if CheckKeyWord(KeyZWORD) or CheckKeyword(KeyZMMWORD) then begin
           if (LastStruct>=0) and (length(StructName)<>0) then begin
            Code:=NewCode;
            Code^.LineNumber:=LastCurrentLineNumber;
            Code^.Column:=LastCurrentColumn;
            Code^.Source:=CurrentSource;
            Code^.CodeItemType:=tcitSTRUCTVAR;
            Code^.SymbolIndex:=CodeSymbolIndex;
            Code^.StructSymbolIndex:=LastStruct;
            Code^.Expression:=nil;
            Code^.Value:=0;
            Code^.ItemSize:=64;
            if LastChar='(' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
             if LastChar<>')' then begin
              Expression:=ReadExpression;
              Expression.Optimize(self);
              Code^.Expression:=Expression;
              SkipWhiteSpaceOnSameLine;
             end else begin
              Code^.Value:=1;
             end;
             if LastChar=')' then begin
              GetChar;
              SkipWhiteSpaceOnSameLine;
             end else begin
              MakeError(26);
             end;
            end else begin
             Code^.Value:=1;
            end;
            Symbol:=UserSymbolList.Items[CodeSymbolIndex];
            Symbol.SymbolType:=ustCONSTANTSTRUCT;
            Symbol.Value.ValueType:=AVT_INT;
            IntegerValueSetQWord(Symbol.Value.IntegerValue,StructSize);
            inc(StructSize,Code^.Value);
            Symbol.Expression:=nil;
           end else begin
            MakeError(25);
           end;
          end else begin
           MakeError('Syntax error');
          end;
         end else begin
          MakeError('Internal error (2015-08-17-21-04-0000)');
         end;
        end;
       end else begin
        MakeError('Internal error (2015-08-17-21-00-0000)');
       end;
      end else if CheckExclamationMark then begin
       if CheckAlpha then begin
        AllowedKeywordKinds:=[kkDIRECTIVE];
        ReadSymbol;
        if SymbolType=stKEYWORD then begin
         case SymbolValue of
{$ifdef SASMBESEN}
          KeySCRIPT:begin
           ScriptContent:=ParseScriptCodeString;
           if length(ScriptContent)>0 then begin
            try
             BESENInstance.Eval(ScriptContent);
            except
             on e:Exception do begin
              MakeError(e.Message);
             end;
            end;
           end;
          end;
{$endif}
          KeyREPEAT:begin
           ParseInstantREPEAT;
          end;
          KeyWHILE:begin
           ParseInstantWHILE;
          end;
          KeyIF:begin
           ParseInstantIF(false);
          end;
          KeySET:begin
           SkipWhiteSpaceOnSameLine;
           if CheckAlpha then begin
            ReadSymbol;
            if (SymbolType=stUSER) and (SymbolNew or (UserSymbolList[SymbolValue].SymbolType in [ustNONE,ustVARIABLE])) then begin
             SkipWhiteSpaceOnSameLine;
             if LastChar='=' then begin
              GetChar;
              SkipWhiteSpaceOnSameLine;
              Symbol:=UserSymbolList.Items[SymbolValue];
              Symbol.SymbolType:=ustVARIABLE;
              Expression:=ReadExpression;
              try
               Symbol.Calculate(self,Expression);
              finally
               Expression.Free;
              end;
             end else begin
              MakeError('"=" expected');
             end;
            end else begin
             MakeError('Symbol expected');
            end;
           end else begin
            MakeError('Symbol expected');
           end;
          end;
          KeyERROR:begin
           Expression:=ReadExpression;
           try
            MakeError(ValueToString(self,Expression.Evaluate(self,false),true));
           finally
            Expression.Free;
           end;
          end;
          KeyWARNING:begin
           Expression:=ReadExpression;
           try
            MakeWarning(ValueToString(self,Expression.Evaluate(self,false),true));
           finally
            Expression.Free;
           end;
          end;
          else begin
           MakeError(8);
          end;
         end;
        end else begin
         MakeError(8);
        end;
       end else begin
        MakeError(8);
       end;
      end else if CheckPoint then begin
       if CheckAlpha then begin
        AllowedKeywordKinds:=[kkDIRECTIVE];
        ReadSymbol;
        if SymbolType=stKEYWORD then begin
         case SymbolValue of
          KeyBITS:begin
           SkipWhiteSpaceOnSameLine;
           if LastChar='(' then begin
            GetChar;
            SkipWhiteSpaceOnSameLine;
            ReadNumber;
            Code:=NewCode;
            Code^.LineNumber:=LastCurrentLineNumber;
            Code^.Column:=LastCurrentColumn;
            Code^.Source:=CurrentSource;
            Code^.CodeItemType:=tcitBITS;
            Code^.Value:=IntegerValueGetInt64(NumberIntegerValue);
            CurrentBits:=Code^.Value;
            SkipWhiteSpaceOnSameLine;
            if LastChar=')' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
            end else begin
             MakeError('")" expected');
            end;
           end else begin
            MakeError('"(" expected');
           end;
          end;
          KeyUSE16:begin
           SkipWhiteSpaceOnSameLine;
           Code:=NewCode;
           Code^.LineNumber:=LastCurrentLineNumber;
           Code^.Column:=LastCurrentColumn;
           Code^.Source:=CurrentSource;
           Code^.CodeItemType:=tcitBITS;
           Code^.Value:=16;
           CurrentBits:=16;
          end;
          KeyUSE32:begin
           SkipWhiteSpaceOnSameLine;
           Code:=NewCode;
           Code^.LineNumber:=LastCurrentLineNumber;
           Code^.Column:=LastCurrentColumn;
           Code^.Source:=CurrentSource;
           Code^.CodeItemType:=tcitBITS;
           Code^.Value:=32;
           CurrentBits:=32;
          end;
          KeyUSE64:begin
           SkipWhiteSpaceOnSameLine;
           Code:=NewCode;
           Code^.LineNumber:=LastCurrentLineNumber;
           Code^.Column:=LastCurrentColumn;
           Code^.Source:=CurrentSource;
           Code^.CodeItemType:=tcitBITS;
           Code^.Value:=64;
           CurrentBits:=64;
          end;
          KeyLIBRARY:begin
           SkipWhiteSpaceOnSameLine;
           if LastChar='(' then begin
            GetChar;
            SkipWhiteSpaceOnSameLine;
            ReadString;
            SkipWhiteSpaceOnSameLine;
            if LastChar=')' then begin
             GetChar;
             CurrentLibrary:=StringData;
             Code:=NewCode;
             Code^.LineNumber:=LastCurrentLineNumber;
             Code^.Column:=LastCurrentColumn;
             Code^.Source:=CurrentSource;
             Code^.CodeItemType:=tcitLIBRARY;
             Code^.StringData:=StringData;
             SkipWhiteSpaceOnSameLine;
             if LastChar='{' then begin
              GetChar;
              SkipWhiteSpaceOnSameLine;
              IsNewLine:=true;
              while (LastChar<>'}') and not AreErrors do begin
               if IsLineEnd then begin
                GetChar;
                SkipWhiteSpaceOnSameLine;
                IsNewLine:=true;
               end else if IsNewLine then begin
                ReadSymbol;
                SkipWhiteSpaceOnSameLine;
                if LastChar<>'=' then begin
                 MakeError('Library import group syntax error');
                 break;
                end;
                GetChar;
                SkipWhiteSpaceOnSameLine;
                CodeSymbolIndex:=SymbolValue;
                ReadString;
                SkipWhiteSpaceOnSameLine;
                NewImport(CodeSymbolIndex,CurrentLibrary,StringData);
                Code:=NewCode;
                Code^.LineNumber:=LastCurrentLineNumber;
                Code^.Column:=LastCurrentColumn;
                Code^.Source:=CurrentSource;
                Code^.CodeItemType:=tcitIMPORT;
                Code^.SymbolIndex:=CodeSymbolIndex;
                Code^.StringData:=StringData;
                IsNewLine:=false;
               end else begin
                MakeError('Library import group syntax error');
                break;
               end;
              end;
              if LastChar='}' then begin
               GetChar;
               SkipWhiteSpaceOnSameLine;
              end else begin
               MakeError('Library import group syntax error');
              end;
             end;
            end else begin
             MakeError('Library import syntax error');
            end;
           end else begin
            MakeError('Library import syntax error');
           end;
          end;
          KeyEXPORT:begin
           SkipWhiteSpaceOnSameLine;
           if LastChar='(' then begin
            GetChar;
            SkipWhiteSpaceOnSameLine;
            ReadSymbol;
            CodeSymbolIndex:=SymbolValue;
            SkipWhiteSpaceOnSameLine;
            if LastChar='=' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
            end else begin
             MakeError('"=" expected');
             exit;
            end;
            ReadString;
            NewExport(CodeSymbolIndex,StringData);
            Code:=NewCode;
            Code^.LineNumber:=LastCurrentLineNumber;
            Code^.Column:=LastCurrentColumn;
            Code^.Source:=CurrentSource;
            Code^.CodeItemType:=tcitEXPORT;
            Code^.SymbolIndex:=CodeSymbolIndex;
            Code^.StringData:=StringData;
            SkipWhiteSpaceOnSameLine;
            if LastChar=')' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
            end else begin
             MakeError('")" expected');
            end;
           end else begin
            MakeError('"(" expected');
           end;
          end;
          KeySEGMENT:begin
           Segment:=nil;
           SkipWhiteSpaceOnSameLine;
           if LastChar='(' then begin
            GetChar;
            SkipWhiteSpaceOnSameLine;
            if CheckAlpha then begin
             ReadSymbol;
             if SymbolType=stUSER then begin
              CodeSymbolIndex:=SymbolValue;
              SkipWhiteSpaceOnSameLine;
              Symbol:=UserSymbolList[CodeSymbolIndex];
              if Symbol.SymbolType=ustNONE then begin
               Symbol.SymbolType:=ustSEGMENT;
               Symbol.Segment:=self.GetSegmentPerName(Symbol.OriginalName);
               Segment:=Symbol.Segment;
              end else begin
               MakeError(29);
              end;
             end else begin
              MakeError(29);
             end;
            end else begin
             MakeError(29);
            end;
            if LastChar=')' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
            end else begin
             MakeError('")" expected');
            end;
           end else begin
            MakeError('"(" expected');
           end;
           if assigned(Segment) and not AreErrors then begin
            Code:=NewCode;
            Code^.LineNumber:=LastCurrentLineNumber;
            Code^.Column:=LastCurrentColumn;
            Code^.Source:=CurrentSource;
            Code^.CodeItemType:=tcitSEGMENT;
            Code^.Segment:=Segment;
            Code^.SymbolIndex:=-1;
            OldLastCode:=LastCode;
            ParseGroup(44);
            OldLastCode^.Down:=OldLastCode^.Next;
            LastCode:=OldLastCode;
            LastCode^.Next:=nil;
           end;
          end;
          KeySECTION:begin
           Section:=nil;
           SkipWhiteSpaceOnSameLine;
           if LastChar='(' then begin
            GetChar;
            SkipWhiteSpaceOnSameLine;
            ReadString;
            SkipWhiteSpaceOnSameLine;
            Section:=GetSectionPerName(StringData);
            if LastChar=',' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
             if assigned(Section^.Flags) then begin
              Expression:=Section^.Flags;
              Section^.Flags:=TAssemblerExpression.Create;
              Section^.Flags.Operation:='|';
              Section^.Flags.Left:=Expression;
              Section^.Flags.Right:=ReadExpression;
             end else begin
              Section^.Flags:=ReadExpression;
             end;
             while assigned(Section^.Flags) and Section^.Flags.Optimize(self) and not AreErrors do begin
             end;
             if LastChar=',' then begin
              GetChar;
              SkipWhiteSpaceOnSameLine;
              FreeAndNil(Section^.Align);
              Section^.Align:=ReadExpression;
              while assigned(Section^.Align) and Section^.Align.Optimize(self) and not AreErrors do begin
              end;
             end;
             if LastChar=')' then begin
              GetChar;
              SkipWhiteSpaceOnSameLine;
             end else begin
              MakeError(44);
             end;
            end else begin
             MakeError(44);
            end;
           end else begin
            MakeError(44);
           end;
           if assigned(Section) and not AreErrors then begin
            Code:=NewCode;
            Code^.LineNumber:=LastCurrentLineNumber;
            Code^.Column:=LastCurrentColumn;
            Code^.Source:=CurrentSource;
            Code^.CodeItemType:=tcitSECTION;
            Code^.Section:=Section;
            Code^.SymbolIndex:=-1;
            OldLastCode:=LastCode;
            ParseGroup(44);
            OldLastCode^.Down:=OldLastCode^.Next;
            LastCode:=OldLastCode;
            LastCode^.Next:=nil;
           end;
          end;
          KeyDIRECTORYENTRY:begin
           Code:=NewCode;
           Code^.LineNumber:=LastCurrentLineNumber;
           Code^.Column:=LastCurrentColumn;
           Code^.Source:=CurrentSource;
           Code^.CodeItemType:=tcitDIRECTORYENTRY;
           SkipWhiteSpaceOnSameLine;
           if LastChar='(' then begin
            GetChar;
            SkipWhiteSpaceOnSameLine;
            Code^.Expression:=ReadExpression;
            if LastChar=')' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
            end else begin
             MakeError(73);
            end;
           end else begin
            MakeError(73);
           end;
           if not AreErrors then begin
            OldLastCode:=LastCode;
            ParseGroup(73);
            OldLastCode^.Down:=OldLastCode^.Next;
            LastCode:=OldLastCode;
            LastCode^.Next:=nil;
           end;
          end;
          KeyTARGET:begin
           SkipWhiteSpaceOnSameLine;
           if LastChar='(' then begin
            GetChar;
            SkipWhiteSpaceOnSameLine;
            ReadAlpha;
            if SymbolName='BIN' then begin
             Target:=ttBIN;
             StartOffset:=0;
             CurrentBits:=16;
             StackSize:=65535;
             HeapSize:=0;
            end else if SymbolName='COM' then begin
             Target:=ttCOM;
             StartOffset:=$100;
             CurrentBits:=16;
             StackSize:=65535;
             HeapSize:=0;
            end else if SymbolName='MZEXE' then begin
             Target:=ttMZEXE;
             StartOffset:=$100;
             CurrentBits:=16;
             StackSize:=65535;
             HeapSize:=0;
            end else if SymbolName='PE32' then begin
             Target:=ttPEEXE32;
             StartOffset:=0;
             CodeBase:=$1000;
             ImageBase:=$400000;
             SubSystem:=IMAGE_SUBSYSTEM_WINDOWS_GUI;
             Characteristics:=IMAGE_FILE_RELOCS_STRIPPED or IMAGE_FILE_EXECUTABLE_IMAGE or IMAGE_FILE_LINE_NUMS_STRIPPED or IMAGE_FILE_LOCAL_SYMS_STRIPPED or IMAGE_FILE_DEBUG_STRIPPED or IMAGE_FILE_32BIT_MACHINE;
             DLLCharacteristics:=0;
             SizeOfStackReserve:=$100000;
             SizeOfStackCommit:=$2000;
             SizeOfHeapReserve:=$100000;
             SizeOfHeapCommit:=$2000;
             CurrentBits:=32;
             StackSize:=16777216;
             HeapSize:=67108864;
            end else if SymbolName='PE64' then begin
             Target:=ttPEEXE64;
             StartOffset:=0;
             CodeBase:=$1000;
             ImageBase:=$400000;
             SubSystem:=IMAGE_SUBSYSTEM_WINDOWS_GUI;
             Characteristics:=IMAGE_FILE_RELOCS_STRIPPED or IMAGE_FILE_EXECUTABLE_IMAGE or IMAGE_FILE_LINE_NUMS_STRIPPED or IMAGE_FILE_LOCAL_SYMS_STRIPPED or IMAGE_FILE_DEBUG_STRIPPED;
             DLLCharacteristics:=0;
             SizeOfStackReserve:=$100000;
             SizeOfStackCommit:=$2000;
             SizeOfHeapReserve:=$100000;
             SizeOfHeapCommit:=$2000;
             CurrentBits:=64;
             StackSize:=16777216;
             HeapSize:=67108864;
            end else if SymbolName='COFFDOS' then begin
             Target:=ttCOFFDOS;
             StartOffset:=0;
             CodeBase:=$1000;
             ImageBase:=$400000;
             CurrentBits:=32;
             StackSize:=16777216;
             HeapSize:=67108864;
            end else if SymbolName='COFF32' then begin
             Target:=ttCOFF32;
             StartOffset:=0;
             CodeBase:=$1000;
             ImageBase:=$400000;
             CurrentBits:=32;
             StackSize:=16777216;
             HeapSize:=67108864;
            end else if SymbolName='COFF64' then begin
             Target:=ttCOFF64;
             StartOffset:=0;
             CodeBase:=$1000;
             ImageBase:=$400000;
             CurrentBits:=64;
             StackSize:=16777216;
             HeapSize:=67108864;
            end else if SymbolName='ELF32' then begin
             Target:=ttELF32;
             ELFType:=1; // ET_REL
             StartOffset:=0;
             CodeBase:=$1000;
             ImageBase:=$400000;
             CurrentBits:=32;
             StackSize:=16777216;
             HeapSize:=67108864;
            end else if SymbolName='ELFX32' then begin
             Target:=ttELFX32;
             ELFType:=1; // ET_REL
             StartOffset:=0;
             CodeBase:=$1000;
             ImageBase:=$400000;
             CurrentBits:=64;
             StackSize:=16777216;
             HeapSize:=67108864;
            end else if SymbolName='ELF64' then begin
             Target:=ttELF64;
             ELFType:=1; // ET_REL
             StartOffset:=0;
             CodeBase:=$1000;
             ImageBase:=$400000;
             CurrentBits:=64;
             StackSize:=16777216;
             HeapSize:=67108864;
            end else if SymbolName='OMF16' then begin
             Target:=ttOMF16;
             StartOffset:=0;
             CodeBase:=$1000;
             ImageBase:=$400000;
             CurrentBits:=16;
             StackSize:=16777216;
             HeapSize:=67108864;
            end else if SymbolName='OMF32' then begin
             Target:=ttOMF32;
             StartOffset:=0;
             CodeBase:=$1000;
             ImageBase:=$400000;
             CurrentBits:=16;
             StackSize:=16777216;
             HeapSize:=67108864;
            end else if SymbolName='RUNTIME' then begin
             Target:=ttRUNTIME;
             StartOffset:=0;
{$ifdef cpu64}
             CurrentBits:=64;
{$else}
             CurrentBits:=32;
{$endif}
            end else if SymbolName='TRI32' then begin
             Target:=ttTRI32;
             StartOffset:=0;
             CodeBase:=$1000;
             ImageBase:=$400000;
             CurrentBits:=32;
             StackSize:=16777216;
             HeapSize:=67108864;
            end else if SymbolName='TRI64' then begin
             Target:=ttTRI64;
             StartOffset:=0;
             CodeBase:=$1000;
             ImageBase:=$400000;
             CurrentBits:=64;
             StackSize:=16777216;
             HeapSize:=67108864;
            end else begin
             MakeError('Unknown target file format');
            end;
            SkipWhiteSpaceOnSameLine;
            if LastChar=')' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
            end else begin
             MakeError('")" expected');
            end;
           end else begin
            MakeError('"(" expected');
           end;
           if not AreErrors then begin
            begin
             Code:=NewCode;
             Code^.LineNumber:=LastCurrentLineNumber;
             Code^.Column:=LastCurrentColumn;
             Code^.Source:=CurrentSource;
             Code^.CodeItemType:=tcitBITS;
             Code^.Value:=CurrentBits;
            end;
            SkipWhiteSpaceOnSameLine;
            if LastChar='{' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
             IsNewLine:=true;
             while (LastChar<>'}') and not AreErrors do begin
              if IsLineEnd then begin
               GetChar;
               SkipWhiteSpaceOnSameLine;
               IsNewLine:=true;
              end else if IsNewLine then begin
               ReadAlpha;
               SkipWhiteSpaceOnSameLine;
               if LastChar<>'=' then begin
                MakeError('Target group syntax error');
                break;
               end;
               GetChar;
               SkipWhiteSpaceOnSameLine;
               if SymbolName='STACK' then begin
                Code:=NewCode;
                Code^.LineNumber:=LastCurrentLineNumber;
                Code^.Column:=LastCurrentColumn;
                Code^.Source:=CurrentSource;
                Code^.CodeItemType:=tcitSTACK;
                Code^.Expression:=ReadExpression;
               end else if SymbolName='HEAP' then begin
                Code:=NewCode;
                Code^.LineNumber:=LastCurrentLineNumber;
                Code^.Column:=LastCurrentColumn;
                Code^.Source:=CurrentSource;
                Code^.CodeItemType:=tcitHEAP;
                Code^.Expression:=ReadExpression;
               end else if SymbolName='CODEBASE' then begin
                Code:=NewCode;
                Code^.LineNumber:=LastCurrentLineNumber;
                Code^.Column:=LastCurrentColumn;
                Code^.Source:=CurrentSource;
                Code^.CodeItemType:=tcitCODEBASE;
                Code^.Expression:=ReadExpression;
               end else if SymbolName='IMAGEBASE' then begin
                Code:=NewCode;
                Code^.LineNumber:=LastCurrentLineNumber;
                Code^.Column:=LastCurrentColumn;
                Code^.Source:=CurrentSource;
                Code^.CodeItemType:=tcitIMAGEBASE;
                Code^.Expression:=ReadExpression;
               end else if SymbolName='SUBSYSTEM' then begin
                Code:=NewCode;
                Code^.LineNumber:=LastCurrentLineNumber;
                Code^.Column:=LastCurrentColumn;
                Code^.Source:=CurrentSource;
                Code^.CodeItemType:=tcitSUBSYSTEM;
                Code^.Expression:=ReadExpression;
               end else if SymbolName='CHARACTERISTICS' then begin
                Code:=NewCode;
                Code^.LineNumber:=LastCurrentLineNumber;
                Code^.Column:=LastCurrentColumn;
                Code^.Source:=CurrentSource;
                Code^.CodeItemType:=tcitCHARACTERISTICS;
                Code^.Expression:=ReadExpression;
               end else if SymbolName='DLLCHARACTERISTICS' then begin
                Code:=NewCode;
                Code^.LineNumber:=LastCurrentLineNumber;
                Code^.Column:=LastCurrentColumn;
                Code^.Source:=CurrentSource;
                Code^.CodeItemType:=tcitDLLCHARACTERISTICS;
                Code^.Expression:=ReadExpression;
               end else if SymbolName='SIZEOFSTACKRESERVE' then begin
                Code:=NewCode;
                Code^.LineNumber:=LastCurrentLineNumber;
                Code^.Column:=LastCurrentColumn;
                Code^.Source:=CurrentSource;
                Code^.CodeItemType:=tcitSIZEOFSTACKRESERVE;
                Code^.Expression:=ReadExpression;
               end else if SymbolName='SIZEOFSTACKCOMMIT' then begin
                Code:=NewCode;
                Code^.LineNumber:=LastCurrentLineNumber;
                Code^.Column:=LastCurrentColumn;
                Code^.Source:=CurrentSource;
                Code^.CodeItemType:=tcitSIZEOFSTACKCOMMIT;
                Code^.Expression:=ReadExpression;
               end else if SymbolName='SIZEOFHEAPRESERVE' then begin
                Code:=NewCode;
                Code^.LineNumber:=LastCurrentLineNumber;
                Code^.Column:=LastCurrentColumn;
                Code^.Source:=CurrentSource;
                Code^.CodeItemType:=tcitSIZEOFHEAPRESERVE;
                Code^.Expression:=ReadExpression;
               end else if SymbolName='SIZEOFHEAPCOMMIT' then begin
                Code:=NewCode;
                Code^.LineNumber:=LastCurrentLineNumber;
                Code^.Column:=LastCurrentColumn;
                Code^.Source:=CurrentSource;
                Code^.CodeItemType:=tcitSIZEOFHEAPCOMMIT;
                Code^.Expression:=ReadExpression;
               end else if SymbolName='STARTOFFSET' then begin
                Code:=NewCode;
                Code^.LineNumber:=LastCurrentLineNumber;
                Code^.Column:=LastCurrentColumn;
                Code^.Source:=CurrentSource;
                Code^.CodeItemType:=tcitSTARTOFFSET;
                Code^.Expression:=ReadExpression;
               end else if (Target in [ttELF32,ttELFX32,ttELF64]) and (SymbolName='TYPE') then begin
                Code:=NewCode;
                Code^.LineNumber:=LastCurrentLineNumber;
                Code^.Column:=LastCurrentColumn;
                Code^.Source:=CurrentSource;
                Code^.CodeItemType:=tcitELFTYPE;
                Code^.Expression:=ReadExpression;
               end else begin
                MakeError('Unknown target parameter');
               end;
               SkipWhiteSpaceOnSameLine;
               IsNewLine:=false;
              end else begin
               MakeError('Target group syntax error');
               break;
              end;
             end;
             if LastChar='}' then begin
              GetChar;
              SkipWhiteSpaceOnSameLine;
             end else begin
              MakeError('Target group syntax error');
             end;
            end;
           end;
          end;
          KeyENTRYPOINT:begin
           Code:=NewCode;
           Code^.LineNumber:=CurrentLineNumber;
           Code^.Column:=CurrentColumn;
           Code^.Source:=CurrentSource;
           Code^.CodeItemType:=tcitENTRYPOINT;
          end;
          KeyREPEAT:begin
           ParseREPEAT;
          end;
          KeyWHILE:begin
           ParseWHILE;
          end;
          KeyIF:begin
           ParseIF(false);
          end;
          KeySCRIPT:begin
           ScriptContent:=ParseScriptCodeString;
           if length(ScriptContent)>0 then begin
            Code:=NewCode;
            Code^.LineNumber:=CurrentLineNumber;
            Code^.Column:=CurrentColumn;
            Code^.Source:=CurrentSource;
            Code^.CodeItemType:=tcitSCRIPT;
            Code^.StringData:=ScriptContent;
           end;
          end;
          KeyDEFINE:begin
           LastCurrentLineNumber:=CurrentLineNumber;
           SkipWhiteSpaceOnSameLine;
           if LastChar='(' then begin
            GetChar;
            SkipWhiteSpaceOnSameLine;
           end else begin
            MakeError('"(" expected');
            exit;
           end;
           if CheckAlpha then begin
            ReadAlpha;
            SkipWhiteSpaceOnSameLine;
            if LastChar=')' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
            end else begin
             MakeError('")" expected');
             exit;
            end;
            MacroParameter:='';
            if LastChar='(' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
             if LastChar<>')' then begin
              Level:=1;
              while ((Level>0) and (LastChar<>#0)) and not AreErrors do begin
               MacroParameter:=MacroParameter+LastChar;
               GetChar;
               case LastChar of
                '(':inc(Level);
                ')':dec(Level);
               end;
              end;
             end;
             if LastChar=')' then begin
              GetChar;
              SkipWhiteSpaceOnSameLine;
             end else begin
              MakeError(16);
             end;
            end;
            Parameters:=TStringList.Create;
            try
             MacroContent:='';
             if LastChar='{' then begin
              MakeError('Defines must be single-line');
             end else begin
              while not (IsLineEnd or AreErrors) do begin
               if LastChar<>#13 then begin
                MacroContent:=MacroContent+LastChar;
               end;
               GetChar;
              end;
             end;
             if not AreErrors then begin
              StringPosition:=1;
              StringLength:=length(MacroParameter);
              while (StringPosition<=StringLength) and not AreErrors do begin
               while (StringPosition<=StringLength) and (MacroParameter[StringPosition] in [#1..#32]) do begin
                inc(StringPosition);
               end;
               Parameters.Add(ParseStringContent(MacroParameter,[','],StringPosition,false));
               while (StringPosition<=StringLength) and (MacroParameter[StringPosition] in [#1..#32]) do begin
                inc(StringPosition);
               end;
              end;
              for ParameterIndex:=0 to Parameters.Count-1 do begin
               ParameterName:=Parameters[ParameterIndex];
               ParameterStringValue:=' __parameter__('+IntToStr(ParameterIndex)+') ';
               MacroContent:=StringReplace(MacroContent,ParameterName,ParameterStringValue,true,true);
              end;
              OldCurrentLineNumber:=CurrentLineNumber;
              OldCurrentColumn:=CurrentColumn;
              OldCurrentSource:=CurrentSource;
              CurrentLineNumber:=LastCurrentLineNumber;
              CurrentColumn:=0;
              ParseString(OriginalSymbolName+' equ '+MacroContent);
              CurrentLineNumber:=OldCurrentLineNumber;
              CurrentColumn:=OldCurrentColumn;
              CurrentSource:=OldCurrentSource;
             end;
             MacroContent:='';
             MacroParameter:='';
            finally
             Parameters.Free;
            end;
           end else begin
            MakeError(17);
           end;
          end;
          KeyMACRO:begin
           SkipWhiteSpaceOnSameLine;
           if LastChar='(' then begin
            GetChar;
            SkipWhiteSpaceOnSameLine;
           end else begin
            MakeError('"(" expected');
            exit;
           end;
           if CheckAlpha then begin
            ReadSymbol;
            SkipWhiteSpaceOnSameLine;
            if LastChar=')' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
            end else begin
             MakeError('")" expected');
             exit;
            end;
            if SymbolType=stUSER then begin
             CodeSymbolIndex:=SymbolValue;
             MacroSymbol:=UserSymbolList[CodeSymbolIndex];
             if SymbolNew or (MacroSymbol.SymbolType=ustNONE) then begin
              SkipWhiteSpaceOnSameLine;
              MacroParameter:='';
              if LastChar='(' then begin
               GetChar;
               SkipWhiteSpaceOnSameLine;
               if LastChar<>')' then begin
                Level:=1;
                while ((Level>0) and (LastChar<>#0)) and not AreErrors do begin
                 MacroParameter:=MacroParameter+LastChar;
                 GetChar;
                 case LastChar of
                  '(':inc(Level);
                  ')':dec(Level);
                 end;
                end;
               end;
               if LastChar=')' then begin
                GetChar;
                SkipWhiteSpaceOnSameLine;
               end else begin
                MakeError(16);
               end;
              end;
              Parameters:=TStringList.Create;
              try
               Locals:=TStringList.Create;
               try
                Lines:=TStringList.Create;
                try
                 MacroContent:='';
                 if LastChar='{' then begin
                  MultiLine:=true;
                  GetChar;
                  SkipWhiteSpaceOnSameLine;
                  if LastChar<>'}' then begin
                   Level:=1;
                   while ((Level>0) and (LastChar<>#0)) and not AreErrors do begin
                    if LastChar<>#13 then begin
                     MacroContent:=MacroContent+LastChar;
                    end;
                    GetChar;
                    case LastChar of
                     '{':inc(Level);
                     '}':dec(Level);
                    end;
                   end;
                  end;
                  if LastChar='}' then begin
                   GetChar;
                  end else begin
                   MakeError(16);
                  end;
                 end else begin
                  MultiLine:=false;
                  while not (IsLineEnd or AreErrors) do begin
                   if LastChar<>#13 then begin
                    MacroContent:=MacroContent+LastChar;
                   end;
                   GetChar;
                  end;
                 end;
                 if not AreErrors then begin
                  StringPosition:=1;
                  StringLength:=length(MacroParameter);
                  while (StringPosition<=StringLength) and not AreErrors do begin
                   while (StringPosition<=StringLength) and (MacroParameter[StringPosition] in [#1..#32]) do begin
                    inc(StringPosition);
                   end;
                   Parameters.Add(ParseStringContent(MacroParameter,[','],StringPosition,false));
                   while (StringPosition<=StringLength) and (MacroParameter[StringPosition] in [#1..#32]) do begin
                    inc(StringPosition);
                   end;
                  end;
                  if (Parameters.Count>0) and (Parameters[Parameters.Count-1]='...') then begin
                   Parameters.Delete(Parameters.Count-1);
                   VA_ARGS:=true;
                  end else begin
                   VA_ARGS:=false;
                  end;    
                  ParseStringIntoStringList(Lines,MacroContent);
                  MacroContent:='';
                  for StringLineIndex:=0 to Lines.Count-1 do begin
                   StringLine:=Lines[StringLineIndex];
                   StringLinePosition:=1;
                   StringLineLength:=length(StringLine);
                   while (StringLinePosition<=StringLineLength) and (StringLine[StringLinePosition] in [#1..#32]) do begin
                    inc(StringLinePosition);
                   end;
                   if ((StringLinePosition+1)<=StringLineLength) and
                      ((StringLine[StringLinePosition] in ['.','!']) and
                       (StringLine[StringLinePosition+1] in ['A'..'Z','a'..'z','@','_','$'])) then begin
                    inc(StringLinePosition);
                    StringLineStringValue:='';
                    repeat
                     StringLineStringValue:=StringLineStringValue+StringLine[StringLinePosition];
                     inc(StringLinePosition);             
                    until (StringLinePosition>StringLineLength) or not (StringLine[StringLinePosition] in ['A'..'Z','a'..'z','0'..'9','_','@','$']);
                    StringLineStringValue:=UpperCase(StringLineStringValue);
                    if StringLineStringValue='LOCAL' then begin
                     MacroContent:=MacroContent+#10;
                     while (StringLinePosition<=StringLineLength) and (StringLine[StringLinePosition] in [#1..#32]) do begin
                      inc(StringLinePosition);
                     end;
                     while StringLinePosition<=StringLineLength do begin
                      if (StringLinePosition<=StringLineLength) and (StringLine[StringLinePosition] in ['A'..'Z','a'..'z','@','_','$']) then begin
                       StringLineStringValue:='';
                       repeat
                        StringLineStringValue:=StringLineStringValue+StringLine[StringLinePosition];
                        inc(StringLinePosition);
                       until (StringLinePosition>StringLineLength) or not (StringLine[StringLinePosition] in ['A'..'Z','a'..'z','0'..'9','_','@','$']);
                       StringLineStringValue:=UpperCase(StringLineStringValue);
                       if Locals.IndexOf(StringLineStringValue)<0 then begin
                        Locals.Add(StringLineStringValue);
                       end else begin
                        MakeError(72);
                       end;
                       while (StringLinePosition<=StringLineLength) and (StringLine[StringLinePosition] in [#1..#32]) do begin
                        inc(StringLinePosition);
                       end;
                       if (StringLinePosition<=StringLineLength) and (StringLine[StringLinePosition]=',') then begin
                        inc(StringLinePosition);
                        while (StringLinePosition<=StringLineLength) and (StringLine[StringLinePosition] in [#1..#32]) do begin
                         inc(StringLinePosition);
                        end;
                        continue;
                       end else begin
                        if StringLinePosition<=StringLineLength then begin
                         MakeError(16);
                        end;
                        break;
                       end;
                      end else begin
                       MakeError(16);
                       break;
                      end;
                     end;
                     continue;
                    end;
                   end;
                   for ParameterIndex:=0 to Parameters.Count-1 do begin
                    ParameterName:=Parameters[ParameterIndex];
                    ParameterStringValue:=#0+
                                          #1+
                                          ansichar(byte(ParameterIndex and $ff))+
                                          ansichar(byte((ParameterIndex shr 8) and $ff))+
                                          ansichar(byte((ParameterIndex shr 16) and $ff))+
                                          ansichar(byte((ParameterIndex shr 24) and $ff))+
                                          #0;
                    StringLine:=StringReplace(StringLine,ParameterName,ParameterStringValue,true,true);
                   end;
                   for LocalIndex:=Locals.Count-1 downto 0 do begin
                    LocalName:=Locals[LocalIndex];
                    LocalStringValue:=#0+
                                      #2+
                                      ansichar(byte(LocalIndex and $ff))+
                                      ansichar(byte((LocalIndex shr 8) and $ff))+
                                      ansichar(byte((LocalIndex shr 16) and $ff))+
                                      ansichar(byte((LocalIndex shr 24) and $ff))+
                                      #0;
                    StringLine:=StringReplace(StringLine,LocalName,LocalStringValue,true,true);
                   end;
                   if VA_ARGS then begin
                    ParameterName:='__VA_ARGS__';
                    ParameterIndex:=Parameters.Count;
                    ParameterStringValue:=#0+
                                           #5+
                                           ansichar(byte(ParameterIndex and $ff))+
                                           ansichar(byte((ParameterIndex shr 8) and $ff))+
                                           ansichar(byte((ParameterIndex shr 16) and $ff))+
                                           ansichar(byte((ParameterIndex shr 24) and $ff))+
                                           #0;
                    StringLine:=StringReplace(StringLine,ParameterName,ParameterStringValue,true,true);
                   end;
                   StringPosition:=1;
                   StringLength:=length(StringLine);
                   while (StringPosition<=StringLength) and not AreErrors do begin
                    case StringLine[StringPosition] of
                     '''','"':begin
                      TerminateChar:=StringLine[StringPosition];
                      inc(StringPosition);
                      while (StringPosition<=StringLength) and not AreErrors do begin
                       case StringLine[StringPosition] of
                        '''','"':begin
                         if StringLine[StringPosition]=TerminateChar then begin
                          inc(StringPosition);
                          break;
                         end else begin
                          inc(StringPosition);
                         end;
                        end;
                        '\':begin
                         inc(StringPosition);
                         if StringPosition<=StringLength then begin
                          inc(StringPosition);
                         end;
                        end;
                        else begin
                         inc(StringPosition);
                        end;
                       end;
                      end;
                     end;
                     '\':begin
                      Delete(StringLine,StringPosition,1);
                      inc(StringPosition);
                     end;
                     '#':begin
                      if ((StringPosition+4)<=StringLength) and (StringLine[StringPosition+1]='#') and (StringLine[StringPosition+2]='#') and (StringLine[StringPosition+3]='#') then begin
                       inc(StringPosition,5);
                      end else if ((StringPosition+3)<=StringLength) and (StringLine[StringPosition+1]='#') and (StringLine[StringPosition+2]='#') then begin
                       ParameterIndex:=Parameters.Count;
                       ParameterStringValue:=#0+
                                             #6+
                                             ansichar(byte(ParameterIndex and $ff))+
                                             ansichar(byte((ParameterIndex shr 8) and $ff))+
                                             ansichar(byte((ParameterIndex shr 16) and $ff))+
                                             ansichar(byte((ParameterIndex shr 24) and $ff))+
                                             StringLine[StringPosition+3]+
                                             #0;
                       Delete(StringLine,StringPosition,3);
                       Insert(ParameterStringValue,StringLine,StringPosition);
                       StringLength:=length(StringLine);
                      end else if ((StringPosition+1)<=StringLength) and (StringLine[StringPosition+1]='#') then begin
                       Delete(StringLine,StringPosition,2);
                       StringLength:=length(StringLine);
                      end else begin
                       Delete(StringLine,StringPosition,1);
                       StringLength:=length(StringLine);
                       if ((StringPosition+6)<=StringLength) and ((StringLine[StringPosition]=#0) and (StringLine[StringPosition+1]=#1) and (StringLine[StringPosition+6]=#0)) then begin
                        StringLine[StringPosition+1]:=#4;
                       end else if ((StringPosition+6)<=StringLength) and ((StringLine[StringPosition]=#0) and (StringLine[StringPosition+1]=#5) and (StringLine[StringPosition+6]=#0)) then begin
                        StringLine[StringPosition+1]:=#6;
                       end else begin
                        MakeError('Stringify operator can be applied only to parameters');
                       end;
                      end;
                     end;
                     else begin
                      inc(StringPosition);
                     end;
                    end;
                   end;
                   if MultiLine then begin
                    MacroContent:=MacroContent+StringLine+#10;
                   end else begin
                    MacroContent:=MacroContent+StringLine;
                   end;
                  end;
                  if MultiLine then begin
                   MacroSymbol.SymbolType:=ustMACRO;
                  end else begin
                   MacroSymbol.SymbolType:=ustONELINEMACRO;
                  end;
                  MacroSymbol.Content:=MacroContent;
                  MacroSymbol.MultiLine:=MultiLine;
                  MacroSymbol.VA_ARGS:=VA_ARGS;
                  MacroSymbol.CountParameters:=Parameters.Count;
                  MacroSymbol.CountLocals:=Locals.Count;
                 end;
                 MacroContent:='';
                 MacroParameter:='';
                finally
                 Lines.Free;
                end;
               finally
                Locals.Free;
               end;
              finally
               Parameters.Free;
              end;
             end else begin
              MakeError(17);
             end;
            end else begin
             MakeError(16);
            end;
           end;
          end;
          KeyUNMACRO:begin
           SkipWhiteSpaceOnSameLine;
           if LastChar='(' then begin
            GetChar;
            SkipWhiteSpaceOnSameLine;
            if CheckAlpha then begin
             ReadSymbol;
             if SymbolType=stUSER then begin
              MacroSymbol:=UserSymbolList[SymbolValue];
              if MacroSymbol.SymbolType in [ustMACRO,ustONELINEMACRO] then begin
               MacroSymbol.SymbolType:=ustNONE;
              end else begin
               MakeError('"'+MacroSymbol.OriginalName+'" is not a macro');
              end;
             end else begin
              MakeError('"'+OriginalSymbolName+'" is not a macro');
             end;
            end else begin
             MakeError('Macro symbol expected');
            end;
            SkipWhiteSpaceOnSameLine;
            if LastChar=')' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
            end else begin
             MakeError('")" expected');
            end;
           end else begin
            MakeError('"(" expected');
           end;
          end;
          KeyINCLUDE:begin
           SkipWhiteSpaceOnSameLine;
           if LastChar='(' then begin
            GetChar;
            SkipWhiteSpaceOnSameLine;
            while not AreErrors do begin
             ReadString;
             StringData:=GetAbsoluteFileEx(CurrentFileName,StringData);
             if CheckFile(StringData) then begin
              ParseFile(StringData);
             end else begin
              MakeError(23);
             end;
             if not CheckComma then begin
              break;
             end;
            end;
            if assigned(Status) then begin
             ShowParsingStatus;
            end;
            SkipWhiteSpaceOnSameLine;
            if LastChar=')' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
            end else begin
             MakeError('")" expected');
            end;
           end else begin
            MakeError('"(" expected');
           end;
          end;
          KeyINCBIN:begin
           SkipWhiteSpaceOnSameLine;
           if LastChar='(' then begin
            GetChar;
            SkipWhiteSpaceOnSameLine;
            ReadString;
            Code:=NewCode;
            Code^.LineNumber:=LastCurrentLineNumber;
            Code^.Column:=LastCurrentColumn;
            Code^.Source:=CurrentSource;
            Code^.CodeItemType:=tcitDataRawString;
            StringData:=GetAbsoluteFileEx(CurrentFileName,StringData);
            if CheckFile(StringData) then begin
             Code^.StringData:=ReadFileAsString(StringData);
             if CheckComma then begin
              Code^.Expression:=ReadExpression;
              if CheckComma then begin
               Code^.SecondExpression:=ReadExpression;
              end;
             end;
            end else begin
             MakeError(23);
            end;
            if assigned(Status) then begin
             ShowParsingStatus;
            end;
            SkipWhiteSpaceOnSameLine;
            if LastChar=')' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
            end else begin
             MakeError('")" expected');
            end;
           end else begin
            MakeError('"(" expected');
           end;
          end;
          KeyWARNING:begin
           SkipWhiteSpaceOnSameLine;
           if LastChar='(' then begin
            GetChar;
            SkipWhiteSpaceOnSameLine;
            Code:=NewCode;
            Code^.LineNumber:=LastCurrentLineNumber;
            Code^.Column:=LastCurrentColumn;
            Code^.Source:=CurrentSource;
            Code^.CodeItemType:=tcitWARNING;
            Code^.Expression:=ReadExpression;
            SkipWhiteSpaceOnSameLine;
            if LastChar=')' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
            end else begin
             MakeError('")" expected');
            end;
           end else begin
            MakeError('"(" expected');
           end;
          end;
          KeyERROR:begin
           SkipWhiteSpaceOnSameLine;
           if LastChar='(' then begin
            GetChar;
            SkipWhiteSpaceOnSameLine;
            Code:=NewCode;
            Code^.LineNumber:=LastCurrentLineNumber;
            Code^.Column:=LastCurrentColumn;
            Code^.Source:=CurrentSource;
            Code^.CodeItemType:=tcitERROR;
            Code^.Expression:=ReadExpression;
            SkipWhiteSpaceOnSameLine;
            if LastChar=')' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
            end else begin
             MakeError('")" expected');
            end;
           end else begin
            MakeError('"(" expected');
           end;
          end;
          KeyORG:begin
           SkipWhiteSpaceOnSameLine;
           if LastChar='(' then begin
            GetChar;
            SkipWhiteSpaceOnSameLine;
            Code:=NewCode;
            Code^.LineNumber:=LastCurrentLineNumber;
            Code^.Column:=LastCurrentColumn;
            Code^.Source:=CurrentSource;
            Code^.CodeItemType:=tcitOFFSET;
            Code^.Expression:=ReadExpression;
            SkipWhiteSpaceOnSameLine;
            if LastChar=')' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
            end else begin
             MakeError('")" expected');
            end;
           end else begin
            MakeError('"(" expected');
           end;
          end;
          KeySTARTOFFSET:begin
           SkipWhiteSpaceOnSameLine;
           if LastChar='(' then begin
            GetChar;
            SkipWhiteSpaceOnSameLine;
            Code:=NewCode;
            Code^.LineNumber:=LastCurrentLineNumber;
            Code^.Column:=LastCurrentColumn;
            Code^.Source:=CurrentSource;
            Code^.CodeItemType:=tcitSTARTOFFSET;
            Code^.Expression:=ReadExpression;
            SkipWhiteSpaceOnSameLine;
            if LastChar=')' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
            end else begin
             MakeError('")" expected');
            end;
           end else begin
            MakeError('"(" expected');
           end;
          end;
          KeyALIGN:begin
           SkipWhiteSpaceOnSameLine;
           if LastChar='(' then begin
            GetChar;
            SkipWhiteSpaceOnSameLine;
            Code:=NewCode;
            Code^.LineNumber:=LastCurrentLineNumber;
            Code^.Column:=LastCurrentColumn;
            Code^.Source:=CurrentSource;
            Code^.CodeItemType:=tcitALIGN;
            Code^.Expression:=ReadExpression;
            SkipWhiteSpaceOnSameLine;
            if LastChar=')' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
            end else begin
             MakeError('")" expected');
            end;
           end else begin
            MakeError('"(" expected');
           end;
          end;
          KeyEND:begin
           Code:=NewCode;
           Code^.LineNumber:=LastCurrentLineNumber;
           Code^.Column:=LastCurrentColumn;
           Code^.Source:=CurrentSource;
           Code^.CodeItemType:=tcitEND;
          end;
          KeySMARTLINK:begin
           SkipWhiteSpaceOnSameLine;
           if CheckAlpha then begin
            ReadSymbol;
            SkipWhiteSpaceOnSameLine;
            if SymbolType=stUSER then begin
             CodeSymbolIndex:=SymbolValue;
             if UserSymbolList[CodeSymbolIndex].SymbolType=ustNONE then begin
              SkipWhiteSpaceOnSameLine;
              UserSymbolList[CodeSymbolIndex].SymbolType:=ustLABEL;
              Code:=NewCode;
              Code^.LineNumber:=LastCurrentLineNumber;
              Code^.Column:=LastCurrentColumn;
              Code^.Source:=CurrentSource;
              Code^.CodeItemType:=tcitSMARTLINK;
              Code^.SymbolIndex:=CodeSymbolIndex;
              OldLastCode:=LastCode;
              Code:=NewCode;
              Code^.LineNumber:=LastCurrentLineNumber;
              Code^.Column:=LastCurrentColumn;
              Code^.Source:=CurrentSource;
              Code^.CodeItemType:=tcitLabel;
              Code^.SymbolIndex:=CodeSymbolIndex;
              ParseGroup(28);
              OldLastCode^.Down:=OldLastCode^.Next;
              LastCode:=OldLastCode;
              LastCode^.Next:=nil;
             end else begin
              MakeError(29);
             end;
            end else begin
             MakeError(14);
            end;
           end else begin
            MakeError(28);
           end;
          end;
          KeyBYTEDIFF:begin
           SkipWhiteSpaceOnSameLine;
           Code:=NewCode;
           Code^.LineNumber:=LastCurrentLineNumber;
           Code^.Column:=LastCurrentColumn;
           Code^.Source:=CurrentSource;
           Code^.CodeItemType:=tcitBYTEDIFF;
           Code^.SymbolIndex:=-1;
           OldLastCode:=LastCode;
           ParseGroup(34);
           OldLastCode^.Down:=OldLastCode^.Next;
           LastCode:=OldLastCode;
           LastCode^.Next:=nil;
          end;
          KeyCODE:begin
           SkipWhiteSpaceOnSameLine;
           if LastChar='(' then begin
            GetChar;
            SkipWhiteSpaceOnSameLine;
            if LastChar<>')' then begin
             Level:=1;
             while ((Level>0) and (LastChar<>#0)) and not AreErrors do begin
              GetChar;
              case LastChar of
               '(':inc(Level);
               ')':dec(Level);
              end;
             end;
            end;
            if LastChar=')' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
            end else begin
             MakeError('")" expected');
            end;
           end;
           ParseGroup(22);
          end;
          KeyCOMMENT:begin
           SkipWhiteSpaceOnSameLine;
           if LastChar='{' then begin
            GetChar;
            SkipWhiteSpaceOnSameLine;
            if LastChar<>'}' then begin
             Level:=1;
             while ((Level>0) and (LastChar<>#0)) and not AreErrors do begin
              GetChar;
              case LastChar of
               '{':inc(Level);
               '}':dec(Level);
              end;
             end;
            end;
            if LastChar='}' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
            end else begin
             MakeError(38);
            end;
           end else begin
            MakeError(38);
           end;
          end;
          KeyEXTERNAL:begin
           SkipWhiteSpaceOnSameLine;
           if LastChar='(' then begin
            GetChar;
            SkipWhiteSpaceOnSameLine;
            if CheckAlpha then begin
             ReadSymbol;
             SkipWhiteSpaceOnSameLine;
             if SymbolType=stUSER then begin
              CodeSymbolIndex:=SymbolValue;
              if UserSymbolList[CodeSymbolIndex].SymbolType=ustNONE then begin
               UserSymbolList[CodeSymbolIndex].SymbolType:=ustLABEL;
               UserSymbolList[CodeSymbolIndex].IsPublic:=false;
               UserSymbolList[CodeSymbolIndex].IsExternal:=true;
               SkipWhiteSpaceOnSameLine;
               if LastChar='=' then begin
                GetChar;
                SkipWhiteSpaceOnSameLine;
                if LastChar in ['''','"'] then begin
                 ReadString;
                 UserSymbolList[CodeSymbolIndex].OriginalName:=StringData;
                 SkipWhiteSpaceOnSameLine;
                end;
               end;
              end else if not UserSymbolList[CodeSymbolIndex].IsExternal then begin
               MakeError(45);
              end;
             end else begin
              MakeError(14);
             end;
            end else begin
             MakeError(14);
            end;
            SkipWhiteSpaceOnSameLine;
            if LastChar=')' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
            end else begin
             MakeError('")" expected');
            end;
           end else begin
            MakeError('"(" expected');
           end;
          end;
          KeyPUBLIC:begin
           SkipWhiteSpaceOnSameLine;
           if LastChar='(' then begin
            GetChar;
            SkipWhiteSpaceOnSameLine;
            if CheckAlpha then begin
             ReadSymbol;
             SkipWhiteSpaceOnSameLine;
             if SymbolType=stUSER then begin
              CodeSymbolIndex:=SymbolValue;
              if (UserSymbolList[CodeSymbolIndex].SymbolType in [ustLABEL,ustNONE]) and not UserSymbolList[CodeSymbolIndex].IsExternal then begin
               UserSymbolList[CodeSymbolIndex].IsExternal:=false;
               UserSymbolList[CodeSymbolIndex].IsPublic:=true;
               if LastChar='=' then begin
                GetChar;
                SkipWhiteSpaceOnSameLine;
                if LastChar in ['''','"'] then begin
                 ReadString;
                 UserSymbolList[CodeSymbolIndex].OriginalName:=StringData;
                 SkipWhiteSpaceOnSameLine;
                end;
               end;
              end else begin
               MakeError(46);
              end;
             end else begin
              MakeError(14);
             end;
            end else begin
             MakeError(14);
            end;
            SkipWhiteSpaceOnSameLine;
            if LastChar=')' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
            end else begin
             MakeError('")" expected');
            end;
           end else begin
            MakeError('"(" expected');
           end;
          end;
          KeySTRUCT:begin
           SkipWhiteSpaceOnSameLine;
           if LastChar='(' then begin
            GetChar;
            SkipWhiteSpaceOnSameLine;
            if CheckAlpha then begin
             ReadSymbol;
             SkipWhiteSpaceOnSameLine;
             if LastChar=')' then begin
              GetChar;
              if (LastStruct<0) and (length(StructName)=0) then begin
               if SymbolType=stUSER then begin
                CodeSymbolIndex:=SymbolValue;
                Symbol:=UserSymbolList[CodeSymbolIndex];
                if SymbolNew or (Symbol.SymbolType=ustNONE) then begin
                 SkipWhiteSpaceOnSameLine;
                 Symbol.SymbolType:=ustSTRUCT;
                 LastStruct:=CodeSymbolIndex;
                 StructName:=SymbolName+'.';
                 StructSize:=0;
                 Code:=NewCode;
                 Code^.LineNumber:=LastCurrentLineNumber;
                 Code^.Column:=LastCurrentColumn;
                 Code^.Source:=CurrentSource;
                 Code^.CodeItemType:=tcitSTRUCTRESET;         
                 Code^.SymbolIndex:=LastStruct;
                 ParseStruct;
                 Symbol.Value.ValueType:=AVT_INT;
                 IntegerValueSetQWord(Symbol.Value.IntegerValue,StructSize);
                 LastStruct:=-1;
                 StructName:='';
                 StructSize:=0;
                end else begin
                 MakeError(17);
                end;
               end else begin
                MakeError(24);
               end;
              end else begin
               MakeError(24);
              end;
             end else begin
              MakeError(24);
             end;
            end else begin
             MakeError(24);
            end;
           end else begin
            MakeError(24);
           end;
          end;
          KeyOPTIMIZE:begin
           SkipWhiteSpaceOnSameLine;
           if LastChar='{' then begin
            GetChar;
            SkipWhiteSpaceOnSameLine;
            OldLastCode:=LastCode;
            ParserPass(false,true);
            DoOptimize(OldLastCode);
            if LastChar='}' then begin
             GetChar;
            end else begin
             MakeError(20);
            end;
           end else begin
            MakeError(20);
           end;
          end;
          KeyDEFAULT:begin
           SkipWhiteSpaceOnSameLine;
           if LastChar='(' then begin
            GetChar;
            SkipWhiteSpaceOnSameLine;
            while not (IsLineEnd or AreErrors) do begin
             SkipWhiteSpaceOnSameLine;
             if LastChar=')' then begin
              break;
             end else begin
              ReadAlpha;
              if SymbolName='REL' then begin
               Include(GlobalDefaults,GD_REL);
              end else if SymbolName='ABS' then begin
               Exclude(GlobalDefaults,GD_REL);
              end else if SymbolName='BND' then begin
               Include(GlobalDefaults,GD_BND);
              end else if SymbolName='NOBND' then begin
               Exclude(GlobalDefaults,GD_BND);
              end else begin
               MakeError('REL, ABS, BND or NOBND expected');
               break;
              end;
              SkipWhiteSpaceOnSameLine;
              if LastChar<>',' then begin
               break;
              end else begin
               GetChar;
              end;
             end;
            end;
            SkipWhiteSpaceOnSameLine;
            if LastChar=')' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
            end else begin
             MakeError('")" expected');
            end;
           end else begin
            MakeError('"(" expected');
           end;
          end;
          KeyOFFSET:begin
           SkipWhiteSpaceOnSameLine;
           if LastChar='(' then begin
            GetChar;
            SkipWhiteSpaceOnSameLine;
            Code:=NewCode;
            Code^.LineNumber:=LastCurrentLineNumber;
            Code^.Column:=LastCurrentColumn;
            Code^.Source:=CurrentSource;
            Code^.CodeItemType:=tcitOFFSET;
            Code^.Expression:=ReadExpression;
            SkipWhiteSpaceOnSameLine;
            if LastChar=')' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
            end else begin
             MakeError('")" expected');
            end;
           end else begin
            MakeError('"(" expected');
           end;
          end;
          KeyCPU:begin
           SkipWhiteSpaceOnSameLine;
           if LastChar='(' then begin
            GetChar;
            SkipWhiteSpaceOnSameLine;
            Code:=NewCode;
            Code^.LineNumber:=LastCurrentLineNumber;
            Code^.Column:=LastCurrentColumn;
            Code^.Source:=CurrentSource;
            Code^.CodeItemType:=tcitCPU;
            ReadAlphaOrNumber;
            if (SymbolName='8086') or (SymbolName='86') then begin
             Code^.Value:=IF_8086;
            end else if (SymbolName='80186') or (SymbolName='186') then begin
             Code^.Value:=IF_186;
            end else if (SymbolName='80286') or (SymbolName='286') then begin
             Code^.Value:=IF_286;
            end else if (SymbolName='80386') or (SymbolName='386') then begin
             Code^.Value:=IF_386;
            end else if (SymbolName='80386') or (SymbolName='486') then begin
             Code^.Value:=IF_486;
            end else if (SymbolName='80586') or (SymbolName='586') or (SymbolName='PENTIUM') then begin
             Code^.Value:=IF_PENT;
            end else if (SymbolName='80686') or (SymbolName='686') or (SymbolName='PENTIUM2') or (SymbolName='P2') or (SymbolName='PENTIUMPRO') or (SymbolName='PPRO') then begin
             Code^.Value:=IF_P6;
            end else if (SymbolName='KATMAI') or (SymbolName='PENTIUM3') or (SymbolName='P3') then begin
             Code^.Value:=IF_KATMAI;
            end else if (SymbolName='WILLAMETTE') or (SymbolName='PENTIUM4') or (SymbolName='P4') then begin
             Code^.Value:=IF_WILLAMETTE;
            end else if SymbolName='PRESCOTT' then begin
             Code^.Value:=IF_PRESCOTT;
            end else if (SymbolName='X86_64') or (SymbolName='X8664') or (SymbolName='X64') or (SymbolName='AMD64') then begin
             Code^.Value:=IF_X86_64;
            end else if SymbolName='NEHALEM' then begin
             Code^.Value:=IF_NEHALEM;
            end else if SymbolName='WESTMERE' then begin
             Code^.Value:=IF_WESTMERE;
            end else if SymbolName='SANDYBRIDGE' then begin
             Code^.Value:=IF_SANDYBRIDGE;
            end else if SymbolName='FUTURE' then begin
             Code^.Value:=IF_FUTURE;
            end else if (SymbolName='IA64') or (SymbolName='IA_64') or (SymbolName='ITANIUM') or (SymbolName='ITANIC') or (SymbolName='MERCED') or (SymbolName='ALL') then begin
             Code^.Value:=IF_IA64;
            end else begin
             MakeError('Unknown CPU level');
             Code^.Value:=IF_IA64;
            end;
            SkipWhiteSpaceOnSameLine;
            if LastChar=')' then begin
             GetChar;
             SkipWhiteSpaceOnSameLine;
            end else begin
             MakeError('")" expected');
            end;
           end else begin
            MakeError('"(" expected');
           end;
          end;
          else begin
           MakeError(7);
          end;
         end;
        end else begin
         MakeError(8);
        end;
       end else begin
        MakeError(8);
       end;
      end else if LastChar='{' then begin
       GetChar;
       SkipWhiteSpaceOnSameLine;
       ParserPass(false,true);
       if LastChar='}' then begin
        GetChar;
       end else begin
        MakeError(21);
       end;
      end else if IsGroup and (LastChar='}') then begin
       break;
      end else begin
       MakeError(70);
       GetChar;
      end;
      if OneInstruction then begin
       break;
      end;
      SkipWhiteSpaceOnSameLine;
      case LastChar of
       #0:begin
        // EOF
        break;
       end;
       #10,      // New line
       ';':begin // New statement
        GetChar;
       end;
       '}':begin
        if IsGroup then begin
         break;
        end else begin
         MakeError('"}" outside group');
        end;
       end;
       else begin
        MakeError('Line end expected');
       end;
      end;
     end;
    end;
   end;
  finally
{$ifdef SASMBESEN}
   SetLength(BESENPArguments,0);
   SetLength(BESENArguments,0);
{$endif}
  end;
 end;
 procedure CheckStartCode;
 begin
  if not (assigned(LastCode) or assigned(StartCode)) then begin
   StartCode:=NewCode;
   StartCode^.CodeItemType:=tcitStart;
  end;
 end;
 procedure CleanSource;
 var SourcePosition,SourceLength,InputSourceCodeLength:longint;
     TerminateChar:ansichar;
 begin
  InputSourceCode:=Source;
  InputSourceCodeLength:=0;
  SourcePosition:=1;
  SourceLength:=length(Source);
  if ((SourcePosition+2)<=SourceLength) and
     ((byte(ansichar(Source[SourcePosition+0]))=$ef) and
      (byte(ansichar(Source[SourcePosition+1]))=$bb) and
      (byte(ansichar(Source[SourcePosition+2]))=$bf)) then begin
   // Skip UTF8 BOM
   inc(SourcePosition,3);
  end;
  while SourcePosition<=SourceLength do begin
   case Source[SourcePosition] of
    #13:begin
     // Clean new lines
     inc(SourcePosition);
     if (SourcePosition<=SourceLength) and (Source[SourcePosition]<>#10) then begin
      inc(InputSourceCodeLength);
      InputSourceCode[InputSourceCodeLength]:=#10;
     end;
    end;
    '''','"':begin
     inc(InputSourceCodeLength);
     InputSourceCode[InputSourceCodeLength]:=Source[SourcePosition];
     TerminateChar:=Source[SourcePosition];
     inc(SourcePosition);
     while SourcePosition<=SourceLength do begin
      case Source[SourcePosition] of
       '''','"':begin
        inc(InputSourceCodeLength);
        InputSourceCode[InputSourceCodeLength]:=Source[SourcePosition];
        if Source[SourcePosition]=TerminateChar then begin
         inc(SourcePosition);
         break;
        end else begin
         inc(SourcePosition);
        end;
       end;
       '\':begin
        inc(InputSourceCodeLength);
        InputSourceCode[InputSourceCodeLength]:=Source[SourcePosition];
        inc(SourcePosition);
        if SourcePosition<=SourceLength then begin
         inc(InputSourceCodeLength);
         InputSourceCode[InputSourceCodeLength]:=Source[SourcePosition];
         inc(SourcePosition);
        end;
       end;
       else begin
        inc(InputSourceCodeLength);
        InputSourceCode[InputSourceCodeLength]:=Source[SourcePosition];
        inc(SourcePosition);
       end;
      end;
     end;
    end;
    '/':begin
     if ((SourcePosition+1)<=SourceLength) and (Source[SourcePosition+1] in ['/','*']) then begin
      inc(SourcePosition);
      case Source[SourcePosition] of
       '*':begin
        inc(SourcePosition);
        inc(InputSourceCodeLength);
        InputSourceCode[InputSourceCodeLength]:=#32;
        inc(InputSourceCodeLength);
        InputSourceCode[InputSourceCodeLength]:=#32;
        while SourcePosition<=SourceLength do begin
         case Source[SourcePosition] of
          #10:begin
           inc(SourcePosition);
           inc(InputSourceCodeLength);
           InputSourceCode[InputSourceCodeLength]:=#10;
          end;
          '*':begin
           inc(SourcePosition);
           inc(InputSourceCodeLength);
           InputSourceCode[InputSourceCodeLength]:=#32;
           if (SourcePosition<=SourceLength) and (Source[SourcePosition]='/') then begin
            inc(SourcePosition);
            inc(InputSourceCodeLength);
            InputSourceCode[InputSourceCodeLength]:=#32;
            break;
           end;
          end;
          else begin
           inc(SourcePosition);
           inc(InputSourceCodeLength);
           InputSourceCode[InputSourceCodeLength]:=#32;
          end;
         end;
        end;
       end;
       '/':begin
        inc(SourcePosition);
        while (SourcePosition<=SourceLength) and (Source[SourcePosition]<>#10) do begin
         inc(SourcePosition);
        end;
       end;
      end;
     end else begin
      inc(InputSourceCodeLength);
      InputSourceCode[InputSourceCodeLength]:=Source[SourcePosition];
      inc(SourcePosition);
     end;
    end;
    else begin
     inc(InputSourceCodeLength);
     InputSourceCode[InputSourceCodeLength]:=Source[SourcePosition];
     inc(SourcePosition);
    end;
   end;
  end;
  SetLength(InputSourceCode,InputSourceCodeLength);
  ParseStringIntoStringList(InputSourceCodeLines,InputSourceCode);
 end;
begin
 if (length(Source)>0) and not AreErrors then begin
  InputSourceCodeLines:=TStringList.Create;
  try
   FillChar(InputSourceCodeHistoryRingBuffer,SizeOf(InputSourceCodeHistoryRingBuffer),#0);
   InputSourceCodeHistoryRingBufferPosition:=0;
   ParsedChars:=0;
   CurrentIEEEFormat:=@IEEEFormat32;
   LastStruct:=-1;
   StructName:='';
   StructSize:=0;
   CheckStartCode;
   SymbolType:=stNONE;
   SymbolValue:=0;
   CleanSource;
   begin
    InputSourceCodeCountLines:=InputSourceCodeLines.Count;
    InputSourceCodeLineIndex:=0;
    if InputSourceCodeLineIndex<InputSourceCodeCountLines then begin
     InputSourceCodeLine:=InputSourceCodeLines[InputSourceCodeLineIndex];
    end else begin
     InputSourceCodeLine:='';
    end;
    PreprocessLine(InputSourceCodeLine);
    InputSourceCodeLineLength:=length(InputSourceCodeLine);
    InputSourceCodeLinePosition:=1;
   end;
   GetChar;
   AllowedKeywordKinds:=[];
   ParserPass(false,false);
   inc(CurrentLineNumber);
   CurrentColumn:=0;
   StructName:='';
  finally
   InputSourceCodeLines.Free;
  end;
 end;
end;
{$ifdef FPC}
 {$notes on}
{$endif}

procedure TAssembler.ParseDefines(Source:ansistring);
var OldCurrentLineNumber:longint;
    OldCurrentColumn:longint;
    OldCurrentSource:longint;
begin
 if length(Source)>0 then begin
  OldCurrentLineNumber:=CurrentLineNumber;
  OldCurrentColumn:=CurrentColumn;
  OldCurrentSource:=CurrentSource;
  CurrentLineNumber:=1;
  CurrentColumn:=0;
  CurrentSource:=SourceDefines;
  ParseString(Source);
  CurrentLineNumber:=OldCurrentLineNumber;
  CurrentColumn:=OldCurrentColumn;
  CurrentSource:=OldCurrentSource;
 end;
end;

procedure TAssembler.ParseStream(const Stream:TStream);
var s:ansistring;
    //OldPosition:int64;
begin
 s:='';
 try
  if assigned(Stream) and not AreErrors then begin
   SetLength(s,Stream.Size);
   if Stream.Size>0 then begin
    //OldPosition:=Stream.Position;
    Stream.Seek(0,soBeginning);
    Stream.Read(s[1],Stream.Size);
    ParseString(s);
   end;
  end;
 finally
  s:='';
 end;
end;

procedure TAssembler.ParseFile(FileName:ansistring);
var SymbolType:TSymbolTreeLinkType;
    SymbolValue:TSymbolTreeLink;
    Symbol:ansistring;
    OldCurrentFileName:ansistring;
    OldCurrentLineNumber:longint;
    OldCurrentColumn:longint;
    OldCurrentSource:longint;
begin
 if not AreErrors then begin
  Symbol:=UpperCase(FileName);
  if not FileSymbolTree.Find(Symbol,SymbolType,SymbolValue) then begin
   SymbolValue:=FileStringList.Add(FileName)+1;
   FileSymbolTree.Add(Symbol,stFILE,SymbolValue);
  end;
  OldCurrentFileName:=CurrentFileName;
  OldCurrentLineNumber:=CurrentLineNumber;
  OldCurrentColumn:=CurrentColumn;
  OldCurrentSource:=CurrentSource;
  CurrentFileName:=FileName;
  CurrentLineNumber:=1;
  CurrentColumn:=0;
  CurrentSource:=SymbolValue;
  ParseString(ReadFileAsString(FileName));
  CurrentFileName:=OldCurrentFileName;
  CurrentLineNumber:=OldCurrentLineNumber;
  CurrentColumn:=OldCurrentColumn;
  CurrentSource:=OldCurrentSource;
 end;
end;

procedure TAssembler.AddExternal(Name:ansistring;ExternalPointer:pointer);
var OldCurrentLineNumber:longint;
    OldCurrentColumn:longint;
    OldCurrentSource:longint;
    Source:ansistring;
begin
 Source:=Name+' dd '+inttostr(TSASMPtrInt(ExternalPointer))+#10+
         Name+'$var dd '+inttostr(TSASMPtrInt(ExternalPointer))+#10+
         Name+'$const equ '+inttostr(TSASMPtrInt(ExternalPointer))+#10;
 if length(Source)>0 then begin
  OldCurrentLineNumber:=CurrentLineNumber;
  OldCurrentColumn:=CurrentColumn;
  OldCurrentSource:=CurrentSource;
  CurrentLineNumber:=1;
  CurrentColumn:=0;
  CurrentSource:=SourceDefines;
  ParseString(Source);
  CurrentLineNumber:=OldCurrentLineNumber;
  CurrentColumn:=OldCurrentColumn;
  CurrentSource:=OldCurrentSource;
 end;
end;

function TAssembler.GetCodePointer:pointer;
begin
 result:=RuntimeCodeImage;
end;

function TAssembler.GetEntryPointPointer:pointer;
begin
 result:=RuntimeCodeImageEntryPoint;
end;

function TAssembler.GetLabelPointer(LabelName:ansistring):pointer;
var SymbolName:ansistring;
    SymbolType:TSymbolTreeLinkType;
    SymbolValue:TSymbolTreeLink;
    Symbol:TUserSymbol;
begin
 result:=nil;
 SymbolName:=LabelName;
 if UserSymbolTree.Find(SymbolName,SymbolType,SymbolValue) then begin
  if (SymbolValue>=0) and (SymbolValue<UserSymbolList.Count) then begin
   Symbol:=UserSymbolList[SymbolValue];
   if assigned(Symbol) and (Symbol.SymbolType=ustLABEL) then begin
    result:=pointer(TSASMPtrUInt(TSASMPtrUInt(RuntimeCodeImage)+TSASMPtrUInt(ValueGetInt64(self,Symbol.GetValue(self),false))));
   end;
  end;
 end;
end;

{var a,b:TIntegerValue;
initialization
 IntegerValueSetInt64(a,5);
 IntegerValueSetInt64(b,6);
 writeln(IntegerValueCompare(a,b));
 writeln(Sign(IntegerValueGetInt64(a)-IntegerValueGetInt64(b)));
 readln;
 halt(0);{}
end.



