package d2

import "core:bufio"
import sa "core:container/small_array"
import "core:fmt"
import "core:log"
import "core:math"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:testing"
import "core:time"

main :: proc() {
	bytes := #load("d2.txt")
	str := string(bytes)
	fmt.println(p1(str))
	fmt.println(p2(str))
}

p1 :: proc(data: string) -> int {

	// The levels are either all increasing or all decreasing.
	// Any two adjacent levels differ by at least one and at most three.

	// In this attempt we process data in place; without deserializing it.
	// Makes it a little harder to reason about the logic from top to down.
	// We only have the previous and current state.

	Direction :: enum {
		None,
		Increasing,
		Decreasing,
	}

	count: int

	// Create an iterator string – it's used as a slice that is modified in place.
	it := string(data)

	// Process each line.
	process: for line in strings.split_lines_iterator(&it) {
		if len(line) == 0 do continue
		fmt.printfln("--- %s", line)

		valid: bool = true
		prev: Maybe(int)
		dir: Maybe(Direction)

		line_it := line
		for curr_str in strings.split_iterator(&line_it, " ") {

			// Parse stingy number to int
			curr, ok := strconv.parse_int(curr_str)
			assert(ok)

			if prev_value, exists := prev.?; exists {

				delta := prev_value - curr
				mag := math.abs(delta)

				fmt.printfln("Prev: %v, Curr: %v, Delta: %v, Mag: %v", prev, curr, delta, mag)

				// Any two adjacent levels differ by at least one and at most three.
				if mag > 3 {
					fmt.printfln("Mag Too Big: %v", mag)
					valid = false
				}

				// Calculate direction from prev to curr e.g. 5-2=3; 3>0=Decreasing
				curr_dir: Direction
				if delta < 0 {
					curr_dir = Direction.Increasing
				} else if delta > 0 {
					curr_dir = Direction.Decreasing
				} else {
					fmt.println("No Dir?")
				}

				fmt.printfln("Dir: %v", curr_dir)

				// Check if current direction matches existing direction
				if dir_value, exists := dir.?; exists {
					if curr_dir != dir_value {
						fmt.println("Dir Changed:", curr_dir, dir_value)
						valid = false
					}
				} else {
					dir = Direction(curr_dir)
				}
			} else {
				fmt.printfln("Prev: None, Curr: %v, ---, ---", curr)
			}

			prev = int(curr)
		}

		if valid {
			count += 1
		}

		fmt.printf("# Valid = %v\n\n", valid)
	}

	return count // 486
}

p2 :: proc(data: string) -> int {

	// Can tolerate a single bad level.

	count: int

	// Create an iterator string – it's used as a slice that is modified in place.
	it := string(data)

	// Process each line.
	outer: for line in strings.split_lines_iterator(&it) {
		if len(line) == 0 do continue
		fmt.printfln("--- %s", line)

		numbers := sa.Small_Array(8, int){}

		line_it := line
		for curr_str in strings.split_iterator(&line_it, " ") {
			// Parse stingy number to int.
			curr, ok := strconv.parse_int(curr_str)
			assert(ok)

			// Add number to our small array.
			sa.push_back(&numbers, curr)
		}

		if is_valid(&numbers) {
			count += 1
		} else {
			// see if removing one number will make it valid
			for i in 0 ..< numbers.len {
				copied_numbers := numbers
				sa.ordered_remove(&copied_numbers, i)
				if is_valid(&copied_numbers) {
					count += 1
					continue outer
				}
			}
		}
	}

	return count // 540
}

is_valid :: proc(numbers: ^sa.Small_Array(8, int)) -> bool {
	prev_dir: Maybe(int)

	for i in 1 ..< numbers.len {
		curr := sa.get(numbers^, i)
		prev := sa.get(numbers^, i - 1)

		diff := curr - prev
		if diff == 0 do return false

		dir := math.clamp(diff, -1, 1)
		if prev_dir_val, exists := prev_dir.?; exists {
			if dir != prev_dir do return false
		} else {
			prev_dir = int(dir)
		}

		mag := math.abs(diff)
		if mag > 3 do return false
	}

	return true
}

TEST_DATA :: `7 6 4 2 1
1 2 7 8 9
9 7 6 2 1
1 3 2 4 5
8 6 4 4 1
1 3 6 7 9`


@(test)
part_one :: proc(t: ^testing.T) {
	testing.expect_value(t, p1(TEST_DATA), 2)
}

@(test)
part_two :: proc(t: ^testing.T) {
	testing.expect_value(t, p2(TEST_DATA), 4)
}

@(test)
part_two_2 :: proc(t: ^testing.T) {
	testing.expect_value(t, p2("51 52 48 46 43 41 39"), 1)
}
