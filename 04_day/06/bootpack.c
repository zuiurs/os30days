/* gasfunc.c */
void io_hlt(void);
void io_cli(void);
void io_out8(int port, int data);
int io_load_eflags(void);
void io_store_eflags(int eflags);

/* local function */
void init_palette(void);
void set_palette(int start, int end, unsigned char *rgb);

void main(void)
{
	int i;
	char* p = (char *) 0xA0000;

	init_palette();

	for (i = 0; i <= 0xFFFF; i ++) {
		p[i] = i & 0x0F;
	}

	for (;;) {
		io_hlt();
	}
}

void init_palette(void)
{
	/* "static char" equals DB instruction in asm */
	unsigned char table_rgb[16 * 3] = {
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
