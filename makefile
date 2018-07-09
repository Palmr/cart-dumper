SRC := src
BUILD := build
RGBASM := rgbasm
RGBLINK := rgblink
RGBFIX := rgbfix

NAME := cart-dumper
TARGET := $(BUILD)/$(NAME).gb
MAPFILE := $(BUILD)/$(NAME).map
SYMFILE := $(BUILD)/$(NAME).sym

SOURCES := $(wildcard $(SRC)/*.asm)
OBJECTS := $(foreach src,$(SOURCES),$(patsubst $(SRC)/%,$(BUILD)/%.o,$(src)))

all: $(TARGET)
$(BUILD)/%.asm.o: $(SRC)/%.asm
	@mkdir -p $(BUILD)
	$(RGBASM) -i $(SRC)/ -i $(BUILD)/ -o $@ $<

$(TARGET): $(OBJECTS)
	$(RGBLINK) -o $(TARGET) -m $(MAPFILE) -n $(SYMFILE) $(OBJECTS)
	$(RGBFIX) -C -v -m 0 -r 0 -p 0 -t $(NAME) $(TARGET)

clean:
	rm -f $(OBJECTS)
	rm -f $(TARGET)
	rm -f $(MAPFILE)
	rm -f $(SYMFILE)
