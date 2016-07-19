# generate 32-bit machine code
.code32
.globl	io_hlt, io_cli, io_sti, io_stihlt
.globl	o_in8, io_in16, io_in32, io_out8, io_out16
.globl	io_out32, io_load_eflags, io_store_eflags
.globl	load_gdtr, load_idtr, load_register_struct

.text
io_hlt:	# void io_hlt(void);
	hlt
	ret

io_cli:	# void io_cli(void);
   	cli
   	ret

io_sti:	# void io_sti(void);
   	sti
   	ret

io_stihlt:	# void io_stihlt(void);
   	sti
   	hlt
   	ret

io_in8:	# int io_in8(int port);
   	movl	4(%esp), %edx		# %edx = port
   	movl	$0, %eax
   	inb		%dx, %al
   	ret

io_in16:	# int io_in16(int port);
   	movl	4(%esp), %edx
   	movl	$0, %eax
   	inw		%dx, %ax
   	ret

io_in32:	# int io_in32(int port);
   	movl	4(%esp), %edx
   	inl		%dx, %eax
   	ret

io_out8:	# void io_out8(int port, int data);
   	movl	4(%esp), %edx	# %edx = port
   	movb	8(%esp), %al	# %al  = data
   	outb	%al, %dx
   	ret

io_out16:	# void io_out16(int port, int data);
   	movl	4(%esp), %edx
   	movw	8(%esp), %ax
   	outw	%ax, %dx
   	ret

io_out32:	# void io_out32(int port, int data);
   	movl	4(%esp), %edx
   	movl	8(%esp), %eax
   	outl	%eax, %dx
   	ret

io_load_eflags:	# int io_load_eflags(void);
   	pushfl			# PUSH EFLAGS
   	pop		%eax	# store %eax with EFLAGS via STACK 
   	ret

io_store_eflags:	# void io_store_eflags(int eflags);
	movl	4(%esp), %eax	# %eax = EFLAGS
	push	%eax			# store stack with EFLAGS
	popfl					# POP EFLAGS (apply EFLAGS)
	ret

load_gdtr:	# void load_gdtr(int limit, int addr);
	movw	4(%esp), %ax
	movw	%ax, 6(%esp)
	lgdtl	6(%esp)
	ret

load_idtr:	# void load_idtr(int limit, int addr);
	movw	4(%esp), %ax
	movw	%ax, 6(%esp)
	lidtl	6(%esp)
	ret

.equ	REG_STRUCT, 0x0e00
load_register_struct:	# void set_register_struct(void);
	# General Purpose Registers
	movl	%eax, (REG_STRUCT)
	movl	%ebx, (REG_STRUCT+4)
	movl	%ecx, (REG_STRUCT+8)  
	# Index Registers
	#movl	%esi, (REG_STRUCT+12)
	#movl	%edi, (REG_STRUCT+16)
	## Pointer Registers
	#movl	%ebp, (REG_STRUCT+20)
	#movl	%esp, (REG_STRUCT+24)
	## Segment Registers
	#movw	%cs,  (REG_STRUCT+28) 
	#movw	%ds,  (REG_STRUCT+30)
	#movw	%ss,  (REG_STRUCT+32)
	#movw	%es,  (REG_STRUCT+34)
	#movw	%fs,  (REG_STRUCT+36)
	#movw	%gs,  (REG_STRUCT+38)
	## Control Register
	##movl	%cr0, (REG_STRUCT+40)
	#pushfl
	#pop		(REG_STRUCT+44)
	ret
