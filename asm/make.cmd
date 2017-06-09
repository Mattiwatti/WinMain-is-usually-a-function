@echo off

set VSVARS32=C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\VC\Auxiliary\Build\vcvars32.bat
set VSVARS64=C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\VC\Auxiliary\Build\vcvars64.bat
set NASMDIR=C:\Nasm

setlocal
set OLDPATH=%PATH%

rd /S /Q obj32 1>nul 2>&1
rd /S /Q obj64 1>nul 2>&1
rd /S /Q bin32 1>nul 2>&1
rd /S /Q bin64 1>nul 2>&1
mkdir obj32 1>nul 2>&1
mkdir obj64 1>nul 2>&1
mkdir bin32 1>nul 2>&1
mkdir bin64 1>nul 2>&1

:: 32 bit. Note: /DYNAMICBASE:NO is used to avoid a reloc directory (which can't go in the same .text section as main)
call "%VSVARS32%" 1>nul
set PATH=%NASMDIR%;%PATH%

nasm -fwin32 -DWINDOWS -D_WINDOWS -Worphan-labels -o obj32/main.obj main32.asm
link /nologo /OUT:"bin32\WinMain.exe" /MANIFEST:NO /NXCOMPAT /NOCOFFGRPINFO /DYNAMICBASE:NO /RELEASE /VERSION:"5.01" /MACHINE:X86 /SAFESEH /INCREMENTAL:NO /OPT:REF /OPT:ICF /SUBSYSTEM:WINDOWS",5.01" "obj32\main.obj" /NODEFAULTLIB

:: 64 bit
set PATH=%OLDPATH%
call "%VSVARS64%" 1>nul
set PATH=%NASMDIR%;%PATH%

nasm -fwin64 -DWINDOWS -D_WINDOWS -Worphan-labels -o obj64/main.obj main64.asm
link /nologo /OUT:"bin64\WinMain.exe" /MANIFEST:NO /NXCOMPAT /NOCOFFGRPINFO /DYNAMICBASE /RELEASE /VERSION:"5.02" /MACHINE:X64 /INCREMENTAL:NO /OPT:REF /OPT:ICF /SUBSYSTEM:WINDOWS",5.02" "obj64\main.obj" /NODEFAULTLIB

set PATH=%OLDPATH%
endlocal
pause
