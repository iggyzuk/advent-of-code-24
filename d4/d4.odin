package d4

import "core:fmt"
import "core:strconv"
import "core:strings"
import "core:testing"

// Find one word: XMAS
// This word search allows words to be horizontal, vertical,
// diagonal, written backwards, or even overlapping other words.
main :: proc() {
	bytes := #load("d4.txt")
	str := string(bytes)
	fmt.println(p1(str))
	fmt.println(p2(str))
}

p1 :: proc(data: string) -> int {
	total: int

	grid := parse_new_grid(data)

	for kernel_str in KERNELS {
		kernel := parse_new_grid(kernel_str)

		range_x := grid.width - kernel.width
		range_y := grid.height - kernel.height

		for y in 0 ..= range_y {
			for x in 0 ..= range_x {
				if check_kernel_match(&grid, &kernel, x, y) {
					total += 1
				}
			}
		}
		delete_grid(&kernel)
	}

	delete_grid(&grid)

	return total // 2551
}

p2 :: proc(data: string) -> int {
	total: int

	grid := parse_new_grid(data)

	for kernel_str in KERNELS_X_SHAPE {
		kernel := parse_new_grid(kernel_str)

		range_x := grid.width - kernel.width
		range_y := grid.height - kernel.height

		for y in 0 ..= range_y {
			for x in 0 ..= range_x {
				if check_kernel_match(&grid, &kernel, x, y) {
					total += 1
				}
			}
		}
		delete_grid(&kernel)
	}

	delete_grid(&grid)

	return total // 1985
}

TEST_DATA :: `MMMSXXMASM
MSAMXMSMSA
AMXSXMAAMM
MSAMASMSMX
XMASAMXAMM
XXAMMXXAMA
SMSMSASXSS
SAXAMASAAA
MAMMMXMMMM
MXMXAXMASX
`


@(test)
part_one :: proc(t: ^testing.T) {
	testing.expect_value(t, p1(TEST_DATA), 18)
}

@(test)
part_two :: proc(t: ^testing.T) {
	testing.expect_value(t, p2(TEST_DATA), 9)
}
