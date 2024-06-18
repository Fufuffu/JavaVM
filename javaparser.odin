package main

import "base:intrinsics"
import "core:fmt"
import "core:os"

FILENAME :: "Main.class"

U4_BUFFER: [4]u8
U2_BUFFER: [2]u8
U1_BUFFER: [1]u8

parse_u1 :: proc(f: os.Handle) -> u8 {
	bytes_read, err := os.read(f, U1_BUFFER[:])
	if err != 0 || bytes_read != 1 {
		panic("couldn't read 1 bytes")
	}
	return transmute(u8)U1_BUFFER
}

parse_u2 :: proc(f: os.Handle) -> u16be {
	bytes_read, err := os.read(f, U2_BUFFER[:])
	if err != 0 || bytes_read != 2 {
		panic("couldn't read 2 bytes")
	}
	return transmute(u16be)U2_BUFFER
}

parse_u4 :: proc(f: os.Handle) -> u32be {
	bytes_read, err := os.read(f, U4_BUFFER[:])
	if err != 0 || bytes_read != 4 {
		panic("couldn't read 4 bytes")
	}
	return transmute(u32be)U4_BUFFER
}

parse_byte_array :: proc(f: os.Handle, length: $T) -> []u8 where intrinsics.type_is_numeric(T) {
	byte_buf := make([]u8, length)
	bytes_read, err := os.read(f, byte_buf[:])
	if err != 0 || T(bytes_read) != length {
		panic("couldn't read length bytes")
	}
	return byte_buf
}

parse_interfaces :: proc(f: os.Handle, count: u16be) -> []u16be {
	interfaces := make([]u16be, count)
	for &interface in interfaces {
		interface = parse_u2(f)
	}
	return interfaces
}

parse_attribute_info :: proc(f: os.Handle, count: u16be) -> []Attribute_Info {
	attributes := make([]Attribute_Info, count)
	for &attribute in attributes {
		attribute.attribute_name_index = parse_u2(f)
		attribute.attribute_length = parse_u4(f)
		attribute.info = parse_byte_array(f, attribute.attribute_length)
	}
	return attributes
}

parse_method_info :: proc(f: os.Handle, count: u16be) -> []Method_Info {
	methods := make([]Method_Info, count)
	for &method in methods {
		method.access_flags = parse_u2(f)
		method.name_index = parse_u2(f)
		method.descriptor_index = parse_u2(f)
		method.attributes_count = parse_u2(f)
		method.attributes = parse_attribute_info(f, method.attributes_count)
	}
	return methods
}

parse_field_info :: proc(f: os.Handle, count: u16be) -> []Field_Info {
	fields := make([]Field_Info, count)
	for &field in fields {
		field.access_flags = parse_u2(f)
		field.name_index = parse_u2(f)
		field.descriptor_index = parse_u2(f)
		field.attributes_count = parse_u2(f)
		field.attributes = parse_attribute_info(f, field.attributes_count)
	}
	return fields
}

parse_cp_info :: proc(f: os.Handle, count: u16be) -> []Cp_Info {
	cp_infos := make([]Cp_Info, count - 1)
	for &cp_info in cp_infos {
		raw_tag := parse_u1(f)
		cp_info.tag = Constant_Kind(raw_tag)

		#partial switch cp_info.tag {
		case .Methodref:
			cp_info.data = CONSTANT_Methodref {
				class_index         = parse_u2(f),
				name_and_type_index = parse_u2(f),
			}
		case .Class:
			cp_info.data = CONSTANT_Class {
				name_index = parse_u2(f),
			}
		case .NameAndType:
			cp_info.data = CONSTANT_NameAndType {
				name_index       = parse_u2(f),
				descriptor_index = parse_u2(f),
			}
		case .Utf8:
			length := parse_u2(f)
			bytes := parse_byte_array(f, length)
			cp_info.data = CONSTANT_Utf8 {
				length = length,
				str    = transmute(string)bytes,
			}
		case .Fieldref:
			cp_info.data = CONSTANT_Fieldref {
				class_index         = parse_u2(f),
				name_and_type_index = parse_u2(f),
			}
		case .String:
			cp_info.data = CONSTANT_String {
				string_index = parse_u2(f),
			}
		case:
			fmt.println("Cp_info tag:", raw_tag, "not implemented")
			os.exit(1)
		}

	}
	return cp_infos
}

