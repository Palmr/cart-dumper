Memory Bank Controllers
=======================

Below is a list of MBC numbers against the cart type value found at $0147 and their description.
I used $EF for MBC types I don't plan to support and $FF for invalid type values.

```
$00,  00h - ROM Only 
$01,  01h - MBC1 
$01,  02h - MBC1 + RAM 
$01,  03h - MBC1 + RAM + Battery 
$FF,  04h - Unused 
$02,  05h - MBC2 
$02,  06h - MBC2 + RAM + Battery 
$FF,  07h - Unused 
$00,  08h - ROM + RAM 
$00,  09h - ROM + RAM + Battery 
$FF,  0Ah - Unused 
$EF,  0Bh - MMM01 
$EF,  0Ch - MMM01 + RAM 
$EF,  0Dh - MMM01 + RAM + Battery 
$FF,  0Eh - Unused 
$03,  0Fh - MBC3 + Timer + Battery ... - Unused
$03,  10h - MBC3 + RAM + Timer + Battery 
$03,  11h - MBC3 
$03,  12h - MBC3 + RAM 
$03,  13h - MBC3 + RAM + Battery 
$FF,  14h - Unused
$FF,  15h - Unused
$FF,  16h - Unused
$FF,  17h - Unused
$FF,  18h - Unused
$05,  19h - MBC5
$05,  1Ah - MBC5 + RAM
$05,  1Bh - MBC5 + RAM + Battery
$05,  1Ch - MBC5 + Rumble
$05,  1Dh - MBC5 + RAM + Rumble
$05,  1Eh - MBC5 + RAM + Battery + Rumble
$FF,  1Fh - Unused
$06,  20h - MBC6 + RAM + Battery
$FF,  21h - Unused
$07,  22h - MBC7 + RAM + Bat. + Accelerometer
```

ROM Size
========

Header value $0148 is the ROM size, I might show the human-readable value in the future but currently I'm going to focus on using it to find the number of banks that will need dumping.

```
00h - 32KB - 2 banks
01h - 64KB - 4 banks
02h - 128KB - 8 banks
03h - 256KB - 16 banks
04h - 512KB - 32 banks
05h - 1MB - 64 banks
06h - 2MB - 128 banks
07h - 4MB - 256 banks
08h - 8MB - 512 banks
```

RAM Size
========

Header value $0149 is the RAM size. I plan to add RAM dumping later so this information is currently just here to save me a trip to a PDF at some point...

```
00h - None
01h - 2KB
02h - 8KB - 1 bank
03h - 32KB - 4 banks of 8KB
04h - 128KB - 16 banks of 8KB
05h - 64KB - 8 banks of 8 KB
```
