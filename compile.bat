..\Rom-Development\rgbds-0.2.4\rgbasm -omain.obj main.asm
..\Rom-Development\rgbds-0.2.4\rgblink -mcart-dumper.map -ncart-dumper.sym -ocart-dumper.gb main.obj
..\Rom-Development\rgbds-0.2.4\rgbfix -v cart-dumper.gb
