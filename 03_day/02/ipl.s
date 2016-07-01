.code16
.globl start

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
	movw	$0, %ax			# レジスタ初期化
	movw	%ax, %ss
	movw	$start, %sp
	movw	%ax, %ds
# ディスクを読む
	movw	$0x0820, %ax
	movw	%ax, %es
	movb	$0, %ch			# シリンダ0
	movb	$0, %dh			# ヘッド0
	movb	$2, %cl			# セクタ2
	movw	$0, %si			# 失敗回数を数えるレジスタ

retry:
	movb	$0x02, %ah		# AH=0x02 : ディスク読み込み
	movb	$1, %al			# 1セクタ
	movw	$0, %bx
	movb	$0x00, %dl		# Aドライブ
	int		$0x13			# ディスクBIOS呼び出し
	jnc		fin
	addw	$1, %si
	cmpw	$5, %si
	jae		error
	movb	$0, %ah			# 初期化してリトライ
	movb	$0, %dl
	int		$0x13
	jmp		retry

fin:
	hlt					# 何かあるまでCPUを停止させる
	jmp		fin				# 無限ループ

error:
	movw	$msg, %si

putloop:
	movb	(%si), %al
	add		$0x01, %si		# SIに1を足す
	cmpb	$0x00, %al
	je		fin
	movb	$0x0e, %ah		# 一文字表示ファンクション
	movw	$0x0015, %bx			# カラーコード
	int		$0x10			# ビデオBIOS呼び出し
	jmp		putloop

.data
msg:
	.string	"Load Error"
