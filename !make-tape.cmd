bin\pasmo --tap --name SCREEN loading.asm loading.tap
bin\pasmo --tap desolcoda.asm desolcode.tap
copy /B /Y basloader.tap+loading.tap+desolcode.tap desolate.tap
bin\tap2tzx desolate.tap desolate.tzx
