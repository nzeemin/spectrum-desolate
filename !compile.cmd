@echo off
if exist desolcod0.bin del desolcod0.bin
if exist desolcode.bin del desolcode.bin
if exist desolcode.txt del desolcode.txt
if exist desolcode.sjbin del desolcode.sjbin
if exist desolcode.sjsym del desolcode.sjsym
if exist desolcode.lzsa del desolcode.lzsa
if exist desolcod0.bin del desolcod0.bin
if exist basloader.tap del basloader.tap
if exist loading.tap del loading.tap
if exist desolcod0.tap del desolcod0.tap
if exist desolate.tap del desolate.tap
if exist desolate.tzx del desolate.tzx

rem Define ESCchar to use in ANSI escape sequences
rem https://stackoverflow.com/questions/2048509/how-to-echo-with-different-colors-in-the-windows-command-line
for /F "delims=#" %%E in ('"prompt #$E# & for %%E in (1) do rem"') do set "ESCchar=%%E"

@echo on
tools\bas2tap.exe -a10 basloader.bas basloader.tap
@if errorlevel 1 goto Failed
@echo off

@echo on
tools\pasmo desolcoda.asm desolcode.bin desolcode.txt
@if errorlevel 1 goto Failed
@echo off

findstr /B "Desolate" desolcode.txt

dir /-c desolcode.bin|findstr /R /C:"desolcode"

@echo on
tools\sjasmplus --raw=desolcode.sjbin --sym=desolcode.sjsym --syntax=f desolcode.sjasm
@if errorlevel 1 goto Failed
@echo off

findstr /B "Desolate" desolcode.sjsym

dir /-c desolcode.sjbin|findstr /R /C:"desolcode"

@echo on
tools\lzsa.exe -f1 -r -c desolcode.bin desolcode.lzsa
@if errorlevel 1 goto Failed
@echo off

dir /-c desolcode.lzsa|findstr /R /C:"desolcode"

@echo on
tools\pasmo desolcod0.asm desolcod0.bin
@if errorlevel 1 goto Failed
@echo off

dir /-c desolcod0.bin|findstr /R /C:"desolcod0.bin"

tools\pasmo --tap --name SCREEN loading.asm loading.tap
@if errorlevel 1 goto Failed

tools\bin2tap desolcod0.bin -o desolcod0.tap -a 45817
@if errorlevel 1 goto Failed

@echo on
copy /B /Y basloader.tap+loading.tap+desolcod0.tap desolate.tap
@if errorlevel 1 goto Failed
tools\tap2tzx desolate.tap desolate.tzx
@if errorlevel 1 goto Failed
@echo off

dir /-c desolate.t*|findstr /R /C:"desolate."

echo %ESCchar%[92mSUCCESS%ESCchar%[0m
exit

:Failed
@echo off
echo %ESCchar%[91mFAILED%ESCchar%[0m
exit /b
