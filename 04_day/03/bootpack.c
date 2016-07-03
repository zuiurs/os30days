void io_hlt(void);

void main(void)
{
	int i;
	/* char* p; */

	for (i = 0xA0000; i <= 0xAFFFF; i ++) {
		/* write byte directly */
		/*
		p = (char *) i;
		*p = i & 0x0F;
		*/

		*((char *) i) = i & 0x0F;
	}

	for (;;) {
		io_hlt();
	}
}