CONSTANT_String :: struct {
	string_index: u16be,
}

CONSTANT_Fieldref :: struct {
	class_index:         u16be,
	name_and_type_index: u16be,
}

CONSTANT_Methodref :: struct {
	class_index:         u16be,
	name_and_type_index: u16be,
}

CONSTANT_Class :: struct {
	name_index: u16be,
}

CONSTANT_NameAndType :: struct {
	name_index:       u16be,
	descriptor_index: u16be,
}

CONSTANT_Utf8 :: struct {
	length: u16be,
	str:    string,
}

Constant_Kind :: enum u8 {
	Utf8               = 1,
	Integer            = 3,
	Float              = 4,
	Long               = 5,
	Double             = 6,
	Class              = 7,
	String             = 8,
	Fieldref           = 9,
	Methodref          = 10,
	InterfaceMethodref = 11,
	NameAndType        = 12,
	MethodHandle       = 15,
	MethodType         = 16,
	Dynamic            = 17,
	InvokeDynamic      = 18,
	Module             = 19,
	Package            = 20,
}

Class_File :: struct {
	magic:               u32be,
	minor_version:       u16be,
	major_version:       u16be,
	constant_pool_count: u16be,
	constant_pool:       []Cp_Info,
	// TODO: convert into a bit_set with an enum backing it
	access_flags:        u16be,
	this_class:          u16be,
	super_class:         u16be,
	interfaces_count:    u16be,
	interfaces:          []u16be,
	fields_count:        u16be,
	fields:              []Field_Info,
	methods_count:       u16be,
	methods:             []Method_Info,
	attributes_count:    u16be,
	attributes:          []Attribute_Info,
}

Cp_Info :: struct {
	tag:  Constant_Kind,
	data: union {
		CONSTANT_Methodref,
		CONSTANT_Class,
		CONSTANT_NameAndType,
		CONSTANT_Utf8,
		CONSTANT_Fieldref,
		CONSTANT_String,
	},
}

Field_Info :: struct {
	access_flags:     u16be,
	name_index:       u16be,
	descriptor_index: u16be,
	attributes_count: u16be,
	attributes:       []Attribute_Info,
}

Method_Info :: struct {
	access_flags:     u16be,
	name_index:       u16be,
	descriptor_index: u16be,
	attributes_count: u16be,
	attributes:       []Attribute_Info,
}

Attribute_Info :: struct {
	attribute_name_index: u16be,
	attribute_length:     u32be,
	info:                 []u8,
}

Code_Attribute :: struct {
	max_stack:              u16be,
	max_locals:             u16be,
	code_length:            u32be,
	code:                   []u8,
	exception_table_length: u16be,
	exception_table:        []Exception,
	attributes_count:       u16be,
	attributes:             []Attribute_Info,
}

Exception :: struct {
	start_pc:   u16be,
	end_pc:     u16be,
	handler_pc: u16be,
	catch_type: u16be,
}

class_file: Class_File

main :: proc() {
	handle, err := os.open(FILENAME, os.O_RDONLY)
	if err != 0 {
		panic("Could not open file")
	}

	class_file.magic = parse_u4(handle)
	class_file.minor_version = parse_u2(handle)
	class_file.major_version = parse_u2(handle)
	class_file.constant_pool_count = parse_u2(handle)
	class_file.constant_pool = parse_cp_info(handle, class_file.constant_pool_count)
	class_file.access_flags = parse_u2(handle)
	class_file.this_class = parse_u2(handle)
	class_file.super_class = parse_u2(handle)
	class_file.interfaces_count = parse_u2(handle)
	class_file.interfaces = parse_interfaces(handle, class_file.interfaces_count)
	class_file.fields_count = parse_u2(handle)
	class_file.fields = parse_field_info(handle, class_file.fields_count)
	class_file.methods_count = parse_u2(handle)
	class_file.methods = parse_method_info(handle, class_file.methods_count)
	class_file.attributes_count = parse_u2(handle)
	class_file.attributes = parse_attribute_info(handle, class_file.attributes_count)

	// https://docs.oracle.com/javase/specs/jvms/se12/html/jvms-6.html#jvms-6.5
	// https://docs.oracle.com/javase/specs/jvms/se12/html/jvms-5.html#jvms-5.3

	run_method(class_file, "main")
}

