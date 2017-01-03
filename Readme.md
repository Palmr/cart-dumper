# Gameboy Cartridge Dumper

This is a rom that loads its main loop into ram on the Gameboy, lets you swap cartridges and then will dump the contents of that cartridge by means I'm yet to decide... Comm port, printer, screen hex display or QR codes on screen?

Currently tested using an EMS 64M flashcart and both a Gameboy pocket and Gameboy Color.

## To build

Get [RGBDS (Rednex Game Boy Development System)](https://github.com/bentley/rgbds) and change the paths in ./compile.bat to point to the RGBDS executables. The compile batch file assembles, links and fixes creating a cart-dumper.gb file to use.

## To use

Copy the cart-dumper.gb rom to a flash-cart, run it on a Gameboy, carefully remove the flashcart once it's running, carefully (slowly, sometimes going too fast will reboot the Gameboy) put a new cartridge in and then wait for the cartridge title to be shown on screen.

The actual dumping part is yet to be written...
