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
void putfonts8_asc(char *vram, int xsize, int x, int y, char c, unsigned char *s);
int lsprintf(char *str, const char *fmt, ...);
void strcls(char *str);
int getDecimalDigit(int num, int digit);
void dec2str(char *s, int num);

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

	putfonts8_asc(binfo->vram, binfo->scrnx,  8,  8, WHITE, "#$%&'()*+,-./0123:;<=>");
	putfonts8_asc(binfo->vram, binfo->scrnx, 31, 31, BLACK, "Haribote OS");
	putfonts8_asc(binfo->vram, binfo->scrnx, 30, 30, WHITE, "Haribote OS");
	char s[20];
	lsprintf(s, "scrnx = %d", binfo->scrnx);
	putfonts8_asc(binfo->vram, binfo->scrnx, 16, 64, WHITE, s);
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

void putfonts8_asc(char *vram, int xsize, int x, int y, char c, unsigned char *s)
{
	for (; *s != 0x00; s++) {
		putfont8(vram, xsize, x, y, c, fonts + *s * 16);
		x += 8;
	}
	return;
}

/**
 * Light-Sprintf
 */
int lsprintf(char *str, const char *fmt, ...)
{
	int *arg = (int *)(&str + 2);	/* Variable-length arguments */
	/* Stack Frame: <Type> <Func>(arg1, arg2, arg3, ...);
	 * -------------------------------------------------
	 * %esp					:arg1
	 * %esp + 1*<TypeLength>:arg2
	 * %esp + 2*<TypeLength>:arg3
	 * -------------------------------------------------
	 */
	int cnt;			/* number of generated characters */
	int argc = 0;		/* number of argmuments */
	int i;				/* counter */
	char buf[20];		/* buffer for converting value */

	strcls(str);	/* initialize memory */
	strcls(buf);	/* initialize buffer */
	for(cnt = 0; *fmt != '\0'; fmt++) {
		switch (*fmt) {
		case '%':
			/* convert along the format */
			switch (fmt[1]) {
				case 'd': dec2str(buf, arg[argc++]); break;
			}
			/* copy converted value from buffer to str */
			for (i = 0; buf[i] != '\0'; i++, cnt++) {
				*str++ = buf[i];
			}
			fmt++;
			break;
		case '\\':
			break;
		default:
			*str++ = *fmt;
			cnt ++;
		}	
	}
	return cnt;
}

/* fill with null */
void strcls(char *str)
{
	while(*str != '\0') *str++ = '\0';
}

int getDecimalDigit(int num, int digit)
{
	if (digit == 0) {
		return 0;
	}

	int i;
	for (i = 0; i < digit-1; i ++) {
		num /= 10;
	}

	return num % 10;
}

void dec2str(char *s, int num)
{
	int p_idx = 0;
	int digit_limit = 10;

	/* case: zero */
	if (num == 0) {
		s[0] = '0';
		s[1] = '\0';
		return;
	}

	/* case: minus */
	if (num < 0) {
		s[0] = '-';
		p_idx ++;

		num = -num;
	}

	int digit;
	int isRec = 0;
	for (digit = digit_limit; digit > 0; digit --) {
		int d = getDecimalDigit(num, digit);
		if (d != 0) {
			isRec = 1;
		}

		if (isRec) {
			s[p_idx] = '0' + d;
			p_idx ++;
		}
	}

	s[p_idx] = '\0';
	return; 
}
