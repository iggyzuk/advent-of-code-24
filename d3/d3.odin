package d3

import "core:fmt"
import "core:strconv"
import "core:strings"
import "core:testing"

main :: proc() {
	bytes := #load("d3.txt")
	str := string(bytes)
	fmt.println(p1(str))
	fmt.println(p2(str))
}

p1 :: proc(data: string) -> int {
	total: int
	it := string(data)
	for line in strings.split_iterator(&it, "mul") {
		left_bracket_idx := strings.index(line, "(")
		right_bracket_idx := strings.index(line, ")")

		if left_bracket_idx == -1 do continue
		if right_bracket_idx == -1 do continue

		if left_bracket_idx > right_bracket_idx do continue

		line := line[left_bracket_idx + 1:right_bracket_idx]

		fmt.println(line)

		left_num, right_num, count_num: int
		for num_str in strings.split_iterator(&line, ",") {
			count_num += 1
			fmt.println("  >", num_str)
			num, ok := strconv.parse_int(num_str)
			if !ok do continue
			if count_num == 1 do left_num = num
			if count_num == 2 do right_num = num
		}
		if count_num != 2 do continue

		total += left_num * right_num
	}
	return total // 173529487
}

p2 :: proc(data: string) -> int {
	total: int
	it := string(data)

	do_idx := strings.index(it, "do()")
	dont_idx := strings.index(it, "don't()")

	if (do_idx != -1 && dont_idx != -1) {
		idx := do_idx < dont_idx ? do_idx : dont_idx
		total += p1(it[:idx])
		it = it[idx:]
	} else if do_idx != -1 {
		total += p1(it[:do_idx])
		it = it[do_idx:]
	} else if dont_idx != -1 {
		total += p1(it[:do_idx])
		it = it[do_idx:]
	}

	for line in strings.split_after_iterator(&it, "do()") {
		index := strings.index(line, "don't()")
		if index != -1 {
			total += p1(line[:index])
		} else {
			total += p1(line)
		}
	}

	return total // 99532691
}

TEST_DATA_P1 :: `xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))`
TEST_DATA_P2 :: `xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))` // 2*4+8*5

@(test)
part_one :: proc(t: ^testing.T) {
	testing.expect_value(t, p1(TEST_DATA_P1), 161)
}

@(test)
part_two :: proc(t: ^testing.T) {
	testing.expect_value(t, p2(TEST_DATA_P2), 48)
}
