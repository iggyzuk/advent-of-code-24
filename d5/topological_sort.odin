package d5

import sa "core:container/small_array"
import "core:log"

Node :: struct {
	value: u8,
	edges: [dynamic]^Node,
}

node_init :: proc(value: u8) -> Node {
	return {value = value}
}

GRAPH_MAX_NODES :: 23

Graph :: sa.Small_Array(GRAPH_MAX_NODES, Node)

find_node_in_graph :: proc(graph: ^Graph, value: u8) -> (node: ^Node, exists: bool) {
	for i in 0 ..< graph.len {
		if graph.data[i].value == value {
			node = &graph.data[i]
			exists = true
			return
		}
	}
	node = nil
	exists = false
	return
}

// https://en.wikipedia.org/wiki/Topological_sorting
// https://www.youtube.com/watch?v=cIBFEhD77b4
topological_sort :: proc(graph: ^Graph) -> [dynamic]u8 {
	n := graph.len
	degrees := make(map[u8]u8, n)
	defer delete(degrees)

	// Loop through the entire graph and increase the degree
	// of all notes that have some other node poiting to it
	for i in 0 ..< n {
		node := graph.data[i]
		degrees[node.value] = 0
	}
	for i in 0 ..< n {
		node := graph.data[i]
		for edge in node.edges {
			log.info(node.value, edge)
			degrees[edge.value] += 1
		}
	}

	log.info(degrees)

	// Add nodes with no incoming edges to the queue
	// Queue is like a frontier
	frontier := make([dynamic]^Node)
	defer delete(frontier)

	for item, degree in degrees {
		if degree == 0 {
			node, exists := find_node_in_graph(graph, item)
			if exists do append(&frontier, node)
		}
	}

	log.info(frontier)

	// Start inserting them one by one
	order := make([dynamic]u8)
	for len(frontier) > 0 {
		at := pop_front(&frontier)
		append(&order, at.value)

		log.info(len(frontier), at)

		// Process current node's edges
		for i in 0 ..< len(at.edges) {
			to := at.edges[i]
			// Decreate their degree by one
			degrees[to.value] = degrees[to.value] - 1
			// When degree reaches zero we can push it onto the frontier
			if degrees[to.value] == 0 do append(&frontier, to)
		}
	}

	log.info(order)

	// Assert that index reached the end of the graph
	assert(len(order) == n, "graph contains a cycle")
	return order
}