run_method :: proc(class_file: Class_File, method_name: string) {
	for method in class_file.methods {
		current_method := class_file.constant_pool[method.name_index - 1].data.(CONSTANT_Utf8).str
		if current_method != method_name do continue

		for attrib in method.attributes {
			attrib_name := class_file.constant_pool[attrib.attribute_name_index - 1]
			if attrib_name.data.(CONSTANT_Utf8).str == "Code" {
				code_attrib := parse_code_attrib(attrib.info)
				execute_code(class_file, code_attrib)
			}
		}
	}
}

parse_code_attrib :: proc(bytes: []u8) -> Code_Attribute {
	code := Code_Attribute{}
	cursor := 0

	cursor += 2
	code.max_stack = (transmute([]u16be)bytes[cursor - 2:cursor])[0]
	cursor += 2
	code.max_locals = (transmute([]u16be)bytes[cursor - 2:cursor])[0]
	cursor += 4
	code.code_length = (transmute([]u32be)bytes[cursor - 4:cursor])[0]
	cursor += int(code.code_length)
	code.code = bytes[cursor - int(code.code_length):cursor]
	cursor += 2
	code.exception_table_length = (transmute([]u16be)bytes[cursor - 2:cursor])[0]
	assert(code.exception_table_length == 0, "We do not support parsing exceptions yet")
	code.exception_table = {}
	cursor += 2
	code.attributes_count = (transmute([]u16be)bytes[cursor - 2:cursor])[0]
	// TODO: Add support for attributes
	code.attributes = {}

	return code
}

Instruction_Type :: enum u8 {
	ICONST_1      = 0x4,
	BIPUSH        = 0x10,
	IADD          = 0x60,
	ISUB          = 0x64,
	GETSTATIC     = 0xb2,
	LDC           = 0x12,
	PUTSTATIC     = 0xb3,
	INVOKEVIRTUAL = 0xb6,
	RETURN        = 0xb1,
}

StackNode :: struct {
	data: union {
		StackNodeFieldRef,
		StackNodeMethodRef,
		StackNodeConstant,
	},
}

RuntimeMethod :: enum {
	PRINTLN = 0,
}
StackNodeMethodRef :: struct {
	runtime_method: RuntimeMethod,
}
StackNodeFieldRef :: struct {
	name: string,
}

StackNodeConstant :: struct {
	data: union {
		string,
		int,
	},
}

get_class_name :: proc(class_file: Class_File, class_index: u32) -> string {
	class := class_file.constant_pool[class_index - 1].data.(CONSTANT_Class)
	return class_file.constant_pool[class.name_index - 1].data.(CONSTANT_Utf8).str
}

get_name_and_type :: proc(
	class_file: Class_File,
	name_type_index: u32,
) -> (
	name: string,
	descriptor: string,
) {
	name_type := class_file.constant_pool[name_type_index - 1].data.(CONSTANT_NameAndType)
	target_name := class_file.constant_pool[name_type.name_index - 1].data.(CONSTANT_Utf8).str
	target_descriptor :=
		class_file.constant_pool[name_type.descriptor_index - 1].data.(CONSTANT_Utf8).str

	return target_name, target_descriptor
}

get_integer_value_from :: proc(node: StackNode, int_fields_map: map[string]int) -> int {
	#partial switch node_type in node.data {
	case StackNodeConstant:
		return node_type.data.(int)
	case StackNodeFieldRef:
		return int_fields_map[node_type.name]
	case:
		panic("Non supported stack node in get integer value")
	}
}

