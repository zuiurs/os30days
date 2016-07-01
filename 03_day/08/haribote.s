.code16
.globl	start

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

# memo
	movb	$0x08, (VMODE)
	movw	$320, (SCRNX)
	movw	$200, (SCRNY)
	movl	$0x000a0000, (VRAM)

# Get LED's status	
	movb	$0x02, %ah	# Return Shift Flag Status
	int		$0x16		# Keyboard Services
	movb	%al, (LEDS)

fin:
	hlt
	jmp fin
