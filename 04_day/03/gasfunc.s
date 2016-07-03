# generate 32-bit machine code
.code32
.globl	io_hlt, write_mem8

.text
io_hlt:	# void io_hlt(void);
	hlt
	ret

