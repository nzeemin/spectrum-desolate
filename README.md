# spectrum-desolate
Porting **Desolate** game from TI-83 Plus calculator to ZX Spectrum.

Status: work in progress.

![](screenshot/port-room1.png)


## The original game

Written by Patrick Prendergast (tr1p1ea) for TI-83/TI-84 calculators.

![](screenshot/original-room1.png)

Links:
 - [Desolate game description and files](https://www.ticalc.org/archives/files/fileinfo/348/34879.html)
 - [Wabbit emulator site](http://wabbitemu.org/) and [GitHub](https://github.com/sputt/wabbitemu)

To run the game on Wabbitemu emulator:
 1. Run Wabbitemu, select ROM file
 2. File Open DesData.8xp
 3. MEM, select Archive; PRGM, select DesData; ENTER
 4. File Open Desolate.8xp
 5. File Open MIRAGEOS.8xk
 6. APPS select MirageOS
 7. Select Main > Desolate


## Tools for the bin folder

 - `bas2tap.exe` and `tap2tzx.exe` utilities
   https://sourceforge.net/projects/zxspectrumutils/files/

 - `pasmo.exe` cross-assembler
   http://pasmo.speccy.org/

 - `sjasmplus.exe`
   https://github.com/z00m128/sjasmplus/releases

