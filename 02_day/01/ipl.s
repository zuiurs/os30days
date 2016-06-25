.code16
.globl start

# �ȉ��͕W���I��FAT12�t�H�[�}�b�g�t���b�s�[�f�B�X�N�̂��߂̋L�q
start:
	jmp		entry
	.byte	0x90
	.ascii	"HELLOIPL"		# �u�[�g�Z�N�^�̖��O�����R�ɏ����Ă悢�i8�o�C�g�j
	.word	512				# 1�Z�N�^�̑傫���i512�ɂ��Ȃ���΂����Ȃ��j
	.byte	1				# �N���X�^�̑傫���i1�Z�N�^�ɂ��Ȃ���΂����Ȃ��j
	.word	1				# FAT���ǂ�����n�܂邩�i���ʂ�1�Z�N�^�ڂ���ɂ���j
	.byte	2				# FAT�̌��i2�ɂ��Ȃ���΂����Ȃ��j
	.word	224				# ���[�g�f�B���N�g���̈�̑傫���i���ʂ�224�G���g���ɂ���j
	.word	2880			# ���̃h���C�u�̑傫���i2880�Z�N�^�ɂ��Ȃ���΂����Ȃ��j
	.byte	0xf0			# ���f�B�A�̃^�C�v�i0xf0�ɂ��Ȃ���΂����Ȃ��j
	.word	9				# FAT�̈�̒����i9�Z�N�^�ɂ��Ȃ���΂����Ȃ��j
	.word	18				# 1�g���b�N�ɂ����̃Z�N�^�����邩�i18�ɂ��Ȃ���΂����Ȃ��j
	.word	2				# �w�b�h�̐��i2�ɂ��Ȃ���΂����Ȃ��j
	.int 	0				# �p�[�e�B�V�������g���ĂȂ��̂ł����͕K��0
	.int 	2880			# ���̃h���C�u�傫����������x����
	.byte	0,0,0x29		# �悭�킩��Ȃ����ǂ��̒l�ɂ��Ă����Ƃ����炵��
	.int 	0xffffffff		# ���Ԃ�{�����[���V���A���ԍ�
	.ascii	"HELLO-OS   "	# �f�B�X�N�̖��O�i11�o�C�g�j
	.ascii	"FAT12   "		# �t�H�[�}�b�g�̖��O�i8�o�C�g�j
	.skip	18				# �Ƃ肠����18�o�C�g�����Ă���
# �v���O�����{��

entry:
	movw	$0, %ax			# ���W�X�^������
	movw	%ax, %ss
	movw	$start, %sp
	movw	%ax, %ds
	movw	%ax, %es

	movw	$msg, %si

putloop:
	movb	(%si), %al
	add		$0x01, %si		# SI��1�𑫂�
	cmpb	$0x00, %al
	je		fin
	movb	$0x0e, %ah		# �ꕶ���\���t�@���N�V����
	movw	$0x0015, %bx			# �J���[�R�[�h
	int		$0x10			# �r�f�IBIOS�Ăяo��
	jmp		putloop
fin:
	hlt					# ��������܂�CPU���~������
	jmp		fin				# �������[�v

msg:
	.byte	0x0a, 0x0a		# ���s��2��
	.ascii	"hello, world"
	.byte	0x0a			# ���s
	.byte	0
	.org	0x01fe		# 0x7dfe�܂ł�0x00�Ŗ��߂閽��
	.byte	0x55, 0xaa
