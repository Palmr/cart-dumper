all: cart-dumper

cart-dumper:
	rgbasm -omain.obj main.asm
	rgblink -mcart-dumper.map -ncart-dumper.sym -ocart-dumper.gb main.obj
	rgbfix -v cart-dumper.gb

clean:
	rm -f *.gb *.map *.sym *.obj
