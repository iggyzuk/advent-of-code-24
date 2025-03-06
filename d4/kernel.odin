package d4

import "core:fmt"

KERNEL_1 :: `XMAS
`


KERNEL_2 :: `SAMX
`


KERNEL_3 :: `X
M
A
S
`


KERNEL_4 :: `S
A
M
X
`


KERNEL_5 :: `X...
.M..
..A.
...S
`


KERNEL_6 :: `S...
.A..
..M.
...X
`


KERNEL_7 :: `...X
..M.
.A..
S...
`


KERNEL_8 :: `...S
..A.
.M..
X...
`


KERNELS :: [?]string {
	KERNEL_1,
	KERNEL_2,
	KERNEL_3,
	KERNEL_4,
	KERNEL_5,
	KERNEL_6,
	KERNEL_7,
	KERNEL_8,
}

KERNEL_X_SHAPE_1 :: `M.S
.A.
M.S
`


KERNEL_X_SHAPE_2 :: `S.S
.A.
M.M
`


KERNEL_X_SHAPE_3 :: `S.M
.A.
S.M
`


KERNEL_X_SHAPE_4 :: `M.M
.A.
S.S
`


KERNELS_X_SHAPE :: [?]string {
	KERNEL_X_SHAPE_1,
	KERNEL_X_SHAPE_2,
	KERNEL_X_SHAPE_3,
	KERNEL_X_SHAPE_4,
}


EMPTY_SYMBOL :: 46

check_kernel_match :: proc(base: ^Grid, kernel: ^Grid, offset_x, offset_y: int) -> bool {
	for y in 0 ..< kernel.height {
		for x in 0 ..< kernel.width {
			kernel_item, ok := get_grid_item(kernel, x, y);assert(ok)
			if kernel_item != EMPTY_SYMBOL {
				base_item, ok := get_grid_item(base, x + offset_x, y + offset_y);assert(ok)
				if base_item != kernel_item do return false
			}
		}
	}
	return true
}
