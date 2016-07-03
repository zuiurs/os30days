.code16
.globl	start

# Memory Map
# 0x00000000 - 0x000fffff: Free (1MB)
# 0x00100000 - 0x00267fff: Load Floppy Image (1440KB)
# 0x00268000 - 0x0026f7ff: Free (30KB)
# 0x0026f800 - 0x0026ffff: IDT (2KB)
# 0x00270000 - 0x0027ffff: GDT (64KB)
# 0x00280000 - 0x002fffff: Load boot.bin (512KB)
# 0x00300000 - 0x003fffff: Stack (1MB)
# 0x00400000 -			 : Free

.equ	BOTPAK,	0x00280000		# Destination address of bootpack
.equ	DSKCAC,	0x00100000		# Disk Cache address
.equ	DSKCAC0,0x00008000		# Disk Cache address (Real mode)

# data store address
.equ	CYLS,	0x0ff0	# 1 byte
.equ	LEDS,	0x0ff1	# 1 byte
.equ	VMODE,	0x0ff2	# 2 byte
.equ	SCRNX,	0x0ff4	# 2 byte
.equ	SCRNY,	0x0ff6	# 2 byte
.equ	VRAM,	0x0ff8	# 2 byte

.text
start:
	movb	$0x13, %al	# VGA Graphics 320 x 200 x 8bit color
	movb	$0x00, %ah
	int		$0x10

# store value
	movb	$0x08, (VMODE)
	movw	$320, (SCRNX)
	movw	$200, (SCRNY)
	movl	$0x000a0000, (VRAM)

# Get LED's status	
	movb	$0x02, %ah	# Return Shift Flag Status
	int		$0x16		# Keyboard Services
	movb	%al, (LEDS)

# make PIC (Programmable Interrupt Controller) shutting out any interruptions
	movb	$0xff, %al
	outb	%al, $0x21		# Preprocessing
	nop						# making sure (sequential out instruction occurs hanging up)
	outb	%al, $0xa1		# Preprocessing
	cli						# prohibit interruption

# Terminate A20 Mask Circuit for accessing over 1MB
#	(A20 Mask Circuit makes A20 bit "0" always)
	call 	waitkbdout
	movb	$0xd1, %al
	outb	%al, $0x64
	call	waitkbdout
	movb	$0xdf, %al		# terminate A20 mask circuit
	outb	%al, $0x60
	call	waitkbdout		# wait to complete these processes

# Switch Protect Mode
.arch	i486					# Enable 32-bit instructions
	lgdtl	(GDTR0)				# Load provisional GDT
	movl	%cr0, %eax
	andl	$0x7fffffff, %eax	# cr0[31] = 0 (disable paging) (PG bit)
	orl		$0x00000001, %eax	# cr0[0]  = 1 (enable "Protect Mode") (PE bit)
	movl	%eax, %cr0			# %cr0 = 0XXX....XXX1
	jmp		pipelineflush		# IMPORTANT
	# * Memo *
	# "jmp" clears some instructions loaded beforehand by pipeline process
	# Before PE bit is enabled, memory access is via GDT,
	#				so you must initialize segment register.
	# Real Mode:	<segment register * 0x10> + <index register>
	# Protect Mode:	<GDT[segment register].BaseAddress * 0x10> + <index register>

# Initialize segment register(exclude %cs)
pipelineflush:
	movw	$1*8, %ax			# {Read/Write}able segment 32bit
	movw	%ax, %ds
	movw	%ax, %es
	movw	%ax, %fs
	movw	%ax, %gs
	movw	%ax, %ss

# Transfer bootpack
	movl	$bootpack, %esi		# Source
	movl	$BOTPAK, %edi		# Destination (x000280000)
	movl	$512*1024/4, %ecx	# transfer 512 KB
	call	memcpy

# Transfer disk data
# [Boot Sector]
	movl	$0x7c00, %esi		# Source
	movl	$DSKCAC, %edi		# Destination (0x00100000)
	movl	$512/4, %ecx		# transfer 512 byte
	call	memcpy
# [Other]
	movl	$DSKCAC0+512, %esi	# Source (0x8000 + 0x0200)
	movl	$DSKCAC+512, %edi	# Destination (0x00100200)
	movl	$0, %ecx			# [ecx               [cx      [ch][cl]]] = 0
	movb	(CYLS), %cl			# %cl = CYLS (refer to ipl.s)
	imull	$512*18*2/4, %ecx	# readCylinder(10) * Sector(18) * Head(2) * sectorSize(512)
								# transfer read size
	subl	$512/4, %ecx		# exclude IPL size
	call	memcpy

