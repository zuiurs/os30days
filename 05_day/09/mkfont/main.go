package main

import (
	"bufio"
	"flag"
	"fmt"
	"os"
	"regexp"
	"strconv"
	"strings"
)

const (
	TARGET = "fonts_by_mkfont.c"
)

func main() {
	var sfile *os.File
	var dfile *os.File

	var err error

	var target = flag.String("o", TARGET, "Output file")
	flag.Parse()

	if flag.Arg(0) == "" {
		fmt.Println("Error: Required an argument")
		return
	} else {
		sfile, err = os.Open(flag.Arg(0))
		if err != nil {
			fmt.Println(err)
			return
		} else {
			defer sfile.Close()
		}
	}

	buff, err := fonts_c_builder(sfile)
	if err != nil {
		fmt.Println(err)
		return
	}

	dfile, err = os.Create(*target)
	if err != nil {
		fmt.Println(err)
		return
	} else {
		defer dfile.Close()
	}
	
	fmt.Println("========> Converting C Source...")
	dfile.Write(([]byte) (buff))
	fmt.Println("========> Finished!")
}

func fonts_c_builder(file *os.File) (string, error) {
	fmt.Println("========> Reading File...")
	
	var buff_str string
	
	r := regexp.MustCompile(`^[\.|\*]{8}$`)

	var text string
	var byte_int uint64
	var line_count int

	isFirst := true

	fmt.Println("========> Generating C Source...")
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		text = scanner.Text()
		if r.MatchString(text) {
			text = strings.Replace(text, ".", "0", -1)
			text = strings.Replace(text, "*", "1", -1)

			/* 01001001 -> 73*/
			byte_int, _ = strconv.ParseUint(text, 2, 8)

			if isFirst {
				isFirst = false
				buff_str += "\n"
			} else {
				buff_str += ", "
			}

			/* 73 -> 0x49 */
			buff_str += fmt.Sprintf("0x%02x", byte_int)

			/* insert "\n" in 16-bytes(1 character) */
			line_count++
			if (line_count % 16) == 0 {
				buff_str += "\n"
			}
		}
	}
	if err := scanner.Err(); err != nil {
		return "", err
	}

	buff_str = fmt.Sprintf("char fonts[%d] = {%s};", line_count, buff_str)

	return buff_str, nil
}
