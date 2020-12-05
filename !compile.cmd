@echo off
if exist desolcode.bin del desolcode.bin
if exist desolcode.txt del desolcode.txt
if exist desolcode.sjbin del desolcode.sjbin
if exist desolcode.sjsym del desolcode.sjsym

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

tools\pasmo --tap --name SCREEN loading.asm loading.tap
@if errorlevel 1 goto Failed
tools\pasmo --tap desolcoda.asm desolcode.tap
@if errorlevel 1 goto Failed
copy /B /Y basloader.tap+loading.tap+desolcode.tap desolate.tap
@if errorlevel 1 goto Failed
tools\tap2tzx desolate.tap desolate.tzx
@if errorlevel 1 goto Failed

dir /-c desolate.t*|findstr /R /C:"desolate."

echo %ESCchar%[92mSUCCESS%ESCchar%[0m
exit

:Failed
@echo off
echo %ESCchar%[91mFAILED%ESCchar%[0m
exit /b
