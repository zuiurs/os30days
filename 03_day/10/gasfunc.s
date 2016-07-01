# generate 32-bit machine code
.code32
.globl	io_hlt

.text
io_hlt:	# void io_hlt(void);
	hlt
	ret
