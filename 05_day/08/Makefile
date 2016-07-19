QEMU		= qemu-system-i386

BUILD_DIR	= build
IMG			= $(BUILD_DIR)/os.img
IPL			= $(BUILD_DIR)/ipl.bin
SYS			= $(BUILD_DIR)/os.sys
MKFONT		= $(BUILD_DIR)/mkfont

IPL_SRC		= ipl.s
IPL_LD		= ipl.ld
HEAD_SRC	= asmhead.s
HEAD_LD		= asmhead.ld

GASFUNC		= gasfunc.s

BOOTPACK_SRC= bootpack.c
BOOTPACK_LD	= bootpack.ld

FONT		= fonts.txt
FONT_C		= $(BUILD_DIR)/fonts.c
MKFONT_SRC	= mkfont/main.go

all: $(BUILD_DIR) $(IMG)

$(BUILD_DIR):
	mkdir $(BUILD_DIR)

$(IMG): $(IPL) $(SYS)
	mformat -f 1440 -C -B $(IPL) -i $@ ::
	mcopy $(SYS) -i $@ ::

$(SYS): $(HEAD_SRC) $(BOOTPACK_SRC) $(FONT_C)
	gcc $(HEAD_SRC) -m32 -nostdlib -T$(HEAD_LD) -o $(BUILD_DIR)/head.bin
	gcc $(BOOTPACK_SRC) -m32 -nostdlib -Wl,--oformat=binary -c -o $(BUILD_DIR)/boot.o
	gcc $(FONT_C) -m32 -nostdlib -Wl,--oformat=binary -c -o $(BUILD_DIR)/fonts.o
	as $(GASFUNC) --32 -o $(BUILD_DIR)/gasfunc.o
	ld -o $(BUILD_DIR)/boot.bin -e main -melf_i386 --script=$(BOOTPACK_LD) $(BUILD_DIR)/boot.o $(BUILD_DIR)/fonts.o $(BUILD_DIR)/gasfunc.o
	cat $(BUILD_DIR)/head.bin $(BUILD_DIR)/boot.bin > $@
	# You must compile in 32-bit, because the qemu is i386 environment!!

$(IPL): $(IPL_SRC) $(IPL_LD)
	gcc $(IPL_SRC) -nostdlib -T$(IPL_LD) -o $@

$(FONT_C): $(FONT) $(MKFONT)
	$(MKFONT) -o $@ $(FONT)

$(MKFONT): $(MKFONT_SRC)
	go build -o $@ $(MKFONT_SRC)

font: $(MKFONT_SRC)
	make $(MKFONT)

run: $(BUILD_DIR) $(IMG)
	$(QEMU) -m 32 -localtime -vga std -fda $(IMG)

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all run clean font
