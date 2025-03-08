package d5

import qu "core:container/queue"
import sa "core:container/small_array"
import "core:fmt"
import "core:log"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:testing"

// In this attempt we parse and deserialize the data first.
// We also experiment with defining types
//
// Useful commands:
// odin test . -define:ODIN_TEST_LOG_LEVEL=warning
// odin test . -thread-count:1

main :: proc() {
	context.logger = log.create_console_logger(
		lowest = log.Level.Info,
		opt = log.Options{.Line, .Procedure},
	)

	bytes := #load("d5.txt")
	str := string(bytes)
	_1 := p1(str)
	_2 := p2(str)
	log.info("p1:", _1)
	log.info("p2:", _2)
}

MAX_RULES :: 24
MAX_UPDATES :: 200
MAX_UPDATE_PAGES :: 32

Page :: distinct u8
Rule :: distinct sa.Small_Array(MAX_RULES, Page)
Rules :: distinct map[Page]Rule
Update :: distinct sa.Small_Array(MAX_UPDATE_PAGES, Page)
Updates :: distinct sa.Small_Array(MAX_UPDATES, Update)

p1 :: proc(data: string) -> int {
	total: int

	rules, updates := parse(data)
	defer delete(rules)

	log.info("Rules:")
	for key, value in rules {
		log.info("\t> Rule:", key, value)
	}

	for update_idx in 0 ..< sa.len(updates) {
		update := sa.get(updates, update_idx)

		log.info("Checking Update:")
		log.info(">\t", update)

		if update_is_valid(&update, &rules) {
			log.info("Update is valid:")
			middle_page_in_update := sa.get_ptr(&update, update.len / 2)
			log.info(">\t Middle Page:", middle_page_in_update^)
			total += int(middle_page_in_update^)
		} else {
			log.info("Update is invalid")
		}
	}

	return total // 4569
}

// For each of the incorrectly-ordered updates, use the page
// ordering rules to put the page numbers in the right order.
// Add together the middle numbers.
p2 :: proc(data: string) -> int {
	total: int

	rules, updates := parse(data)
	defer delete(rules)

	log.info("Rules:")
	for key, value in rules {
		log.info("\t> Rule:", key, value)
	}

	for update_idx in 0 ..< sa.len(updates) {
		update := sa.get_ptr(&updates, update_idx)

		log.info("Checking Update:")
		log.info(">\t", update)

		if update_is_valid(update, &rules) {
			log.info("Update is valid (bad)")
		} else {

			graph := Graph{}
			defer {
				for i in 0 ..< graph.len {
					delete(graph.data[i].edges)
				}
			}

			for i in 0 ..< update.len {
				page_in_update := update.data[i]
				node := node_init(u8(page_in_update))
				ok := sa.push_back(&graph, node)
				assert(ok, "Graph does not have enough memory for another node")
			}

			// For every node in the graph we must follow the rules
			// and add the current node as their dependency.
			//
			// Example: this means we must find nodes 3,4 and add 1 to their edges (as a dependency).
			// Because the syntax means `this_must_come_before|this_one`
			// 1|3
			// 1|4

			for i in 0 ..< graph.len {
				node := graph.data[i]
				page := Page(node.value)
				if page in rules {
					rule := rules[page]
					for j in 0 ..< rule.len {
						r := rule.data[j]
						existing_node, exists := find_node_in_graph(&graph, u8(r))
						if exists {
							log.infof("Add rule for %v -> %v:", existing_node.value, node.value)
							original_node, original_exists := find_node_in_graph(&graph, u8(page))
							assert(original_exists)
							append(&existing_node.edges, original_node)
						}
					}
				}
			}

			result := topological_sort(&graph)
			defer delete(result)

			log.info("And the result is:", result)

			middle := int(result[len(result) / 2])
			log.info("Middle being:", middle)

			total += middle
		}
	}

	return total // 6456
}

parse :: proc(data: string) -> (Rules, Updates) {
	it := string(data)
	section := 0

	rules := make(Rules)
	updates := Updates{}

	for line in strings.split_iterator(&it, "\n\n") {
		line_it := string(line)
		for line in strings.split_lines_iterator(&line_it) {
			if section == 0 {
				log.info("-1-", line)
				part_idx := 0
				part_left, part_right: Page
				part_it := string(line)
				for part in strings.split_iterator(&part_it, "|") {
					log.info("\t>", part)
					part_value, ok := strconv.parse_int(part);assert(ok)
					if part_idx == 0 do part_left = Page(part_value)
					else if part_idx == 1 do part_right = Page(part_value)
					part_idx += 1
				}

				exists := part_left in rules
				if !exists {
					rules[part_left] = Rule{}
				}

				ok := sa.push_back(&rules[part_left], part_right);assert(ok)
			} else {
				log.info("-2-", line)
				update := Update{}
				part_it := string(line)
				for part in strings.split_iterator(&part_it, ",") {
					log.info("\t>", part)
					part_value, ok := strconv.parse_int(part);assert(ok)
					sa.push_back(&update, Page(part_value))
				}
				sa.push_back(&updates, update)
			}
		}
		section += 1
	}

	return rules, updates
}

update_is_valid :: proc(update: ^Update, rules: ^Rules) -> bool {
	// Check each page in the update array
	for update_page_idx in 0 ..< sa.len(update^) {
		update_page := sa.get_ptr(update, update_page_idx)

		// Make sure it has rules to begin with
		if update_page^ in rules {
			log.info("Page in rules:", update_page^)

			// Make sure that every rule is respected
			// They must all have a smaller index with
			// in the current update list.
			rule := rules[update_page^]
			for rule_page_idx in 0 ..< rule.len {
				rule_page := sa.get_ptr(&rule, rule_page_idx)
				rule_idx_within_update := index_of(update, rule_page^)

				log.infof(
					"Check rule: %v(idx:%v)\t%v(idx:%v)",
					update_page^,
					update_page_idx,
					rule_page^,
					rule_idx_within_update,
				)

				if rule_idx_within_update == -1 do continue
				if rule_idx_within_update < update_page_idx do return false
			}
		} else {
			log.info("Page NOT in rules:", update_page^)
		}
	}
	return true
}

/*
Returns the index of the item in a small array.
If it doesn't manage to find it -1 is returned.
*/
index_of :: proc "contextless" (a: ^$A/sa.Small_Array($N, $T), item: T) -> int {
	for idx in 0 ..< a.len {
		curr := sa.get_ptr(a, idx)
		if curr^ == item do return idx
	}
	return -1
}

TEST_DATA :: `47|53
97|13
97|61
97|47
75|29
61|13
75|53
29|13
97|29
53|29
61|53
97|53
61|29
47|13
75|47
97|75
47|61
75|61
47|29
75|13
53|13

75,47,61,53,29
97,61,53,29,13
75,29,13
75,97,47,61,53
61,13,29
97,13,75,29,47
`


@(test)
part_one :: proc(t: ^testing.T) {
	testing.expect_value(t, p1(TEST_DATA), 143)
}

@(test)
part_two :: proc(t: ^testing.T) {
	testing.expect_value(t, p2(TEST_DATA), 123)
}
