OUTPUT_FORMAT("binary")

/* 0x8000 + 0x4200 = 0xC200 */
BASE_ADDRESS = 0xC200;

SECTIONS {
	. = BASE_ADDRESS;
	.text : {*(.text)}
}
