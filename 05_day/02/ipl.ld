OUTPUT_FORMAT("binary")

BASE_ADDRESS = 0x7C00;

SECTIONS {
	. = BASE_ADDRESS;
	.text : {*(.text)}
	.data : {*(.text)}
	/* add MBR magic number to the end */
	. = BASE_ADDRESS + 510;
	.sign : {SHORT(0xAA55)}
}
