OUTPUT_FORMAT("binary")

BASE_ADDRESS = 0x7c00;

SECTIONS {
	. = BASE_ADDRESS;
	/* .text : {*(.text)} */
}
