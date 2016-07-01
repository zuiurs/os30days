.code16
.globl	start

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

# PICが一切の割り込みを受け付けないようにする
#	AT互換機の仕様では、PICの初期化をするなら、
#	こいつをCLI前にやっておかないと、たまにハングアップする
#	PICの初期化はあとでやる

	movb	$0xff, %al
	outb	%al, $0x21
	nop						# OUT命令を連続させるとうまくいかない機種があるらしいので
	outb	%al, $0xa1
	cli						# さらにCPUレベルでも割り込み禁止

# CPUから1MB以上のメモリにアクセスできるように、A20GATEを設定
  
	call 	waitkbdout
	movb	$0xd1, %al
	outb	%al, $0x64
	call	waitkbdout
	movb	$0xdf, %al			# enable A20
	outb	%al, $0x60
	call	waitkbdout

# プロテクトモード移行

.arch	i486				# 486の命令まで使いたいという記述
	lgdtl	(GDTR0)			# 暫定GDTを設定
	movl	%cr0, %eax
	andl	$0x7fffffff, %eax	# bit31を0にする（ページング禁止のため）
	orl		$0x00000001, %eax	# bit0を1にする（プロテクトモード移行のため）
	movl	%eax, %cr0		# %eax = 0XXX....XXX1
	jmp		pipelineflush

pipelineflush:
	movw	$1*8, %ax			#  読み書き可能セグメント32bit
	movw	%ax, %ds
	movw	%ax, %es
	movw	%ax, %fs
	movw	%ax, %gs
	movw	%ax, %ss

# bootpackの転送
	movl	$bootpack, %esi	# 転送元
	movl	$BOTPAK, %edi		# 転送先
	movl	$512*1024/4, %ecx
	call	memcpy

# ついでにディスクデータも本来の位置へ転送

# まずはブートセクタから

	movl	$0x7c00, %esi		# 転送元
	movl	$DSKCAC, %edi		# 転送先
	movl	$512/4, %ecx
	call	memcpy

# 残り全部

	movl	$DSKCAC0+512, %esi	# 転送元
	movl	$DSKCAC+512, %edi	# 転送先
	movl	$0, %ecx
	movb	(CYLS), %cl
	imull	$512*18*2/4, %ecx	# シリンダ数からバイト数/4に変換
	subl	$512/4, %ecx		# IPLの分だけ差し引く
	call	memcpy

# asmheadでしなければいけないことは全部し終わったので、
#	あとはbootpackに任せる

# bootpackの起動

#	movl	$BOTPAK, %ebx
#	movl	$BOTPAK+16, %ecx
#	addl	$3, %ecx			# ECX += 3#
#	shrl	$2, %ecx			# ECX /= 4#
#	jz		skip			# 転送するべきものがない
#	movl	$BOTPAK+20, %esi	# 転送元
#	addl	$BOTPAK, %esi
#	movl	$BOTPAK+12, %edi	# 転送先
#	call	memcpy
#skip:
#	movl	$BOTPAK+12, %esp	# スタック初期値
#	#ljmpl	DWORD 2*8:0x0000001b
#	jmpl	$2*8, $0x0000001b

	movl	$BOTPAK, %ebx
	movl	$0x11a8, %ecx
	addl	$3, %ecx			# ECX += 3#
	shrl	$2, %ecx			# ECX /= 4#
	jz		skip			# 転送するべきものがない
	movl	$0x10c8, %esi	# 転送元
	addl	%ebx, %esi
	movl	$0x00310000, %edi	# 転送先
	call	memcpy
skip:
	movl	$0x00310000, %esp	# スタック初期値
	ljmpl	$2*8, $0x00000000

waitkbdout:
	inb		 $0x64, %al
	andb	 $0x02, %al
	#inb		$0x60, %al
	jnz		waitkbdout		# ANDの結果が0でなければwaitkbdoutへ
	ret

memcpy:
	movl	(%esi), %eax
	addl	$4, %esi
	movl	%eax, (%edi)
	addl	$4, %edi
	subl	$1, %ecx
	jnz		memcpy			# 引き算した結果が0でなければmemcpyへ
	ret
# memcpyはアドレスサイズプリフィクスを入れ忘れなければ、ストリング命令でも書ける

	.align	16
GDT0:
	.skip	8				# ヌルセレクタ
	.word	0xffff,0x0000,0x9200,0x00cf	# 読み書き可能セグメント32bit
	.word	0xffff,0x0000,0x9a28,0x0047	# 実行可能セグメント32bit（bootpack用）

	.word	0
GDTR0:
	.word	8*3-1
	.int	GDT0

	.align	16
bootpack:
