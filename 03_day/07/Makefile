QEMU		= qemu-system-i386

BUILD_DIR	= build
IMG			= $(BUILD_DIR)/os.img
IPL			= $(BUILD_DIR)/ipl.bin
SYS			= $(BUILD_DIR)/os.sys

SRC			= ipl.s
LD			= ipl.ld
MAINSYS		= haribote.s
MAINLD		= haribote.ld

all: $(BUILD_DIR) $(IMG)

$(BUILD_DIR):
	mkdir $(BUILD_DIR)

$(IMG): $(IPL) $(SYS)
	mformat -f 1440 -C -B $(IPL) -i $@ ::
	mcopy $(SYS) -i $(IMG) ::

$(SYS): $(MAINSYS)
	#as $(MAINSYS) -o $(SYS)
	gcc $(MAINSYS) -nostdlib -T$(MAINLD) -o $@

$(IPL): $(SRC) $(LD)
	gcc $(SRC) -nostdlib -T$(LD) -o $@

run: $(IMG)
	$(QEMU) -m 32 -localtime -vga std -fda $(IMG)

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all run clean
