QEMU		= qemu-system-i386

BUILD_DIR	= build
IMG			= $(BUILD_DIR)/os.img
IPL			= $(BUILD_DIR)/ipl.bin

SRC			= ipl.s
LD			= ipl.ld

all: $(BUILD_DIR) $(IMG)

$(BUILD_DIR):
	mkdir $(BUILD_DIR)

$(IMG): $(IPL)
	mformat -f 1440 -C -B $(IPL) -i $@ ::

$(IPL): $(SRC) $(LD)
	gcc $(SRC) -nostdlib -T$(LD) -o $@

run: $(IMG)
	$(QEMU) -m 32 -localtime -vga std -fda $(IMG)

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all run clean
