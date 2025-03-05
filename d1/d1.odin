package d1

import "core:bufio"
import "core:fmt"
import "core:log"
import "core:math"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:testing"
import "core:time"

DATA_FILEPATH :: "d1.txt"

main :: proc() {
	fmt.println("\n# day 1")

	data, ok := os.read_entire_file(DATA_FILEPATH, context.allocator)
	if !ok {
		fmt.print("could not read file")
		return
	}
	defer delete(data, context.allocator)

	it := string(data)

	fmt.println(p1(it))
	fmt.println(p2(it))
}

p1 :: proc(data: string) -> int {

	l := make([dynamic]int)
	r := make([dynamic]int)

	lines := strings.split(data, "\n")

	for line, i in lines {
		fmt.printf("LINE (%v):\t%s\n", i, line)

		curr_left: int = 0
		curr_right: int = 0

		spaced: bool = false

		for char, j in line {
			if char == ' ' {
				spaced = true
				fmt.println("SPACE")
				continue
			}

			fmt.printf("\tindex: %v, char: %v\n", j, char)

			// 1 + 2 + 3 should be 123; so we need to convert the string ("123") to an int
			// See part 2 for how to do this with string builders
			if spaced {
				curr_right = curr_right * 10 + (int(char) - '0')
			} else {
				curr_left = curr_left * 10 + (int(char) - '0')
			}
		}

		append(&l, curr_left)
		append(&r, curr_right)
	}
	fmt.print("\n")

	slice.sort(l[:])
	slice.sort(r[:])

	assert(len(l) == len(r), "lengths of l and r must be equal")

	total_delta: int = 0

	for i in 0 ..< len(l) {
		delta: int = math.abs(l[i] - r[i])
		total_delta += delta
		fmt.printf("l: %v, r: %v, delta: %v, total = %v\n", l[i], r[i], delta, total_delta)
	}

	fmt.printf("total delta: %v\n", total_delta)

	return total_delta // 2815556
}

p2 :: proc(data: string) -> int {

	l := make([dynamic]int)

	// Count right value duplicates
	duplicates := make(map[int]int)

	lines := strings.split(data, "\n")

	for line, i in lines {
		fmt.printf("LINE (%v):\t%s\n", i, line)

		ls: strings.Builder
		rs: strings.Builder
		strings.builder_init(&ls)
		strings.builder_init(&rs)

		spaced: bool = false

		for char, j in line {
			if char == ' ' {
				spaced = true
				fmt.println("SPACE")
				continue
			}

			fmt.printf("\tindex: %v, char: %v\n", j, char)

			if spaced {
				strings.write_rune(&rs, char)
			} else {
				strings.write_rune(&ls, char)
			}
		}

		// Convert builders to strings and then to integers
		left_str := strings.to_string(ls)
		right_str := strings.to_string(rs)

		curr_left, ok1 := strconv.parse_int(left_str)
		curr_right, ok2 := strconv.parse_int(right_str)

		if !ok1 || !ok2 {
			fmt.println("Failed to parse integer")
			continue
		}

		append(&l, curr_left)

		exists := curr_right in duplicates
		if exists {
			duplicates[curr_right] = duplicates[curr_right] + 1
		} else {
			duplicates[curr_right] = 1
		}

		// Clean up builders
		strings.builder_destroy(&ls)
		strings.builder_destroy(&rs)
	}
	fmt.print("\n")

	total: int = 0

	for i in 0 ..< len(l) {
		left := l[i]
		total += left * duplicates[left]
	}

	fmt.printf("total: %v\n", total)

	return total // 23927637
}

TEST_DATA :: `3   4
4   3
2   5
1   3
3   9
3   3
`

@(test)
part_one :: proc(t: ^testing.T) {
	testing.expect_value(t, p1(TEST_DATA), 11)
}

@(test)
part_two :: proc(t: ^testing.T) {
	testing.expect_value(t, p2(TEST_DATA), 31)
}
