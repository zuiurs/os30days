void io_hlt(void);
void write_mem8(int addr, int data);

void main(void)
{
	int i;

	for (i = 0xA0000; i <= 0xAFFFF; i ++) {
		/* cyan */
		write_mem8(i, 11);	/* movl $15, (i) */
	}

	for (;;) {
		io_hlt();
	}
}
