package d4

import "core:fmt"
import "core:strconv"
import "core:strings"
import "core:testing"

Grid :: struct {
	items:  [][]u8,
	width:  int,
	height: int,
}

new_grid :: proc(width, height: int) -> Grid {
	items := make([][]u8, height)
	for i in 0 ..< height {
		items[i] = make([]u8, width)
	}
	return Grid{items, width, height}
}

parse_new_grid :: proc(str: string) -> Grid {
	lines := strings.split_lines(str, context.temp_allocator)

	width := len(lines[0])
	height := len(lines) - 1

	fmt.println("New Grid:", width, height)

	grid := new_grid(width, height)

	for y in 0 ..< height {
		for x in 0 ..< width {
			grid.items[y][x] = lines[y][x]
		}
	}

	free_all(context.temp_allocator)

	return grid
}

get_grid_item :: proc(grid: ^Grid, x, y: int) -> (item: u8, ok: bool) {
	if x < 0 || x > grid.width || y < 0 || y > grid.height do return 0, false
	return grid.items[y][x], true
}

delete_grid :: proc(grid: ^Grid) {
	for i in 0 ..< grid.height {
		delete(grid.items[i])
	}
	delete(grid.items)
}
