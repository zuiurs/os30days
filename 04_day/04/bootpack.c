void io_hlt(void);

void main(void)
{
	int i;
	char* p = (char *) 0xA0000;

	for (i = 0; i <= 0xFFFF; i ++) {
		*(p + i) = i & 0x0F;
	}

	for (;;) {
		io_hlt();
	}
}
