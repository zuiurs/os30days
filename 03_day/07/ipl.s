.code16
.globl start

.equ	CYLS, 10

# 以下は標準的なFAT12フォーマットフロッピーディスクのための記述
.text
start:
	jmp		entry
	.byte	0x90
	.ascii	"IPL     "		# ブートセクタの名前を自由に書いてよい（8バイト）
	.word	512				# 1セクタの大きさ（512にしなければいけない）
	.byte	1				# クラスタの大きさ（1セクタにしなければいけない）
	.word	1				# FATがどこから始まるか（普通は1セクタ目からにする）
	.byte	2				# FATの個数（2にしなければいけない）
	.word	224				# ルートディレクトリ領域の大きさ（普通は224エントリにする）
	.word	2880			# このドライブの大きさ（2880セクタにしなければいけない）
	.byte	0xf0			# メディアのタイプ（0xf0にしなければいけない）
	.word	9				# FAT領域の長さ（9セクタにしなければいけない）
	.word	18				# 1トラックにいくつのセクタがあるか（18にしなければいけない）
	.word	2				# ヘッドの数（2にしなければいけない）
	.int 	0				# パーティションを使ってないのでここは必ず0
	.int 	2880			# このドライブ大きさをもう一度書く
	.byte	0,0,0x29		# よくわからないけどこの値にしておくといいらしい
	.int 	0xffffffff		# たぶんボリュームシリアル番号
	.ascii	"HARIBOTEOS "	# ディスクの名前（11バイト）
	.ascii	"FAT12   "		# フォーマットの名前（8バイト）
	.skip	18				# とりあえず18バイトあけておく
# プログラム本体

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

main:
	jmp		0xc200

error:
	movw	$msg0, %si

putloop:	# display messages
	movb	(%si), %al		
	add		$0x01, %si		# SIに1を足す
	cmpb	$0x00, %al
	je		fin
	movb	$0x0e, %ah		# 一文字表示ファンクション
	movw	$0x0015, %bx	# カラーコード
	int		$0x10			# ビデオBIOS呼び出し
	jmp		putloop

fin:	# ecological HLT loop
	hlt
	jmp		fin

.data
msg0:
	.string	"Load Error"
msg1:
	.string "Success"
