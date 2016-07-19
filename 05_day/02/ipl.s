.code16
.globl start

.equ	CYLS, 10

# META PROGRAM: 3.5 Inch Floppy 2HD Disk (formated FAT12)
.text
start:
	jmp		entry			# Relative jmp instruction
	.byte	0x90			# nop
	.ascii	"IPL     "		# Boot loader's (IPL's) name (8 byte) (OEM Name)
	.word	512				# Sector Size: 512 (Specification)
	.byte	1				# Allocation Unit Size (Cluster Size): 1 Sector (Specification)
	.word	1				# FAT Table Position: 1 Sector (Normally set 1)
	.byte	2				# Number of FAT Tables: 2 (Normally set 2)
	.word	224				# Size of Root Directory: 224 (Normally set 224) (FAT12 Only Setting)
	.word	2880			# Drive Size: 2880 (Specification)
	.byte	0xf0			# Media Type: 0xF0 (Specification)
	.word	9				# Number of Sectors in FAT Table: 9 (Specification)
	.word	18				# Number of Sectors per Track: 18 (Specification)
	.word	2				# Number of Heads: 2 (Specification)
	.int 	0				# Hidden Sector: 0 (given the front of each partition)
	.int 	2880			# Number of Sectors: 2880
	.byte	0,0,0x29		# Drive Number: 0, Preserved Byte:0, Boot Info: 0x29
	.int 	0xffffffff		# Volume Serial ID
	.ascii	"HARIBOTEOS "	# Volume Label (11 byte)
	.ascii	"FAT12   "		# File System Type (8 byte)
	.skip	18				# fill out by adequately values

# MAIN PROGRAM
entry:
	movw	$0, %ax			# Initialize %ax (Accumlator)
	movw	%ax, %ss		# Initialize %ss (Stack Segment)
	movw	$start, %sp		# set %sp(Stack Pointer) $start(0x7C00)
	movw	%ax, %ds		# Initialize %ds (Data Segment)
# Read Disk
	movw	$0x0820, %ax	# %ax = 0x0820
	movw	%ax, %es		# %es = 0x0820 (Buffer Address)
	movb	$0, %ch			# cylinder = 0
	movb	$0, %dh			# head = 0
	movb	$2, %cl			# sector = 2

readloop:
	movw	$0, %si			# fc (failure counter (%si))

retry:
	movb	$0x02, %ah		# %ah = 0x02: (read mode)
	movb	$1, %al			# Read Sector: 1
	movw	$0, %bx			# Buffer Address (%bx): 0
	movb	$0x00, %dl		# Drive: A
	int		$0x13			# Interruption: Disk Service
	jnc		next			# if no problem then; goto label:next
	addw	$1, %si			# fc ++
	cmpw	$5, %si			
	jae		error			# if fc >= 5 then; goto error
	movb	$0, %ah			# %ah = 0x00: (none)
	movb	$0, %dl			# Drive: A
	int		$0x13			# Interruption: Disk Service (for initialization param)
	jmp		retry

next:
	movw	%es, %ax		# %ax = %es (restore %es to %ax for calculation)
	addw	$0x0020, %ax	# plus 0x20 (%es*16 + %bx, so %es increasing 0x20 means 0x200)
	movw	%ax, %es		# shift 512 byte(0x200 byte)(a sector size is 512 byte in floppy)
	addb	$1, %cl			# sector ++
	cmpb	$18, %cl
	jbe		readloop		# if sector <= 18 then; goto readloop
	movb	$1, %cl			# sector = 1
	addb	$1, %dh			# header ++
	cmpb	$2, %dh
	jb		readloop		# if head < 2 then; goto readloop // read 18 sector
	movb	$0, %dh			# header = 0
	addb	$1, %ch			# cylinder ++
	cmpb	$CYLS, %ch
	jb		readloop		# if cylinder < CYLS then; goto readloop
# read flow: C0H0S0 -> C0H1S0 -> C1H0S0 -> C1H1S0 -> ... -> C9H1S18 
	movb	$CYLS, (0x0ff0)	# Store current Cylinder

main:
	jmp		0xc200

error:
	movw	$msg0, %si

putloop:	# display messages
	movb	(%si), %al		# data of char(1 byte) to %al
	add		$0x01, %si		# %si ++
	cmpb	$0x00, %al
	je		fin				# if char == \0 then; goto fin
	movb	$0x0e, %ah		# Write Teletype mode(displays a char, and moves cursor to next)
	movw	$0x0015, %bx	# BH: Page Number, BL: Color Code
	int		$0x10			# Interruption: Video Services
	jmp		putloop

fin:	# ecological HLT loop
	hlt
	jmp		fin

.data
msg0:
	.string	"Load Error"
msg1:
	.string "Success"
