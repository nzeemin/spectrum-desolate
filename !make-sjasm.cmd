@echo off
if exist desolcode.sjbin del desolcode.sjbin
if exist desolcode.sjsym del desolcode.sjsym

rem Define ESCchar to use in ANSI escape sequences
rem https://stackoverflow.com/questions/2048509/how-to-echo-with-different-colors-in-the-windows-command-line
for /F "delims=#" %%E in ('"prompt #$E# & for %%E in (1) do rem"') do set "ESCchar=%%E"

@echo on
bin\sjasmplus --raw=desolate.sjbin --sym=desolate.sjsym --syntax=f desolcode.sjasm
@if errorlevel 1 (
  echo %ESCchar%[91mFAILED%ESCchar%[0m
  exit /b
)
@echo off

findstr /B "Desolate" desolate.sjsym

dir /-c desolate.sjbin|findstr /R /C:"desolate"

echo %ESCchar%[92mSUCCESS%ESCchar%[0m
