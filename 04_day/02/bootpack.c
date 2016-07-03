void io_hlt(void);
void write_mem8(int addr, int data);

void main(void)
{
	int i;

	for (i = 0xA0000; i <= 0xAFFFF; i ++) {
		write_mem8(i, i & 0x0F);
	}

	for (;;) {
		io_hlt();
	}
}
