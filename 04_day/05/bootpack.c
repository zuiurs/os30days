void io_hlt(void);

void main(void)
{
	int i;
	char* p = (char *) 0xA0000;

	for (i = 0; i <= 0xFFFF; i ++) {
		// p[i] = i & 0x0F; /* work fine naturally */
		i[p] = i & 0x0F; /* work fine!! */
		/* a[b] equals *(a + b) */
	}

	for (;;) {
		io_hlt();
	}
}