# Set the bootpack.c and go
	movl	$BOTPAK, %ebx		# SOURCE_INDEX(%ebx) = 0x00280000
	movl	$0x0084, %ecx		# data counter = 0x0084 bytes (size of boot.bin)
	addl	$3, %ecx			# adjust counter for memcpy which copies by 4-bytes
	shrl	$2, %ecx			# make 4-bytes counter (2-bit right shift)
	jz		skip				# if %ecx == 0; then skip;
	movl	$0x0000, %esi		# SOURCE_BASE(%esi) = 0
	addl	%ebx, %esi			# SOURCE_INDEX(%ebx) = 0x00280000 + 0x0
	movl	$0x00310000, %edi	# DESTINATION(%edi) = 0x00310000 (adequately)
	call	memcpy
skip:
	movl	$0x00310000, %esp	# sp = 0x00310000
	ljmpl	$2*8, $0x00000000

###### Function Codes ######
waitkbdout:	# send data(%al) to 0x64 port
	inb		$0x64, %al
	andb	$0x02, %al
	inb		$0x60, %al		# read left buffer (for avoiding malfunction by buffer received)
	jnz		waitkbdout		# if (%al && 0x02) != 0; then continue;
	ret

memcpy:		# double word incremental copy
	movl	(%esi), %eax	# %eax = data[%esi]
	addl	$4, %esi		# %esi += 4
	movl	%eax, (%edi)	# memory[%edi] = %eax
	addl	$4, %edi		# %edi += 4
	subl	$1, %ecx		# data counter(%ecx) --
	jnz		memcpy			# if %ecx == 0; then return;
	ret
############################

	.align	8	# for good place
	# If GDT label isn't a multiple of 8,
	#	mov (to segment register) inst will get late.

# Dummy GDT
GDT0:
	# Segment Descriptor: 64-bit (8 byte)
	.word	0x0000, 0x0000, 0x0000, 0x0000	# Null Selector
	.word	0xffff, 0x0000, 0x9200, 0x00cf	# {Read/Write}able Segment 32-bit
		# Segment Limit Low		: 0xffff	# 0 - 16 bit
		# Base Address Low		: 0x0000
		# Base Address Mid		: 0x00
		# Type					: 0010(2)	# Read/Write
		# Descripter Type		:    1(2)	# Code/Data Segment Type
		# Privilege Level		:   00(2)	# 0 - 3 (0 is highest previlege level)
		# Segment Present Flag	:    1(2)	# exists this segment in memory
		# Segment Limit High	: 1111(2)	# 17 - 20 bit
		# Available (Free bit)	:    0(2)	# OS can use freely
		# META					:    0(2)	# this bit must be "0"
		# Operation Size		:    1(2)	# 0: 16-bit, 1: 32-bit
		# Granularity Flag		:    1(2)	# Segment Limit treated as byte(0) or *4KB(1) (normally "1")
		# Base Address High		: 0x00
	.word	0xffff, 0x0000, 0x9a28, 0x0047	# Executable Segment 32-bit (for bootpack)
		# Segment Limit Low		: 0xffff	# 0 - 16 bit
		# Base Address Low		: 0x0000
		# Base Address Mid		: 0x28
		# Type					: 1010(2)	# Executable/Read
		# Descripter Type		:    1(2)	# Code/Data Segment Type
		# Privilege Level		:   00(2)	# 0 - 3 (0 is highest previlege level)
		# Segment Present Flag	:    1(2)	# exists this segment in memory
		# Segment Limit High	: 0111(2)	# 17 - 20 bit
		# Available (Free bit)	:    0(2)	# OS can use freely
		# META					:    0(2)	# this bit must be "0"
		# Operation Size		:    1(2)	# 0: 16-bit, 1: 32-bit
		# Granularity Flag		:    0(2)	# Segment Limit treated as byte(0) or *4KB(1) (normally "1")
		# Base Address High		: 0x00

	.word	0
GDTR0:
	.word	8*3-1	# size of GDT (should be <byte of table> - 1 )
	.int	GDT0	# 32-bit address of GDT0
	# Format: [47    <Linear Base Address>   16|15<Table Limit>0]

	.align	8	# for good place

bootpack:
