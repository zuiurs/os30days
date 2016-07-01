.code16
.globl	start
.text
start:
	movw	$msg, %si

putloop:	# display messages
	movb	(%si), %al		
	add		$0x01, %si		# SIに1を足す
	cmpb	$0x00, %al
	je		fin
	movb	$0x0e, %ah		# 一文字表示ファンクション
	movw	$0x0015, %bx	# カラーコード
	int		$0x10			# ビデオBIOS呼び出し
	jmp		putloop

fin:
	hlt
	jmp fin

.data
msg:
	.string "main program" 
