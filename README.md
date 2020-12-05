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
 2. File Open `DesData.8xp`
 3. <kbd>MEM</kbd>, select Archive; <kbd>PRGM</kbd>, select DesData; <kbd>ENTER</kbd>
 4. File Open `Desolate.8xp`
 5. File Open `MIRAGEOS.8xk`
 6. <kbd>APPS</kbd> select MirageOS
 7. Select Main > Desolate


## Tools for the tools folder

 - `bas2tap.exe`, `bin2tap.exe`, `tap2tzx.exe` utilities
   https://sourceforge.net/projects/zxspectrumutils/files/

 - `pasmo.exe` cross-assembler
   http://pasmo.speccy.org/

 - `sjasmplus.exe`
   https://github.com/z00m128/sjasmplus/releases

 - `lzsa.exe`
   https://github.com/emmanuel-marty/lzsa/releases


## Links

 - [Discussion on zx-pk.ru (in Russian)](https://zx-pk.ru/threads/32431-desolate-port-s-ti-83-plus.html)
 - [Desolate port on Vector-06c](https://github.com/nzeemin/vector06c-desolate)

