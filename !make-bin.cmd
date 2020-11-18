@echo off
if exist desolcode.bin del desolcode.bin
if exist desolcode.txt del desolcode.txt

rem Define ESCchar to use in ANSI escape sequences
rem https://stackoverflow.com/questions/2048509/how-to-echo-with-different-colors-in-the-windows-command-line
for /F "delims=#" %%E in ('"prompt #$E# & for %%E in (1) do rem"') do set "ESCchar=%%E"

@echo on
bin\pasmo desolcoda.asm desolcode.bin desolate.txt
@if errorlevel 1 (
  echo %ESCchar%[91mFAILED%ESCchar%[0m
  exit /b
)
@echo off

findstr /B "Desolate" desolate.txt

dir /-c desolcode.bin|findstr /R /C:"desolcode"

echo %ESCchar%[92mSUCCESS%ESCchar%[0m
