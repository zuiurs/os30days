QEMU		= qemu-system-i386

BUILD_DIR	= build
IMG			= $(BUILD_DIR)/os.img
IPL			= $(BUILD_DIR)/ipl.bin
SYS			= $(BUILD_DIR)/os.sys

IPL_SRC		= ipl.s
IPL_LD		= ipl.ld
HEAD_SRC	= asmhead.s
HEAD_LD		= asmhead.ld

BOOTPACK	= bootpack.c

all: $(BUILD_DIR) $(IMG)

$(BUILD_DIR):
	mkdir $(BUILD_DIR)

$(IMG): $(IPL) $(SYS)
	mformat -f 1440 -C -B $(IPL) -i $@ ::
	mcopy $(SYS) -i $@ ::

$(SYS): $(HEAD_SRC) $(BOOTPACK)
	gcc $(HEAD_SRC) -nostdlib -T$(HEAD_LD) -o $(BUILD_DIR)/head.bin
	gcc $(BOOTPACK) -nostdlib -c -o $(BUILD_DIR)/boot.o
	ld -o $(BUILD_DIR)/boot.bin -e main --oformat=binary $(BUILD_DIR)/boot.o
	cat $(BUILD_DIR)/head.bin $(BUILD_DIR)/boot.bin > $@

$(IPL): $(IPL_SRC) $(IPL_LD)
	gcc $(IPL_SRC) -nostdlib -T$(IPL_LD) -o $@

run: $(IMG)
	$(QEMU) -m 32 -localtime -vga std -fda $(IMG)

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all run clean
