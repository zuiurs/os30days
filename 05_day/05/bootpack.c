/* gasfunc.c */
void io_hlt(void);
void io_cli(void);
void io_out8(int port, int data);
int io_load_eflags(void);
void io_store_eflags(int eflags);

/* local function */
void init_screen(char* vram, int x, int y);
void init_palette(void);
void set_palette(int start, int end, unsigned char *rgb);
void boxfill8(unsigned char *vram, int xsize, unsigned char c, int x0, int y0, int x1, int y1);
void putfont8(char *vram, int xsize, int x, int y, char c, char *font);

/* extern data */
extern char fonts[4096];

#define BLACK		0
#define L_RED		1
#define L_GREEN		2
#define L_YELLOW	3
#define L_BLUE		4
#define L_PURPLE	5
#define L_CYAN		6
#define WHITE		7
#define L_GRAY		8
#define D_RED		9
#define D_GREEN		10
#define D_YELLOW	11
#define D_BLUE		12
#define D_PURPLE	13
#define D_CYAN		14
#define D_GRAY		15

struct BOOTINFO {
	char cyls, leds, vmode, reserve;
	short scrnx, scrny;
	char *vram;
};

void main(void)
{
	struct BOOTINFO *binfo = (struct BOOTINFO *) 0x0FF0;

	init_palette();

	init_screen(binfo -> vram,
			    binfo -> scrnx,
				binfo -> scrny);

	putfont8(binfo->vram, binfo->scrnx,  8, 8, WHITE, fonts + 'A' * 16);
	putfont8(binfo->vram, binfo->scrnx, 16, 8, WHITE, fonts + 'B' * 16);
	putfont8(binfo->vram, binfo->scrnx, 24, 8, WHITE, fonts + 'C' * 16);
	putfont8(binfo->vram, binfo->scrnx, 40, 8, WHITE, fonts + '1' * 16);
	putfont8(binfo->vram, binfo->scrnx, 48, 8, WHITE, fonts + '2' * 16);
	putfont8(binfo->vram, binfo->scrnx, 56, 8, WHITE, fonts + '3' * 16);

	for (;;) {
		io_hlt();
	}
}

void init_screen(char* vram, int x, int y)
{
	boxfill8(vram, x, D_CYAN,      0,      0, x -  1, y - 29);
	boxfill8(vram, x, L_GRAY,      0, y - 28, x -  1, y - 28);
	boxfill8(vram, x,  WHITE,      0, y - 27, x -  1, y - 27);
	boxfill8(vram, x, L_GRAY,      0, y - 26, x -  1, y -  1);

	boxfill8(vram, x,  WHITE,      3, y - 24,     59, y - 24);
	boxfill8(vram, x,  WHITE,      2, y - 24,      2, y -  4);
	boxfill8(vram, x, D_GRAY,      3, y -  4,     59, y -  4);
	boxfill8(vram, x, D_GRAY,     59, y - 23,     59, y -  5);
	boxfill8(vram, x,  BLACK,      2, y -  3,     59, y -  3);
	boxfill8(vram, x,  BLACK,     60, y - 24,     60, y -  3);

	boxfill8(vram, x, D_GRAY, x - 47, y - 24, x -  4, y - 24);
	boxfill8(vram, x, D_GRAY, x - 47, y - 23, x - 47, y -  4);
	boxfill8(vram, x,  WHITE, x - 47, y -  3, x -  4, y -  3);
	boxfill8(vram, x,  WHITE, x -  3, y - 24, x -  3, y -  3);

	return;
}

void boxfill8(unsigned char *vram, int xsize, unsigned char c, int x0, int y0, int x1, int y1)
{
	int x, y;
	for (y = y0; y <= y1; y++) {
		for (x = x0; x <= x1; x++)
			vram[y * xsize + x] = c;
	}
	return;
}

void init_palette(void)
{
	/* "static char" equals DB instruction in asm */
	static unsigned char table_rgb[16 * 3] = {
		0x00, 0x00, 0x00,	/*  0: black */
		0xff, 0x00, 0x00,	/*  1: light red */
		0x00, 0xff, 0x00,	/*  2: light green */
		0xff, 0xff, 0x00,	/*  3: light yellow */
		0x00, 0x00, 0xff,	/*  4: light blue */
		0xff, 0x00, 0xff,	/*  5: light purple */
		0x00, 0xff, 0xff,	/*  6: light cyan */
		0xff, 0xff, 0xff,	/*  7: white */
		0xc6, 0xc6, 0xc6,	/*  8: light gray */
		0x84, 0x00, 0x00,	/*  9: dark red */
		0x00, 0x84, 0x00,	/* 10: dark green */
		0x84, 0x84, 0x00,	/* 11: dark yellow */
		0x00, 0x00, 0x84,	/* 12: dark blue */
		0x84, 0x00, 0x84,	/* 13: dark purple */
		0x00, 0x84, 0x84,	/* 14: dark cyan */
		0x84, 0x84, 0x84	/* 15: dark gray */
	};
	set_palette(0, 15, table_rgb);
	return;
}

void set_palette(int start, int end, unsigned char *rgb)
{
	int i, eflags;
	eflags = io_load_eflags();	/* Store interrupt acception flag */
	io_cli(); 					/* Prohibit interruption (flag = 0) */
	io_out8(0x03c8, start);
	for (i = start; i <= end; i++) {
		io_out8(0x03c9, rgb[0] / 4);
		io_out8(0x03c9, rgb[1] / 4);
		io_out8(0x03c9, rgb[2] / 4);
		rgb += 3;
	}
	/* 
	 * Set Pallet
	 *	write port of 0x03c8 pallet number which you would like set.
	 *	write port of 0x03c9 value of R -> G -> B.
	 *	If you set next pallet, you needn't write pallet number.
	 * Read Pallet
	 *	write port of 0x03c7 pallet number
	 *	read port of 0x03c9 value 3 times. (R -> G -> B)
	 *	If you read next pallet, you needn't write pallet number.
	 */
	io_store_eflags(eflags);	/* Restore interrupt acception flag */
	return;
}

/**
 * Display font data
 *
 * *vram:	address of vram buffer
 * xsize:	size of horizontal screen
 * x:		offset x
 * y:		offset y
 * c:		color number
 * *font:	address of font data
 */
void putfont8(char *vram, int xsize, int x, int y, char c, char *font)
{
	int i;
	char *p, d /* data */;
	for (i = 0; i < 16; i++) {
		p = vram + (y + i) * xsize + x;
		d = font[i];
		if ((d & 0x80) != 0) { p[0] = c; }
		if ((d & 0x40) != 0) { p[1] = c; }
		if ((d & 0x20) != 0) { p[2] = c; }
		if ((d & 0x10) != 0) { p[3] = c; }
		if ((d & 0x08) != 0) { p[4] = c; }
		if ((d & 0x04) != 0) { p[5] = c; }
		if ((d & 0x02) != 0) { p[6] = c; }
		if ((d & 0x01) != 0) { p[7] = c; }
	}
	return;
}
