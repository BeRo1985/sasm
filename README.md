# SASM

SASM (Scriptable ASseMbler) is a x86 assembler with ECMAScript as (additional) macro language as an optional compile-in-option 

# Features

- Support for x86-16, x86-32 and x86-64 targets 
  - since 2015, it's based on the opcode tables from the NASM project, before 2015, the whole x86 ISA code generation was hardcoded 
- Supported output formats: 
  - BIN 
  - COM 
  - MZEXE 
  - PE32 
  - PE32+/PE64 
  - ELF32 (Work in progress, existent, but still bit buggy) 
  - ELFX32 (Work in progress, existent, but still bit buggy) 
  - ELF64 (Work in progress, existent, but still bit buggy) 
  - COFF32 
  - COFF64 
  - OMF16 (Work in progress, non-existent/only-stub) 
  - OMF32 (Work in progress, non-existent/only-stub) 
  - TRI32 (TRI = Tiny Runtime Image, a simple object in-memory file format, designed for usage in just-in-time compilers and so on)
  - TRI64 (TRI = Tiny Runtime Image, a simple object in-memory file format, designed for usage in just-in-time compilers and so on)
  - and of course RUNTIME, where the assembled code can run directly after the assemblation, so it's also a runtime x86 assembler.
- 1024-bit big integer parsing and arithmetics
- Floating point number literal parsing up to inoffical 512 bit FP data formats.
- And many more features . . . 

# Requirements

- Delphi or FreePascal as compiler for to compile SASM itself
- PUCU.pas from https://github.com/BeRo1985/pucu for unicode handling stuff
- Optional together with SASMBESEN as define: BESEN*.pas from https://github.com/BeRo1985/besen 

# License

zlib, otherwise see beginning comment of https://github.com/BeRo1985/sasm/blob/master/src/SASM.inc

# General guidelines for code contributors

See beginning comment of https://github.com/BeRo1985/sasm/blob/master/src/SASM.inc
