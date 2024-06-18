package main

import "core:fmt"

Stack :: struct {
	nodes:    []StackNode,
	top:      int,
	capacity: int,
}

stack_init :: proc(cap: int) -> Stack {
	return Stack{nodes = make([]StackNode, cap), top = -1, capacity = cap}
}

stack_push :: proc(stack: ^Stack, node: StackNode) {
	assert(stack.top < stack.capacity, "Not enough capacity")
	stack.top += 1
	stack.nodes[stack.top] = node
}

stack_pop :: proc(stack: ^Stack) -> StackNode {
	assert(stack.top >= 0, "Cannot pop empty stack")
	node := stack.nodes[stack.top]
	stack.top -= 1
	return node
}

stack_peek :: proc(stack: ^Stack, offset: int) -> StackNode {
	return stack.nodes[stack.top + 1 + offset]
}

stack_size :: proc(stack: Stack) -> int {
	return stack.top + 1
}
