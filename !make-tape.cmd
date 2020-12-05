tools\pasmo --tap --name SCREEN loading.asm loading.tap
tools\pasmo --tap desolcoda.asm desolcode.tap
copy /B /Y basloader.tap+loading.tap+desolcode.tap desolate.tap
tools\tap2tzx desolate.tap desolate.tzx