execute_code :: proc(class_file: Class_File, code_attrib: Code_Attribute) {
	stack := stack_init(int(code_attrib.max_stack))
	int_fields_map := make(map[string]int)

	cursor := -1
	for cursor < len(code_attrib.code) {
		cursor += 1
		instruction := Instruction_Type(code_attrib.code[cursor])
		switch instruction {
		case .GETSTATIC:
			cursor += 2
			cp_index := (transmute([]u16be)code_attrib.code[cursor - 1:cursor + 1])[0]

			field_ref := class_file.constant_pool[cp_index - 1].data.(CONSTANT_Fieldref)

			class_name := get_class_name(class_file, u32(field_ref.class_index))
			target_name, target_descriptor := get_name_and_type(
				class_file,
				u32(field_ref.name_and_type_index),
			)

			if class_name == "java/lang/System" &&
			   target_name == "out" &&
			   target_descriptor == "Ljava/io/PrintStream;" {
				node := StackNodeMethodRef{RuntimeMethod.PRINTLN}
				stack_push(&stack, StackNode{node})
				// Only handles INT fields
			} else if (class_name == "Main" && target_descriptor == "I") {
				node := StackNodeFieldRef{target_name}
				stack_push(&stack, StackNode{node})
			} else {
				fmt.println(
					"UNSUPPORTED METHOD IN GET STATIC:",
					class_name,
					target_name,
					target_descriptor,
				)
				return
			}
		case .PUTSTATIC:
			cursor += 2
			cp_index := (transmute([]u16be)code_attrib.code[cursor - 1:cursor + 1])[0]

			field_ref := class_file.constant_pool[cp_index - 1].data.(CONSTANT_Fieldref)

			class_name := get_class_name(class_file, u32(field_ref.class_index))
			field_name, target_descriptor := get_name_and_type(
				class_file,
				u32(field_ref.name_and_type_index),
			)

			if class_name == "Main" && target_descriptor == "I" {
				value := get_integer_value_from(stack_pop(&stack), int_fields_map)
				int_fields_map[field_name] = value
			} else {
				fmt.println(
					"UNSUPPORTED METHOD IN PUT STATIC:",
					class_name,
					field_name,
					target_descriptor,
				)
				return
			}
		case .BIPUSH:
			cursor += 1
			byte_value := code_attrib.code[cursor]
			node := StackNodeConstant{int(byte_value)}
			stack_push(&stack, StackNode{node})
		case .ICONST_1:
			node := StackNodeConstant{int(1)}
			stack_push(&stack, StackNode{node})
		case .LDC:
			cursor += 1
			cp_index := code_attrib.code[cursor]

			constant := class_file.constant_pool[cp_index - 1]
			#partial switch c in constant.data {
			case CONSTANT_String:
				str := class_file.constant_pool[c.string_index - 1].data.(CONSTANT_Utf8).str
				node := StackNodeConstant{str}
				stack_push(&stack, StackNode{node})
			case:
				fmt.println("constant of kind:", c, "is not supported")
				return
			}
		case .IADD:
			val1 := get_integer_value_from(stack_pop(&stack), int_fields_map)
			val2 := get_integer_value_from(stack_pop(&stack), int_fields_map)

			node := StackNodeConstant{int(val1 + val2)}
			stack_push(&stack, StackNode{node})
		case .ISUB:
			val2 := get_integer_value_from(stack_pop(&stack), int_fields_map)
			val1 := get_integer_value_from(stack_pop(&stack), int_fields_map)

			node := StackNodeConstant{int(val1 - val2)}
			stack_push(&stack, StackNode{node})
		case .INVOKEVIRTUAL:
			cursor += 2
			cp_index := (transmute([]u16be)code_attrib.code[cursor - 1:cursor + 1])[0]

			method_ref := class_file.constant_pool[cp_index - 1].data.(CONSTANT_Methodref)

			class_name := get_class_name(class_file, u32(method_ref.class_index))
			target_name, target_descriptor := get_name_and_type(
				class_file,
				u32(method_ref.name_and_type_index),
			)
			assert(
				stack_size(stack) > 0,
				"Invoke virtual expects a method ref on top of the stack",
			)
			// This should always be a method
			node := stack_peek(&stack, -2)
			stack_method := node.data.(StackNodeMethodRef).runtime_method
			switch stack_method {
			case .PRINTLN:
				method_println(&stack, int_fields_map)
			}
			// Pop the method
			stack_pop(&stack)
		case .RETURN:
			fmt.println("RETURN FROM METHOD")
			return
		case:
			fmt.println("Instruction not supported:", code_attrib.code[cursor])
			return
		}
	}
}

method_println :: proc(stack: ^Stack, int_fields_map: map[string]int) {
	assert(stack_size(stack^) > 0, "println expects a constant string")
	node := stack_pop(stack)

	#partial switch node_type in node.data {
	case StackNodeConstant:
		switch data in node_type.data {
		case string:
			fmt.println("PRINTLN (String):", data)
		case int:
			fmt.println("PRINTLN (Integer):", data)
		case:
			fmt.println("Unsupported constant type in println:", data)
			return
		}
	case StackNodeFieldRef:
		fmt.println("PRINTLN (Integer):", get_integer_value_from(node, int_fields_map))
	case:
		panic("Non supported stack node in get integer value")
	}


}
